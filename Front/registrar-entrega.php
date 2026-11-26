<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$errores = [];
$emps = q_all("SELECT id, nombres, apellidos FROM empleado WHERE negocio_id = ? AND sede_id = ? AND activo = 1 ORDER BY nombres", [$NEG, $SEDE]);
$prods = q_all("SELECT id, nombre, tipo, precio_empleado FROM producto WHERE negocio_id = ? AND activo = 1 ORDER BY tipo, nombre", [$NEG]);
$f = ['empleado_id' => (int)($_GET['empleado'] ?? 0), 'producto_id' => (int)($_GET['producto'] ?? 0), 'cantidad' => 1, 'nota' => ''];
if (es_post() && csrf_ok()) {
    $f['empleado_id'] = (int)$_POST['empleado_id']; $f['producto_id'] = (int)$_POST['producto_id']; $f['cantidad'] = (int)$_POST['cantidad']; $f['nota'] = trim($_POST['nota'] ?? '');
    $p = q_row("SELECT * FROM producto WHERE negocio_id = ? AND id = ?", [$NEG, $f['producto_id']]);
    if (!$p) $errores[] = 'Elige un producto.';
    if (!q_val("SELECT 1 FROM empleado WHERE negocio_id = ? AND id = ?", [$NEG, $f['empleado_id']])) $errores[] = 'Elige un empleado.';
    if ($f['cantidad'] < 1) $errores[] = 'La cantidad debe ser al menos 1.';
    if (!$errores) {
        $conexion->begin_transaction();
        try {
            $eid = q_insert("INSERT INTO entrega_interna (negocio_id, producto_id, empleado_id, entregada_por, tipo, cantidad, precio_unitario, nota) VALUES (?,?,?,?,?,?,?,?)",
                [$NEG, $f['producto_id'], $f['empleado_id'], $UID, $p['tipo'], $f['cantidad'], $p['tipo'] === 'venta' ? $p['precio_empleado'] : null, $f['nota'] ?: null]);
            if (!hay_triggers()) mover_inventario($NEG, $f['producto_id'], $SEDE, 'entrega', -$f['cantidad'], $UID, $eid, null, $f['nota'] ?: null);
            $conexion->commit(); flash('Entrega registrada.'); header('Location: dotacion.php'); exit;
        } catch (Throwable $e) { $conexion->rollback(); $errores[] = $e->getMessage(); }
    }
}
cabecera('Registrar entrega', 'inventario');
?>
    <h1 class="mb-3">Registrar entrega</h1><?php errores_html($errores); ?>
    <form method="post" class="card p-4" style="max-width:640px"><?= csrf() ?><div class="row g-3">
      <div class="col-12"><label class="form-label">Empleado</label><select name="empleado_id" class="form-select" required><option value="">Elige…</option><?php foreach ($emps as $e): ?><option value="<?= (int)$e['id'] ?>" <?= $f['empleado_id'] === (int)$e['id'] ? 'selected' : '' ?>><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></option><?php endforeach; ?></select></div>
      <div class="col-md-8"><label class="form-label">Producto</label><select name="producto_id" class="form-select" required><option value="">Elige…</option><?php foreach ($prods as $p): ?><option value="<?= (int)$p['id'] ?>" <?= $f['producto_id'] === (int)$p['id'] ? 'selected' : '' ?>><?= h($p['nombre']) ?> (<?= h($p['tipo']) ?>)</option><?php endforeach; ?></select></div>
      <div class="col-md-4"><label class="form-label">Cantidad</label><input name="cantidad" type="number" min="1" class="form-control" value="<?= (int)$f['cantidad'] ?>"></div>
      <div class="col-12"><label class="form-label">Nota</label><input name="nota" class="form-control" maxlength="200" value="<?= h($f['nota']) ?>"></div>
    </div><div class="d-flex justify-content-end gap-2 mt-4"><a href="inventario.php" class="btn btn-secondary px-4">Cancelar</a><button class="btn btn-primary px-4">Registrar entrega</button></div></form>
<?php pie();
