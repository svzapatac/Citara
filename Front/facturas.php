<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$rows = q_all("SELECT f.id, f.numero, f.total, f.metodo_pago, f.estado, f.emitida_en, CONCAT(c.nombres,' ',c.apellidos) AS cliente
   FROM factura f JOIN cita ci ON ci.negocio_id = f.negocio_id AND ci.id = f.cita_id JOIN cliente c ON c.negocio_id = ci.negocio_id AND c.id = ci.cliente_id
   WHERE f.negocio_id = ? AND ci.sede_id = ? ORDER BY f.emitida_en DESC LIMIT 100", [$NEG, $SEDE]);
cabecera('Facturas', 'facturas');
?>
    <h1 class="mb-1">Facturas</h1><p class="text-secondary mb-3">Facturas emitidas en esta sede.</p>
    <div class="card p-2 p-md-3"><div class="table-responsive"><table class="table table-hover tabla-citara">
      <thead><tr><th>Número</th><th>Cliente</th><th>Fecha</th><th>Método</th><th class="text-end">Total</th><th>Estado</th></tr></thead><tbody>
      <?php foreach ($rows as $r): ?><tr onclick="location='factura.php?id=<?= (int)$r['id'] ?>'" style="cursor:pointer"><td class="nombre-fila"><?= h($r['numero']) ?></td><td><?= h($r['cliente']) ?></td><td><?= fecha_corta(substr($r['emitida_en'], 0, 10)) ?></td><td><?= h(ucfirst($r['metodo_pago'])) ?></td><td class="text-end"><?= pesos($r['total']) ?></td><td><span class="badge <?= $r['estado'] === 'emitida' ? 'text-bg-success' : 'text-bg-secondary' ?>"><?= h(ucfirst($r['estado'])) ?></span></td></tr>
      <?php endforeach; if (!$rows) echo '<tr><td colspan="6" class="text-center text-secondary py-4">Todavía no hay facturas.</td></tr>'; ?></tbody></table></div></div>
<?php pie();
