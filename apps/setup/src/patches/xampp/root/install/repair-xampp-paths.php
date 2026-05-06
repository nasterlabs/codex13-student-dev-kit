<?php

// cspell:ignore ukasz

/**
 * Codex 13 Student Development Kit - XAMPP Unicode path repair utility (Apache + PHP + MySQL) - v12.
 *
 * Created by Naster Labs, the software brand of Luczak Consulting P.S.A.,
 * for Codex 13 Student Dev Kit.
 *
 * This helper is not part of the original Apache Friends XAMPP distribution.
 * It is designed to repair XAMPP configuration files already damaged by an
 * old relocation pass that could not handle non-ASCII Windows paths such as:
 *
 * C:\Users\Łukasz\AppData\Local\Codex13\StudentDevKit\xampp
 *
 * Store as:
 *
 * xampp\install\repair-xampp-paths.php
 *
 * Run from the XAMPP root:
 *
 * .\php\php.exe .\install\repair-xampp-paths.php
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

$xamppRootReal = realpath(dirname(__DIR__));
if ($xamppRootReal === false || $xamppRootReal === '') {
    fwrite(STDERR, "Cannot detect XAMPP root.\r\n");
    exit(1);
}

$xamppRoot = str_replace('\\', '/', $xamppRootReal);
$xamppBackslash = str_replace('/', '\\', $xamppRoot);

$files = array(
    'apache/conf/httpd.conf',
    'apache/conf/extra/httpd-ssl.conf',
    'apache/conf/extra/httpd-xampp.conf',
    'apache/conf/extra/httpd-vhosts.conf',
    'apache/conf/extra/httpd-default.conf',
    'apache/conf/extra/httpd-info.conf',
    'apache/conf/extra/httpd-languages.conf',
    'apache/conf/extra/httpd-mpm.conf',
    'apache/conf/extra/httpd-autoindex.conf',
    'php/php.ini',
    'apache/bin/php.ini',
    'mysql/bin/my.ini',
);

function rx_replace_literal($pattern, $replacement, $content)
{
    return preg_replace_callback($pattern, function () use ($replacement) {
        return $replacement;
    }, $content);
}


function codex13_php_ini_set($content, $key, $value)
{
    $pattern = '~(?m)^\s*;?\s*' . preg_quote($key, '~') . '\s*=.*$~';
    $replacement = $key . '="' . $value . '"';

    if (preg_match($pattern, $content)) {
        return preg_replace($pattern, $replacement, $content);
    }

    return rtrim($content) . "\r\n" . $replacement . "\r\n";
}

function codex13_repair_php_ini($content, $xamppBackslash)
{
    // [CODEX13-SDK PHP ENCODING]
    // XAMPP PHP on Windows reads php.ini using the legacy Windows ANSI code
    // page. If php.ini is saved as UTF-8 and the path contains Polish
    // characters such as "Ł", PHP may corrupt the path while loading dynamic
    // extensions. Therefore this function returns UTF-8 text for in-memory
    // processing, but callers must write php.ini back as Windows ANSI bytes.
    $php = $xamppBackslash . '\\php';
    $apache = $xamppBackslash . '\\apache';
    $tmp = $xamppBackslash . '\\tmp';

    $content = codex13_php_ini_set($content, 'extension_dir', $php . '\\ext');
    $content = codex13_php_ini_set($content, 'upload_tmp_dir', $tmp);
    $content = codex13_php_ini_set($content, 'session.save_path', $tmp);
    $content = codex13_php_ini_set($content, 'include_path', $php . '\\PEAR');
    $content = codex13_php_ini_set($content, 'error_log', $php . '\\logs\\php_error_log');
    $content = codex13_php_ini_set($content, 'browscap', $php . '\\extras\\browscap.ini');
    $content = codex13_php_ini_set($content, 'curl.cainfo', $apache . '\\bin\\curl-ca-bundle.crt');
    $content = codex13_php_ini_set($content, 'openssl.cafile', $apache . '\\bin\\curl-ca-bundle.crt');

    return $content;
}

function codex13_xampp_path_without_drive($xamppRoot)
{
    // [CODEX13-SDK MYSQL PATH FORMAT]
    // The stock XAMPP relocation script writes MariaDB paths on Windows in
    // a Unix-like form without the drive letter, for example:
    //   /Users/Łukasz/AppData/Local/.../xampp/mysql/data
    // Keep that form for my.ini. In this XAMPP/MariaDB bundle C:/Users/...
    // with non-ASCII characters is fragile.
    return preg_replace('~^[A-Za-z]:~', '', $xamppRoot);
}

function codex13_is_valid_utf8($bytes)
{
    return preg_match('//u', $bytes) === 1;
}

function codex13_from_windows_ansi_bytes($bytes)
{
    // If the file is already UTF-8, keep it as-is for in-memory repair.
    if (codex13_is_valid_utf8($bytes)) {
        return $bytes;
    }

    // [CODEX13-SDK MYSQL ENCODING]
    // MariaDB bundled with XAMPP reads my.ini using the legacy Windows
    // narrow-character path layer. On Polish Windows, paths such as
    // "Łukasz" must therefore be stored in Windows-1250 / system ANSI bytes.
    // Convert raw ANSI bytes to UTF-8 for regex-based processing.
    if (function_exists('sapi_windows_cp_get') && function_exists('sapi_windows_cp_conv')) {
        $ansi = sapi_windows_cp_get('ansi');
        $converted = @sapi_windows_cp_conv($ansi, 65001, $bytes);
        if ($converted !== false && $converted !== null) {
            return $converted;
        }
    }

    if (function_exists('iconv')) {
        $converted = @iconv('Windows-1250', 'UTF-8//IGNORE', $bytes);
        if ($converted !== false) {
            return $converted;
        }
    }

    return $bytes;
}

function codex13_to_windows_ansi_bytes($utf8)
{
    // Write my.ini back as system ANSI, not UTF-8. This is required for
    // MariaDB/XAMPP to resolve non-ASCII Windows user-profile paths.
    if (function_exists('sapi_windows_cp_get') && function_exists('sapi_windows_cp_conv')) {
        $ansi = sapi_windows_cp_get('ansi');
        $converted = @sapi_windows_cp_conv(65001, $ansi, $utf8);
        if ($converted !== false && $converted !== null) {
            return $converted;
        }
    }

    if (function_exists('iconv')) {
        $converted = @iconv('UTF-8', 'Windows-1250//TRANSLIT', $utf8);
        if ($converted !== false) {
            return $converted;
        }
    }

    return $utf8;
}

function codex13_repair_mysql_ini($content, $xamppRoot)
{
    // [CODEX13-SDK MYSQL]
    // Do not use relative paths here and do not use C:/... absolute paths.
    // Match the path style produced by the original XAMPP relocation logic
    // that is confirmed to work in Unicode profile directories.
    $root = codex13_xampp_path_without_drive($xamppRoot);

    $replacements = array(
        '~(?m)^\s*socket\s*=.*$~' => 'socket = "' . $root . '/mysql/mysql.sock"',
        '~(?m)^\s*basedir\s*=.*$~' => 'basedir = "' . $root . '/mysql"',
        '~(?m)^\s*tmpdir\s*=.*$~' => 'tmpdir = "' . $root . '/tmp"',
        '~(?m)^\s*datadir\s*=.*$~' => 'datadir = "' . $root . '/mysql/data"',
        '~(?m)^\s*plugin_dir\s*=.*$~' => 'plugin_dir = "' . $root . '/mysql/lib/plugin/"',
        '~(?m)^\s*innodb_data_home_dir\s*=.*$~' => 'innodb_data_home_dir = "' . $root . '/mysql/data"',
        '~(?m)^\s*innodb_log_group_home_dir\s*=.*$~' => 'innodb_log_group_home_dir = "' . $root . '/mysql/data"',
    );

    foreach ($replacements as $pattern => $replacement) {
        $content = preg_replace($pattern, $replacement, $content);
    }

    return $content;
}

$changed = 0;
foreach ($files as $rel) {
    $path = $xamppRoot . '/' . $rel;
    if (!file_exists($path)) {
        continue;
    }

    $rawContent = file_get_contents($path);
    if ($rawContent === false) {
        echo "SKIP read failed: $rel\r\n";
        continue;
    }

    $content = ($rel === 'mysql/bin/my.ini' || $rel === 'php/php.ini' || $rel === 'apache/bin/php.ini')
        ? codex13_from_windows_ansi_bytes($rawContent)
        : $rawContent;

    $old = $content;

    // [CODEX13-SDK REPAIR]
    // Fix a specific v2 regression first: "shmc/Users/..." or "shmcC:/..."
    // must become "shmcb:<xampp>/apache/logs/ssl_scache(512000)".
    $content = rx_replace_literal(
        '~shmc(?:[A-Za-z]:)?/[^\r\n"\']*?/xampp/apache/logs/ssl_scache~',
        'shmcb:' . $xamppRoot . '/apache/logs/ssl_scache',
        $content
    );
    $content = rx_replace_literal(
        '~shmc/Users/[^\r\n"\']*?/StudentDevKit/xampp/apache/logs/ssl_scache~',
        'shmcb:' . $xamppRoot . '/apache/logs/ssl_scache',
        $content
    );

    // [CODEX13-SDK REPAIR]
    // Replace full slash paths ending at /xampp. Important: do not let the
    // optional drive-letter branch match the final "b:/" inside "shmcb:/".
    $content = rx_replace_literal(
        '~(?<![A-Za-z0-9_])(?:[A-Za-z]:)?/[^\r\n"\']*?/xampp(?=([/"\'\s\)]|$))~',
        $xamppRoot,
        $content
    );

    // [CODEX13-SDK REPAIR]
    // Replace a bare /xampp placeholder only when it is really a path token,
    // not part of another protocol/cache prefix.
    $content = rx_replace_literal(
        '~(?<![A-Za-z0-9_:])/xampp(?=([/"\'\s\)]|$))~',
        $xamppRoot,
        $content
    );

    // [CODEX13-SDK REPAIR]
    // Backslash forms.
    $content = rx_replace_literal(
        '~(?<![A-Za-z0-9_])(?:[A-Za-z]:)?\\\\[^\r\n"\']*?\\\\xampp(?=([\\\\"\'\s\)]|$))~',
        $xamppBackslash,
        $content
    );
    $content = rx_replace_literal(
        '~(?<![A-Za-z0-9_:])\\\\xampp(?=([\\\\"\'\s\)]|$))~',
        $xamppBackslash,
        $content
    );

    // [CODEX13-SDK REPAIR]
    // Safety: SSLSessionCache must keep the provider prefix "shmcb:".
    $content = preg_replace(
        '~SSLSessionCache\s+"shmcb:([^"]*?)"~',
        'SSLSessionCache "shmcb:$1"',
        $content
    );

    if ($rel === 'php/php.ini' || $rel === 'apache/bin/php.ini') {
        $content = codex13_repair_php_ini($content, $xamppBackslash);
    }

    if ($rel === 'mysql/bin/my.ini') {
        $content = codex13_repair_mysql_ini($content, $xamppRoot);
    }

    $outputBytes = ($rel === 'mysql/bin/my.ini' || $rel === 'php/php.ini' || $rel === 'apache/bin/php.ini')
        ? codex13_to_windows_ansi_bytes($content)
        : $content;

    if ($outputBytes !== $rawContent) {
        @copy($path, $path . '.unicode-repair-v12.bak');
        file_put_contents($path, $outputBytes);
        echo "FIXED $rel\r\n";
        $changed++;
    } else {
        echo "OK    $rel\r\n";
    }
}


// [CODEX13-SDK RUNTIME DIRECTORIES]
// Some XAMPP archives do not contain empty runtime directories after extraction
// (for example xampp/tmp or apache/logs). MariaDB reports this as
// "InnoDB: Unable to create temporary file; errno: 2" even when my.ini paths
// are otherwise correct. Ensure those directories exist after path repair.
$runtimeDirs = array(
    'tmp',
    'apache/logs',
    'mysql/data',
);
foreach ($runtimeDirs as $runtimeRel) {
    $runtimePath = $xamppRoot . '/' . $runtimeRel;
    if (!is_dir($runtimePath)) {
        if (@mkdir($runtimePath, 0777, true)) {
            echo "CREATED $runtimeRel\r\n";
        } else {
            echo "WARN  cannot create $runtimeRel\r\n";
        }
    }
}

$installSys = $xamppRoot . '/install/install.sys';
$version = '?';
$versionFile = $xamppRoot . '/htdocs/xampp/.version';
if (file_exists($versionFile)) {
    $version = trim(file_get_contents($versionFile));
}
$installSysContent =
    "DIR = " . str_replace('/', '\\', $xamppRoot) . "\r\n" .
    "xampp = $version\r\n" .
    "server = 0\r\n" .
    "perl = 0\r\n" .
    "python = 0\r\n" .
    "utils = 0\r\n" .
    "java = 0\r\n" .
    "other = 0\r\n" .
    "usbstick = 0";
file_put_contents($installSys, $installSysContent);
echo "UPDATED install/install.sys\r\n";
echo "Done. Changed files: $changed\r\n";
