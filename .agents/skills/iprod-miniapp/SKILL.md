---
name: iprod-miniapp
description: 为本地应用工作台（Local App Workbench / 拾趣）生成、校验并打包 Web mini app bundle，输出可被 Flutter 宿主导入的 .ipd 文件。当用户希望创建 app、mini app、小工具、widget、本地网页应用或 .ipd bundle 时使用。Use when the user asks to create an app, mini app, tool, widget, local web app, or .ipd bundle that should run inside Local App Workbench.
---

# iProd Mini App

为本地应用工作台（拾趣）构建一个本地优先的 Web mini app bundle，并产出可导入的 `.ipd` 文件。

## 输出契约

bundle 是一个目录，根目录必须包含 `app.json` 和 `app.json.entry` 指向的入口 HTML。其它文件可选，必须由入口 HTML 用相对路径引用：

```text
app.json             # 必需，包含元数据、版本、权限和入口
index.html/main.html # 必需，由 app.json.entry 决定文件名
任意 CSS/JS/资源     # 可选，由入口 HTML 通过相对路径引用
```

最终产物：

```text
dist/<app-id>.ipd
```

`.ipd` 内部是一个 zip 容器，但对外只用 `.ipd` 后缀。压缩包的根必须直接是 `app.json`，不要再嵌套一层文件夹。

## 工作流

1. 在 `generated-bundles/<slug>/` 下建立工作目录。
2. 把 mini app 实现成一个独立的 Web bundle。本地文件和远程 CDN 资源都可以使用；如果用了构建工具，请把构建产物放进 bundle 目录。
   - 宿主会按 `app.json.entry` 加载入口 HTML。
   - CSS、JS、图片、其它资源都是可选的，注意保持入口 HTML 中相对引用路径正确。
3. **mini app 是全屏铺满渲染的。** 宿主默认开启全沉浸：不显示宿主 chrome 顶栏、不为顶部状态栏和底部 home 指示器留 SafeArea（`app.json.immersive.topInset` / `bottomInset` / `showHeader` 的默认值都是 `false`）。这意味着你的 HTML 会盖住状态栏和底部手势条，**你必须自己处理 SafeArea**，否则关键内容会被系统 UI 遮挡：
   - 如果你自己写 viewport meta，记得加 `viewport-fit=cover`（宿主已经注入了一份，一般不用再加）。
   - 顶部容器加 `padding-top: max(16px, env(safe-area-inset-top))`（旧 WebKit 可以再回退到 `constant(...)`）。
   - 底部 bar、悬浮按钮、滚动列表加 `padding-bottom: max(16px, env(safe-area-inset-bottom))`。
   - 全屏布局优先用 `min-height: 100dvh`，不要用 `100vh`。

   如果某个方向你确实没法自己适配，可以在 `app.json.immersive` 中把 `topInset` / `bottomInset` 设为 `true`，让宿主帮你留出 SafeArea。`showHeader: true` 仅在 mini app 真的需要宿主提供返回 / 刷新 / 管理 chrome 顶栏时才使用。
4. 所有宿主能力一律走 `window.AppRuntime`，不要直接调用 native channel。
5. 数据本地优先，使用 `AppRuntime.storage` 持久化。
6. `app.json` 中只声明真正会用到的权限。
7. 校验 bundle：

```bash
node scripts/iprod_bundle.mjs validate generated-bundles/<slug>
```

8. 打包：

```bash
node scripts/iprod_bundle.mjs pack generated-bundles/<slug> --out dist/<slug>.ipd
```

9. 上传打包结果。这是必需步骤，仅打包不算完成：

```bash
node scripts/upload_bundle.mjs dist/<slug>.ipd --key <slug>.ipd
```

10. 把上传得到的 `downloadUrl` 返回给用户。如果校验、打包或上传失败，先修复 bundle，再重新跑 validate / pack / upload，最后再结束任务。

## Manifest 规范

`app.json` 必需，且必须包含以下字段：

- `id`：稳定且安全的 id，通常是 `user.<slug>` 或 `local.<slug>`
- `name`：展示名
- `version`：版本号
- `description`：描述
- `icon`：短文本图标
- `entry`：相对本地 HTML 路径，通常是 `index.html`
- `permissions`：可选自 `storage`、`secureStorage`、`notification`、`network`、`device`、`ui`、`clipboard`、`share`、`open`、`file`、`media`、`location`、`haptics`、`barcode`、`audio`、`biometric`、`contacts`、`calendar`、`download`、`events`
- `createdAt`：ISO-8601 时间
- `runtimeVersion`：固定 `1.0`
- `networkAllowlist`：仅 host 名，不带协议和路径
- `signature`：MVP 阶段固定为 `null`
- `immersive`（可选）：对象 `{ topInset?: bool, bottomInset?: bool, showHeader?: bool }`，三个字段默认都是 `false`，代表 WebView 全屏铺满。**只要某个字段保持 `false`，mini app 就必须自己用 CSS `env(safe-area-inset-top)` / `env(safe-area-inset-bottom)` 处理对应方向的 SafeArea。** 仅在 mini app 无法自适应时才把 `topInset` / `bottomInset` 设为 `true`，仅在确实需要宿主返回 / 刷新 / 管理 chrome 顶栏时才把 `showHeader` 设为 `true`。

权限和 API 的对应关系：

- 调用 `AppRuntime.storage.*`，加 `storage`
- 调用 `AppRuntime.secureStorage.*`，加 `secureStorage`
- 调用 `AppRuntime.notification.*`，加 `notification`
- 调用 `AppRuntime.network.*`，加 `network`，并填非空的 `networkAllowlist`
- 调用 `AppRuntime.<namespace>.*`（其它 native 能力），加同名 namespace 权限

## 安全约束

- 不要直接使用 `AppRuntimeNative`。
- 远程 CDN 上的脚本、样式、字体、图片和其它 Web 资源都允许使用。
- mini app 自己的浏览器网络请求（`fetch`、`XMLHttpRequest`、WebSocket、EventSource 等）允许使用；只有在需要宿主代理网络请求时才用 `AppRuntime.network.fetch`，并声明 `network` 权限。
- 不要把 `localStorage` 当作长期存储，应使用 `AppRuntime.storage`。
- 不要随意申请敏感权限，按需声明。

## 参考

按需加载：

- `references/app-runtime.md`：JS API 类型定义和 SafeArea 处理参考。
- `references/app-json.md`：manifest 字段示例。
- `scripts/iprod_bundle.mjs`：确定性的 create / validate / pack / inspect 命令。
- `scripts/upload_bundle.mjs`：把 `.ipd` 上传到 Cloudflare R2。
