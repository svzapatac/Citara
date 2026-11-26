<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$errores = []; $f = ['nombres' => '', 'apellidos' => '', 'celular' => '', 'correo' => '', 'tipo_documento' => 'CC', 'documento' => '', 'fecha_nacimiento' => '', 'origen' => 'administrador', 'notas' => '', 'acepta' => 1];
$ORI = ['administrador' => 'Lo registro yo', 'whatsapp' => 'WhatsApp', 'instagram' => 'Instagram', 'recomendacion' => 'Recomendación', 'local' => 'Llegó al local', 'otro' => 'Otro'];
if (es_post() && csrf_ok()) {
    foreach (['nombres', 'apellidos', 'celular', 'correo', 'tipo_documento', 'documento', 'fecha_nacimiento', 'origen', 'notas'] as $k) $f[$k] = trim($_POST[$k] ?? '');
    $f['acepta'] = isset($_POST['acepta']) ? 1 : 0;
    $f['celular'] = solo_digitos($f['celular']);
    if ($f['nombres'] === '' || $f['apellidos'] === '') $errores[] = 'Escribe nombres y apellidos.';
    if (strlen($f['celular']) < 7) $errores[] = 'El celular no es válido.';
    if ($f['correo'] !== '' && !filter_var($f['correo'], FILTER_VALIDATE_EMAIL)) $errores[] = 'El correo no es válido.';
    if (!isset($ORI[$f['origen']])) $f['origen'] = 'administrador';
    if (!$errores && q_val("SELECT 1 FROM cliente WHERE negocio_id = ? AND celular = ?", [$NEG, $f['celular']])) $errores[] = 'Ya existe un cliente con ese celular.';
    if (!$errores) {
        $id = q_insert("INSERT INTO cliente (negocio_id, nombres, apellidos, celular, correo, tipo_documento, documento, fecha_nacimiento, notas, acepta_recordatorios, origen) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            [$NEG, $f['nombres'], $f['apellidos'], $f['celular'], $f['correo'] ?: null, $f['documento'] ? $f['tipo_documento'] : null, $f['documento'] ?: null, $f['fecha_nacimiento'] ?: null, $f['notas'] ?: null, $f['acepta'], $f['origen']]);
        flash('Cliente registrado.');
        header('Location: ' . (($_GET['volver'] ?? '') === 'nueva-cita' ? 'nueva-cita.php?cliente=' . $id : 'clientes.php?id=' . $id)); exit;
    }
}
cabecera('Nuevo cliente', 'clientes');
?>
    <h1 class="mb-3">Nuevo cliente</h1>
    <?php errores_html($errores); ?>
    <form method="post" class="card p-4" style="max-width:760px"><?= csrf() ?>
      <div class="row g-3">
        <div class="col-md-6"><label class="form-label" for="n">Nombres</label><input id="n" name="nombres" class="form-control" required value="<?= h($f['nombres']) ?>"></div>
        <div class="col-md-6"><label class="form-label" for="a">Apellidos</label><input id="a" name="apellidos" class="form-control" required value="<?= h($f['apellidos']) ?>"></div>
        <div class="col-md-6"><label class="form-label" for="c">Celular</label><input id="c" name="celular" class="form-control" required value="<?= h($f['celular']) ?>"></div>
        <div class="col-md-6"><label class="form-label" for="e">Correo (opcional)</label><input id="e" name="correo" type="email" class="form-control" value="<?= h($f['correo']) ?>"></div>
        <div class="col-md-4"><label class="form-label" for="td">Tipo de documento</label><select id="td" name="tipo_documento" class="form-select"><?php foreach (['CC', 'CE', 'TI', 'PAS'] as $t): ?><option <?= $f['tipo_documento'] === $t ? 'selected' : '' ?>><?= $t ?></option><?php endforeach; ?></select></div>
        <div class="col-md-4"><label class="form-label" for="d">Documento</label><input id="d" name="documento" class="form-control" value="<?= h($f['documento']) ?>"></div>
        <div class="col-md-4"><label class="form-label" for="fn">Nacimiento</label><input id="fn" name="fecha_nacimiento" type="date" class="form-control" value="<?= h($f['fecha_nacimiento']) ?>"></div>
        <div class="col-md-6"><label class="form-label" for="o">¿Cómo llegó?</label><select id="o" name="origen" class="form-select"><?php foreach ($ORI as $k => $v): ?><option value="<?= $k ?>" <?= $f['origen'] === $k ? 'selected' : '' ?>><?= $v ?></option><?php endforeach; ?></select></div>
        <div class="col-md-6 d-flex align-items-end"><div class="form-check"><input class="form-check-input" type="checkbox" name="acepta" id="r" <?= $f['acepta'] ? 'checked' : '' ?>><label class="form-check-label" for="r">Acepta recordatorios de cita</label></div></div>
        <div class="col-12"><label class="form-label" for="no">Notas</label><textarea id="no" name="notas" class="form-control" rows="2" maxlength="1000"><?= h($f['notas']) ?></textarea></div>
      </div>
      <div class="d-flex justify-content-end gap-2 mt-4"><a href="clientes.php" class="btn btn-secondary px-4">Cancelar</a><button class="btn btn-primary px-4">Guardar cliente</button></div>
    </form>
<?php pie();
