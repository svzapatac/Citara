<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(['empleado']);
$EMP = (int)($_SESSION['empleado_id'] ?? 0);
if (es_post() && csrf_ok() && ($cid = (int)($_POST['cs'] ?? 0))) {    // solo sus propios servicios
    q_run("UPDATE cita_servicio SET estado = 'realizado' WHERE negocio_id = ? AND id = ? AND empleado_id = ? AND estado IN ('programado','en curso') AND DATE(inicio) = CURDATE()", [$NEG, $cid, $EMP]);
    flash('Servicio marcado como realizado.'); header('Location: empleado-hoy.php'); exit;
}
$rows = q_all("SELECT cs.id, cs.inicio, cs.fin, cs.estado, s.nombre AS servicio, CONCAT(c.nombres,' ',c.apellidos) AS cliente FROM cita_servicio cs JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
   JOIN cita ci ON ci.negocio_id = cs.negocio_id AND ci.id = cs.cita_id JOIN cliente c ON c.negocio_id = ci.negocio_id AND c.id = ci.cliente_id
   WHERE cs.negocio_id = ? AND cs.empleado_id = ? AND DATE(cs.inicio) = CURDATE() AND cs.estado <> 'cancelado' ORDER BY cs.inicio", [$NEG, $EMP]);
cabecera('Mi día', 'hoy');
?>
    <h1 class="mb-1">Mi día</h1><p class="text-secondary mb-3"><?= fecha_larga(date('Y-m-d')) ?></p>
    <div class="card p-4" style="max-width:720px"><?php foreach ($rows as $r): ?><div class="linea-servicio"><div><strong class="d-block"><?= hora($r['inicio']) ?> · <?= h($r['servicio']) ?></strong><small><?= h($r['cliente']) ?> · hasta <?= hora($r['fin']) ?></small></div>
      <?php if ($r['estado'] === 'realizado'): ?><span class="badge text-bg-success">Realizado</span><?php else: ?><form method="post"><?= csrf() ?><button name="cs" value="<?= (int)$r['id'] ?>" class="btn btn-sm btn-primary">Marcar realizado</button></form><?php endif; ?></div><?php endforeach; if (!$rows) echo '<span class="text-secondary">No tienes servicios hoy.</span>'; ?></div>
<?php pie();
