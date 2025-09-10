# Rocket.Chat 项目部署指南

本文档记录了 Rocket.Chat 二次开发项目的完整部署流程和配置信息。

## 项目基础信息

### 开发环境
- **系统环境**：Windows 11 + WSL (Ubuntu 22.04)
- **源码路径**：`/home/admin888/code/Rocket.Chat`
- **本地运行状态**：已在 WSL 中成功运行 Rocket.Chat
- **开发服务器**：`http://localhost:3000`
- **当前运行服务**: 
  - Rocket.Chat 开发服务器: http://localhost:3000/home
  - 运行命令: `cd /home/admin888/code/Rocket.Chat/apps/meteor && yarn dev`
  - 终端状态: 活跃运行中 (terminal_id: 3)

### Git 配置信息
- **用户配置**: admin888 <admin888@example.com>
- **GitHub 用户名**：`sl1018990955`
- **Git 配置邮箱**：`1018990955@qq.com`
- **SSH Key 状态**：已生成并绑定 GitHub（可正常执行 `ssh -T git@github.com`）
- **远程仓库**: 
  - origin: git@github.com:sl1018990955/Rocket.Chat.git (个人fork仓库)
  - upstream: git@github.com:RocketChat/Rocket.Chat.git (上游官方仓库)
- **当前分支**: main
- **最新提交**: d782353 (HEAD -> main, feat/test-push) chore: test push commit
- **工作区状态**: 
  - 已修改文件: 
    - apps/meteor/client/views/home/DefaultHomePage.tsx
    - packages/i18n/src/locales/zh.i18n.json
    - yarn.lock
  - 未跟踪文件: 
    - Rocket.Chat中文翻译添加指南.md
    - Rocket.Chat项目部署指南.md
- **可用分支**: 
  - 本地: develop, feat/test-push, main
  - 远程: origin/develop, origin/HEAD -> origin/develop

### 仓库配置
- **Fork 仓库**：`sl1018990955/Rocket.Chat`
- **远程仓库配置**：
  - `origin` → `git@github.com:sl1018990955/Rocket.Chat.git`
  - `upstream` → `git@github.com:RocketChat/Rocket.Chat.git`
- **默认分支**：`main`
- **测试分支**：`feat/test-push`（已验证推送功能）

## 部署架构

### 开发流程
1. 本地开发：在 WSL 环境中修改源码
2. 热更新调试：通过 `yarn dev` 实时验证修改效果
3. 代码提交：将修改推送到 GitHub 仓库
4. 镜像构建：通过 GitHub Actions 自动构建 Docker 镜像
5. 生产部署：客户通过 Docker Compose 更新镜像

### 镜像发布流程
1. 将代码修改合并到 `main` 分支
2. 创建版本标签（格式：`v6.7.3-custA-r1`）
3. GitHub Actions 自动触发构建
4. 镜像推送到 GHCR：`ghcr.io/sl1018990955/rocketchat-custom:<tag>`

## 已配置组件

### 中文翻译
- **翻译文件路径**: `packages/i18n/src/locales/zh.i18n.json`
- **已添加翻译**: 首页相关的中文翻译键值对
  - `Default_Home_Page_Welcome`: "欢迎使用 Rocket.Chat"
  - `Default_Home_Page_Description`: "开始您的团队协作之旅"
  - `Default_Home_Page_Get_Started`: "立即开始"
- **构建状态**: i18n 包已重新构建
- **相关文档**: 已创建《Rocket.Chat中文翻译添加指南.md》


### Docker 配置
- **Dockerfile**：多阶段构建配置（构建 → 运行镜像）
- **构建目标**：生产就绪的 Node.js 运行镜像

### GitHub Actions
- **工作流文件**：`.github/workflows/release-image.yml`
- **触发条件**：推送版本标签时自动执行
- **功能**：自动构建并推送 Docker 镜像到 GHCR

## 完整部署操作流程

### 1. 本地开发和测试

```bash
# 启动开发服务器
cd /home/admin888/code/Rocket.Chat/apps/meteor
yarn dev

# 访问本地服务验证修改
# http://localhost:3000
```

### 2. 代码提交和版本发布

```bash
# 提交代码修改
git add .
git commit -m "feat: 添加中文翻译支持"
git push origin main

# 创建版本标签
git tag -a v6.7.3-custA-r1 -m "添加中文翻译支持"
git push origin v6.7.3-custA-r1
```

### 3. 验证镜像构建

```bash
# 检查 GitHub Actions 构建状态
# 访问：https://github.com/sl1018990955/Rocket.Chat/actions

# 验证镜像是否成功推送
# 访问：https://github.com/sl1018990955/Rocket.Chat/pkgs/container/rocketchat-custom
```

### 4. 客户端更新部署

客户需要在生产环境执行以下命令：

```bash
# 拉取最新镜像
docker compose pull rocketchat

# 重启服务应用新镜像
docker compose up -d rocketchat
```

## 客户端 Docker Compose 配置要求

客户的 `docker-compose.yml` 文件需要包含以下配置：

```yaml
version: '3.8'

services:
  rocketchat:
    image: ghcr.io/sl1018990955/rocketchat-custom:v6.7.3-custA-r1
    # 其他配置...
```

## 版本标签命名规范

建议使用以下格式：
- **格式**：`v{base_version}-{customer}-r{revision}`
- **示例**：
  - `v6.7.3-custA-r1`：客户A的第1个修订版本
  - `v6.7.3-custA-r2`：客户A的第2个修订版本
  - `v6.7.3-custB-r1`：客户B的第1个修订版本

## ⚠️ 缺失的关键配置文件

**经过检查，发现以下关键文件缺失，需要立即创建：**

### 1. 🚨 缺失：Dockerfile
- **状态**：❌ 不存在
- **位置**：项目根目录 `/home/admin888/code/Rocket.Chat/Dockerfile`
- **影响**：无法构建 Docker 镜像
- **优先级**：🔴 高优先级

### 2. 🚨 缺失：GitHub Actions 工作流
- **状态**：❌ 不存在
- **位置**：`.github/workflows/release-image.yml`
- **影响**：无法自动构建和发布镜像
- **优先级**：🔴 高优先级

## 环境限制和解决方案

### 网络连接问题
- **GitHub CLI 安装失败**: 网络连接问题导致无法通过 apt、snap、curl 安装
- **解决方案**: 使用现有 Git 命令行工具完成所有操作
- **Git 可用性**: ✅ Git 2.34.1 已安装且配置正确

### 命令行操作可行性
- **用户需求**: 完全通过命令行操作，无需手动 Git 操作
- **可行性**: ✅ 完全可行
- **工具**: 使用原生 Git 命令完成代码管理、版本发布等操作

### 3. 需要补充的其他信息

#### GitHub Actions 配置验证
- [ ] 验证 GitHub Actions 是否有推送到 GHCR 的权限
- [ ] 检查 GITHUB_TOKEN 权限配置
- [ ] 配置 GHCR 访问权限

#### Docker 配置验证
- [ ] 测试本地 Docker 构建是否成功
- [ ] 验证构建后的镜像功能完整性

### 3. 客户环境信息
- [ ] 客户当前使用的 Rocket.Chat 版本
- [ ] 客户的 `docker-compose.yml` 配置
- [ ] 客户的数据库配置和数据迁移需求
- [ ] 客户的环境变量配置

### 4. 镜像仓库配置
- [ ] GHCR 访问权限设置（公开/私有）
- [ ] 客户是否能正常访问 GHCR
- [ ] 镜像拉取认证配置（如果是私有仓库）

## 验证清单

在执行部署前，请确认以下项目：

- [ ] 本地代码修改已完成并测试通过
- [ ] Git 仓库状态正常，无未提交的修改
- [ ] GitHub Actions 工作流配置正确
- [ ] Docker 构建配置验证通过
- [ ] 版本标签命名符合规范
- [ ] 客户环境配置已确认
- [ ] 备份策略已制定（如数据库备份）

## 故障排查

### GitHub Actions 构建失败
1. 检查 `.github/workflows/release-image.yml` 语法
2. 验证 GITHUB_TOKEN 权限
3. 查看构建日志中的错误信息

### Docker 镜像构建失败
1. 本地测试 Docker 构建：`docker build -t test-image .`
2. 检查 Dockerfile 语法和依赖
3. 验证构建上下文中的文件

### 客户部署失败
1. 确认客户能访问镜像仓库
2. 检查 docker-compose.yml 配置
3. 验证环境变量和数据库连接

## 🚀 紧急行动计划

### 第一阶段：创建缺失的核心文件（必须完成）

1. **创建 Dockerfile**
   ```bash
   # 需要在项目根目录创建 Dockerfile
   # 包含 Rocket.Chat 的多阶段构建配置
   ```

2. **创建 GitHub Actions 工作流**
   ```bash
   # 需要创建 .github/workflows/release-image.yml
   # 配置自动构建和推送到 GHCR 的流程
   ```

### 第二阶段：配置和测试

3. **配置 GitHub 权限**
   - 设置 GITHUB_TOKEN 权限
   - 配置 GHCR 访问权限

4. **本地测试**
   - 测试 Docker 构建
   - 验证镜像功能

5. **端到端测试**
   - 创建测试标签
   - 验证自动构建流程
   - 测试镜像部署

### 第三阶段：生产部署

6. **正式发布**
   - 创建生产版本标签
   - 通知客户更新流程

## 下一步行动

### 立即执行 (通过命令行)

1. **提交当前修改**
   ```bash
   git add .
   git commit -m "feat: 添加中文翻译和部署指南文档"
   git push origin main
   ```

2. **创建 Dockerfile**
   - 在项目根目录创建多阶段构建的 Dockerfile
   - 基于现有 apps/meteor/.docker/ 配置优化

3. **创建 GitHub Actions 工作流**
   - 创建 .github/workflows/release-image.yml
   - 配置自动构建和推送到 GHCR

4. **测试完整流程**
   - 本地测试 Docker 构建: `docker build -t rocketchat-custom .`
   - 推送代码触发 GitHub Actions
   - 验证镜像构建和发布

### 重要提醒
- ✅ 所有操作可通过 Git 命令行完成，无需手动操作
- ✅ 当前环境已具备完整的开发和部署条件
- ⚠️ 网络连接问题已通过使用原生 Git 工具解决

---

*本文档将随着项目进展持续更新，确保部署流程的准确性和完整性。*