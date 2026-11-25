<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pago de Laura · Citara</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link href="Style.css" rel="stylesheet">
</head>
<body>

<div class="d-flex flex-column flex-lg-row">

  <!-- Menú lateral (lo construye menu.js) -->
  <div id="menu-lateral" class="menu-envoltura" data-activo="comisiones" data-rol="dueno"></div>

  <main class="contenido p-3 p-lg-4">

    <h1 class="mb-1">Pago de Laura</h1>
    <p class="text-secondary mb-3">Servicios realizados y descuentos del período.</p>

    <div class="row g-3">

      <!-- Detalle -->
      <div class="col-12 col-xl-8">
        <div class="card p-2 p-md-3">
          <div class="table-responsive">
            <table class="table tabla-citara">
              <thead>
                <tr><th>Fecha</th><th>Concepto</th><th>Factura</th><th class="text-end">Valor</th><th class="text-end">Valor para su pago</th></tr>
              </thead>
              <tbody>
            <tr><td>3 nov</td><td>Corte</td><td>0121</td><td class="text-end">$35.000</td><td class="text-end">$14.000</td></tr>
            <tr><td>5 nov</td><td>Peinado</td><td>0124</td><td class="text-end">$40.000</td><td class="text-end">$16.000</td></tr>
            <tr><td>10 nov</td><td>Corte</td><td>0131</td><td class="text-end">$35.000</td><td class="text-end">$14.000</td></tr>
            <tr><td>17 nov</td><td>Corte</td><td>0140</td><td class="text-end">$35.000</td><td class="text-end">$14.000</td></tr>
            <tr><td>22 nov</td><td>Corte</td><td>0146</td><td class="text-end">$35.000</td><td class="text-end">$14.000</td></tr>
            <tr><td></td><td class="text-secondary">13 servicios más del mes</td><td></td><td class="text-end">$575.000</td><td class="text-end">$230.000</td></tr>
            <tr class="table-active"><td>19 nov</td><td>Shampoo hidratante · 3 vendidas a clientes</td><td></td><td class="text-end">−$90.000</td><td class="text-end">−$90.000</td></tr>
            <tr class="table-active"><td>24 nov</td><td>Mascarilla capilar · 1 de uso personal</td><td></td><td class="text-end">−$30.000</td><td class="text-end">−$30.000</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Resumen -->
      <div class="col-12 col-xl-4">
        <div class="card p-4">
          <div class="d-flex align-items-center gap-3 mb-3">
            <span class="avatar avatar-80 rounded-circle d-inline-flex align-items-center justify-content-center">LG</span>
            <div>
              <div class="nombre-grande">Laura Gómez</div>
              <small class="text-secondary">Mensual · noviembre</small>
            </div>
          </div>

          <div class="dato-fila"><span>Valor atendido (18 servicios)</span><strong>$720.000</strong></div>
          <div class="dato-fila"><span>Comisión 40%</span><strong>$288.000</strong></div>
          <div class="dato-fila"><span>Productos para vender (3 × $30.000)</span><strong>−$90.000</strong></div>
          <div class="dato-fila"><span>Uso personal (1 × $30.000)</span><strong>−$30.000</strong></div>

          <div class="total-barra total-grande my-3">
            <span class="etiqueta">Total a pagar</span>
            <strong>$168.000</strong>
          </div>

          <div class="nota-suave mb-3"><strong>Ganancia por ventas:</strong> cobró $114.000 a los clientes y descuenta $90.000, así que se queda con $24.000. La compra de uso personal no deja ganancia.</div>

          <a href="comisiones.php" class="btn btn-primary w-100 mb-2"><i class="bi bi-check-lg me-2"></i>Marcar como pagado</a>
          <a href="comisiones.php" class="btn btn-secondary w-100">Volver</a>
        </div>
      </div>

    </div>

  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="menu.js"></script>
</body>
</html>