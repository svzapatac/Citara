-- =====================================================================
-- CITARA · 07 · Datos de demostración (solo para desarrollo y pruebas)
-- Dos negocios independientes para comprobar el aislamiento.
-- =====================================================================
SET NAMES utf8mb4;
USE citara;
SET @plan := (SELECT id FROM plan WHERE nombre = 'Profesional');
CALL sp_crear_negocio('salon-demo',      'Salón Demo',      @plan, 'dueno@salondemo.co',  '$2b$12$hashdemo', @n1);
CALL sp_crear_negocio('barberia-norte',  'Barbería Norte',  @plan, 'dueno@barberianorte.co','$2b$12$hashdemo', @n2);

SET @sede1 := (SELECT id FROM sede WHERE negocio_id=@n1 AND principal=1);
SET @sede2 := (SELECT id FROM sede WHERE negocio_id=@n2 AND principal=1);
SET @dueno1 := (SELECT id FROM usuario WHERE negocio_id=@n1);
SET @a_cab := (SELECT id FROM area WHERE negocio_id=@n1 AND nombre='Cabello');
SET @a_uni := (SELECT id FROM area WHERE negocio_id=@n1 AND nombre='Uñas');
SET @a_bar := (SELECT id FROM area WHERE negocio_id=@n1 AND nombre='Barbería');

-- Equipo del negocio 1
INSERT INTO empleado (negocio_id, sede_id, documento, nombres, apellidos, celular, fecha_ingreso, periodicidad_pago) VALUES
  (@n1,@sede1,'1030456789','Laura','Gómez','311 111 1111','2026-02-03','quincenal'),
  (@n1,@sede1,'1020345678','Camila','Ruiz','311 222 3344','2026-02-03','quincenal'),
  (@n1,@sede1,'1010222333','Andrés','Pardo','311 333 4455','2026-03-01','mensual');
SET @laura  := (SELECT id FROM empleado WHERE negocio_id=@n1 AND nombres='Laura');
SET @camila := (SELECT id FROM empleado WHERE negocio_id=@n1 AND nombres='Camila');
SET @andres := (SELECT id FROM empleado WHERE negocio_id=@n1 AND nombres='Andrés');
INSERT INTO empleado_area VALUES (@n1,@laura,@a_cab),(@n1,@camila,@a_uni),(@n1,@andres,@a_bar);
INSERT INTO empleado_servicio (negocio_id, empleado_id, servicio_id)
  SELECT @n1,@laura,id  FROM servicio WHERE negocio_id=@n1 AND nombre IN ('Corte','Color','Peinado');
INSERT INTO empleado_servicio (negocio_id, empleado_id, servicio_id)
  SELECT @n1,@camila,id FROM servicio WHERE negocio_id=@n1 AND nombre IN ('Tradicional','Acrílicas','Semipermanentes');
INSERT INTO empleado_servicio (negocio_id, empleado_id, servicio_id)
  SELECT @n1,@andres,id FROM servicio WHERE negocio_id=@n1 AND nombre IN ('Corte','Barba','Cejas');
INSERT INTO comision (negocio_id, empleado_id, porcentaje, vigente_desde) VALUES
  (@n1,@laura,40,'2026-02-03'),(@n1,@camila,45,'2026-02-03'),(@n1,@andres,40,'2026-03-01');

-- Documentos del expediente de Camila (4 de 5, sin vencimiento)
SET @doc_id  := (SELECT id FROM documento_requerido WHERE negocio_id=@n1 AND nombre='Documento de identidad');
SET @doc_eps := (SELECT id FROM documento_requerido WHERE negocio_id=@n1 AND nombre='Afiliación a salud (EPS)');
SET @doc_bio := (SELECT id FROM documento_requerido WHERE negocio_id=@n1 AND nombre='Certificado de bioseguridad');
INSERT INTO empleado_documento (negocio_id, empleado_id, documento_requerido_id, archivo_url, estado, verificado_por, verificado_en) VALUES
  (@n1,@camila,@doc_id,'/docs/camila/cedula.pdf','verificado',@dueno1,NOW()),
  (@n1,@camila,@doc_eps,'/docs/camila/eps.pdf','verificado',@dueno1,NOW());
INSERT INTO empleado_documento (negocio_id, empleado_id, documento_requerido_id, archivo_url) VALUES
  (@n1,@camila,@doc_bio,'/docs/camila/bioseguridad.pdf');

-- Turnos del lunes 23 nov 2026: Laura tiene dos turnos el mismo día
INSERT INTO turno_empleado (negocio_id, empleado_id, sede_id, fecha, inicio, fin) VALUES
  (@n1,@laura ,@sede1,'2026-11-23','09:00','13:00'),
  (@n1,@laura ,@sede1,'2026-11-23','15:00','19:00'),
  (@n1,@camila,@sede1,'2026-11-23','09:00','18:00'),
  (@n1,@andres,@sede1,'2026-11-23','09:00','18:00');

-- Clientes
INSERT INTO cliente (negocio_id, nombres, apellidos, celular, origen) VALUES
  (@n1,'Ana','Martínez','312 345 6789','recomendacion'),
  (@n1,'Marta','León','300 111 2222','enlace');
SET @ana := (SELECT id FROM cliente WHERE negocio_id=@n1 AND nombres='Ana');

-- Una cita con DOS servicios de personas distintas (corte + uñas)
INSERT INTO cita (negocio_id, sede_id, cliente_id, creada_por, fecha) VALUES (@n1,@sede1,@ana,@dueno1,'2026-11-23');
SET @cita1 := LAST_INSERT_ID();
INSERT INTO cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  SELECT @n1,@cita1,id,@laura,'2026-11-23 10:00','2026-11-23 10:30',30,precio FROM servicio WHERE negocio_id=@n1 AND nombre='Corte';
INSERT INTO cita_servicio (negocio_id,cita_id,servicio_id,empleado_id,inicio,fin,duracion_min,valor)
  SELECT @n1,@cita1,id,@camila,'2026-11-23 10:30','2026-11-23 11:15',45,precio FROM servicio WHERE negocio_id=@n1 AND nombre='Semipermanentes';

-- Productos e inventario
INSERT INTO producto (negocio_id,nombre,tipo,codigo,costo,precio_publico,precio_empleado,proveedor) VALUES
  (@n1,'Shampoo hidratante 500 ml','venta','SH-500',22000,38000,30000,'Distribuidora Belleza');
INSERT INTO producto (negocio_id,nombre,tipo,codigo,costo) VALUES
  (@n1,'Tijeras de corte','dotacion','DOT-001',85000),
  (@n1,'Tinte','uso_interno','TIN-01',18000);
SET @shampoo := (SELECT id FROM producto WHERE negocio_id=@n1 AND codigo='SH-500');
SET @tijeras := (SELECT id FROM producto WHERE negocio_id=@n1 AND codigo='DOT-001');
INSERT INTO area_dotacion (negocio_id,area_id,producto_id,cantidad) VALUES (@n1,@a_cab,@tijeras,1);
INSERT INTO movimiento_inventario (negocio_id,producto_id,sede_id,tipo,cantidad,nota) VALUES
  (@n1,@shampoo,@sede1,'compra',12,'compra inicial'),
  (@n1,@tijeras,@sede1,'compra',4,'compra inicial');
-- Dotación de Laura (no se cobra) y 4 shampoo para vender (precio de empleado)
INSERT INTO entrega_interna (negocio_id,producto_id,empleado_id,entregada_por,tipo,fecha,cantidad)
  VALUES (@n1,@tijeras,@laura,@dueno1,'dotacion','2026-11-01',1);
INSERT INTO entrega_interna (negocio_id,producto_id,empleado_id,entregada_por,tipo,fecha,cantidad)
  VALUES (@n1,@shampoo,@laura,@dueno1,'venta','2026-11-19',4);
SET @entrega_sh := LAST_INSERT_ID();
-- Laura vende 2 a clientes, se lleva 1 para ella y devuelve 1 sin vender
INSERT INTO venta_producto (negocio_id,producto_id,empleado_id,entrega_id,cliente_id,cita_id,fecha,cantidad,destino,precio_cobrado)
  VALUES (@n1,@shampoo,@laura,@entrega_sh,@ana,@cita1,'2026-11-23',2,'cliente',38000);
INSERT INTO venta_producto (negocio_id,producto_id,empleado_id,entrega_id,fecha,cantidad,destino,precio_cobrado)
  VALUES (@n1,@shampoo,@laura,@entrega_sh,'2026-11-24',1,'uso_personal',30000);
INSERT INTO devolucion_entrega (negocio_id,entrega_id,fecha,cantidad,motivo)
  VALUES (@n1,@entrega_sh,'2026-11-25',1,'no vendida');

-- Se realizan los servicios y se factura (consecutivo 1 del negocio)
UPDATE cita_servicio SET estado='realizado' WHERE negocio_id=@n1 AND cita_id=@cita1;
CALL sp_emitir_factura(@n1, @cita1, 'efectivo', @f1);

-- Gasto
INSERT INTO gasto (negocio_id,sede_id,categoria_id,concepto,valor,fecha)
  SELECT @n1,@sede1,id,'Arriendo noviembre',2500000,'2026-11-01' FROM categoria_gasto WHERE negocio_id=@n1 AND nombre='Arriendo';

-- Negocio 2: un cliente con el MISMO celular que uno del negocio 1 (permitido: único por negocio)
INSERT INTO cliente (negocio_id, nombres, apellidos, celular) VALUES (@n2,'Pedro','Suárez','312 345 6789');
