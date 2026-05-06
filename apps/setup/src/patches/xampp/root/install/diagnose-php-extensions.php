<?php
declare(strict_types=1);

/**
 * Codex 13 / XAMPP PHP extension loader diagnostic.
 *
 * Installed for manual diagnostics only. Setup does not run this helper.
 * It checks PHP, php.ini, extension_dir and PHP extension DLL loading without
 * starting Apache or MySQL services.
 */

error_reporting(E_ALL);

function out(string $level, string $message): void
{
    printf("%-7s %s\n", $level, $message);
}

function norm(string $path): string
{
    return str_replace('\\', '/', $path);
}

$script = __FILE__;
$xamppRoot = realpath(dirname(__DIR__));
if ($xamppRoot === false) {
    out('ERROR', 'Cannot resolve XAMPP root from script location.');
    exit(2);
}

$xamppRoot = norm($xamppRoot);
$phpDir = $xamppRoot . '/php';
$expectedExtDir = $phpDir . '/ext';

out('INFO', 'PHP binary: ' . PHP_BINARY);
out('INFO', 'PHP version: ' . PHP_VERSION);
out('INFO', 'XAMPP root: ' . $xamppRoot);
out('INFO', 'Loaded php.ini: ' . (php_ini_loaded_file() ?: '(none)'));
out('INFO', 'Scanned ini files: ' . (php_ini_scanned_files() ?: '(none)'));
out('INFO', 'Current working directory: ' . norm(getcwd() ?: '(unknown)'));
out('INFO', 'extension_dir raw: ' . (string) ini_get('extension_dir'));

$resolvedExtDir = ini_get('extension_dir') ?: '';
if ($resolvedExtDir !== '' && !preg_match('~^[A-Za-z]:[\\\\/]~', $resolvedExtDir) && !str_starts_with($resolvedExtDir, '/') && !str_starts_with($resolvedExtDir, '\\\\')) {
    $resolvedExtDir = norm((getcwd() ?: '.') . '/' . $resolvedExtDir);
} else {
    $resolvedExtDir = norm($resolvedExtDir);
}

out('INFO', 'extension_dir resolved-ish: ' . $resolvedExtDir);
out('INFO', 'expected ext dir: ' . $expectedExtDir);

if (!is_dir($expectedExtDir)) {
    out('ERROR', 'Expected ext dir does not exist: ' . $expectedExtDir);
    exit(2);
}

$required = [
    'mysqli',
    'pdo_mysql',
    'pdo_sqlite',
    'mbstring',
    'curl',
    'fileinfo',
    'openssl',
    'ftp',
    'bz2',
    'gettext',
    'exif',
];

out('', '');
out('INFO', 'Static extension status from current PHP process:');

$errors = 0;

foreach ($required as $ext) {
    $dll = $expectedExtDir . '/php_' . $ext . '.dll';
    $loaded = extension_loaded($ext);

    if (!is_file($dll)) {
        out('ERROR', sprintf('%-12s not loaded=%s, DLL missing: %s', $ext, $loaded ? 'yes' : 'no', $dll));
        $errors++;
        continue;
    }

    out($loaded ? 'OK' : 'WARN', sprintf('%-12s loaded=%s, DLL exists: %s', $ext, $loaded ? 'yes' : 'no', $dll));
}

out('', '');
out('INFO', 'On-demand dl() test with current process:');

if (!function_exists('dl')) {
    out('WARN', 'dl() function is not available in this SAPI.');
} elseif (!filter_var(ini_get('enable_dl'), FILTER_VALIDATE_BOOLEAN)) {
    out('WARN', 'enable_dl is Off. Direct load test skipped.');
} else {
    foreach ($required as $ext) {
        if (extension_loaded($ext)) {
            out('OK', sprintf('%-12s already loaded', $ext));
            continue;
        }

        $dllName = 'php_' . $ext . '.dll';
        $before = error_get_last();
        $ok = @dl($dllName);
        $after = error_get_last();

        if ($ok || extension_loaded($ext)) {
            out('OK', sprintf('%-12s loaded via dl(%s)', $ext, $dllName));
        } else {
            $msg = $after && $after !== $before ? $after['message'] : 'unknown load error';
            out('ERROR', sprintf('%-12s failed via dl(%s): %s', $ext, $dllName, $msg));
            $errors++;
        }
    }
}

exit($errors > 0 ? 1 : 0);
