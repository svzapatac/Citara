#!/usr/bin/env python3
"""Genera 05_aislamiento_tenant.sql: el esquema `citara_app` con una vista por tabla
del cliente, filtrada por negocio_id = fn_negocio() y con WITH CHECK OPTION.
Es el reemplazo de RLS de PostgreSQL en MySQL. Uso: python3 generar_aislamiento.py
(requiere el esquema `citara` ya creado y el cliente `mysql` en el PATH)."""
import subprocess

def q(sql):
    out = subprocess.run(["mysql", "-uroot", "-N", "-B", "-e", sql], capture_output=True, text=True, check=True).stdout
    return [l.split("\t") for l in out.strip().splitlines()]

cols = {}
for t, c in q("SELECT table_name, column_name FROM information_schema.columns "
              "WHERE table_schema='citara' ORDER BY table_name, ordinal_position"):
    cols.setdefault(t, []).append(c)
tables = {t for (t,) in q("SELECT table_name FROM information_schema.tables WHERE table_schema='citara' AND table_type='BASE TABLE'")}
views = {t for (t,) in q("SELECT table_name FROM information_schema.views WHERE table_schema='citara'")}
GLOBAL = {"plan", "rol", "permiso", "rol_permiso"}          # catálogos globales: solo lectura
SOLO_PLATAFORMA = {"admin_plataforma"}                       # nunca visibles para la app
out = ["""-- =====================================================================
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
CREATE DATABASE citara_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE citara_app;
"""]
for t in sorted(tables | views):
    if t in SOLO_PLATAFORMA: continue
    cl = ", ".join(f"`{c}`" for c in cols[t])
    if t in GLOBAL:
        out.append(f"CREATE OR REPLACE SQL SECURITY DEFINER VIEW `{t}` AS SELECT {cl} FROM citara.`{t}`;")
    elif t == "negocio":
        out.append(f"CREATE OR REPLACE SQL SECURITY DEFINER VIEW `negocio` AS SELECT {cl} FROM citara.negocio WHERE id = citara.fn_negocio();")
    elif t in views:
        out.append(f"CREATE OR REPLACE SQL SECURITY DEFINER VIEW `{t}` AS SELECT {cl} FROM citara.`{t}` WHERE negocio_id = citara.fn_negocio();")
    else:
        out.append(f"CREATE OR REPLACE SQL SECURITY DEFINER VIEW `{t}` AS SELECT {cl} FROM citara.`{t}` "
                   f"WHERE negocio_id = citara.fn_negocio() WITH CHECK OPTION;")
out.append("""
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
""")
open("05_aislamiento_tenant.sql", "w").write("\n".join(out) + "\n")
print(len(tables | views) - len(SOLO_PLATAFORMA), "vistas")
