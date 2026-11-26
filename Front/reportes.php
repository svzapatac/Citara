<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(['dueno']);
$d0 = preg_match('/^\d{4}-\d{2}-\d{2}$/', $_GET['desde'] ?? '') ? $_GET['desde'] : date('Y-m-01');
$d1 = preg_match('/^\d{4}-\d{2}-\d{2}$/', $_GET['hasta'] ?? '') ? $_GET['hasta'] : date('Y-m-d');
$top = q_all("SELECT s.nombre, COUNT(*) AS n, SUM(cs.valor) AS total FROM cita_servicio cs JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id JOIN cita c ON c.negocio_id = cs.negocio_id AND c.id = cs.cita_id
   WHERE cs.negocio_id = ? AND c.sede_id = ? AND cs.estado = 'realizado' AND DATE(cs.inicio) BETWEEN ? AND ? GROUP BY s.id ORDER BY total DESC LIMIT 10", [$NEG, $SEDE, $d0, $d1]);
$pro = q_all("SELECT CONCAT(e.nombres,' ',e.apellidos) AS emp, COUNT(*) AS n, SUM(cs.valor) AS total FROM cita_servicio cs JOIN empleado e ON e.negocio_id = cs.negocio_id AND e.id = cs.empleado_id JOIN cita c ON c.negocio_id = cs.negocio_id AND c.id = cs.cita_id
   WHERE cs.negocio_id = ? AND c.sede_id = ? AND cs.estado = 'realizado' AND DATE(cs.inicio) BETWEEN ? AND ? GROUP BY e.id ORDER BY total DESC", [$NEG, $SEDE, $d0, $d1]);
$est = q_all("SELECT estado, COUNT(*) AS n FROM cita WHERE negocio_id = ? AND sede_id = ? AND fecha BETWEEN ? AND ? GROUP BY estado", [$NEG, $SEDE, $d0, $d1]);
$nuevos = (int)q_val("SELECT COUNT(*) FROM cliente WHERE negocio_id = ? AND DATE(creado_en) BETWEEN ? AND ?", [$NEG, $d0, $d1]);
$bajo = q_all("SELECT producto, existencia, stock_minimo FROM v_stock_bajo WHERE negocio_id = ? AND sede_id = ?", [$NEG, $SEDE]);
cabecera('Reportes', 'reportes');
?>
    <div class="d-flex flex-wrap justify-content-between gap-3 mb-3"><h1 class="mb-0">Reportes</h1>
      <form class="d-flex gap-2" method="get"><input type="date" name="desde" class="form-control" value="<?= h($d0) ?>"><input type="date" name="hasta" class="form-control" value="<?= h($d1) ?>"><button class="btn btn-secondary">Ver</button></form></div>
    <div class="row g-3">
      <div class="col-12 col-xl-6"><div class="card p-4 h-100"><p class="etiqueta mb-2">Servicios más vendidos</p><?php foreach ($top as $r): ?><div class="linea-servicio"><div><strong class="d-block"><?= h($r['nombre']) ?></strong><small><?= (int)$r['n'] ?> realizados</small></div><strong><?= pesos($r['total']) ?></strong></div><?php endforeach; if (!$top) echo '<span class="text-secondary small">Sin datos en el rango.</span>'; ?></div></div>
      <div class="col-12 col-xl-6"><div class="card p-4 h-100"><p class="etiqueta mb-2">Producción por profesional</p><?php foreach ($pro as $r): ?><div class="linea-servicio"><div><strong class="d-block"><?= h($r['emp']) ?></strong><small><?= (int)$r['n'] ?> servicios</small></div><strong><?= pesos($r['total']) ?></strong></div><?php endforeach; if (!$pro) echo '<span class="text-secondary small">Sin datos en el rango.</span>'; ?></div></div>
      <div class="col-md-6 col-xl-4"><div class="card p-4"><p class="etiqueta mb-2">Citas por estado</p><?php foreach ($est as $r): ?><div class="linea-servicio"><span><?= h(ucfirst($r['estado'])) ?></span><strong><?= (int)$r['n'] ?></strong></div><?php endforeach; ?></div></div>
      <div class="col-md-6 col-xl-4"><div class="card p-4"><p class="etiqueta mb-1">Clientes nuevos</p><strong class="fs-3"><?= $nuevos ?></strong></div></div>
      <div class="col-md-12 col-xl-4"><div class="card p-4"><p class="etiqueta mb-2">Stock bajo</p><?php foreach ($bajo as $r): ?><div class="linea-servicio"><span><?= h($r['producto']) ?></span><strong class="text-danger"><?= (int)$r['existencia'] ?>/<?= (int)$r['stock_minimo'] ?></strong></div><?php endforeach; if (!$bajo) echo '<span class="text-secondary small">Todo en orden.</span>'; ?></div></div>
    </div>
<?php pie();
