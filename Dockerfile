FROM node:23-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app

# Debug: Check if .git is copied
COPY . .
RUN ls -la && \
    echo "==== Root directory contents ====" && \
    pwd && \
    ls -la .git || echo ".git not found in root"

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk git

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

# Debug: Check deployed directory structure
RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api && \
    echo "==== Deployed directory contents ====" && \
    ls -la /prod/api && \
    echo "==== Attempting .git copy ====" && \
    cp -rv .git /prod/api/.git || echo "Failed to copy .git"

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app

# Debug: Check final stage
RUN echo "==== Final stage contents ====" && \
    ls -la && \
    ls -la .git || echo ".git not found in final stage"

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
