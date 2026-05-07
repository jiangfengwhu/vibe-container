#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';

const allowedPermissions = new Set([
  'storage',
  'secureStorage',
  'notification',
  'network',
  'device',
  'ui',
  'clipboard',
  'share',
  'open',
  'file',
  'media',
  'location',
  'haptics',
  'barcode',
  'audio',
  'biometric',
  'contacts',
  'calendar',
  'download',
  'events'
]);

function main() {
  const [command, ...args] = process.argv.slice(2);
  try {
    if (command === 'create') {
      createBundle(args);
    } else if (command === 'validate') {
      const manifest = validateBundle(requiredArg(args, 0, 'directory'));
      console.log(`OK ${manifest.id} ${manifest.version}`);
    } else if (command === 'pack') {
      console.log(packBundle(args));
    } else if (command === 'inspect') {
      inspectArchive(requiredArg(args, 0, 'archive'));
    } else {
      throw new Error('usage: iprod_bundle.mjs create|validate|pack|inspect ...');
    }
  } catch (error) {
    console.error(`ERROR: ${error.message}`);
    process.exitCode = 1;
  }
}

function createBundle(args) {
  const directory = requiredArg(args, 0, 'directory');
  const options = parseOptions(args.slice(1));
  const id = requiredOption(options, 'id');
  const name = requiredOption(options, 'name');
  const permissions = unique(options.permission.length ? options.permission : ['storage']);
  for (const permission of permissions) {
    if (!allowedPermissions.has(permission)) {
      throw new Error(`unsupported permission: ${permission}`);
    }
  }
  mkdirSync(directory, { recursive: true });
  writeFileSync(
    join(directory, 'app.json'),
    `${JSON.stringify(defaultManifest({
      id,
      name,
      description: options.description[0] || 'A local mini app.',
      icon: options.icon[0] || '*',
      permissions
    }), null, 2)}\n`
  );
  writeFileSync(join(directory, 'index.html'), starterHtml());
  console.log(directory);
}

function validateBundle(directory) {
  const root = resolve(directory);
  if (!existsSync(root) || !statSync(root).isDirectory()) {
    throw new Error(`bundle directory not found: ${root}`);
  }
  const manifest = readManifest(root);
  validateManifest(manifest);
  const entryPath = join(root, manifest.entry);
  if (!existsSync(entryPath)) {
    throw new Error(`entry file does not exist: ${manifest.entry}`);
  }

  const indexHtml = readFileSync(entryPath, 'utf8');
  const jsSource = walk(root)
    .filter((path) => path.endsWith('.js'))
    .map((path) => readFileSync(path, 'utf8'))
    .join('\n');

  const used = detectBridgeUsage(`${indexHtml}\n${jsSource}`);
  const declared = new Set(manifest.permissions || []);
  const missing = [...used].filter((permission) => !declared.has(permission));
  if (missing.length) {
    throw new Error(`bridge usage requires missing permissions: ${missing.sort().join(', ')}`);
  }
  if (declared.has('network') && (!manifest.networkAllowlist || manifest.networkAllowlist.length === 0)) {
    throw new Error('network permission requires non-empty networkAllowlist');
  }
  return manifest;
}

function packBundle(args) {
  const directory = requiredArg(args, 0, 'directory');
  const options = parseOptions(args.slice(1));
  const manifest = validateBundle(directory);
  const output = options.out[0] || join('dist', `${safeFileName(manifest.id)}.ipd`);
  mkdirSync(dirname(resolve(output)), { recursive: true });
  const result = spawnSync('zip', ['-qr', resolve(output), '.'], {
    cwd: resolve(directory),
    stdio: 'inherit'
  });
  if (result.status !== 0) {
    throw new Error('zip command failed');
  }
  return output;
}

function inspectArchive(archivePath) {
  if (!existsSync(archivePath)) {
    throw new Error(`archive not found: ${archivePath}`);
  }
  const manifestResult = spawnSync('unzip', ['-p', archivePath, 'app.json'], {
    encoding: 'utf8'
  });
  if (manifestResult.status === 0 && manifestResult.stdout.trim()) {
    console.log(JSON.stringify(JSON.parse(manifestResult.stdout), null, 2));
    return;
  }
  throw new Error('archive is missing app.json');
}

function readManifest(root) {
  const manifestPath = join(root, 'app.json');
  if (!existsSync(manifestPath)) {
    throw new Error('missing required file: app.json');
  }
  return JSON.parse(readFileSync(manifestPath, 'utf8'));
}

function validateManifest(manifest) {
  for (const key of ['id', 'name', 'version', 'description', 'icon', 'entry', 'permissions', 'createdAt', 'runtimeVersion']) {
    if (!(key in manifest)) {
      throw new Error(`app.json missing field: ${key}`);
    }
  }
  if (!/^[a-zA-Z0-9][a-zA-Z0-9._-]{2,63}$/.test(manifest.id)) {
    throw new Error('manifest id must be 3-64 safe characters');
  }
  if (typeof manifest.name !== 'string' || manifest.name.trim() === '' || manifest.name.length > 80) {
    throw new Error('manifest name must be non-empty and <= 80 chars');
  }
  if (typeof manifest.description !== 'string' || manifest.description.length > 240) {
    throw new Error('manifest description must be <= 240 chars');
  }
  if (
    typeof manifest.entry !== 'string' ||
    manifest.entry.startsWith('/') ||
    manifest.entry.includes('..') ||
    manifest.entry.startsWith('http://') ||
    manifest.entry.startsWith('https://') ||
    !manifest.entry.toLowerCase().endsWith('.html')
  ) {
    throw new Error('manifest entry must be a relative local html path');
  }
  if (!Array.isArray(manifest.permissions) || manifest.permissions.some((item) => typeof item !== 'string')) {
    throw new Error('manifest permissions must be a string array');
  }
  const unsupported = manifest.permissions.filter((permission) => !allowedPermissions.has(permission));
  if (unsupported.length) {
    throw new Error(`unsupported permissions: ${unsupported.sort().join(', ')}`);
  }
  const allowlist = manifest.networkAllowlist || [];
  if (!Array.isArray(allowlist) || allowlist.some((host) => typeof host !== 'string' || !/^[a-zA-Z0-9.-]+$/.test(host))) {
    throw new Error('networkAllowlist must contain host names only');
  }
  if (Number.isNaN(Date.parse(manifest.createdAt))) {
    throw new Error('createdAt must be ISO-8601');
  }
  if (manifest.immersive !== undefined && manifest.immersive !== null) {
    if (typeof manifest.immersive !== 'object' || Array.isArray(manifest.immersive)) {
      throw new Error('immersive must be an object');
    }
    for (const key of ['topInset', 'bottomInset', 'showHeader']) {
      if (manifest.immersive[key] !== undefined && typeof manifest.immersive[key] !== 'boolean') {
        throw new Error(`immersive.${key} must be a boolean`);
      }
    }
  }
}

function detectBridgeUsage(source) {
  const usage = new Set();
  for (const permission of allowedPermissions) {
    if (source.includes(`AppRuntime.${permission}.`)) {
      usage.add(permission);
    }
  }
  return usage;
}

function defaultManifest({ id, name, description, icon, permissions }) {
  return {
    id,
    name,
    version: '1.0.0',
    description,
    icon,
    entry: 'index.html',
    permissions,
    createdAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
    runtimeVersion: '1.0',
    networkAllowlist: [],
    signature: null,
    immersive: {
      topInset: false,
      bottomInset: false,
      showHeader: false
    }
  };
}

function starterHtml() {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Mini App</title>
  <style>
    body { margin: 0; min-height: 100vh; background: #f6f7f4; color: #17201d; font: 16px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    .shell { width: min(720px, 100%); margin: 0 auto; padding: 20px; }
    form { display: grid; grid-template-columns: 1fr auto; gap: 10px; margin: 18px 0; }
    input, button { min-height: 44px; border-radius: 8px; font: inherit; }
  </style>
</head>
<body>
  <main class="shell">
    <h1 id="title"></h1>
    <form id="form">
      <input id="itemInput" placeholder="Add an item" required>
      <button type="submit">Add</button>
    </form>
    <ul id="items"></ul>
  </main>
  <script>
    (function () {
      const title = document.getElementById('title');
      const form = document.getElementById('form');
      const input = document.getElementById('itemInput');
      const items = document.getElementById('items');
      let state = [];
      function render() {
        title.textContent = 'Mini App';
        items.innerHTML = '';
        state.forEach(function (item) {
          const row = document.createElement('li');
          row.textContent = item;
          items.appendChild(row);
        });
      }
      async function save() {
        await AppRuntime.storage.set('items', state);
        render();
      }
      form.addEventListener('submit', async function (event) {
        event.preventDefault();
        state.push(input.value.trim());
        input.value = '';
        await save();
      });
      AppRuntime.storage.get('items').then(function (value) {
        state = Array.isArray(value) ? value : [];
        render();
      });
    })();
  </script>
</body>
</html>
`;
}

function parseOptions(args) {
  const options = { id: [], name: [], description: [], icon: [], permission: [], out: [] };
  for (let index = 0; index < args.length; index += 1) {
    const key = args[index];
    if (!key.startsWith('--')) {
      continue;
    }
    const name = key.slice(2);
    if (!(name in options)) {
      throw new Error(`unsupported option: ${key}`);
    }
    const value = args[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`missing value for ${key}`);
    }
    options[name].push(value);
    index += 1;
  }
  return options;
}

function walk(directory) {
  const result = [];
  for (const name of readdirSync(directory)) {
    const path = join(directory, name);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      result.push(...walk(path));
    } else if (stat.isFile()) {
      result.push(path);
    }
  }
  return result;
}

function requiredArg(args, index, name) {
  if (!args[index]) {
    throw new Error(`missing ${name}`);
  }
  return args[index];
}

function requiredOption(options, name) {
  const value = options[name][0];
  if (!value) {
    throw new Error(`missing --${name}`);
  }
  return value;
}

function unique(values) {
  return [...new Set(values)];
}

function safeFileName(value) {
  return value.replace(/[^a-zA-Z0-9._-]+/g, '-');
}

main();
