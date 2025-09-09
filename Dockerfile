FROM node:22.16.0-alpine3.20

LABEL maintainer="buildmaster@rocket.chat"

ENV LANG=C.UTF-8

# Install dependencies and create user
RUN apk add --no-cache dumb-init ttf-dejavu \
    && apk add --no-cache --virtual .build-deps shadow python3 make g++ py3-setuptools libc6-compat \
    && addgroup -S rocketchat \
    && adduser -S -G rocketchat rocketchat

# Copy application files
COPY --chown=rocketchat:rocketchat . /app

# Set environment variables
ENV DEPLOY_METHOD=docker \
    NODE_ENV=production \
    MONGO_URL=mongodb://mongo:27017/rocketchat \
    HOME=/tmp \
    PORT=3000 \
    ROOT_URL=http://localhost:3000 \
    Accounts_AvatarStorePath=/app/uploads

# Switch to rocketchat user for npm operations
USER rocketchat

# Install and build dependencies
RUN cd /app/bundle/programs/server \
    && npm install --omit=dev \
    && rm -rf npm/node_modules/sharp \
    && npm install sharp@0.32.6 --no-save \
    && mv node_modules/sharp npm/node_modules/sharp \
    && cd /app/bundle/programs/server/npm/node_modules/@vector-im/matrix-bot-sdk \
    && npm install \
    && cd /app/bundle/programs/server/npm \
    && npm rebuild bcrypt --build-from-source \
    && npm cache clear --force

# Switch back to root to clean up build dependencies
USER root
RUN apk del .build-deps

# Switch back to rocketchat user
USER rocketchat

# Matrix SDK files are not available in this build context
# TODO: Add matrix SDK files if needed for matrix functionality

# Create volume for uploads
VOLUME /app/uploads

# Set working directory
WORKDIR /app/bundle

# Expose port
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/info || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "main.js"]