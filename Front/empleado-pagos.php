<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(['empleado']);
$EMP = (int)($_SESSION['empleado_id'] ?? 0);
$rows = q_all("SELECT desde, hasta, total_comisiones, total_descuentos, total_neto, estado FROM liquidacion WHERE negocio_id = ? AND empleado_id = ? ORDER BY hasta DESC LIMIT 24", [$NEG, $EMP]);
$mes = q_row("SELECT ganancia, descuento_ventas, descuento_personal FROM v_ganancia_empleado WHERE negocio_id = ? AND empleado_id = ? ORDER BY mes DESC LIMIT 1", [$NEG, $EMP]);
cabecera('Mis pagos', 'pagos');
?>
    <h1 class="mb-3">Mis pagos</h1>
    <?php if ($mes): ?><div class="card p-4 mb-3" style="max-width:420px"><p class="etiqueta mb-1">Ganancia del mes</p><strong class="fs-3"><?= pesos($mes['ganancia']) ?></strong></div><?php endif; ?>
    <div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Periodo</th><th class="text-end">Comisiones</th><th class="text-end">Descuentos</th><th class="text-end">Neto</th><th>Estado</th></tr></thead><tbody>
    <?php foreach ($rows as $r): ?><tr><td><?= fecha_corta($r['desde']) ?> – <?= fecha_corta($r['hasta']) ?></td><td class="text-end"><?= pesos($r['total_comisiones']) ?></td><td class="text-end"><?= pesos($r['total_descuentos']) ?></td><td class="text-end"><strong><?= pesos($r['total_neto']) ?></strong></td><td><?= h(ucfirst($r['estado'])) ?></td></tr><?php endforeach; if (!$rows) echo '<tr><td colspan="5" class="text-center text-secondary py-4">Aún no tienes liquidaciones.</td></tr>'; ?></tbody></table></div></div>
<?php pie();
