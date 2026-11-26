#!/usr/bin/env python3
"""Genera 09_datos_masivos.sql: 55 negocios con datos coherentes para probar
(más de 50 filas en casi todas las tablas). Respeta las reglas de la base:
turnos sin cruzarse, citas dentro de turno, inventario sin negativos, etc.
Uso: python3 generar_masivo.py   (semilla fija: siempre genera lo mismo)
Se carga DESPUÉS de 01-06 (con o sin 07_datos_demo.sql)."""
import random, hashlib, datetime as dt
random.seed(2026)
OUT = ["SET NAMES utf8mb4;", "USE citara;", "SET autocommit = 0;"]
BASE = 1000                      # ids explícitos desde 1000: no chocan con la demo
cnt = {}
def nid(t):
    cnt[t] = cnt.get(t, BASE) + 1
    return cnt[t]
def q(v):
    if v is None: return "NULL"
    if isinstance(v, bool): return "1" if v else "0"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"
def ins(t, **kw):
    OUT.append(f"INSERT INTO {t} ({', '.join(kw)}) VALUES ({', '.join(q(v) for v in kw.values())});")
def sha(s): return hashlib.sha256(s.encode()).hexdigest()
HASH = "$2b$12$hashdemoCitaraNoUsarEnProduccion"

NOM_F = "Laura Camila Sofía Valentina Daniela Paula Andrea Mariana Juliana Natalia Carolina Marcela Lucía Isabela Gabriela Diana Patricia Sara Manuela Alejandra".split()
NOM_M = "Andrés Carlos Juan Santiago Mateo Felipe Sebastián David Daniel Camilo Esteban Nicolás Julián Miguel Diego Alejandro Jorge Pedro Luis Tomás".split()
APE = "Gómez Ruiz Pardo Díaz Martínez León Castro Ortiz Rojas Suárez Herrera Mejía Vargas Cárdenas Torres Ramírez Moreno Jiménez Navarro Quintero Salazar Peña Rincón Duarte Bermúdez".split()
BARRIOS = ["Chapinero","Usaquén","Cedritos","Suba","Kennedy","Teusaquillo","Engativá","Fontibón","Laureles","El Poblado","Envigado","Granada","Ciudad Jardín"]
CIUDADES = ["Bogotá","Medellín","Cali","Barranquilla","Bucaramanga","Cartagena"]
TIPOS = ["Salón","Estética","Barbería","Studio","Beauty","Estilo"]
def nombre(): 
    f = random.random() < .6
    return random.choice(NOM_F if f else NOM_M), f
def apellidos(): return f"{random.choice(APE)} {random.choice(APE)}"

SERV = [  # nombre, area(0..3), min, precio, asesoria
    ("Corte",0,30,35000,0),("Color",0,30,80000,1),("Peinado",0,30,40000,0),
    ("Tradicional",1,45,30000,0),("Acrílicas",1,45,70000,1),("Semipermanentes",1,45,45000,0),
    ("Barba",2,30,20000,0),("Cejas",3,15,15000,0)]
AREAS = ["Cabello","Uñas","Barbería","Cejas"]
DOCS = [("Documento de identidad",1),("Afiliación a salud (EPS)",1),("Certificado de bioseguridad",1),("Examen médico ocupacional",1),("Hoja de vida",0)]
CATG = ["Arriendo","Servicios públicos","Insumos","Nómina","Publicidad","Otros"]
FECHAS = [dt.date(2026,11,23), dt.date(2026,11,24), dt.date(2026,11,25)]

# --- tablas globales extra: más permisos y administradores de plataforma
mods = ["asesoria","dotacion","documentos"]
for m in mods:
    for a in ("ver","crear","editar","eliminar"):
        ins("permiso", modulo=m, accion=a)
OUT.append("INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p WHERE r.clave='dueno' AND p.modulo IN ('asesoria','dotacion','documentos');")
OUT.append("INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p WHERE r.clave='administrador' AND p.modulo IN ('asesoria','dotacion','documentos');")
for i in range(1, 56):
    ins("admin_plataforma", correo=f"soporte{i:02d}@citara.app", clave_hash=HASH, activo=True)

N = 55
for n in range(1, N + 1):
    NG = BASE + n
    tipo = TIPOS[n % len(TIPOS)]
    ins("negocio", id=NG, slug=f"{tipo.lower()}-{n:03d}".translate(str.maketrans("áéíóú","aeiou")), nombre=f"{tipo} {random.choice(APE)} {n:03d}",
        nit=f"9{random.randint(10000000,99999999)}-{random.randint(0,9)}", plan_id=(n % 3) + 1,
        estado="activo" if n % 17 else "suspendido", ultimo_numero_factura=0)
    ins("suscripcion", id=nid("suscripcion"), negocio_id=NG, plan_id=(n % 3) + 1, estado=random.choice(["prueba","activa","activa"]), inicio="2026-10-01")
    # sedes
    sede = nid("sede"); sede2 = nid("sede")
    ciudad = random.choice(CIUDADES)
    ins("sede", id=sede, negocio_id=NG, nombre="Sede principal", direccion=f"Cra {random.randint(1,80)} # {random.randint(1,120)}-{random.randint(1,99)}", ciudad=ciudad, telefono=f"60{random.randint(1000000,9999999)}", principal=True, activa=True)
    ins("sede", id=sede2, negocio_id=NG, nombre=f"Sede {random.choice(BARRIOS)}", direccion=f"Cll {random.randint(1,120)} # {random.randint(1,80)}-{random.randint(1,99)}", ciudad=ciudad, telefono=f"60{random.randint(1000000,9999999)}", principal=False, activa=True)
    for d in range(1, 7):
        ins("sede_horario", id=nid("sede_horario"), negocio_id=NG, sede_id=sede, dia_semana=d, apertura="09:00", cierre="19:00")
    ins("televisor", id=nid("televisor"), negocio_id=NG, sede_id=sede, nombre="TV recepción", token_hash=sha(f"tv{n}"), activo=True)
    ins("documento_negocio", id=nid("documento_negocio"), negocio_id=NG, tipo="Cámara de comercio", nombre="Cámara de comercio.pdf", archivo_url=f"/negocios/{n}/camara.pdf")
    ins("documento_negocio", id=nid("documento_negocio"), negocio_id=NG, tipo="RUT", nombre="RUT.pdf", archivo_url=f"/negocios/{n}/rut.pdf")
    # usuarios
    dueno = nid("usuario"); admin = nid("usuario")
    ins("usuario", id=dueno, negocio_id=NG, correo=f"dueno@negocio{n:03d}.co", clave_hash=HASH, rol_id=4, activo=True)
    ins("usuario", id=admin, negocio_id=NG, correo=f"admin@negocio{n:03d}.co", clave_hash=HASH, rol_id=3, activo=True)
    for u in (dueno, admin):
        ins("usuario_sede", negocio_id=NG, usuario_id=u, sede_id=sede)
    ins("usuario_sede", negocio_id=NG, usuario_id=admin, sede_id=sede2)
    # áreas, servicios, documentos requeridos, categorías
    area = [nid("area") for _ in AREAS]
    for a, nm in zip(area, AREAS): ins("area", id=a, negocio_id=NG, nombre=nm, activa=True)
    serv = []
    for nm, ai, mins, pr, ase in SERV:
        s = nid("servicio"); serv.append(s)
        ins("servicio", id=s, negocio_id=NG, area_id=area[ai], nombre=nm, descripcion=f"{nm} profesional", duracion_min=mins, precio=pr, permite_asesoria=bool(ase), activo=True)
    for s, ase in zip(serv, [x[4] for x in SERV]):
        if ase: ins("asesoria_regla", id=nid("asesoria_regla"), negocio_id=NG, servicio_id=s, motivo="Caso especial / tiempo extra", duracion_min=120)
    docreq = []
    for i, (nm, ob) in enumerate(DOCS):
        d = nid("documento_requerido"); docreq.append(d)
        ins("documento_requerido", id=d, negocio_id=NG, nombre=nm, obligatorio=bool(ob), orden=i + 1)
    cats = []
    for nm in CATG:
        c = nid("categoria_gasto"); cats.append(c); ins("categoria_gasto", id=c, negocio_id=NG, nombre=nm)
    # empleados: uno por área
    emp = []
    for ai in range(4):
        e = nid("empleado"); u = nid("usuario"); nom, f = nombre()
        ape = apellidos()
        ins("usuario", id=u, negocio_id=NG, correo=f"emp{ai+1}@negocio{n:03d}.co", clave_hash=HASH, rol_id=2, activo=True)
        ins("empleado", id=e, negocio_id=NG, usuario_id=u, sede_id=sede, tipo_documento="CC", documento=f"10{n:02d}{ai}{random.randint(10000,99999)}",
            nombres=nom, apellidos=ape, fecha_nacimiento=f"{random.randint(1985,2003)}-{random.randint(1,12):02d}-{random.randint(1,28):02d}",
            celular=f"3{random.randint(10,21)} {random.randint(100,999)} {random.randint(1000,9999)}", correo=f"{nom.lower().replace('í','i').replace('á','a').replace('é','e')}{n}@correo.com",
            direccion=f"Cra {random.randint(1,90)} # {random.randint(1,150)}-{random.randint(1,99)}", contacto_emergencia=f"{random.choice(NOM_F)} {ape.split()[0]}",
            telefono_emergencia=f"310 {random.randint(100,999)} {random.randint(1000,9999)}", fecha_ingreso=f"2026-0{random.randint(1,9)}-{random.randint(1,28):02d}",
            periodicidad_pago=random.choice(["quincenal","mensual","semanal"]), activo=True)
        ins("empleado_area", negocio_id=NG, empleado_id=e, area_id=area[ai])
        emp.append(e)
    # servicios habilitados: cada uno los de su área; la barbería también hace Corte
    habil = {0: [0,1,2], 1: [3,4,5], 2: [6,0], 3: [7]}
    for ai, e in enumerate(emp):
        for si in habil[ai]: ins("empleado_servicio", negocio_id=NG, empleado_id=e, servicio_id=serv[si])
        ins("comision", id=nid("comision"), negocio_id=NG, empleado_id=e, servicio_id=None, porcentaje=random.choice([35,40,45,50]), vigente_desde="2026-01-01")
        ins("comision", id=nid("comision"), negocio_id=NG, empleado_id=e, servicio_id=serv[habil[ai][0]], porcentaje=random.choice([50,55]), vigente_desde="2026-06-01")
        for j, dr in enumerate(docreq[:3]):
            ver = j < 2
            if ver: ins("empleado_documento", id=nid("empleado_documento"), negocio_id=NG, empleado_id=e, documento_requerido_id=dr, archivo_url=f"/emp/{e}/doc{j}.pdf", estado="verificado", verificado_por=admin, verificado_en="2026-11-10 15:00:00")
            else: ins("empleado_documento", id=nid("empleado_documento"), negocio_id=NG, empleado_id=e, documento_requerido_id=dr, archivo_url=f"/emp/{e}/doc{j}.pdf", estado="pendiente")
        for f_ in FECHAS:
            ins("turno_empleado", id=nid("turno_empleado"), negocio_id=NG, empleado_id=e, sede_id=sede, fecha=f_, inicio="09:00", fin="13:00")
            ins("turno_empleado", id=nid("turno_empleado"), negocio_id=NG, empleado_id=e, sede_id=sede, fecha=f_, inicio="15:00", fin="19:00")
        ins("bloqueo_agenda", id=nid("bloqueo_agenda"), negocio_id=NG, empleado_id=e, inicio="2026-11-23 13:00:00", fin="2026-11-23 14:00:00", motivo=random.choice(["descanso","permiso","otro"]))
        ins("invitacion", id=nid("invitacion"), negocio_id=NG, correo=f"emp{ai+1}@negocio{n:03d}.co", rol_id=2, empleado_id=e, creada_por=admin, token_hash=sha(f"inv{n}-{ai}"), expira_en="2026-12-31 00:00:00", estado="aceptada")
    # clientes
    cli = []
    for k in range(8):
        c = nid("cliente"); nom, f = nombre()
        cli.append(c)
        ins("cliente", id=c, negocio_id=NG, nombres=nom, apellidos=apellidos(), celular=f"3{random.randint(0,2)}{k} {random.randint(100,999)} {random.randint(1000,9999)}",
            correo=f"{nom.lower().replace('í','i').replace('á','a').replace('é','e')}{c}@correo.com", acepta_recordatorios=random.random() < .8,
            origen=random.choice(["enlace","whatsapp","administrador","recomendacion","instagram","local"]), activo=True, notas=random.choice([None,"Alérgica a tintes con amoníaco","Prefiere atención por la tarde",None]))
    # catálogo de inventario
    prod = {}
    for k, (nm, tp, cod, costo, pp, pe) in enumerate([
        ("Shampoo hidratante 500 ml","venta","SH-500",22000,38000,30000),("Mascarilla capilar","venta","MA-250",18000,32000,25000),
        ("Esmalte en gel","venta","EG-15",9000,18000,14000),("Tijeras de corte","dotacion","DOT-TIJ",85000,None,None),
        ("Lámpara UV","dotacion","DOT-UV",70000,None,None),("Máquina de corte","dotacion","DOT-MAQ",120000,None,None),
        ("Kit de cera y pinzas","dotacion","DOT-CER",30000,None,None),("Uniforme","dotacion","DOT-UNI",45000,None,None),
        ("Tinte","uso_interno","TIN-01",18000,None,None),("Toallas desechables","uso_interno","TOA-01",12000,None,None)]):
        p = nid("producto"); prod[cod] = p
        ins("producto", id=p, negocio_id=NG, nombre=nm, tipo=tp, codigo=cod, unidad="unidad", costo=costo, precio_publico=pp, precio_empleado=pe, stock_minimo=5, proveedor="Distribuidora Belleza")
        ins("movimiento_inventario", negocio_id=NG, producto_id=p, sede_id=sede, registrado_por=admin, tipo="compra", cantidad=20, nota="Compra inicial")
    for ai, cod in enumerate(["DOT-TIJ","DOT-UV","DOT-MAQ","DOT-CER"]):
        ins("area_dotacion", id=nid("area_dotacion"), negocio_id=NG, area_id=area[ai], producto_id=prod[cod], cantidad=1)
        ins("area_dotacion", id=nid("area_dotacion"), negocio_id=NG, area_id=area[ai], producto_id=prod["DOT-UNI"], cantidad=2)
    # entregas
    ent_dot = []
    for ai, cod in enumerate(["DOT-TIJ","DOT-UV","DOT-MAQ","DOT-CER"]):
        e_ = nid("entrega_interna"); ent_dot.append(e_)
        ins("entrega_interna", id=e_, negocio_id=NG, producto_id=prod[cod], empleado_id=emp[ai], entregada_por=admin, tipo="dotacion", fecha="2026-11-02", cantidad=1)
    ent_v1 = nid("entrega_interna"); ent_v2 = nid("entrega_interna"); ent_ui = nid("entrega_interna")
    ins("entrega_interna", id=ent_v1, negocio_id=NG, producto_id=prod["SH-500"], empleado_id=emp[0], entregada_por=admin, tipo="venta", fecha="2026-11-19", cantidad=6)
    ins("entrega_interna", id=ent_v2, negocio_id=NG, producto_id=prod["EG-15"], empleado_id=emp[1], entregada_por=admin, tipo="venta", fecha="2026-11-19", cantidad=5)
    ins("entrega_interna", id=ent_ui, negocio_id=NG, producto_id=prod["TIN-01"], empleado_id=emp[0], entregada_por=admin, tipo="uso_interno", fecha="2026-11-20", cantidad=2)
    # citas con sus servicios (agenda sin cruces)
    libre = {}
    def slot(e, f_, mins):
        t = libre.get((e, f_), 9 * 60)
        if t < 13 * 60 and t + mins > 13 * 60: t = 15 * 60
        if t < 15 * 60 and t >= 13 * 60: t = 15 * 60
        if t + mins > 19 * 60: return None
        libre[(e, f_)] = t + mins
        return t
    def hhmm(f_, t): return f"{f_} {t // 60:02d}:{t % 60:02d}:00"
    citas = []
    for k in range(6):
        c = nid("cita"); f_ = FECHAS[k % 3]; fin_ = k < 3
        ins("cita", id=c, negocio_id=NG, sede_id=sede, cliente_id=cli[k], creada_por=admin if k % 2 else None, fecha=f_,
            origen="administrador" if k % 2 else "enlace", estado="finalizada" if fin_ else random.choice(["reservada","reservada","en curso"]), notas=None)
        lines = []
        for e_idx, s_idx in random.choice([[(0,0)], [(1,3)], [(2,6),(2,0)], [(3,7)], [(0,1)], [(1,5),(0,0)]]):
            e = emp[e_idx]; mins = SERV[s_idx][2]
            t = slot(e, f_, mins)
            if t is None: continue
            cs = nid("cita_servicio"); lines.append(cs)
            ins("cita_servicio", id=cs, negocio_id=NG, cita_id=c, servicio_id=serv[s_idx], empleado_id=e, inicio=hhmm(f_, t), fin=hhmm(f_, t + mins),
                duracion_min=mins, valor=SERV[s_idx][3], estado="realizado" if fin_ else "programado")
        if not lines:   # garantiza al menos un servicio por cita
            for e_idx in range(4):
                s_idx = habil[e_idx][0]; mins = SERV[s_idx][2]; t = slot(emp[e_idx], f_, mins)
                if t is not None:
                    cs = nid("cita_servicio"); lines.append(cs)
                    ins("cita_servicio", id=cs, negocio_id=NG, cita_id=c, servicio_id=serv[s_idx], empleado_id=emp[e_idx], inicio=hhmm(f_, t), fin=hhmm(f_, t + mins), duracion_min=mins, valor=SERV[s_idx][3], estado="realizado" if fin_ else "programado")
                    break
        citas.append((c, lines))
    # ventas (de las entregas) y una de mostrador
    v1 = nid("venta_producto"); v2 = nid("venta_producto"); v3 = nid("venta_producto"); v4 = nid("venta_producto")
    ins("venta_producto", id=v1, negocio_id=NG, producto_id=prod["SH-500"], empleado_id=emp[0], entrega_id=ent_v1, cliente_id=cli[0], cita_id=citas[0][0], fecha="2026-11-23", cantidad=2, destino="cliente", precio_cobrado=38000)
    ins("venta_producto", id=v2, negocio_id=NG, producto_id=prod["SH-500"], empleado_id=emp[0], entrega_id=ent_v1, cliente_id=cli[1], cita_id=citas[1][0], fecha="2026-11-24", cantidad=1, destino="cliente", precio_cobrado=38000)
    ins("venta_producto", id=v3, negocio_id=NG, producto_id=prod["SH-500"], empleado_id=emp[0], entrega_id=ent_v1, fecha="2026-11-24", cantidad=1, destino="uso_personal", precio_cobrado=30000)
    ins("venta_producto", id=v4, negocio_id=NG, producto_id=prod["MA-250"], empleado_id=None, entrega_id=None, fecha="2026-11-25", cantidad=1, destino="mostrador", precio_cobrado=32000)
    ins("venta_producto", id=nid("venta_producto"), negocio_id=NG, producto_id=prod["EG-15"], empleado_id=emp[1], entrega_id=ent_v2, cliente_id=cli[2], cita_id=citas[2][0], fecha="2026-11-25", cantidad=2, destino="cliente", precio_cobrado=18000)
    # devoluciones: una no vendida y una pérdida de dotación que el administrador decide cobrar
    ins("devolucion_entrega", id=nid("devolucion_entrega"), negocio_id=NG, entrega_id=ent_v1, fecha="2026-11-25", cantidad=1, motivo="no vendida", se_cobra=False)
    dperd = nid("devolucion_entrega")
    ins("devolucion_entrega", id=dperd, negocio_id=NG, entrega_id=ent_dot[3], fecha="2026-11-25", cantidad=1, motivo="perdida", se_cobra=True)
    # facturas de las 3 citas finalizadas
    for c, _ in citas[:3]:
        OUT.append(f"CALL sp_emitir_factura({NG}, {c}, '{random.choice(['efectivo','tarjeta','transferencia'])}', @f);")
    # asesoría
    for k in range(2):
        ch = nid("asesoria_chat")
        ins("asesoria_chat", id=ch, negocio_id=NG, cliente_id=cli[k + 3], cita_id=citas[k + 3][0], tipo="tiempo_extra", duracion_propuesta_min=120, estado="abierto" if k else "confirmado por administrador")
        for autor, tx in [("cliente","¿Cuánto demora una decoloración completa?"),("bot","Puede tardar hasta 2 horas según el largo y el color actual."),("administrador","Confirmado: te reservamos el tiempo.")]:
            ins("asesoria_mensaje", id=nid("asesoria_mensaje"), negocio_id=NG, chat_id=ch, autor=autor, texto=tx)
    # liquidaciones (una por empleado) y gastos
    for i, e in enumerate(emp):
        L = nid("liquidacion"); com = random.randint(300, 900) * 1000; desc = random.choice([0, 30000, 60000, 85000])
        ins("liquidacion", id=L, negocio_id=NG, empleado_id=e, pagado_por=admin, periodicidad="quincenal", desde="2026-11-01", hasta="2026-11-15",
            total_comisiones=com, total_descuentos=desc, total_neto=com - desc, estado="pagado", pagado_en="2026-11-16 15:00:00")
        ins("liquidacion_detalle", id=nid("liquidacion_detalle"), negocio_id=NG, liquidacion_id=L, tipo="comision", descripcion="Comisión del periodo", base=com * 2, porcentaje=50, valor=com)
        if desc: ins("liquidacion_detalle", id=nid("liquidacion_detalle"), negocio_id=NG, liquidacion_id=L, tipo="descuento_venta", descripcion="Productos vendidos a precio de empleado", valor=desc)
        else: ins("liquidacion_detalle", id=nid("liquidacion_detalle"), negocio_id=NG, liquidacion_id=L, tipo="comision", descripcion="Bono de servicios", base=0, porcentaje=0, valor=0)
    L = nid("liquidacion")
    ins("liquidacion", id=L, negocio_id=NG, empleado_id=emp[3], pagado_por=None, periodicidad="quincenal", desde="2026-11-16", hasta="2026-11-30", total_comisiones=400000, total_descuentos=30000, total_neto=370000, estado="pendiente")
    ins("liquidacion_detalle", id=nid("liquidacion_detalle"), negocio_id=NG, liquidacion_id=L, tipo="comision", descripcion="Comisión del periodo", base=800000, porcentaje=50, valor=400000)
    ins("liquidacion_detalle", id=nid("liquidacion_detalle"), negocio_id=NG, liquidacion_id=L, devolucion_id=dperd, tipo="descuento_dotacion", descripcion="Pieza de dotación perdida", valor=30000)
    for k in range(4):
        ins("gasto", id=nid("gasto"), negocio_id=NG, sede_id=sede, categoria_id=cats[k], registrado_por=admin, concepto=f"{CATG[k]} noviembre", valor=random.randint(2, 40) * 50000, fecha=f"2026-11-{random.randint(1,25):02d}")
    for k, (ent, acc) in enumerate([("cita","crear"),("empleado","editar"),("factura","crear")]):
        ins("auditoria", negocio_id=NG, usuario_id=admin, entidad=ent, entidad_id=BASE + k, accion=acc, antes=None, despues='{"estado": "ok"}')
OUT += ["COMMIT;", "SET autocommit = 1;"]
open("09_datos_masivos.sql", "w").write("\n".join(OUT) + "\n")
print(len(OUT), "sentencias")
