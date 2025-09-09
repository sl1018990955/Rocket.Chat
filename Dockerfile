FROM node:22.16.0-alpine3.20

LABEL maintainer="buildmaster@rocket.chat"

ENV LANG=C.UTF-8

# Install dependencies and create user (based on official Dockerfile.alpine)
RUN apk add --no-cache deno ttf-dejavu \
    && apk add --no-cache --virtual deps shadow python3 make g++ py3-setuptools libc6-compat \
    && groupmod -n rocketchat nogroup \
    && useradd -u 65533 -r -g rocketchat rocketchat

COPY --chown=rocketchat:rocketchat . /app

# Set environment variables
ENV DEPLOY_METHOD=docker \
    NODE_ENV=production \
    MONGO_URL=mongodb://mongo:27017/rocketchat \
    HOME=/tmp \
    PORT=3000 \
    ROOT_URL=http://localhost:3000 \
    Accounts_AvatarStorePath=/app/uploads

USER rocketchat

# Install dependencies (based on official configuration)
RUN cd /app/bundle/programs/server \
    && npm install --omit=dev \
    && cd /app/bundle/programs/server \
    && rm -rf npm/node_modules/sharp \
    && npm install sharp@0.32.6 --no-save \
    && mv node_modules/sharp npm/node_modules/sharp \
    && cd /app/bundle/programs/server/npm/node_modules/@vector-im/matrix-bot-sdk \
    && npm install \
    && cd /app/bundle/programs/server/npm \
    && npm rebuild bcrypt --build-from-source \
    && npm cache clear --force

USER root

RUN apk del deps

USER rocketchat

VOLUME /app/uploads

WORKDIR /app/bundle

EXPOSE 3000

CMD ["node", "main.js"]