FROM node:23-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk git

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

# Capture Git information before deploying
RUN git rev-parse HEAD > /app/git_commit && \
    git rev-parse --abbrev-ref HEAD > /app/git_branch && \
    git config --get remote.origin.url > /app/git_remote

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
COPY --from=build --chown=node:node /app/git_* /app/

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
