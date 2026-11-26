<?php
// Pantalla para televisor de la sala de espera. Sin sesión: se entra con un enlace con token
// (turnos-hoy.php?t=TOKEN). En la BD solo se guarda el hash SHA-256 del token.
require_once is_file(__DIR__ . '/conexion.local.php') ? __DIR__ . '/conexion.local.php' : __DIR__ . '/conexion.php';
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conexion->set_charset('utf8mb4'); date_default_timezone_set('America/Bogota');
$t = (string)($_GET['t'] ?? '');
$st = $conexion->prepare("SELECT tv.negocio_id, tv.sede_id, tv.nombre, n.nombre AS negocio, s.nombre AS sede FROM televisor tv JOIN negocio n ON n.id = tv.negocio_id JOIN sede s ON s.negocio_id = tv.negocio_id AND s.id = tv.sede_id WHERE tv.token_hash = ? AND tv.activo = 1 AND n.estado = 'activo'");
$hash = hash('sha256', $t); $st->bind_param('s', $hash); $st->execute(); $tv = $st->get_result()->fetch_assoc();
if (!$tv || $t === '') { http_response_code(404); echo 'Enlace no válido.'; exit; }
$st = $conexion->prepare("SELECT cs.inicio, cs.fin, cs.estado, s.nombre AS servicio, c.nombres AS cliente, LEFT(c.apellidos,1) AS ini, e.nombres AS emp
   FROM cita_servicio cs JOIN cita ci ON ci.negocio_id = cs.negocio_id AND ci.id = cs.cita_id JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
   JOIN cliente c ON c.negocio_id = ci.negocio_id AND c.id = ci.cliente_id JOIN empleado e ON e.negocio_id = cs.negocio_id AND e.id = cs.empleado_id
   WHERE cs.negocio_id = ? AND ci.sede_id = ? AND DATE(cs.inicio) = CURDATE() AND cs.estado IN ('programado','en curso') AND cs.fin >= NOW() ORDER BY cs.inicio LIMIT 12");
$st->bind_param('ii', $tv['negocio_id'], $tv['sede_id']); $st->execute(); $rows = $st->get_result()->fetch_all(MYSQLI_ASSOC);
function e($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
?><!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="refresh" content="30"><title>Turnos de hoy · <?= e($tv['negocio']) ?></title>
<style>body{margin:0;background:#111;color:#fff;font-family:Inter,system-ui,sans-serif;padding:3vw}h1{font-size:3vw;margin:0 0 .3em}small{color:#aaa}.f{display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #333;padding:1.2vw 0;font-size:2.2vw}.h{font-weight:700;width:9vw}.en{color:#7CFFB2}</style></head><body>
<h1><?= e($tv['negocio']) ?> · <?= e($tv['sede']) ?></h1><small><?= date('H:i') ?> · se actualiza solo</small>
<?php foreach ($rows as $r): ?><div class="f"><span class="h <?= $r['estado'] === 'en curso' ? 'en' : '' ?>"><?= date('H:i', strtotime($r['inicio'])) ?></span><span style="flex:1"><?= e($r['cliente'] . ' ' . $r['ini']) ?>.</span><span style="flex:1"><?= e($r['servicio']) ?></span><span><?= e($r['emp']) ?></span></div><?php endforeach; if (!$rows) echo '<p style="font-size:2.4vw;color:#aaa">No hay más citas por hoy.</p>'; ?>
</body></html>
