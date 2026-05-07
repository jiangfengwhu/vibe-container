# app.json

`app.json` is required. It controls metadata, versioning, permissions, network allowlist, and the HTML entry loaded by the host.

Minimal storage app:

```json
{
  "id": "user.todo",
  "name": "Todo",
  "version": "1.0.0",
  "description": "A local todo list.",
  "icon": "T",
  "entry": "index.html",
  "permissions": ["storage"],
  "createdAt": "2026-05-07T00:00:00Z",
  "runtimeVersion": "1.0",
  "networkAllowlist": [],
  "signature": null
}
```

Network app:

```json
{
  "id": "user.weather",
  "name": "Weather",
  "version": "1.0.0",
  "description": "Fetches weather from an allowlisted API.",
  "icon": "W",
  "entry": "index.html",
  "permissions": ["storage", "network"],
  "createdAt": "2026-05-07T00:00:00Z",
  "runtimeVersion": "1.0",
  "networkAllowlist": ["api.example.com"],
  "signature": null
}
```

Rules:

- `id` must match `^[a-zA-Z0-9][a-zA-Z0-9._-]{2,63}$`.
- `entry` must be a relative local HTML path, usually `index.html`.
- `permissions` may include `storage`, `secureStorage`, `notification`, `network`, `device`, `ui`, `clipboard`, `share`, `open`, `file`, `media`, `location`, `haptics`, `barcode`, `audio`, `biometric`, `contacts`, `calendar`, `download`, and `events`.
- `networkAllowlist` contains host names only, not URLs.
- `signature` is reserved and should be `null` in MVP.
