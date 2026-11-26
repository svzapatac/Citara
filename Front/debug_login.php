<?php
// DIAGNÓSTICO DEL LOGIN — BÓRRALO CUANDO TERMINES
require_once __DIR__ . '/conexion.php';

function fila($ok, $texto) {
    echo ($ok ? '✅ ' : '❌ ') . $texto . "\n";
}

$correo = trim($_POST['correo'] ?? '');
$clave  = $_POST['clave'] ?? '';
?>
<form method="post" style="font-family:sans-serif;max-width:360px;margin:30px auto">
  <h3>Diagnóstico login</h3>
  <input name="correo" placeholder="Correo" value="<?= htmlspecialchars($correo) ?>" style="width:100%;padding:6px;margin-bottom:6px">
  <input name="clave" placeholder="Clave" style="width:100%;padding:6px;margin-bottom:6px">
  <button>Probar</button>
</form>
<pre style="max-width:700px;margin:auto;font-size:14px">
<?php
if ($_SERVER['REQUEST_METHOD'] !== 'POST') exit;

// 1. Columnas de la tabla
$cols = [];
foreach ($conexion->query("SHOW COLUMNS FROM admin_plataforma") as $c) {
    $cols[] = $c['Field'] . ' (' . $c['Type'] . ')';
}
echo "Columnas de admin_plataforma:\n  " . implode("\n  ", $cols) . "\n\n";

// 2. ¿Existe el correo (sin importar activo)?
$stmt = $conexion->prepare("SELECT * FROM usuario WHERE correo = ?");
$stmt->bind_param('s', $correo);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();

fila((bool)$u, "Usuario con correo '" . htmlspecialchars($correo) . "' encontrado");
if (!$u) {
    echo "\nCorreos que sí hay en la tabla:\n";
    foreach ($conexion->query("SELECT correo FROM admin_plataforma") as $r) {
        echo "  '" . htmlspecialchars($r['correo']) . "'\n";
    }
    exit;
}

// 3. ¿Está activo?
fila(isset($u['activo']) && $u['activo'] == 1, "activo = " . var_export($u['activo'] ?? null, true));

// 4. ¿La clave guardada es un hash completo?
$guardada = $u['clave'] ?? null;
fila($guardada !== null, "Existe la columna 'clave'");
if ($guardada === null) exit;

$len = strlen($guardada);
fila(str_starts_with($guardada, '$2y$'), "La clave guardada es un hash bcrypt (empieza por \$2y\$)");
fila($len === 60, "Largo del hash: $len (debe ser 60)");
echo "   Valor guardado: " . htmlspecialchars($guardada) . "\n";

// 5. ¿Coincide la clave?
fila(password_verify($clave, $guardada), "password_verify con la clave escrita");