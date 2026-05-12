const defaultLabel = 'automerge';

function parseArgs(argv) {
  const args = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith('--')) {
      throw new Error(`Unexpected argument: ${arg}`);
    }

    const key = arg.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`Missing value for --${key}`);
    }

    args[key] = value;
    index += 1;
  }

  return args;
}

function splitRepo(repo) {
  const [owner, name] = (repo || '').split('/');
  if (!owner || !name) {
    throw new Error(`Repository must be in owner/name form. Actual: ${repo || '(empty)'}`);
  }

  return { owner, name };
}

async function githubFetch(url, token, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Accept: 'application/vnd.github+json',
      Authorization: `Bearer ${token}`,
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'codex13-automerge-branch-updater',
      ...(options.headers || {}),
    },
  });

  const text = await response.text();
  let body = null;
  if (text.trim()) {
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
  }

  return { response, body };
}

async function graphql(token, query, variables) {
  const { response, body } = await githubFetch('https://api.github.com/graphql', token, {
    method: 'POST',
    body: JSON.stringify({ query, variables }),
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok || body?.errors?.length > 0) {
    throw new Error(`GitHub GraphQL request failed: ${response.status} ${JSON.stringify(body)}`);
  }

  return body.data;
}

async function listOpenPullRequests({ owner, name, token }) {
  const query = `
    query($owner: String!, $name: String!, $cursor: String) {
      repository(owner: $owner, name: $name) {
        pullRequests(first: 100, after: $cursor, states: OPEN, orderBy: { field: UPDATED_AT, direction: DESC }) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            number
            title
            isDraft
            baseRefName
            headRefName
            headRefOid
            headRepository {
              nameWithOwner
            }
            autoMergeRequest {
              enabledAt
            }
            labels(first: 50) {
              nodes {
                name
              }
            }
          }
        }
      }
    }
  `;

  const pullRequests = [];
  let cursor = null;
  do {
    const data = await graphql(token, query, { owner, name, cursor });
    const connection = data.repository.pullRequests;
    pullRequests.push(...connection.nodes);
    cursor = connection.pageInfo.hasNextPage ? connection.pageInfo.endCursor : null;
  } while (cursor);

  return pullRequests;
}

function isEligiblePullRequest(pr, { repo, baseBranch, label }) {
  const labels = (pr.labels?.nodes || []).map((node) => node.name.toLowerCase());
  const hasLabel = labels.includes(label.toLowerCase());
  const hasAutoMerge = Boolean(pr.autoMergeRequest);

  if (!hasAutoMerge && !hasLabel) {
    return { eligible: false, reason: `missing auto-merge and ${label} label` };
  }

  if (pr.isDraft) {
    return { eligible: false, reason: 'draft pull request' };
  }

  if (pr.baseRefName !== baseBranch) {
    return { eligible: false, reason: `base branch is ${pr.baseRefName}` };
  }

  if (pr.headRepository?.nameWithOwner !== repo) {
    return { eligible: false, reason: `head repository is ${pr.headRepository?.nameWithOwner || '(deleted)'}` };
  }

  return { eligible: true, reason: hasAutoMerge ? 'auto-merge enabled' : `${label} label` };
}

function isConflictLikeUpdateFailure(status, body) {
  const message = typeof body?.message === 'string' ? body.message.toLowerCase() : '';
  const errors = Array.isArray(body?.errors) ? body.errors : [];

  return (
    status === 409 ||
    (status === 422 &&
      (message.includes('merge conflict') ||
        message.includes('not mergeable') ||
        message.includes('validation failed') ||
        errors.some((error) => `${error.message || ''} ${error.code || ''}`.toLowerCase().includes('conflict'))))
  );
}

async function updatePullRequestBranch({ repo, token, pr, dryRun }) {
  if (dryRun) {
    console.log(`DRY-RUN: would update #${pr.number} (${pr.headRefName}) at ${pr.headRefOid}`);
    return { status: 'dry-run' };
  }

  const url = `https://api.github.com/repos/${repo}/pulls/${pr.number}/update-branch`;
  const { response, body } = await githubFetch(url, token, {
    method: 'PUT',
    body: JSON.stringify({ expected_head_sha: pr.headRefOid }),
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (response.status === 202) {
    console.log(`UPDATED: #${pr.number} ${pr.title}`);
    return { status: 'updated' };
  }

  if (response.status === 204) {
    console.log(`UNCHANGED: #${pr.number} ${pr.title}`);
    return { status: 'unchanged' };
  }

  if (response.status === 422 && `${body?.message || ''}`.toLowerCase().includes('expected head sha')) {
    console.log(`SKIPPED: #${pr.number} head changed before update completed.`);
    return { status: 'skipped' };
  }

  if (isConflictLikeUpdateFailure(response.status, body)) {
    console.log(`SKIPPED: #${pr.number} cannot be updated cleanly: ${body?.message || response.status}`);
    return { status: 'conflict' };
  }

  throw new Error(`Failed to update #${pr.number}: ${response.status} ${JSON.stringify(body)}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const repo = args.repo || process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  const baseBranch = args['base-branch'] || process.env.BASE_BRANCH || 'main';
  const label = args.label || process.env.AUTOMERGE_LABEL || defaultLabel;
  const dryRun = (args['dry-run'] || process.env.DRY_RUN || 'false').toLowerCase() === 'true';

  if (!token) {
    throw new Error('GITHUB_TOKEN or GH_TOKEN is required.');
  }

  const { owner, name } = splitRepo(repo);
  const pullRequests = await listOpenPullRequests({ owner, name, token });
  const summary = {
    checked: pullRequests.length,
    eligible: 0,
    updated: 0,
    unchanged: 0,
    skipped: 0,
    conflicts: 0,
    dryRuns: 0,
  };

  for (const pr of pullRequests) {
    const eligibility = isEligiblePullRequest(pr, { repo, baseBranch, label });
    if (!eligibility.eligible) {
      console.log(`SKIP: #${pr.number} ${pr.title} (${eligibility.reason})`);
      summary.skipped += 1;
      continue;
    }

    summary.eligible += 1;
    console.log(`CANDIDATE: #${pr.number} ${pr.title} (${eligibility.reason})`);
    const result = await updatePullRequestBranch({ repo, token, pr, dryRun });

    if (result.status === 'updated') summary.updated += 1;
    else if (result.status === 'unchanged') summary.unchanged += 1;
    else if (result.status === 'conflict') summary.conflicts += 1;
    else if (result.status === 'dry-run') summary.dryRuns += 1;
    else summary.skipped += 1;
  }

  console.log(
    `Summary: checked=${summary.checked}, eligible=${summary.eligible}, updated=${summary.updated}, unchanged=${summary.unchanged}, conflicts=${summary.conflicts}, dry-runs=${summary.dryRuns}, skipped=${summary.skipped}`,
  );
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exit(1);
});
