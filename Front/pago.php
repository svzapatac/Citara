<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
if (es_post() && csrf_ok()) {
    try {
        if (isset($_POST['pagar'])) {
            q_run("UPDATE liquidacion SET estado = 'pagado', pagado_por = ?, pagado_en = UTC_TIMESTAMP() WHERE negocio_id = ? AND id = ? AND estado = 'pendiente'", [$UID, $NEG, (int)$_POST['pagar']]);
            flash('Pago registrado.');
        } else {
            $emp = (int)$_POST['empleado_id']; $d = $_POST['desde'] ?? ''; $h2 = $_POST['hasta'] ?? '';
            $e = q_row("SELECT periodicidad_pago FROM empleado WHERE negocio_id = ? AND id = ? AND sede_id = ?", [$NEG, $emp, $SEDE]);
            if (!$e) throw new RuntimeException('Elige un empleado.');
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $d) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $h2) || $h2 < $d) throw new RuntimeException('Revisa el rango de fechas.');
            $conexion->begin_transaction();
            $com = q_all("SELECT cs.id, cs.valor, s.nombre,
                 COALESCE((SELECT c.porcentaje FROM comision c WHERE c.negocio_id = cs.negocio_id AND c.empleado_id = cs.empleado_id AND c.servicio_id = cs.servicio_id AND c.vigente_desde <= DATE(cs.inicio) AND (c.vigente_hasta IS NULL OR c.vigente_hasta >= DATE(cs.inicio)) ORDER BY c.vigente_desde DESC LIMIT 1), 0) AS pct
                 FROM cita_servicio cs JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
                 WHERE cs.negocio_id = ? AND cs.empleado_id = ? AND cs.estado = 'realizado' AND DATE(cs.inicio) BETWEEN ? AND ?
                   AND NOT EXISTS (SELECT 1 FROM liquidacion_detalle ld WHERE ld.negocio_id = cs.negocio_id AND ld.cita_servicio_id = cs.id)", [$NEG, $emp, $d, $h2]);
            $des = q_all("SELECT v.id, v.cantidad * v.precio_cobrado AS valor, p.nombre FROM venta_producto v JOIN producto p ON p.negocio_id = v.negocio_id AND p.id = v.producto_id
                 WHERE v.negocio_id = ? AND v.empleado_id = ? AND v.destino = 'uso_personal' AND v.fecha BETWEEN ? AND ?
                   AND NOT EXISTS (SELECT 1 FROM liquidacion_detalle ld WHERE ld.negocio_id = v.negocio_id AND ld.venta_id = v.id)", [$NEG, $emp, $d, $h2]);
            if (!$com && !$des) throw new RuntimeException('No hay nada por liquidar en ese rango.');
            $tc = 0; foreach ($com as $c) $tc += round($c['valor'] * $c['pct'] / 100, 2);
            $td = 0; foreach ($des as $x) $td += (float)$x['valor'];
            $lid = q_insert("INSERT INTO liquidacion (negocio_id, empleado_id, periodicidad, desde, hasta, total_comisiones, total_descuentos, total_neto) VALUES (?,?,?,?,?,?,?,?)", [$NEG, $emp, $e['periodicidad_pago'], $d, $h2, $tc, $td, $tc - $td]);
            foreach ($com as $c) q_run("INSERT INTO liquidacion_detalle (negocio_id, liquidacion_id, cita_servicio_id, tipo, descripcion, base, porcentaje, valor) VALUES (?,?,?,'comision',?,?,?,?)", [$NEG, $lid, $c['id'], $c['nombre'], $c['valor'], $c['pct'], round($c['valor'] * $c['pct'] / 100, 2)]);
            foreach ($des as $x) q_run("INSERT INTO liquidacion_detalle (negocio_id, liquidacion_id, venta_id, tipo, descripcion, valor) VALUES (?,?,?,'descuento_personal',?,?)", [$NEG, $lid, $x['id'], $x['nombre'], $x['valor']]);
            $conexion->commit(); flash('Liquidación generada.');
        }
    } catch (Throwable $x) { try { $conexion->rollback(); } catch (Throwable $_) {} flash($x->getMessage(), 'danger'); }
    header('Location: pago.php'); exit;
}
$emps = q_all("SELECT id, nombres, apellidos FROM empleado WHERE negocio_id = ? AND sede_id = ? AND activo = 1 ORDER BY nombres", [$NEG, $SEDE]);
$rows = q_all("SELECT l.*, CONCAT(e.nombres,' ',e.apellidos) AS emp FROM liquidacion l JOIN empleado e ON e.negocio_id = l.negocio_id AND e.id = l.empleado_id WHERE l.negocio_id = ? AND e.sede_id = ? ORDER BY l.hasta DESC, l.id DESC LIMIT 60", [$NEG, $SEDE]);
cabecera('Pagos', 'pagos');
?>
    <h1 class="mb-1">Pagos al equipo</h1><p class="text-secondary mb-3">Liquidaciones de comisiones menos descuentos por productos de uso personal.</p>
    <div class="row g-3"><div class="col-12 col-xl-8"><div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Profesional</th><th>Periodo</th><th class="text-end">Comisiones</th><th class="text-end">Descuentos</th><th class="text-end">Neto</th><th></th></tr></thead><tbody>
      <?php foreach ($rows as $r): ?><tr><td class="nombre-fila"><?= h($r['emp']) ?></td><td><?= fecha_corta($r['desde']) ?> – <?= fecha_corta($r['hasta']) ?></td><td class="text-end"><?= pesos($r['total_comisiones']) ?></td><td class="text-end"><?= pesos($r['total_descuentos']) ?></td><td class="text-end"><strong><?= pesos($r['total_neto']) ?></strong></td>
        <td class="text-end"><?php if ($r['estado'] === 'pendiente'): ?><form method="post"><?= csrf() ?><button name="pagar" value="<?= (int)$r['id'] ?>" class="btn btn-sm btn-primary">Marcar pagado</button></form><?php else: ?><span class="badge text-bg-success">Pagado</span><?php endif; ?></td></tr>
      <?php endforeach; if (!$rows) echo '<tr><td colspan="6" class="text-center text-secondary py-4">Aún no hay liquidaciones.</td></tr>'; ?></tbody></table></div></div></div>
    <div class="col-12 col-xl-4"><form method="post" class="card p-4"><?= csrf() ?><p class="etiqueta mb-2">Generar liquidación</p>
      <label class="form-label">Profesional</label><select name="empleado_id" class="form-select mb-2"><?php foreach ($emps as $e): ?><option value="<?= (int)$e['id'] ?>"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></option><?php endforeach; ?></select>
      <label class="form-label">Desde</label><input type="date" name="desde" class="form-control mb-2" value="<?= date('Y-m-01') ?>"><label class="form-label">Hasta</label><input type="date" name="hasta" class="form-control mb-3" value="<?= date('Y-m-d') ?>"><button class="btn btn-primary">Generar</button></form></div></div>
<?php pie();
