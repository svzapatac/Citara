<?php
session_start();

if (isset($_SESSION['usuario_id'])) {
    header('Location: agenda.php');
    exit;
}
// No se puede saltar el paso 1
if (empty($_SESSION['registro']['paso1'])) {
    header('Location: registro-1.php');
    exit;
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// "Salón Isa Bogotá" → "salon-isa-bogota"
function slugify($s) {
    $s = mb_strtolower(trim($s), 'UTF-8');
    $s = strtr($s, ['á'=>'a','é'=>'e','í'=>'i','ó'=>'o','ú'=>'u','ü'=>'u','ñ'=>'n']);
    $s = preg_replace('/[^a-z0-9]+/', '-', $s);
    return trim($s, '-');
}

$tipos       = ['Peluquería y uñas', 'Barbería', 'Spa'];
$diasNombres = [1 => 'Lun', 2 => 'Mar', 3 => 'Mié', 4 => 'Jue', 5 => 'Vie', 6 => 'Sáb', 7 => 'Dom'];

// ---- Planes disponibles (tabla plan) ----
require_once is_file(__DIR__ . '/conexion.local.php') ? __DIR__ . '/conexion.local.php' : __DIR__ . '/conexion.php'; $conexion->set_charset('utf8mb4');
$planes = [];
$errores = [];
try {
    foreach ($conexion->query("SELECT * FROM plan ORDER BY id") as $p) {
        if (isset($p['activo']) && !$p['activo']) continue;   // si la tabla tiene "activo", oculta los apagados
        $planes[(int)$p['id']] = [
            'nombre'      => $p['nombre'] ?? $p['name'] ?? ('Plan ' . $p['id']),
            'precio'      => $p['precio'] ?? $p['precio_mensual'] ?? $p['valor'] ?? null,
            'descripcion' => $p['descripcion'] ?? '',
        ];
    }
} catch (mysqli_sql_exception $e) {
    $errores[] = 'No se pudieron cargar los planes: ' . $e->getMessage();
}
if (!$planes && !$errores) $errores[] = 'No hay planes creados en la tabla plan.';

$d = $_SESSION['registro']['paso2'] ?? [
    'negocio' => '', 'nit' => '', 'tipo' => $tipos[0], 'slug' => '', 'logo' => null,
    'plan_id' => $planes ? key($planes) : 0,
    'sede' => '', 'ciudad' => '', 'direccion' => '',
    'dias' => [1, 2, 3, 4, 5, 6], 'abre' => '08:00', 'cierra' => '19:00',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $logoAnterior = $d['logo'] ?? null;

    $d = [
        'negocio'   => trim($_POST['negocio'] ?? ''),
        'nit'       => trim($_POST['nit'] ?? ''),
        'tipo'      => $_POST['tipo'] ?? '',
        'slug'      => slugify($_POST['slug'] ?? ''),
        'logo'      => $logoAnterior,
        'plan_id'   => (int)($_POST['plan_id'] ?? 0),
        'sede'      => trim($_POST['sede'] ?? ''),
        'ciudad'    => trim($_POST['ciudad'] ?? ''),
        'direccion' => trim($_POST['dir'] ?? ''),
        'dias'      => array_values(array_unique(array_filter(
                           array_map('intval', (array)($_POST['dias'] ?? [])),
                           function ($n) { return $n >= 1 && $n <= 7; }
                       ))),
        'abre'      => $_POST['abre'] ?? '',
        'cierra'    => $_POST['cierra'] ?? '',
    ];
    sort($d['dias']);

    if ($d['negocio'] === '') $errores[] = 'Escribe el nombre del negocio.';
    if ($d['nit'] !== '' && !preg_match('/^[0-9]{6,12}(-[0-9])?$/', $d['nit'])) $errores[] = 'El NIT no es válido (ej: 900123456 o 900123456-7).';
    if (!in_array($d['tipo'], $tipos, true)) $errores[] = 'Elige un tipo de negocio válido.';
    if (!isset($planes[$d['plan_id']])) $errores[] = 'Elige un plan.';

    // Si deja el slug vacío, se arma con el nombre del negocio
    if ($d['slug'] === '') $d['slug'] = slugify($d['negocio']);
    if (!preg_match('/^[a-z0-9]+(-[a-z0-9]+)*$/', $d['slug']) || strlen($d['slug']) < 3 || strlen($d['slug']) > 60) {
        $errores[] = 'El enlace debe tener entre 3 y 60 caracteres: solo letras, números y guiones (ej: barber-092).';
    } else {
        // ¿Ya lo usa otro negocio?
        try {
            $stmt = $conexion->prepare("SELECT 1 FROM negocio WHERE slug = ? LIMIT 1");
            $stmt->bind_param('s', $d['slug']);
            $stmt->execute();
            if ($stmt->get_result()->fetch_row()) {
                $errores[] = "El enlace «{$d['slug']}» ya lo usa otro negocio. Prueba con otro.";
            }
            $stmt->close();
        } catch (mysqli_sql_exception $e) {
            $errores[] = 'Error de base de datos: ' . $e->getMessage();
        }
    }
    if ($d['sede'] === '')      $errores[] = 'Escribe el nombre de la sede.';
    if ($d['ciudad'] === '')    $errores[] = 'Escribe la ciudad.';
    if ($d['direccion'] === '') $errores[] = 'Escribe la dirección.';
    if (!$d['dias'])            $errores[] = 'Elige al menos un día de atención.';

    $horaOk = '/^([01]\d|2[0-3]):[0-5]\d$/';
    if (!preg_match($horaOk, $d['abre']) || !preg_match($horaOk, $d['cierra'])) {
        $errores[] = 'Revisa las horas de apertura y cierre.';
    } elseif ($d['cierra'] <= $d['abre']) {
        $errores[] = 'La hora de cierre debe ser después de la de apertura.';
    }

    // ---- Logo (opcional) ----
    $logo = $_FILES['logo'] ?? null;
    $extLogo = null;
    if ($logo && $logo['error'] !== UPLOAD_ERR_NO_FILE) {
        $permitidos = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'image/gif' => 'gif'];
        if ($logo['error'] !== UPLOAD_ERR_OK) {
            $errores[] = 'No se pudo subir el logo. Prueba con una imagen más liviana.';
        } elseif ($logo['size'] > 2 * 1024 * 1024) {
            $errores[] = 'El logo no puede pesar más de 2 MB.';
        } else {
            $info = @getimagesize($logo['tmp_name']);
            if (!$info || !isset($permitidos[$info['mime']])) {
                $errores[] = 'El logo debe ser una imagen JPG, PNG, WEBP o GIF.';
            } else {
                $extLogo = $permitidos[$info['mime']];
            }
        }
    }

    if (!$errores && $extLogo) {
        $carpeta = __DIR__ . '/uploads/logos';
        if (!is_dir($carpeta)) mkdir($carpeta, 0755, true);
        $nombre = bin2hex(random_bytes(16)) . '.' . $extLogo;
        if (move_uploaded_file($logo['tmp_name'], "$carpeta/$nombre")) {
            if ($logoAnterior && is_file(__DIR__ . '/' . $logoAnterior)) unlink(__DIR__ . '/' . $logoAnterior);
            $d['logo'] = "uploads/logos/$nombre";
        } else {
            $errores[] = 'No se pudo guardar el logo en el servidor.';
        }
    }

    if (!$errores) {
        $_SESSION['registro']['paso2'] = $d;
        header('Location: registro-3.php');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tu negocio · Citara</title>
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
    <div class="paso activo"><span class="paso-num">2</span><div><strong>Negocio y sede</strong><small>Datos del salón y horario</small></div></div>
    <div class="paso"><span class="paso-num">3</span><div><strong>Servicios</strong><small>Catálogo y precios</small></div></div>

    <p class="panel-pie mt-auto mb-0">Los datos de tu negocio quedan separados de los de otros negocios.</p>
  </aside>

  <section class="col-12 col-lg-8 d-flex align-items-center justify-content-center p-4">
    <div class="form-ancho-lg">
      <img src="../assets/citara-logo.png" alt="Citara" height="40" class="d-lg-none mb-4">

      <p class="etiqueta mb-2">Paso 2 de 3</p>
      <h1 class="mb-2">Cuéntanos de tu negocio</h1>
      <p class="text-secondary mb-4">Estos datos aparecen en tu enlace de reservas y en las facturas.</p>

      <?php if ($errores): ?>
        <div class="alert alert-danger" role="alert">
          <i class="bi bi-exclamation-circle me-1"></i>
          <?php foreach ($errores as $e): ?><div><?= h($e) ?></div><?php endforeach; ?>
        </div>
      <?php endif; ?>

      <form method="post" action="" enctype="multipart/form-data">
        <div class="card p-4">

          <p class="etiqueta mb-3">Negocio</p>
          <div class="row g-3 mb-4">
            <div class="col-md-8">
              <label class="form-label" for="negocio">Nombre del negocio</label>
              <input id="negocio" name="negocio" class="form-control" placeholder="Nombre del salón" value="<?= h($d['negocio']) ?>" required>
            </div>
            <div class="col-md-4">
              <label class="form-label" for="nit">NIT</label>
              <input id="nit" name="nit" class="form-control" placeholder="900123456" value="<?= h($d['nit']) ?>">
            </div>
            <div class="col-md-7">
              <label class="form-label" for="tipo">Tipo de negocio</label>
              <select id="tipo" name="tipo" class="form-select">
                <?php foreach ($tipos as $t): ?>
                  <option <?= $t === $d['tipo'] ? 'selected' : '' ?>><?= h($t) ?></option>
                <?php endforeach; ?>
              </select>
            </div>
            <div class="col-md-5">
              <label class="form-label" for="slug">Enlace de reservas</label>
              <input id="slug" name="slug" class="form-control" placeholder="barber-092" value="<?= h($d['slug']) ?>"
                     pattern="[a-z0-9]+(-[a-z0-9]+)*" maxlength="60" autocapitalize="none" spellcheck="false">
              <div class="form-text">citara.juangg.com/<span id="slug-vista"><?= h($d['slug'] ?: 'tu-negocio') ?></span></div>
            </div>
            <div class="col-12">
              <label class="form-label">Logo</label>
              <label class="subir w-100">
                <i class="bi bi-upload"></i>
                <span id="logo-texto"><?= $d['logo'] ? 'Logo cargado ✓ (clic para cambiarlo)' : 'Subir imagen' ?></span>
                <input type="file" name="logo" accept="image/*" hidden
                       onchange="document.getElementById('logo-texto').textContent = this.files[0] ? this.files[0].name : 'Subir imagen'">
              </label>
            </div>
          </div>

          <p class="etiqueta mb-3">Plan</p>
          <div class="row g-3 mb-4">
            <?php foreach ($planes as $id => $p): ?>
              <div class="col-md">
                <input type="radio" class="btn-check" name="plan_id" id="plan<?= $id ?>" value="<?= $id ?>"
                       <?= (int)$d['plan_id'] === $id ? 'checked' : '' ?> required>
                <label class="btn btn-outline-primary w-100 h-100 text-start p-3" for="plan<?= $id ?>">
                  <strong class="d-block"><?= h($p['nombre']) ?></strong>
                  <?php if ($p['precio'] !== null): ?>
                    <span class="d-block fs-5"><?= is_numeric($p['precio']) ? '$' . number_format((float)$p['precio'], 0, ',', '.') : h($p['precio']) ?><small class="fs-6 opacity-75"> /mes</small></span>
                  <?php endif; ?>
                  <?php if ($p['descripcion'] !== ''): ?>
                    <small class="d-block opacity-75 mt-1"><?= h($p['descripcion']) ?></small>
                  <?php endif; ?>
                </label>
              </div>
            <?php endforeach; ?>
          </div>

          <p class="etiqueta mb-3">Primera sede</p>
          <div class="row g-3">
            <div class="col-md-7">
              <label class="form-label" for="sede">Nombre de la sede</label>
              <input id="sede" name="sede" class="form-control" placeholder="Sede principal" value="<?= h($d['sede']) ?>" required>
            </div>
            <div class="col-md-5">
              <label class="form-label" for="ciudad">Ciudad</label>
              <input id="ciudad" name="ciudad" class="form-control" placeholder="Bogotá" value="<?= h($d['ciudad']) ?>" required>
            </div>
            <div class="col-12">
              <label class="form-label" for="dir">Dirección</label>
              <input id="dir" name="dir" class="form-control" placeholder="Cra. 15 # 85-20" value="<?= h($d['direccion']) ?>" required>
            </div>

            <div class="col-12">
              <label class="form-label d-block">Días de atención</label>
              <div class="d-flex flex-wrap gap-2">
                <?php foreach ($diasNombres as $num => $nombre): ?>
                  <input type="checkbox" class="btn-check" id="d<?= $num ?>" name="dias[]" value="<?= $num ?>" <?= in_array($num, $d['dias'], true) ? 'checked' : '' ?>><label class="btn btn-outline-dark rounded-pill" for="d<?= $num ?>"><?= $nombre ?></label>
                <?php endforeach; ?>
              </div>
            </div>

            <div class="col-md-6">
              <label class="form-label" for="abre">Abre</label>
              <input id="abre" name="abre" type="time" class="form-control" value="<?= h($d['abre']) ?>" required>
            </div>
            <div class="col-md-6">
              <label class="form-label" for="cierra">Cierra</label>
              <input id="cierra" name="cierra" type="time" class="form-control" value="<?= h($d['cierra']) ?>" required>
            </div>

            <p class="text-secondary small mb-0">Podrás agregar más sedes después, desde «Negocio y sedes».</p>
          </div>
        </div>

        <div class="d-flex justify-content-end gap-2 mt-3">
          <a href="registro-1.php" class="btn btn-secondary px-4">Atrás</a>
          <button type="submit" class="btn btn-primary px-4">Continuar <i class="bi bi-arrow-right ms-1"></i></button>
        </div>
      </form>
    </div>
  </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
  // Arma el enlace mientras escribe el nombre del negocio (hasta que lo edite a mano)
  const negocio = document.getElementById('negocio');
  const slug    = document.getElementById('slug');
  const vista   = document.getElementById('slug-vista');
  let editadoAMano = slug.value !== '';

  const slugify = t => t.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
                        .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);

  negocio.addEventListener('input', () => {
    if (!editadoAMano) { slug.value = slugify(negocio.value); vista.textContent = slug.value || 'tu-negocio'; }
  });
  slug.addEventListener('input', () => {
    editadoAMano = slug.value !== '';
    vista.textContent = slugify(slug.value) || 'tu-negocio';
  });
  slug.addEventListener('blur', () => { slug.value = slugify(slug.value); });
</script>
</body>
</html>