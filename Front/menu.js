// Menú lateral compartido por todas las pantallas del panel.
// Cada página trae <div id="menu-lateral" data-activo="agenda" data-rol="administrador"></div>

(function () {
  const LOGO = '../assets/citara-logo.png';

  const opciones = [
    { id: 'agenda',     texto: 'Agenda',             icono: 'calendar3',          href: 'agenda.html' },
    { id: 'clientes',   texto: 'Clientes',           icono: 'people',             href: 'clientes.html' },
    { id: 'equipo',     texto: 'Equipo',             icono: 'person-vcard',       href: 'equipo.html' },
    { id: 'servicios',  texto: 'Servicios',          icono: 'scissors',           href: 'servicios.html' },
    { id: 'facturas',   texto: 'Facturas',           icono: 'receipt',            href: 'facturas.html' },
    { id: 'comisiones', texto: 'Comisiones y pagos', icono: 'cash-coin',          href: 'comisiones.html' },
    { id: 'inventario', texto: 'Inventario',         icono: 'box-seam',           href: 'inventario.html' },
    // Solo el dueño
    { id: 'finanzas',   texto: 'Finanzas',            icono: 'bar-chart',          href: 'finanzas.html',  soloDueno: true },
    { id: 'reportes',   texto: 'Reportes',            icono: 'file-earmark-text',  href: 'reportes.html',  soloDueno: true },
    { id: 'usuarios',   texto: 'Usuarios y permisos', icono: 'shield-check',       href: 'usuarios.html',  soloDueno: true },
    { id: 'sedes',      texto: 'Negocio y sedes',     icono: 'geo-alt',            href: 'sedes.html',     soloDueno: true }
  ];

  const cont = document.getElementById('menu-lateral');
  if (!cont) return;

  const activo = cont.dataset.activo;
  const esDueno = cont.dataset.rol === 'dueno';
  const rol = esDueno ? 'Dueño' : 'Administrador';

  const lista = opciones
    .filter(o => esDueno || !o.soloDueno)
    .map(o => `<a class="nav-link${o.id === activo ? ' active' : ''}" href="${o.href}"><i class="bi bi-${o.icono} me-3"></i>${o.texto}</a>`)
    .join('');

  const usuario = `
    <div class="usuario-caja d-flex align-items-center gap-2">
      <span class="avatar rounded-circle d-inline-flex align-items-center justify-content-center">IR</span>
      <div class="lh-sm">
        <strong class="d-block">Isabel Rojas</strong>
        <small>${rol} · Sede principal</small>
      </div>
    </div>`;

  cont.innerHTML = `
    <!-- Celular: barra superior + menú desplegable (offcanvas de Bootstrap) -->
    <header class="barra-movil d-lg-none d-flex align-items-center gap-3 px-3 py-2">
      <button class="btn btn-outline-light" type="button" data-bs-toggle="offcanvas" data-bs-target="#menu-movil" aria-label="Abrir menú">
        <i class="bi bi-list"></i>
      </button>
      <div class="logo-caja"><img src="${LOGO}" alt="Citara" height="28"></div>
    </header>

    <div class="offcanvas offcanvas-start offcanvas-citara" tabindex="-1" id="menu-movil" aria-label="Menú">
      <div class="offcanvas-header">
        <div class="logo-caja"><img src="${LOGO}" alt="Citara" height="32"></div>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="offcanvas" aria-label="Cerrar"></button>
      </div>
      <div class="offcanvas-body d-flex flex-column">
        <nav class="nav nav-pills nav-citara flex-column gap-1">${lista}</nav>
        <div class="mt-auto pt-3">${usuario}</div>
      </div>
    </div>

    <!-- Pantallas grandes: menú fijo a la izquierda -->
    <aside class="menu-lateral d-none d-lg-flex flex-column">
      <nav class="nav nav-pills nav-citara flex-column gap-1">${lista}</nav>
      <div class="mt-auto pt-3">
        <div class="logo-caja mb-3"><img src="${LOGO}" alt="Citara" height="40"></div>
        ${usuario}
      </div>
    </aside>`;
})();