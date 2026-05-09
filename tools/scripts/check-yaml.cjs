#!/usr/bin/env node

const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const YAML = require('yaml');

const files = execFileSync('git', ['ls-files', '--', '*.yml', '*.yaml', 'CITATION.cff'], {
  encoding: 'utf8',
})
  .split(/\r?\n/)
  .filter(Boolean);

let hasErrors = false;

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8');
  if (/[�]|(?:Ĺ|Å)/u.test(source)) {
    hasErrors = true;
    console.error(`${file}:?:? EncodingError: file contains likely mojibake`);
    continue;
  }

  const document = YAML.parseDocument(source, {
    prettyErrors: true,
    strict: true,
    uniqueKeys: true,
  });

  const problems = [...document.errors, ...document.warnings];
  if (problems.length === 0) {
    continue;
  }

  hasErrors = true;
  for (const problem of problems) {
    const linePos = problem.linePos?.[0];
    const location = linePos ? `${linePos.line}:${linePos.col}` : '?:?';
    console.error(`${file}:${location} ${problem.name}: ${problem.message}`);
  }
}

if (hasErrors) {
  process.exit(1);
}

console.log(`YAML files checked: ${files.length}`);
