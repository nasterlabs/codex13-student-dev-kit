const allowedBranchPattern =
  /^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)\/[a-z0-9][a-z0-9._-]*$/;
const allowedBotBranchPattern = /^(dependabot|renovate)\//;
const allowedDependencyBotAuthors = new Set(['dependabot[bot]', 'renovate[bot]']);

const author = (process.env.PR_AUTHOR || '').trim();
const headRef = (process.env.PR_HEAD_REF || '').trim();
const body = process.env.PR_BODY || '';

const errors = [];
const isDependencyBotPr =
  allowedBotBranchPattern.test(headRef) && allowedDependencyBotAuthors.has(author);

if (!headRef) {
  errors.push('Missing PR_HEAD_REF.');
} else if (
  !allowedBranchPattern.test(headRef) &&
  !allowedBotBranchPattern.test(headRef)
) {
  errors.push(
    `Branch name must match <type>/<name> using a conventional type. Actual: ${headRef}`,
  );
}

const normalizedBody = body.replace(/\r\n/g, '\n').trim();
if (!normalizedBody) {
  errors.push('Pull request body must not be empty.');
}

if (isDependencyBotPr && normalizedBody) {
  console.log('Dependency bot PR metadata check passed.');
  process.exit(0);
}

function getSection(text, heading) {
  const pattern = new RegExp(
    `^## ${heading}\\s*\\n([\\s\\S]*?)(?=\\n##\\s+|$)`,
    'm',
  );
  const match = text.match(pattern);
  return match ? match[1].trim() : '';
}

const summary = getSection(normalizedBody, 'Summary');
if (!summary || /^-\s*$/.test(summary)) {
  errors.push('Pull request body must include a non-placeholder Summary section.');
}

const verification = getSection(normalizedBody, 'Verification');
if (!verification) {
  errors.push('Pull request body must include a Verification section.');
} else {
  const meaningfulVerificationLines = verification
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line) => !/^- \[ \] /.test(line));

  if (meaningfulVerificationLines.length === 0) {
    errors.push(
      'Pull request body Verification section must include completed checks or explicit verification notes.',
    );
  }
}

if (errors.length > 0) {
  console.error('ERROR: Pull request metadata check failed.');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log('Pull request metadata check passed.');
