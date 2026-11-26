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
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS citara;
CREATE DATABASE citara CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE citara;
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
SET NAMES utf8mb4;
USE citara;

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
-- =====================================================================
-- CITARA · 03 · Reglas en la base de datos: funciones, procedimientos
-- y disparadores (MySQL no tiene EXCLUDE ni RLS, así que se hacen aquí).
-- Se ejecuta con el cliente `mysql` (usa DELIMITER).
-- =====================================================================
SET NAMES utf8mb4;
USE citara;
DELIMITER $$

-- ---------------------------------------------------------------------
-- Tenant de la conexión. Con un pool de conexiones, la app DEBE llamar
-- sp_set_negocio al tomar la conexión y sp_limpiar_negocio al devolverla.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_negocio() RETURNS BIGINT UNSIGNED
  NO SQL DETERMINISTIC
BEGIN
  RETURN @negocio_id;      -- NULL si nadie lo fijó: las vistas no devuelven nada
END$$

CREATE PROCEDURE sp_set_negocio(IN p_negocio BIGINT UNSIGNED)
BEGIN
  DECLARE v_estado VARCHAR(15);
  SELECT estado INTO v_estado FROM negocio WHERE id = p_negocio;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Negocio no existe';
  ELSEIF v_estado <> 'activo' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Negocio suspendido o cancelado';
  END IF;
  SET @negocio_id = p_negocio;
END$$

CREATE PROCEDURE sp_limpiar_negocio()
BEGIN
  SET @negocio_id = NULL;
END$$

-- ---------------------------------------------------------------------
-- TURNOS: varios por día, sin cruzarse por empleado.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_validar_turno(
  IN p_negocio BIGINT UNSIGNED, IN p_id BIGINT UNSIGNED, IN p_empleado BIGINT UNSIGNED,
  IN p_fecha DATE, IN p_inicio TIME, IN p_fin TIME)
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  -- Serializa a quienes tocan el mismo empleado: evita dos turnos simultáneos que se crucen.
  SELECT id INTO v_lock FROM empleado WHERE negocio_id = p_negocio AND id = p_empleado FOR UPDATE;
  IF EXISTS (SELECT 1 FROM turno_empleado t
              WHERE t.negocio_id = p_negocio AND t.empleado_id = p_empleado AND t.fecha = p_fecha
                AND t.id <> COALESCE(p_id, 0) AND t.inicio < p_fin AND t.fin > p_inicio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El turno se cruza con otro turno del mismo empleado';
  END IF;
END$$

CREATE TRIGGER trg_turno_bi BEFORE INSERT ON turno_empleado FOR EACH ROW
BEGIN
  CALL sp_validar_turno(NEW.negocio_id, NULL, NEW.empleado_id, NEW.fecha, NEW.inicio, NEW.fin);
END$$

CREATE TRIGGER trg_turno_bu BEFORE UPDATE ON turno_empleado FOR EACH ROW
BEGIN
  CALL sp_validar_turno(NEW.negocio_id, OLD.id, NEW.empleado_id, NEW.fecha, NEW.inicio, NEW.fin);
END$$

-- ---------------------------------------------------------------------
-- CITAS: un servicio de una cita debe
--   * empezar y terminar el mismo día de la cita,
--   * ser de un empleado habilitado para ese servicio,
--   * caer dentro de un turno del empleado en esa sede,
--   * no cruzarse con otra cita ni con un bloqueo de agenda.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_validar_cita_servicio(
  IN p_negocio BIGINT UNSIGNED, IN p_id BIGINT UNSIGNED, IN p_cita BIGINT UNSIGNED,
  IN p_servicio BIGINT UNSIGNED, IN p_empleado BIGINT UNSIGNED,
  IN p_inicio DATETIME, IN p_fin DATETIME, IN p_estado VARCHAR(12))
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  DECLARE v_fecha DATE;
  DECLARE v_sede BIGINT UNSIGNED;
  DECLARE v_activo TINYINT(1);

  IF p_estado <> 'cancelado' THEN
    SELECT id, activo INTO v_lock, v_activo FROM empleado
     WHERE negocio_id = p_negocio AND id = p_empleado FOR UPDATE;

    SELECT fecha, sede_id INTO v_fecha, v_sede FROM cita WHERE negocio_id = p_negocio AND id = p_cita;

    IF DATE(p_inicio) <> DATE(p_fin) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio debe empezar y terminar el mismo día';
    END IF;
    IF v_fecha <> DATE(p_inicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio no coincide con la fecha de la cita';
    END IF;
    IF v_activo = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no está activo';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM empleado_servicio
                    WHERE negocio_id = p_negocio AND empleado_id = p_empleado AND servicio_id = p_servicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no está habilitado para este servicio';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM turno_empleado t
                    WHERE t.negocio_id = p_negocio AND t.empleado_id = p_empleado AND t.sede_id = v_sede
                      AND t.fecha = DATE(p_inicio) AND t.inicio <= TIME(p_inicio) AND t.fin >= TIME(p_fin)) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El servicio queda fuera de los turnos del empleado';
    END IF;
    IF EXISTS (SELECT 1 FROM cita_servicio c
                WHERE c.negocio_id = p_negocio AND c.empleado_id = p_empleado
                  AND c.estado <> 'cancelado' AND c.id <> COALESCE(p_id, 0)
                  AND c.inicio < p_fin AND c.fin > p_inicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado ya tiene una cita en ese horario';
    END IF;
    IF EXISTS (SELECT 1 FROM bloqueo_agenda b
                WHERE b.negocio_id = p_negocio AND b.empleado_id = p_empleado
                  AND b.inicio < p_fin AND b.fin > p_inicio) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El horario está bloqueado en la agenda del empleado';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_citaserv_bi BEFORE INSERT ON cita_servicio FOR EACH ROW
BEGIN
  CALL sp_validar_cita_servicio(NEW.negocio_id, NULL, NEW.cita_id, NEW.servicio_id,
                                NEW.empleado_id, NEW.inicio, NEW.fin, NEW.estado);
END$$

CREATE TRIGGER trg_citaserv_bu BEFORE UPDATE ON cita_servicio FOR EACH ROW
BEGIN
  -- Solo revalida si cambia lo que afecta la agenda (cerrar o facturar un servicio no la revalida).
  IF NOT (NEW.inicio = OLD.inicio AND NEW.fin = OLD.fin AND NEW.empleado_id = OLD.empleado_id
          AND NEW.servicio_id = OLD.servicio_id AND NOT (OLD.estado = 'cancelado' AND NEW.estado <> 'cancelado')) THEN
    CALL sp_validar_cita_servicio(NEW.negocio_id, OLD.id, NEW.cita_id, NEW.servicio_id,
                                  NEW.empleado_id, NEW.inicio, NEW.fin, NEW.estado);
  END IF;
END$$

-- ---------------------------------------------------------------------
-- INVENTARIO
-- Existencia en bodega = suma del libro de movimientos.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_stock_bodega(p_negocio BIGINT UNSIGNED, p_producto BIGINT UNSIGNED, p_sede BIGINT UNSIGNED)
  RETURNS INT READS SQL DATA
BEGIN
  DECLARE v INT;
  SELECT COALESCE(SUM(cantidad), 0) INTO v FROM movimiento_inventario
   WHERE negocio_id = p_negocio AND producto_id = p_producto AND sede_id = p_sede;
  RETURN v;
END$$

-- Unidades que el empleado aún tiene de una entrega (entregadas - devueltas - vendidas/usadas).
CREATE FUNCTION fn_en_mano(p_negocio BIGINT UNSIGNED, p_entrega BIGINT UNSIGNED)
  RETURNS INT READS SQL DATA
BEGIN
  DECLARE v INT;
  SELECT e.cantidad
         - COALESCE((SELECT SUM(d.cantidad) FROM devolucion_entrega d
                      WHERE d.negocio_id = e.negocio_id AND d.entrega_id = e.id), 0)
         - COALESCE((SELECT SUM(v.cantidad) FROM venta_producto v
                      WHERE v.negocio_id = e.negocio_id AND v.entrega_id = e.id), 0)
    INTO v FROM entrega_interna e WHERE e.negocio_id = p_negocio AND e.id = p_entrega;
  RETURN v;
END$$

-- La bodega nunca queda en negativo.
CREATE TRIGGER trg_mov_bi BEFORE INSERT ON movimiento_inventario FOR EACH ROW
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  IF NEW.cantidad < 0 THEN
    SELECT id INTO v_lock FROM producto WHERE negocio_id = NEW.negocio_id AND id = NEW.producto_id FOR UPDATE;
    IF fn_stock_bodega(NEW.negocio_id, NEW.producto_id, NEW.sede_id) + NEW.cantidad < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay existencias suficientes en la bodega';
    END IF;
  END IF;
END$$

-- El libro de inventario y la auditoría solo se agregan: no se editan ni se borran.
CREATE TRIGGER trg_mov_bu BEFORE UPDATE ON movimiento_inventario FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos de inventario no se editan: registra un ajuste'; END$$
CREATE TRIGGER trg_mov_bd BEFORE DELETE ON movimiento_inventario FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos de inventario no se borran: registra un ajuste'; END$$
CREATE TRIGGER trg_aud_bu BEFORE UPDATE ON auditoria FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La auditoría no se edita'; END$$
CREATE TRIGGER trg_aud_bd BEFORE DELETE ON auditoria FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La auditoría no se borra'; END$$

-- Entrega al empleado: coherente con el producto y saca las unidades de la bodega.
CREATE TRIGGER trg_entrega_bi BEFORE INSERT ON entrega_interna FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(12);
  DECLARE v_precio DECIMAL(12,2);
  SELECT tipo, precio_empleado INTO v_tipo, v_precio FROM producto
   WHERE negocio_id = NEW.negocio_id AND id = NEW.producto_id;
  IF v_tipo <> NEW.tipo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tipo de la entrega no coincide con el tipo del producto';
  END IF;
  IF NEW.tipo = 'venta' AND NEW.precio_unitario IS NULL THEN
    SET NEW.precio_unitario = v_precio;      -- por defecto, el precio de empleado del producto
  END IF;
END$$

CREATE TRIGGER trg_entrega_ai AFTER INSERT ON entrega_interna FOR EACH ROW
BEGIN
  DECLARE v_sede BIGINT UNSIGNED;
  SELECT sede_id INTO v_sede FROM empleado WHERE negocio_id = NEW.negocio_id AND id = NEW.empleado_id;
  INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, entrega_id, registrado_por, tipo, cantidad, nota)
  VALUES (NEW.negocio_id, NEW.producto_id, v_sede, NEW.id, NEW.entregada_por, 'entrega', -NEW.cantidad, NEW.nota);
END$$

-- Devolución: no puede devolver más de lo que tiene. Lo dañado o perdido no regresa a la bodega.
CREATE TRIGGER trg_devolucion_bi BEFORE INSERT ON devolucion_entrega FOR EACH ROW
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  SELECT id INTO v_lock FROM entrega_interna WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id FOR UPDATE;
  IF NEW.cantidad > fn_en_mano(NEW.negocio_id, NEW.entrega_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Devuelve más unidades de las que el empleado tiene';
  END IF;
  IF NEW.motivo IN ('danada','perdida') AND NEW.se_cobra IS NULL THEN SET NEW.se_cobra = 0; END IF;
  IF NEW.motivo IN ('no vendida','retiro') THEN SET NEW.se_cobra = 0; END IF;
END$$

CREATE TRIGGER trg_devolucion_ai AFTER INSERT ON devolucion_entrega FOR EACH ROW
BEGIN
  DECLARE v_producto BIGINT UNSIGNED; DECLARE v_empleado BIGINT UNSIGNED; DECLARE v_sede BIGINT UNSIGNED;
  SELECT producto_id, empleado_id INTO v_producto, v_empleado FROM entrega_interna
   WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
  IF NEW.motivo IN ('no vendida','retiro') THEN
    SELECT sede_id INTO v_sede FROM empleado WHERE negocio_id = NEW.negocio_id AND id = v_empleado;
    INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, entrega_id, tipo, cantidad, nota)
    VALUES (NEW.negocio_id, v_producto, v_sede, NEW.entrega_id, 'devolucion', NEW.cantidad, NEW.motivo);
  END IF;
  IF fn_en_mano(NEW.negocio_id, NEW.entrega_id) = 0 THEN
    UPDATE entrega_interna SET estado = 'cerrada' WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
  END IF;
END$$

-- Venta: si sale de una entrega, no vende más de lo que el empleado tiene (la bodega ya
-- se descontó al entregar). Si es de mostrador, descuenta la bodega de la sede.
CREATE TRIGGER trg_venta_bi BEFORE INSERT ON venta_producto FOR EACH ROW
BEGIN
  DECLARE v_lock BIGINT UNSIGNED;
  DECLARE v_pe DECIMAL(12,2);
  DECLARE v_prod BIGINT UNSIGNED; DECLARE v_emp BIGINT UNSIGNED; DECLARE v_tipo VARCHAR(12);
  IF NEW.entrega_id IS NOT NULL THEN
    SELECT id, producto_id, empleado_id, tipo INTO v_lock, v_prod, v_emp, v_tipo FROM entrega_interna
     WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id FOR UPDATE;
    IF v_tipo <> 'venta' OR v_prod <> NEW.producto_id OR v_emp <> NEW.empleado_id THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no corresponde a la entrega indicada';
    END IF;
    IF NEW.cantidad > fn_en_mano(NEW.negocio_id, NEW.entrega_id) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no tiene tantas unidades';
    END IF;
    IF NEW.precio_empleado IS NULL THEN
      SELECT precio_unitario INTO v_pe FROM entrega_interna WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
      SET NEW.precio_empleado = v_pe;
    END IF;
  ELSEIF NEW.destino <> 'mostrador' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta de un empleado debe indicar la entrega de la que sale';
  END IF;
END$$

CREATE TRIGGER trg_venta_ai AFTER INSERT ON venta_producto FOR EACH ROW
BEGIN
  DECLARE v_sede BIGINT UNSIGNED;
  IF NEW.entrega_id IS NULL THEN
    IF NEW.cita_id IS NOT NULL THEN
      SELECT sede_id INTO v_sede FROM cita WHERE negocio_id = NEW.negocio_id AND id = NEW.cita_id;
    ELSE
      SELECT id INTO v_sede FROM sede WHERE negocio_id = NEW.negocio_id AND principal = 1 LIMIT 1;
    END IF;
    INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, venta_id, tipo, cantidad)
    VALUES (NEW.negocio_id, NEW.producto_id, v_sede, NEW.id, 'venta', -NEW.cantidad);
  ELSE
    IF fn_en_mano(NEW.negocio_id, NEW.entrega_id) = 0 THEN
      UPDATE entrega_interna SET estado = 'cerrada' WHERE negocio_id = NEW.negocio_id AND id = NEW.entrega_id;
    END IF;
  END IF;
END$$

-- ---------------------------------------------------------------------
-- FACTURA: consecutivo por negocio, líneas desde la cita y total.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_emitir_factura(
  IN p_negocio BIGINT UNSIGNED, IN p_cita BIGINT UNSIGNED, IN p_metodo VARCHAR(15),
  OUT p_factura BIGINT UNSIGNED)
BEGIN
  DECLARE v_num INT UNSIGNED; DECLARE v_total DECIMAL(12,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  IF EXISTS (SELECT 1 FROM factura WHERE negocio_id = p_negocio AND cita_id = p_cita) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita ya tiene factura';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cita_servicio WHERE negocio_id = p_negocio AND cita_id = p_cita AND estado = 'realizado') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cita no tiene servicios realizados para facturar';
  END IF;
  -- El UPDATE bloquea la fila del negocio: dos facturas simultáneas no repiten número.
  UPDATE negocio SET ultimo_numero_factura = ultimo_numero_factura + 1 WHERE id = p_negocio;
  SELECT ultimo_numero_factura INTO v_num FROM negocio WHERE id = p_negocio;

  INSERT INTO factura (negocio_id, cita_id, numero, total, metodo_pago) VALUES (p_negocio, p_cita, v_num, 0, p_metodo);
  SET p_factura = LAST_INSERT_ID();

  INSERT INTO factura_linea (negocio_id, factura_id, cita_servicio_id, empleado_id, descripcion, valor)
  SELECT cs.negocio_id, p_factura, cs.id, cs.empleado_id, s.nombre, cs.valor
    FROM cita_servicio cs JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
   WHERE cs.negocio_id = p_negocio AND cs.cita_id = p_cita AND cs.estado = 'realizado';

  INSERT INTO factura_linea (negocio_id, factura_id, venta_producto_id, empleado_id, descripcion, valor)
  SELECT v.negocio_id, p_factura, v.id, v.empleado_id, pr.nombre, v.cantidad * v.precio_cobrado
    FROM venta_producto v JOIN producto pr ON pr.negocio_id = v.negocio_id AND pr.id = v.producto_id
   WHERE v.negocio_id = p_negocio AND v.cita_id = p_cita AND v.destino = 'cliente';

  SELECT COALESCE(SUM(valor), 0) INTO v_total FROM factura_linea WHERE negocio_id = p_negocio AND factura_id = p_factura;
  UPDATE factura SET total = v_total WHERE negocio_id = p_negocio AND id = p_factura;
  UPDATE cita SET estado = 'finalizada' WHERE negocio_id = p_negocio AND id = p_cita;
  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- ALTA DE UN NEGOCIO (tenant) con todo lo que necesita para empezar:
-- sede principal, áreas, catálogo base, documentos requeridos, categorías
-- de gasto y el usuario dueño.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_crear_negocio(
  IN p_slug VARCHAR(60), IN p_nombre VARCHAR(120), IN p_plan BIGINT UNSIGNED,
  IN p_correo_dueno VARCHAR(160), IN p_clave_hash VARCHAR(255),
  OUT p_negocio BIGINT UNSIGNED)
BEGIN
  DECLARE v_cab BIGINT UNSIGNED; DECLARE v_uni BIGINT UNSIGNED;
  DECLARE v_bar BIGINT UNSIGNED; DECLARE v_cej BIGINT UNSIGNED;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;
  INSERT INTO negocio (slug, nombre, plan_id) VALUES (p_slug, p_nombre, p_plan);
  SET p_negocio = LAST_INSERT_ID();

  INSERT INTO suscripcion (negocio_id, plan_id, estado, inicio) VALUES (p_negocio, p_plan, 'prueba', CURRENT_DATE);
  INSERT INTO sede (negocio_id, nombre, principal) VALUES (p_negocio, 'Sede principal', 1);
  INSERT INTO usuario (negocio_id, correo, clave_hash, rol_id)
    SELECT p_negocio, p_correo_dueno, p_clave_hash, id FROM rol WHERE clave = 'dueno';

  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Cabello'); SET v_cab = LAST_INSERT_ID();
  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Uñas');    SET v_uni = LAST_INSERT_ID();
  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Barbería');SET v_bar = LAST_INSERT_ID();
  INSERT INTO area (negocio_id, nombre) VALUES (p_negocio,'Cejas');   SET v_cej = LAST_INSERT_ID();

  -- Catálogo base: cabello y barba 30 min, uñas 45 min, cejas 15 min. El dueño ajusta precios.
  INSERT INTO servicio (negocio_id, area_id, nombre, duracion_min, precio, permite_asesoria) VALUES
    (p_negocio, v_cab, 'Corte', 30, 35000, 0),
    (p_negocio, v_cab, 'Color', 30, 80000, 1),
    (p_negocio, v_cab, 'Peinado', 30, 40000, 0),
    (p_negocio, v_uni, 'Tradicional', 45, 30000, 0),
    (p_negocio, v_uni, 'Acrílicas', 45, 70000, 1),
    (p_negocio, v_uni, 'Semipermanentes', 45, 45000, 0),
    (p_negocio, v_bar, 'Barba', 30, 20000, 0),
    (p_negocio, v_cej, 'Cejas', 15, 15000, 0);

  INSERT INTO documento_requerido (negocio_id, nombre, obligatorio, orden) VALUES
    (p_negocio,'Documento de identidad',1,1), (p_negocio,'Afiliación a salud (EPS)',1,2),
    (p_negocio,'Certificado de bioseguridad',1,3), (p_negocio,'Examen médico ocupacional',1,4),
    (p_negocio,'Hoja de vida',0,5);

  INSERT INTO categoria_gasto (negocio_id, nombre) VALUES
    (p_negocio,'Arriendo'), (p_negocio,'Servicios públicos'), (p_negocio,'Insumos'),
    (p_negocio,'Nómina'), (p_negocio,'Publicidad'), (p_negocio,'Otros');
  COMMIT;
END$$

DELIMITER ;
-- =====================================================================
-- CITARA · 04 · Vistas derivadas (lo que se calcula, no se guarda)
-- Incluyen negocio_id: la app las usa a través de las vistas t_* de 05.
-- =====================================================================
SET NAMES utf8mb4;
USE citara;

-- Existencias en bodega por producto y sede.
CREATE OR REPLACE VIEW v_existencia_bodega AS
SELECT p.negocio_id, p.id AS producto_id, s.id AS sede_id, p.nombre AS producto, p.tipo, s.nombre AS sede,
       COALESCE(SUM(m.cantidad), 0) AS existencia, p.stock_minimo
  FROM producto p
  JOIN sede s ON s.negocio_id = p.negocio_id
  LEFT JOIN movimiento_inventario m
         ON m.negocio_id = p.negocio_id AND m.producto_id = p.id AND m.sede_id = s.id
 WHERE p.activo = 1
 GROUP BY p.negocio_id, p.id, s.id, p.nombre, p.tipo, s.nombre, p.stock_minimo;

-- Productos de venta con menos existencias que su mínimo (alerta del inventario).
CREATE OR REPLACE VIEW v_stock_bajo AS
SELECT * FROM v_existencia_bodega WHERE tipo = 'venta' AND existencia < stock_minimo;

-- Lo que cada empleado tiene en la mano, por entrega.
CREATE OR REPLACE VIEW v_en_mano_empleado AS
SELECT e.negocio_id, e.id AS entrega_id, e.empleado_id, e.producto_id, p.nombre AS producto, e.tipo,
       e.cantidad AS entregadas,
       COALESCE((SELECT SUM(d.cantidad) FROM devolucion_entrega d WHERE d.negocio_id = e.negocio_id AND d.entrega_id = e.id), 0) AS devueltas,
       COALESCE((SELECT SUM(v.cantidad) FROM venta_producto v WHERE v.negocio_id = e.negocio_id AND v.entrega_id = e.id), 0) AS vendidas,
       fn_en_mano(e.negocio_id, e.id) AS en_mano
  FROM entrega_interna e JOIN producto p ON p.negocio_id = e.negocio_id AND p.id = e.producto_id;

-- Agenda del día: un renglón por servicio.
CREATE OR REPLACE VIEW v_agenda_dia AS
SELECT c.negocio_id, c.sede_id, c.fecha, cs.id AS cita_servicio_id, c.id AS cita_id,
       cs.inicio, cs.fin, cs.empleado_id, CONCAT(e.nombres,' ',e.apellidos) AS empleado,
       cl.id AS cliente_id, CONCAT(cl.nombres,' ',cl.apellidos) AS cliente,
       s.nombre AS servicio, cs.valor, cs.estado AS estado_servicio, c.estado AS estado_cita
  FROM cita c
  JOIN cita_servicio cs ON cs.negocio_id = c.negocio_id AND cs.cita_id = c.id
  JOIN empleado e  ON e.negocio_id = cs.negocio_id AND e.id = cs.empleado_id
  JOIN cliente cl  ON cl.negocio_id = c.negocio_id AND cl.id = c.cliente_id
  JOIN servicio s  ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id;

-- Dotación: qué piezas debe tener cada empleado según su área y cuántas tiene.
CREATE OR REPLACE VIEW v_estado_dotacion AS
SELECT ea.negocio_id, ea.empleado_id, a.nombre AS area, ad.producto_id, p.nombre AS pieza,
       ad.cantidad AS requerida,
       COALESCE((SELECT SUM(fn_en_mano(e.negocio_id, e.id)) FROM entrega_interna e
                  WHERE e.negocio_id = ea.negocio_id AND e.empleado_id = ea.empleado_id
                    AND e.producto_id = ad.producto_id AND e.tipo = 'dotacion'), 0) AS entregada,
       CASE WHEN COALESCE((SELECT SUM(fn_en_mano(e.negocio_id, e.id)) FROM entrega_interna e
                  WHERE e.negocio_id = ea.negocio_id AND e.empleado_id = ea.empleado_id
                    AND e.producto_id = ad.producto_id AND e.tipo = 'dotacion'), 0) >= ad.cantidad
            THEN 'completa' ELSE 'falta' END AS estado
  FROM empleado_area ea
  JOIN area a ON a.negocio_id = ea.negocio_id AND a.id = ea.area_id
  JOIN area_dotacion ad ON ad.negocio_id = ea.negocio_id AND ad.area_id = ea.area_id
  JOIN producto p ON p.negocio_id = ad.negocio_id AND p.id = ad.producto_id;

-- Ganancia del empleado por ventas a clientes (público - empleado). El uso personal no gana.
CREATE OR REPLACE VIEW v_ganancia_empleado AS
SELECT v.negocio_id, v.empleado_id, DATE_FORMAT(v.fecha, '%Y-%m') AS mes,
       SUM(CASE WHEN v.destino = 'cliente' THEN v.cantidad * (v.precio_cobrado - v.precio_empleado) ELSE 0 END) AS ganancia,
       SUM(CASE WHEN v.destino = 'cliente' THEN v.cantidad * v.precio_empleado ELSE 0 END) AS descuento_ventas,
       SUM(CASE WHEN v.destino = 'uso_personal' THEN v.cantidad * v.precio_empleado ELSE 0 END) AS descuento_personal
  FROM venta_producto v
 WHERE v.empleado_id IS NOT NULL
 GROUP BY v.negocio_id, v.empleado_id, DATE_FORMAT(v.fecha, '%Y-%m');

-- Documentos del empleado: lo subido, lo pendiente y lo que falta subir.
CREATE OR REPLACE VIEW v_expediente_documentos AS
SELECT e.negocio_id, e.id AS empleado_id, dr.id AS documento_requerido_id, dr.nombre, dr.obligatorio, dr.orden,
       ed.id AS empleado_documento_id, ed.subido_en, ed.verificado_en,
       CASE WHEN ed.id IS NULL THEN 'Falta subir' WHEN ed.estado = 'verificado' THEN 'Verificado' ELSE 'Por verificar' END AS estado
  FROM empleado e
  JOIN documento_requerido dr ON dr.negocio_id = e.negocio_id
  LEFT JOIN empleado_documento ed
         ON ed.negocio_id = e.negocio_id AND ed.empleado_id = e.id AND ed.documento_requerido_id = dr.id;
-- =====================================================================
-- CITARA · 05 · Aislamiento entre negocios (reemplazo de RLS)  [GENERADO]
-- Generado por generar_aislamiento.py. No editar a mano.
--
-- La app se conecta SOLO al esquema `citara_app`. Cada vista:
--   * filtra por negocio_id = fn_negocio()  (el tenant de la conexión),
--   * rechaza INSERT/UPDATE de filas de otro negocio (WITH CHECK OPTION).
-- Si la conexión no fijó el tenant (@negocio_id NULL), no ve ni escribe nada.
-- =====================================================================
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS citara_app;
CREATE DATABASE citara_app CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE citara_app;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW `area` AS SELECT `id`, `negocio_id`, `nombre`, `activa` FROM citara.`area` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `area_dotacion` AS SELECT `id`, `negocio_id`, `area_id`, `producto_id`, `cantidad`, `nota` FROM citara.`area_dotacion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `asesoria_chat` AS SELECT `id`, `negocio_id`, `cliente_id`, `cita_id`, `tipo`, `duracion_propuesta_min`, `estado` FROM citara.`asesoria_chat` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `asesoria_mensaje` AS SELECT `id`, `negocio_id`, `chat_id`, `autor`, `texto`, `enviado_en` FROM citara.`asesoria_mensaje` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `asesoria_regla` AS SELECT `id`, `negocio_id`, `servicio_id`, `motivo`, `duracion_min` FROM citara.`asesoria_regla` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `auditoria` AS SELECT `id`, `negocio_id`, `usuario_id`, `entidad`, `entidad_id`, `accion`, `antes`, `despues`, `fecha` FROM citara.`auditoria` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `bloqueo_agenda` AS SELECT `id`, `negocio_id`, `empleado_id`, `inicio`, `fin`, `motivo` FROM citara.`bloqueo_agenda` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `categoria_gasto` AS SELECT `id`, `negocio_id`, `nombre` FROM citara.`categoria_gasto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `cita` AS SELECT `id`, `negocio_id`, `sede_id`, `cliente_id`, `creada_por`, `fecha`, `origen`, `estado`, `notas`, `creada_en` FROM citara.`cita` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `cita_servicio` AS SELECT `id`, `negocio_id`, `cita_id`, `servicio_id`, `empleado_id`, `inicio`, `fin`, `duracion_min`, `valor`, `estado` FROM citara.`cita_servicio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `cliente` AS SELECT `id`, `negocio_id`, `usuario_id`, `nombres`, `apellidos`, `celular`, `correo`, `tipo_documento`, `documento`, `fecha_nacimiento`, `notas`, `acepta_recordatorios`, `origen`, `activo`, `creado_en` FROM citara.`cliente` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `comision` AS SELECT `id`, `negocio_id`, `empleado_id`, `servicio_id`, `porcentaje`, `vigente_desde`, `vigente_hasta` FROM citara.`comision` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `devolucion_entrega` AS SELECT `id`, `negocio_id`, `entrega_id`, `fecha`, `cantidad`, `motivo`, `se_cobra` FROM citara.`devolucion_entrega` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `documento_negocio` AS SELECT `id`, `negocio_id`, `tipo`, `nombre`, `archivo_url`, `subido_en` FROM citara.`documento_negocio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `documento_requerido` AS SELECT `id`, `negocio_id`, `nombre`, `obligatorio`, `orden` FROM citara.`documento_requerido` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado` AS SELECT `id`, `negocio_id`, `usuario_id`, `sede_id`, `tipo_documento`, `documento`, `nombres`, `apellidos`, `fecha_nacimiento`, `celular`, `correo`, `direccion`, `contacto_emergencia`, `telefono_emergencia`, `fecha_ingreso`, `fecha_retiro`, `motivo_retiro`, `periodicidad_pago`, `activo` FROM citara.`empleado` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado_area` AS SELECT `negocio_id`, `empleado_id`, `area_id` FROM citara.`empleado_area` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado_documento` AS SELECT `id`, `negocio_id`, `empleado_id`, `documento_requerido_id`, `archivo_url`, `estado`, `verificado_por`, `subido_en`, `verificado_en` FROM citara.`empleado_documento` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `empleado_servicio` AS SELECT `negocio_id`, `empleado_id`, `servicio_id` FROM citara.`empleado_servicio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `entrega_interna` AS SELECT `id`, `negocio_id`, `producto_id`, `empleado_id`, `entregada_por`, `tipo`, `fecha`, `cantidad`, `precio_unitario`, `estado`, `nota` FROM citara.`entrega_interna` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `factura` AS SELECT `id`, `negocio_id`, `cita_id`, `numero`, `total`, `metodo_pago`, `estado`, `emitida_en` FROM citara.`factura` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `factura_linea` AS SELECT `id`, `negocio_id`, `factura_id`, `cita_servicio_id`, `venta_producto_id`, `empleado_id`, `descripcion`, `valor` FROM citara.`factura_linea` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `gasto` AS SELECT `id`, `negocio_id`, `sede_id`, `categoria_id`, `registrado_por`, `concepto`, `valor`, `fecha` FROM citara.`gasto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `invitacion` AS SELECT `id`, `negocio_id`, `correo`, `rol_id`, `empleado_id`, `creada_por`, `token_hash`, `expira_en`, `estado` FROM citara.`invitacion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `liquidacion` AS SELECT `id`, `negocio_id`, `empleado_id`, `pagado_por`, `periodicidad`, `desde`, `hasta`, `total_comisiones`, `total_descuentos`, `total_neto`, `estado`, `pagado_en` FROM citara.`liquidacion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `liquidacion_detalle` AS SELECT `id`, `negocio_id`, `liquidacion_id`, `cita_servicio_id`, `venta_id`, `devolucion_id`, `tipo`, `descripcion`, `base`, `porcentaje`, `valor` FROM citara.`liquidacion_detalle` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `movimiento_inventario` AS SELECT `id`, `negocio_id`, `producto_id`, `sede_id`, `entrega_id`, `venta_id`, `registrado_por`, `tipo`, `cantidad`, `fecha`, `nota` FROM citara.`movimiento_inventario` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `negocio` AS SELECT `id`, `slug`, `nombre`, `nit`, `plan_id`, `estado`, `zona_horaria`, `moneda`, `ultimo_numero_factura`, `creado_en` FROM citara.negocio WHERE id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `permiso` AS SELECT `id`, `modulo`, `accion` FROM citara.`permiso`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `plan` AS SELECT `id`, `nombre`, `max_sedes`, `max_empleados`, `precio_mensual`, `activo` FROM citara.`plan`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `producto` AS SELECT `id`, `negocio_id`, `nombre`, `tipo`, `codigo`, `unidad`, `costo`, `precio_publico`, `precio_empleado`, `stock_minimo`, `proveedor`, `activo` FROM citara.`producto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `rol` AS SELECT `id`, `clave`, `nombre` FROM citara.`rol`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `rol_permiso` AS SELECT `rol_id`, `permiso_id` FROM citara.`rol_permiso`;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `sede` AS SELECT `id`, `negocio_id`, `nombre`, `direccion`, `ciudad`, `telefono`, `principal`, `activa` FROM citara.`sede` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `sede_horario` AS SELECT `id`, `negocio_id`, `sede_id`, `dia_semana`, `apertura`, `cierre` FROM citara.`sede_horario` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `servicio` AS SELECT `id`, `negocio_id`, `area_id`, `nombre`, `descripcion`, `duracion_min`, `precio`, `permite_asesoria`, `activo` FROM citara.`servicio` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `suscripcion` AS SELECT `id`, `negocio_id`, `plan_id`, `estado`, `inicio`, `fin` FROM citara.`suscripcion` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `televisor` AS SELECT `id`, `negocio_id`, `sede_id`, `nombre`, `token_hash`, `activo` FROM citara.`televisor` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `turno_empleado` AS SELECT `id`, `negocio_id`, `empleado_id`, `sede_id`, `fecha`, `inicio`, `fin` FROM citara.`turno_empleado` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `usuario` AS SELECT `id`, `negocio_id`, `correo`, `clave_hash`, `rol_id`, `activo`, `ultimo_acceso` FROM citara.`usuario` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `usuario_sede` AS SELECT `negocio_id`, `usuario_id`, `sede_id` FROM citara.`usuario_sede` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_agenda_dia` AS SELECT `negocio_id`, `sede_id`, `fecha`, `cita_servicio_id`, `cita_id`, `inicio`, `fin`, `empleado_id`, `empleado`, `cliente_id`, `cliente`, `servicio`, `valor`, `estado_servicio`, `estado_cita` FROM citara.`v_agenda_dia` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_en_mano_empleado` AS SELECT `negocio_id`, `entrega_id`, `empleado_id`, `producto_id`, `producto`, `tipo`, `entregadas`, `devueltas`, `vendidas`, `en_mano` FROM citara.`v_en_mano_empleado` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_estado_dotacion` AS SELECT `negocio_id`, `empleado_id`, `area`, `producto_id`, `pieza`, `requerida`, `entregada`, `estado` FROM citara.`v_estado_dotacion` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_existencia_bodega` AS SELECT `negocio_id`, `producto_id`, `sede_id`, `producto`, `tipo`, `sede`, `existencia`, `stock_minimo` FROM citara.`v_existencia_bodega` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_expediente_documentos` AS SELECT `negocio_id`, `empleado_id`, `documento_requerido_id`, `nombre`, `obligatorio`, `orden`, `empleado_documento_id`, `subido_en`, `verificado_en`, `estado` FROM citara.`v_expediente_documentos` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_ganancia_empleado` AS SELECT `negocio_id`, `empleado_id`, `mes`, `ganancia`, `descuento_ventas`, `descuento_personal` FROM citara.`v_ganancia_empleado` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `v_stock_bajo` AS SELECT `negocio_id`, `producto_id`, `sede_id`, `producto`, `tipo`, `sede`, `existencia`, `stock_minimo` FROM citara.`v_stock_bajo` WHERE negocio_id = citara.fn_negocio();
CREATE OR REPLACE SQL SECURITY DEFINER VIEW `venta_producto` AS SELECT `id`, `negocio_id`, `producto_id`, `empleado_id`, `entrega_id`, `cliente_id`, `cita_id`, `fecha`, `cantidad`, `destino`, `precio_cobrado`, `precio_empleado` FROM citara.`venta_producto` WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;

-- Rutinas que la app puede usar. El negocio NUNCA es un parámetro: sale de la conexión.
DELIMITER $$
CREATE PROCEDURE sp_set_negocio(IN p_negocio BIGINT UNSIGNED) BEGIN CALL citara.sp_set_negocio(p_negocio); END$$
CREATE PROCEDURE sp_limpiar_negocio() BEGIN CALL citara.sp_limpiar_negocio(); END$$
CREATE PROCEDURE sp_emitir_factura(IN p_cita BIGINT UNSIGNED, IN p_metodo VARCHAR(15), OUT p_factura BIGINT UNSIGNED)
BEGIN
  IF citara.fn_negocio() IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Falta fijar el negocio de la conexión'; END IF;
  CALL citara.sp_emitir_factura(citara.fn_negocio(), p_cita, p_metodo, p_factura);
END$$
DELIMITER ;

-- =====================================================================
-- CITARA · 06 · Usuarios de la base de datos
-- CAMBIAR las claves antes de usar fuera de una máquina local.
--   citara_app   → la aplicación. Solo ve el esquema citara_app (aislado por negocio).
--   citara_admin → la plataforma (altas de negocios, soporte). Ve todo; nunca desde la web pública.
-- =====================================================================
SET NAMES utf8mb4;
CREATE USER IF NOT EXISTS 'citara_app'@'%'   IDENTIFIED BY 'CAMBIAR_clave_app_1';
CREATE USER IF NOT EXISTS 'citara_admin'@'%' IDENTIFIED BY 'CAMBIAR_clave_admin_1';

GRANT SELECT, INSERT, UPDATE, DELETE ON citara_app.* TO 'citara_app'@'%';
GRANT EXECUTE ON citara_app.* TO 'citara_app'@'%';
-- La app NO tiene permisos sobre el esquema `citara`: no puede saltarse las vistas.

GRANT ALL PRIVILEGES ON citara.*     TO 'citara_admin'@'%';
GRANT ALL PRIVILEGES ON citara_app.* TO 'citara_admin'@'%';
FLUSH PRIVILEGES;
