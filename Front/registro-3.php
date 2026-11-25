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

      <form action="agenda.php">
        <div class="card p-4">

          <p class="etiqueta mb-2">Cabello · 30 min por servicio</p>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Corte</span><span class="duracion">30 min</span><input class="form-control" value="$35.000" aria-label="Precio de Corte"></div>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Color</span><span class="duracion">30 min</span><input class="form-control" value="$80.000" aria-label="Precio de Color"></div>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Peinado</span><span class="duracion">30 min</span><input class="form-control" value="$40.000" aria-label="Precio de Peinado"></div>

          <p class="etiqueta mt-3 mb-2">Uñas · 45 min por servicio</p>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Tradicional</span><span class="duracion">45 min</span><input class="form-control" value="$30.000" aria-label="Precio de Tradicional"></div>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Acrílicas</span><span class="duracion">45 min</span><input class="form-control" value="$70.000" aria-label="Precio de Acrílicas"></div>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Semipermanentes</span><span class="duracion">45 min</span><input class="form-control" value="$45.000" aria-label="Precio de Semipermanentes"></div>

          <p class="etiqueta mt-3 mb-2">Barbería · 30 min</p>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Barba</span><span class="duracion">30 min</span><input class="form-control" value="$20.000" aria-label="Precio de Barba"></div>

          <p class="etiqueta mt-3 mb-2">Cejas · 15 min</p>
          <div class="servicio"><input class="form-check-input" type="checkbox" checked><span class="nombre">Cejas</span><span class="duracion">15 min</span><input class="form-control" value="$15.000" aria-label="Precio de Cejas"></div>

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