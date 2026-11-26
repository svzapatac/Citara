<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);

$fecha = $_GET['fecha'] ?? date('Y-m-d');
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha)) $fecha = date('Y-m-d');
$lunes = date('Y-m-d', strtotime('monday this week', strtotime($fecha)));
$dias = []; for ($i = 0; $i < 6; $i++) $dias[] = date('Y-m-d', strtotime("$lunes +$i day"));

$hor = q_row("SELECT MIN(apertura) a, MAX(cierre) c FROM sede_horario WHERE negocio_id = ? AND sede_id = ?", [$NEG, $SEDE]);
$h0 = $hor && $hor['a'] ? (int)substr($hor['a'], 0, 2) : 9;
$h1 = $hor && $hor['c'] ? (int)substr($hor['c'], 0, 2) : 19;
if ($h1 <= $h0) $h1 = $h0 + 10;

$filas = q_all("SELECT c.fecha, cs.inicio, cs.duracion_min, cs.estado, s.nombre AS servicio, cl.nombres, e.nombres AS emp
    FROM cita_servicio cs JOIN cita c ON c.negocio_id = cs.negocio_id AND c.id = cs.cita_id
    JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
    JOIN cliente cl ON cl.negocio_id = c.negocio_id AND cl.id = c.cliente_id
    JOIN empleado e ON e.negocio_id = cs.negocio_id AND e.id = cs.empleado_id
    WHERE cs.negocio_id = ? AND c.sede_id = ? AND c.fecha BETWEEN ? AND ? AND cs.estado <> 'cancelado' ORDER BY cs.inicio", [$NEG, $SEDE, $dias[0], $dias[5]]);
$porDia = []; foreach ($filas as $f) $porDia[$f['fecha']][] = $f;

cabecera('Agenda', 'agenda');
?>
    <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
      <h1 class="mb-0">Agenda</h1>
      <div class="d-flex flex-wrap align-items-center gap-2">
        <a class="btn btn-secondary" href="?fecha=<?= date('Y-m-d', strtotime("$lunes -7 day")) ?>" aria-label="Semana anterior"><i class="bi bi-chevron-left"></i></a>
        <span class="fw-semibold">Semana del <?= date('j', strtotime($dias[0])) ?> al <?= date('j', strtotime($dias[5])) ?> de <?= h(MESES[(int)date('n', strtotime($dias[5]))]) ?></span>
        <a class="btn btn-secondary" href="?fecha=<?= date('Y-m-d', strtotime("$lunes +7 day")) ?>" aria-label="Semana siguiente"><i class="bi bi-chevron-right"></i></a>
        <div class="btn-group segmento" role="group" aria-label="Vista">
          <a href="agenda.php?fecha=<?= h($fecha) ?>" class="btn btn-segmento">Día</a>
          <a href="agenda-semana.php" class="btn btn-segmento active" aria-current="page">Semana</a>
        </div>
        <a href="nueva-cita.php" class="btn btn-primary"><i class="bi bi-plus-lg me-1"></i> Nueva cita</a>
      </div>
    </div>
    <div class="card agenda agenda-semana" style="--horas: <?= $h1 - $h0 ?>">
      <div class="agenda-scroll"><div class="agenda-ancho">
        <div class="agenda-cab">
          <div></div>
          <?php foreach ($dias as $d): ?>
            <a href="agenda.php?fecha=<?= h($d) ?>" class="agenda-dia <?= $d === date('Y-m-d') ? 'hoy' : '' ?>" style="text-decoration:none;color:inherit"><small><?= h(mb_strtoupper(mb_substr(DIAS[(int)date('N', strtotime($d))], 0, 3, 'UTF-8'), 'UTF-8')) ?></small><strong><?= date('j', strtotime($d)) ?></strong></a>
          <?php endforeach; ?>
        </div>
        <div class="agenda-cuerpo">
          <div class="agenda-horas"><?php for ($i = 0; $i < $h1 - $h0; $i++): ?><span style="--n:<?= $i ?>"><?= $h0 + $i ?>:00</span><?php endfor; ?></div>
          <?php foreach ($dias as $d): ?>
            <div class="agenda-col">
              <?php foreach ($porDia[$d] ?? [] as $c):
                  $ini = (strtotime($c['inicio']) - strtotime("$d {$h0}:00")) / 3600; $dur = $c['duracion_min'] / 60; ?>
                <div class="cita <?= $c['estado'] === 'realizado' ? 'hecha' : '' ?>" style="--ini:<?= $ini ?>; --dur:<?= $dur ?>"><strong><?= hora($c['inicio']) ?> <?= h($c['servicio']) ?></strong><small class="d-block"><?= h($c['nombres']) ?> · <?= h($c['emp']) ?></small></div>
              <?php endforeach; ?>
            </div>
          <?php endforeach; ?>
        </div>
      </div></div>
    </div>
<?php pie();
