#!/usr/bin/env bash
# Instala la base de datos de Citara en un MySQL 8.0.16+.
# Uso:        ./instalar.sh                 (usuario root, sin clave)
#             MYSQL_PWD='clave' ./instalar.sh usuario
#             CON_DEMO=1 ./instalar.sh      (agrega datos de demo y corre las pruebas)
# ¡Borra y recrea las bases `citara` y `citara_app`!
set -euo pipefail
cd "$(dirname "$0")"
U="${1:-root}"
run() { echo ">> $1"; mysql -u"$U" --default-character-set=utf8mb4 < "$1"; }
run 01_esquema.sql
run 02_datos_base.sql
run 03_logica.sql
run 04_vistas_derivadas.sql
run 05_aislamiento_tenant.sql
run 06_roles.sql
if [ "${CON_DEMO:-0}" = "1" ]; then
  run 07_datos_demo.sql
  echo ">> 08_pruebas.sql"; mysql -u"$U" --force --default-character-set=utf8mb4 -t < 08_pruebas.sql 2>&1 | grep -E "OK|FALLA|ERROR" || true
fi
echo "Listo: base citara (+ citara_app para la aplicación)."
