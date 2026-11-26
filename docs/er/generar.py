import re,subprocess,sys,html,os
HERE=os.path.dirname(os.path.abspath(__file__))  # genera las imágenes con Graphviz: python3 generar.py
src=open(os.path.join(HERE,'modelo-er.mmd')).read()
src='\n'.join(l for l in src.split('\n') if not l.strip().startswith('%%'))
rels=[]
for l in src.split('\n'):
    m=re.match(r'\s{4}(\w+) (\S+)--(\S+) (\w+) : (.+)',l)
    if m: rels.append(m.groups())
ents={}
for m in re.finditer(r'^    (\w+) \{ ?(.*?) ?\}$',src,re.M|re.S):
    rows=[]
    for ln in m.group(2).split('\n'):
        ln=ln.strip()
        if not ln: continue
        mm=re.match(r'(\w+) (\w+)(?: ([A-Z,]+))?(?: "(.*)")?$',ln)
        rows.append(mm.groups() if mm else (ln,'','',''))
    ents[m.group(1)]=rows
MODS=[('Plataforma (global)',['PLAN','NEGOCIO','SUSCRIPCION','ROL','PERMISO','ROL_PERMISO','ADMIN_PLATAFORMA'],'#5B6676'),
('Accesos y auditoría',['USUARIO','USUARIO_SEDE','INVITACION','AUDITORIA'],'#031641'),
('Organización',['SEDE','SEDE_HORARIO','TELEVISOR','DOCUMENTO_NEGOCIO'],'#2E3F6B'),
('Equipo',['EMPLEADO','EMPLEADO_AREA','DOCUMENTO_REQUERIDO','EMPLEADO_DOCUMENTO','TURNO_EMPLEADO','BLOQUEO_AGENDA','COMISION'],'#0033DD'),
('Catálogo',['AREA','SERVICIO','EMPLEADO_SERVICIO','ASESORIA_REGLA'],'#1E5AA8'),
('Clientes, reservas y facturas',['CLIENTE','CITA','CITA_SERVICIO','ASESORIA_CHAT','ASESORIA_MENSAJE','FACTURA','FACTURA_LINEA'],'#3A4F8F'),
('Inventario',['PRODUCTO','MOVIMIENTO_INVENTARIO','AREA_DOTACION','ENTREGA_INTERNA','DEVOLUCION_ENTREGA','VENTA_PRODUCTO'],'#4A5A82'),
('Pagos y finanzas',['LIQUIDACION','LIQUIDACION_DETALLE','CATEGORIA_GASTO','GASTO'],'#0B5C7A')]
MOD={e:i for i,(n,es,c) in enumerate(MODS) for e in es}
MN=[m[0] for m in MODS]; HC=[m[2] for m in MODS]
def arrow(sym,left):
    # sym like '||','|o','o|','o{','|{'
    s=sym
    if left: s=s[::-1].replace('{','}')  # mirror
    # normalize: we want description at the entity end
    one='|' in s and ('{' not in s and '}' not in s)
    many=('{' in s or '}' in s)
    zero='o' in s
    if many: return 'crowodot' if zero else 'crowtee'
    return 'teeodot' if zero else 'teetee'
def table(n,full):
    h=HC[MOD[n]]
    if not full or not ents.get(n):
        return f'<<table border="1" cellborder="0" cellspacing="0" cellpadding="6" color="#8A93A3" bgcolor="white"><tr><td bgcolor="{h}"><font color="white" face="Helvetica-Bold" point-size="15">{n}</font></td></tr></table>>'
    rows=''
    for t,a,k,c in ents[n]:
        kk=f'<b>{k}</b>' if k else ''
        cc=f' <font color="#5B6676" point-size="10">  {html.escape(c)}</font>' if c else ''
        bg='#E8EEFC' if k=='PK' else ('#F3F6FD' if k=='FK' else 'white')
        rows+=f'<tr><td align="left" bgcolor="{bg}" port="{a}"><font point-size="12" color="#5B6676">{t}</font></td><td align="left" bgcolor="{bg}"><font point-size="13">{a}</font>{cc}</td><td bgcolor="{bg}"><font point-size="11" color="#0033DD">{kk or "&nbsp;&nbsp;"}</font></td></tr>'
    return f'<<table border="1" cellborder="0" cellspacing="0" cellpadding="4" color="#8A93A3" bgcolor="white"><tr><td colspan="3" bgcolor="{h}"><font color="white" face="Helvetica-Bold" point-size="15">{n}</font></td></tr>{rows}</table>>'
def build(name,focal,title,clusters=True,full=True,rankdir='TB',extra=None):
    rl=[r for r in rels if r[0] in focal or r[3] in focal]
    used=set()
    for r in rl: used|={r[0],r[3]}
    used|=set(focal)
    o=[f'digraph G {{ graph [rankdir={rankdir},splines=true,nodesep=0.7,ranksep=1.1,pad=0.4,fontname="Helvetica",label=<<font point-size="26"><b>{title}</b></font>>,labelloc=t,bgcolor=white]; node [shape=plain,fontname="Helvetica"]; edge [fontname="Helvetica",fontsize=11,fontcolor="#3A4556",color="#5B6676",dir=both,penwidth=1.3];']
    if clusters:
        for i in range(len(MODS)):
            mem=[e for e in used if MOD[e]==i]
            if not mem: continue
            o.append(f'subgraph cluster{i} {{ label=<<font point-size="14" color="{HC[i]}"><b>{MN[i]}</b></font>>; style="rounded,filled"; fillcolor="#F5F7FA"; color="#DCE0E6"; '+' '.join(f'{e};' for e in mem)+'}')
    for e in used: o.append(f'{e} [label={table(e, full and e in focal)}];')
    for a,s1,s2,b,lab in rl:
        o.append(f'{a} -> {b} [arrowtail={arrow(s1,True)},arrowhead={arrow(s2,False)},label="  {lab.strip(chr(34))}  "];')
    o.append('}')
    open(os.path.join(HERE,name+'.dot'),'w').write('\n'.join(o))
    subprocess.run(['dot','-Tpng','-Gdpi=100',os.path.join(HERE,name+'.dot'),'-o',os.path.join(HERE,name+'.png')],check=True)
    subprocess.run(['dot','-Tsvg',os.path.join(HERE,name+'.dot'),'-o',os.path.join(HERE,name+'.svg')],check=True)
allents=list(ents)
build('00-modelo-er-completo',set(allents),'Modelo entidad-relación de Citara (multi-tenant)',full=True)
build('00b-mapa-de-relaciones',set(allents),'Mapa de relaciones (solo tablas)',full=False)
for i,(n,es,c) in enumerate(MODS):
    build(f'{i+1:02d}-'+re.sub(r'[^a-z]+','-',n.lower().replace('í','i').replace('ó','o').replace('á','a').replace('é','e')).strip('-'),set(es),n)
