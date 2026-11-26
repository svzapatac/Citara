<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$errores = []; $f = ['nombres' => '', 'apellidos' => '', 'tipo_documento' => 'CC', 'documento' => '', 'celular' => '', 'correo' => '', 'fecha_ingreso' => date('Y-m-d'), 'periodicidad_pago' => 'quincenal', 'areas' => [], 'servicios' => []];
$areas = q_all("SELECT id, nombre FROM area WHERE negocio_id = ? AND activa = 1 ORDER BY id", [$NEG]);
$servs = q_all("SELECT id, nombre FROM servicio WHERE negocio_id = ? AND activo = 1 ORDER BY nombre", [$NEG]);
if (es_post() && csrf_ok()) {
    foreach (['nombres', 'apellidos', 'tipo_documento', 'documento', 'celular', 'correo', 'fecha_ingreso', 'periodicidad_pago'] as $k) $f[$k] = trim($_POST[$k] ?? '');
    $f['areas'] = array_map('intval', (array)($_POST['areas'] ?? [])); $f['servicios'] = array_map('intval', (array)($_POST['servicios'] ?? []));
    if ($f['nombres'] === '' || $f['apellidos'] === '') $errores[] = 'Escribe nombres y apellidos.';
    if (!in_array($f['tipo_documento'], ['CC', 'CE', 'TI', 'PA', 'PPT'], true)) $errores[] = 'Tipo de documento no válido.';
    if ($f['documento'] === '') $errores[] = 'El documento es obligatorio.';
    if (!in_array($f['periodicidad_pago'], ['diario', 'semanal', 'quincenal', 'mensual'], true)) $errores[] = 'Periodicidad no válida.';
    if ($f['correo'] !== '' && !filter_var($f['correo'], FILTER_VALIDATE_EMAIL)) $errores[] = 'El correo no es válido.';
    if (!$errores && q_val("SELECT 1 FROM empleado WHERE negocio_id = ? AND tipo_documento = ? AND documento = ?", [$NEG, $f['tipo_documento'], $f['documento']])) $errores[] = 'Ya hay un empleado con ese documento.';
    if (!$errores) {
        $conexion->begin_transaction();
        try {
            $id = q_insert("INSERT INTO empleado (negocio_id, sede_id, tipo_documento, documento, nombres, apellidos, celular, correo, fecha_ingreso, periodicidad_pago) VALUES (?,?,?,?,?,?,?,?,?,?)",
                [$NEG, $SEDE, $f['tipo_documento'], $f['documento'], $f['nombres'], $f['apellidos'], $f['celular'] ?: null, $f['correo'] ?: null, $f['fecha_ingreso'], $f['periodicidad_pago']]);
            foreach ($f['areas'] as $a) if (q_val("SELECT 1 FROM area WHERE negocio_id = ? AND id = ?", [$NEG, $a])) q_run("INSERT IGNORE INTO empleado_area (negocio_id, empleado_id, area_id) VALUES (?,?,?)", [$NEG, $id, $a]);
            foreach ($f['servicios'] as $s) if (q_val("SELECT 1 FROM servicio WHERE negocio_id = ? AND id = ?", [$NEG, $s])) q_run("INSERT IGNORE INTO empleado_servicio (negocio_id, empleado_id, servicio_id) VALUES (?,?,?)", [$NEG, $id, $s]);
            $conexion->commit(); flash('Empleado registrado. Ahora sube su documentación en el expediente.');
            header('Location: expediente.php?id=' . $id); exit;
        } catch (Throwable $e) { $conexion->rollback(); $errores[] = 'No se pudo guardar: ' . $e->getMessage(); }
    }
}
cabecera('Registrar empleado', 'equipo');
?>
    <h1 class="mb-3">Registrar empleado</h1><?php errores_html($errores); ?>
    <form method="post" class="card p-4" style="max-width:820px"><?= csrf() ?><div class="row g-3">
      <div class="col-md-6"><label class="form-label">Nombres</label><input name="nombres" class="form-control" required value="<?= h($f['nombres']) ?>"></div>
      <div class="col-md-6"><label class="form-label">Apellidos</label><input name="apellidos" class="form-control" required value="<?= h($f['apellidos']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Tipo de documento</label><select name="tipo_documento" class="form-select"><?php foreach (['CC', 'CE', 'TI', 'PA', 'PPT'] as $t): ?><option <?= $f['tipo_documento'] === $t ? 'selected' : '' ?>><?= $t ?></option><?php endforeach; ?></select></div>
      <div class="col-md-4"><label class="form-label">Documento</label><input name="documento" class="form-control" required value="<?= h($f['documento']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Celular</label><input name="celular" class="form-control" value="<?= h($f['celular']) ?>"></div>
      <div class="col-md-5"><label class="form-label">Correo</label><input name="correo" type="email" class="form-control" value="<?= h($f['correo']) ?>"></div>
      <div class="col-md-4"><label class="form-label">Fecha de ingreso</label><input name="fecha_ingreso" type="date" class="form-control" value="<?= h($f['fecha_ingreso']) ?>"></div>
      <div class="col-md-3"><label class="form-label">Pago</label><select name="periodicidad_pago" class="form-select"><?php foreach (['diario', 'semanal', 'quincenal', 'mensual'] as $t): ?><option <?= $f['periodicidad_pago'] === $t ? 'selected' : '' ?>><?= $t ?></option><?php endforeach; ?></select></div>
      <div class="col-12"><label class="form-label d-block">Áreas</label><div class="d-flex flex-wrap gap-2"><?php foreach ($areas as $a): ?><input type="checkbox" class="btn-check" name="areas[]" value="<?= (int)$a['id'] ?>" id="a<?= (int)$a['id'] ?>" <?= in_array((int)$a['id'], $f['areas'], true) ? 'checked' : '' ?>><label class="btn btn-outline-dark rounded-pill" for="a<?= (int)$a['id'] ?>"><?= h($a['nombre']) ?></label><?php endforeach; ?></div></div>
      <div class="col-12"><label class="form-label d-block">Servicios que realiza</label><div class="d-flex flex-wrap gap-2"><?php foreach ($servs as $s): ?><input type="checkbox" class="btn-check" name="servicios[]" value="<?= (int)$s['id'] ?>" id="s<?= (int)$s['id'] ?>" <?= in_array((int)$s['id'], $f['servicios'], true) ? 'checked' : '' ?>><label class="btn btn-outline-dark rounded-pill" for="s<?= (int)$s['id'] ?>"><?= h($s['nombre']) ?></label><?php endforeach; ?></div></div>
    </div><div class="d-flex justify-content-end gap-2 mt-4"><a href="equipo.php" class="btn btn-secondary px-4">Cancelar</a><button class="btn btn-primary px-4">Guardar empleado</button></div></form>
<?php pie();
