<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$id = (int)($_GET['id'] ?? 0);
if (es_post() && csrf_ok() && isset($_POST['cita_id'])) {   // emitir factura de una cita
    $cid = (int)$_POST['cita_id'];
    try { $fid = emitir_factura($NEG, $cid, $_POST['metodo'] ?? 'efectivo'); flash('Factura emitida.'); header('Location: factura.php?id=' . (int)$fid); }
    catch (Throwable $e) { flash($e->getMessage(), 'danger'); header('Location: agenda.php'); }
    exit;
}
$f = q_row("SELECT f.*, ci.fecha, CONCAT(c.nombres,' ',c.apellidos) AS cliente, c.celular FROM factura f JOIN cita ci ON ci.negocio_id = f.negocio_id AND ci.id = f.cita_id JOIN cliente c ON c.negocio_id = ci.negocio_id AND c.id = ci.cliente_id WHERE f.negocio_id = ? AND f.id = ?", [$NEG, $id]);
if (!$f) { flash('No encontramos esa factura.', 'danger'); header('Location: facturas.php'); exit; }
$lin = q_all("SELECT l.descripcion, l.valor, e.nombres FROM factura_linea l LEFT JOIN empleado e ON e.negocio_id = l.negocio_id AND e.id = l.empleado_id WHERE l.negocio_id = ? AND l.factura_id = ? ORDER BY l.id", [$NEG, $id]);
cabecera('Factura ' . $f['numero'], 'facturas');
?>
    <a href="facturas.php" class="enlace-suave small"><i class="bi bi-arrow-left"></i> Facturas</a>
    <div class="card p-4 mt-2" style="max-width:640px">
      <div class="d-flex justify-content-between"><div><p class="etiqueta mb-1">Factura</p><h1 class="h3"><?= h($f['numero']) ?></h1></div><span class="badge align-self-start <?= $f['estado'] === 'emitida' ? 'text-bg-success' : 'text-bg-secondary' ?>"><?= h(ucfirst($f['estado'])) ?></span></div>
      <p class="mb-3 text-secondary"><?= h($f['cliente']) ?> · <?= h($f['celular']) ?><br>Cita del <?= fecha_completa($f['fecha']) ?> · <?= h(ucfirst($f['metodo_pago'])) ?></p>
      <?php foreach ($lin as $l): ?><div class="linea-servicio"><div><strong class="d-block"><?= h($l['descripcion']) ?></strong><?php if ($l['nombres']): ?><small><?= h($l['nombres']) ?></small><?php endif; ?></div><strong><?= pesos($l['valor']) ?></strong></div><?php endforeach; ?>
      <div class="d-flex justify-content-between align-items-baseline mt-3"><span class="etiqueta">Total</span><strong class="fs-3"><?= pesos($f['total']) ?></strong></div>
      <button class="btn btn-secondary mt-3 align-self-start" onclick="window.print()"><i class="bi bi-printer me-2"></i>Imprimir</button>
    </div>
<?php pie();
