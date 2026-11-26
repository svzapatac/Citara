<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$errores = []; $f = ['nombre' => '', 'tipo' => 'venta', 'codigo' => '', 'unidad' => 'unidad', 'costo' => '0', 'precio_publico' => '', 'precio_empleado' => '', 'stock_minimo' => '0', 'proveedor' => '', 'inicial' => '0'];
if (es_post() && csrf_ok()) {
    foreach ($f as $k => $_) $f[$k] = trim($_POST[$k] ?? '');
    $n = fn($v) => (float)str_replace(['.', ','], ['', '.'], $v);
    if ($f['nombre'] === '') $errores[] = 'Escribe el nombre.';
    if (!in_array($f['tipo'], ['venta', 'dotacion', 'uso_interno'], true)) $errores[] = 'Tipo no válido.';
    $pp = $pe = null;
    if ($f['tipo'] === 'venta') { $pp = $n($f['precio_publico']); $pe = $n($f['precio_empleado']); if ($pp <= 0) $errores[] = 'Indica el precio al público.'; if ($pe < 0 || $pe > $pp) $errores[] = 'El precio para empleados debe estar entre 0 y el precio al público.'; }
    if (!$errores) {
        $conexion->begin_transaction();
        try {
            $id = q_insert("INSERT INTO producto (negocio_id, nombre, tipo, codigo, unidad, costo, precio_publico, precio_empleado, stock_minimo, proveedor) VALUES (?,?,?,?,?,?,?,?,?,?)",
                [$NEG, $f['nombre'], $f['tipo'], $f['codigo'] ?: null, $f['unidad'] ?: 'unidad', $n($f['costo']), $pp, $pe, (int)$f['stock_minimo'], $f['proveedor'] ?: null]);
            if ((int)$f['inicial'] > 0) mover_inventario($NEG, $id, $SEDE, 'compra', (int)$f['inicial'], $UID, null, null, 'Existencia inicial');
            $conexion->commit(); flash('Producto creado.'); header('Location: inventario.php'); exit;
        } catch (Throwable $e) { $conexion->rollback(); $errores[] = 'No se pudo guardar: ' . $e->getMessage(); }
    }
}
cabecera('Nuevo producto', 'inventario');
?>
    <h1 class="mb-3">Nuevo producto</h1><?php errores_html($errores); ?>
    <form method="post" class="card p-4" style="max-width:760px"><?= csrf() ?><div class="row g-3">
      <div class="col-md-8"><label class="form-label">Nombre</label><input name="nombre" class="form-control" required value="<?= h($f['nombre']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Tipo</label><select name="tipo" class="form-select"><?php foreach (['venta' => 'Para la venta', 'dotacion' => 'Dotación', 'uso_interno' => 'Uso interno'] as $k => $v): ?><option value="<?= $k ?>" <?= $f['tipo'] === $k ? 'selected' : '' ?>><?= $v ?></option><?php endforeach; ?></select></div>
      <div class="col-md-4"><label class="form-label">Código</label><input name="codigo" class="form-control" value="<?= h($f['codigo']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Unidad</label><input name="unidad" class="form-control" value="<?= h($f['unidad']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Costo</label><input name="costo" class="form-control" value="<?= h($f['costo']) ?>"></div>
      <div class="col-md-6"><label class="form-label">Precio al público <small class="text-secondary">(solo venta)</small></label><input name="precio_publico" class="form-control" value="<?= h($f['precio_publico']) ?>"></div>
      <div class="col-md-6"><label class="form-label">Precio para empleados <small class="text-secondary">(solo venta)</small></label><input name="precio_empleado" class="form-control" value="<?= h($f['precio_empleado']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Stock mínimo</label><input name="stock_minimo" type="number" min="0" class="form-control" value="<?= h($f['stock_minimo']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Existencia inicial</label><input name="inicial" type="number" min="0" class="form-control" value="<?= h($f['inicial']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Proveedor</label><input name="proveedor" class="form-control" value="<?= h($f['proveedor']) ?>"></div>
    </div><div class="d-flex justify-content-end gap-2 mt-4"><a href="inventario.php" class="btn btn-secondary px-4">Cancelar</a><button class="btn btn-primary px-4">Guardar producto</button></div></form>
<?php pie();
