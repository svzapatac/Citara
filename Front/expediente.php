<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$id = (int)($_GET['id'] ?? 0);
$e = q_row("SELECT * FROM empleado WHERE negocio_id = ? AND id = ?", [$NEG, $id]);
if (!$e) { flash('No encontramos ese empleado.', 'danger'); header('Location: equipo.php'); exit; }
if (es_post() && csrf_ok()) {
    $acc = $_POST['accion'] ?? ''; $did = (int)($_POST['doc_req'] ?? 0);
    try {
        if (!q_val("SELECT 1 FROM documento_requerido WHERE negocio_id = ? AND id = ?", [$NEG, $did])) throw new RuntimeException('Documento no válido.');
        if ($acc === 'subir') {
            $a = $_FILES['archivo'] ?? null; $ext = strtolower(pathinfo($a['name'] ?? '', PATHINFO_EXTENSION));
            if (!$a || $a['error'] !== UPLOAD_ERR_OK) throw new RuntimeException('No se pudo subir el archivo.');
            if (!in_array($ext, ['pdf', 'jpg', 'jpeg', 'png'], true) || $a['size'] > 5 * 1024 * 1024) throw new RuntimeException('Solo PDF, JPG o PNG de hasta 5 MB.');
            $dir = __DIR__ . "/uploads/$NEG"; if (!is_dir($dir)) mkdir($dir, 0775, true);
            $nom = "emp{$id}_doc{$did}_" . bin2hex(random_bytes(4)) . ".$ext";
            if (!move_uploaded_file($a['tmp_name'], "$dir/$nom")) throw new RuntimeException('No se pudo guardar el archivo.');
            q_run("INSERT INTO empleado_documento (negocio_id, empleado_id, documento_requerido_id, archivo_url, estado) VALUES (?,?,?,?, 'pendiente')
                   ON DUPLICATE KEY UPDATE archivo_url = VALUES(archivo_url), estado = 'pendiente', verificado_por = NULL, verificado_en = NULL, subido_en = UTC_TIMESTAMP()", [$NEG, $id, $did, "uploads/$NEG/$nom"]);
            flash('Documento subido.');
        } elseif ($acc === 'verificar') {
            q_run("UPDATE empleado_documento SET estado = 'verificado', verificado_por = ?, verificado_en = UTC_TIMESTAMP() WHERE negocio_id = ? AND empleado_id = ? AND documento_requerido_id = ?", [$UID, $NEG, $id, $did]);
            flash('Documento verificado.');
        }
    } catch (Throwable $x) { flash($x->getMessage(), 'danger'); }
    header('Location: expediente.php?id=' . $id); exit;
}
$docs = q_all("SELECT v.*, d.archivo_url FROM v_expediente_documentos v LEFT JOIN empleado_documento d ON d.negocio_id = v.negocio_id AND d.id = v.empleado_documento_id WHERE v.negocio_id = ? AND v.empleado_id = ? ORDER BY v.orden", [$NEG, $id]);
$servs = q_all("SELECT s.nombre FROM empleado_servicio es JOIN servicio s ON s.negocio_id = es.negocio_id AND s.id = es.servicio_id WHERE es.negocio_id = ? AND es.empleado_id = ? ORDER BY s.nombre", [$NEG, $id]);
$dot = q_all("SELECT pieza, requerida, entregada FROM v_estado_dotacion WHERE negocio_id = ? AND empleado_id = ?", [$NEG, $id]);
$mano = q_all("SELECT producto, en_mano FROM v_en_mano_empleado WHERE negocio_id = ? AND empleado_id = ? AND en_mano > 0", [$NEG, $id]);
cabecera('Expediente', 'equipo');
?>
    <a href="equipo.php" class="enlace-suave small"><i class="bi bi-arrow-left"></i> Equipo</a>
    <div class="d-flex align-items-center gap-3 my-3"><?= avatar($e['nombres'] . ' ' . $e['apellidos'], 'avatar-44') ?><div><h1 class="h3 mb-0"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></h1><small class="text-secondary"><?= h($e['tipo_documento'] . ' ' . $e['documento']) ?> · ingresó el <?= fecha_completa($e['fecha_ingreso']) ?></small></div></div>
    <div class="row g-3">
      <div class="col-12 col-xl-7"><div class="card p-4"><p class="etiqueta mb-2">Documentos</p>
        <?php foreach ($docs as $d): ?><div class="linea-servicio flex-wrap gap-2"><div><strong class="d-block"><?= h($d['nombre']) ?><?= $d['obligatorio'] ? '' : ' <small class="text-secondary">(opcional)</small>' ?></strong>
          <small><?= !$d['empleado_documento_id'] ? 'Sin subir' : ($d['estado'] === 'verificado' ? 'Verificado' : 'Pendiente de verificar') ?></small></div>
          <div class="d-flex flex-wrap gap-2 align-items-center">
          <?php if ($d['archivo_url']): ?><a class="btn btn-sm btn-secondary" target="_blank" href="<?= h($d['archivo_url']) ?>">Ver</a><?php endif; ?>
          <?php if ($d['empleado_documento_id'] && $d['estado'] !== 'verificado'): ?><form method="post"><?= csrf() ?><input type="hidden" name="doc_req" value="<?= (int)$d['documento_requerido_id'] ?>"><button name="accion" value="verificar" class="btn btn-sm btn-primary">Verificar</button></form><?php endif; ?>
          <form method="post" enctype="multipart/form-data" class="d-flex gap-1"><?= csrf() ?><input type="hidden" name="doc_req" value="<?= (int)$d['documento_requerido_id'] ?>"><input type="file" name="archivo" class="form-control form-control-sm" required accept=".pdf,.jpg,.jpeg,.png" style="max-width:190px"><button name="accion" value="subir" class="btn btn-sm btn-secondary">Subir</button></form></div></div>
        <?php endforeach; ?></div></div>
      <div class="col-12 col-xl-5"><div class="card p-4 mb-3"><p class="etiqueta mb-2">Servicios que realiza</p><div class="d-flex flex-wrap gap-2"><?php foreach ($servs as $s): ?><span class="badge text-bg-light border"><?= h($s['nombre']) ?></span><?php endforeach; if (!$servs) echo '<span class="text-secondary small">Ninguno asignado.</span>'; ?></div></div>
        <div class="card p-4"><p class="etiqueta mb-2">Dotación</p>
          <?php foreach ($dot as $d): ?><div class="linea-servicio"><strong><?= h($d['pieza']) ?></strong><span><?= (int)$d['entregada'] ?>/<?= (int)$d['requerida'] ?></span></div><?php endforeach; if (!$dot) echo '<span class="text-secondary small">Sin piezas requeridas.</span>'; ?>
          <?php if ($mano): ?><p class="etiqueta mt-3 mb-2">Productos en mano</p><?php foreach ($mano as $m): ?><div class="linea-servicio"><strong><?= h($m['producto']) ?></strong><span><?= (int)$m['en_mano'] ?></span></div><?php endforeach; endif; ?>
          <a href="registrar-entrega.php?empleado=<?= $id ?>" class="btn btn-secondary mt-3">Registrar entrega</a></div></div>
    </div>
<?php pie();
