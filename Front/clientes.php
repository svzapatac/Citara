<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$buscar = trim($_GET['q'] ?? '');
$sel = (int)($_GET['id'] ?? 0);
$p = [$NEG]; $w = '';
if ($buscar !== '') { $w = " AND (c.nombres LIKE ? OR c.apellidos LIKE ? OR c.celular LIKE ? OR CONCAT(c.nombres,' ',c.apellidos) LIKE ?)"; $l = "%$buscar%"; array_push($p, $l, $l, $l, $l); }
$rows = q_all("SELECT c.id, c.nombres, c.apellidos, c.celular, c.origen,
    (SELECT MAX(ci.fecha) FROM cita ci WHERE ci.negocio_id = c.negocio_id AND ci.cliente_id = c.id AND ci.estado <> 'cancelada') AS ultima,
    (SELECT COUNT(*) FROM cita ci WHERE ci.negocio_id = c.negocio_id AND ci.cliente_id = c.id AND ci.estado <> 'cancelada') AS citas,
    (SELECT COALESCE(SUM(f.total),0) FROM factura f JOIN cita ci ON ci.negocio_id = f.negocio_id AND ci.id = f.cita_id WHERE ci.negocio_id = c.negocio_id AND ci.cliente_id = c.id AND f.estado <> 'anulada') AS gastado
    FROM cliente c WHERE c.negocio_id = ? AND c.activo = 1 $w ORDER BY c.nombres, c.apellidos LIMIT 100", $p);
if (!$sel && $rows) $sel = (int)$rows[0]['id'];
$c = $sel ? q_row("SELECT * FROM cliente WHERE negocio_id = ? AND id = ?", [$NEG, $sel]) : null;
$hist = $c ? q_all("SELECT ci.id, ci.fecha, ci.estado, GROUP_CONCAT(s.nombre SEPARATOR ', ') AS servicios, SUM(cs.valor) AS total
    FROM cita ci JOIN cita_servicio cs ON cs.negocio_id = ci.negocio_id AND cs.cita_id = ci.id JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
    WHERE ci.negocio_id = ? AND ci.cliente_id = ? GROUP BY ci.id ORDER BY ci.fecha DESC LIMIT 8", [$NEG, $sel]) : [];
$CAN = ['enlace' => 'Enlace', 'whatsapp' => 'WhatsApp', 'administrador' => 'Administrador', 'recomendacion' => 'Recomendación', 'instagram' => 'Instagram', 'local' => 'Local', 'otro' => 'Otro'];
cabecera('Clientes', 'clientes');
?>
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div><h1 class="mb-1">Clientes</h1><p class="text-secondary mb-0">Todos los clientes del negocio y su historial.</p></div>
      <div class="d-flex flex-wrap gap-2">
        <form class="input-group buscador" method="get"><span class="input-group-text border-end-0"><i class="bi bi-search"></i></span>
          <input type="search" name="q" value="<?= h($buscar) ?>" class="form-control border-start-0" placeholder="Buscar cliente" aria-label="Buscar cliente"></form>
        <a href="cliente-nuevo.php" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Nuevo cliente</a>
      </div>
    </div>
    <div class="row g-3">
      <div class="col-12 col-xl-8"><div class="card p-2 p-md-3"><div class="table-responsive">
        <table class="table table-hover tabla-citara"><thead><tr><th>Cliente</th><th>Celular</th><th>Última visita</th><th class="text-end">Citas</th><th class="text-end">Total gastado</th><th>Canal</th></tr></thead><tbody>
        <?php foreach ($rows as $r): ?>
          <tr class="<?= (int)$r['id'] === $sel ? 'table-active' : '' ?>" onclick="location='?id=<?= (int)$r['id'] ?>&q=<?= urlencode($buscar) ?>'" style="cursor:pointer">
            <td><div class="d-flex align-items-center gap-3"><?= avatar($r['nombres'] . ' ' . $r['apellidos'], 'avatar-44') ?><span class="nombre-fila"><?= h($r['nombres'] . ' ' . $r['apellidos']) ?></span></div></td>
            <td><?= h($r['celular']) ?></td><td><?= fecha_corta($r['ultima']) ?></td><td class="text-end"><?= (int)$r['citas'] ?></td><td class="text-end"><?= pesos($r['gastado']) ?></td><td><?= h($CAN[$r['origen']] ?? $r['origen']) ?></td>
          </tr>
        <?php endforeach; if (!$rows): ?><tr><td colspan="6" class="text-secondary text-center py-4">No hay clientes que coincidan.</td></tr><?php endif; ?>
        </tbody></table></div></div></div>
      <div class="col-12 col-xl-4"><?php if ($c): ?><div class="card p-4">
        <div class="d-flex align-items-center gap-3 mb-3"><?= avatar($c['nombres'] . ' ' . $c['apellidos'], 'avatar-44') ?><div><h2 class="h5 mb-0"><?= h($c['nombres'] . ' ' . $c['apellidos']) ?></h2><small class="text-secondary">Cliente desde <?= fecha_corta(substr($c['creado_en'], 0, 10)) ?></small></div></div>
        <p class="mb-1"><i class="bi bi-telephone me-2"></i><?= h($c['celular']) ?></p>
        <?php if ($c['correo']): ?><p class="mb-1"><i class="bi bi-envelope me-2"></i><?= h($c['correo']) ?></p><?php endif; ?>
        <?php if ($c['notas']): ?><p class="small text-secondary mt-2"><?= h($c['notas']) ?></p><?php endif; ?>
        <a href="nueva-cita.php?cliente=<?= (int)$c['id'] ?>" class="btn btn-primary w-100 my-3"><i class="bi bi-calendar-plus me-2"></i>Nueva cita</a>
        <p class="etiqueta mb-2">Últimas citas</p>
        <?php foreach ($hist as $x): ?><div class="linea-servicio"><div><strong class="d-block"><?= fecha_corta($x['fecha']) ?> · <?= h($x['servicios']) ?></strong><small><?= h($x['estado']) ?></small></div><strong><?= pesos($x['total']) ?></strong></div><?php endforeach; ?>
        <?php if (!$hist): ?><p class="text-secondary small mb-0">Aún no tiene citas.</p><?php endif; ?>
      </div><?php endif; ?></div>
    </div>
<?php pie();
