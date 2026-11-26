<?php
session_start();

// Si ya inició sesión, va directo a la agenda
if (isset($_SESSION['usuario_id'])) {
    header('Location: agenda.php');
    exit;
}

$error  = '';
$correo = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_once __DIR__ . '/conexion.php';

    $correo = trim($_POST['correo'] ?? '');
    $clave  = $_POST['clave'] ?? '';

    if ($correo === '' || $clave === '') {
        $error = 'Escribe tu correo y tu contraseña.';
    } else {
        $sesion = null;

        // 1. Dueños, administradores y empleados de un negocio
        $stmt = $conexion->prepare(
            "SELECT u.id, u.negocio_id, u.sede_id, u.nombres, u.correo, u.clave_hash, u.rol
             FROM usuarios u
             JOIN negocio n ON n.id = u.negocio_id
             WHERE u.correo = ? AND u.activo = 1 AND n.estado = 'activo'
             LIMIT 1"
        );
        $stmt->bind_param('s', $correo);
        $stmt->execute();
        $u = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if ($u && password_verify($clave, $u['clave_hash'])) {
            $sesion = [
                'usuario_id'     => $u['id'],
                'negocio_id'     => $u['negocio_id'],
                'sede_id'        => $u['sede_id'],
                'rol'            => $u['rol'],
                'tipo_cuenta'    => 'negocio',
                'usuario_correo' => $u['correo'],
                'usuario_nombre' => $u['nombres'],
            ];
        } else {
            // 2. Cuentas de soporte de la plataforma
            $stmt = $conexion->prepare(
                "SELECT id, correo, clave_hash FROM admin_plataforma WHERE correo = ? AND activo = 1 LIMIT 1"
            );
            $stmt->bind_param('s', $correo);
            $stmt->execute();
            $a = $stmt->get_result()->fetch_assoc();
            $stmt->close();

            if ($a && password_verify($clave, $a['clave_hash'])) {
                $sesion = [
                    'usuario_id'     => $a['id'],
                    'negocio_id'     => null,
                    'sede_id'        => null,
                    'rol'            => 'admin_plataforma',
                    'tipo_cuenta'    => 'plataforma',
                    'usuario_correo' => $a['correo'],
                    'usuario_nombre' => 'Soporte',
                ];
            }
        }

        if ($sesion) {
            session_regenerate_id(true);
            foreach ($sesion as $k => $v) {
                $_SESSION[$k] = $v;
            }

            // "Mantener sesión": la cookie dura 30 días en vez de cerrarse con el navegador
            if (!empty($_POST['mantener'])) {
                $p = session_get_cookie_params();
                setcookie(session_name(), session_id(), time() + 60 * 60 * 24 * 30,
                          $p['path'], $p['domain'], $p['secure'], true);
            }

            header('Location: agenda.php');
            exit;
        }

        $error = 'Correo o contraseña incorrectos.';
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Inicia sesión · Citara</title>

  <!-- Bootstrap, iconos y fuente Inter -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <!-- Tus estilos: siempre después de Bootstrap -->
  <link href="Style.css" rel="stylesheet">
</head>
<body>

<main class="row g-0 min-vh-100">

  <!-- Panel azul marino (izquierda) -->
  <aside class="col-lg-5 panel-marino d-none d-lg-flex flex-column justify-content-between">
    <div class="logo-caja"><img src="./assets/citara-logo.png" alt="Citara" height="52"></div>
    <div>
      <h2 class="panel-titulo">Menos coordinar, más tiempo para tu negocio.</h2>
      <p class="panel-texto">Reservas, agenda, comisiones e inventario en un solo lugar, para cada sede.</p>
    </div>
  </aside>

  <!-- Formulario (derecha) -->
  <section class="col-12 col-lg-7 d-flex align-items-center justify-content-center p-4">
    <div class="form-ancho">

      <!-- Logo solo en celular, donde se oculta el panel -->
      <img src="./assets/citara-logo.png" alt="Citara" height="40" class="d-lg-none mb-4">

      <h1 class="mb-2">Inicia sesión</h1>
      <p class="text-secondary mb-4">Empleados, administradores y dueños entran aquí. Cada quien ve solo lo que le corresponde.</p>

      <?php if ($error): ?>
        <div class="alert alert-danger d-flex align-items-center gap-2" role="alert">
          <i class="bi bi-exclamation-circle"></i> <?= htmlspecialchars($error) ?>
        </div>
      <?php endif; ?>

      <form method="post" action="">
        <label for="correo" class="form-label">Correo</label>
        <input type="email" id="correo" name="correo" class="form-control mb-3" placeholder="nombre@correo.com"
               value="<?= htmlspecialchars($correo) ?>" required autofocus>

        <label for="clave" class="form-label">Contraseña</label>
        <input type="password" id="clave" name="clave" class="form-control mb-3" placeholder="12345678" required>

        <div class="d-flex justify-content-between align-items-center mb-3">
          <div class="form-check">
            <input class="form-check-input" type="checkbox" id="mantener" name="mantener" value="1" checked>
            <label class="form-check-label text-secondary" for="mantener">Mantener sesión</label>
          </div>
        </div>

        <button type="submit" class="btn btn-primary w-100">Entrar</button>
      </form>

      <hr class="my-4">
<!--
      <a href="#" class="btn btn-outline-primary w-100 d-flex justify-content-between align-items-center mb-2">
        Soy cliente: reservar sin cuenta <i class="bi bi-arrow-right"></i>
      </a> -->
      <a href="registro-1.php" class="btn btn-secondary w-100 d-flex justify-content-between align-items-center">
        Soy dueño: registrar mi negocio <i class="bi bi-arrow-right"></i>
      </a>

    </div>
  </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>