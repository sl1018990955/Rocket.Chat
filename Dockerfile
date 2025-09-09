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
    git \
    libc6-compat

WORKDIR /app

# Copy package files first for better caching
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/ .yarn/

# Install dependencies
RUN yarn install --immutable

# Copy source code
COPY . .

# Build the application
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
    dumb-init \
    fontconfig \
    ttf-dejavu

# Create rocketchat user
RUN addgroup -S rocketchat && \
    adduser -D -S -G rocketchat rocketchat

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

# Install production dependencies
RUN cd /app/bundle/programs/server && \
    npm install --omit=dev && \
    npm cache clean --force

# Create uploads directory
RUN mkdir -p /app/uploads

VOLUME ["/app/uploads"]

WORKDIR /app/bundle

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/info', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "main.js"]