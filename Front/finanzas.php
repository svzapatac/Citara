<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$mes = preg_match('/^\d{4}-\d{2}$/', $_GET['mes'] ?? '') ? $_GET['mes'] : date('Y-m');
$d0 = "$mes-01"; $d1 = date('Y-m-t', strtotime($d0));
if (es_post() && csrf_ok()) {
    $v = (float)str_replace(['.', ','], ['', '.'], $_POST['valor'] ?? '0'); $cat = (int)($_POST['categoria_id'] ?? 0); $con = trim($_POST['concepto'] ?? '');
    if ($v > 0 && $con !== '' && q_val("SELECT 1 FROM categoria_gasto WHERE negocio_id = ? AND id = ?", [$NEG, $cat])) {
        q_run("INSERT INTO gasto (negocio_id, sede_id, categoria_id, registrado_por, concepto, valor, fecha) VALUES (?,?,?,?,?,?,?)", [$NEG, $SEDE, $cat, $UID, $con, $v, preg_match('/^\d{4}-\d{2}-\d{2}$/', $_POST['fecha'] ?? '') ? $_POST['fecha'] : date('Y-m-d')]);
        flash('Gasto registrado.');
    } else flash('Revisa el concepto, la categoría y el valor.', 'danger');
    header('Location: finanzas.php?mes=' . $mes); exit;
}
$ing = (float)q_val("SELECT COALESCE(SUM(f.total),0) FROM factura f JOIN cita c ON c.negocio_id = f.negocio_id AND c.id = f.cita_id WHERE f.negocio_id = ? AND c.sede_id = ? AND f.estado = 'emitida' AND DATE(f.emitida_en) BETWEEN ? AND ?", [$NEG, $SEDE, $d0, $d1]);
$gas = (float)q_val("SELECT COALESCE(SUM(valor),0) FROM gasto WHERE negocio_id = ? AND sede_id = ? AND fecha BETWEEN ? AND ?", [$NEG, $SEDE, $d0, $d1]);
$gastos = q_all("SELECT g.fecha, g.concepto, g.valor, cg.nombre AS cat FROM gasto g JOIN categoria_gasto cg ON cg.negocio_id = g.negocio_id AND cg.id = g.categoria_id WHERE g.negocio_id = ? AND g.sede_id = ? AND g.fecha BETWEEN ? AND ? ORDER BY g.fecha DESC LIMIT 50", [$NEG, $SEDE, $d0, $d1]);
$cats = q_all("SELECT id, nombre FROM categoria_gasto WHERE negocio_id = ? ORDER BY nombre", [$NEG]);
cabecera('Finanzas', 'finanzas');
?>
    <div class="d-flex flex-wrap justify-content-between gap-3 mb-3"><h1 class="mb-0">Finanzas</h1>
      <div class="d-flex align-items-center gap-2"><a class="btn btn-secondary" href="?mes=<?= date('Y-m', strtotime("$d0 -1 month")) ?>"><i class="bi bi-chevron-left"></i></a><strong><?= h(ucfirst(MESES[(int)date('n', strtotime($d0))])) ?> <?= date('Y', strtotime($d0)) ?></strong><a class="btn btn-secondary" href="?mes=<?= date('Y-m', strtotime("$d0 +1 month")) ?>"><i class="bi bi-chevron-right"></i></a></div></div>
    <div class="row g-3 mb-3">
      <div class="col-md-4"><div class="card p-4"><p class="etiqueta mb-1">Ingresos</p><strong class="fs-3"><?= pesos($ing) ?></strong></div></div>
      <div class="col-md-4"><div class="card p-4"><p class="etiqueta mb-1">Gastos</p><strong class="fs-3"><?= pesos($gas) ?></strong></div></div>
      <div class="col-md-4"><div class="card p-4"><p class="etiqueta mb-1">Resultado</p><strong class="fs-3 <?= $ing - $gas < 0 ? 'text-danger' : '' ?>"><?= pesos($ing - $gas) ?></strong></div></div>
    </div>
    <div class="row g-3"><div class="col-12 col-xl-8"><div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Fecha</th><th>Concepto</th><th>Categoría</th><th class="text-end">Valor</th></tr></thead><tbody>
      <?php foreach ($gastos as $g): ?><tr><td><?= fecha_corta($g['fecha']) ?></td><td><?= h($g['concepto']) ?></td><td><?= h($g['cat']) ?></td><td class="text-end"><?= pesos($g['valor']) ?></td></tr><?php endforeach; if (!$gastos) echo '<tr><td colspan="4" class="text-center text-secondary py-4">Sin gastos este mes.</td></tr>'; ?></tbody></table></div></div></div>
      <div class="col-12 col-xl-4"><form method="post" class="card p-4"><?= csrf() ?><p class="etiqueta mb-2">Registrar gasto</p>
        <label class="form-label">Concepto</label><input name="concepto" class="form-control mb-2" required maxlength="150">
        <label class="form-label">Categoría</label><select name="categoria_id" class="form-select mb-2"><?php foreach ($cats as $c): ?><option value="<?= (int)$c['id'] ?>"><?= h($c['nombre']) ?></option><?php endforeach; ?></select>
        <label class="form-label">Valor</label><input name="valor" class="form-control mb-2" required inputmode="numeric">
        <label class="form-label">Fecha</label><input name="fecha" type="date" class="form-control mb-3" value="<?= date('Y-m-d') ?>"><button class="btn btn-primary">Guardar gasto</button></form></div></div>
<?php pie();
