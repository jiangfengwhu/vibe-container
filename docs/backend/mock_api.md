# Backend Mock API

The first MVP does not call a real coding agent. This document defines the API contract reserved for the future generation backend.

## Generate App

`POST /apps/generate`

Request:

```json
{
  "prompt": "I want a local habit tracker with reminders",
  "style": "clean utility",
  "capabilities": ["storage", "notification"]
}
```

Response:

```json
{
  "jobId": "job_01HZY7Y9W8WQZ",
  "status": "queued"
}
```

## Poll Generation Job

`GET /apps/generate/:jobId`

Running response:

```json
{
  "status": "running",
  "bundleUrl": null,
  "logs": [
    "Scaffolding standard web mini app template",
    "Generating bundle implementation"
  ]
}
```

Succeeded response:

```json
{
  "status": "succeeded",
  "bundleUrl": "https://example.invalid/bundles/local.checkin.zip",
  "logs": [
    "Generated app.json",
    "Validated bridge API usage",
    "Allowed remote Web resources",
    "Packed bundle"
  ]
}
```

Failed response:

```json
{
  "status": "failed",
  "bundleUrl": null,
  "logs": [
    "Generation failed validation: missing app.json"
  ]
}
```

## Future Pipeline

```text
User prompt
  -> generation API
  -> professional coding agent
  -> standard web app template
  -> automated tests
  -> static security scan
  -> app.json validation
  -> bundle package
  -> optional signature
  -> mobile host import
```

Security gates before bundle delivery:

- Validate `app.json` against the shared schema.
- Allow remote scripts and external assets; AI-generated bundles may depend on CDN resources.
- Check requested bridge APIs against manifest permissions.
- Run generated app tests in a browser harness.
- Reserve or verify `signature` once bundle signing is introduced.
