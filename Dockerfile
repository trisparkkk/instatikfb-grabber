FROM node:23-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app

# Debug: Check initial context
COPY . .
RUN echo "==== Initial Build Context ====" && \
    pwd && \
    ls -la / && \
    echo "==== Git Status ====" && \
    git status || echo "Git not initialized" && \
    echo "==== Docker Build Args ====" && \
    printenv

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk git

# Debug: Check Git configuration
RUN git --version && \
    git config --list || echo "No git config"

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app

# Debug: Check package.json for Git dependencies
RUN echo "==== Package.json Contents ====" && \
    cat package.json

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
