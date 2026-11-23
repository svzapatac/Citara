import re,subprocess,sys,html,os
HERE=os.path.dirname(os.path.abspath(__file__))  # genera las imágenes con Graphviz: python3 generar.py
src=open(os.path.join(HERE,'modelo-er.mmd')).read()
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
        mm=re.match(r'(\w+) (\w+)(?: (PK|FK))?(?: "(.*)")?$',ln)
        rows.append(mm.groups() if mm else (ln,'','',''))
    ents[m.group(1)]=rows
MOD={'NEGOCIO':0,'SEDE':0,'SEDE_HORARIO':0,'DOCUMENTO_NEGOCIO':0,'TELEVISOR':0,'USUARIO':0,'CLIENTE':0,
'EMPLEADO':1,'DOCUMENTO_REQUERIDO':1,'EMPLEADO_DOCUMENTO':1,'AREA':1,'EMPLEADO_AREA':1,'SERVICIO':1,'EMPLEADO_SERVICIO':1,'TURNO_EMPLEADO':1,'COMISION_CONFIG':1,'ASESORIA_REGLA':1,
'CITA':2,'CITA_SERVICIO':2,'FACTURA':2,'ASESORIA_CHAT':2,'ASESORIA_MENSAJE':2,
'LIQUIDACION':3,'LIQUIDACION_DETALLE':3,
'PRODUCTO':4,'AREA_DOTACION':4,'ENTREGA_INTERNA':4,'VENTA_PRODUCTO':4,'GASTO':4}
MN=['Negocio, sedes y accesos','Equipo, áreas y servicios','Reservas, asesoría y facturas','Comisiones y pagos','Inventario, dotación y gastos']
HC=['#031641','#0033DD','#2E3F6B','#1E5AA8','#4A5A82']
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
        for i in range(5):
            mem=[e for e in used if MOD[e]==i]
            if not mem: continue
            o.append(f'subgraph cluster{i} {{ label=<<font point-size="14" color="{HC[i]}"><b>{MN[i]}</b></font>>; style="rounded,filled"; fillcolor="#F5F7FA"; color="#DCE0E6"; '+' '.join(f'{e};' for e in mem)+'}')
    for e in used: o.append(f'{e} [label={table(e, full and e in focal)}];')
    for a,s1,s2,b,lab in rl:
        o.append(f'{a} -> {b} [arrowtail={arrow(s1,True)},arrowhead={arrow(s2,False)},label="  {lab}  "];')
    o.append('}')
    open(os.path.join(HERE,name+'.dot'),'w').write('\n'.join(o))
    subprocess.run(['dot','-Tpng','-Gdpi=100',os.path.join(HERE,name+'.dot'),'-o',os.path.join(HERE,name+'.png')],check=True)
    subprocess.run(['dot','-Tsvg',os.path.join(HERE,name+'.dot'),'-o',os.path.join(HERE,name+'.svg')],check=True)
allents=list(ents)
build('00-modelo-er-completo',set(allents),'Modelo entidad-relación de Citara',full=True)
G=[('01-negocio-sedes-accesos',['NEGOCIO','SEDE','SEDE_HORARIO','DOCUMENTO_NEGOCIO','TELEVISOR','USUARIO','CLIENTE'],'Negocio, sedes y accesos'),
('02-equipo-y-documentos',['EMPLEADO','DOCUMENTO_REQUERIDO','EMPLEADO_DOCUMENTO','EMPLEADO_AREA','TURNO_EMPLEADO','COMISION_CONFIG'],'Equipo: documentos, turnos y comisión'),
('02b-areas-y-servicios',['AREA','SERVICIO','EMPLEADO_SERVICIO','EMPLEADO_AREA','ASESORIA_REGLA'],'Áreas, servicios y quién los presta'),
('03-reservas-y-facturas',['CLIENTE','CITA','CITA_SERVICIO','FACTURA','ASESORIA_CHAT','ASESORIA_MENSAJE'],'Reservas, asesoría y facturas'),
('04-comisiones-y-pagos',['LIQUIDACION','LIQUIDACION_DETALLE','VENTA_PRODUCTO','ENTREGA_INTERNA'],'Comisiones y pagos'),
('05-inventario-dotacion-gastos',['PRODUCTO','AREA_DOTACION','ENTREGA_INTERNA','VENTA_PRODUCTO','GASTO'],'Inventario, dotación, ventas y gastos')]
for n,f,t in G: build(n,set(f),t)
