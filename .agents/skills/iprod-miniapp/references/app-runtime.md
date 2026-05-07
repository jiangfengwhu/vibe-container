# AppRuntime API

All APIs return Promises.

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
        getSafeArea(): Promise<Record<string, unknown>>;
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
        setHeaderVisible(visible: boolean): Promise<{ visible: boolean }>;
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

Errors reject the Promise with:

```json
{
  "code": "PERMISSION_DENIED | INVALID_PARAMS | NOT_FOUND | NOT_SUPPORTED | CANCELLED | INTERNAL_ERROR",
  "message": "..."
}
```

Prefer small JSON-safe values in storage. Use arrays and objects, not class instances, functions, Dates, Maps, Sets, or binary blobs.
