FROM node:23-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk git

# Initialize git and create static files with default values
RUN echo "unknown" > /app/git_commit && \
    echo "main" > /app/git_branch && \
    echo "https://github.com/imputnet/cobalt" > /app/git_remote

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
COPY --from=build --chown=node:node /app/git_* /app/

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
