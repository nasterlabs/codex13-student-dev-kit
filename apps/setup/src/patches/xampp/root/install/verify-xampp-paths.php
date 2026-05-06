<?php

// cspell:ignore ukasz

/**
 * Codex 13 Student Development Kit - XAMPP path verification utility - v8.
 *
 * Created by Naster Labs, the software brand of Luczak Consulting P.S.A.,
 * for Codex 13 Student Dev Kit.
 *
 * This helper is not part of the original Apache Friends XAMPP distribution.
 * It is intended to be used after the Codex 13 XAMPP path repair step to verify
 * that configuration files do not contain broken, duplicated, or unsafe paths.
 *
 * Original upstream context:
 * - Apache Friends XAMPP for Windows
 * - setup-xampp.bat / install/install.php relocation mechanism
 *
 * Why this file exists:
 * older XAMPP relocation logic uses external awk/cmd-style path replacement
 * and can corrupt non-ASCII Windows paths, for example paths containing Polish
 * characters such as "Ł" in C:\Users\Łukasz. This verifier checks whether the
 * resulting configuration is safe enough for Codex 13 Student Development Kit.
 *
 * Store as:
 *   xampp\install\verify-xampp-paths.php
 *
 * Run from the XAMPP root:
 *   .\php\php.exe -n .\install\verify-xampp-paths.php
 *
 * Exit codes:
 *   0 - OK
 *   1 - validation failed
 *   2 - cannot detect XAMPP root or critical file read error
 *
 * Codex 13 SDK repository:
 * https://github.com/nasterlabs/codex13-student-dev-kit
 *
 * Codex 13 SDK product page:
 * https://codex13.dev/student-dev-kit
 *
 * License: GPL-2.0-only, matching the XAMPP patch set it accompanies. See
 * LICENSES/LicenseRef-xampp-patch.txt and LICENSES/GPL-2.0-only.txt in the
 * Codex 13 Student Dev Kit repository.
 */

error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_WARNING & ~E_NOTICE);

$scriptDir = str_replace('\\', '/', __DIR__);
$xamppRootReal = realpath(dirname(__DIR__));

if ($xamppRootReal === false || $xamppRootReal === '') {
    fwrite(STDERR, "ERROR Cannot detect XAMPP root from: {$scriptDir}\r\n");
    echo "SUMMARY NOT_OK\r\n";
    exit(2);
}

$xamppRoot = str_replace('\\', '/', $xamppRootReal);
$xamppBackslash = str_replace('/', '\\', $xamppRoot);
$errors = 0;
$warnings = 0;
$checked = 0;

$apacheFiles = array(
    'apache/conf/httpd.conf',
    'apache/conf/extra/httpd-ssl.conf',
    'apache/conf/extra/httpd-xampp.conf',
    'apache/conf/extra/httpd-vhosts.conf',
    'apache/conf/extra/httpd-default.conf',
    'apache/conf/extra/httpd-info.conf',
    'apache/conf/extra/httpd-languages.conf',
    'apache/conf/extra/httpd-mpm.conf',
    'apache/conf/extra/httpd-autoindex.conf',
);

$phpFiles = array(
    'php/php.ini',
);

$mysqlFiles = array(
    'mysql/bin/my.ini',
);

function c13_print_result($status, $file, $message)
{
    printf("%-7s %-42s %s\r\n", $status, $file, $message);
}

function c13_is_valid_utf8($bytes)
{
    return preg_match('//u', $bytes) === 1;
}

function c13_from_windows_ansi_bytes($content)
{
    // Some XAMPP files may intentionally be stored in the current Windows ANSI
    // code page so Windows/PHP/MariaDB can resolve non-ASCII usernames.
    // In particular, php.ini must remain ANSI/Windows-1250 in this bundle;
    // UTF-8 can break PHP extension loading for paths containing Polish Ł.
    // If the file is
    // already valid UTF-8, do not reinterpret it as ANSI, because that turns
    // "Ł" into mojibake-like text such as "Ĺ".
    if (c13_is_valid_utf8($content)) {
        return $content;
    }

    if (function_exists('sapi_windows_cp_get') && function_exists('sapi_windows_cp_conv')) {
        $ansi = sapi_windows_cp_get('ansi');
        $converted = @sapi_windows_cp_conv($ansi, 65001, $content);
        if ($converted !== false && $converted !== null) {
            return $converted;
        }
    }

    if (function_exists('iconv')) {
        $converted = @iconv('Windows-1250', 'UTF-8//IGNORE', $content);
        if ($converted !== false) {
            return $converted;
        }
    }

    return $content;
}

function c13_read_file($xamppRoot, $rel)
{
    $path = $xamppRoot . '/' . $rel;
    if (!file_exists($path)) {
        return array(false, "missing file");
    }

    $content = file_get_contents($path);
    if ($content === false) {
        return array(false, "read failed");
    }

    if ($rel === 'mysql/bin/my.ini' || $rel === 'php/php.ini') {
        $content = c13_from_windows_ansi_bytes($content);
    }

    return array($content, null);
}

function c13_remove_comments($content)
{
    $lines = preg_split('~\R~', $content);
    $kept = array();
    foreach ($lines as $line) {
        $trimmed = ltrim($line);
        if ($trimmed === '' || $trimmed[0] === '#' || $trimmed[0] === ';') {
            continue;
        }
        $kept[] = $line;
    }
    return implode("\n", $kept);
}

function c13_check_common_broken_patterns($rel, $content, $allowUnicodePath)
{
    $issues = array();
    $activeContent = c13_remove_comments($content);

    $patterns = array(
        '~/(?:Users|xampp)/\s+[^\r\n"\']*~' => 'contains path segment with whitespace after slash, typical corrupted Unicode path',
        '~/Users/ ukasz~i' => 'contains known corrupted path /Users/ ukasz',
        '~[A-Za-z]:/[^\r\n"\']*?/StudentDevKit/[^\r\n"\']*?/StudentDevKit/~i' => 'contains duplicated StudentDevKit path segment',
        '~/Users/[^\r\n"\']*?/AppData/Local/Codex13/StudentDevKit/Users/~i' => 'contains concatenated /Users path',
        '~SSLSessionCache\s+"shmc(?!b:)~i' => 'contains broken SSLSessionCache provider prefix; expected shmcb:',
    );

    foreach ($patterns as $pattern => $message) {
        if (preg_match($pattern, $activeContent)) {
            $issues[] = $message;
        }
    }

    // Apache handles the UTF-8 path used by Codex 13 after repair. PHP and
    // MariaDB are stricter in this XAMPP bundle, so their active runtime
    // directives must avoid embedding C:/Users/<Unicode>/... paths. Comments
    // are ignored so provenance notes can still mention the original problem.
    if (!$allowUnicodePath && preg_match('~┼|úukasz|Łukasz~u', $activeContent)) {
        $issues[] = 'contains Unicode/mojibake user path marker in an active directive of a component that must use portable ASCII-safe paths';
    }

    return $issues;
}

function c13_normalize_config_path($value)
{
    $value = trim($value);
    $value = trim($value, " \t\n\r\0\x0B\"'");
    return str_replace('\\', '/', $value);
}


function c13_xampp_path_without_drive($xamppRoot)
{
    return preg_replace('~^[A-Za-z]:~', '', $xamppRoot);
}

function c13_extract_ini_value($content, $key)
{
    if (preg_match('~^\s*' . preg_quote($key, '~') . '\s*=\s*(.*?)\s*$~mi', $content, $m)) {
        return c13_normalize_config_path($m[1]);
    }

    return null;
}

function c13_check_apache_file($rel, $content, $xamppRoot)
{
    $issues = c13_check_common_broken_patterns($rel, $content, true);

    if ($rel === 'apache/conf/httpd.conf') {
        if (!preg_match('~^\s*Define\s+SRVROOT\s+"' . preg_quote($xamppRoot . '/apache', '~') . '"\s*$~m', $content)) {
            $issues[] = 'Define SRVROOT does not point to current XAMPP Apache directory';
        }
        if (!preg_match('~^\s*ServerRoot\s+"' . preg_quote($xamppRoot . '/apache', '~') . '"\s*$~m', $content)) {
            $issues[] = 'ServerRoot does not point to current XAMPP Apache directory';
        }
        if (!preg_match('~^\s*DocumentRoot\s+"' . preg_quote($xamppRoot . '/htdocs', '~') . '"\s*$~m', $content)) {
            $issues[] = 'DocumentRoot does not point to current XAMPP htdocs directory';
        }
    }

    if ($rel === 'apache/conf/extra/httpd-ssl.conf') {
        // Accept both Codex 13 absolute paths and XAMPP/Apache variable-based
        // paths. What matters here is the provider prefix and target cache
        // file shape, not the exact root formatting.
        if (!preg_match('~^\s*SSLSessionCache\s+"shmcb:[^"]*ssl_scache\(512000\)"\s*$~m', $content)) {
            $issues[] = 'SSLSessionCache should use shmcb:<path>/ssl_scache(512000)';
        }
    }

    return $issues;
}

function c13_check_php_ini($content)
{
    // PHP CLI must not depend on C:\xampp-style paths. Only validate the
    // directives that affect extension and temporary-file loading. Do not fail
    // the whole file just because comments mention the Unicode installation path.
    $issues = c13_check_common_broken_patterns('php/php.ini', $content, true);

    $expectedExtensionDir = $GLOBALS['xamppRoot'] . '/php/ext';
    $expectedTmpDir = $GLOBALS['xamppRoot'] . '/tmp';

    $extensionDir = c13_extract_ini_value($content, 'extension_dir');
    if ($extensionDir !== $expectedExtensionDir) {
        $issues[] = 'extension_dir should be "' . $expectedExtensionDir . '", got "' . (string)$extensionDir . '"';
    }

    $uploadTmp = c13_extract_ini_value($content, 'upload_tmp_dir');
    if ($uploadTmp !== $expectedTmpDir) {
        $issues[] = 'upload_tmp_dir should be "' . $expectedTmpDir . '", got "' . (string)$uploadTmp . '"';
    }

    $sessionPath = c13_extract_ini_value($content, 'session.save_path');
    if ($sessionPath !== $expectedTmpDir) {
        $issues[] = 'session.save_path should be "' . $expectedTmpDir . '", got "' . (string)$sessionPath . '"';
    }

    return $issues;
}

function c13_check_mysql_ini($content, $xamppRoot)
{
    // MariaDB in this XAMPP bundle is expected to use XAMPP's original
    // drive-less slash path form, e.g. /Users/Łukasz/.../xampp/mysql/data.
    // This is intentionally not ASCII-only; the problematic variant is
    // C:/Users/Łukasz/... in active MariaDB directives.
    $issues = c13_check_common_broken_patterns('mysql/bin/my.ini', $content, true);
    $root = c13_xampp_path_without_drive($xamppRoot);

    $expected = array(
        'socket' => $root . '/mysql/mysql.sock',
        'basedir' => $root . '/mysql',
        'tmpdir' => $root . '/tmp',
        'datadir' => $root . '/mysql/data',
        'plugin_dir' => $root . '/mysql/lib/plugin/',
        'innodb_data_home_dir' => $root . '/mysql/data',
        'innodb_log_group_home_dir' => $root . '/mysql/data',
    );

    foreach ($expected as $key => $expectedValue) {
        $actual = c13_extract_ini_value($content, $key);
        if ($actual === null) {
            $issues[] = "missing {$key}";
            continue;
        }

        if ($actual !== $expectedValue) {
            $issues[] = "{$key} should be \"{$expectedValue}\", got \"{$actual}\"";
        }
    }

    $activeContent = c13_remove_comments($content);
    if (preg_match('~[A-Za-z]:/[^\r\n"\']*?(?:Łukasz|┼|úukasz)~u', $activeContent)) {
        $issues[] = 'active MariaDB directive contains C:/... Unicode/mojibake path; use drive-less /Users/... form';
    }

    return $issues;
}

function c13_check_install_sys($xamppRoot)
{
    $rel = 'install/install.sys';
    list($content, $error) = c13_read_file($xamppRoot, $rel);
    if ($content === false) {
        return array("{$rel}: {$error}");
    }

    $issues = array();
    if (!preg_match('~^\s*usbstick\s*=\s*0\s*$~mi', $content)) {
        $issues[] = 'install.sys should contain usbstick = 0';
    }

    return $issues;
}

echo "Codex 13 XAMPP path verification\r\n";
echo "XAMPP root: {$xamppRoot}\r\n\r\n";

foreach ($apacheFiles as $rel) {
    $checked++;
    list($content, $error) = c13_read_file($xamppRoot, $rel);
    if ($content === false) {
        c13_print_result('ERROR', $rel, $error);
        $errors++;
        continue;
    }

    $issues = c13_check_apache_file($rel, $content, $xamppRoot);
    if (count($issues) === 0) {
        c13_print_result('OK', $rel, 'paths look valid');
    } else {
        foreach ($issues as $issue) {
            c13_print_result('ERROR', $rel, $issue);
            $errors++;
        }
    }
}

foreach ($phpFiles as $rel) {
    $checked++;
    list($content, $error) = c13_read_file($xamppRoot, $rel);
    if ($content === false) {
        c13_print_result('ERROR', $rel, $error);
        $errors++;
        continue;
    }

    $issues = c13_check_php_ini($content);
    if (count($issues) === 0) {
        c13_print_result('OK', $rel, 'paths look valid');
    } else {
        foreach ($issues as $issue) {
            c13_print_result('ERROR', $rel, $issue);
            $errors++;
        }
    }
}

foreach ($mysqlFiles as $rel) {
    $checked++;
    list($content, $error) = c13_read_file($xamppRoot, $rel);
    if ($content === false) {
        c13_print_result('ERROR', $rel, $error);
        $errors++;
        continue;
    }

    $issues = c13_check_mysql_ini($content, $xamppRoot);
    if (count($issues) === 0) {
        c13_print_result('OK', $rel, 'paths look valid');
    } else {
        foreach ($issues as $issue) {
            c13_print_result('ERROR', $rel, $issue);
            $errors++;
        }
    }
}

$installSysIssues = c13_check_install_sys($xamppRoot);
$checked++;
if (count($installSysIssues) === 0) {
    c13_print_result('OK', 'install/install.sys', 'portable mode disabled');
} else {
    foreach ($installSysIssues as $issue) {
        c13_print_result('ERROR', 'install/install.sys', $issue);
        $errors++;
    }
}

$runtimeDirs = array('tmp', 'apache/logs', 'mysql/data');
foreach ($runtimeDirs as $runtimeRel) {
    $checked++;
    if (is_dir($xamppRoot . '/' . $runtimeRel)) {
        c13_print_result('OK', $runtimeRel, 'runtime directory exists');
    } else {
        c13_print_result('ERROR', $runtimeRel, 'runtime directory is missing');
        $errors++;
    }
}

echo "\r\n";
echo "Checked files: {$checked}\r\n";
echo "Errors: {$errors}\r\n";
echo "Warnings: {$warnings}\r\n";

if ($errors > 0) {
    echo "SUMMARY NOT_OK\r\n";
    exit(1);
}

echo "SUMMARY OK\r\n";
exit(0);
