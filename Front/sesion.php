<?php
// Pon require_once __DIR__ . '/sesion.php'; al inicio de cada página privada
session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: index.php');
    exit;
}