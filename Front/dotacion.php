<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$rows = q_all("SELECT d.empleado_id, CONCAT(e.nombres,' ',e.apellidos) AS empleado, d.area, d.pieza, d.requerida, d.entregada, d.estado, d.producto_id
   FROM v_estado_dotacion d JOIN empleado e ON e.negocio_id = d.negocio_id AND e.id = d.empleado_id WHERE d.negocio_id = ? AND e.sede_id = ? AND e.activo = 1 ORDER BY e.nombres, d.pieza", [$NEG, $SEDE]);
$por = []; foreach ($rows as $r) $por[$r['empleado_id']]['n'] = $r['empleado'] and $por[$r['empleado_id']]['f'][] = $r;
cabecera('Dotación', 'dotacion');
?>
    <div class="d-flex flex-wrap justify-content-between gap-3 mb-3"><div><h1 class="mb-1">Dotación</h1><p class="text-secondary mb-0">Piezas que cada empleado debe tener según su área.</p></div>
      <a href="registrar-entrega.php" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Registrar entrega</a></div>
    <div class="row g-3">
    <?php foreach ($por as $eid => $d): ?><div class="col-12 col-xl-6"><div class="card p-4 h-100"><h2 class="h6 mb-3"><?= h($d['n']) ?></h2>
      <?php foreach ($d['f'] as $r): $ok = (int)$r['entregada'] >= (int)$r['requerida']; ?>
        <div class="linea-servicio"><div><strong class="d-block"><?= h($r['pieza']) ?></strong><small><?= (int)$r['entregada'] ?> de <?= (int)$r['requerida'] ?></small></div>
        <?php if ($ok): ?><span class="badge text-bg-success">Completa</span><?php else: ?><a class="btn btn-sm btn-secondary" href="registrar-entrega.php?empleado=<?= (int)$eid ?>&producto=<?= (int)$r['producto_id'] ?>">Entregar</a><?php endif; ?></div>
      <?php endforeach; ?></div></div>
    <?php endforeach; if (!$por) echo '<p class="text-secondary">No hay piezas de dotación configuradas.</p>'; ?>
    </div>
<?php pie();
