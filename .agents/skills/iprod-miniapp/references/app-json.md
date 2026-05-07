# app.json

`app.json` 必需，用来声明 mini app 的元数据、版本、权限、网络白名单和宿主加载的入口 HTML。

最简存储型 mini app：

```json
{
  "id": "user.todo",
  "name": "待办清单",
  "version": "1.0.0",
  "description": "一个本地的待办列表。",
  "icon": "T",
  "entry": "index.html",
  "permissions": ["storage"],
  "createdAt": "2026-05-07T00:00:00Z",
  "runtimeVersion": "1.0",
  "networkAllowlist": [],
  "signature": null
}
```

需要走宿主网络代理的 mini app：

```json
{
  "id": "user.weather",
  "name": "天气",
  "version": "1.0.0",
  "description": "通过白名单 API 获取天气。",
  "icon": "W",
  "entry": "index.html",
  "permissions": ["storage", "network"],
  "createdAt": "2026-05-07T00:00:00Z",
  "runtimeVersion": "1.0",
  "networkAllowlist": ["api.example.com"],
  "signature": null
}
```

希望宿主帮忙保留顶部状态栏 SafeArea 的 mini app：

```json
{
  "id": "user.reader",
  "name": "阅读",
  "version": "1.0.0",
  "description": "一个保留状态栏的长文阅读器。",
  "icon": "R",
  "entry": "index.html",
  "permissions": ["storage"],
  "createdAt": "2026-05-07T00:00:00Z",
  "runtimeVersion": "1.0",
  "networkAllowlist": [],
  "signature": null,
  "immersive": {
    "topInset": true,
    "bottomInset": false,
    "showHeader": false
  }
}
```

字段约束：

- `id` 必须匹配 `^[a-zA-Z0-9][a-zA-Z0-9._-]{2,63}$`。
- `entry` 必须是相对本地 HTML 路径，通常是 `index.html`。
- `permissions` 可包含 `storage`、`secureStorage`、`notification`、`network`、`device`、`ui`、`clipboard`、`share`、`open`、`file`、`media`、`location`、`haptics`、`barcode`、`audio`、`biometric`、`contacts`、`calendar`、`download`、`events`。
- `networkAllowlist` 只能是 host 名，不能写完整 URL。
- `signature` 是预留字段，MVP 阶段固定为 `null`。
- `immersive` 可选。`topInset` / `bottomInset` / `showHeader` 默认都是 `false`，意味着 WebView 会铺满整个屏幕（无宿主 chrome、无顶部/底部 SafeArea）。**只要某个字段保持 `false`，mini app 就必须自己用 CSS `env(safe-area-inset-top)` / `env(safe-area-inset-bottom)` 处理对应方向的 SafeArea。** 用户可以在宿主的"管理"页里逐个 mini app 覆盖这些设置。
