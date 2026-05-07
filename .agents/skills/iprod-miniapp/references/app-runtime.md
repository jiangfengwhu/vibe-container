# AppRuntime API

所有 API 都返回 Promise。

```ts
declare global {
  interface Window {
    AppRuntime: {
      storage: {
        get<T = unknown>(key: string): Promise<T | null | undefined>;
        set(key: string, value: unknown): Promise<{ ok: true }>;
        remove(key: string): Promise<{ ok: true }>;
        clear(): Promise<{ ok: true }>;
      };
      secureStorage: {
        get(key: string): Promise<string | null | undefined>;
        set(key: string, value: string): Promise<{ ok: true }>;
        remove(key: string): Promise<{ ok: true }>;
        clear(): Promise<{ ok: true }>;
      };
      notification: {
        requestPermission(): Promise<{ granted: boolean }>;
        getPermissionStatus(): Promise<{ granted: boolean }>;
        schedule(options: {
          id?: number;
          title: string;
          body: string;
          time: string;
        }): Promise<Record<string, unknown>>;
        cancel(id: number): Promise<{ ok: true }>;
        cancelAll(): Promise<{ ok: true }>;
      };
      network: {
        fetch(url: string, options?: {
          method?: 'GET' | 'POST';
          headers?: Record<string, string>;
          body?: string;
        }): Promise<{
          status: number;
          headers: Record<string, string>;
          body: string;
        }>;
      };
      app: {
        getManifest(): Promise<Record<string, unknown>>;
        getPermissions(): Promise<Record<string, boolean>>;
        getCapabilities(): Promise<Record<string, unknown>>;
        getLocale(): Promise<Record<string, unknown>>;
        getTheme(): Promise<Record<string, unknown>>;
        getLifecycleState(): Promise<Record<string, unknown>>;
      };
      device: {
        getInfo(): Promise<Record<string, unknown>>;
        getNetworkStatus(): Promise<Record<string, unknown>>;
        getBatteryStatus(): Promise<Record<string, unknown>>;
      };
      ui: {
        toast(message: string, options?: Record<string, unknown>): Promise<{ ok: true }>;
        alert(options: { title?: string; message?: string; buttonText?: string }): Promise<{ ok: true }>;
        confirm(options: { title?: string; message?: string; confirmText?: string; cancelText?: string }): Promise<{ accepted: boolean }>;
        actionSheet(options: { options: string[] }): Promise<{ selectedIndex?: number; selected?: string }>;
        showLoading(options?: { message?: string }): Promise<{ ok: true }>;
        hideLoading(): Promise<{ ok: true }>;
      };
      clipboard: {
        readText(): Promise<{ text?: string }>;
        writeText(text: string): Promise<{ ok: true }>;
      };
      share: {
        text(options: { text: string; title?: string; subject?: string }): Promise<Record<string, unknown>>;
        files(options: { paths: string[]; text?: string; title?: string; subject?: string }): Promise<Record<string, unknown>>;
      };
      open: {
        url(url: string): Promise<{ opened: boolean }>;
        phone(number: string): Promise<{ opened: boolean }>;
        email(options: { to: string; subject?: string; body?: string }): Promise<{ opened: boolean }>;
        map(options: { latitude: number; longitude: number; label?: string }): Promise<{ opened: boolean }>;
        settings(): Promise<{ opened: boolean }>;
      };
      file: Record<string, (...args: unknown[]) => Promise<unknown>>;
      media: Record<string, (...args: unknown[]) => Promise<unknown>>;
      location: Record<string, (...args: unknown[]) => Promise<unknown>>;
      haptics: Record<string, () => Promise<{ ok: true }>>;
      barcode: { scan(options?: Record<string, unknown>): Promise<{ value: string }> };
      audio: Record<string, (...args: unknown[]) => Promise<unknown>>;
      biometric: Record<string, (...args: unknown[]) => Promise<unknown>>;
      contacts: Record<string, (...args: unknown[]) => Promise<unknown>>;
      calendar: Record<string, (...args: unknown[]) => Promise<unknown>>;
      download: Record<string, (...args: unknown[]) => Promise<unknown>>;
      events: {
        on(type: string, listener: (payload: Record<string, unknown>) => void): () => void;
      };
    };
  }
}
```

错误以 Promise reject 形式抛出：

```json
{
  "code": "PERMISSION_DENIED | INVALID_PARAMS | NOT_FOUND | NOT_SUPPORTED | CANCELLED | INTERNAL_ERROR",
  "message": "..."
}
```

存储中的值请保持 JSON-safe，使用数组和对象，不要存类实例、函数、Date、Map、Set 或二进制 blob。

## SafeArea

mini app 会被加载进一个 edge-to-edge 的 WebView。**默认情况下宿主不渲染 chrome 顶栏，也不为顶部和底部留 SafeArea**，因此你的 HTML 会铺满整个屏幕，包括状态栏和底部 home 指示器之下的区域。SafeArea 必须由 mini app 自己处理。

通过 `app.json.immersive` 声明：

```json
"immersive": {
  "topInset": false,
  "bottomInset": false,
  "showHeader": false
}
```

三个字段默认都是 `false`。用户后续可以在宿主的"管理"页里覆盖每个 mini app 的设置，但你在编写 mini app 时应该按默认全沉浸来设计。

推荐的 CSS 基线（无论用户是否后续覆盖了 immersive 设置都安全）：

```css
:root {
  --safe-top: env(safe-area-inset-top, 0px);
  --safe-bottom: env(safe-area-inset-bottom, 0px);
  --safe-left: env(safe-area-inset-left, 0px);
  --safe-right: env(safe-area-inset-right, 0px);
}

html, body {
  min-height: 100dvh;
}

.app-shell {
  padding-top: max(16px, var(--safe-top));
  padding-bottom: max(16px, var(--safe-bottom));
  padding-left: max(16px, var(--safe-left));
  padding-right: max(16px, var(--safe-right));
}

.bottom-bar {
  padding-bottom: max(12px, var(--safe-bottom));
}
```

补充说明：

- 宿主已经注入了 `<meta name="viewport" content="... viewport-fit=cover">`，在带刘海 / 灵动岛 / home 指示器的设备上 `env(safe-area-inset-*)` 会返回非 0 值，无需自己再加 viewport meta。
- 全屏布局请使用 `100dvh`（或 flex / grid 布局），不要使用 `100vh`，避免地址栏 / 手势条引起溢出。
- 如果 mini app 完全无法自适应 SafeArea，请把 `topInset` 和 / 或 `bottomInset` 设为 `true`，让宿主帮忙留白；不要直接忽略 SafeArea。
