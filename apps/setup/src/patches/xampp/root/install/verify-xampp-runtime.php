<?php
/**
 * Codex 13 Student Dev Kit - XAMPP runtime health check.
 *
 * Installed for manual diagnostics only. Setup does not run this helper.
 * It checks Apache, MySQL, PHP and phpMyAdmin after Apache and MySQL are
 * already running.
 */

error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_WARNING & ~E_NOTICE);

$xamppRootReal = realpath(dirname(__DIR__));
if ($xamppRootReal === false || $xamppRootReal === '') {
    fwrite(STDERR, "ERROR Cannot detect XAMPP root.\r\n");
    echo "SUMMARY NOT_OK\r\n";
    exit(2);
}

$xamppRoot = str_replace('\\', '/', $xamppRootReal);
$errors = 0;

function result($status, $name, $message) {
    printf("%-7s %-24s %s\r\n", $status, $name, $message);
}

function fail($name, $message) {
    global $errors;
    $errors++;
    result('ERROR', $name, $message);
}

function ok($name, $message) {
    result('OK', $name, $message);
}

function warnx($name, $message) {
    result('WARN', $name, $message);
}

function tcp_probe($host, $port, $timeout = 2.0) {
    $errno = 0;
    $errstr = '';
    $fp = @fsockopen($host, $port, $errno, $errstr, $timeout);
    if (!$fp) {
        return array(false, trim($errstr) !== '' ? $errstr : 'connection failed');
    }
    fclose($fp);
    return array(true, 'port is reachable');
}

function run_cmd($cmd) {
    $output = array();
    $code = 0;
    @exec($cmd, $output, $code);
    return array($code, implode("\n", $output));
}

function fetch_http($url) {
    $context = stream_context_create(array(
        'http' => array(
            'timeout' => 5,
            'ignore_errors' => true,
        ),
    ));

    $body = @file_get_contents($url, false, $context);
    return $body === false ? '' : $body;
}

echo "Codex 13 XAMPP runtime verification\r\n";
echo "XAMPP root: {$xamppRoot}\r\n\r\n";

$phpExe = $xamppRoot . '/php/php.exe';
$httpdExe = $xamppRoot . '/apache/bin/httpd.exe';
$mysqlExe = $xamppRoot . '/mysql/bin/mysql.exe';

foreach (array('php.exe' => $phpExe, 'httpd.exe' => $httpdExe, 'mysql.exe' => $mysqlExe) as $name => $path) {
    if (is_file($path)) {
        ok($name, $path);
    } else {
        fail($name, 'missing: ' . $path);
    }
}

if (is_file($phpExe)) {
    list($code, $modules) = run_cmd('"' . $phpExe . '" -m 2>&1');
    if ($code !== 0) {
        fail('PHP modules', 'php -m failed: ' . $modules);
    } else {
        foreach (array('mysqli', 'pdo_mysql', 'mbstring', 'openssl', 'curl') as $module) {
            if (preg_match('~^' . preg_quote($module, '~') . '$~mi', $modules)) {
                ok('PHP extension', $module . ' loaded');
            } else {
                fail('PHP extension', $module . ' not loaded');
            }
        }
    }

    list($code, $ini) = run_cmd('"' . $phpExe . '" --ini 2>&1');
    if ($code === 0) {
        ok('PHP ini', trim($ini));
    } else {
        warnx('PHP ini', trim($ini));
    }
}

list($apacheReachable, $apacheMsg) = tcp_probe('127.0.0.1', 80);
if ($apacheReachable) {
    ok('Apache', '127.0.0.1:80 reachable');
} else {
    fail('Apache', '127.0.0.1:80 not reachable: ' . $apacheMsg);
}

list($mysqlReachable, $mysqlMsg) = tcp_probe('127.0.0.1', 3306);
if ($mysqlReachable) {
    ok('MySQL', '127.0.0.1:3306 reachable');
} else {
    fail('MySQL', '127.0.0.1:3306 not reachable: ' . $mysqlMsg);
}

if (is_file($mysqlExe)) {
    $cmd = '"' . $mysqlExe . '" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --batch --skip-column-names --execute="SELECT VERSION();" 2>&1';
    list($code, $out) = run_cmd($cmd);
    if ($code === 0 && trim($out) !== '') {
        ok('MySQL query', 'SELECT VERSION() => ' . trim($out));
    } else {
        fail('MySQL query', trim($out) !== '' ? trim($out) : 'query failed');
    }
}

$healthFile = $xamppRoot . '/htdocs/codex13-xampp-health.php';
$healthPhp = <<<'PHP'
<?php
header('Content-Type: text/plain; charset=utf-8');
echo "PHP_VERSION=" . PHP_VERSION . "\n";
echo "PHP_SAPI=" . PHP_SAPI . "\n";
foreach (array('mysqli', 'pdo_mysql', 'mbstring', 'openssl', 'curl') as $module) {
    echo "EXT_" . strtoupper($module) . "=" . (extension_loaded($module) ? '1' : '0') . "\n";
}
if (extension_loaded('mysqli')) {
    mysqli_report(MYSQLI_REPORT_OFF);
    $db = @new mysqli('127.0.0.1', 'root', '', '', 3306);
    echo "MYSQLI_CONNECT=" . ($db && !$db->connect_errno ? '1' : '0') . "\n";
    if ($db && !$db->connect_errno) {
        $res = @$db->query('SELECT VERSION() AS version');
        $row = $res ? $res->fetch_assoc() : null;
        echo "MYSQL_VERSION=" . ($row ? $row['version'] : '') . "\n";
        $db->close();
    }
}
PHP;

if (@file_put_contents($healthFile, $healthPhp) === false) {
    fail('HTTP health file', 'cannot write ' . $healthFile);
} else {
    $body = fetch_http('http://127.0.0.1/codex13-xampp-health.php');
    if (trim($body) === '') {
        fail('HTTP PHP health', 'cannot fetch health endpoint through Apache');
    } else {
        ok('HTTP PHP health', str_replace("\n", '; ', trim($body)));
        foreach (array('EXT_MYSQLI=1', 'EXT_PDO_MYSQL=1', 'EXT_MBSTRING=1') as $needle) {
            if (strpos($body, $needle) === false) {
                fail('HTTP PHP module', $needle . ' missing in Apache PHP runtime');
            }
        }
        if (strpos($body, 'MYSQLI_CONNECT=1') === false) {
            fail('HTTP MySQLi', 'Apache PHP could not connect to MySQL as root without password');
        }
    }
    @unlink($healthFile);
}

$phpMyAdminBody = fetch_http('http://127.0.0.1/phpmyadmin/');
if (trim($phpMyAdminBody) === '') {
    fail('phpMyAdmin', 'cannot fetch http://127.0.0.1/phpmyadmin/ through Apache');
} elseif (stripos($phpMyAdminBody, 'phpMyAdmin') !== false || stripos($phpMyAdminBody, 'pma_') !== false) {
    ok('phpMyAdmin', 'HTTP endpoint returned phpMyAdmin content');
} else {
    fail('phpMyAdmin', 'HTTP endpoint returned unexpected content');
}

echo "\r\nSUMMARY " . ($errors === 0 ? 'OK' : 'NOT_OK') . "\r\n";
exit($errors === 0 ? 0 : 1);
