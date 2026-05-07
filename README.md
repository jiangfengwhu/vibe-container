# 本地应用工作台

本地应用工作台（Local App Workbench）是一个 Flutter MVP，用来在移动端作为本地优先的 mini app 宿主运行 AI 生成的 Web 小应用。宿主应用负责管理应用库、导入 bundle、在系统 WebView 中加载本地资源，并暴露一组受限的异步运行时桥接能力。

MVP 使用 Flutter 构建跨平台宿主壳。Web 运行时通过 `webview_flutter` 使用平台 WebView：iOS 上是 `WKWebView`，Android 上是 Android WebView。

## 已包含能力

- 应用库：展示名称、图标、描述和上次使用时间。卡片左滑可揭示「管理」按钮，点击或滑到底部进入管理页（权限、删除、沉浸模式）。
- 内置示例 bundle 导入：目前仅保留一个“城市应急巡检台”，用于验证 AppRuntime bridge 全量能力。
- 远程导入：支持从 Cloudflare R2 下载并导入生成好的 `.ipd` bundle。
- WebView 运行页：默认全沉浸、不显示宿主 header，加载错误友好展示，运行时桥接随页面自动注入。
- 沉浸式容器：通过 `app.json.immersive` 声明（`topInset` / `bottomInset` / `showHeader`），默认 `{topInset: false, bottomInset: false, showHeader: false}`。用户可以在每个 mini app 的「管理」页里覆盖默认值；mini app 自身用 CSS `env(safe-area-inset-*)` 适配。
- 应用级权限管理：支持 `storage`、`notification`、`network`。
- `app.json` manifest 解析与校验。
- 按应用隔离的本地存储命名空间。
- Web 侧 JS SDK：注入为 `window.AppRuntime`。
- Dart 侧桥接请求和响应 schema 校验。
- 网络桥接：`AppRuntime.network.fetch` 仅允许访问 `networkAllowlist` 中的 HTTPS host。
- 常用 native 能力桥接：设备信息、UI、剪贴板、分享、打开外部资源、文件、媒体、位置、触感、扫码、音频、生物识别、联系人选择、日历事件、下载和运行时事件。
- Bundle 校验：校验 manifest、入口文件和桥接权限声明，不限制 HTML/CSS/JS 引用远程资源。
- 基础测试：覆盖 manifest 解析、payload 校验、存储隔离和权限拒绝等核心路径。
- 宿主界面国际化：当前支持中文和英文，默认回退语言为中文。

## 运行

```bash
flutter pub get
flutter run
```

常用检查：

```bash
flutter analyze
flutter test
```

## 项目结构

```text
lib/
  main.dart
  src/
    bridge/       运行时桥接协议、校验与分发
    l10n/         Flutter 宿主界面本地化资源
    models/       app.json 与已安装应用模型
    services/     应用库、bundle 导入、存储、网络、通知服务
    ui/           应用库、导入、权限、运行时页面
    webview/      Web 文档构建与运行时注入
assets/
  runtime/        Web 侧 AppRuntime JS SDK
  sample_bundles/ 内置示例应用 bundle
docs/
  backend/        Mock 后端 API 设计
tooling/
  bundle-kit/     确定性的 bundle 创建、校验、打包 CLI
.agents/
  skills/         用于生成可导入 mini app bundle 的 Agent Skill
test/             核心运行时测试
```

## Bundle 格式

每个 Web mini app bundle 是一个目录，根目录必须包含 `app.json` 和它声明的入口 HTML：

```text
app.json             # 必需，用于元数据、版本、权限和入口声明
index.html/main.html # 必需，实际路径由 app.json 的 entry 指定
任意 CSS/JS/assets   # 可选，由入口 HTML 通过相对路径引用
```

宿主会读取 `app.json.entry` 并加载对应 HTML，不要求入口必须叫 `index.html`。如果页面需要 CSS、JS、图片或其他资源，可以在入口 HTML 中自行声明依赖；本地资源使用相对路径，远程 CDN/资源 URL 不做额外限制，例如：

```html
<link rel="stylesheet" href="bundle.css">
<script src="bundle.js"></script>
<script src="https://cdn.example.com/library.min.js"></script>
```

`app.json` 是必需文件，用于控制应用 id、版本、展示信息、入口和权限：

```json
{
  "id": "local.checkin",
  "name": "城市应急巡检台",
  "version": "1.0.0",
  "description": "面向外勤应急巡检的任务台。",
  "icon": "巡",
  "entry": "index.html",
  "permissions": ["storage"],
  "createdAt": "2026-05-07T00:00:00Z",
  "runtimeVersion": "1.0",
  "networkAllowlist": [],
  "signature": null
}
```

注意事项：

- `entry` 必须是相对本地 HTML 路径，例如 `index.html`、`main.html` 或 `pages/home.html`。
- `permissions` 可包含 `storage`、`secureStorage`、`notification`、`network`、`device`、`ui`、`clipboard`、`share`、`open`、`file`、`media`、`location`、`haptics`、`barcode`、`audio`、`biometric`、`contacts`、`calendar`、`download`、`events`。
- `networkAllowlist` 只约束 `AppRuntime.network.fetch`，只能包含 host name，且必须同时声明 `network` 权限。
- `signature` 是为未来 bundle 签名预留的字段。
- `immersive` 是可选对象，三个布尔字段均默认为 `false`：
  - `topInset`：宿主是否在顶部为状态栏让出 SafeArea。`false` 表示 mini app 铺到状态栏背后，需要自己用 CSS `env(safe-area-inset-top)` 避让。
  - `bottomInset`：宿主是否为底部 home 指示器让出 SafeArea。`false` 表示 mini app 铺到底部手势条背后。
  - `showHeader`：宿主是否在 mini app 顶上叠一条返回 / 刷新 / 管理的 chrome 顶栏。`false` 表示完全沉浸。
- bundle 校验不会拦截远程 `<script>`、CSS、图片、字体或其他 Web 资源；AI 生成的 bundle 可以按普通 Web 页面方式引用 CDN。

## 添加内置示例 Bundle

1. 创建 `assets/sample_bundles/my_app/`。
2. 添加 `app.json`、入口 HTML，并按需添加 CSS、JS 和 assets。
3. 在 `pubspec.yaml` 的 `flutter.assets` 下加入这些文件。
4. 在 `assets/sample_bundles/index.json` 中加入示例条目。
5. 运行 `flutter test`。

如果是后续下载或 AI 生成的 bundle，也使用同样的磁盘结构。当前 `BundleManager` 会把导入的 bundle 放入应用文档目录中隔离的 bundle 路径。

## 使用 Agent 生成 Bundle

仓库包含一个项目级 skill：

```text
.agents/skills/iprod-miniapp/SKILL.md
```

可以这样请求 Agent：

```text
使用 iprod-miniapp skill 创建一个个人饮食计划 mini app，并打包成 .ipd bundle。
```

该 skill 会指导 Agent 在 `generated-bundles/<slug>/` 下创建 bundle，随后校验并打包：

```bash
node .agents/skills/iprod-miniapp/scripts/iprod_bundle.mjs validate generated-bundles/<slug>
node .agents/skills/iprod-miniapp/scripts/iprod_bundle.mjs pack generated-bundles/<slug> --out dist/<slug>.ipd
node .agents/skills/iprod-miniapp/scripts/upload_bundle.mjs dist/<slug>.ipd --key <slug>.ipd
```

也可以手动创建一个起始 bundle：

```bash
node tooling/bundle-kit/iprod_bundle.mjs create generated-bundles/todo --id user.todo --name 待办清单
node tooling/bundle-kit/iprod_bundle.mjs validate generated-bundles/todo
node tooling/bundle-kit/iprod_bundle.mjs pack generated-bundles/todo --out dist/todo.ipd
```

项目开发时可以继续使用 `tooling/bundle-kit/iprod_bundle.mjs`；打包后的 skill 会自带 `scripts/iprod_bundle.mjs` 和 `scripts/upload_bundle.mjs`，方便在其他 agent 平台独立校验、打包并上传 bundle。

`upload_bundle.mjs` 默认上传到 `https://infra.308893.xyz/api/r2/objects/<key>`，使用 `X-Sanyi-INFRA: sanyi`。成功后会输出可在宿主导入页使用的 `downloadUrl`。宿主应用的“从 Cloudflare 下载”入口同时接受对象 key（例如 `<slug>.ipd`）或完整下载 URL。

## 打包 Agent Skill

项目内置的 mini app 生成 skill 可打包成 zip，方便导入其他 agent 平台：

```bash
node tooling/skill-kit/package_skill.mjs .agents/skills/iprod-miniapp dist/iprod-miniapp-skill.zip
```

在宿主应用中导入打包结果：

1. 在设备或模拟器上运行 Flutter 宿主应用。
2. 打开“导入应用 bundle”。
3. 在“从 Cloudflare 下载”中输入上传脚本返回的对象 key 或 `downloadUrl`。
4. 点击“下载并导入”。
5. 从应用库中打开已导入的 mini app。

## 运行时桥接

宿主会在 bundle 脚本之前注入 `window.AppRuntime`。

所有 API 都是异步的，并返回 Promise：

```js
await AppRuntime.storage.set('entries', [{ amount: 12 }]);
const entries = await AppRuntime.storage.get('entries');
await AppRuntime.storage.remove('entries');
await AppRuntime.storage.clear();

const permission = await AppRuntime.notification.requestPermission();
await AppRuntime.notification.schedule({
  title: '提醒',
  body: '该检查了',
  time: new Date().toISOString()
});

const response = await AppRuntime.network.fetch('https://api.example.com/data', {
  method: 'GET',
  headers: {}
});

const manifest = await AppRuntime.app.getManifest();
const permissions = await AppRuntime.app.getPermissions();
const capabilities = await AppRuntime.app.getCapabilities();

await AppRuntime.ui.toast('已保存');
await AppRuntime.clipboard.writeText('hello');
const device = await AppRuntime.device.getInfo();
const image = await AppRuntime.media.pickImage();
const position = await AppRuntime.location.getCurrentPosition();
const unsubscribe = AppRuntime.events.on('resume', () => {
  console.log('mini app resumed');
});
unsubscribe();
```

Web 到 Native 的消息：

```json
{
  "requestId": "uuid",
  "appId": "current-app-id",
  "namespace": "storage",
  "method": "get",
  "params": {
    "key": "entries"
  }
}
```

Native 到 Web 的成功响应：

```json
{
  "requestId": "uuid",
  "ok": true,
  "result": {}
}
```

Native 到 Web 的失败响应：

```json
{
  "requestId": "uuid",
  "ok": false,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "storage permission denied"
  }
}
```

## 国际化

Flutter 宿主界面的本地化资源在 `lib/src/l10n/workbench_localizations.dart`。当前支持：

- `zh`：中文，作为默认回退语言。
- `en`：英文。

宿主当前显式使用中文作为默认界面语言；英文资源已保留在本地化表中，后续可接入语言切换入口。内置示例 bundle 的 manifest 与界面文案当前也以中文为默认。

## Native 能力桥接

`window.AppRuntime` 通过同一个 `AppRuntimeNative` channel 访问 native 能力。每个 namespace 都要求 `app.json` 显式声明同名权限；位置、相机、麦克风、联系人、日历、生物识别等能力还会触发系统权限流程。不支持的平台会返回 `NOT_SUPPORTED`，用户取消选择或扫码等操作会返回 `CANCELLED`。

本轮不包含推送、后台任务和支付。跨平台能力以 Flutter 插件支持范围为准，mini app 应优先调用 `AppRuntime.app.getCapabilities()` 判断是否声明和授权。

## 安全模型

- WebView 只暴露 `AppRuntimeNative` JS channel，供 SDK 使用。
- 桥接请求会校验 `requestId`、`appId`、`namespace`、`method` 和 JSON-safe `params`。
- 请求中的 `appId` 必须匹配当前运行的应用，否则会被拒绝。
- 存储文件按 app id 隔离，一个 mini app 不能读取另一个 mini app 的存储命名空间。
- 通知和 `AppRuntime.network.fetch` 调用都需要 manifest 声明和用户授予运行时权限。
- `AppRuntime.network.fetch` 只接受 HTTPS URL，且 host 必须在 manifest allowlist 中。
- WebView 不额外限制页面自己的远程资源引用；远程脚本、样式、图片、字体和 CDN 资源由页面按标准 Web 方式加载。
- Bundle 签名尚未在 MVP 中实现，但 manifest 已预留 `signature` 字段。

## MVP 限制

- 已实现内置示例导入；后端 bundle 下载仍是预留方向。
- `notification.schedule` 目前只在运行时服务中记录计划通知意图，真正接入原生系统通知是下一步平台插件工作。
- 公开市场、账号系统、云同步、付费分发和协作能力都暂不属于 MVP 范围。
