<?php
// =====================================================================
// CITARA · Reglas del negocio en PHP (funcionan aunque el hosting no
// permita disparadores). Se incluye con: require_once 'modelo.php';
// Todas reciben el negocio ($neg) y filtran por él.
// =====================================================================
require_once __DIR__ . '/lib.php';

/** Valida un servicio de una cita. Devuelve un texto de error o null si está bien. */
function validar_servicio_cita($neg, $citaId, $servicioId, $empId, $ini, $fin, $excluirId = 0) {
    $cita = q_row("SELECT fecha, sede_id FROM cita WHERE negocio_id = ? AND id = ?", [$neg, $citaId]);
    if (!$cita) return 'La cita no existe.';
    if (date('Y-m-d', strtotime($ini)) !== date('Y-m-d', strtotime($fin))) return 'El servicio debe empezar y terminar el mismo día.';
    if ($cita['fecha'] !== date('Y-m-d', strtotime($ini))) return 'El servicio no coincide con la fecha de la cita.';
    if (!q_val("SELECT 1 FROM empleado WHERE negocio_id = ? AND id = ? AND activo = 1", [$neg, $empId])) return 'El empleado no está activo.';
    if (!q_val("SELECT 1 FROM empleado_servicio WHERE negocio_id = ? AND empleado_id = ? AND servicio_id = ?", [$neg, $empId, $servicioId]))
        return 'El empleado no está habilitado para este servicio.';
    $f = date('Y-m-d', strtotime($ini)); $hi = date('H:i:s', strtotime($ini)); $hf = date('H:i:s', strtotime($fin));
    if (!q_val("SELECT 1 FROM turno_empleado WHERE negocio_id = ? AND empleado_id = ? AND sede_id = ? AND fecha = ? AND inicio <= ? AND fin >= ?",
               [$neg, $empId, (int)$cita['sede_id'], $f, $hi, $hf])) return 'El horario queda fuera de los turnos del empleado.';
    if (q_val("SELECT 1 FROM cita_servicio WHERE negocio_id = ? AND empleado_id = ? AND estado <> 'cancelado' AND id <> ? AND inicio < ? AND fin > ?",
              [$neg, $empId, $excluirId, $fin, $ini])) return 'El empleado ya tiene una cita en ese horario.';
    if (q_val("SELECT 1 FROM bloqueo_agenda WHERE negocio_id = ? AND empleado_id = ? AND inicio < ? AND fin > ?", [$neg, $empId, $fin, $ini]))
        return 'El horario está bloqueado en la agenda del empleado.';
    return null;
}

/** Siguiente hueco libre de un empleado ese día para un servicio de $min minutos, desde $desde (H:i). */
function proximo_hueco($neg, $empId, $sedeId, $fecha, $min, $desde) {
    $turnos = q_all("SELECT inicio, fin FROM turno_empleado WHERE negocio_id = ? AND empleado_id = ? AND sede_id = ? AND fecha = ? ORDER BY inicio", [$neg, $empId, $sedeId, $fecha]);
    $ocupado = q_all("SELECT inicio, fin FROM cita_servicio WHERE negocio_id = ? AND empleado_id = ? AND estado <> 'cancelado' AND DATE(inicio) = ? ORDER BY inicio", [$neg, $empId, $fecha]);
    foreach ($turnos as $t) {
        $cur = max(strtotime("$fecha $desde"), strtotime("$fecha {$t['inicio']}"));
        $finT = strtotime("$fecha {$t['fin']}");
        foreach ($ocupado as $o) {
            $oi = strtotime($o['inicio']); $of = strtotime($o['fin']);
            if ($cur + $min * 60 <= $oi) break;
            if ($of > $cur) $cur = $of;
        }
        if ($cur + $min * 60 <= $finT) return date('H:i', $cur);
    }
    return null;
}

/** Cuántas unidades tiene todavía el empleado de una entrega. */
function en_mano($neg, $entregaId) {
    return (int)q_val("SELECT e.cantidad
        - COALESCE((SELECT SUM(d.cantidad) FROM devolucion_entrega d WHERE d.negocio_id = e.negocio_id AND d.entrega_id = e.id), 0)
        - COALESCE((SELECT SUM(v.cantidad) FROM venta_producto v WHERE v.negocio_id = e.negocio_id AND v.entrega_id = e.id), 0)
        FROM entrega_interna e WHERE e.negocio_id = ? AND e.id = ?", [$neg, $entregaId]);
}

/** Existencias de un producto en la bodega de una sede (suma del libro de movimientos). */
function stock_bodega($neg, $productoId, $sedeId) {
    return (int)q_val("SELECT COALESCE(SUM(cantidad), 0) FROM movimiento_inventario WHERE negocio_id = ? AND producto_id = ? AND sede_id = ?", [$neg, $productoId, $sedeId]);
}

/** Registra un movimiento del libro de inventario (nunca deja la bodega en negativo). */
function mover_inventario($neg, $productoId, $sedeId, $tipo, $cantidad, $usuarioId = null, $entregaId = null, $ventaId = null, $nota = null) {
    if ($cantidad < 0 && stock_bodega($neg, $productoId, $sedeId) + $cantidad < 0) throw new RuntimeException('No hay existencias suficientes en la bodega.');
    q_run("INSERT INTO movimiento_inventario (negocio_id, producto_id, sede_id, entrega_id, venta_id, registrado_por, tipo, cantidad, nota) VALUES (?,?,?,?,?,?,?,?,?)",
          [$neg, $productoId, $sedeId, $entregaId, $ventaId, $usuarioId, $tipo, $cantidad, $nota]);
}

/** Porcentaje de comisión vigente de un empleado para un servicio (el específico gana al general). */
function comision_pct($neg, $empId, $servicioId, $fecha) {
    $r = q_val("SELECT porcentaje FROM comision WHERE negocio_id = ? AND empleado_id = ? AND vigente_desde <= ? AND (vigente_hasta IS NULL OR vigente_hasta >= ?)
                AND (servicio_id = ? OR servicio_id IS NULL) ORDER BY servicio_id IS NULL, vigente_desde DESC LIMIT 1",
               [$neg, $empId, $fecha, $fecha, $servicioId]);
    return $r === null ? 0.0 : (float)$r;
}

/** Emite la factura de una cita con consecutivo por negocio. Devuelve el id de la factura. */
function emitir_factura($neg, $citaId, $metodo = 'efectivo') {
    global $conexion;
    $conexion->begin_transaction();
    try {
        if (q_val("SELECT 1 FROM factura WHERE negocio_id = ? AND cita_id = ?", [$neg, $citaId])) throw new RuntimeException('La cita ya tiene factura.');
        if (!q_val("SELECT 1 FROM cita_servicio WHERE negocio_id = ? AND cita_id = ? AND estado = 'realizado'", [$neg, $citaId]))
            throw new RuntimeException('Marca primero los servicios como realizados.');
        q_run("UPDATE negocio SET ultimo_numero_factura = ultimo_numero_factura + 1 WHERE id = ?", [$neg]);   // bloquea la fila: sin números repetidos
        $num = (int)q_val("SELECT ultimo_numero_factura FROM negocio WHERE id = ?", [$neg]);
        $fid = q_insert("INSERT INTO factura (negocio_id, cita_id, numero, total, metodo_pago) VALUES (?,?,?,0,?)", [$neg, $citaId, $num, $metodo]);
        q_run("INSERT INTO factura_linea (negocio_id, factura_id, cita_servicio_id, empleado_id, descripcion, valor)
               SELECT cs.negocio_id, ?, cs.id, cs.empleado_id, s.nombre, cs.valor FROM cita_servicio cs
               JOIN servicio s ON s.negocio_id = cs.negocio_id AND s.id = cs.servicio_id
               WHERE cs.negocio_id = ? AND cs.cita_id = ? AND cs.estado = 'realizado'", [$fid, $neg, $citaId]);
        q_run("INSERT INTO factura_linea (negocio_id, factura_id, venta_producto_id, empleado_id, descripcion, valor)
               SELECT v.negocio_id, ?, v.id, v.empleado_id, p.nombre, v.cantidad * v.precio_cobrado FROM venta_producto v
               JOIN producto p ON p.negocio_id = v.negocio_id AND p.id = v.producto_id
               WHERE v.negocio_id = ? AND v.cita_id = ? AND v.destino = 'cliente'", [$fid, $neg, $citaId]);
        $total = q_val("SELECT COALESCE(SUM(valor), 0) FROM factura_linea WHERE negocio_id = ? AND factura_id = ?", [$neg, $fid]);
        q_run("UPDATE factura SET total = ? WHERE negocio_id = ? AND id = ?", [(float)$total, $neg, $fid]);
        q_run("UPDATE cita SET estado = 'finalizada' WHERE negocio_id = ? AND id = ?", [$neg, $citaId]);
        $conexion->commit();
        return $fid;
    } catch (Throwable $e) { $conexion->rollback(); throw $e; }
}

/** Resumen de documentos del expediente de un empleado: [verificados, por_verificar, faltan]. */
function resumen_documentos($neg, $empId) {
    $r = q_row("SELECT
        SUM(ed.estado = 'verificado') AS ok, SUM(ed.id IS NOT NULL AND ed.estado <> 'verificado') AS por, SUM(ed.id IS NULL) AS falta, COUNT(*) AS total
        FROM documento_requerido dr LEFT JOIN empleado_documento ed ON ed.negocio_id = dr.negocio_id AND ed.documento_requerido_id = dr.id AND ed.empleado_id = ?
        WHERE dr.negocio_id = ?", [$empId, $neg]);
    return ['ok' => (int)$r['ok'], 'por' => (int)$r['por'], 'falta' => (int)$r['falta'], 'total' => (int)$r['total']];
}

/** Estado de la dotación de un empleado: [piezas_requeridas, piezas_completas, faltan]. */
function resumen_dotacion($neg, $empId) {
    $filas = q_all("SELECT ad.producto_id, ad.cantidad,
        COALESCE((SELECT SUM(e.cantidad - COALESCE((SELECT SUM(d.cantidad) FROM devolucion_entrega d WHERE d.negocio_id = e.negocio_id AND d.entrega_id = e.id), 0))
                  FROM entrega_interna e WHERE e.negocio_id = ea.negocio_id AND e.empleado_id = ea.empleado_id AND e.producto_id = ad.producto_id AND e.tipo = 'dotacion'), 0) AS entregada
        FROM empleado_area ea JOIN area_dotacion ad ON ad.negocio_id = ea.negocio_id AND ad.area_id = ea.area_id
        WHERE ea.negocio_id = ? AND ea.empleado_id = ?", [$neg, $empId]);
    $falta = 0; foreach ($filas as $f) if ((int)$f['entregada'] < (int)$f['cantidad']) $falta++;
    return ['total' => count($filas), 'falta' => $falta];
}

/** ¿La base ya trae los disparadores de inventario (03_logica.sql)? Si sí, ellos mueven la bodega. */
function hay_triggers() {
    static $r = null;
    if ($r === null) $r = (int)q_val("SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = DATABASE() AND trigger_name = 'trg_entrega_ai'") > 0;
    return $r;
}
