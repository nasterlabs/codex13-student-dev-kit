const fs = require('node:fs');
const { spawnSync } = require('node:child_process');

const messagePath = process.argv[2];
if (!messagePath) {
  console.error('ERROR: Missing commit message path.');
  process.exit(1);
}

const message = fs.readFileSync(messagePath, 'utf8');
const trailers = message
  .split(/\r?\n/)
  .map((line) => line.match(/^Signed-off-by: (.+?) <([^>]+)>$/))
  .filter(Boolean)
  .map((match) => ({ name: match[1].trim(), email: match[2].trim() }));

if (trailers.length === 0) {
  console.error('ERROR: Missing DCO Signed-off-by trailer.');
  console.error('Fix: git commit -s --amend');
  process.exit(1);
}

const authorResult = spawnSync('git', ['var', 'GIT_AUTHOR_IDENT'], {
  encoding: 'utf8',
  stdio: 'pipe',
});

if (authorResult.status !== 0) {
  console.error('ERROR: Cannot read Git author identity.');
  if (authorResult.stderr) {
    console.error(authorResult.stderr.trim());
  }
  process.exit(authorResult.status || 1);
}

const authorMatch = authorResult.stdout
  .trim()
  .match(/^(.+) <([^>]+)> \d+ [+-]\d+$/);

if (!authorMatch) {
  console.error('ERROR: Cannot parse Git author identity.');
  console.error(authorResult.stdout.trim());
  process.exit(1);
}

const author = {
  name: authorMatch[1].trim(),
  email: authorMatch[2].trim(),
};

const hasAuthorSignOff = trailers.some(
  (trailer) => trailer.email.toLowerCase() === author.email.toLowerCase(),
);

if (!hasAuthorSignOff) {
  console.error('ERROR: DCO Signed-off-by trailer does not match commit author.');
  console.error(`Author: ${author.name} <${author.email}>`);
  console.error(
    `Signed-off-by: ${trailers
      .map((trailer) => `${trailer.name} <${trailer.email}>`)
      .join(', ')}`,
  );
  console.error('Fix: git commit -s --amend');
  process.exit(1);
}
