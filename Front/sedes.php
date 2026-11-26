<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(['dueno']);
$errores = [];
if (es_post() && csrf_ok()) {
    $n = trim($_POST['nombre'] ?? ''); $dir = trim($_POST['direccion'] ?? ''); $ciu = trim($_POST['ciudad'] ?? ''); $tel = trim($_POST['telefono'] ?? '');
    if ($n === '' || $dir === '' || $ciu === '') $errores[] = 'Nombre, dirección y ciudad son obligatorios.';
    else { $sid = q_insert("INSERT INTO sede (negocio_id, nombre, direccion, ciudad, telefono) VALUES (?,?,?,?,?)", [$NEG, $n, $dir, $ciu, $tel ?: null]);
      for ($d = 1; $d <= 6; $d++) q_run("INSERT INTO sede_horario (negocio_id, sede_id, dia_semana, apertura, cierre) VALUES (?,?,?,'09:00','19:00')", [$NEG, $sid, $d]);
      flash('Sede creada.'); header('Location: sedes.php'); exit; }
}
$rows = q_all("SELECT s.*, (SELECT COUNT(*) FROM empleado e WHERE e.negocio_id = s.negocio_id AND e.sede_id = s.id AND e.activo = 1) AS equipo FROM sede s WHERE s.negocio_id = ? ORDER BY s.principal DESC, s.nombre", [$NEG]);
cabecera('Sedes', 'sedes');
?>
    <h1 class="mb-3">Sedes</h1><?php errores_html($errores); ?>
    <div class="row g-3"><div class="col-12 col-xl-8"><div class="row g-3"><?php foreach ($rows as $s): ?><div class="col-md-6"><div class="card p-4 h-100"><h2 class="h6"><?= h($s['nombre']) ?> <?= $s['principal'] ? '<span class="badge text-bg-dark">Principal</span>' : '' ?></h2>
      <p class="mb-1 small"><i class="bi bi-geo-alt me-2"></i><?= h($s['direccion'] . ', ' . $s['ciudad']) ?></p><p class="mb-1 small"><i class="bi bi-telephone me-2"></i><?= h($s['telefono'] ?: '—') ?></p><p class="mb-0 small"><i class="bi bi-people me-2"></i><?= (int)$s['equipo'] ?> en el equipo</p></div></div><?php endforeach; ?></div></div>
    <div class="col-12 col-xl-4"><form method="post" class="card p-4"><?= csrf() ?><p class="etiqueta mb-2">Nueva sede</p>
      <input name="nombre" class="form-control mb-2" placeholder="Nombre" required><input name="direccion" class="form-control mb-2" placeholder="Dirección" required><input name="ciudad" class="form-control mb-2" placeholder="Ciudad" required><input name="telefono" class="form-control mb-3" placeholder="Teléfono"><button class="btn btn-primary">Crear sede</button></form></div></div>
<?php pie();
