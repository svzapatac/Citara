<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Factura 0148 · Citara</title>
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

    <h1 class="mb-3">Factura 0148</h1>

    <div class="row g-3">

      <!-- La factura -->
      <div class="col-12 col-xl-7">
        <div class="card p-3 p-md-4">

          <div class="d-flex flex-wrap align-items-end justify-content-between gap-3 pb-3 divisor-punteado-abajo">
            <div>
              <img src="../assets/citara-logo.png" alt="Citara" height="56" class="mb-1">
              <div class="text-secondary">Sede principal · Cra. 15 # 85-20 · Bogotá</div>
            </div>
            <div class="text-sm-end">
              <p class="etiqueta mb-1">Factura</p>
              <div class="factura-num">N.º 0148</div>
              <small class="text-secondary">23 nov 2026 · 1 cita, 2 servicios</small>
            </div>
          </div>

          <div class="d-flex flex-wrap gap-4 py-3">
            <div><p class="etiqueta mb-1">Cliente</p><strong class="d-block">Ana Martínez</strong><span class="text-secondary">300 765 4321</span></div>
            <div><p class="etiqueta mb-1">Canal</p><strong>WhatsApp</strong></div>
            <div><p class="etiqueta mb-1">Estado</p><span class="badge bg-primary-subtle text-primary-emphasis">En curso</span></div>
          </div>

          <div class="table-responsive">
            <table class="table tabla-citara">
              <thead>
                <tr><th>Servicio</th><th>Empleado</th><th>Horario</th><th class="text-end">Valor</th></tr>
              </thead>
              <tbody>
                <tr>
                  <td><span class="punto"></span><strong>Corte</strong></td>
                  <td><div class="d-flex align-items-center gap-2"><span class="avatar avatar-40 rounded-circle d-inline-flex align-items-center justify-content-center">LG</span>Laura</div></td>
                  <td>10:00 a 10:30</td>
                  <td class="text-end"><strong>$35.000</strong></td>
                </tr>
                <tr>
                  <td><span class="punto"></span><strong>Uñas · Tradicional</strong></td>
                  <td><div class="d-flex align-items-center gap-2"><span class="avatar avatar-40 rounded-circle d-inline-flex align-items-center justify-content-center">CR</span>Camila</div></td>
                  <td>10:30 a 11:15</td>
                  <td class="text-end"><strong>$30.000</strong></td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="total-barra mt-3">
            <span class="etiqueta">Total</span>
            <strong>$65.000</strong>
          </div>
        </div>
      </div>

      <!-- Lateral -->
      <div class="col-12 col-xl-5 d-flex flex-column gap-3 no-imprimir">
        <div class="card p-4">
          <p class="etiqueta mb-2">Comisión que genera cada línea</p>
          <div class="dato-fila"><span>Laura · 40% de $35.000</span><strong>$14.000</strong></div>
          <div class="dato-fila"><span>Camila · 45% de $30.000</span><strong>$13.500</strong></div>
          <p class="text-secondary small mt-2 mb-0">Se suma a su liquidación cuando el servicio queda como realizado.</p>
        </div>

        <div class="card p-4">
          <button type="button" class="btn btn-outline-primary w-100 mb-2" onclick="window.print()"><i class="bi bi-file-earmark-text me-2"></i>Imprimir o guardar PDF</button>
          <a href="facturas.php" class="btn btn-secondary w-100">Volver al historial</a>
        </div>
      </div>

    </div>

  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="menu.js"></script>
</body>
</html>