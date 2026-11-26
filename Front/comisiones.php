<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
if (es_post() && csrf_ok()) {
    $emp = (int)$_POST['empleado_id']; $srv = (int)$_POST['servicio_id']; $pct = (float)str_replace(',', '.', $_POST['porcentaje'] ?? '-1');
    if ($pct < 0 || $pct > 100 || !q_val("SELECT 1 FROM empleado_servicio WHERE negocio_id = ? AND empleado_id = ? AND servicio_id = ?", [$NEG, $emp, $srv])) flash('Revisa el empleado, el servicio y el porcentaje (0–100).', 'danger');
    else {
        $conexion->begin_transaction();
        q_run("UPDATE comision SET vigente_hasta = DATE_SUB(CURDATE(), INTERVAL 1 DAY) WHERE negocio_id = ? AND empleado_id = ? AND servicio_id = ? AND vigente_hasta IS NULL AND vigente_desde < CURDATE()", [$NEG, $emp, $srv]);
        q_run("DELETE FROM comision WHERE negocio_id = ? AND empleado_id = ? AND servicio_id = ? AND vigente_desde = CURDATE()", [$NEG, $emp, $srv]);
        q_run("INSERT INTO comision (negocio_id, empleado_id, servicio_id, porcentaje, vigente_desde) VALUES (?,?,?,?,CURDATE())", [$NEG, $emp, $srv, $pct]);
        $conexion->commit(); flash('Comisión actualizada.');
    }
    header('Location: comisiones.php'); exit;
}
$rows = q_all("SELECT e.id AS eid, CONCAT(e.nombres,' ',e.apellidos) AS emp, s.id AS sid, s.nombre AS servicio,
   (SELECT c.porcentaje FROM comision c WHERE c.negocio_id = es.negocio_id AND c.empleado_id = es.empleado_id AND c.servicio_id = es.servicio_id AND c.vigente_desde <= CURDATE() AND (c.vigente_hasta IS NULL OR c.vigente_hasta >= CURDATE()) ORDER BY c.vigente_desde DESC LIMIT 1) AS pct
   FROM empleado_servicio es JOIN empleado e ON e.negocio_id = es.negocio_id AND e.id = es.empleado_id JOIN servicio s ON s.negocio_id = es.negocio_id AND s.id = es.servicio_id
   WHERE es.negocio_id = ? AND e.sede_id = ? AND e.activo = 1 ORDER BY e.nombres, s.nombre", [$NEG, $SEDE]);
cabecera('Comisiones', 'comisiones');
?>
    <h1 class="mb-1">Comisiones</h1><p class="text-secondary mb-3">Porcentaje que gana cada profesional por servicio. Un cambio rige desde hoy; no altera liquidaciones pasadas.</p>
    <div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Profesional</th><th>Servicio</th><th style="width:220px">Porcentaje</th></tr></thead><tbody>
    <?php foreach ($rows as $r): ?><tr><td class="nombre-fila"><?= h($r['emp']) ?></td><td><?= h($r['servicio']) ?></td><td><form method="post" class="input-group input-group-sm"><?= csrf() ?><input type="hidden" name="empleado_id" value="<?= (int)$r['eid'] ?>"><input type="hidden" name="servicio_id" value="<?= (int)$r['sid'] ?>"><input name="porcentaje" class="form-control" value="<?= $r['pct'] !== null ? rtrim(rtrim($r['pct'], '0'), '.') : '' ?>" placeholder="—"><span class="input-group-text">%</span><button class="btn btn-secondary">Guardar</button></form></td></tr><?php endforeach; ?></tbody></table></div></div>
<?php pie();
