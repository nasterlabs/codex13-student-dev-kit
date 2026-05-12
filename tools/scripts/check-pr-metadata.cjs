const allowedBranchPattern =
  /^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)\/[a-z0-9][a-z0-9._-]*$/;
const allowedReleaseBranchPattern =
  /^release\/v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$/;
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
  !allowedReleaseBranchPattern.test(headRef) &&
  !allowedBotBranchPattern.test(headRef)
) {
  errors.push(
    `Branch name must match <type>/<name> using a conventional type or release/v<semver>. Actual: ${headRef}`,
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
  const lines = text.split('\n');
  let start = -1;
  let end = lines.length;

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const match = line.match(/^##\s+(.+?)\s*$/);
    if (!match) {
      continue;
    }

    const normalizedHeading = match[1].replace(/^[^A-Za-z0-9]+/, '').trim();
    if (start < 0 && normalizedHeading === heading) {
      start = index + 1;
      continue;
    }

    if (start >= 0) {
      end = index;
      break;
    }
  }

  return start >= 0 ? lines.slice(start, end).join('\n').trim() : '';
}

const summary = getSection(normalizedBody, 'Summary');
if (!summary || /^-\s*$/.test(summary)) {
  errors.push('Pull request body must include a non-placeholder Summary section.');
}

function getNonEmptyLines(section) {
  return section
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
}

const verification = getSection(normalizedBody, 'Verification');
if (!verification) {
  errors.push('Pull request body must include a Verification section.');
} else {
  const verificationLines = getNonEmptyLines(verification);
  const checklistLines = verificationLines.filter((line) => /^- \[[ xX]\] .+/.test(line));
  const checkedLines = checklistLines.filter((line) => /^- \[[xX]\] .+/.test(line));

  if (checklistLines.length === 0) {
    errors.push('Pull request body Verification section must use checklist items.');
  }

  if (checkedLines.length === 0) {
    errors.push(
      'Pull request body Verification section must include at least one completed checklist item.',
    );
  }

  for (const line of checkedLines) {
    if (/^- \[[xX]\]\s+(task|pnpm|git|pwsh|node|gh|act)\b/.test(line)) {
      errors.push(`Verification command must be wrapped in backticks: ${line}`);
    }
  }
}

const notes = getSection(normalizedBody, 'Notes');
if (!notes) {
  errors.push('Pull request body must include a Notes section.');
} else {
  const noteLines = getNonEmptyLines(notes);
  if (noteLines.length === 0) {
    errors.push('Pull request body Notes section must include checklist items or explicit notes.');
  }

  const malformedChecklistLines = noteLines.filter((line) => line.startsWith('- [') && !/^- \[[ xX]\] .+/.test(line));
  for (const line of malformedChecklistLines) {
    errors.push(`Notes checklist item is malformed: ${line}`);
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
