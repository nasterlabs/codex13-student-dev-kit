const fs = require('node:fs');

const messagePath = process.argv[2];
if (!messagePath) {
  console.error('ERROR: Missing commit message path.');
  process.exit(1);
}

const message = fs.readFileSync(messagePath, 'utf8');
const hasDcoTrailer = message
  .split(/\r?\n/)
  .some((line) => /^Signed-off-by: .+ <[^>]+>$/.test(line));

if (!hasDcoTrailer) {
  console.error('ERROR: Missing DCO Signed-off-by trailer.');
  console.error('Fix: git commit -s --amend');
  process.exit(1);
}
