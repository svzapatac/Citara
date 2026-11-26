<?php

$conexion = new mysqli("sql106.infinityfree.com", "if0_42524756", "Cocomusa1224", "if0_42524756_citara",3306);

if ($conexion->connect_error) {
    die("Error de conexión: " . $conexion->connect_error);
}

?>