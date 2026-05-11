const fs = require('node:fs');
const path = require('node:path');

const semverTagPattern =
  /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$/;

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

function readText(relativePath) {
  return fs.readFileSync(path.join(process.cwd(), relativePath), 'utf8');
}

function writeGitHubOutput(values) {
  const outputPath = process.env.GITHUB_OUTPUT;
  if (!outputPath) {
    return;
  }

  const lines = Object.entries(values).map(([key, value]) => `${key}=${value}`);
  fs.appendFileSync(outputPath, `${lines.join('\n')}\n`, 'utf8');
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const releaseBranch = (args['release-branch'] || process.env.RELEASE_BRANCH || '').trim();
  const errors = [];

  if (!releaseBranch) {
    errors.push('Release branch is required.');
  }

  const branchMatch = releaseBranch.match(/^release\/(v.+)$/);
  const tag = branchMatch ? branchMatch[1] : '';

  if (!branchMatch || !semverTagPattern.test(tag)) {
    errors.push(`Release branch must match release/v<semver>. Actual: ${releaseBranch}`);
  }

  const version = tag ? tag.slice(1) : '';
  const versionCore = version ? version.split(/[-+]/, 1)[0] : '';

  if (version) {
    const packageJson = JSON.parse(readText('package.json'));
    if (packageJson.version !== version) {
      errors.push(
        `package.json version (${packageJson.version}) must match release tag version (${version}).`,
      );
    }

    const config = readText('apps/setup/src/nsis/config.nsh');
    const appVersionMatch = config.match(/^\s*!define\s+APP_VERSION\s+"([^"]+)"/m);
    if (!appVersionMatch) {
      errors.push('Cannot read APP_VERSION from apps/setup/src/nsis/config.nsh.');
    } else if (appVersionMatch[1] !== versionCore) {
      errors.push(`APP_VERSION (${appVersionMatch[1]}) must match release version core (${versionCore}).`);
    }

    const changelog = readText('CHANGELOG.md');
    const headingPattern = new RegExp(`^## .*\\[${version.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\]`, 'm');
    if (!headingPattern.test(changelog)) {
      errors.push(`CHANGELOG.md must contain a section for ${version}.`);
    }
  }

  if (errors.length > 0) {
    console.error('ERROR: Release state check failed.');
    for (const error of errors) {
      console.error(`- ${error}`);
    }
    process.exit(1);
  }

  writeGitHubOutput({ tag, version });
  console.log(`Release state check passed for ${tag}.`);
}

main();
