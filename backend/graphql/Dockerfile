# ---- Base settings ----------------------------------------------------------
ARG NODE_VERSION=20-alpine
ARG APP_DIR=/app

# ---- Builder: install deps & build ------------------------------------------
FROM node:${NODE_VERSION} AS builder
ARG APP_DIR
WORKDIR ${APP_DIR}

# Environment for development build
ENV NODE_ENV=development
ENV npm_config_fund=false npm_config_audit=false

# Copy package files first for better caching
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Copy source and build
COPY . .
RUN npm run build

# ---- Runtime: minimal, non-root, production deps only -----------------------
FROM node:${NODE_VERSION} AS runtime
ARG APP_DIR
WORKDIR ${APP_DIR}

# Environment for production
ENV NODE_ENV=production \
    GRAPHQL_PORT=8080

# Copy package files and install prod dependencies
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# Copy built artifacts from builder
COPY --from=builder ${APP_DIR}/dist ./dist
COPY --from=builder ${APP_DIR}/neo4j ./neo4j
COPY --from=builder ${APP_DIR}/schema.graphql ./schema.graphql

# Non-root user for security
RUN addgroup -S nodegrp && adduser -S nodeuser -G nodegrp
USER nodeuser

# Expose GraphQL port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start command
CMD [ "npm", "run", "start" ]