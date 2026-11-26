-- Citara · tablas y datos base para hosting compartido (usa la base de datos que ya tienes seleccionada)
SET NAMES utf8mb4;
-- =====================================================================
-- CITARA · Base de datos multi-tenant (pool) · MySQL 8.0.16 o superior
-- 01 · Esquema: tablas, claves, restricciones e índices
--
-- Convenciones
--   * Todas las tablas del cliente llevan negocio_id NOT NULL (el tenant).
--   * Cada tabla del cliente tiene UNIQUE (negocio_id, id) y las claves
--     foráneas entre ellas son COMPUESTAS (negocio_id, x_id): así un
--     registro de un negocio NUNCA puede apuntar a uno de otro negocio.
--   * Los textos únicos lo son DENTRO de cada negocio.
--   * Fechas de citas y turnos: hora local del negocio (DATETIME).
--     Fechas de auditoría y registros del sistema: UTC (DATETIME).
--   * Enumeraciones: columnas VARCHAR con CHECK.
-- =====================================================================
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================================
-- 1. PLATAFORMA (tablas globales, sin negocio_id)
-- =====================================================================
CREATE TABLE plan (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(60)  NOT NULL,
  max_sedes       INT          NOT NULL,
  max_empleados   INT          NOT NULL,
  precio_mensual  DECIMAL(12,2) NOT NULL,
  activo          TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_plan_nombre (nombre),
  CONSTRAINT ck_plan_limites CHECK (max_sedes > 0 AND max_empleados > 0 AND precio_mensual >= 0)
) ENGINE=InnoDB;

CREATE TABLE rol (
  id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  clave   VARCHAR(30) NOT NULL,
  nombre  VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_rol_clave (clave),
  CONSTRAINT ck_rol_clave CHECK (clave IN ('cliente','empleado','administrador','dueno'))
) ENGINE=InnoDB;

CREATE TABLE permiso (
  id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  modulo  VARCHAR(40) NOT NULL,
  accion  VARCHAR(20) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_permiso (modulo, accion),
  CONSTRAINT ck_permiso_accion CHECK (accion IN ('ver','crear','editar','eliminar'))
) ENGINE=InnoDB;

CREATE TABLE rol_permiso (
  rol_id      BIGINT UNSIGNED NOT NULL,
  permiso_id  BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (rol_id, permiso_id),
  CONSTRAINT fk_rolperm_rol     FOREIGN KEY (rol_id)     REFERENCES rol (id),
  CONSTRAINT fk_rolperm_permiso FOREIGN KEY (permiso_id) REFERENCES permiso (id)
) ENGINE=InnoDB;

CREATE TABLE admin_plataforma (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  correo      VARCHAR(160) NOT NULL,
  clave_hash  VARCHAR(255) NOT NULL,
  activo      TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_admin_plataforma_correo (correo)
) ENGINE=InnoDB;

-- El negocio ES el tenant: su id es el negocio_id de todo el sistema.
CREATE TABLE negocio (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug                  VARCHAR(60)  NOT NULL COMMENT 'enlace público y acceso: citara.app/<slug>',
  nombre                VARCHAR(120) NOT NULL,
  nit                   VARCHAR(30)  NULL,
  plan_id               BIGINT UNSIGNED NOT NULL,
  estado                VARCHAR(15)  NOT NULL DEFAULT 'activo',
  zona_horaria          VARCHAR(50)  NOT NULL DEFAULT 'America/Bogota',
  moneda                CHAR(3)      NOT NULL DEFAULT 'COP',
  ultimo_numero_factura INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'consecutivo de facturas del negocio',
  creado_en             DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_negocio_slug (slug),
  KEY ix_negocio_plan (plan_id),
  CONSTRAINT fk_negocio_plan FOREIGN KEY (plan_id) REFERENCES plan (id),
  CONSTRAINT ck_negocio_estado CHECK (estado IN ('activo','suspendido','cancelado')),
  CONSTRAINT ck_negocio_slug CHECK (slug REGEXP '^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$')
) ENGINE=InnoDB;

CREATE TABLE suscripcion (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  plan_id     BIGINT UNSIGNED NOT NULL,
  estado      VARCHAR(15) NOT NULL DEFAULT 'prueba',
  inicio      DATE NOT NULL,
  fin         DATE NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_suscripcion_negocio_id (negocio_id, id),
  KEY ix_suscripcion_plan (plan_id),
  CONSTRAINT fk_suscripcion_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id),
  CONSTRAINT fk_suscripcion_plan    FOREIGN KEY (plan_id)    REFERENCES plan (id),
  CONSTRAINT ck_suscripcion_estado CHECK (estado IN ('prueba','activa','vencida','cancelada')),
  CONSTRAINT ck_suscripcion_fechas CHECK (fin IS NULL OR fin >= inicio)
) ENGINE=InnoDB;

-- =====================================================================
-- 2. ACCESOS Y AUDITORÍA
-- =====================================================================
CREATE TABLE usuario (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id     BIGINT UNSIGNED NOT NULL,
  correo         VARCHAR(160) NOT NULL,
  clave_hash     VARCHAR(255) NOT NULL,
  rol_id         BIGINT UNSIGNED NOT NULL,
  activo         TINYINT(1) NOT NULL DEFAULT 1,
  ultimo_acceso  DATETIME NULL COMMENT 'UTC',
  PRIMARY KEY (id),
  UNIQUE KEY uk_usuario_negocio_id (negocio_id, id),
  UNIQUE KEY uk_usuario_correo (negocio_id, correo),
  KEY ix_usuario_rol (rol_id),
  CONSTRAINT fk_usuario_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id),
  CONSTRAINT fk_usuario_rol     FOREIGN KEY (rol_id)     REFERENCES rol (id)
) ENGINE=InnoDB;

CREATE TABLE sede (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  nombre      VARCHAR(100) NOT NULL,
  direccion   VARCHAR(200) NULL,
  ciudad      VARCHAR(80)  NULL,
  telefono    VARCHAR(30)  NULL,
  principal   TINYINT(1) NOT NULL DEFAULT 0,
  activa      TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sede_negocio_id (negocio_id, id),
  UNIQUE KEY uk_sede_nombre (negocio_id, nombre),
  CONSTRAINT fk_sede_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id)
) ENGINE=InnoDB;

CREATE TABLE usuario_sede (
  negocio_id  BIGINT UNSIGNED NOT NULL,
  usuario_id  BIGINT UNSIGNED NOT NULL,
  sede_id     BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (usuario_id, sede_id),
  KEY ix_usuariosede_negocio_sede (negocio_id, sede_id),
  CONSTRAINT fk_usuariosede_usuario FOREIGN KEY (negocio_id, usuario_id) REFERENCES usuario (negocio_id, id),
  CONSTRAINT fk_usuariosede_sede    FOREIGN KEY (negocio_id, sede_id)    REFERENCES sede (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE area (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  nombre      VARCHAR(60) NOT NULL COMMENT 'Cabello, Uñas, Barbería, Cejas',
  activa      TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_area_negocio_id (negocio_id, id),
  UNIQUE KEY uk_area_nombre (negocio_id, nombre),
  CONSTRAINT fk_area_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id)
) ENGINE=InnoDB;

CREATE TABLE empleado (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id            BIGINT UNSIGNED NOT NULL,
  usuario_id            BIGINT UNSIGNED NULL,
  sede_id               BIGINT UNSIGNED NOT NULL,
  tipo_documento        VARCHAR(10)  NOT NULL DEFAULT 'CC',
  documento             VARCHAR(30)  NOT NULL,
  nombres               VARCHAR(80)  NOT NULL,
  apellidos             VARCHAR(80)  NOT NULL,
  fecha_nacimiento      DATE NULL,
  celular               VARCHAR(30)  NULL,
  correo                VARCHAR(160) NULL,
  direccion             VARCHAR(200) NULL,
  contacto_emergencia   VARCHAR(100) NULL,
  telefono_emergencia   VARCHAR(30)  NULL,
  fecha_ingreso         DATE NOT NULL,
  fecha_retiro          DATE NULL,
  motivo_retiro         VARCHAR(200) NULL,
  periodicidad_pago     VARCHAR(10)  NOT NULL DEFAULT 'quincenal',
  activo                TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_empleado_negocio_id (negocio_id, id),
  UNIQUE KEY uk_empleado_documento (negocio_id, tipo_documento, documento),
  UNIQUE KEY uk_empleado_usuario (negocio_id, usuario_id),
  KEY ix_empleado_sede (negocio_id, sede_id),
  CONSTRAINT fk_empleado_negocio FOREIGN KEY (negocio_id)             REFERENCES negocio (id),
  CONSTRAINT fk_empleado_usuario FOREIGN KEY (negocio_id, usuario_id) REFERENCES usuario (negocio_id, id),
  CONSTRAINT fk_empleado_sede    FOREIGN KEY (negocio_id, sede_id)    REFERENCES sede (negocio_id, id),
  CONSTRAINT ck_empleado_tipo_doc CHECK (tipo_documento IN ('CC','CE','TI','PA','PPT')),
  CONSTRAINT ck_empleado_periodicidad CHECK (periodicidad_pago IN ('diario','semanal','quincenal','mensual')),
  CONSTRAINT ck_empleado_retiro CHECK (fecha_retiro IS NULL OR fecha_retiro >= fecha_ingreso)
) ENGINE=InnoDB;

CREATE TABLE invitacion (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  correo       VARCHAR(160) NOT NULL,
  rol_id       BIGINT UNSIGNED NOT NULL,
  empleado_id  BIGINT UNSIGNED NULL,
  creada_por   BIGINT UNSIGNED NOT NULL,
  token_hash   CHAR(64) NOT NULL,
  expira_en    DATETIME NOT NULL COMMENT 'UTC',
  estado       VARCHAR(12) NOT NULL DEFAULT 'pendiente',
  PRIMARY KEY (id),
  UNIQUE KEY uk_invitacion_negocio_id (negocio_id, id),
  UNIQUE KEY uk_invitacion_token (token_hash),
  KEY ix_invitacion_rol (rol_id),
  KEY ix_invitacion_empleado (negocio_id, empleado_id),
  KEY ix_invitacion_creada (negocio_id, creada_por),
  CONSTRAINT fk_invitacion_rol      FOREIGN KEY (rol_id)                   REFERENCES rol (id),
  CONSTRAINT fk_invitacion_empleado FOREIGN KEY (negocio_id, empleado_id)  REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_invitacion_creada   FOREIGN KEY (negocio_id, creada_por)   REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_invitacion_estado CHECK (estado IN ('pendiente','aceptada','vencida'))
) ENGINE=InnoDB;

CREATE TABLE auditoria (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  usuario_id  BIGINT UNSIGNED NULL,
  entidad     VARCHAR(60) NOT NULL,
  entidad_id  BIGINT UNSIGNED NULL,
  accion      VARCHAR(30) NOT NULL,
  antes       JSON NULL,
  despues     JSON NULL,
  fecha       DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY ix_auditoria_fecha (negocio_id, fecha),
  KEY ix_auditoria_entidad (negocio_id, entidad, entidad_id),
  KEY ix_auditoria_usuario (negocio_id, usuario_id),
  CONSTRAINT fk_auditoria_negocio FOREIGN KEY (negocio_id)             REFERENCES negocio (id),
  CONSTRAINT fk_auditoria_usuario FOREIGN KEY (negocio_id, usuario_id) REFERENCES usuario (negocio_id, id)
) ENGINE=InnoDB;

-- =====================================================================
-- 3. ORGANIZACIÓN
-- =====================================================================
CREATE TABLE sede_horario (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  sede_id     BIGINT UNSIGNED NOT NULL,
  dia_semana  TINYINT NOT NULL COMMENT '1 = lunes ... 7 = domingo',
  apertura    TIME NOT NULL,
  cierre      TIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sedehorario_negocio_id (negocio_id, id),
  KEY ix_sedehorario_sede (negocio_id, sede_id, dia_semana),
  CONSTRAINT fk_sedehorario_sede FOREIGN KEY (negocio_id, sede_id) REFERENCES sede (negocio_id, id),
  CONSTRAINT ck_sedehorario_dia  CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT ck_sedehorario_hora CHECK (cierre > apertura)
) ENGINE=InnoDB;

CREATE TABLE televisor (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  sede_id     BIGINT UNSIGNED NOT NULL,
  nombre      VARCHAR(80) NOT NULL,
  token_hash  CHAR(64) NOT NULL COMMENT 'acceso sin clave: el token identifica negocio y sede',
  activo      TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_televisor_negocio_id (negocio_id, id),
  UNIQUE KEY uk_televisor_token (token_hash),
  KEY ix_televisor_sede (negocio_id, sede_id),
  CONSTRAINT fk_televisor_sede FOREIGN KEY (negocio_id, sede_id) REFERENCES sede (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE documento_negocio (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  tipo         VARCHAR(60)  NOT NULL,
  nombre       VARCHAR(120) NOT NULL,
  archivo_url  VARCHAR(500) NOT NULL,
  subido_en    DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_docnegocio_negocio_id (negocio_id, id),
  CONSTRAINT fk_docnegocio_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id)
) ENGINE=InnoDB;

-- =====================================================================
-- 4. EQUIPO
-- =====================================================================
CREATE TABLE empleado_area (
  negocio_id   BIGINT UNSIGNED NOT NULL,
  empleado_id  BIGINT UNSIGNED NOT NULL,
  area_id      BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (empleado_id, area_id),
  KEY ix_empleadoarea_area (negocio_id, area_id),
  CONSTRAINT fk_empleadoarea_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_empleadoarea_area     FOREIGN KEY (negocio_id, area_id)     REFERENCES area (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE documento_requerido (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  nombre       VARCHAR(120) NOT NULL,
  obligatorio  TINYINT(1) NOT NULL DEFAULT 1,
  orden        INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_docrequerido_negocio_id (negocio_id, id),
  UNIQUE KEY uk_docrequerido_nombre (negocio_id, nombre),
  CONSTRAINT fk_docrequerido_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id)
) ENGINE=InnoDB;

-- Los documentos NO vencen: solo están pendientes de verificar o verificados.
CREATE TABLE empleado_documento (
  id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id              BIGINT UNSIGNED NOT NULL,
  empleado_id             BIGINT UNSIGNED NOT NULL,
  documento_requerido_id  BIGINT UNSIGNED NOT NULL,
  archivo_url             VARCHAR(500) NOT NULL,
  estado                  VARCHAR(12) NOT NULL DEFAULT 'pendiente',
  verificado_por          BIGINT UNSIGNED NULL,
  subido_en               DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  verificado_en           DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_empdoc_negocio_id (negocio_id, id),
  UNIQUE KEY uk_empdoc_unico (negocio_id, empleado_id, documento_requerido_id),
  KEY ix_empdoc_requerido (negocio_id, documento_requerido_id),
  KEY ix_empdoc_verificador (negocio_id, verificado_por),
  CONSTRAINT fk_empdoc_empleado  FOREIGN KEY (negocio_id, empleado_id)            REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_empdoc_requerido FOREIGN KEY (negocio_id, documento_requerido_id) REFERENCES documento_requerido (negocio_id, id),
  CONSTRAINT fk_empdoc_verifica  FOREIGN KEY (negocio_id, verificado_por)         REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_empdoc_estado CHECK (estado IN ('pendiente','verificado')),
  CONSTRAINT ck_empdoc_verificado CHECK (estado = 'pendiente' OR (verificado_por IS NOT NULL AND verificado_en IS NOT NULL))
) ENGINE=InnoDB;

CREATE TABLE turno_empleado (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  empleado_id  BIGINT UNSIGNED NOT NULL,
  sede_id      BIGINT UNSIGNED NOT NULL,
  fecha        DATE NOT NULL,
  inicio       TIME NOT NULL,
  fin          TIME NOT NULL COMMENT 'varios turnos por día, sin cruzarse (lo valida trg_turno_*)',
  PRIMARY KEY (id),
  UNIQUE KEY uk_turno_negocio_id (negocio_id, id),
  KEY ix_turno_empleado_fecha (negocio_id, empleado_id, fecha),
  KEY ix_turno_sede_fecha (negocio_id, sede_id, fecha),
  CONSTRAINT fk_turno_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_turno_sede     FOREIGN KEY (negocio_id, sede_id)     REFERENCES sede (negocio_id, id),
  CONSTRAINT ck_turno_horas CHECK (fin > inicio)
) ENGINE=InnoDB;

CREATE TABLE bloqueo_agenda (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  empleado_id  BIGINT UNSIGNED NOT NULL,
  inicio       DATETIME NOT NULL COMMENT 'hora local del negocio',
  fin          DATETIME NOT NULL,
  motivo       VARCHAR(12) NOT NULL DEFAULT 'otro',
  PRIMARY KEY (id),
  UNIQUE KEY uk_bloqueo_negocio_id (negocio_id, id),
  KEY ix_bloqueo_empleado (negocio_id, empleado_id, inicio),
  CONSTRAINT fk_bloqueo_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT ck_bloqueo_horas CHECK (fin > inicio),
  CONSTRAINT ck_bloqueo_motivo CHECK (motivo IN ('descanso','permiso','otro'))
) ENGINE=InnoDB;

-- =====================================================================
-- 5. CATÁLOGO
-- =====================================================================
CREATE TABLE servicio (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id         BIGINT UNSIGNED NOT NULL,
  area_id            BIGINT UNSIGNED NOT NULL,
  nombre             VARCHAR(100) NOT NULL,
  descripcion        VARCHAR(300) NULL,
  duracion_min       INT NOT NULL COMMENT '30 cabello y barba, 45 uñas, 15 cejas',
  precio             DECIMAL(12,2) NOT NULL,
  permite_asesoria   TINYINT(1) NOT NULL DEFAULT 0,
  activo             TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_servicio_negocio_id (negocio_id, id),
  UNIQUE KEY uk_servicio_nombre (negocio_id, nombre),
  KEY ix_servicio_area (negocio_id, area_id),
  CONSTRAINT fk_servicio_area FOREIGN KEY (negocio_id, area_id) REFERENCES area (negocio_id, id),
  CONSTRAINT ck_servicio_valores CHECK (duracion_min > 0 AND precio >= 0)
) ENGINE=InnoDB;

CREATE TABLE empleado_servicio (
  negocio_id   BIGINT UNSIGNED NOT NULL,
  empleado_id  BIGINT UNSIGNED NOT NULL,
  servicio_id  BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (empleado_id, servicio_id),
  KEY ix_empserv_servicio (negocio_id, servicio_id),
  CONSTRAINT fk_empserv_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_empserv_servicio FOREIGN KEY (negocio_id, servicio_id) REFERENCES servicio (negocio_id, id)
) ENGINE=InnoDB;

CREATE TABLE asesoria_regla (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id    BIGINT UNSIGNED NOT NULL,
  servicio_id   BIGINT UNSIGNED NOT NULL,
  motivo        VARCHAR(100) NOT NULL COMMENT 'ej. decoloración',
  duracion_min  INT NOT NULL COMMENT 'ej. 300',
  PRIMARY KEY (id),
  UNIQUE KEY uk_asesoriaregla_negocio_id (negocio_id, id),
  KEY ix_asesoriaregla_servicio (negocio_id, servicio_id),
  CONSTRAINT fk_asesoriaregla_servicio FOREIGN KEY (negocio_id, servicio_id) REFERENCES servicio (negocio_id, id),
  CONSTRAINT ck_asesoriaregla_dur CHECK (duracion_min > 0)
) ENGINE=InnoDB;

-- Comisión: servicio_id vacío = porcentaje general del empleado.
CREATE TABLE comision (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id     BIGINT UNSIGNED NOT NULL,
  empleado_id    BIGINT UNSIGNED NOT NULL,
  servicio_id    BIGINT UNSIGNED NULL,
  porcentaje     DECIMAL(5,2) NOT NULL,
  vigente_desde  DATE NOT NULL,
  vigente_hasta  DATE NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_comision_negocio_id (negocio_id, id),
  KEY ix_comision_empleado (negocio_id, empleado_id, vigente_desde),
  KEY ix_comision_servicio (negocio_id, servicio_id),
  CONSTRAINT fk_comision_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_comision_servicio FOREIGN KEY (negocio_id, servicio_id) REFERENCES servicio (negocio_id, id),
  CONSTRAINT ck_comision_pct CHECK (porcentaje BETWEEN 0 AND 100),
  CONSTRAINT ck_comision_fechas CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde)
) ENGINE=InnoDB;

-- =====================================================================
-- 6. CLIENTES, RESERVAS Y FACTURAS
-- =====================================================================
CREATE TABLE cliente (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id            BIGINT UNSIGNED NOT NULL,
  usuario_id            BIGINT UNSIGNED NULL COMMENT 'solo si tiene cuenta',
  nombres               VARCHAR(80)  NOT NULL,
  apellidos             VARCHAR(80)  NOT NULL,
  celular               VARCHAR(30)  NOT NULL,
  correo                VARCHAR(160) NULL,
  tipo_documento        VARCHAR(10)  NULL,
  documento             VARCHAR(30)  NULL,
  fecha_nacimiento      DATE NULL,
  notas                 VARCHAR(1000) NULL,
  acepta_recordatorios  TINYINT(1) NOT NULL DEFAULT 1,
  origen                VARCHAR(15) NOT NULL DEFAULT 'administrador',
  activo                TINYINT(1) NOT NULL DEFAULT 1,
  creado_en             DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_cliente_negocio_id (negocio_id, id),
  UNIQUE KEY uk_cliente_celular (negocio_id, celular),
  UNIQUE KEY uk_cliente_usuario (negocio_id, usuario_id),
  KEY ix_cliente_nombre (negocio_id, apellidos, nombres),
  CONSTRAINT fk_cliente_usuario FOREIGN KEY (negocio_id, usuario_id) REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_cliente_origen CHECK (origen IN ('enlace','whatsapp','administrador','recomendacion','instagram','local','otro'))
) ENGINE=InnoDB;

CREATE TABLE cita (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  sede_id      BIGINT UNSIGNED NOT NULL,
  cliente_id   BIGINT UNSIGNED NOT NULL,
  creada_por   BIGINT UNSIGNED NULL COMMENT 'vacío si la reservó el propio cliente',
  fecha        DATE NOT NULL,
  origen       VARCHAR(15) NOT NULL DEFAULT 'administrador',
  estado       VARCHAR(12) NOT NULL DEFAULT 'reservada',
  notas        VARCHAR(500) NULL,
  creada_en    DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_cita_negocio_id (negocio_id, id),
  KEY ix_cita_fecha (negocio_id, sede_id, fecha),
  KEY ix_cita_cliente (negocio_id, cliente_id, fecha),
  KEY ix_cita_creadapor (negocio_id, creada_por),
  CONSTRAINT fk_cita_sede     FOREIGN KEY (negocio_id, sede_id)    REFERENCES sede (negocio_id, id),
  CONSTRAINT fk_cita_cliente  FOREIGN KEY (negocio_id, cliente_id) REFERENCES cliente (negocio_id, id),
  CONSTRAINT fk_cita_creadapor FOREIGN KEY (negocio_id, creada_por) REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_cita_origen CHECK (origen IN ('enlace','whatsapp','administrador')),
  CONSTRAINT ck_cita_estado CHECK (estado IN ('reservada','en curso','finalizada','cancelada','no asistio'))
) ENGINE=InnoDB;

-- Una cita puede traer varios servicios (corte + barba): una línea por servicio.
CREATE TABLE cita_servicio (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id    BIGINT UNSIGNED NOT NULL,
  cita_id       BIGINT UNSIGNED NOT NULL,
  servicio_id   BIGINT UNSIGNED NOT NULL,
  empleado_id   BIGINT UNSIGNED NOT NULL,
  inicio        DATETIME NOT NULL COMMENT 'hora local del negocio',
  fin           DATETIME NOT NULL,
  duracion_min  INT NOT NULL,
  valor         DECIMAL(12,2) NOT NULL COMMENT 'precio al reservar',
  estado        VARCHAR(12) NOT NULL DEFAULT 'programado',
  PRIMARY KEY (id),
  UNIQUE KEY uk_citaserv_negocio_id (negocio_id, id),
  KEY ix_citaserv_cita (negocio_id, cita_id),
  KEY ix_citaserv_empleado (negocio_id, empleado_id, inicio),
  KEY ix_citaserv_servicio (negocio_id, servicio_id),
  CONSTRAINT fk_citaserv_cita     FOREIGN KEY (negocio_id, cita_id)     REFERENCES cita (negocio_id, id),
  CONSTRAINT fk_citaserv_servicio FOREIGN KEY (negocio_id, servicio_id) REFERENCES servicio (negocio_id, id),
  CONSTRAINT fk_citaserv_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT ck_citaserv_horas CHECK (fin > inicio AND duracion_min > 0 AND valor >= 0),
  CONSTRAINT ck_citaserv_estado CHECK (estado IN ('programado','en curso','realizado','cancelado'))
) ENGINE=InnoDB;

CREATE TABLE asesoria_chat (
  id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id              BIGINT UNSIGNED NOT NULL,
  cliente_id              BIGINT UNSIGNED NOT NULL,
  cita_id                 BIGINT UNSIGNED NULL,
  tipo                    VARCHAR(20) NOT NULL DEFAULT 'tiempo_extra',
  duracion_propuesta_min  INT NULL,
  estado                  VARCHAR(30) NOT NULL DEFAULT 'abierto',
  PRIMARY KEY (id),
  UNIQUE KEY uk_asesoriachat_negocio_id (negocio_id, id),
  KEY ix_asesoriachat_cliente (negocio_id, cliente_id),
  KEY ix_asesoriachat_cita (negocio_id, cita_id),
  CONSTRAINT fk_asesoriachat_cliente FOREIGN KEY (negocio_id, cliente_id) REFERENCES cliente (negocio_id, id),
  CONSTRAINT fk_asesoriachat_cita    FOREIGN KEY (negocio_id, cita_id)    REFERENCES cita (negocio_id, id),
  CONSTRAINT ck_asesoriachat_tipo CHECK (tipo IN ('tiempo_extra','caso_especial')),
  CONSTRAINT ck_asesoriachat_estado CHECK (estado IN ('abierto','confirmado por administrador'))
) ENGINE=InnoDB;

CREATE TABLE asesoria_mensaje (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  chat_id     BIGINT UNSIGNED NOT NULL,
  autor       VARCHAR(15) NOT NULL,
  texto       VARCHAR(2000) NOT NULL,
  enviado_en  DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY ix_asesoriamsj_chat (negocio_id, chat_id, enviado_en),
  CONSTRAINT fk_asesoriamsj_chat FOREIGN KEY (negocio_id, chat_id) REFERENCES asesoria_chat (negocio_id, id),
  CONSTRAINT ck_asesoriamsj_autor CHECK (autor IN ('bot','cliente','administrador'))
) ENGINE=InnoDB;

-- =====================================================================
-- 7. INVENTARIO
-- =====================================================================
CREATE TABLE producto (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id       BIGINT UNSIGNED NOT NULL,
  nombre           VARCHAR(120) NOT NULL,
  tipo             VARCHAR(12) NOT NULL,
  codigo           VARCHAR(40) NULL,
  unidad           VARCHAR(20) NOT NULL DEFAULT 'unidad',
  costo            DECIMAL(12,2) NOT NULL DEFAULT 0,
  precio_publico   DECIMAL(12,2) NULL COMMENT 'solo productos de venta',
  precio_empleado  DECIMAL(12,2) NULL COMMENT 'solo productos de venta',
  stock_minimo     INT NOT NULL DEFAULT 5 COMMENT 'umbral de alerta',
  proveedor        VARCHAR(120) NULL,
  activo           TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_producto_negocio_id (negocio_id, id),
  UNIQUE KEY uk_producto_codigo (negocio_id, codigo),
  KEY ix_producto_tipo (negocio_id, tipo, nombre),
  CONSTRAINT fk_producto_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id),
  CONSTRAINT ck_producto_tipo CHECK (tipo IN ('venta','dotacion','uso_interno')),
  CONSTRAINT ck_producto_costo CHECK (costo >= 0 AND stock_minimo >= 0),
  -- venta: lleva ambos precios y el de empleado no supera al público; los demás tipos no llevan precio
  CONSTRAINT ck_producto_precios CHECK (
    (tipo = 'venta' AND precio_publico IS NOT NULL AND precio_empleado IS NOT NULL
        AND precio_empleado <= precio_publico AND precio_empleado >= 0)
    OR (tipo <> 'venta' AND precio_publico IS NULL AND precio_empleado IS NULL))
) ENGINE=InnoDB;

CREATE TABLE area_dotacion (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  area_id      BIGINT UNSIGNED NOT NULL,
  producto_id  BIGINT UNSIGNED NOT NULL,
  cantidad     INT NOT NULL DEFAULT 1 COMMENT 'piezas por persona',
  nota         VARCHAR(200) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_areadot_negocio_id (negocio_id, id),
  UNIQUE KEY uk_areadot_pieza (negocio_id, area_id, producto_id),
  KEY ix_areadot_producto (negocio_id, producto_id),
  CONSTRAINT fk_areadot_area     FOREIGN KEY (negocio_id, area_id)     REFERENCES area (negocio_id, id),
  CONSTRAINT fk_areadot_producto FOREIGN KEY (negocio_id, producto_id) REFERENCES producto (negocio_id, id),
  CONSTRAINT ck_areadot_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

CREATE TABLE entrega_interna (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id      BIGINT UNSIGNED NOT NULL,
  producto_id     BIGINT UNSIGNED NOT NULL,
  empleado_id     BIGINT UNSIGNED NOT NULL,
  entregada_por   BIGINT UNSIGNED NULL,
  tipo            VARCHAR(12) NOT NULL,
  fecha           DATE NOT NULL,
  cantidad        INT NOT NULL,
  precio_unitario DECIMAL(12,2) NULL COMMENT 'precio de empleado si es de venta',
  estado          VARCHAR(8) NOT NULL DEFAULT 'vigente',
  nota            VARCHAR(200) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_entrega_negocio_id (negocio_id, id),
  KEY ix_entrega_empleado (negocio_id, empleado_id, fecha),
  KEY ix_entrega_producto (negocio_id, producto_id),
  KEY ix_entrega_por (negocio_id, entregada_por),
  CONSTRAINT fk_entrega_producto FOREIGN KEY (negocio_id, producto_id)   REFERENCES producto (negocio_id, id),
  CONSTRAINT fk_entrega_empleado FOREIGN KEY (negocio_id, empleado_id)   REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_entrega_por      FOREIGN KEY (negocio_id, entregada_por) REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_entrega_tipo CHECK (tipo IN ('dotacion','venta','uso_interno')),
  CONSTRAINT ck_entrega_estado CHECK (estado IN ('vigente','cerrada')),
  CONSTRAINT ck_entrega_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_entrega_precio CHECK ((tipo = 'venta' AND precio_unitario IS NOT NULL) OR tipo <> 'venta')
) ENGINE=InnoDB;

CREATE TABLE devolucion_entrega (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  entrega_id  BIGINT UNSIGNED NOT NULL,
  fecha       DATE NOT NULL,
  cantidad    INT NOT NULL,
  motivo      VARCHAR(12) NOT NULL,
  se_cobra    TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'pérdida o daño que el administrador decide descontar',
  PRIMARY KEY (id),
  UNIQUE KEY uk_devolucion_negocio_id (negocio_id, id),
  KEY ix_devolucion_entrega (negocio_id, entrega_id),
  CONSTRAINT fk_devolucion_entrega FOREIGN KEY (negocio_id, entrega_id) REFERENCES entrega_interna (negocio_id, id),
  CONSTRAINT ck_devolucion_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_devolucion_motivo CHECK (motivo IN ('no vendida','retiro','danada','perdida'))
) ENGINE=InnoDB;

CREATE TABLE venta_producto (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id       BIGINT UNSIGNED NOT NULL,
  producto_id      BIGINT UNSIGNED NOT NULL,
  empleado_id      BIGINT UNSIGNED NULL COMMENT 'vacío si es de mostrador',
  entrega_id       BIGINT UNSIGNED NULL COMMENT 'de qué entrega al empleado salió',
  cliente_id       BIGINT UNSIGNED NULL,
  cita_id          BIGINT UNSIGNED NULL,
  fecha            DATE NOT NULL,
  cantidad         INT NOT NULL,
  destino          VARCHAR(12) NOT NULL,
  precio_cobrado   DECIMAL(12,2) NOT NULL COMMENT 'lo que paga el cliente (precio público)',
  precio_empleado  DECIMAL(12,2) NULL COMMENT 'lo que se le descuenta al empleado',
  PRIMARY KEY (id),
  UNIQUE KEY uk_venta_negocio_id (negocio_id, id),
  KEY ix_venta_producto (negocio_id, producto_id, fecha),
  KEY ix_venta_empleado (negocio_id, empleado_id, fecha),
  KEY ix_venta_entrega (negocio_id, entrega_id),
  KEY ix_venta_cliente (negocio_id, cliente_id),
  KEY ix_venta_cita (negocio_id, cita_id),
  CONSTRAINT fk_venta_producto FOREIGN KEY (negocio_id, producto_id) REFERENCES producto (negocio_id, id),
  CONSTRAINT fk_venta_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_venta_entrega  FOREIGN KEY (negocio_id, entrega_id)  REFERENCES entrega_interna (negocio_id, id),
  CONSTRAINT fk_venta_cliente  FOREIGN KEY (negocio_id, cliente_id)  REFERENCES cliente (negocio_id, id),
  CONSTRAINT fk_venta_cita     FOREIGN KEY (negocio_id, cita_id)     REFERENCES cita (negocio_id, id),
  CONSTRAINT ck_venta_cantidad CHECK (cantidad > 0 AND precio_cobrado >= 0),
  CONSTRAINT ck_venta_destino CHECK (destino IN ('cliente','uso_personal','mostrador')),
  -- uso personal y venta de un empleado exigen empleado; mostrador no lleva empleado
  CONSTRAINT ck_venta_empleado CHECK (
    (destino = 'mostrador' AND empleado_id IS NULL)
    OR (destino IN ('cliente','uso_personal') AND empleado_id IS NOT NULL)
    OR (destino = 'cliente' AND empleado_id IS NULL))
) ENGINE=InnoDB;

-- Libro de inventario: solo se agrega, nunca se edita ni se borra.
-- cantidad > 0 entra a la bodega, cantidad < 0 sale.
CREATE TABLE movimiento_inventario (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id     BIGINT UNSIGNED NOT NULL,
  producto_id    BIGINT UNSIGNED NOT NULL,
  sede_id        BIGINT UNSIGNED NOT NULL,
  entrega_id     BIGINT UNSIGNED NULL,
  venta_id       BIGINT UNSIGNED NULL,
  registrado_por BIGINT UNSIGNED NULL,
  tipo           VARCHAR(12) NOT NULL,
  cantidad       INT NOT NULL,
  fecha          DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  nota           VARCHAR(200) NULL,
  PRIMARY KEY (id),
  KEY ix_mov_producto (negocio_id, producto_id, sede_id),
  KEY ix_mov_entrega (negocio_id, entrega_id),
  KEY ix_mov_venta (negocio_id, venta_id),
  KEY ix_mov_sede (negocio_id, sede_id, fecha),
  KEY ix_mov_registra (negocio_id, registrado_por),
  CONSTRAINT fk_mov_producto FOREIGN KEY (negocio_id, producto_id)    REFERENCES producto (negocio_id, id),
  CONSTRAINT fk_mov_sede     FOREIGN KEY (negocio_id, sede_id)        REFERENCES sede (negocio_id, id),
  CONSTRAINT fk_mov_entrega  FOREIGN KEY (negocio_id, entrega_id)     REFERENCES entrega_interna (negocio_id, id),
  CONSTRAINT fk_mov_venta    FOREIGN KEY (negocio_id, venta_id)       REFERENCES venta_producto (negocio_id, id),
  CONSTRAINT fk_mov_registra FOREIGN KEY (negocio_id, registrado_por) REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_mov_tipo CHECK (tipo IN ('compra','entrega','devolucion','venta','ajuste','baja')),
  CONSTRAINT ck_mov_signo CHECK (
    (tipo IN ('compra','devolucion') AND cantidad > 0)
    OR (tipo IN ('entrega','venta','baja') AND cantidad < 0)
    OR (tipo = 'ajuste' AND cantidad <> 0))
) ENGINE=InnoDB;

-- =====================================================================
-- 8. FACTURAS (solo historial: no hay facturación electrónica)
-- =====================================================================
CREATE TABLE factura (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id   BIGINT UNSIGNED NOT NULL,
  cita_id      BIGINT UNSIGNED NOT NULL,
  numero       INT UNSIGNED NOT NULL COMMENT 'consecutivo por negocio',
  total        DECIMAL(12,2) NOT NULL,
  metodo_pago  VARCHAR(15) NOT NULL DEFAULT 'efectivo',
  estado       VARCHAR(10) NOT NULL DEFAULT 'emitida',
  emitida_en   DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uk_factura_negocio_id (negocio_id, id),
  UNIQUE KEY uk_factura_numero (negocio_id, numero),
  UNIQUE KEY uk_factura_cita (negocio_id, cita_id),
  CONSTRAINT fk_factura_cita FOREIGN KEY (negocio_id, cita_id) REFERENCES cita (negocio_id, id),
  CONSTRAINT ck_factura_total CHECK (total >= 0),
  CONSTRAINT ck_factura_metodo CHECK (metodo_pago IN ('efectivo','tarjeta','transferencia','otro')),
  CONSTRAINT ck_factura_estado CHECK (estado IN ('emitida','anulada'))
) ENGINE=InnoDB;

CREATE TABLE factura_linea (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id        BIGINT UNSIGNED NOT NULL,
  factura_id        BIGINT UNSIGNED NOT NULL,
  cita_servicio_id  BIGINT UNSIGNED NULL,
  venta_producto_id BIGINT UNSIGNED NULL,
  empleado_id       BIGINT UNSIGNED NULL,
  descripcion       VARCHAR(200) NOT NULL,
  valor             DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_facturalinea_negocio_id (negocio_id, id),
  UNIQUE KEY uk_facturalinea_citaserv (negocio_id, cita_servicio_id),
  UNIQUE KEY uk_facturalinea_venta (negocio_id, venta_producto_id),
  KEY ix_facturalinea_factura (negocio_id, factura_id),
  KEY ix_facturalinea_empleado (negocio_id, empleado_id),
  CONSTRAINT fk_facturalinea_factura  FOREIGN KEY (negocio_id, factura_id)        REFERENCES factura (negocio_id, id),
  CONSTRAINT fk_facturalinea_citaserv FOREIGN KEY (negocio_id, cita_servicio_id)  REFERENCES cita_servicio (negocio_id, id),
  CONSTRAINT fk_facturalinea_venta    FOREIGN KEY (negocio_id, venta_producto_id) REFERENCES venta_producto (negocio_id, id),
  CONSTRAINT fk_facturalinea_empleado FOREIGN KEY (negocio_id, empleado_id)       REFERENCES empleado (negocio_id, id),
  CONSTRAINT ck_facturalinea_origen CHECK (cita_servicio_id IS NULL OR venta_producto_id IS NULL),
  CONSTRAINT ck_facturalinea_valor CHECK (valor >= 0)
) ENGINE=InnoDB;

-- =====================================================================
-- 9. PAGOS Y FINANZAS
-- =====================================================================
CREATE TABLE liquidacion (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id       BIGINT UNSIGNED NOT NULL,
  empleado_id      BIGINT UNSIGNED NOT NULL,
  pagado_por       BIGINT UNSIGNED NULL,
  periodicidad     VARCHAR(10) NOT NULL,
  desde            DATE NOT NULL,
  hasta            DATE NOT NULL,
  total_comisiones DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_descuentos DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_neto       DECIMAL(12,2) NOT NULL DEFAULT 0,
  estado           VARCHAR(10) NOT NULL DEFAULT 'pendiente',
  pagado_en        DATETIME NULL COMMENT 'UTC',
  PRIMARY KEY (id),
  UNIQUE KEY uk_liquidacion_negocio_id (negocio_id, id),
  UNIQUE KEY uk_liquidacion_periodo (negocio_id, empleado_id, desde, hasta),
  KEY ix_liquidacion_pagadopor (negocio_id, pagado_por),
  CONSTRAINT fk_liquidacion_empleado FOREIGN KEY (negocio_id, empleado_id) REFERENCES empleado (negocio_id, id),
  CONSTRAINT fk_liquidacion_pagador  FOREIGN KEY (negocio_id, pagado_por)  REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_liquidacion_period CHECK (periodicidad IN ('diario','semanal','quincenal','mensual') AND hasta >= desde),
  CONSTRAINT ck_liquidacion_estado CHECK (estado IN ('pendiente','pagado')),
  CONSTRAINT ck_liquidacion_neto CHECK (total_neto = total_comisiones - total_descuentos)
) ENGINE=InnoDB;

CREATE TABLE liquidacion_detalle (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id        BIGINT UNSIGNED NOT NULL,
  liquidacion_id    BIGINT UNSIGNED NOT NULL,
  cita_servicio_id  BIGINT UNSIGNED NULL,
  venta_id          BIGINT UNSIGNED NULL,
  devolucion_id     BIGINT UNSIGNED NULL,
  tipo              VARCHAR(20) NOT NULL,
  descripcion       VARCHAR(200) NOT NULL,
  base              DECIMAL(12,2) NULL,
  porcentaje        DECIMAL(5,2)  NULL,
  valor             DECIMAL(12,2) NOT NULL COMMENT 'siempre positivo; el tipo dice si suma o resta',
  PRIMARY KEY (id),
  UNIQUE KEY uk_liqdetalle_negocio_id (negocio_id, id),
  KEY ix_liqdetalle_liquidacion (negocio_id, liquidacion_id),
  KEY ix_liqdetalle_citaserv (negocio_id, cita_servicio_id),
  KEY ix_liqdetalle_venta (negocio_id, venta_id),
  KEY ix_liqdetalle_devolucion (negocio_id, devolucion_id),
  CONSTRAINT fk_liqdetalle_liquidacion FOREIGN KEY (negocio_id, liquidacion_id)   REFERENCES liquidacion (negocio_id, id),
  CONSTRAINT fk_liqdetalle_citaserv    FOREIGN KEY (negocio_id, cita_servicio_id) REFERENCES cita_servicio (negocio_id, id),
  CONSTRAINT fk_liqdetalle_venta       FOREIGN KEY (negocio_id, venta_id)         REFERENCES venta_producto (negocio_id, id),
  CONSTRAINT fk_liqdetalle_devolucion  FOREIGN KEY (negocio_id, devolucion_id)    REFERENCES devolucion_entrega (negocio_id, id),
  CONSTRAINT ck_liqdetalle_tipo CHECK (tipo IN ('comision','descuento_venta','descuento_personal','descuento_dotacion')),
  CONSTRAINT ck_liqdetalle_valor CHECK (valor >= 0)
) ENGINE=InnoDB;

CREATE TABLE categoria_gasto (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id  BIGINT UNSIGNED NOT NULL,
  nombre      VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_catgasto_negocio_id (negocio_id, id),
  UNIQUE KEY uk_catgasto_nombre (negocio_id, nombre),
  CONSTRAINT fk_catgasto_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id)
) ENGINE=InnoDB;

CREATE TABLE gasto (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id      BIGINT UNSIGNED NOT NULL,
  sede_id         BIGINT UNSIGNED NOT NULL,
  categoria_id    BIGINT UNSIGNED NOT NULL,
  registrado_por  BIGINT UNSIGNED NULL,
  concepto        VARCHAR(200) NOT NULL,
  valor           DECIMAL(12,2) NOT NULL,
  fecha           DATE NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_gasto_negocio_id (negocio_id, id),
  KEY ix_gasto_fecha (negocio_id, sede_id, fecha),
  KEY ix_gasto_categoria (negocio_id, categoria_id),
  KEY ix_gasto_registra (negocio_id, registrado_por),
  CONSTRAINT fk_gasto_sede      FOREIGN KEY (negocio_id, sede_id)        REFERENCES sede (negocio_id, id),
  CONSTRAINT fk_gasto_categoria FOREIGN KEY (negocio_id, categoria_id)   REFERENCES categoria_gasto (negocio_id, id),
  CONSTRAINT fk_gasto_registra  FOREIGN KEY (negocio_id, registrado_por) REFERENCES usuario (negocio_id, id),
  CONSTRAINT ck_gasto_valor CHECK (valor >= 0)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
-- =====================================================================
-- CITARA · 02 · Datos base de la plataforma (globales)
-- Roles, permisos y planes. Los límites y precios de los planes son
-- EJEMPLOS: están por confirmar con el equipo.
-- =====================================================================

INSERT INTO rol (clave, nombre) VALUES
  ('cliente','Cliente'), ('empleado','Empleado'),
  ('administrador','Administrador'), ('dueno','Dueño');

INSERT INTO permiso (modulo, accion)
SELECT m.modulo, a.accion
FROM (SELECT 'agenda' modulo UNION SELECT 'clientes' UNION SELECT 'equipo' UNION SELECT 'servicios'
      UNION SELECT 'facturas' UNION SELECT 'pagos' UNION SELECT 'inventario' UNION SELECT 'finanzas'
      UNION SELECT 'reportes' UNION SELECT 'usuarios' UNION SELECT 'negocio') m
CROSS JOIN (SELECT 'ver' accion UNION SELECT 'crear' UNION SELECT 'editar' UNION SELECT 'eliminar') a;

-- Dueño: todo.
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p WHERE r.clave = 'dueno';
-- Administrador: operación diaria (no finanzas, reportes, usuarios ni negocio).
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p
 WHERE r.clave = 'administrador'
   AND p.modulo IN ('agenda','clientes','equipo','servicios','facturas','pagos','inventario');
-- Empleado: ve su agenda, sus clientes y su inventario.
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p
 WHERE r.clave = 'empleado' AND p.accion = 'ver' AND p.modulo IN ('agenda','inventario','pagos');
-- Cliente: reserva y ve sus citas.
INSERT INTO rol_permiso SELECT r.id, p.id FROM rol r, permiso p
 WHERE r.clave = 'cliente' AND p.modulo = 'agenda' AND p.accion IN ('ver','crear');

INSERT INTO plan (nombre, max_sedes, max_empleados, precio_mensual) VALUES
  ('Inicial',      1,  5,  49000),
  ('Profesional',  3, 20, 99000),
  ('Cadena',      10, 100, 249000);
