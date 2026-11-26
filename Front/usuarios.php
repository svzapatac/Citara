<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(['dueno']);
$errores = [];
if (es_post() && csrf_ok()) {
    if (isset($_POST['toggle'])) { q_run("UPDATE usuario SET activo = 1 - activo WHERE negocio_id = ? AND id = ? AND id <> ?", [$NEG, (int)$_POST['toggle'], $UID]); flash('Usuario actualizado.'); header('Location: usuarios.php'); exit; }
    $correo = strtolower(trim($_POST['correo'] ?? '')); $nom = trim($_POST['nombres'] ?? ''); $ape = trim($_POST['apellidos'] ?? ''); $clave = $_POST['clave'] ?? ''; $rol = $_POST['rol'] ?? 'administrador';
    if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) $errores[] = 'El correo no es válido.';
    if (strlen($clave) < 8) $errores[] = 'La clave debe tener al menos 8 caracteres.';
    if (!in_array($rol, ['administrador', 'empleado'], true)) $errores[] = 'Rol no válido.';
    if (!$errores && q_val("SELECT 1 FROM usuario WHERE negocio_id = ? AND correo = ?", [$NEG, $correo])) $errores[] = 'Ese correo ya está en uso en tu negocio.';
    if (!$errores) {
        $rid = (int)q_val("SELECT id FROM rol WHERE clave = ?", [$rol]);
        $uid = q_insert("INSERT INTO usuario (negocio_id, correo, clave_hash, nombres, apellidos, rol_id) VALUES (?,?,?,?,?,?)", [$NEG, $correo, password_hash($clave, PASSWORD_DEFAULT), $nom ?: null, $ape ?: null, $rid]);
        q_run("INSERT IGNORE INTO usuario_sede (negocio_id, usuario_id, sede_id) VALUES (?,?,?)", [$NEG, $uid, $SEDE]);
        if ($rol === 'empleado' && ($eid = (int)($_POST['empleado_id'] ?? 0))) q_run("UPDATE empleado SET usuario_id = ? WHERE negocio_id = ? AND id = ? AND usuario_id IS NULL", [$uid, $NEG, $eid]);
        flash('Usuario creado.'); header('Location: usuarios.php'); exit;
    }
}
$rows = q_all("SELECT u.id, u.correo, u.nombres, u.apellidos, u.activo, u.ultimo_acceso, r.nombre AS rol FROM usuario u JOIN rol r ON r.id = u.rol_id WHERE u.negocio_id = ? AND r.clave <> 'cliente' ORDER BY r.id, u.correo LIMIT 100", [$NEG]);
$libres = q_all("SELECT id, nombres, apellidos FROM empleado WHERE negocio_id = ? AND usuario_id IS NULL AND activo = 1 ORDER BY nombres", [$NEG]);
cabecera('Usuarios', 'usuarios');
?>
    <h1 class="mb-1">Usuarios</h1><p class="text-secondary mb-3">Quién puede entrar al sistema de tu negocio.</p><?php errores_html($errores); ?>
    <div class="row g-3"><div class="col-12 col-xl-8"><div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Usuario</th><th>Rol</th><th>Último acceso</th><th></th></tr></thead><tbody>
      <?php foreach ($rows as $u): ?><tr><td><strong class="d-block"><?= h(trim($u['nombres'] . ' ' . $u['apellidos']) ?: $u['correo']) ?></strong><small class="text-secondary"><?= h($u['correo']) ?></small></td><td><?= h($u['rol']) ?></td><td><?= $u['ultimo_acceso'] ? fecha_corta(substr($u['ultimo_acceso'], 0, 10)) : 'Nunca' ?></td>
        <td class="text-end"><?php if ((int)$u['id'] !== $UID): ?><form method="post"><?= csrf() ?><button name="toggle" value="<?= (int)$u['id'] ?>" class="btn btn-sm btn-secondary"><?= $u['activo'] ? 'Desactivar' : 'Activar' ?></button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></div></div></div>
    <div class="col-12 col-xl-4"><form method="post" class="card p-4"><?= csrf() ?><p class="etiqueta mb-2">Nuevo usuario</p>
      <input name="nombres" class="form-control mb-2" placeholder="Nombres"><input name="apellidos" class="form-control mb-2" placeholder="Apellidos"><input name="correo" type="email" class="form-control mb-2" placeholder="Correo" required>
      <input name="clave" type="password" class="form-control mb-2" placeholder="Clave (mín. 8)" required autocomplete="new-password">
      <select name="rol" class="form-select mb-2"><option value="administrador">Administrador</option><option value="empleado">Empleado</option></select>
      <select name="empleado_id" class="form-select mb-3"><option value="0">Vincular a empleado (solo rol empleado)…</option><?php foreach ($libres as $e): ?><option value="<?= (int)$e['id'] ?>"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></option><?php endforeach; ?></select><button class="btn btn-primary">Crear usuario</button></form></div></div>
<?php pie();
