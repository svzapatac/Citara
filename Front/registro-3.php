<?php
session_start();

if (isset($_SESSION['usuario_id'])) {
    header('Location: agenda.php');
    exit;
}
if (empty($_SESSION['registro']['paso1'])) { header('Location: registro-1.php'); exit; }
if (empty($_SESSION['registro']['paso2'])) { header('Location: registro-2.php'); exit; }

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function pesos($n) { return '$' . number_format((int)$n, 0, ',', '.'); }

// Catálogo inicial que se le crea a cada negocio nuevo
$grupos = [
    'Cabello'  => 'Cabello · 30 min por servicio',
    'Uñas'     => 'Uñas · 45 min por servicio',
    'Barbería' => 'Barbería · 30 min',
    'Cejas'    => 'Cejas · 15 min',
];
$catalogo = [
    ['categoria' => 'Cabello',  'nombre' => 'Corte',           'duracion' => 30, 'precio' => 35000],
    ['categoria' => 'Cabello',  'nombre' => 'Color',           'duracion' => 30, 'precio' => 80000],
    ['categoria' => 'Cabello',  'nombre' => 'Peinado',         'duracion' => 30, 'precio' => 40000],
    ['categoria' => 'Uñas',     'nombre' => 'Tradicional',     'duracion' => 45, 'precio' => 30000],
    ['categoria' => 'Uñas',     'nombre' => 'Acrílicas',       'duracion' => 45, 'precio' => 70000],
    ['categoria' => 'Uñas',     'nombre' => 'Semipermanentes', 'duracion' => 45, 'precio' => 45000],
    ['categoria' => 'Barbería', 'nombre' => 'Barba',           'duracion' => 30, 'precio' => 20000],
    ['categoria' => 'Cejas',    'nombre' => 'Cejas',           'duracion' => 15, 'precio' => 15000],
];
foreach ($catalogo as &$s) { $s['activo'] = true; } unset($s);

$errores = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $enviados = $_POST['servicios'] ?? [];
    $activos  = 0;

    foreach ($catalogo as $i => &$s) {
        $s['activo'] = !empty($enviados[$i]['activo']);
        $precio = (int)preg_replace('/\D/', '', $enviados[$i]['precio'] ?? '');
        $s['precio'] = $precio;
        if ($s['activo']) {
            $activos++;
            if ($precio <= 0) $errores[] = "Ponle precio a {$s['nombre']}.";
        }
    }
    unset($s);

    if ($activos === 0) $errores[] = 'Activa al menos un servicio.';

    if (!$errores) {
        require_once is_file(__DIR__ . '/conexion.local.php') ? __DIR__ . '/conexion.local.php' : __DIR__ . '/conexion.php'; $conexion->set_charset('utf8mb4');

        $p1 = $_SESSION['registro']['paso1'];
        $p2 = $_SESSION['registro']['paso2'];

        $nit      = $p2['nit'] !== '' ? $p2['nit'] : null;
        $logo     = $p2['logo'] ?: null;
        $dias     = implode(',', $p2['dias']);

        $conexion->begin_transaction();
        try {
            // 1. Negocio
            $stmt = $conexion->prepare("INSERT INTO negocio (plan_id, slug, nombre, nit, tipo, logo) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->bind_param('isssss', $p2['plan_id'], $p2['slug'], $p2['negocio'], $nit, $p2['tipo'], $logo);
            $stmt->execute();
            $negocioId = $conexion->insert_id;
            $stmt->close();

            $conexion->query("INSERT INTO suscripcion (negocio_id, plan_id, estado, inicio) VALUES ($negocioId, " . (int)$p2['plan_id'] . ", 'prueba', CURRENT_DATE)");

            // 2. Primera sede (principal) y su horario, un renglón por día de atención
            $stmt = $conexion->prepare("INSERT INTO sede (negocio_id, nombre, ciudad, direccion, principal) VALUES (?, ?, ?, ?, 1)");
            $stmt->bind_param('isss', $negocioId, $p2['sede'], $p2['ciudad'], $p2['direccion']);
            $stmt->execute();
            $sedeId = $conexion->insert_id;
            $stmt->close();

            $stmt = $conexion->prepare("INSERT INTO sede_horario (negocio_id, sede_id, dia_semana, apertura, cierre) VALUES (?, ?, ?, ?, ?)");
            foreach ($p2['dias'] as $dia) {
                $stmt->bind_param('iiiss', $negocioId, $sedeId, $dia, $p2['abre'], $p2['cierra']);
                $stmt->execute();
            }
            $stmt->close();

            // 3. Dueño
            $rol = 'dueno';
            $rolId = (int)$conexion->query("SELECT id FROM rol WHERE clave = 'dueno'")->fetch_row()[0];
            $stmt = $conexion->prepare(
                "INSERT INTO usuario (negocio_id, correo, clave_hash, nombres, apellidos, tipo_documento, documento, celular, rol_id)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );
            $stmt->bind_param('isssssssi', $negocioId, $p1['correo'], $p1['clave_hash'], $p1['nombres'], $p1['apellidos'],
                              $p1['tipo_documento'], $p1['numero_documento'], $p1['celular'], $rolId);
            $stmt->execute();
            $usuarioId = $conexion->insert_id;
            $stmt->close();
            $conexion->query("INSERT INTO usuario_sede (negocio_id, usuario_id, sede_id) VALUES ($negocioId, $usuarioId, $sedeId)");

            // 4. Áreas (Cabello, Uñas, Barbería, Cejas) y servicios (también los desactivados, para activarlos después)
            $areaId = [];
            $stmt = $conexion->prepare("INSERT INTO area (negocio_id, nombre) VALUES (?, ?)");
            foreach (array_keys($grupos) as $nombreArea) {
                $stmt->bind_param('is', $negocioId, $nombreArea);
                $stmt->execute();
                $areaId[$nombreArea] = $conexion->insert_id;
            }
            $stmt->close();

            $stmt = $conexion->prepare(
                "INSERT INTO servicio (negocio_id, area_id, nombre, duracion_min, precio, permite_asesoria, activo) VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            foreach ($catalogo as $s) {
                $activo = $s['activo'] ? 1 : 0;
                $ase = in_array($s['nombre'], ['Color', 'Acrílicas'], true) ? 1 : 0;
                $aid = $areaId[$s['categoria']];
                $stmt->bind_param('iisiiii', $negocioId, $aid, $s['nombre'], $s['duracion'], $s['precio'], $ase, $activo);
                $stmt->execute();
            }
            $stmt->close();

            // 5. Documentos que se piden a cada empleado y categorías de gasto de arranque
            foreach ([['Documento de identidad',1],['Afiliación a salud (EPS)',1],['Certificado de bioseguridad',1],['Examen médico ocupacional',1],['Hoja de vida',0]] as $i => $dr) {
                $conexion->query("INSERT INTO documento_requerido (negocio_id, nombre, obligatorio, orden) VALUES ($negocioId, '" . $conexion->real_escape_string($dr[0]) . "', $dr[1], " . ($i + 1) . ")");
            }
            foreach (['Arriendo','Servicios públicos','Insumos','Nómina','Publicidad','Otros'] as $cg) {
                $conexion->query("INSERT INTO categoria_gasto (negocio_id, nombre) VALUES ($negocioId, '" . $conexion->real_escape_string($cg) . "')");
            }

            $conexion->commit();

            // 6. Queda con la sesión iniciada
            unset($_SESSION['registro']);
            session_regenerate_id(true);
            $_SESSION['usuario_id']     = $usuarioId;
            $_SESSION['negocio_id']     = $negocioId;
            $_SESSION['sede_id']        = $sedeId;
            $_SESSION['sede_nombre']    = $p2['sede'];
            $_SESSION['empleado_id']    = null;
            $_SESSION['rol']            = $rol;
            $_SESSION['tipo_cuenta']    = 'negocio';
            $_SESSION['usuario_correo'] = $p1['correo'];
            $_SESSION['usuario_nombre'] = trim($p1['nombres'] . ' ' . $p1['apellidos']);

            header('Location: agenda.php');
            exit;

        } catch (mysqli_sql_exception $e) {
            $conexion->rollback();
            if ($e->getCode() === 1062 && strpos($e->getMessage(), 'slug') !== false) {
                $errores[] = 'Ese enlace de reservas acaba de ser tomado por otro negocio. Vuelve al paso 2 y elige otro.';
            } elseif ($e->getCode() === 1062) {
                $errores[] = 'Ese correo ya quedó registrado. Vuelve al paso 1 y usa otro, o inicia sesión.';
            } else {
                // Mientras pruebas se muestra el error real; luego déjalo genérico.
                $errores[] = 'No se pudo crear el negocio: ' . $e->getMessage();
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tus servicios · Citara</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="Style.css" rel="stylesheet">
</head>
<body>

<main class="row g-0 min-vh-100">

  <aside class="col-lg-4 panel-marino d-none d-lg-flex flex-column">
    <div class="logo-caja mb-5"><img src="../assets/citara-logo.png" alt="Citara" height="52"></div>

    <div class="paso hecho"><span class="paso-num"><i class="bi bi-check-lg"></i></span><div><strong>Cuenta del dueño</strong><small>Tus datos de acceso</small></div></div>
    <div class="paso hecho"><span class="paso-num"><i class="bi bi-check-lg"></i></span><div><strong>Negocio y sede</strong><small>Datos del salón y horario</small></div></div>
    <div class="paso activo"><span class="paso-num">3</span><div><strong>Servicios</strong><small>Catálogo y precios</small></div></div>

    <p class="panel-pie mt-auto mb-0">Los datos de tu negocio quedan separados de los de otros negocios.</p>
  </aside>

  <section class="col-12 col-lg-8 d-flex align-items-center justify-content-center p-4">
    <div class="form-ancho-lg">
      <img src="../assets/citara-logo.png" alt="Citara" height="40" class="d-lg-none mb-4">

      <p class="etiqueta mb-2">Paso 3 de 3</p>
      <h1 class="mb-2">Elige tus servicios</h1>
      <p class="text-secondary mb-4">Puedes cambiar precios y activar servicios cuando quieras.</p>

      <?php if ($errores): ?>
        <div class="alert alert-danger" role="alert">
          <i class="bi bi-exclamation-circle me-1"></i>
          <?php foreach ($errores as $e): ?><div><?= h($e) ?></div><?php endforeach; ?>
        </div>
      <?php endif; ?>

      <form method="post" action="">
        <div class="card p-4">

          <?php $primero = true; foreach ($grupos as $cat => $titulo): ?>
            <p class="etiqueta <?= $primero ? '' : 'mt-3' ?> mb-2"><?= h($titulo) ?></p>
            <?php $primero = false; ?>
            <?php foreach ($catalogo as $i => $s): if ($s['categoria'] !== $cat) continue; ?>
              <div class="servicio">
                <input class="form-check-input" type="checkbox" name="servicios[<?= $i ?>][activo]" value="1" <?= $s['activo'] ? 'checked' : '' ?> aria-label="Activar <?= h($s['nombre']) ?>">
                <span class="nombre"><?= h($s['nombre']) ?></span>
                <span class="duracion"><?= $s['duracion'] ?> min</span>
                <input class="form-control" name="servicios[<?= $i ?>][precio]" value="<?= pesos($s['precio']) ?>" inputmode="numeric" aria-label="Precio de <?= h($s['nombre']) ?>">
              </div>
            <?php endforeach; ?>
          <?php endforeach; ?>

          <p class="text-secondary small mt-3 mb-0">Todos los servicios están disponibles para cualquier cliente. La duración es fija. Los casos que necesitan más tiempo, como una decoloración, se resuelven con el chat de asesoría antes de reservar.</p>
        </div>

        <div class="d-flex justify-content-end gap-2 mt-3">
          <a href="registro-2.php" class="btn btn-secondary px-4">Atrás</a>
          <button type="submit" class="btn btn-primary px-4">Ir a mi agenda <i class="bi bi-arrow-right ms-1"></i></button>
        </div>
      </form>
    </div>
  </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>