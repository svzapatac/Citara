<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
if (es_post() && csrf_ok() && ($sid = (int)($_POST['toggle'] ?? 0))) {
    q_run("UPDATE servicio SET activo = 1 - activo WHERE negocio_id = ? AND id = ?", [$NEG, $sid]);
    flash('Servicio actualizado.'); header('Location: servicios.php'); exit;
}
$rows = q_all("SELECT s.*, a.nombre AS area,
   (SELECT COUNT(*) FROM empleado_servicio es WHERE es.negocio_id = s.negocio_id AND es.servicio_id = s.id) AS pros
   FROM servicio s JOIN area a ON a.negocio_id = s.negocio_id AND a.id = s.area_id WHERE s.negocio_id = ? ORDER BY a.id, s.nombre", [$NEG]);
cabecera('Servicios', 'servicios');
?>
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div><h1 class="mb-1">Servicios</h1><p class="text-secondary mb-0">Catálogo con duración y precio. La duración se usa para armar la agenda.</p></div>
      <a href="servicio-nuevo.php" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Nuevo servicio</a>
    </div>
    <div class="card p-2 p-md-3"><div class="table-responsive"><table class="table table-hover tabla-citara">
      <thead><tr><th>Servicio</th><th>Área</th><th class="text-end">Duración</th><th class="text-end">Precio</th><th class="text-end">Profesionales</th><th>Estado</th><th></th></tr></thead><tbody>
      <?php foreach ($rows as $r): ?><tr>
        <td class="nombre-fila"><?= h($r['nombre']) ?></td><td><?= h($r['area']) ?></td><td class="text-end"><?= (int)$r['duracion_min'] ?> min</td><td class="text-end"><?= pesos($r['precio']) ?></td><td class="text-end"><?= (int)$r['pros'] ?></td>
        <td><span class="badge <?= $r['activo'] ? 'text-bg-success' : 'text-bg-secondary' ?>"><?= $r['activo'] ? 'Activo' : 'Inactivo' ?></span></td>
        <td class="text-end"><form method="post" class="d-inline"><?= csrf() ?><button name="toggle" value="<?= (int)$r['id'] ?>" class="btn btn-sm btn-secondary"><?= $r['activo'] ? 'Desactivar' : 'Activar' ?></button></form></td></tr>
      <?php endforeach; ?></tbody></table></div></div>
<?php pie();
