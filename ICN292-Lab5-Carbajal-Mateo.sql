-- ICN-292 Sistemas de Información para la Gestión — Laboratorio 5 (SQL 2/2)
-- Base: andesbike (Andes Bike)
-- Ejecutable de principio a fin sobre una base vacía.

DROP DATABASE IF EXISTS andesbike;
CREATE DATABASE andesbike CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE andesbike;

-- =====================================================
-- ENTREGABLE 1: CREACIÓN DE TABLAS
-- =====================================================

CREATE TABLE tiendas (
    id_tienda INT          NOT NULL AUTO_INCREMENT,
    nombre    VARCHAR(60)  NOT NULL,
    comuna    VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id_tienda)
) ENGINE=InnoDB;

CREATE TABLE vendedores (
    id_vendedor   INT          NOT NULL AUTO_INCREMENT,
    nombre        VARCHAR(80)  NOT NULL,
    id_tienda     INT          NULL,           -- Rubén Castro no tiene tienda (NULL)
    fecha_ingreso DATE         NOT NULL,
    PRIMARY KEY (id_vendedor),
    CONSTRAINT fk_vendedores_tiendas
        FOREIGN KEY (id_tienda) REFERENCES tiendas (id_tienda)
) ENGINE=InnoDB;

CREATE TABLE bicicletas (
    id_bicicleta INT            NOT NULL AUTO_INCREMENT,
    modelo       VARCHAR(60)    NOT NULL,
    categoria    ENUM('Eléctrica','Infantil','Montaña','Ruta','Urbana') NOT NULL,
    precio       DECIMAL(10,2)  NOT NULL,
    PRIMARY KEY (id_bicicleta),
    CONSTRAINT chk_precio_positivo CHECK (precio > 0)
) ENGINE=InnoDB;

CREATE TABLE ventas (
    id_venta     INT   NOT NULL AUTO_INCREMENT,
    id_vendedor  INT   NOT NULL,
    id_bicicleta INT   NOT NULL,
    fecha        DATE  NOT NULL,
    unidades     INT   NOT NULL,
    PRIMARY KEY (id_venta),
    CONSTRAINT fk_ventas_vendedores
        FOREIGN KEY (id_vendedor)  REFERENCES vendedores (id_vendedor),
    CONSTRAINT fk_ventas_bicicletas
        FOREIGN KEY (id_bicicleta) REFERENCES bicicletas (id_bicicleta),
    CONSTRAINT chk_unidades_positivas CHECK (unidades > 0)
) ENGINE=InnoDB;

-- =====================================================
-- CARGA OFICIAL
-- =====================================================

INSERT INTO tiendas (id_tienda, nombre, comuna) VALUES
(1, 'Andes Providencia', 'Providencia'),
(2, 'Andes Maipú',       'Maipú'),
(3, 'Andes Concepción',  'Concepción'),
(4, 'Andes La Serena',   'La Serena');

INSERT INTO vendedores (id_vendedor, nombre, id_tienda, fecha_ingreso) VALUES
(1, 'Camila Ortiz',    1,    '2024-06-20'),
(2, 'Diego Fuentes',   1,    '2024-01-15'),
(3, 'Javiera Soto',    2,    '2023-07-24'),
(4, 'Matías Herrera',  2,    '2024-01-15'),
(5, 'Paula Riquelme',  3,    '2022-11-02'),
(6, 'Ignacio Vera',    3,    '2024-08-19'),
(7, 'Fernanda Lillo',  1,    '2025-02-03'),
(8, 'Rubén Castro',    NULL, '2025-06-10');

INSERT INTO bicicletas (id_bicicleta, modelo, categoria, precio) VALUES
(1, 'Cordillera 29',  'Montaña',   549900.00),
(2, 'Ruta Austral',   'Ruta',      899900.00),
(3, 'Urbana Pro',     'Urbana',    329900.00),
(4, 'Pequeño Andes',  'Infantil',  149900.00),
(5, 'Volt City',      'Eléctrica', 1249900.00),
(6, 'Trail Master',   'Montaña',   749900.00),
(7, 'Urbana Lite',    'Urbana',    229900.00),
(8, 'Sprint R7',      'Ruta',      1099900.00);

INSERT INTO ventas (id_venta, id_vendedor, id_bicicleta, fecha, unidades) VALUES
( 1, 1, 1, '2025-03-04', 2),
( 2, 1, 3, '2025-03-18', 1),
( 3, 1, 5, '2025-04-02', 1),
( 4, 2, 2, '2025-03-04', 1),
( 5, 2, 1, '2025-04-11', 3),
( 6, 2, 7, '2025-05-06', 2),
( 7, 3, 4, '2025-03-21', 4),
( 8, 3, 3, '2025-04-15', 2),
( 9, 3, 6, '2025-05-20', 1),
(10, 4, 1, '2025-03-27', 1),
(11, 4, 5, '2025-05-09', 2),
(12, 5, 2, '2025-04-08', 1),
(13, 5, 6, '2025-04-23', 2),
(14, 5, 4, '2025-06-02', 5),
(15, 6, 3, '2025-05-13', 3),
(16, 6, 7, '2025-06-17', 1),
(17, 6, 1, '2025-06-24', 2),
(18, 1, 6, '2025-06-30', 1);

-- Control: debe dar 18 ventas, 35 unidades y monto 16966500
-- SELECT COUNT(*), SUM(unidades), SUM(v.unidades * b.precio)
-- FROM ventas v JOIN bicicletas b ON b.id_bicicleta = v.id_bicicleta;

-- =====================================================
-- ENTREGABLE 2: CONSULTAS
-- =====================================================

-- Consulta 1: todos los vendedores con su cantidad de ventas (0 si no tienen)
SELECT ve.nombre,
       COUNT(v.id_venta) AS cantidad_ventas
FROM vendedores ve
LEFT JOIN ventas v ON v.id_vendedor = ve.id_vendedor
GROUP BY ve.id_vendedor, ve.nombre
ORDER BY cantidad_ventas DESC, ve.nombre ASC;

-- Consulta 2: por tienda, ventas registradas y unidades vendidas (incluye tiendas sin vendedores)
SELECT t.nombre,
       COUNT(v.id_venta)            AS cantidad_ventas,
       COALESCE(SUM(v.unidades), 0) AS unidades_vendidas
FROM tiendas t
LEFT JOIN vendedores ve ON ve.id_tienda   = t.id_tienda
LEFT JOIN ventas v      ON v.id_vendedor  = ve.id_vendedor
GROUP BY t.id_tienda, t.nombre
ORDER BY unidades_vendidas DESC;

-- Consulta 3: tiendas sin ningún vendedor asignado
SELECT t.nombre
FROM tiendas t
LEFT JOIN vendedores ve ON ve.id_tienda = t.id_tienda
WHERE ve.id_vendedor IS NULL;

-- Consulta 4: modelos que no se vendieron ni una vez en junio de 2025
-- La condición del mes va en el ON del LEFT JOIN (no en el WHERE).
SELECT b.modelo
FROM bicicletas b
LEFT JOIN ventas v
       ON v.id_bicicleta = b.id_bicicleta
      AND v.fecha >= '2025-06-01'
      AND v.fecha <  '2025-07-01'
WHERE v.id_venta IS NULL
ORDER BY b.modelo;

-- Consulta 5: vendedores sin ventas, con el nombre de su tienda (Rubén no tiene tienda)
SELECT ve.nombre AS vendedor,
       t.nombre  AS tienda
FROM vendedores ve
LEFT JOIN tiendas t ON t.id_tienda    = ve.id_tienda
LEFT JOIN ventas v  ON v.id_vendedor  = ve.id_vendedor
WHERE v.id_venta IS NULL;

-- Consulta 6: pares de vendedores de la misma tienda (primero el que ingresó antes), cada par una vez
SELECT a.nombre AS vendedor_1,
       b.nombre AS vendedor_2,
       a.fecha_ingreso AS ingreso_1,
       b.fecha_ingreso AS ingreso_2,
       t.nombre AS tienda
FROM vendedores a
JOIN vendedores b
  ON  a.id_tienda = b.id_tienda
  AND (a.fecha_ingreso < b.fecha_ingreso
       OR (a.fecha_ingreso = b.fecha_ingreso AND a.id_vendedor < b.id_vendedor))
JOIN tiendas t ON t.id_tienda = a.id_tienda
ORDER BY t.nombre, a.fecha_ingreso, b.fecha_ingreso;

-- Consulta 7: monto vendido por tienda en categorías Montaña y Ruta, solo > 2.000.000
SELECT t.nombre,
       SUM(v.unidades * b.precio) AS monto_total
FROM tiendas t
JOIN vendedores ve ON ve.id_tienda    = t.id_tienda
JOIN ventas v      ON v.id_vendedor   = ve.id_vendedor
JOIN bicicletas b  ON b.id_bicicleta  = v.id_bicicleta
WHERE b.categoria IN ('Montaña', 'Ruta')
GROUP BY t.id_tienda, t.nombre
HAVING SUM(v.unidades * b.precio) > 2000000
ORDER BY monto_total DESC;

-- Consulta 8: modelos con precio sobre el promedio del catálogo
-- El promedio sale de AVG(precio) sobre la tabla bicicletas (subconsulta): 657.400
SELECT modelo, precio
FROM bicicletas
WHERE precio > (SELECT AVG(precio) FROM bicicletas)
ORDER BY precio DESC;

-- Consulta 9: vendedores cuyo promedio de unidades por venta supera el de toda la cadena
-- Promedio de la cadena: AVG(unidades) sobre todas las ventas = 35/18 ≈ 1,9444
SELECT ve.nombre,
       AVG(v.unidades) AS promedio_unidades
FROM vendedores ve
JOIN ventas v ON v.id_vendedor = ve.id_vendedor
GROUP BY ve.id_vendedor, ve.nombre
HAVING AVG(v.unidades) > (SELECT AVG(unidades) FROM ventas)
ORDER BY promedio_unidades DESC, ve.nombre ASC;

-- Consulta 10: todos los vendedores con su monto total vendido (0 si no vendieron)
SELECT ve.nombre,
       COALESCE(SUM(v.unidades * b.precio), 0) AS monto_total
FROM vendedores ve
LEFT JOIN ventas v     ON v.id_vendedor  = ve.id_vendedor
LEFT JOIN bicicletas b ON b.id_bicicleta = v.id_bicicleta
GROUP BY ve.id_vendedor, ve.nombre
ORDER BY monto_total DESC;
