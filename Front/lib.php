<?php
// =====================================================================
// CITARA · Base común de las pantallas privadas
// Uso: require_once __DIR__ . '/lib.php';  al inicio de cada página.
// Trae: sesión (redirige al login si no hay), conexión, ayudantes de
// consulta, formato de fechas/dinero, mensajes y el esqueleto HTML.
// El negocio sale SIEMPRE de la sesión ($NEG), nunca de un dato del navegador.
// =====================================================================
require_once __DIR__ . '/sesion.php';
require_once is_file(__DIR__ . '/conexion.local.php') ? __DIR__ . '/conexion.local.php' : __DIR__ . '/conexion.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conexion->set_charset('utf8mb4');
date_default_timezone_set('America/Bogota');

$NEG   = (int)($_SESSION['negocio_id'] ?? 0);
$SEDE  = (int)($_SESSION['sede_id'] ?? 0);
$ROL   = $_SESSION['rol'] ?? '';
$UID   = (int)($_SESSION['usuario_id'] ?? 0);

// ---------- Texto y formato ----------
function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function pesos($n) { return '$' . number_format((float)$n, 0, ',', '.'); }
function iniciales($nombre) {
    $p = preg_split('/\s+/', trim((string)$nombre));
    $a = mb_substr($p[0] ?? '', 0, 1, 'UTF-8');
    $b = mb_substr($p[1] ?? '', 0, 1, 'UTF-8');
    return mb_strtoupper($a . $b, 'UTF-8');
}
const MESES = [1=>'enero',2=>'febrero',3=>'marzo',4=>'abril',5=>'mayo',6=>'junio',7=>'julio',8=>'agosto',9=>'septiembre',10=>'octubre',11=>'noviembre',12=>'diciembre'];
const DIAS  = [1=>'Lunes',2=>'Martes',3=>'Miércoles',4=>'Jueves',5=>'Viernes',6=>'Sábado',7=>'Domingo'];
function fecha_larga($f) { $t = strtotime($f); return DIAS[(int)date('N', $t)] . ' ' . date('j', $t) . ' de ' . MESES[(int)date('n', $t)]; }
function fecha_corta($f) { if (!$f) return '—'; $t = strtotime($f); return date('j', $t) . ' ' . mb_substr(MESES[(int)date('n', $t)], 0, 3, 'UTF-8'); }
function fecha_completa($f) { if (!$f) return '—'; $t = strtotime($f); return date('j', $t) . ' ' . mb_substr(MESES[(int)date('n', $t)], 0, 3, 'UTF-8') . ' ' . date('Y', $t); }
function hora($dt) { return date('H:i', strtotime($dt)); }
function solo_digitos($s) { return preg_replace('/\D/', '', (string)$s); }

// ---------- Consultas (siempre con parámetros) ----------
function _bind($st, $p) {
    if (!$p) return;
    $t = '';
    foreach ($p as $v) $t .= is_int($v) ? 'i' : (is_float($v) ? 'd' : 's');
    $st->bind_param($t, ...$p);
}
function q_all($sql, $p = []) {
    global $conexion; $st = $conexion->prepare($sql); _bind($st, $p); $st->execute();
    $r = $st->get_result()->fetch_all(MYSQLI_ASSOC); $st->close(); return $r;
}
function q_row($sql, $p = []) { $r = q_all($sql, $p); return $r[0] ?? null; }
function q_val($sql, $p = []) { $r = q_row($sql, $p); return $r ? array_values($r)[0] : null; }
function q_run($sql, $p = []) {          // INSERT/UPDATE/DELETE → filas afectadas
    global $conexion; $st = $conexion->prepare($sql); _bind($st, $p); $st->execute();
    $n = $st->affected_rows; $st->close(); return $n;
}
function q_insert($sql, $p = []) {       // INSERT → id nuevo
    global $conexion; q_run($sql, $p); return (int)$conexion->insert_id;
}

// ---------- Permisos ----------
function requerir_rol(array $roles) {
    global $ROL;
    if (($_SESSION['tipo_cuenta'] ?? '') !== 'negocio' || !in_array($ROL, $roles, true)) {
        $destino = ($ROL === 'empleado') ? 'empleado-hoy.php' : (($_SESSION['tipo_cuenta'] ?? '') === 'plataforma' ? 'plataforma.php' : 'index.php');
        header('Location: ' . $destino); exit;
    }
}
const ADMIN = ['dueno', 'administrador'];

// ---------- Mensajes entre páginas ----------
function flash($msg, $tipo = 'success') { $_SESSION['flash'] = [$msg, $tipo]; }
function mostrar_flash() {
    if (empty($_SESSION['flash'])) return;
    [$m, $t] = $_SESSION['flash']; unset($_SESSION['flash']);
    echo '<div class="alert alert-' . h($t) . ' d-flex align-items-center gap-2" role="alert">' . h($m) . '</div>';
}
function errores_html(array $e) {
    if (!$e) return;
    echo '<div class="alert alert-danger" role="alert"><i class="bi bi-exclamation-circle me-1"></i>';
    foreach ($e as $x) echo '<div>' . h($x) . '</div>';
    echo '</div>';
}

// ---------- Protección de formularios ----------
function csrf() {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(16));
    return '<input type="hidden" name="csrf" value="' . h($_SESSION['csrf']) . '">';
}
function csrf_ok() {
    return isset($_POST['csrf'], $_SESSION['csrf']) && hash_equals($_SESSION['csrf'], $_POST['csrf']);
}
function es_post() { return $_SERVER['REQUEST_METHOD'] === 'POST'; }

// ---------- Esqueleto HTML ----------
function cabecera($titulo, $activo = '') {
    global $ROL;
    $nombre = $_SESSION['usuario_nombre'] ?? '';
    $sede   = $_SESSION['sede_nombre'] ?? '';
    echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">'
       . '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
       . '<title>' . h($titulo) . ' · Citara</title>'
       . '<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">'
       . '<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">'
       . '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">'
       . '<link href="Style.css" rel="stylesheet"></head><body>'
       . '<div class="d-flex flex-column flex-lg-row">'
       . '<div id="menu-lateral" class="menu-envoltura" data-activo="' . h($activo) . '" data-rol="' . h($ROL) . '" data-nombre="' . h($nombre) . '" data-sede="' . h($sede) . '"></div>'
       . '<main class="contenido p-3 p-lg-4">';
    mostrar_flash();
}
function pie() {
    echo '</main></div><script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script><script src="menu.js"></script></body></html>';
}
function avatar($nombre, $extra = '') {
    return '<span class="avatar ' . h($extra) . ' rounded-circle d-inline-flex align-items-center justify-content-center">' . h(iniciales($nombre)) . '</span>';
}
