---
name: iprod-miniapp
description: Generate, validate, and package Local App Workbench web mini app bundles for import into the Flutter host app. Use when the user asks Codex to create an app, mini app, tool, widget, local web app, or .iprod.zip bundle that should run inside Local App Workbench.
---

# iProd Mini App

Build one local-first web mini app bundle that can be imported by Local App Workbench.

## Output Contract

Create a bundle directory whose root contains `app.json` and the HTML file referenced by `app.json.entry`. Other files are optional and must be referenced from the entry HTML with relative paths:

```text
app.json             # required metadata, version, permissions, entry
index.html/main.html # required entry HTML named by app.json.entry
any CSS/JS/assets referenced by the entry HTML
```

Then produce a packed artifact:

```text
dist/<app-id>.iprod.zip
```

The zip root must contain `app.json`, not an extra wrapper folder.

## Workflow

1. Create a workspace directory under `generated-bundles/<slug>/`.
2. Implement the app as a standalone web bundle. Local files and remote CDN resources are both allowed; if you use a build tool, include the generated files in the bundle.
   - The host loads the HTML path from `app.json.entry`.
   - CSS, JS, images, and assets are optional; keep local relative links correct inside the entry HTML.
3. Design for the host runtime chrome. The host defaults to fully immersive: no chrome header, no top/bottom safe area padding. Declare what you need in `app.json.immersive` (`topInset`, `bottomInset`, `showHeader`); each defaults to `false`. The user can later override these per app from the Manage screen. When you opt out of insets, handle the safe area in CSS via `env(safe-area-inset-top)` / `env(safe-area-inset-bottom)`.
4. Use `window.AppRuntime` for all host capabilities. Do not call native channels directly.
5. Keep data local-first. Use `AppRuntime.storage` for persistence.
6. Request only the permissions that are truly needed in `app.json`.
7. Run validation:

```bash
node scripts/iprod_bundle.mjs validate generated-bundles/<slug>
```

8. Pack:

```bash
node scripts/iprod_bundle.mjs pack generated-bundles/<slug> --out dist/<slug>.iprod.zip
```

9. Upload the packed archive. This is required; do not finish after packing only:

```bash
node scripts/upload_bundle.mjs dist/<slug>.iprod.zip --key <slug>.iprod.zip
```

10. Return the uploaded `downloadUrl` to the user. If validation, packing, or upload fails, fix the bundle and rerun validate/pack/upload before finishing.

## Manifest Rules

`app.json` is required and must include:

- `id`: safe stable id, usually `user.<slug>` or `local.<slug>`
- `name`
- `version`
- `description`
- `icon`: short text icon
- `entry`: relative local HTML path, usually `index.html`
- `permissions`: any of `storage`, `secureStorage`, `notification`, `network`, `device`, `ui`, `clipboard`, `share`, `open`, `file`, `media`, `location`, `haptics`, `barcode`, `audio`, `biometric`, `contacts`, `calendar`, `download`, `events`
- `createdAt`: ISO-8601
- `runtimeVersion`: `1.0`
- `networkAllowlist`: host names only
- `signature`: `null` for MVP
- `immersive` (optional): object `{ topInset?: bool, bottomInset?: bool, showHeader?: bool }`. Each field defaults to `false`. Set `topInset`/`bottomInset` to `true` only if the mini app cannot itself adapt to the status bar / home indicator; set `showHeader` to `true` if you want the host to render its back / refresh / manage chrome bar.

If the app calls:

- `AppRuntime.storage.*`, include `storage`
- `AppRuntime.secureStorage.*`, include `secureStorage`
- `AppRuntime.notification.*`, include `notification`
- `AppRuntime.network.*`, include `network` and a non-empty `networkAllowlist`
- `AppRuntime.<namespace>.*`, include the matching namespace permission for other native capabilities

## Security Rules

- No direct use of `AppRuntimeNative`.
- Remote CDN scripts, styles, fonts, images, and other Web resources are allowed.
- Browser networking such as `fetch`, `XMLHttpRequest`, WebSocket, and EventSource is allowed when the mini app needs it. Use `AppRuntime.network.fetch` only when you need host-mediated network calls and declare `network`.
- Do not assume browser `localStorage` is the durable app store. Use `AppRuntime.storage`.
- Avoid sensitive permissions unless requested.

## References

Load only when needed:

- `references/app-runtime.md` for the JS API.
- `references/app-json.md` for manifest examples.
- `scripts/iprod_bundle.mjs` for deterministic create/validate/pack/inspect commands.
- `scripts/upload_bundle.mjs` for uploading `.iprod.zip` archives to Cloudflare R2.
