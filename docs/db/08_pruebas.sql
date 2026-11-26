-- =====================================================================
-- CITARA · 08 · Pruebas. Cada línea "PRUEBA" debe terminar en OK.
-- Se ejecuta con: mysql -uroot --force < 08_pruebas.sql
-- (--force sigue después de cada error esperado.) Después de cada prueba
-- que "debe fallar" se imprime el mensaje de error de MySQL.
-- =====================================================================
SET NAMES utf8mb4;
USE citara;
SET @n1 := (SELECT id FROM negocio WHERE slug='salon-demo');
SET @n2 := (SELECT id FROM negocio WHERE slug='barberia-norte');

-- ---------- Aislamiento entre negocios (como lo vería la app) ----------
CALL citara_app.sp_limpiar_negocio();
SELECT 'PRUEBA sin tenant fijado no ve nada' AS prueba,
       IF((SELECT COUNT(*) FROM citara_app.cliente)=0 AND (SELECT COUNT(*) FROM citara_app.cita)=0,'OK','FALLA') AS resultado;

CALL citara_app.sp_set_negocio(@n1);
SELECT 'PRUEBA negocio 1 solo ve sus clientes' AS prueba,
       IF((SELECT COUNT(*) FROM citara_app.cliente)=2 AND (SELECT COUNT(*) FROM citara_app.cliente WHERE nombres='Pedro')=0,'OK','FALLA') AS resultado;

CALL citara_app.sp_set_negocio(@n2);
SELECT 'PRUEBA negocio 2 solo ve su cliente' AS prueba,
       IF((SELECT COUNT(*) FROM citara_app.cliente)=1 AND (SELECT COUNT(*) FROM citara_app.empleado)=0,'OK','FALLA') AS resultado;
SELECT 'PRUEBA negocio 2 no ve el negocio 1' AS prueba,
       IF((SELECT COUNT(*) FROM citara_app.negocio)=1 AND (SELECT slug FROM citara_app.negocio)='barberia-norte','OK','FALLA') AS resultado;

-- Negocio 2 intenta escribir en el negocio 1 (debe fallar: WITH CHECK OPTION)
SELECT 'DEBE FALLAR insertar un cliente en otro negocio' AS prueba;
INSERT INTO citara_app.cliente (negocio_id,nombres,apellidos,celular) VALUES (@n1,'Intruso','X','999');
-- Negocio 2 intenta editar y borrar filas del negocio 1 (0 filas afectadas)
UPDATE citara_app.cliente SET nombres='Hackeado' WHERE nombres='Ana';
SELECT 'PRUEBA no puede editar filas de otro negocio' AS prueba,
       IF((SELECT nombres FROM citara.cliente WHERE negocio_id=@n1 AND apellidos='Martínez')='Ana','OK','FALLA') AS resultado;
DELETE FROM citara_app.cliente WHERE negocio_id=@n1;
SELECT 'PRUEBA no puede borrar filas de otro negocio' AS prueba,
       IF((SELECT COUNT(*) FROM citara.cliente WHERE negocio_id=@n1)=2,'OK','FALLA') AS resultado;

-- Claves foráneas compuestas: aun con acceso total, no se mezclan negocios
SELECT 'DEBE FALLAR una cita del negocio 2 con un cliente del negocio 1' AS prueba;
INSERT INTO citara.cita (negocio_id,sede_id,cliente_id,fecha)
  VALUES (@n2,(SELECT id FROM sede WHERE negocio_id=@n2 LIMIT 1),(SELECT id FROM cliente WHERE negocio_id=@n1 LIMIT 1),'2026-11-23');

-- Único por negocio, no global
SELECT 'PRUEBA el mismo celular puede existir en dos negocios' AS prueba,
       IF((SELECT COUNT(*) FROM citara.cliente WHERE celular='312 345 6789')=2,'OK','FALLA') AS resultado;
SELECT 'DEBE FALLAR celular repetido dentro del mismo negocio' AS prueba;
INSERT INTO citara.cliente (negocio_id,nombres,apellidos,celular) VALUES (@n1,'Otra','Ana','312 345 6789');

-- ---------- Reglas de agenda ----------
CALL citara_app.sp_set_negocio(@n1);
SET @laura := (SELECT id FROM citara.empleado WHERE negocio_id=@n1 AND nombres='Laura');
SET @cita  := (SELECT id FROM citara.cita WHERE negocio_id=@n1 LIMIT 1);
SET @corte := (SELECT id FROM citara.servicio WHERE negocio_id=@n1 AND nombre='Corte');
SET @color := (SELECT id FROM citara.servicio WHERE negocio_id=@n1 AND nombre='Color');

SELECT 'DEBE FALLAR dos turnos del mismo empleado que se cruzan' AS prueba;
INSERT INTO citara_app.turno_empleado (negocio_id,empleado_id,sede_id,fecha,inicio,fin)
  VALUES (@n1,@laura,(SELECT id FROM citara.sede WHERE negocio_id=@n1 LIMIT 1),'2026-11-23','12:00','16:00');
SELECT 'PRUEBA dos turnos el mismo día sin cruzarse (09-13 y 15-19) existen' AS prueba,
       IF((SELECT COUNT(*) FROM citara_app.turno_empleado WHERE empleado_id=@laura AND fecha='2026-11-23')=2,'OK','FALLA') AS resultado;

SELECT 'DEBE FALLAR cita que se cruza con otra del mismo empleado' AS prueba;
INSERT INTO citara_app.cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  VALUES (@n1,@cita,@corte,@laura,'2026-11-23 10:15','2026-11-23 10:45',30,35000);
SELECT 'DEBE FALLAR cita fuera del turno (13:00-15:00 es el descanso de Laura)' AS prueba;
INSERT INTO citara_app.cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  VALUES (@n1,@cita,@corte,@laura,'2026-11-23 13:30','2026-11-23 14:00',30,35000);
SELECT 'DEBE FALLAR servicio que el empleado no tiene habilitado (Laura no hace Barba)' AS prueba;
INSERT INTO citara_app.cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  VALUES (@n1,@cita,(SELECT id FROM citara.servicio WHERE negocio_id=@n1 AND nombre='Barba'),@laura,'2026-11-23 16:00','2026-11-23 16:30',30,20000);
SELECT 'PRUEBA cita válida en el segundo turno' AS prueba;
INSERT INTO citara_app.cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  VALUES (@n1,@cita,@corte,@laura,'2026-11-23 16:00','2026-11-23 16:30',30,35000);
SELECT IF((SELECT COUNT(*) FROM citara_app.cita_servicio WHERE empleado_id=@laura)=2,'OK','FALLA') AS resultado;

-- Bloqueo de agenda
INSERT INTO citara_app.bloqueo_agenda (negocio_id,empleado_id,inicio,fin,motivo) VALUES (@n1,@laura,'2026-11-23 17:00','2026-11-23 18:00','permiso');
SELECT 'DEBE FALLAR cita sobre un bloqueo de agenda' AS prueba;
INSERT INTO citara_app.cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  VALUES (@n1,@cita,@corte,@laura,'2026-11-23 17:00','2026-11-23 17:30',30,35000);

-- ---------- Reglas de inventario ----------
SET @shampoo := (SELECT id FROM citara.producto WHERE negocio_id=@n1 AND codigo='SH-500');
SET @sede := (SELECT id FROM citara.sede WHERE negocio_id=@n1 LIMIT 1);
SELECT 'DEBE FALLAR sacar más de lo que hay en bodega' AS prueba;
INSERT INTO citara_app.movimiento_inventario (negocio_id,producto_id,sede_id,tipo,cantidad) VALUES (@n1,@shampoo,@sede,'baja',-50);
SELECT 'DEBE FALLAR editar un movimiento de inventario' AS prueba;
UPDATE citara_app.movimiento_inventario SET cantidad=-1 WHERE id=1;
SELECT 'DEBE FALLAR vender más de lo que el empleado tiene' AS prueba;
INSERT INTO citara_app.venta_producto (negocio_id,producto_id,empleado_id,entrega_id,fecha,cantidad,destino,precio_cobrado)
  VALUES (@n1,@shampoo,@laura,2,'2026-11-26',1,'cliente',38000);
SELECT 'DEBE FALLAR un producto de venta sin precios' AS prueba;
INSERT INTO citara_app.producto (negocio_id,nombre,tipo) VALUES (@n1,'Sin precio','venta');
SELECT 'DEBE FALLAR precio de empleado mayor al público' AS prueba;
INSERT INTO citara_app.producto (negocio_id,nombre,tipo,precio_publico,precio_empleado) VALUES (@n1,'Caro','venta',10000,20000);

-- ---------- Facturas ----------
SELECT 'PRUEBA el consecutivo de facturas es por negocio' AS prueba,
       IF((SELECT numero FROM citara.factura WHERE negocio_id=@n1)=1 AND (SELECT ultimo_numero_factura FROM citara.negocio WHERE id=@n2)=0,'OK','FALLA') AS resultado;
SELECT 'DEBE FALLAR facturar dos veces la misma cita' AS prueba;
CALL citara_app.sp_emitir_factura(@cita, 'efectivo', @x);

-- ---------- Documentos ----------
SELECT 'PRUEBA expediente de Camila: 2 verificados, 1 por verificar, 2 faltan' AS prueba,
       IF((SELECT SUM(estado='Verificado') FROM citara_app.v_expediente_documentos WHERE empleado_id=(SELECT id FROM citara.empleado WHERE nombres='Camila'))=2
      AND (SELECT SUM(estado='Falta subir') FROM citara_app.v_expediente_documentos WHERE empleado_id=(SELECT id FROM citara.empleado WHERE nombres='Camila'))=2,'OK','FALLA') AS resultado;
CALL citara_app.sp_limpiar_negocio();
