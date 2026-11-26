<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$errores = []; $f = ['nombre' => '', 'area_id' => 0, 'duracion_min' => 30, 'precio' => '', 'descripcion' => '', 'emp' => []];
$areas = q_all("SELECT id, nombre FROM area WHERE negocio_id = ? AND activa = 1 ORDER BY id", [$NEG]);
$emps = q_all("SELECT id, nombres, apellidos FROM empleado WHERE negocio_id = ? AND activo = 1 ORDER BY nombres", [$NEG]);
if (es_post() && csrf_ok()) {
    $f['nombre'] = trim($_POST['nombre'] ?? ''); $f['area_id'] = (int)($_POST['area_id'] ?? 0); $f['duracion_min'] = (int)($_POST['duracion_min'] ?? 0);
    $f['precio'] = (float)str_replace(['.', ','], ['', '.'], $_POST['precio'] ?? '0'); $f['descripcion'] = trim($_POST['descripcion'] ?? ''); $f['emp'] = array_map('intval', (array)($_POST['emp'] ?? []));
    if ($f['nombre'] === '') $errores[] = 'Escribe el nombre del servicio.';
    if (!q_val("SELECT 1 FROM area WHERE negocio_id = ? AND id = ?", [$NEG, $f['area_id']])) $errores[] = 'Elige un área.';
    if ($f['duracion_min'] < 5 || $f['duracion_min'] > 600) $errores[] = 'La duración debe estar entre 5 y 600 minutos.';
    if ($f['precio'] <= 0) $errores[] = 'El precio debe ser mayor que 0.';
    if (!$errores) {
        $conexion->begin_transaction();
        try {
            $id = q_insert("INSERT INTO servicio (negocio_id, area_id, nombre, descripcion, duracion_min, precio) VALUES (?,?,?,?,?,?)", [$NEG, $f['area_id'], $f['nombre'], $f['descripcion'] ?: null, $f['duracion_min'], $f['precio']]);
            foreach ($f['emp'] as $e) if (q_val("SELECT 1 FROM empleado WHERE negocio_id = ? AND id = ?", [$NEG, $e])) q_run("INSERT IGNORE INTO empleado_servicio (negocio_id, empleado_id, servicio_id) VALUES (?,?,?)", [$NEG, $e, $id]);
            $conexion->commit(); flash('Servicio creado.'); header('Location: servicios.php'); exit;
        } catch (Throwable $e) { $conexion->rollback(); $errores[] = 'No se pudo guardar: ' . $e->getMessage(); }
    }
}
cabecera('Nuevo servicio', 'servicios');
?>
    <h1 class="mb-3">Nuevo servicio</h1><?php errores_html($errores); ?>
    <form method="post" class="card p-4" style="max-width:760px"><?= csrf() ?><div class="row g-3">
      <div class="col-md-8"><label class="form-label" for="n">Nombre</label><input id="n" name="nombre" class="form-control" required value="<?= h($f['nombre']) ?>"></div>
      <div class="col-md-4"><label class="form-label" for="ar">Área</label><select id="ar" name="area_id" class="form-select"><?php foreach ($areas as $a): ?><option value="<?= (int)$a['id'] ?>" <?= $f['area_id'] === (int)$a['id'] ? 'selected' : '' ?>><?= h($a['nombre']) ?></option><?php endforeach; ?></select></div>
      <div class="col-md-6"><label class="form-label" for="du">Duración (minutos)</label><input id="du" name="duracion_min" type="number" min="5" step="5" class="form-control" value="<?= (int)$f['duracion_min'] ?>"></div>
      <div class="col-md-6"><label class="form-label" for="pr">Precio (COP)</label><input id="pr" name="precio" class="form-control" inputmode="numeric" required value="<?= h($f['precio']) ?>"></div>
      <div class="col-12"><label class="form-label" for="de">Descripción (opcional)</label><input id="de" name="descripcion" class="form-control" maxlength="300" value="<?= h($f['descripcion']) ?>"></div>
      <div class="col-12"><label class="form-label d-block">Profesionales que lo realizan</label><div class="d-flex flex-wrap gap-2">
        <?php foreach ($emps as $e): ?><input type="checkbox" class="btn-check" name="emp[]" value="<?= (int)$e['id'] ?>" id="e<?= (int)$e['id'] ?>" <?= in_array((int)$e['id'], $f['emp'], true) ? 'checked' : '' ?>><label class="btn btn-outline-dark rounded-pill" for="e<?= (int)$e['id'] ?>"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></label><?php endforeach; ?></div></div>
    </div><div class="d-flex justify-content-end gap-2 mt-4"><a href="servicios.php" class="btn btn-secondary px-4">Cancelar</a><button class="btn btn-primary px-4">Guardar servicio</button></div></form>
<?php pie();
