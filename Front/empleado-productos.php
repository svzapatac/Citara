<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(['empleado']);
$EMP = (int)($_SESSION['empleado_id'] ?? 0);
$rows = q_all("SELECT producto, tipo, entregadas, devueltas, vendidas, en_mano FROM v_en_mano_empleado WHERE negocio_id = ? AND empleado_id = ? ORDER BY producto", [$NEG, $EMP]);
cabecera('Mis productos', 'productos');
?>
    <h1 class="mb-3">Mis productos</h1><div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Producto</th><th>Tipo</th><th class="text-end">Entregados</th><th class="text-end">Devueltos</th><th class="text-end">Vendidos</th><th class="text-end">En mano</th></tr></thead><tbody>
    <?php foreach ($rows as $r): ?><tr><td class="nombre-fila"><?= h($r['producto']) ?></td><td><?= h($r['tipo']) ?></td><td class="text-end"><?= (int)$r['entregadas'] ?></td><td class="text-end"><?= (int)$r['devueltas'] ?></td><td class="text-end"><?= (int)$r['vendidas'] ?></td><td class="text-end"><strong><?= (int)$r['en_mano'] ?></strong></td></tr><?php endforeach; if (!$rows) echo '<tr><td colspan="6" class="text-center text-secondary py-4">No tienes productos entregados.</td></tr>'; ?></tbody></table></div></div>
<?php pie();
