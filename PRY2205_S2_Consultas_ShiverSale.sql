/*
  PRY2205 - Consulta de Bases de Datos
  Semana 2 - Creando consultas utilizando funciones SQL
  Caso: ShiverSale
  Usuario: PRY2205_S2  |  Conexión: PRY2205_ACTIVIDAD_S2
  Nombre: Juan Miranda
*/

SET VERIFY OFF

/* ============================================================
   CASO 1: Análisis de Facturas
   - Solo facturas del año anterior al año de ejecución
   - Orden: fecha DESC, monto neto DESC
   ============================================================ */
SELECT
    numfactura                                                        AS "N° Factura",
    TO_CHAR(fecha, 'DD "de" Month YYYY', 'NLS_DATE_LANGUAGE=SPANISH') AS "Fecha Emisión",
    LPAD(rutcliente, 10, '0')                                         AS "RUT Cliente",
    TO_CHAR(neto,  'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Monto Neto",
    TO_CHAR(iva,   'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Monto Iva",
    TO_CHAR(total, 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "Total Factura",
    CASE
        WHEN total <= 50000  THEN 'Bajo'
        WHEN total <= 100000 THEN 'Medio'
        ELSE 'Alto'
    END                                                               AS "Categoría Monto",
    CASE codpago
        WHEN 1 THEN 'EFECTIVO'
        WHEN 2 THEN 'TARJETA DEBITO'
        WHEN 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END                                                               AS "Forma de pago"
FROM factura
WHERE EXTRACT(YEAR FROM fecha) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY fecha DESC, neto DESC;


/* ============================================================
   CASO 2: Clasificación de Clientes
   - Clientes con estado 'A' y crédito > 0
   - Orden: nombre ASC
   ============================================================ */
SELECT
    LPAD(rutcliente, 12, '*')                         AS "RUT",
    INITCAP(nombre)                                   AS "Cliente",
    NVL(TO_CHAR(telefono), 'Sin teléfono')            AS "TELÉFONO",
    NVL(TO_CHAR(codcomuna), 'Sin comuna')             AS "COMUNA",
    estado                                            AS "ESTADO",
    CASE
        WHEN saldo / credito < 0.5 THEN
            'Bueno (' || TO_CHAR(credito - saldo, '$9G999G999',
                                 'NLS_NUMERIC_CHARACTERS='',.''') || ')'
        WHEN saldo / credito <= 0.8 THEN
            'Regular (' || TO_CHAR(saldo, '$9G999G999',
                                   'NLS_NUMERIC_CHARACTERS='',.''') || ')'
        ELSE 'Crítico'
    END                                               AS "Estado Crédito",
    CASE
        WHEN mail IS NULL THEN 'Correo no registrado'
        ELSE UPPER(SUBSTR(mail, INSTR(mail, '@') + 1))
    END                                               AS "Dominio Correo"
FROM cliente
WHERE estado = 'A'
  AND credito > 0
ORDER BY nombre ASC;


/* ============================================================
   CASO 3: Stock de Productos
   Variables de sustitución (se piden al ejecutar):
     TIPOCAMBIO_DOLAR, UMBRAL_BAJO, UMBRAL_ALTO
   - Solo productos con 'zapato' en la descripción y procedencia 'I'
   - Orden: codproducto DESC
   ============================================================ */
SELECT
    codproducto                                       AS "ID",
    INITCAP(descripcion)                              AS "Descripción de Producto",
    CASE
        WHEN valorcompradolar IS NULL THEN 'Sin registro'
        ELSE RTRIM(TO_CHAR(valorcompradolar, 'FM990D99',
                           'NLS_NUMERIC_CHARACTERS='',.'''), ',') || ' USD'
    END                                               AS "Compra en USD",
    CASE
        WHEN valorcompradolar IS NULL THEN 'Sin registro'
        ELSE TO_CHAR(ROUND(valorcompradolar * &&TIPOCAMBIO_DOLAR),
                     'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') || ' PESOS'
    END                                               AS "USD convertido",
    totalstock                                        AS "Stock",
    CASE
        WHEN totalstock IS NULL            THEN 'Sin datos'
        WHEN totalstock < &&UMBRAL_BAJO    THEN '¡ALERTA stock muy bajo!'
        WHEN totalstock <= &&UMBRAL_ALTO   THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END                                               AS "Alerta Stock",
    CASE
        WHEN totalstock > 80 THEN
            TO_CHAR(ROUND(vunitario * 0.9), 'FM$999G999G999',
                    'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE 'N/A'
    END                                               AS "Precio Oferta"
FROM producto
WHERE UPPER(descripcion) LIKE '%ZAPATO%'
  AND procedencia = 'I'
ORDER BY codproducto DESC;
