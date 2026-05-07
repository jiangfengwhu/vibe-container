# Runtime JS SDK

规范 SDK 位于：

```text
assets/runtime/app_runtime.js
```

宿主会在每个 WebView 中注入该文件，并替换：

- `__APP_ID__`
- `__RUNTIME_VERSION__`

生成的 Web mini app 应调用 `window.AppRuntime`，不要直接向 native channel 发送消息。

当前 SDK 暴露这些 namespace：

- `storage` / `secureStorage`
- `notification` / `network`
- `app` / `device` / `events`
- `ui` / `clipboard` / `share` / `open`
- `file` / `media` / `download`
- `location` / `haptics` / `barcode`
- `audio` / `biometric` / `contacts` / `calendar`

所有 API 都返回 Promise；失败会 reject `{ code, message }`。如果当前平台不支持某能力，会返回 `NOT_SUPPORTED`。事件通过 `AppRuntime.events.on(type, listener)` 订阅，返回的函数可取消订阅。
