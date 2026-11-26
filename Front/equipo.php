<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$rows = q_all("SELECT e.id, e.nombres, e.apellidos, e.celular, e.fecha_ingreso, e.activo,
   (SELECT GROUP_CONCAT(a.nombre SEPARATOR ', ') FROM empleado_area ea JOIN area a ON a.negocio_id = ea.negocio_id AND a.id = ea.area_id WHERE ea.negocio_id = e.negocio_id AND ea.empleado_id = e.id) AS areas,
   (SELECT COUNT(*) FROM cita_servicio cs WHERE cs.negocio_id = e.negocio_id AND cs.empleado_id = e.id AND DATE(cs.inicio) = CURDATE() AND cs.estado <> 'cancelado') AS hoy,
   (SELECT COUNT(*) FROM v_expediente_documentos d WHERE d.negocio_id = e.negocio_id AND d.empleado_id = e.id AND d.obligatorio = 1 AND (d.estado IS NULL OR d.estado <> 'verificado')) AS docs_pend
   FROM empleado e WHERE e.negocio_id = ? AND e.sede_id = ? ORDER BY e.activo DESC, e.nombres", [$NEG, $SEDE]);
cabecera('Equipo', 'equipo');
?>
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div><h1 class="mb-1">Equipo</h1><p class="text-secondary mb-0">Profesionales de la sede, su expediente y su carga de hoy.</p></div>
      <a href="registrar-empleado.php" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Registrar empleado</a>
    </div>
    <div class="row g-3">
    <?php foreach ($rows as $e): ?>
      <div class="col-12 col-md-6 col-xl-4"><div class="card p-4 h-100">
        <div class="d-flex align-items-center gap-3 mb-3"><?= avatar($e['nombres'] . ' ' . $e['apellidos'], 'avatar-44') ?>
          <div><h2 class="h6 mb-0"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></h2><small class="text-secondary"><?= h($e['areas'] ?: 'Sin área') ?></small></div></div>
        <p class="mb-1 small"><i class="bi bi-telephone me-2"></i><?= h($e['celular'] ?: '—') ?></p>
        <p class="mb-1 small"><i class="bi bi-calendar-check me-2"></i><?= (int)$e['hoy'] ?> servicios hoy</p>
        <p class="mb-3 small"><i class="bi bi-folder2-open me-2"></i><?= (int)$e['docs_pend'] ? (int)$e['docs_pend'] . ' documentos pendientes' : 'Documentos al día' ?></p>
        <div class="mt-auto d-flex gap-2"><span class="badge <?= $e['activo'] ? 'text-bg-success' : 'text-bg-secondary' ?>"><?= $e['activo'] ? 'Activo' : 'Retirado' ?></span>
          <a href="expediente.php?id=<?= (int)$e['id'] ?>" class="btn btn-sm btn-secondary ms-auto">Expediente</a></div>
      </div></div>
    <?php endforeach; if (!$rows) echo '<p class="text-secondary">Aún no hay empleados en esta sede.</p>'; ?>
    </div>
<?php pie();
