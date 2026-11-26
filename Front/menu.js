// Menú lateral compartido por todas las pantallas del panel.
// Cada página trae <div id="menu-lateral" data-activo="agenda" data-rol="administrador"></div>

(function() {
    const LOGO = '../assets/citara-logo.png';

    const opciones = [
        { id: 'agenda', texto: 'Agenda', icono: 'calendar3', href: 'agenda.php' },
        { id: 'clientes', texto: 'Clientes', icono: 'people', href: 'clientes.php' },
        { id: 'equipo', texto: 'Equipo', icono: 'person-vcard', href: 'equipo.php' },
        { id: 'turnos', texto: 'Turnos', icono: 'clock-history', href: 'turnos.php' },
        { id: 'servicios', texto: 'Servicios', icono: 'scissors', href: 'servicios.php' },
        { id: 'facturas', texto: 'Facturas', icono: 'receipt', href: 'facturas.php' },
        { id: 'comisiones', texto: 'Comisiones', icono: 'percent', href: 'comisiones.php' },
        { id: 'pagos', texto: 'Pagos al equipo', icono: 'cash-coin', href: 'pago.php' },
        { id: 'inventario', texto: 'Inventario', icono: 'box-seam', href: 'inventario.php' },
        { id: 'dotacion', texto: 'Dotación', icono: 'bag-check', href: 'dotacion.php' },
        // Solo el dueño
        { id: 'finanzas', texto: 'Finanzas', icono: 'bar-chart', href: 'finanzas.php', soloDueno: true },
        { id: 'reportes', texto: 'Reportes', icono: 'file-earmark-text', href: 'reportes.php', soloDueno: true },
        { id: 'usuarios', texto: 'Usuarios y permisos', icono: 'shield-check', href: 'usuarios.php', soloDueno: true },
        { id: 'sedes', texto: 'Negocio y sedes', icono: 'geo-alt', href: 'sedes.php', soloDueno: true }
    ];

    // Menú del empleado: solo su día, sus productos y sus pagos
    const opcionesEmpleado = [
        { id: 'hoy', texto: 'Mi día', icono: 'calendar3', href: 'empleado-hoy.php' },
        { id: 'productos', texto: 'Mis productos', icono: 'box-seam', href: 'empleado-productos.php' },
        { id: 'pagos', texto: 'Mis pagos', icono: 'cash-coin', href: 'empleado-pagos.php' }
    ];
    // Menú de la plataforma (soporte)
    const opcionesPlataforma = [
        { id: 'negocios', texto: 'Negocios', icono: 'shop', href: 'plataforma.php' }
    ];

    const cont = document.getElementById('menu-lateral');
    if (!cont) return;

    const activo = cont.dataset.activo;
    const rolClave = cont.dataset.rol;
    const esDueno = rolClave === 'dueno';
    const rol = { dueno: 'Dueño', administrador: 'Administrador', empleado: 'Empleado', admin_plataforma: 'Plataforma' }[rolClave] || rolClave;
    const nombre = cont.dataset.nombre || '';
    const sede = cont.dataset.sede || '';
    const ini = nombre.split(/\s+/).filter(Boolean).slice(0, 2).map(p => p[0].toUpperCase()).join('') || 'U';
    const esc = t => String(t).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

    const base = rolClave === 'empleado' ? opcionesEmpleado : (rolClave === 'admin_plataforma' ? opcionesPlataforma : opciones);
    const lista = base
        .filter(o => esDueno || !o.soloDueno)
        .map(o => `<a class="nav-link${o.id === activo ? ' active' : ''}" href="${o.href}"><i class="bi bi-${o.icono} me-3"></i>${o.texto}</a>`)
        .join('');

    const usuario = `
    <div class="usuario-caja d-flex align-items-center gap-2">
      <span class="avatar rounded-circle d-inline-flex align-items-center justify-content-center">${esc(ini)}</span>
      <div class="lh-sm">
        <strong class="d-block">${esc(nombre)}</strong>
        <small>${rol}${sede ? ' · ' + esc(sede) : ''}</small>
      </div>
    </div>
    <a class="btn btn-outline-light btn-sm w-100 mt-2" href="salir.php"><i class="bi bi-box-arrow-right me-1"></i>Salir</a>`;

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