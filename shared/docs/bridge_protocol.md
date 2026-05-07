# Runtime Bridge Protocol

All bridge methods are asynchronous. The web SDK sends JSON through the single `AppRuntimeNative` channel and resolves Promises from host responses. Host-to-web events are delivered through `window.__AppRuntimeEmit`.

The host requires `app.json` and loads the relative local HTML path declared by `app.json.entry`. CSS, JavaScript, and assets are optional; local files can be linked with relative paths, and remote CDN/Web resources are not blocked by bundle validation.

## Request

```json
{
  "requestId": "uuid",
  "appId": "current-app-id",
  "namespace": "storage | secureStorage | notification | network | app | device | ui | clipboard | share | open | file | media | location | haptics | barcode | audio | biometric | contacts | calendar | download | events",
  "method": "namespace-specific method",
  "params": {}
}
```

## Success

```json
{
  "requestId": "uuid",
  "ok": true,
  "result": {}
}
```

## Failure

```json
{
  "requestId": "uuid",
  "ok": false,
  "error": {
    "code": "PERMISSION_DENIED | INVALID_PARAMS | NOT_FOUND | NOT_SUPPORTED | CANCELLED | INTERNAL_ERROR",
    "message": "..."
  }
}
```

## Namespaces

### `storage`

- `get({ key })`
- `set({ key, value })`
- `remove({ key })`
- `clear({})`

Values must be JSON-safe. Storage is isolated by `appId`.

### `secureStorage`

- `get({ key })`
- `set({ key, value })`
- `remove({ key })`
- `clear({})`

Values are strings and are isolated by `appId`.

### `notification`

- `requestPermission({})`
- `getPermissionStatus({})`
- `schedule({ id?, title, body, time })`
- `cancel({ id })`
- `cancelAll({})`

Requires manifest declaration and user runtime authorization.

### `network`

- `fetch({ url, options })`

Requires manifest declaration, user runtime authorization, HTTPS, and manifest host allowlist. This only applies to host-mediated `AppRuntime.network.fetch`; normal WebView resource loading and browser networking are not part of the bridge protocol.

### `app`

- `getManifest({})`
- `getPermissions({})`
- `getCapabilities({})`
- `getLocale({})`
- `getTheme({})`
- `getLifecycleState({})`

> Safe area is handled by the host via the manifest `immersive` block (see `app.json` schema). The host no longer exposes a runtime bridge for safe area or header visibility — they are decided declaratively.

### Native namespaces

- `device`: `getInfo`, `getNetworkStatus`, `getBatteryStatus`
- `ui`: `toast`, `alert`, `confirm`, `actionSheet`, `showLoading`, `hideLoading`
- `clipboard`: `readText`, `writeText`
- `share`: `text`, `files`
- `open`: `url`, `phone`, `email`, `map`, `settings`
- `file`: `pick`, `saveText`, `saveBase64`, `readBase64`, `share`
- `media`: `pickImage`, `pickVideo`, `captureImage`, `captureVideo`
- `location`: `getPermissionStatus`, `requestPermission`, `getCurrentPosition`
- `haptics`: `selection`, `light`, `medium`, `heavy`, `success`, `warning`, `error`, `vibrate`
- `barcode`: `scan`
- `audio`: `requestPermission`, `startRecording`, `stopRecording`, `play`, `stop`
- `biometric`: `canAuthenticate`, `authenticate`
- `contacts`: `requestPermission`, `pick`
- `calendar`: `addEvent`
- `download`: `file`
- `events`: `subscribe`, `unsubscribe`

Each namespace requires the matching manifest permission. Some capabilities also require user runtime authorization and platform system permission. Unsupported platforms return `NOT_SUPPORTED`.
