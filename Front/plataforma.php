<?php
require_once __DIR__ . '/modelo.php';
if (($_SESSION['tipo_cuenta'] ?? '') !== 'plataforma') { header('Location: Index.php'); exit; }
if (es_post() && csrf_ok() && ($nid = (int)($_POST['negocio'] ?? 0))) {
    $nuevo = ($_POST['estado'] ?? '') === 'activo' ? 'activo' : 'suspendido';
    q_run("UPDATE negocio SET estado = ? WHERE id = ?", [$nuevo, $nid]); flash('Negocio actualizado.'); header('Location: plataforma.php'); exit;
}
$rows = q_all("SELECT n.id, n.nombre, n.slug, n.tipo, n.estado, n.creado_en, p.nombre AS plan,
   (SELECT COUNT(*) FROM sede s WHERE s.negocio_id = n.id) AS sedes, (SELECT COUNT(*) FROM empleado e WHERE e.negocio_id = n.id AND e.activo = 1) AS equipo,
   (SELECT COUNT(*) FROM cliente c WHERE c.negocio_id = n.id) AS clientes FROM negocio n LEFT JOIN plan p ON p.id = n.plan_id ORDER BY n.id DESC LIMIT 200");
cabecera('Negocios', 'negocios');
?>
    <h1 class="mb-1">Negocios</h1><p class="text-secondary mb-3"><?= count($rows) ?> negocios en la plataforma.</p>
    <div class="card p-2 p-md-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Negocio</th><th>Plan</th><th class="text-end">Sedes</th><th class="text-end">Equipo</th><th class="text-end">Clientes</th><th>Estado</th><th></th></tr></thead><tbody>
    <?php foreach ($rows as $r): ?><tr><td><strong class="d-block"><?= h($r['nombre']) ?></strong><small class="text-secondary"><?= h($r['slug']) ?></small></td><td><?= h($r['plan'] ?: '—') ?></td><td class="text-end"><?= (int)$r['sedes'] ?></td><td class="text-end"><?= (int)$r['equipo'] ?></td><td class="text-end"><?= (int)$r['clientes'] ?></td>
      <td><span class="badge <?= $r['estado'] === 'activo' ? 'text-bg-success' : 'text-bg-secondary' ?>"><?= h(ucfirst($r['estado'])) ?></span></td>
      <td class="text-end"><form method="post"><?= csrf() ?><input type="hidden" name="negocio" value="<?= (int)$r['id'] ?>"><button name="estado" value="<?= $r['estado'] === 'activo' ? 'suspendido' : 'activo' ?>" class="btn btn-sm btn-secondary"><?= $r['estado'] === 'activo' ? 'Suspender' : 'Activar' ?></button></form></td></tr><?php endforeach; ?></tbody></table></div></div>
<?php pie();
