#!/usr/bin/env node
import { existsSync, readFileSync, statSync } from 'node:fs';
import { basename } from 'node:path';

const defaultBaseUrl = 'https://infra.308893.xyz';
const defaultAuth = process.env.IPROD_INFRA_AUTH || 'sanyi';

async function main() {
  const archivePath = process.argv[2];
  if (!archivePath || archivePath.startsWith('--')) {
    throw new Error('usage: upload_bundle.mjs <bundle.ipd> [--key name.ipd] [--base-url url] [--auth token]');
  }

  const options = parseOptions(process.argv.slice(3));
  if (!existsSync(archivePath) || !statSync(archivePath).isFile()) {
    throw new Error(`bundle archive not found: ${archivePath}`);
  }

  const key = options.key[0] || safeKey(basename(archivePath));
  const baseUrl = trimSlash(options['base-url'][0] || defaultBaseUrl);
  const auth = options.auth[0] || defaultAuth;
  const url = `${baseUrl}/api/r2/objects/${encodeURIComponent(key)}`;

  const response = await fetch(url, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/octet-stream',
      'X-Sanyi-INFRA': auth
    },
    body: readFileSync(archivePath)
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`upload failed: HTTP ${response.status} ${text}`);
  }

  const payload = text ? JSON.parse(text) : {};
  const downloadUrl = `${baseUrl}/api/r2/objects/${encodeURIComponent(key)}`;
  console.log(JSON.stringify({
    ok: true,
    key,
    upload: payload,
    downloadUrl
  }, null, 2));
}

function parseOptions(args) {
  const options = { key: [], 'base-url': [], auth: [] };
  for (let index = 0; index < args.length; index += 1) {
    const item = args[index];
    if (!item.startsWith('--')) {
      throw new Error(`unexpected argument: ${item}`);
    }
    const name = item.slice(2);
    if (!(name in options)) {
      throw new Error(`unsupported option: ${item}`);
    }
    const value = args[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`missing value for ${item}`);
    }
    options[name].push(value);
    index += 1;
  }
  return options;
}

function safeKey(value) {
  return value.replace(/[^a-zA-Z0-9._-]+/g, '-');
}

function trimSlash(value) {
  return value.replace(/\/+$/, '');
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exitCode = 1;
});
