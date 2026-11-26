<?php
session_start();

// Si ya inició sesión, va a la pantalla que le corresponde
function destino_por_rol($rol) {
    if ($rol === 'empleado') return 'empleado-hoy.php';
    if ($rol === 'admin_plataforma') return 'plataforma.php';
    return 'agenda.php';
}
if (isset($_SESSION['usuario_id'])) {
    header('Location: ' . destino_por_rol($_SESSION['rol'] ?? ''));
    exit;
}

$error  = '';
$correo = '';
$enlace = strtolower(trim($_GET['n'] ?? $_POST['n'] ?? ''));   // enlace del negocio (opcional): ?n=estetica-001

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $local = is_file(__DIR__ . '/conexion.local.php') ? '/conexion.local.php' : '/conexion.php';
    require_once __DIR__ . $local;
    $conexion->set_charset('utf8mb4');

    $correo = strtolower(trim($_POST['correo'] ?? ''));
    $clave  = $_POST['clave'] ?? '';

    if ($correo === '' || $clave === '') {
        $error = 'Escribe tu correo y tu contraseña.';
    } else {
        $sesion = null;

        // 1. Usuarios de un negocio (el correo solo es único dentro de cada negocio)
        $sql = "SELECT u.id, u.negocio_id, u.nombres, u.apellidos, u.correo, u.clave_hash, r.clave AS rol, n.slug,
                       e.id AS empleado_id,
                       COALESCE(e.sede_id,
                                (SELECT us.sede_id FROM usuario_sede us WHERE us.usuario_id = u.id ORDER BY us.sede_id LIMIT 1),
                                (SELECT s.id FROM sede s WHERE s.negocio_id = u.negocio_id AND s.principal = 1 LIMIT 1)) AS sede_id
                  FROM usuario u
                  JOIN rol r ON r.id = u.rol_id
                  JOIN negocio n ON n.id = u.negocio_id
                  LEFT JOIN empleado e ON e.negocio_id = u.negocio_id AND e.usuario_id = u.id
                 WHERE u.correo = ? AND u.activo = 1 AND n.estado = 'activo'" . ($enlace !== '' ? " AND n.slug = ?" : "");
        $stmt = $conexion->prepare($sql);
        if ($enlace !== '') $stmt->bind_param('ss', $correo, $enlace); else $stmt->bind_param('s', $correo);
        $stmt->execute();
        $coinciden = [];
        foreach ($stmt->get_result() as $u) {
            if (password_verify($clave, $u['clave_hash'])) $coinciden[] = $u;
        }
        $stmt->close();

        if (count($coinciden) > 1) {
            $error = 'Ese correo está en varios negocios. Entra desde el enlace de tu negocio (ej: ?n=mi-salon).';
        } elseif (count($coinciden) === 1) {
            $u = $coinciden[0];
            $sede = $conexion->query("SELECT nombre FROM sede WHERE id = " . (int)$u['sede_id'])->fetch_row();
            $sesion = [
                'usuario_id'     => (int)$u['id'],
                'negocio_id'     => (int)$u['negocio_id'],
                'sede_id'        => (int)$u['sede_id'],
                'sede_nombre'    => $sede[0] ?? '',
                'empleado_id'    => $u['empleado_id'] ? (int)$u['empleado_id'] : null,
                'rol'            => $u['rol'],
                'tipo_cuenta'    => 'negocio',
                'usuario_correo' => $u['correo'],
                'usuario_nombre' => trim(($u['nombres'] ?? '') . ' ' . ($u['apellidos'] ?? '')) ?: $u['correo'],
            ];
            $conexion->query("UPDATE usuario SET ultimo_acceso = UTC_TIMESTAMP() WHERE id = " . (int)$u['id']);
        } else {
            // 2. Cuentas de soporte de la plataforma
            $stmt = $conexion->prepare("SELECT id, correo, clave_hash FROM admin_plataforma WHERE correo = ? AND activo = 1 LIMIT 1");
            $stmt->bind_param('s', $correo);
            $stmt->execute();
            $a = $stmt->get_result()->fetch_assoc();
            $stmt->close();
            if ($a && password_verify($clave, $a['clave_hash'])) {
                $sesion = [
                    'usuario_id'     => (int)$a['id'],
                    'negocio_id'     => null,
                    'sede_id'        => null,
                    'sede_nombre'    => '',
                    'empleado_id'    => null,
                    'rol'            => 'admin_plataforma',
                    'tipo_cuenta'    => 'plataforma',
                    'usuario_correo' => $a['correo'],
                    'usuario_nombre' => 'Soporte',
                ];
            }
        }

        if ($sesion) {
            session_regenerate_id(true);
            foreach ($sesion as $k => $v) $_SESSION[$k] = $v;

            // "Mantener sesión": la cookie dura 30 días en vez de cerrarse con el navegador
            if (!empty($_POST['mantener'])) {
                $p = session_get_cookie_params();
                setcookie(session_name(), session_id(), time() + 60 * 60 * 24 * 30, $p['path'], $p['domain'], $p['secure'], true);
            }
            header('Location: ' . destino_por_rol($sesion['rol']));
            exit;
        }
        if (!$error) $error = 'Correo o contraseña incorrectos.';
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
    <div class="logo-caja"><img src="../assets/citara-logo.png" alt="Citara" height="52"></div>
    <div>
      <h2 class="panel-titulo">Menos coordinar, más tiempo para tu negocio.</h2>
      <p class="panel-texto">Reservas, agenda, comisiones e inventario en un solo lugar, para cada sede.</p>
    </div>
  </aside>

  <!-- Formulario (derecha) -->
  <section class="col-12 col-lg-7 d-flex align-items-center justify-content-center p-4">
    <div class="form-ancho">

      <!-- Logo solo en celular, donde se oculta el panel -->
      <img src="../assets/citara-logo.png" alt="Citara" height="40" class="d-lg-none mb-4">

      <h1 class="mb-2">Inicia sesión</h1>
      <p class="text-secondary mb-4">Empleados, administradores y dueños entran aquí. Cada quien ve solo lo que le corresponde.</p>

      <?php if ($error): ?>
        <div class="alert alert-danger d-flex align-items-center gap-2" role="alert">
          <i class="bi bi-exclamation-circle"></i> <?= htmlspecialchars($error) ?>
        </div>
      <?php endif; ?>

      <form method="post" action="">
        <input type="hidden" name="n" value="<?= htmlspecialchars($enlace) ?>">
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