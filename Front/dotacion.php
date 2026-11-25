<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dotación por área · Citara</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="Style.css" rel="stylesheet">
</head>
<body>

<div class="d-flex flex-column flex-lg-row">

  <!-- Menú lateral (lo construye menu.js) -->
  <div id="menu-lateral" class="menu-envoltura" data-activo="inventario" data-rol="administrador"></div>

  <main class="contenido p-3 p-lg-4">

    <!-- Encabezado -->
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div>
        <h1 class="mb-1">Dotación por área</h1>
        <p class="text-secondary mb-0 ancho-texto">Cada área recibe lo básico para sus servicios, no se entrega por separado a cada persona.</p>
      </div>
      <a href="#" class="btn btn-outline-primary"><i class="bi bi-plus-lg me-2"></i>Nueva pieza</a>
    </div>

    <div class="row g-3">

      <div class="col-12 col-xl-8">
        <div class="row g-3">
        <div class="col-12 col-md-6">
          <div class="card p-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
              <h2 class="card-titulo mb-0">Cabello</h2>
              <span class="badge bg-secondary-subtle text-secondary-emphasis">3 personas</span>
            </div>
            <div class="lista-lineas">
              <div class="dato-fila"><span>Tijeras de corte</span><strong>1</strong></div>
              <div class="dato-fila"><span>Tijeras de entresaque</span><strong>1</strong></div>
              <div class="dato-fila"><span>Secador</span><strong>1</strong></div>
              <div class="dato-fila"><span>Plancha</span><strong>1</strong></div>
              <div class="dato-fila"><span>Peinillas y cepillos</span><strong>1 set</strong></div>
              <div class="dato-fila"><span>Uniforme</span><strong>2</strong></div>
            </div>
          </div>
        </div>
        <div class="col-12 col-md-6">
          <div class="card p-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
              <h2 class="card-titulo mb-0">Uñas</h2>
              <span class="badge bg-secondary-subtle text-secondary-emphasis">1 persona</span>
            </div>
            <div class="lista-lineas">
              <div class="dato-fila"><span>Esmaltes (kit base)</span><strong>12</strong></div>
              <div class="dato-fila"><span>Brochas y pinceles</span><strong>1 set</strong></div>
              <div class="dato-fila"><span>Limas y pulidores</span><strong>1 set</strong></div>
              <div class="dato-fila"><span>Lámpara UV</span><strong>1</strong></div>
              <div class="dato-fila"><span>Uniforme</span><strong>2</strong></div>
            </div>
          </div>
        </div>
        <div class="col-12 col-md-6">
          <div class="card p-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
              <h2 class="card-titulo mb-0">Barbería</h2>
              <span class="badge bg-secondary-subtle text-secondary-emphasis">1 persona</span>
            </div>
            <div class="lista-lineas">
              <div class="dato-fila"><span>Tijeras de corte</span><strong>1</strong></div>
              <div class="dato-fila"><span>Máquina de corte</span><strong>1</strong></div>
              <div class="dato-fila"><span>Navajas</span><strong>2</strong></div>
              <div class="dato-fila"><span>Capa y cuello</span><strong>2</strong></div>
              <div class="dato-fila"><span>Uniforme</span><strong>2</strong></div>
            </div>
          </div>
        </div>
        <div class="col-12 col-md-6">
          <div class="card p-4 h-100">
            <div class="d-flex align-items-center justify-content-between mb-2">
              <h2 class="card-titulo mb-0">Cejas</h2>
              <span class="badge bg-secondary-subtle text-secondary-emphasis">2 personas</span>
            </div>
            <div class="lista-lineas">
              <div class="dato-fila"><span>Cera y calentador</span><strong>1</strong></div>
              <div class="dato-fila"><span>Pinzas</span><strong>2</strong></div>
              <div class="dato-fila"><span>Hilo y plantillas</span><strong>1 set</strong></div>
              <div class="dato-fila"><span>Uniforme</span><strong>2</strong></div>
            </div>
          </div>
        </div>
        </div>
      </div>

      <div class="col-12 col-xl-4">
        <div class="card p-4">
          <h2 class="card-titulo">Entregar o reponer</h2>
          <label class="form-label" for="persona">Empleado</label>
          <select id="persona" class="form-select mb-2">
            <option selected>Sofía Díaz · Cabello</option><option>Laura Gómez · Cabello</option><option>Patty Mora · Cabello</option>
            <option>Camila Ruiz · Uñas</option><option>Andrés Pardo · Barbería y cejas</option>
          </select>
            <div class="dotacion-fila py-2"><input class="form-check-input" type="checkbox" checked aria-label="Tijeras de corte"><span>Tijeras de corte</span></div>
            <div class="dotacion-fila py-2"><input class="form-check-input" type="checkbox" checked aria-label="Tijeras de entresaque"><span>Tijeras de entresaque</span></div>
            <div class="dotacion-fila py-2"><input class="form-check-input" type="checkbox" checked aria-label="Secador"><span>Secador</span></div>
            <div class="dotacion-fila py-2"><input class="form-check-input" type="checkbox" aria-label="Plancha"><span>Plancha</span><span class="badge bg-secondary-subtle text-secondary-emphasis ms-auto">Falta</span></div>
            <div class="dotacion-fila py-2"><input class="form-check-input" type="checkbox" checked aria-label="Peinillas y cepillos"><span>Peinillas y cepillos</span></div>
            <div class="dotacion-fila py-2"><input class="form-check-input" type="checkbox" checked aria-label="Uniforme"><span>Uniforme</span></div>
          <button type="button" class="btn btn-primary w-100 mt-3">Entregar piezas marcadas</button>
          <p class="text-secondary small mt-3">La dotación no se cobra. Si una pieza se pierde o se daña, el administrador decide si se descuenta del pago, como concepto aparte. Al retirar a la persona, la dotación se devuelve.</p>
          <a href="inventario.php" class="btn btn-secondary w-100">Volver al inventario</a>
        </div>
      </div>

    </div>

  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="menu.js"></script>
</body>
</html>