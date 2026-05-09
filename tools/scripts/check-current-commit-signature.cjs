const { spawnSync } = require('node:child_process');

const result = spawnSync('git', ['verify-commit', 'HEAD'], {
  encoding: 'utf8',
  stdio: 'pipe',
});

if (result.status === 0) {
  process.exit(0);
}

const details = `${result.stdout || ''}${result.stderr || ''}`.trim();
console.error('ERROR: Commit signature could not be verified.');
if (details) {
  console.error(details);
}
console.error('Fix: git commit --amend --no-edit -S');
process.exit(result.status || 1);
