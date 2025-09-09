# Multi-stage Dockerfile for Rocket.Chat Custom Build
# Stage 1: Build stage
FROM node:22.16.0-alpine AS builder

LABEL maintainer="admin888@example.com"

ENV LANG=C.UTF-8

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    py3-setuptools \
    git \
    shadow \
    libc6-compat

WORKDIR /app

# Copy package files for dependency installation
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/ .yarn/

# Copy all packages and apps
COPY packages/ packages/
COPY apps/ apps/
COPY ee/ ee/

# Install dependencies
RUN yarn install --immutable

# Build packages
RUN yarn build

# Build meteor application
WORKDIR /app/apps/meteor
RUN yarn build

# Stage 2: Runtime stage
FROM node:22.16.0-alpine

LABEL maintainer="admin888@example.com"
LABEL description="Rocket.Chat Custom Build with HT.Chat branding"

ENV LANG=C.UTF-8

# Install runtime dependencies
RUN apk add --no-cache \
    deno \
    ttf-dejavu \
    shadow \
    python3 \
    make \
    g++ \
    py3-setuptools \
    libc6-compat

# Create rocketchat user and group
RUN groupmod -n rocketchat nogroup \
    && useradd -u 65533 -r -g rocketchat rocketchat

# Copy built application from builder stage
COPY --from=builder --chown=rocketchat:rocketchat /app/apps/meteor/.meteor/local/build /app/bundle

# Set environment variables
ENV DEPLOY_METHOD=docker \
    NODE_ENV=production \
    MONGO_URL=mongodb://mongo:27017/rocketchat \
    HOME=/tmp \
    PORT=3000 \
    ROOT_URL=http://localhost:3000 \
    Accounts_AvatarStorePath=/app/uploads

USER rocketchat

# Install production dependencies and rebuild native modules
RUN cd /app/bundle/programs/server \
    && npm install --omit=dev \
    && rm -rf npm/node_modules/sharp \
    && npm install sharp@0.32.6 --no-save \
    && mv node_modules/sharp npm/node_modules/sharp \
    && cd npm/node_modules/@vector-im/matrix-bot-sdk \
    && npm install \
    && cd /app/bundle/programs/server/npm \
    && npm rebuild bcrypt --build-from-source \
    && npm cache clear --force

# Switch back to root to clean up build dependencies
USER root
RUN apk del python3 make g++ py3-setuptools

# Switch back to rocketchat user
USER rocketchat

# Create uploads volume
VOLUME /app/uploads

WORKDIR /app/bundle

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/info || exit 1

CMD ["node", "main.js"]