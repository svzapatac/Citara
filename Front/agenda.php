<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);

$fecha = $_GET['fecha'] ?? date('Y-m-d');
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha)) $fecha = date('Y-m-d');

// ---- Acciones sobre una cita ----
if (es_post() && csrf_ok()) {
    $citaId = (int)($_POST['cita_id'] ?? 0);
    $accion = $_POST['accion'] ?? '';
    try {
        if ($accion === 'realizados') {
            q_run("UPDATE cita_servicio SET estado = 'realizado' WHERE negocio_id = ? AND cita_id = ? AND estado <> 'cancelado'", [$NEG, $citaId]);
            q_run("UPDATE cita SET estado = 'finalizada' WHERE negocio_id = ? AND id = ?", [$NEG, $citaId]);
            flash('Servicios marcados como realizados.');
        } elseif ($accion === 'en_curso') {
            q_run("UPDATE cita_servicio SET estado = 'en curso' WHERE negocio_id = ? AND cita_id = ? AND estado = 'programado'", [$NEG, $citaId]);
            q_run("UPDATE cita SET estado = 'en curso' WHERE negocio_id = ? AND id = ?", [$NEG, $citaId]);
            flash('La cita quedó en curso.');
        } elseif ($accion === 'cancelar') {
            q_run("UPDATE cita_servicio SET estado = 'cancelado' WHERE negocio_id = ? AND cita_id = ?", [$NEG, $citaId]);
            q_run("UPDATE cita SET estado = 'cancelada' WHERE negocio_id = ? AND id = ?", [$NEG, $citaId]);
            flash('Cita cancelada.', 'warning');
        } elseif ($accion === 'facturar') {
            $fid = emitir_factura($NEG, $citaId, $_POST['metodo'] ?? 'efectivo');
            header('Location: factura.php?id=' . $fid); exit;
        }
    } catch (Throwable $e) { flash($e->getMessage(), 'danger'); }
    header('Location: agenda.php?fecha=' . urlencode($fecha) . '&cita=' . $citaId); exit;
}

// ---- Datos del día ----
$hor = q_row("SELECT MIN(apertura) a, MAX(cierre) c FROM sede_horario WHERE negocio_id = ? AND sede_id = ?", [$NEG, $SEDE]);
$h0 = $hor && $hor['a'] ? (int)substr($hor['a'], 0, 2) : 9;
$h1 = $hor && $hor['c'] ? (int)substr($hor['c'], 0, 2) : 19;
if ($h1 <= $h0) $h1 = $h0 + 10;

$emps = q_all("SELECT e.id, e.nombres, e.apellidos, GROUP_CONCAT(DISTINCT a.nombre ORDER BY a.nombre SEPARATOR ' · ') AS areas
               FROM empleado e LEFT JOIN empleado_area ea ON ea.negocio_id = e.negocio_id AND ea.empleado_id = e.id
               LEFT JOIN area a ON a.negocio_id = ea.negocio_id AND a.id = ea.area_id
               WHERE e.negocio_id = ? AND e.sede_id = ? AND e.activo = 1 GROUP BY e.id ORDER BY e.nombres", [$NEG, $SEDE]);
$citas = q_all("SELECT cs.id, cs.cita_id, cs.empleado_id, cs.inicio, cs.fin, cs.estado, s.nombre AS servicio, cl.nombres, cl.apellidos, cs.duracion_min
                FROM cita_servicio cs JOIN cita c ON c.negocio_id = cs.negocio_id AND c.id = cs.cita_id
                JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
                JOIN cliente cl ON cl.negocio_id = c.negocio_id AND cl.id = c.cliente_id
                WHERE cs.negocio_id = ? AND c.sede_id = ? AND c.fecha = ? AND cs.estado <> 'cancelado' ORDER BY cs.inicio", [$NEG, $SEDE, $fecha]);
$bloqueos = q_all("SELECT b.empleado_id, b.inicio, b.fin, b.motivo FROM bloqueo_agenda b WHERE b.negocio_id = ? AND DATE(b.inicio) = ?", [$NEG, $fecha]);
$porEmp = []; foreach ($citas as $c) $porEmp[$c['empleado_id']][] = $c;
$blqEmp = []; foreach ($bloqueos as $b) $blqEmp[$b['empleado_id']][] = $b;

// Cita seleccionada para el panel de detalle (la indicada o la primera del día)
$sel = (int)($_GET['cita'] ?? ($citas[0]['cita_id'] ?? 0));
$detalle = null;
if ($sel) {
    $detalle = q_row("SELECT c.id, c.estado, c.origen, cl.nombres, cl.apellidos, cl.celular, f.id AS factura_id, f.numero
                      FROM cita c JOIN cliente cl ON cl.negocio_id = c.negocio_id AND cl.id = c.cliente_id
                      LEFT JOIN factura f ON f.negocio_id = c.negocio_id AND f.cita_id = c.id
                      WHERE c.negocio_id = ? AND c.id = ?", [$NEG, $sel]);
    if ($detalle) $detalle['lineas'] = q_all("SELECT cs.inicio, cs.fin, cs.valor, cs.estado, s.nombre AS servicio, e.nombres AS emp FROM cita_servicio cs
        JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id JOIN empleado e ON e.negocio_id = cs.negocio_id AND e.id = cs.empleado_id
        WHERE cs.negocio_id = ? AND cs.cita_id = ? AND cs.estado <> 'cancelado' ORDER BY cs.inicio", [$NEG, $sel]);
}
$ESTADO = ['programado' => '', 'en curso' => 'En curso', 'realizado' => 'Realizado'];

cabecera('Agenda', 'agenda');
?>
    <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-2">
      <h1 class="mb-0">Agenda</h1>
      <div class="d-flex flex-wrap align-items-center gap-2">
        <form method="get" class="d-flex gap-2 align-items-center">
          <a class="btn btn-secondary" href="?fecha=<?= date('Y-m-d', strtotime("$fecha -1 day")) ?>" aria-label="Día anterior"><i class="bi bi-chevron-left"></i></a>
          <input type="date" name="fecha" value="<?= h($fecha) ?>" class="form-control w-auto fw-semibold" onchange="this.form.submit()" aria-label="Fecha">
          <a class="btn btn-secondary" href="?fecha=<?= date('Y-m-d', strtotime("$fecha +1 day")) ?>" aria-label="Día siguiente"><i class="bi bi-chevron-right"></i></a>
        </form>
        <div class="btn-group segmento" role="group" aria-label="Vista">
          <a href="agenda.php?fecha=<?= h($fecha) ?>" class="btn btn-segmento active" aria-current="page">Día</a>
          <a href="agenda-semana.php?fecha=<?= h($fecha) ?>" class="btn btn-segmento">Semana</a>
        </div>
        <a href="nueva-cita.php?fecha=<?= h($fecha) ?>" class="btn btn-primary"><i class="bi bi-plus-lg me-1"></i> Nueva cita</a>
      </div>
    </div>
    <p class="text-secondary mb-2"><?= h(fecha_larga($fecha)) ?> · <?= h($_SESSION['sede_nombre'] ?? '') ?></p>
    <p class="small text-secondary mb-3"><span class="leyenda-cita"></span>Cita <span class="leyenda-bloqueo ms-3"></span>Bloqueo / descanso</p>

    <div class="row g-3">
      <div class="col-12 col-xl-8">
        <div class="card agenda" style="--cols: <?= max(1, count($emps)) ?>; --hora: 64px; --horas: <?= $h1 - $h0 ?>">
          <div class="agenda-scroll"><div class="agenda-ancho">
            <div class="agenda-cab">
              <div></div>
              <?php foreach ($emps as $e): ?>
                <div class="agenda-emp"><?= avatar($e['nombres'] . ' ' . $e['apellidos']) ?><div><strong><?= h($e['nombres']) ?></strong><small><?= h($e['areas']) ?></small></div></div>
              <?php endforeach; ?>
            </div>
            <div class="agenda-cuerpo">
              <div class="agenda-horas"><?php for ($i = 0; $i < $h1 - $h0; $i++): ?><span style="--n:<?= $i ?>"><?= $h0 + $i ?>:00</span><?php endfor; ?></div>
              <?php foreach ($emps as $e): ?>
                <div class="agenda-col">
                  <?php foreach ($blqEmp[$e['id']] ?? [] as $b):
                      $ini = (strtotime($b['inicio']) - strtotime("$fecha {$h0}:00")) / 3600; $dur = (strtotime($b['fin']) - strtotime($b['inicio'])) / 3600; ?>
                    <div style="position:absolute;left:4px;right:4px;top:calc(var(--hora) * <?= $ini ?>);height:calc(var(--hora) * <?= $dur ?> - 3px);background:#E4E8F0;border-radius:6px;padding:.3rem .5rem;font-size:.75rem;color:#5b6676"><?= h(ucfirst($b['motivo'])) ?></div>
                  <?php endforeach; ?>
                  <?php foreach ($porEmp[$e['id']] ?? [] as $c):
                      $ini = (strtotime($c['inicio']) - strtotime("$fecha {$h0}:00")) / 3600; $dur = $c['duracion_min'] / 60; ?>
                    <a href="?fecha=<?= h($fecha) ?>&cita=<?= (int)$c['cita_id'] ?>" class="cita <?= $c['estado'] === 'realizado' ? 'hecha' : '' ?> <?= $dur <= .25 ? 'corta' : '' ?>" style="--ini:<?= $ini ?>; --dur:<?= $dur ?>; text-decoration:none<?= (int)$c['cita_id'] === $sel ? ';outline:2px solid var(--c-accion)' : '' ?>">
                      <strong><?= hora($c['inicio']) ?> <?= h($c['servicio']) ?></strong>
                      <?php if (!empty($ESTADO[$c['estado']])): ?><span class="cita-estado"><?= h($ESTADO[$c['estado']]) ?></span><?php endif; ?>
                      <small class="d-block"><?= h($c['nombres'] . ' ' . mb_substr($c['apellidos'], 0, 1) . '.') ?></small>
                    </a>
                  <?php endforeach; ?>
                </div>
              <?php endforeach; ?>
              <?php if ($fecha === date('Y-m-d')): $ahora = (time() - strtotime("$fecha {$h0}:00")) / 3600; if ($ahora > 0 && $ahora < $h1 - $h0): ?>
                <div class="agenda-ahora" style="--ini:<?= $ahora ?>"><span><?= date('H:i') ?></span></div>
              <?php endif; endif; ?>
            </div>
          </div></div>
        </div>
        <?php if (!$emps): ?><p class="text-secondary mt-3">Aún no hay empleados en esta sede. <a href="registrar-empleado.php" class="enlace-fuerte">Registra al primero</a>.</p><?php endif; ?>
      </div>

      <div class="col-12 col-xl-4">
        <div class="card p-3">
          <h2 class="h3 mb-3">Detalle de cita</h2>
          <?php if (!$detalle): ?>
            <p class="text-secondary mb-0">No hay citas este día. Crea una con «Nueva cita».</p>
          <?php else: $tot = array_sum(array_column($detalle['lineas'], 'valor')); $nom = $detalle['nombres'] . ' ' . $detalle['apellidos']; ?>
            <div class="d-flex align-items-center gap-3 mb-3">
              <span class="avatar rounded-circle d-inline-flex align-items-center justify-content-center" style="width:52px;height:52px;background:var(--c-suave);color:var(--c-medio);font-size:1rem"><?= h(iniciales($nom)) ?></span>
              <div><strong class="fs-5 d-block lh-sm"><?= h($nom) ?></strong><small class="text-secondary"><?= h($detalle['celular']) ?> · <?= h(ucfirst($detalle['origen'])) ?></small></div>
            </div>
            <?php foreach ($detalle['lineas'] as $l): ?>
              <div class="linea-servicio"><div><strong class="d-block"><?= h($l['servicio']) ?></strong><small><?= h($l['emp']) ?> · <?= hora($l['inicio']) ?> a <?= hora($l['fin']) ?></small></div><strong><?= pesos($l['valor']) ?></strong></div>
            <?php endforeach; ?>
            <div class="d-flex justify-content-between align-items-baseline my-3">
              <span class="etiqueta">Total<?= $detalle['numero'] ? ' · Factura ' . str_pad($detalle['numero'], 4, '0', STR_PAD_LEFT) : '' ?></span><strong class="fs-3"><?= pesos($tot) ?></strong>
            </div>
            <div class="d-flex gap-2 mb-3"><span class="badge bg-primary-subtle text-primary-emphasis"><?= h(ucfirst($detalle['estado'])) ?></span></div>
            <form method="post" class="d-grid gap-2">
              <?= csrf() ?><input type="hidden" name="cita_id" value="<?= (int)$detalle['id'] ?>">
              <?php if ($detalle['estado'] === 'reservada'): ?><button name="accion" value="en_curso" class="btn btn-outline-primary">Empezar cita</button><?php endif; ?>
              <?php if (!in_array($detalle['estado'], ['finalizada', 'cancelada'])): ?>
                <button name="accion" value="realizados" class="btn btn-primary"><i class="bi bi-check-lg me-2"></i>Marcar servicios realizados</button>
                <button name="accion" value="cancelar" class="btn btn-outline-primary" onclick="return confirm('¿Cancelar esta cita?')">Cancelar cita</button>
              <?php endif; ?>
              <?php if ($detalle['factura_id']): ?>
                <a href="factura.php?id=<?= (int)$detalle['factura_id'] ?>" class="btn btn-secondary">Ver factura</a>
              <?php elseif ($detalle['estado'] === 'finalizada'): ?>
                <select name="metodo" class="form-select"><option value="efectivo">Efectivo</option><option value="tarjeta">Tarjeta</option><option value="transferencia">Transferencia</option></select>
                <button name="accion" value="facturar" class="btn btn-primary">Facturar</button>
              <?php endif; ?>
            </form>
          <?php endif; ?>
        </div>
      </div>
    </div>
<?php pie();
