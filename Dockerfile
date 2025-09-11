# ---------- Stage 1: Build bundle on Debian (更稳) ----------
FROM node:22.16.0-bullseye AS builder

ENV LANG=C.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl python3 build-essential \
    pkg-config libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# Install Rust for native modules like @napi-rs/pinyin
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Deno for apps-engine
RUN curl -fsSL https://deno.land/install.sh | sh
ENV PATH="/root/.deno/bin:${PATH}"

# 安装 Meteor（允许 root，增加重试机制）
RUN for i in 1 2 3; do \
        curl -fsSL https://install.meteor.com/ | sed s/--progress-bar/-sL/g | sh && break || \
        (echo "Meteor install attempt $i failed, retrying..." && sleep 5); \
    done
ENV PATH="/root/.meteor:${PATH}"

WORKDIR /src

# 先装依赖（利用缓存）
COPY package.json .yarnrc.yml ./
COPY .yarn ./.yarn
COPY packages ./packages
COPY ee ./ee
COPY apps ./apps
# 安装依赖（配置已在.yarnrc.yml中设置）
RUN corepack enable && \
    yarn install --mode=skip-build && \
    yarn cache clean --all

# 拷贝剩余源码
COPY . .

# 确保 ts-patch 和 typia 正确安装
RUN cd packages/ui-kit && yarn run .:build:prepare

# monorepo 预构建（等价于你之前的 build:ci）
RUN yarn build && \
    yarn cache clean --all

# 打 Meteor 服务器 bundle
WORKDIR /src/apps/meteor
RUN yarn install && \
    yarn cache clean --all
RUN meteor build --server-only --directory /opt/rc-bundle --allow-superuser && \
    rm -rf /src/apps/meteor/node_modules && \
    rm -rf /tmp/* && \
    cd /opt/rc-bundle/bundle && \
    find . -name "*.map" -delete && \
    find . -name "*.ts" -delete && \
    find . -name "*.coffee" -delete && \
    rm -rf programs/web.browser/dynamic/node_modules/*/test* && \
    rm -rf programs/web.browser/dynamic/node_modules/*/docs && \
    rm -rf programs/web.browser/dynamic/node_modules/*/examples && \
    rm -rf programs/web.browser.legacy/dynamic/node_modules/*/test* && \
    rm -rf programs/web.browser.legacy/dynamic/node_modules/*/docs && \
    rm -rf programs/web.browser.legacy/dynamic/node_modules/*/examples

# ---------- Stage 2: Runtime on Alpine ----------
FROM node:22.16.0-alpine AS runtime

ENV LANG=C.UTF-8 \
    NODE_ENV=production \
    DEPLOY_METHOD=docker \
    PORT=3000 \
    ROOT_URL=http://localhost:3000 \
    MONGO_URL=mongodb://mongo:27017/rocketchat \
    Accounts_AvatarStorePath=/app/uploads

# 仅运行期必需的包
RUN apk add --no-cache tini tzdata openssl libc6-compat

# 创建非 root 用户（用 busybox 自带 addgroup/adduser 更简单）
# 不固定 GID，避免冲突；可选：固定 UID（常见为 65533），若担心也可不固定
RUN addgroup -S rocketchat \
 && adduser -S -D -G rocketchat -u 65533 -H -s /sbin/nologin rocketchat || \
    (deluser rocketchat 2>/dev/null || true && adduser -S -D -G rocketchat -H -s /sbin/nologin rocketchat)


WORKDIR /app

# 从 builder 拷贝 bundle
COPY --from=builder --chown=rocketchat:rocketchat /opt/rc-bundle/bundle /app/bundle

# 安装 server 端依赖（musl 环境）
WORKDIR /app/bundle/programs/server
# 若需强制用 musl 预编译，可加环境开关；否则走源码编译
RUN npm ci --omit=dev \
 && npm rebuild bcrypt --build-from-source \
 # sharp 在 musl 上常见，单独装并放回 npm 层级（你的原 hack 保留）
 && rm -rf npm/node_modules/sharp \
 && npm install sharp@0.32.6 --no-save \
 && mv node_modules/sharp npm/node_modules/sharp \
 && npm cache clean --force

# （可选）如果你有提前构建好的 matrix musl .node，可在这里 COPY 进去：
# COPY matrix-sdk-crypto.linux-x64-musl.node \
#   /app/bundle/programs/server/npm/node_modules/@matrix-org/matrix-sdk-crypto-nodejs/prebuilds/linux-x64/musl/matrix-sdk-crypto.linux-x64-musl.node

USER rocketchat
WORKDIR /app/bundle

VOLUME /app/uploads
EXPOSE 3000

ENTRYPOINT ["/sbin/tini","--"]
CMD ["node","main.js"]
