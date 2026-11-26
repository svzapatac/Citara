-- ============================================================
--  Citara · Ajuste para usar TU tabla `negocio`
--  Ejecútalo completo en phpMyAdmin → pestaña SQL.
--  Se puede correr más de una vez sin dañar nada.
-- ============================================================

-- 1. Tu tabla negocio: se le agregan tipo y logo (los pide el paso 2)
ALTER TABLE negocio
  ADD COLUMN IF NOT EXISTS tipo VARCHAR(40)  NULL AFTER nit,
  ADD COLUMN IF NOT EXISTS logo VARCHAR(255) NULL AFTER tipo;

-- 2. Tablas que cuelgan del negocio (se crean solo si no existen)
CREATE TABLE IF NOT EXISTS sedes (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id     BIGINT UNSIGNED NOT NULL,
  nombre         VARCHAR(120)    NOT NULL,
  ciudad         VARCHAR(80)     NOT NULL,
  direccion      VARCHAR(160)    NOT NULL,
  dias_atencion  VARCHAR(20)     NOT NULL COMMENT '1=Lun ... 7=Dom, separados por coma',
  hora_abre      TIME            NOT NULL,
  hora_cierra    TIME            NOT NULL,
  activo         TINYINT(1)      NOT NULL DEFAULT 1,
  creado_en      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sedes_negocio (negocio_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usuarios (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id        BIGINT UNSIGNED NOT NULL,
  sede_id           BIGINT UNSIGNED NULL,
  nombres           VARCHAR(80)     NOT NULL,
  apellidos         VARCHAR(80)     NOT NULL,
  tipo_documento    VARCHAR(30)     NOT NULL,
  numero_documento  VARCHAR(20)     NOT NULL,
  celular           VARCHAR(20)     NOT NULL,
  correo            VARCHAR(160)    NOT NULL,
  clave_hash        VARCHAR(255)    NOT NULL,
  rol               ENUM('dueno','administrador','empleado') NOT NULL DEFAULT 'empleado',
  activo            TINYINT(1)      NOT NULL DEFAULT 1,
  creado_en         TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_correo (correo),
  KEY idx_usuarios_negocio (negocio_id),
  KEY idx_usuarios_sede (sede_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS servicios (
  id            BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  negocio_id    BIGINT UNSIGNED   NOT NULL,
  categoria     VARCHAR(60)       NOT NULL,
  nombre        VARCHAR(100)      NOT NULL,
  duracion_min  SMALLINT UNSIGNED NOT NULL,
  precio        INT UNSIGNED      NOT NULL DEFAULT 0 COMMENT 'En pesos, sin decimales',
  activo        TINYINT(1)        NOT NULL DEFAULT 1,
  creado_en     TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_servicios_negocio (negocio_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Las relaciones ahora apuntan a TU tabla `negocio`
--    (antes apuntaban a `negocios`, la tabla de prueba en plural)
ALTER TABLE sedes     DROP FOREIGN KEY IF EXISTS fk_sedes_negocio;
ALTER TABLE usuarios  DROP FOREIGN KEY IF EXISTS fk_usuarios_negocio;
ALTER TABLE usuarios  DROP FOREIGN KEY IF EXISTS fk_usuarios_sede;
ALTER TABLE servicios DROP FOREIGN KEY IF EXISTS fk_servicios_negocio;

ALTER TABLE sedes     ADD CONSTRAINT fk_sedes_negocio     FOREIGN KEY (negocio_id) REFERENCES negocio (id) ON DELETE CASCADE;
ALTER TABLE usuarios  ADD CONSTRAINT fk_usuarios_negocio  FOREIGN KEY (negocio_id) REFERENCES negocio (id) ON DELETE CASCADE;
ALTER TABLE usuarios  ADD CONSTRAINT fk_usuarios_sede     FOREIGN KEY (sede_id)    REFERENCES sedes (id)   ON DELETE SET NULL;
ALTER TABLE servicios ADD CONSTRAINT fk_servicios_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id) ON DELETE CASCADE;

-- 4. La tabla de prueba `negocios` (en plural) ya no se usa
DROP TABLE IF EXISTS negocios;