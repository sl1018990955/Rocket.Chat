# Rocket.Chat 中文翻译添加指南

本文档详细说明了如何在 Rocket.Chat 项目中正确添加中文翻译的完整流程。

## 概述

Rocket.Chat 使用 i18n 国际化系统来管理多语言翻译。翻译文件位于 `packages/i18n/src/locales/` 目录下，每种语言都有对应的 JSON 文件。

## 翻译添加流程

### 1. 定位翻译文件

中文翻译文件位置：
```
packages/i18n/src/locales/zh.i18n.json
```

### 2. 添加翻译键值对

在 `zh.i18n.json` 文件中添加新的翻译键值对。格式如下：

```json
{
  "translation_key": "中文翻译内容",
  "another_key": "另一个中文翻译"
}
```

**示例：**
```json
{
  "Take_Rocket_Chat_with_you_with_mobile_app": "通过移动应用随身携带 Rocket.Chat",
  "Install_Rocket_Chat_Desktop_App_for_better_experience": "安装 Rocket.Chat 桌面应用以获得更好体验",
  "Learn_more_about_Rocket_Chat_and_unlock_powerful_features": "了解更多关于 Rocket.Chat 的信息并解锁强大功能"
}
```

### 3. 重新构建 i18n 包

添加翻译后，必须重新构建 i18n 包以使翻译生效：

```bash
cd /path/to/Rocket.Chat
yarn workspace @rocket.chat/i18n build
```

这个步骤会：
- 编译翻译文件
- 生成构建后的翻译资源
- 更新 `packages/i18n/dist/resources/` 目录下的文件

### 4. 重启开发服务器

重新构建后，需要重启开发服务器以加载新的翻译：

```bash
# 停止当前服务器（如果正在运行）
# 然后重新启动
cd apps/meteor
yarn dev
```

### 5. 验证翻译是否生效

#### 5.1 检查构建文件

验证翻译是否已包含在构建文件中：

```bash
grep "translation_key" packages/i18n/dist/resources/zh.i18n.json
```

#### 5.2 检查服务器提供的翻译文件

确认服务器是否提供了更新的翻译：

```bash
curl http://localhost:3000/i18n/zh.i18n.json | grep "translation_key"
```

#### 5.3 浏览器验证

1. 打开浏览器访问 `http://localhost:3000`
2. 设置浏览器语言为中文或在应用中切换到中文
3. 刷新页面或清除浏览器缓存
4. 检查翻译是否正确显示

## 常见问题和解决方案

### 问题1：翻译不显示

**可能原因：**
- 未重新构建 i18n 包
- 未重启开发服务器
- 浏览器缓存问题

**解决方案：**
1. 确保执行了 `yarn workspace @rocket.chat/i18n build`
2. 重启开发服务器
3. 清除浏览器缓存或强制刷新（Ctrl+F5）

### 问题2：构建文件中没有翻译

**可能原因：**
- JSON 语法错误
- 翻译键名不符合规范

**解决方案：**
1. 检查 JSON 文件语法是否正确
2. 确保翻译键名使用下划线分隔
3. 重新运行构建命令

### 问题3：服务器未提供更新的翻译

**可能原因：**
- 服务器缓存
- 构建文件未正确复制到服务器资源目录

**解决方案：**
1. 完全重启开发服务器
2. 检查 `apps/meteor/.meteor/local/build/programs/server/assets/app/i18n/` 目录
3. 如果必要，清理构建缓存后重新构建

## 文件路径参考

### 源文件
- 中文翻译源文件：`packages/i18n/src/locales/zh.i18n.json`
- 其他语言文件：`packages/i18n/src/locales/[language].i18n.json`

### 构建文件
- 构建后的翻译文件：`packages/i18n/dist/resources/zh.i18n.json`
- 服务器资源文件：`apps/meteor/.meteor/local/build/programs/server/assets/app/i18n/zh.i18n.json`

### 服务器访问
- 翻译文件 API：`http://localhost:3000/i18n/zh.i18n.json`

## 最佳实践

1. **翻译键命名规范**：使用描述性的英文键名，单词间用下划线分隔
2. **翻译内容**：确保翻译准确、自然，符合中文表达习惯
3. **测试验证**：每次添加翻译后都要进行完整的验证流程
4. **版本控制**：确保翻译文件的修改被正确提交到版本控制系统

## 完整操作示例

以下是一个完整的翻译添加示例：

```bash
# 1. 编辑翻译文件
vim packages/i18n/src/locales/zh.i18n.json

# 2. 重新构建 i18n 包
yarn workspace @rocket.chat/i18n build

# 3. 重启开发服务器
cd apps/meteor
yarn dev

# 4. 验证翻译（在新终端中）
curl http://localhost:3000/i18n/zh.i18n.json | grep "新添加的翻译键"

# 5. 浏览器测试
# 访问 http://localhost:3000 并验证翻译显示
```

## 注意事项

- 每次修改翻译文件后都必须重新构建 i18n 包
- 开发服务器需要重启才能加载新的翻译
- 浏览器可能需要清除缓存才能看到更新
- 确保 JSON 文件语法正确，避免构建失败
- 翻译键应该具有描述性，便于维护

---

*本文档基于 Rocket.Chat 项目的实际操作经验编写，适用于开发环境下的翻译添加流程。*