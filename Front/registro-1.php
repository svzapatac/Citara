<?php
session_start();

// Si ya tiene sesión, no necesita registrarse
if (isset($_SESSION['usuario_id'])) {
    header('Location: agenda.php');
    exit;
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$tiposDoc = ['Cédula', 'Cédula de extranjería', 'Pasaporte'];

// Si vuelve con "Atrás", se rellenan los datos que ya había escrito
$d = $_SESSION['registro']['paso1'] ?? [
    'nombres' => '', 'apellidos' => '', 'tipo_documento' => 'Cédula',
    'numero_documento' => '', 'celular' => '', 'correo' => '',
];
$errores = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_once __DIR__ . '/conexion.php';

    $d = [
        'nombres'          => trim($_POST['nombres'] ?? ''),
        'apellidos'        => trim($_POST['apellidos'] ?? ''),
        'tipo_documento'   => $_POST['tipodoc'] ?? '',
        'numero_documento' => preg_replace('/\s+/', '', $_POST['numdoc'] ?? ''),
        'celular'          => preg_replace('/\D/', '', $_POST['celular'] ?? ''),
        'correo'           => strtolower(trim($_POST['correo'] ?? '')),
    ];
    $clave  = $_POST['clave'] ?? '';
    $clave2 = $_POST['clave2'] ?? '';

    if ($d['nombres'] === '')   $errores[] = 'Escribe tus nombres.';
    if ($d['apellidos'] === '') $errores[] = 'Escribe tus apellidos.';
    if (!in_array($d['tipo_documento'], $tiposDoc, true)) $errores[] = 'Elige un tipo de documento válido.';
    if (!preg_match('/^[A-Za-z0-9]{5,20}$/', $d['numero_documento'])) $errores[] = 'El número de documento no es válido.';
    if (!preg_match('/^\d{7,15}$/', $d['celular'])) $errores[] = 'El celular no es válido.';
    if (!filter_var($d['correo'], FILTER_VALIDATE_EMAIL)) $errores[] = 'El correo no es válido.';
    if (strlen($clave) < 8) $errores[] = 'La contraseña debe tener al menos 8 caracteres.';
    elseif ($clave !== $clave2) $errores[] = 'Las contraseñas no coinciden.';
    if (empty($_POST['terminos'])) $errores[] = 'Debes aceptar los términos.';

    // ¿El correo ya existe?
    if (!$errores) {
        try {
            $stmt = $conexion->prepare(
                "SELECT 1 FROM usuario WHERE correo = ?"
            );
            $stmt->bind_param('ss', $d['correo'], $d['correo']);
            $stmt->execute();
            if ($stmt->get_result()->fetch_row()) {
                $errores[] = 'Ya existe una cuenta con ese correo. Inicia sesión.';
            }
            $stmt->close();
        } catch (mysqli_sql_exception $e) {
            // Mientras pruebas se muestra el error real; luego déjalo genérico.
            $errores[] = 'Error de base de datos: ' . $e->getMessage();
        }
    }

    if (!$errores) {
        // La clave se guarda ya en hash; nunca en texto plano
        $d['clave_hash'] = password_hash($clave, PASSWORD_DEFAULT);
        $_SESSION['registro']['paso1'] = $d;
        header('Location: registro-2.php');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Crea tu cuenta · Citara</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="Style.css" rel="stylesheet">
</head>
<body>

<main class="row g-0 min-vh-100">

  <aside class="col-lg-4 panel-marino d-none d-lg-flex flex-column">
    <div class="logo-caja mb-5"><img src="../assets/citara-logo.png" alt="Citara" height="52"></div>

    <div class="paso activo"><span class="paso-num">1</span><div><strong>Cuenta del dueño</strong><small>Tus datos de acceso</small></div></div>
    <div class="paso"><span class="paso-num">2</span><div><strong>Negocio y sede</strong><small>Datos del salón y horario</small></div></div>
    <div class="paso"><span class="paso-num">3</span><div><strong>Servicios</strong><small>Catálogo y precios</small></div></div>

    <p class="panel-pie mt-auto mb-0">Los datos de tu negocio quedan separados de los de otros negocios.</p>
  </aside>

  <section class="col-12 col-lg-8 d-flex align-items-center justify-content-center p-4">
    <div class="form-ancho-lg">
      <img src="../assets/citara-logo.png" alt="Citara" height="40" class="d-lg-none mb-4">

      <p class="etiqueta mb-2">Paso 1 de 3</p>
      <h1 class="mb-2">Crea tu cuenta de dueño</h1>
      <p class="text-secondary mb-4">Con esta cuenta administras tu negocio, tus sedes y tu equipo.</p>

      <?php if ($errores): ?>
        <div class="alert alert-danger" role="alert">
          <i class="bi bi-exclamation-circle me-1"></i>
          <?php foreach ($errores as $e): ?><div><?= h($e) ?></div><?php endforeach; ?>
        </div>
      <?php endif; ?>

      <form method="post" action="">
        <div class="card p-4">
          <div class="row g-3">
            <div class="col-md-6">
              <label class="form-label" for="nombres">Nombres</label>
              <input id="nombres" name="nombres" class="form-control" placeholder="Isabel" value="<?= h($d['nombres']) ?>" required>
            </div>
            <div class="col-md-6">
              <label class="form-label" for="apellidos">Apellidos</label>
              <input id="apellidos" name="apellidos" class="form-control" placeholder="Rojas Gomez" value="<?= h($d['apellidos']) ?>" required>
            </div>

            <div class="col-md-4">
              <label class="form-label" for="tipodoc">Tipo de documento</label>
              <select id="tipodoc" name="tipodoc" class="form-select">
                <?php foreach ($tiposDoc as $t): ?>
                  <option <?= $t === $d['tipo_documento'] ? 'selected' : '' ?>><?= h($t) ?></option>
                <?php endforeach; ?>
              </select>
            </div>
            <div class="col-md-8">
              <label class="form-label" for="numdoc">Número de documento</label>
              <input id="numdoc" name="numdoc" class="form-control" inputmode="numeric" placeholder="1020345678" value="<?= h($d['numero_documento']) ?>" required>
            </div>

            <div class="col-md-6">
              <label class="form-label" for="celular">Celular</label>
              <input id="celular" name="celular" type="tel" class="form-control" placeholder="3001234567" value="<?= h($d['celular']) ?>" required>
            </div>
            <div class="col-md-6">
              <label class="form-label" for="correo">Correo</label>
              <input id="correo" name="correo" type="email" class="form-control" placeholder="isabelrg@correo.com" value="<?= h($d['correo']) ?>" required>
            </div>

            <div class="col-md-6">
              <label class="form-label" for="clave">Contraseña</label>
              <input id="clave" name="clave" type="password" class="form-control" placeholder="Clave12345" minlength="8" required>
            </div>
            <div class="col-md-6">
              <label class="form-label" for="clave2">Confirmar contraseña</label>
              <input id="clave2" name="clave2" type="password" class="form-control" placeholder="Clave12345" minlength="8" required>
            </div>

            <div class="col-12">
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="terminos" name="terminos" value="1" checked required>
                <label class="form-check-label text-secondary" for="terminos">Acepto los términos y el tratamiento de mis datos</label>
              </div>
            </div>
          </div>
        </div>

        <div class="d-flex justify-content-between align-items-center mt-3">
          <a href="index.php" class="text-secondary small">¿Ya tienes cuenta? Inicia sesión</a>
          <button type="submit" class="btn btn-primary px-4">Continuar <i class="bi bi-arrow-right ms-1"></i></button>
        </div>
      </form>
    </div>
  </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>