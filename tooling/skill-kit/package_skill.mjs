#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';

function main() {
  const [source = '.agents/skills/iprod-miniapp', output = `dist/${basename(source)}-skill.zip`] =
    process.argv.slice(2);
  const sourcePath = resolve(source);
  const outputPath = resolve(output);

  if (!existsSync(sourcePath)) {
    console.error(`ERROR: skill directory not found: ${source}`);
    process.exit(1);
  }

  mkdirSync(dirname(outputPath), { recursive: true });
  const result = spawnSync('zip', ['-qr', outputPath, basename(sourcePath)], {
    cwd: dirname(sourcePath),
    stdio: 'inherit',
  });
  if (result.status !== 0) {
    console.error('ERROR: zip command failed');
    process.exit(result.status || 1);
  }
  console.log(output);
}

main();
