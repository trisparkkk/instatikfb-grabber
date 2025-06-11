FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk git

# Create a minimal git structure with default values
RUN mkdir -p /app/.git/logs && \
    echo "0000000000000000000000000000000000000000 unknown" > /app/.git/logs/HEAD && \
    echo "ref: refs/heads/main" > /app/.git/HEAD && \
    echo "[remote \"origin\"]\n\turl = https://github.com/imputnet/cobalt" > /app/.git/config

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# Copy the .git directory to prod/api to maintain the same structure
RUN cp -r /app/.git /prod/api/

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
