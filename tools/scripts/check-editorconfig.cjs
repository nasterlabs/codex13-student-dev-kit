const { execFileSync } = require('node:child_process');
const path = require('node:path');

const root = path.resolve(__dirname, '..', '..');
const eclint = require.resolve('eclint/bin/eclint.js');

const trackedFiles = execFileSync('git', ['ls-files'], {
  cwd: root,
  encoding: 'utf8',
})
  .split(/\r?\n/)
  .filter(Boolean);

const checkableExtensions = new Set([
  '.c',
  '.cjs',
  '.cmd',
  '.cpp',
  '.filters',
  '.gitattributes',
  '.gitignore',
  '.h',
  '.hpp',
  '.ini',
  '.js',
  '.json',
  '.nsh',
  '.nsi',
  '.npmrc',
  '.php',
  '.ps1',
  '.psd1',
  '.rc',
  '.svg',
  '.vcxproj',
  '.xml',
  '.yaml',
  '.yml',
]);

const checkableNames = new Set([
  '.editorconfig',
  'Taskfile.yml',
  'commitlint.config.cjs',
  'package.json',
  'pnpm-workspace.yaml',
]);

function isCheckable(file) {
  if (file.startsWith('apps/setup/vendor/')) return false;
  if (file.startsWith('apps/setup/assets/')) return false;
  if (file.startsWith('apps/setup/src/patches/')) return false;
  if (file.startsWith('assets/')) return false;
  if (file.startsWith('packages/nsis-naster-archive/src/nsis-plugin-api/')) return false;
  if (file.startsWith('dist/')) return false;
  if (file.startsWith('.build/')) return false;
  if (file === 'pnpm-lock.yaml') return false;
  // eclint hangs on this PowerShell generator in Node 24; repository checks
  // still validate it as a required tracked file and execute it directly.
  if (file === 'tools/scripts/write-release-manifest.ps1') return false;

  const base = path.posix.basename(file);
  if (checkableNames.has(file) || checkableNames.has(base)) return true;

  return checkableExtensions.has(path.posix.extname(file));
}

const files = trackedFiles.filter(isCheckable);
const batchSize = 50;

for (let index = 0; index < files.length; index += batchSize) {
  const batch = files.slice(index, index + batchSize);
  execFileSync(process.execPath, [eclint, 'check', ...batch], {
    cwd: root,
    stdio: 'inherit',
  });
}
