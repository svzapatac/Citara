<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);

$errores = [];
$f = ['cliente_id' => (int)($_GET['cliente'] ?? 0), 'canal' => 'whatsapp', 'fecha' => $_GET['fecha'] ?? date('Y-m-d'), 'hora' => '09:00',
      'servicios' => [], 'emp' => [], 'notas' => ''];
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $f['fecha'])) $f['fecha'] = date('Y-m-d');

$servicios = q_all("SELECT s.id, s.nombre, s.duracion_min, s.precio, a.nombre AS area FROM servicio s JOIN area a ON a.negocio_id = s.negocio_id AND a.id = s.area_id
                    WHERE s.negocio_id = ? AND s.activo = 1 ORDER BY a.id, s.id", [$NEG]);
$habil = [];   // servicio_id => [[id, nombre], ...]
foreach (q_all("SELECT es.servicio_id, e.id, e.nombres FROM empleado_servicio es JOIN empleado e ON e.negocio_id = es.negocio_id AND e.id = es.empleado_id
                WHERE es.negocio_id = ? AND e.activo = 1 AND e.sede_id = ? ORDER BY e.nombres", [$NEG, $SEDE]) as $r) $habil[$r['servicio_id']][] = [$r['id'], $r['nombres']];
$clientes = q_all("SELECT id, nombres, apellidos, celular FROM cliente WHERE negocio_id = ? AND activo = 1 ORDER BY nombres, apellidos LIMIT 500", [$NEG]);
$CANALES = ['whatsapp' => 'WhatsApp', 'facebook' => 'Facebook', 'instagram' => 'Instagram', 'llamada' => 'Llamada', 'enlace' => 'Enlace de reservas'];

if (es_post() && csrf_ok()) {
    $f['cliente_id'] = (int)($_POST['cliente_id'] ?? 0);
    $f['canal']  = $_POST['canal'] ?? 'whatsapp';
    $f['fecha']  = $_POST['fecha'] ?? '';
    $f['hora']   = $_POST['hora'] ?? '';
    $f['notas']  = trim($_POST['notas'] ?? '');
    $f['servicios'] = array_map('intval', (array)($_POST['servicios'] ?? []));
    $f['emp']    = array_map('intval', (array)($_POST['emp'] ?? []));

    if (!q_val("SELECT 1 FROM cliente WHERE negocio_id = ? AND id = ?", [$NEG, $f['cliente_id']])) $errores[] = 'Elige un cliente (o regístralo primero).';
    if (!$f['servicios']) $errores[] = 'Elige al menos un servicio.';
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $f['fecha'])) $errores[] = 'La fecha no es válida.';
    if (!preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $f['hora'])) $errores[] = 'La hora no es válida.';

    if (!$errores) {
        $orden = []; foreach ($servicios as $s) if (in_array((int)$s['id'], $f['servicios'], true)) $orden[] = $s;
        $conexion->begin_transaction();
        try {
            $origen = in_array($f['canal'], ['whatsapp', 'enlace'], true) ? $f['canal'] : 'administrador';
            $citaId = q_insert("INSERT INTO cita (negocio_id, sede_id, cliente_id, creada_por, fecha, origen, estado, notas) VALUES (?,?,?,?,?,?,'reservada',?)",
                               [$NEG, $SEDE, $f['cliente_id'], $UID, $f['fecha'], $origen, $f['notas'] ?: null]);
            $cursor = $f['hora'];
            foreach ($orden as $s) {
                $sid = (int)$s['id']; $min = (int)$s['duracion_min'];
                $candidatos = ($f['emp'][$sid] ?? 0) ? [[(int)$f['emp'][$sid]]] : ($habil[$sid] ?? []);
                $mejor = null;
                foreach ($candidatos as $c) {
                    $h = proximo_hueco($NEG, (int)$c[0], $SEDE, $f['fecha'], $min, $cursor);
                    if ($h !== null && ($mejor === null || $h < $mejor[1])) $mejor = [(int)$c[0], $h];
                }
                if (!$mejor) throw new RuntimeException("No hay disponibilidad para {$s['nombre']} ese día a partir de las $cursor.");
                $ini = $f['fecha'] . ' ' . $mejor[1] . ':00';
                $fin = date('Y-m-d H:i:s', strtotime($ini) + $min * 60);
                if ($e = validar_servicio_cita($NEG, $citaId, $sid, $mejor[0], $ini, $fin)) throw new RuntimeException($s['nombre'] . ': ' . $e);
                q_run("INSERT INTO cita_servicio (negocio_id, cita_id, servicio_id, empleado_id, inicio, fin, duracion_min, valor) VALUES (?,?,?,?,?,?,?,?)",
                      [$NEG, $citaId, $sid, $mejor[0], $ini, $fin, $min, (float)$s['precio']]);
                $cursor = date('H:i', strtotime($fin));    // el siguiente servicio empieza cuando termina este
            }
            $conexion->commit();
            flash('Cita creada.');
            header('Location: agenda.php?fecha=' . urlencode($f['fecha']) . '&cita=' . $citaId); exit;
        } catch (Throwable $e) { $conexion->rollback(); $errores[] = $e->getMessage(); }
    }
}
cabecera('Nueva cita', 'agenda');
?>
    <h1 class="mb-2">Nueva cita</h1>
    <p class="text-secondary mb-4">Registra aquí las solicitudes que llegan por WhatsApp, Facebook u otros canales. El sistema valida duración y disponibilidad de cada servicio, y asigna a quien esté libre si no eliges profesional.</p>
    <?php errores_html($errores); ?>
    <form method="post"><?= csrf() ?>
      <div class="row g-3">
        <div class="col-12 col-xl-7"><div class="card p-4 h-100"><div class="row g-3">
          <div class="col-md-7">
            <label class="form-label" for="cliente">Cliente</label>
            <select id="cliente" name="cliente_id" class="form-select" required>
              <option value="">Elige un cliente…</option>
              <?php foreach ($clientes as $c): ?><option value="<?= (int)$c['id'] ?>" <?= $f['cliente_id'] === (int)$c['id'] ? 'selected' : '' ?>><?= h($c['nombres'] . ' ' . $c['apellidos'] . ' · ' . $c['celular']) ?></option><?php endforeach; ?>
            </select>
            <div class="small text-secondary mt-1">¿Cliente nuevo? <a href="cliente-nuevo.php?volver=nueva-cita" class="enlace-suave">Registrar cliente</a></div>
          </div>
          <div class="col-md-5">
            <label class="form-label" for="canal">Canal por el que llegó</label>
            <select id="canal" name="canal" class="form-select"><?php foreach ($CANALES as $k => $v): ?><option value="<?= $k ?>" <?= $f['canal'] === $k ? 'selected' : '' ?>><?= $v ?></option><?php endforeach; ?></select>
          </div>
          <div class="col-12">
            <label class="form-label d-block">Servicios</label>
            <div class="d-flex flex-wrap gap-2">
              <?php foreach ($servicios as $s): ?>
                <input type="checkbox" class="btn-check svc" name="servicios[]" value="<?= (int)$s['id'] ?>" id="s<?= (int)$s['id'] ?>" <?= in_array((int)$s['id'], $f['servicios'], true) ? 'checked' : '' ?>>
                <label class="btn btn-outline-dark rounded-pill" for="s<?= (int)$s['id'] ?>"><?= h($s['nombre']) ?> · <?= (int)$s['duracion_min'] ?> min</label>
              <?php endforeach; ?>
            </div>
          </div>
          <div class="col-12" id="profesionales"></div>
          <div class="col-md-6"><label class="form-label" for="fecha">Fecha</label><input id="fecha" name="fecha" type="date" class="form-control" value="<?= h($f['fecha']) ?>" required></div>
          <div class="col-md-6"><label class="form-label" for="hora">Hora de inicio</label><input id="hora" name="hora" type="time" class="form-control" value="<?= h($f['hora']) ?>" required></div>
          <div class="col-12"><label class="form-label" for="notas">Notas (opcional)</label><input id="notas" name="notas" class="form-control" maxlength="500" value="<?= h($f['notas']) ?>"></div>
        </div></div></div>
        <div class="col-12 col-xl-5"><div class="card p-4 h-100">
          <p class="etiqueta mb-2">Resumen</p>
          <div id="resumen" class="text-secondary">Elige los servicios para ver el total.</div>
          <p class="small text-secondary mt-3 mb-0">Si pides varios servicios, quedan uno después del otro. Las citas solo se reservan dentro de los turnos de cada profesional y en los servicios que tiene habilitados.</p>
        </div></div>
      </div>
      <div class="d-flex justify-content-end gap-2 mt-3">
        <a href="agenda.php" class="btn btn-secondary px-4">Cancelar</a>
        <button class="btn btn-primary px-4">Guardar cita</button>
      </div>
    </form>
    <script>
    const SERV = <?= json_encode(array_column($servicios, null, 'id'), JSON_UNESCAPED_UNICODE) ?>;
    const HAB = <?= json_encode($habil, JSON_UNESCAPED_UNICODE) ?>;
    const PREV = <?= json_encode($f['emp']) ?>;
    const fmt = n => '$' + Number(n).toLocaleString('es-CO');
    function pintar() {
      const marcados = [...document.querySelectorAll('.svc:checked')].map(c => c.value);
      let total = 0, min = 0, html = '', res = '';
      marcados.forEach(id => {
        const s = SERV[id]; total += +s.precio; min += +s.duracion_min;
        const ops = (HAB[id] || []).map(e => `<option value="${e[0]}" ${PREV[id] == e[0] ? 'selected' : ''}>${e[1]}</option>`).join('');
        html += `<div class="d-flex align-items-center gap-2 mb-2"><span style="min-width:140px">${s.nombre}</span><select name="emp[${id}]" class="form-select"><option value="0">Quien esté libre</option>${ops}</select></div>`;
        res += `<div class="linea-servicio"><div><strong class="d-block">${s.nombre}</strong><small>${s.duracion_min} min</small></div><strong>${fmt(s.precio)}</strong></div>`;
      });
      document.getElementById('profesionales').innerHTML = marcados.length ? '<label class="form-label d-block">Profesional</label>' + html : '';
      document.getElementById('resumen').innerHTML = marcados.length ? res + `<div class="d-flex justify-content-between align-items-baseline mt-3"><span class="etiqueta">Total · ${min} min</span><strong class="fs-3">${fmt(total)}</strong></div>` : 'Elige los servicios para ver el total.';
    }
    document.querySelectorAll('.svc').forEach(c => c.addEventListener('change', pintar)); pintar();
    </script>
<?php pie();
