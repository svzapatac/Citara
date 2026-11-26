<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
if (es_post() && csrf_ok()) {    // registrar compra / ajuste de bodega
    $pid = (int)($_POST['producto_id'] ?? 0); $cant = (int)($_POST['cantidad'] ?? 0); $tipo = ($_POST['tipo'] ?? 'compra') === 'ajuste' ? 'ajuste' : 'compra';
    try {
        if (!q_val("SELECT 1 FROM producto WHERE negocio_id = ? AND id = ?", [$NEG, $pid])) throw new RuntimeException('Elige un producto.');
        if ($cant === 0 || ($tipo === 'compra' && $cant < 0)) throw new RuntimeException('La cantidad no es válida.');
        mover_inventario($NEG, $pid, $SEDE, $tipo, $cant, $UID, null, null, trim($_POST['nota'] ?? '') ?: null);
        flash('Inventario actualizado.');
    } catch (Throwable $e) { flash($e->getMessage(), 'danger'); }
    header('Location: inventario.php'); exit;
}
$rows = q_all("SELECT p.id, p.nombre, p.tipo, p.precio_publico, p.stock_minimo, p.activo, COALESCE((SELECT SUM(m.cantidad) FROM movimiento_inventario m WHERE m.negocio_id = p.negocio_id AND m.producto_id = p.id AND m.sede_id = ?), 0) AS existencia
   FROM producto p WHERE p.negocio_id = ? AND p.activo = 1 ORDER BY p.tipo, p.nombre", [$SEDE, $NEG]);
$TIPO = ['venta' => 'Para la venta', 'dotacion' => 'Dotación', 'uso_interno' => 'Uso interno'];
cabecera('Inventario', 'inventario');
?>
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div><h1 class="mb-1">Inventario</h1><p class="text-secondary mb-0">Existencias de la bodega de esta sede.</p></div>
      <div class="d-flex gap-2"><a href="registrar-entrega.php" class="btn btn-secondary"><i class="bi bi-box-arrow-right me-2"></i>Entregar a empleado</a><a href="producto-nuevo.php" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Nuevo producto</a></div>
    </div>
    <div class="row g-3"><div class="col-12 col-xl-8"><div class="card p-2 p-md-3"><div class="table-responsive"><table class="table table-hover tabla-citara">
      <thead><tr><th>Producto</th><th>Tipo</th><th class="text-end">Existencia</th><th class="text-end">Mínimo</th><th class="text-end">Precio</th></tr></thead><tbody>
      <?php foreach ($rows as $r): $bajo = (int)$r['existencia'] <= (int)$r['stock_minimo']; ?><tr>
        <td class="nombre-fila"><?= h($r['nombre']) ?></td><td><?= h($TIPO[$r['tipo']] ?? $r['tipo']) ?></td>
        <td class="text-end"><span class="<?= $bajo ? 'text-danger fw-semibold' : '' ?>"><?= (int)$r['existencia'] ?></span><?= $bajo ? ' <i class="bi bi-exclamation-triangle text-danger"></i>' : '' ?></td>
        <td class="text-end"><?= (int)$r['stock_minimo'] ?></td><td class="text-end"><?= $r['precio_publico'] !== null ? pesos($r['precio_publico']) : '—' ?></td></tr>
      <?php endforeach; ?></tbody></table></div></div></div>
      <div class="col-12 col-xl-4"><form method="post" class="card p-4"><?= csrf() ?><p class="etiqueta mb-2">Registrar entrada o ajuste</p>
        <label class="form-label">Producto</label><select name="producto_id" class="form-select mb-2" required><option value="">Elige…</option><?php foreach ($rows as $r): ?><option value="<?= (int)$r['id'] ?>"><?= h($r['nombre']) ?></option><?php endforeach; ?></select>
        <label class="form-label">Movimiento</label><select name="tipo" class="form-select mb-2"><option value="compra">Compra (suma)</option><option value="ajuste">Ajuste (+/−)</option></select>
        <label class="form-label">Cantidad</label><input name="cantidad" type="number" class="form-control mb-2" required>
        <label class="form-label">Nota</label><input name="nota" class="form-control mb-3" maxlength="200">
        <button class="btn btn-primary">Guardar</button></form></div></div>
<?php pie();
