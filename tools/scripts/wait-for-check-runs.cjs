const defaultIntervalSeconds = 15;
const defaultTimeoutSeconds = 900;

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

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

function latestByName(checkRuns) {
  const latest = new Map();

  for (const run of checkRuns) {
    const current = latest.get(run.name);
    const runTime = Date.parse(run.started_at || run.created_at || 0);
    const currentTime = current ? Date.parse(current.started_at || current.created_at || 0) : -1;

    if (!current || runTime >= currentTime) {
      latest.set(run.name, run);
    }
  }

  return latest;
}

async function getCheckRuns(repo, sha, token) {
  const url = `https://api.github.com/repos/${repo}/commits/${sha}/check-runs?per_page=100`;
  const response = await fetch(url, {
    headers: {
      Accept: 'application/vnd.github+json',
      Authorization: `Bearer ${token}`,
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'codex13-release-check-gate',
    },
  });

  if (!response.ok) {
    throw new Error(`GitHub check-runs request failed: ${response.status} ${await response.text()}`);
  }

  return (await response.json()).check_runs || [];
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const repo = args.repo || process.env.GITHUB_REPOSITORY;
  const sha = args.sha;
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  const required = (args.required || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  const timeoutSeconds = Number(args['timeout-seconds'] || defaultTimeoutSeconds);
  const intervalSeconds = Number(args['interval-seconds'] || defaultIntervalSeconds);
  const deadline = Date.now() + timeoutSeconds * 1000;

  if (!repo) {
    throw new Error('Repository is required.');
  }

  if (!sha) {
    throw new Error('Commit SHA is required.');
  }

  if (!token) {
    throw new Error('GITHUB_TOKEN or GH_TOKEN is required.');
  }

  if (required.length === 0) {
    throw new Error('At least one required check name is required.');
  }

  while (Date.now() <= deadline) {
    const runsByName = latestByName(await getCheckRuns(repo, sha, token));
    const missing = [];
    const pending = [];
    const failed = [];

    for (const name of required) {
      const run = runsByName.get(name);

      if (!run) {
        missing.push(name);
        continue;
      }

      if (run.status !== 'completed') {
        pending.push(`${name} (${run.status})`);
        continue;
      }

      if (run.conclusion !== 'success') {
        failed.push(`${name} (${run.conclusion})`);
      }
    }

    if (failed.length > 0) {
      throw new Error(`Required checks failed for ${sha}: ${failed.join(', ')}`);
    }

    if (missing.length === 0 && pending.length === 0) {
      console.log(`Required checks passed for ${sha}: ${required.join(', ')}`);
      return;
    }

    console.log(
      `Waiting for required checks on ${sha}. Missing: ${missing.join(', ') || 'none'}. Pending: ${pending.join(', ') || 'none'}.`,
    );
    await sleep(intervalSeconds * 1000);
  }

  throw new Error(`Timed out waiting for required checks on ${sha}: ${required.join(', ')}`);
}

main().catch((error) => {
  console.error(`ERROR: ${error.message}`);
  process.exit(1);
});
