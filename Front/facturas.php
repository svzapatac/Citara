<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Historial de facturas · Citara</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="Style.css" rel="stylesheet">
</head>
<body>

<div class="d-flex flex-column flex-lg-row">

  <!-- Menú lateral (lo construye menu.js) -->
  <div id="menu-lateral" class="menu-envoltura" data-activo="facturas" data-rol="administrador"></div>

  <main class="contenido p-3 p-lg-4">

    <!-- Encabezado -->
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-3">
      <div>
        <h1 class="mb-1">Historial de facturas</h1>
        <p class="text-secondary mb-0 ancho-texto">Una factura por cita, con cada servicio y la persona que lo prestó.</p>
      </div>
      <div class="d-flex flex-wrap gap-2">
        <div class="input-group buscador">
          <span class="input-group-text border-end-0"><i class="bi bi-search"></i></span>
          <input type="search" class="form-control border-start-0" placeholder="Buscar cliente o N.º" aria-label="Buscar cliente o número">
        </div>
        <select class="form-select w-auto fw-semibold" aria-label="Empleado">
          <option selected>Empleado: todos</option><option>Laura</option><option>Camila</option><option>Patty</option><option>Sofía</option><option>Andrés</option>
        </select>
        <select class="form-select w-auto fw-semibold" aria-label="Mes">
          <option selected>Noviembre 2026</option><option>Octubre 2026</option>
        </select>
      </div>
    </div>

    <!-- Resumen -->
    <div class="row g-3 mb-3">
      <div class="col-12 col-md-6 col-xl-3">
        <div class="card p-4 h-100">
          <p class="etiqueta mb-2">Facturas del mes</p>
          <div class="d-flex align-items-center justify-content-between gap-2">
            <span class="cifra-grande">148</span>
            <span class="badge bg-primary-subtle text-primary-emphasis">Solo consulta</span>
          </div>
        </div>
      </div>
      <div class="col-12 col-md-6 col-xl-3">
        <div class="card p-4 h-100">
          <p class="etiqueta mb-2">Total facturado</p>
          <span class="cifra-grande">$5.420.000</span>
        </div>
      </div>
      <div class="col-12 col-xl-6">
        <div class="card p-4 h-100 justify-content-center">
          <p class="text-secondary mb-0">El sistema guarda y muestra cada factura. No las emite electrónicamente ni se conecta con un proveedor.</p>
        </div>
      </div>
    </div>

    <!-- Tabla de facturas -->
    <div class="card p-2 p-md-3">
      <div class="table-responsive">
        <table class="table table-hover tabla-citara">
          <thead>
            <tr>
              <th>N.º</th><th>Fecha</th><th>Cliente</th><th>Servicios</th><th>Empleados</th>
              <th class="text-end">Total</th><th></th>
            </tr>
          </thead>
          <tbody>
            <tr class="table-active">
              <td class="nombre-fila">0148</td>
              <td>23 nov</td>
              <td>Ana Martínez</td>
              <td>Corte + Uñas tradicional</td>
              <td>Laura, Camila</td>
              <td class="text-end">$65.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
            <tr>
              <td class="nombre-fila">0147</td>
              <td>23 nov</td>
              <td>Marta León</td>
              <td>Corte</td>
              <td>Laura</td>
              <td class="text-end">$35.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
            <tr>
              <td class="nombre-fila">0146</td>
              <td>22 nov</td>
              <td>Daniela Ruiz</td>
              <td>Uñas semipermanentes</td>
              <td>Camila</td>
              <td class="text-end">$45.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
            <tr>
              <td class="nombre-fila">0145</td>
              <td>21 nov</td>
              <td>Julián Rey</td>
              <td>Corte + Barba</td>
              <td>Andrés</td>
              <td class="text-end">$55.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
            <tr>
              <td class="nombre-fila">0144</td>
              <td>21 nov</td>
              <td>Valentina Gómez</td>
              <td>Uñas acrílicas</td>
              <td>Camila</td>
              <td class="text-end">$70.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
            <tr>
              <td class="nombre-fila">0143</td>
              <td>20 nov</td>
              <td>Elena Pardo</td>
              <td>Color</td>
              <td>Patty</td>
              <td class="text-end">$80.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
            <tr>
              <td class="nombre-fila">0142</td>
              <td>20 nov</td>
              <td>Rosa Vega</td>
              <td>Corte + Peinado</td>
              <td>Laura</td>
              <td class="text-end">$75.000</td>
              <td><a href="factura.php" class="enlace-fuerte">Ver detalle</a></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="menu.js"></script>
</body>
</html>