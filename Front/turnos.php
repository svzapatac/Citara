<?php
require_once __DIR__ . '/modelo.php';
requerir_rol(ADMIN);
$fecha = preg_match('/^\d{4}-\d{2}-\d{2}$/', $_GET['fecha'] ?? '') ? $_GET['fecha'] : date('Y-m-d');
$lunes = date('Y-m-d', strtotime('monday this week', strtotime($fecha)));
$dias = []; for ($i = 0; $i < 6; $i++) $dias[] = date('Y-m-d', strtotime("$lunes +$i day"));
if (es_post() && csrf_ok()) {
    try {
        if (isset($_POST['borrar'])) { q_run("DELETE FROM turno_empleado WHERE negocio_id = ? AND id = ?", [$NEG, (int)$_POST['borrar']]); flash('Turno eliminado.'); }
        else {
            $emp = (int)$_POST['empleado_id']; $d = $_POST['dia'] ?? ''; $i = $_POST['inicio'] ?? ''; $f = $_POST['fin'] ?? '';
            if (!q_val("SELECT 1 FROM empleado WHERE negocio_id = ? AND id = ? AND sede_id = ?", [$NEG, $emp, $SEDE])) throw new RuntimeException('Empleado no válido.');
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $d) || !preg_match('/^\d\d:\d\d$/', $i) || !preg_match('/^\d\d:\d\d$/', $f) || $f <= $i) throw new RuntimeException('Revisa el día y las horas.');
            if (q_val("SELECT 1 FROM turno_empleado WHERE negocio_id = ? AND empleado_id = ? AND fecha = ? AND inicio < ? AND fin > ?", [$NEG, $emp, $d, "$f:00", "$i:00"])) throw new RuntimeException('Ese turno se cruza con otro del mismo empleado.');
            q_run("INSERT INTO turno_empleado (negocio_id, empleado_id, sede_id, fecha, inicio, fin) VALUES (?,?,?,?,?,?)", [$NEG, $emp, $SEDE, $d, $i, $f]); flash('Turno guardado.');
        }
    } catch (Throwable $x) { flash($x->getMessage(), 'danger'); }
    header('Location: turnos.php?fecha=' . $fecha); exit;
}
$emps = q_all("SELECT id, nombres, apellidos FROM empleado WHERE negocio_id = ? AND sede_id = ? AND activo = 1 ORDER BY nombres", [$NEG, $SEDE]);
$t = []; foreach (q_all("SELECT id, empleado_id, fecha, inicio, fin FROM turno_empleado WHERE negocio_id = ? AND sede_id = ? AND fecha BETWEEN ? AND ? ORDER BY inicio", [$NEG, $SEDE, $dias[0], $dias[5]]) as $r) $t[$r['empleado_id']][$r['fecha']][] = $r;
cabecera('Turnos', 'turnos');
?>
    <div class="d-flex flex-wrap justify-content-between gap-3 mb-3"><div><h1 class="mb-1">Turnos</h1><p class="text-secondary mb-0">Horario de cada profesional. Solo se agenda dentro de estos turnos.</p></div>
      <div class="d-flex align-items-center gap-2"><a class="btn btn-secondary" href="?fecha=<?= date('Y-m-d', strtotime("$lunes -7 day")) ?>"><i class="bi bi-chevron-left"></i></a><strong>Semana del <?= date('j', strtotime($dias[0])) ?> al <?= date('j', strtotime($dias[5])) ?> de <?= h(MESES[(int)date('n', strtotime($dias[5]))]) ?></strong><a class="btn btn-secondary" href="?fecha=<?= date('Y-m-d', strtotime("$lunes +7 day")) ?>"><i class="bi bi-chevron-right"></i></a></div></div>
    <div class="card p-2 p-md-3 mb-3"><div class="table-responsive"><table class="table tabla-citara"><thead><tr><th>Profesional</th><?php foreach ($dias as $d): ?><th><?= h(mb_substr(DIAS[(int)date('N', strtotime($d))], 0, 3, 'UTF-8')) ?> <?= date('j', strtotime($d)) ?></th><?php endforeach; ?></tr></thead><tbody>
      <?php foreach ($emps as $e): ?><tr><td class="nombre-fila"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></td>
        <?php foreach ($dias as $d): ?><td><?php foreach ($t[$e['id']][$d] ?? [] as $x): ?><form method="post" class="d-flex align-items-center gap-1 small"><?= csrf() ?><span><?= hora($x['inicio']) ?>–<?= hora($x['fin']) ?></span><button name="borrar" value="<?= (int)$x['id'] ?>" class="btn btn-sm p-0 text-danger" aria-label="Quitar turno"><i class="bi bi-x-lg"></i></button></form><?php endforeach; ?></td><?php endforeach; ?></tr><?php endforeach; ?>
    </tbody></table></div></div>
    <form method="post" class="card p-4" style="max-width:760px"><?= csrf() ?><p class="etiqueta mb-2">Agregar turno</p><div class="row g-2 align-items-end">
      <div class="col-md-4"><label class="form-label">Profesional</label><select name="empleado_id" class="form-select"><?php foreach ($emps as $e): ?><option value="<?= (int)$e['id'] ?>"><?= h($e['nombres'] . ' ' . $e['apellidos']) ?></option><?php endforeach; ?></select></div>
      <div class="col-md-3"><label class="form-label">Día</label><select name="dia" class="form-select"><?php foreach ($dias as $d): ?><option value="<?= $d ?>"><?= h(DIAS[(int)date('N', strtotime($d))]) ?> <?= date('j', strtotime($d)) ?></option><?php endforeach; ?></select></div>
      <div class="col-md-2"><label class="form-label">Desde</label><input type="time" name="inicio" class="form-control" value="09:00"></div><div class="col-md-2"><label class="form-label">Hasta</label><input type="time" name="fin" class="form-control" value="13:00"></div>
      <div class="col-md-1"><button class="btn btn-primary w-100">Ok</button></div></div></form>
<?php pie();
