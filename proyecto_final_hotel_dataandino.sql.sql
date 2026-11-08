-- ============================================================
-- PROYECTO FINAL: Análisis de Cancelaciones en Hotel DataAndino
-- Docente: Christian Condori Nina
-- Alumna: Yida Yazmin Alamo Anccori
-- Plataforma: Databricks SQL
-- Tabla principal: cursodataacademy.hotel_db.tb_reservas
-- ============================================================

-- ============================================================
-- PARTE 1: Limpieza, Exploración y Modificaciones
-- ============================================================

-- 1. (CREATE / INSERT)

CREATE TABLE IF NOT EXISTS cursodataacademy.hotel_db.tb_reservas_prueba AS
SELECT *
FROM cursodataacademy.hotel_db.tb_reservas
WHERE hotel = 'City Hotel'
  AND is_canceled = 1;

-- Conclusión: Se aislan las reservas canceladas de City Hotel en una tabla
-- de pruebas para realizar análisis y modificaciones sin afectar la data
-- original, protegiendo la integridad de la tabla principal.

-- 2. (UPDATE)

UPDATE cursodataacademy.hotel_db.tb_reservas_prueba
SET babies = 0;

-- Conclusión: Se corrige el error masivo de captura del canal de reservas.
-- Todos los registros de bebés en la tabla de pruebas se establecen en 0,
-- evitando que datos erróneos distorsionen futuros análisis de segmentación.

-- 3. (CAST / CONCAT)

SELECT
    arrival_date_day_of_month,
    arrival_date_month,
    arrival_date_year,
    CONCAT(
        CAST(arrival_date_day_of_month AS STRING),
        '-',
        arrival_date_month,
        '-',
        CAST(arrival_date_year AS STRING)
    ) AS arrival_date_string
FROM cursodataacademy.hotel_db.tb_reservas;

-- Conclusión: Se genera una columna legible con la fecha de llegada completa.
-- Esto facilita la lectura rápida de fechas en reportes sin necesidad de
-- interpretar tres columnas por separado.

-- 4. (LIKE)

SELECT *
FROM cursodataacademy.hotel_db.tb_reservas
WHERE distribution_channel LIKE 'T%';

-- Conclusión: Se filtran las reservas del canal TA/TO (agencias de viajes
-- y marketing), que es precisamente el canal sujeto a revisión contractual
-- por el problema de cobros en reservas canceladas.

-- 5. (COUNT / SUM / AVG)

SELECT
    COUNT(*) AS total_reservas,
    SUM(total_of_special_requests) AS total_solicitudes_especiales,
    AVG(adr) AS promedio_precio_noche
FROM cursodataacademy.hotel_db.tb_reservas;

-- Conclusión: Estas métricas globales dan un panorama general del volumen
-- de operaciones del hotel, el nivel de demanda de servicios adicionales y
-- el precio promedio por noche, útiles como línea base para el análisis.

-- 6. (DELETE)

DELETE FROM cursodataacademy.hotel_db.tb_reservas_prueba
WHERE adr = 0.0;

-- Conclusión: Se eliminan registros con tarifa cero que corresponden a
-- pruebas internas del sistema. Mantenerlos distorsionaría los promedios
-- de precio y las métricas financieras del análisis.

-- 7. (GROUP BY)

SELECT
    distribution_channel,
    COUNT(*) AS cantidad_reservas
FROM cursodataacademy.hotel_db.tb_reservas
GROUP BY distribution_channel;

-- Conclusión: Se identifica qué canales generan mayor volumen de reservas.
-- El canal con mayor participación es clave para la renegociación de
-- contratos, especialmente si concentra muchas cancelaciones.

-- 8. (CASE WHEN / Tipos de Datos)

SELECT
    hotel,
    adr,
    CASE
        WHEN adr < 50 THEN 'Económico'
        WHEN adr BETWEEN 50 AND 150 THEN 'Estándar'
        WHEN adr > 150 THEN 'Premium'
    END AS categoria_precio
FROM cursodataacademy.hotel_db.tb_reservas;

-- Conclusión: Segmentar por precio permite identificar en qué rango tarifario
-- se concentran las cancelaciones. Si el segmento Premium cancela más, la
-- pérdida por reserva es proporcionalmente mayor para el hotel.

-- 9. (Funciones de Fecha - DATE_SUB / DATE_ADD)

SELECT
    arrival_date,
    lead_time,
    DATE_SUB(arrival_date, lead_time) AS booking_date
FROM cursodataacademy.hotel_db.tb_reservas;

-- Conclusión: Conocer la fecha exacta de la reserva permite analizar
-- estacionalidad en la generación de reservas y detectar patrones
-- temporales que preceden a las cancelaciones.

-- 10. (Funciones Matemáticas)

SELECT
    lead_time,
    lead_time / 30 AS meses_anticipacion,
    CEIL(lead_time / 30) AS meses_anticipacion_techo
FROM cursodataacademy.hotel_db.tb_reservas;

-- Conclusión: Convertir los días de anticipación a meses facilita la
-- segmentación del riesgo de cancelación. Reservas con muchos meses de
-- anticipación podrían tener mayor probabilidad de ser canceladas.


-- ============================================================
-- PARTE 2: Impacto Financiero y JOINS
-- ============================================================

-- 11. El Costo del Marketing Inútil (Agregación con Filtro)

SELECT
    COUNT(*) AS reservas_canceladas_agencia,
    COUNT(*) * 1.5 AS perdida_total_usd
FROM cursodataacademy.hotel_db.tb_reservas
WHERE distribution_channel = 'TA/TO'
  AND is_canceled = 1;

-- Conclusión: Esta consulta cuantifica directamente la fuga de dinero por
-- pagar comisiones de marketing por reservas que nunca se materializaron.
-- Este monto justifica la renegociación contractual con las agencias.

-- 12. El Costo de Cancelar Tarde (DATE_DIFF)

SELECT
    COUNT(*) AS cancelaciones_tardias,
    COUNT(*) * 120 AS perdida_total_usd
FROM cursodataacademy.hotel_db.tb_reservas
WHERE is_canceled = 1
  AND DATEDIFF(arrival_date, reservation_status_date) < 3;

-- Conclusión: Las cancelaciones tardías generan un costo operativo hundido
-- significativo porque el hotel ya comprometió recursos (limpieza, insumos,
-- personal). Este dato respalda la implementación de penalidades por cancelación tardía.

-- ===============================================================
-- CREACIÓN DE TABLAS AUXILIARES PARA EJERCICIOS 13, 14, 15 y 16
-- ===============================================================

-- TABLA AUXILIAR: tb_paises (ejercicios 13 y 14)

CREATE TABLE IF NOT EXISTS cursodataacademy.hotel_db.tb_paises (
    cod_pais STRING,
    nombre_pais STRING
);

INSERT INTO cursodataacademy.hotel_db.tb_paises VALUES
    ('PRT', 'Portugal'),
    ('GBR', 'Reino Unido'),
    ('FRA', 'Francia'),
    ('ESP', 'España'),
    ('DEU', 'Alemania'),
    ('ITA', 'Italia'),
    ('IRL', 'Irlanda'),
    ('BEL', 'Bélgica'),
    ('BRA', 'Brasil'),
    ('NLD', 'Países Bajos'),
    ('USA', 'Estados Unidos'),
    ('CHN', 'China'),
    ('AUT', 'Austria'),
    ('SWE', 'Suecia'),
    ('CHE', 'Suiza'),
    ('ARG', 'Argentina'),
    ('COL', 'Colombia'),
    ('MEX', 'México'),
    ('PER', 'Perú'),
    ('JPN', 'Japón'),
    ('KOR', 'Corea del Sur'),
    ('RUS', 'Rusia'),
    ('POL', 'Polonia'),
    ('ISR', 'Israel'),
    ('MAR', 'Marruecos'),
    ('AGO', 'Angola'),
    ('MOZ', 'Mozambique'),
    ('ROU', 'Rumania'),
    ('NOR', 'Noruega'),
    ('FIN', 'Finlandia');

-- TABLA AUXILIAR: tb_vendedores (ejercicio 15)

CREATE TABLE IF NOT EXISTS cursodataacademy.hotel_db.tb_vendedores (
    id_vendedor INT,
    nombre_vendedor STRING
);

INSERT INTO cursodataacademy.hotel_db.tb_vendedores VALUES
    (1, 'Carlos Mendoza'),
    (2, 'Ana Torres'),
    (3, 'Luis García'),
    (4, 'María Rodríguez'),
    (5, 'Pedro Sánchez'),
    (6, 'Lucía Fernández'),
    (7, 'Jorge Ramírez'),
    (8, 'Claudia Vargas'),
    (9, 'Roberto Díaz'),
    (10, 'Sofía Paredes');

-- TABLA AUXILIAR: tb_facturas (ejercicio 16)

CREATE TABLE IF NOT EXISTS cursodataacademy.hotel_db.tb_facturas (
    id_reserva INT,
    monto_facturado DOUBLE
);

INSERT INTO cursodataacademy.hotel_db.tb_facturas VALUES
    (1, 250.00),
    (2, 180.50),
    (3, 320.75),
    (10, 195.00),
    (25, 410.00),
    (50, 275.30),
    (75, 520.00),
    (100, 150.25),
    (200, 340.60),
    (500, 180.90),
    (1000, 460.00),
    (5000, 290.50),
    (99998, 600.00),
    (99999, 750.00);

-- 13. (JOIN 1 - LEFT JOIN - Entendiendo el Modelo)

SELECT
    r.is_canceled,
    p.nombre_pais
FROM cursodataacademy.hotel_db.tb_reservas r
LEFT JOIN cursodataacademy.hotel_db.tb_paises p
    ON r.country = p.cod_pais;

-- Conclusión: El LEFT JOIN conserva todas las reservas aunque el país no
-- exista en tb_paises (aparece NULL). Esto permite detectar códigos de
-- país faltantes en el catálogo y completar la tabla de referencia.

-- 14. (JOIN 2 - INNER JOIN con Agrupación)

SELECT
    p.nombre_pais,
    COUNT(*) AS total_cancelaciones
FROM cursodataacademy.hotel_db.tb_reservas r
INNER JOIN cursodataacademy.hotel_db.tb_paises p
    ON r.country = p.cod_pais
WHERE r.is_canceled = 1
GROUP BY p.nombre_pais
ORDER BY total_cancelaciones DESC
LIMIT 5;

-- Conclusión: Identificar los países con más cancelaciones permite al
-- hotel focalizar estrategias de retención o ajustar políticas de
-- depósito anticipado para mercados con alto riesgo de cancelación.

-- 15. (JOIN 3 - Simulación FULL OUTER JOIN)

SELECT
    r.distribution_channel,
    v.nombre_vendedor
FROM cursodataacademy.hotel_db.tb_reservas r
FULL OUTER JOIN cursodataacademy.hotel_db.tb_vendedores v
    ON r.id_vendedor = v.id_vendedor;

-- Conclusión: El FULL OUTER JOIN muestra reservas sin vendedor asignado
-- (NULL en nombre_vendedor) y vendedores sin reservas (NULL en canal).
-- Esto permite optimizar la carga de trabajo del equipo comercial.

-- 16. (JOIN 4 - RIGHT JOIN)

SELECT
    r.hotel,
    f.id_reserva,
    f.monto_facturado
FROM cursodataacademy.hotel_db.tb_reservas r
RIGHT JOIN cursodataacademy.hotel_db.tb_facturas f
    ON r.id_reserva = f.id_reserva;

-- Conclusión: El RIGHT JOIN prioriza las facturas: todas aparecen aunque
-- no tengan reserva asociada (hotel = NULL). Esto permite a contabilidad
-- detectar facturas huérfanas e inconsistencias en la facturación.


-- ============================================================
-- PARTE 3: Validación de Hipótesis de Cancelación
-- ============================================================

-- 17. Hipótesis 1: ¿Los hijos aseguran el viaje?

SELECT
    CASE
        WHEN children > 0 OR babies > 0 THEN 'Con Hijos'
        ELSE 'Sin Hijos'
    END AS segmento_familiar,
    COUNT(*) AS total_reservas,
    AVG(is_canceled) AS tasa_cancelacion
FROM cursodataacademy.hotel_db.tb_reservas
GROUP BY
    CASE
        WHEN children > 0 OR babies > 0 THEN 'Con Hijos'
        ELSE 'Sin Hijos'
    END;

-- Conclusión: Se espera que el segmento "Sin Hijos" presente una tasa de
-- cancelación más alta, ya que las familias con niños suelen tener planes
-- más firmes y comprometidos con el viaje.

-- 18. Hipótesis 2: El impacto de las solicitudes especiales.

SELECT
    total_of_special_requests,
    COUNT(*) AS total_reservas,
    AVG(is_canceled) AS tasa_cancelacion
FROM cursodataacademy.hotel_db.tb_reservas
GROUP BY total_of_special_requests
ORDER BY total_of_special_requests ASC;

-- Conclusión: A mayor número de solicitudes especiales, menor tasa de
-- cancelación. El cliente que personaliza su estadía demuestra mayor
-- compromiso con la reserva, lo que reduce la probabilidad de cancelar.

-- 19. Hipótesis 3: ¿Cambiar la reserva es señal de compromiso?

SELECT
    CASE
        WHEN booking_changes = 0 THEN 'Sin Cambios'
        WHEN booking_changes BETWEEN 1 AND 3 THEN '1 a 3 cambios'
        WHEN booking_changes > 3 THEN 'Más de 3 cambios'
    END AS grupo_cambios,
    COUNT(*) AS total_reservas,
    AVG(is_canceled) AS tasa_cancelacion
FROM cursodataacademy.hotel_db.tb_reservas
GROUP BY
    CASE
        WHEN booking_changes = 0 THEN 'Sin Cambios'
        WHEN booking_changes BETWEEN 1 AND 3 THEN '1 a 3 cambios'
        WHEN booking_changes > 3 THEN 'Más de 3 cambios'
    END;

-- Conclusión: Los huéspedes que realizan cambios a su reserva tienen menor
-- riesgo de cancelar, ya que ajustar detalles indica interés real en la
-- estadía. El grupo "Sin Cambios" probablemente concentra más cancelaciones.

-- 20. Hipótesis 4: El factor precio (adr).

SELECT
    hotel,
    COUNT(*) AS total_cancelaciones,
    AVG(adr) AS promedio_adr_canceladas
FROM cursodataacademy.hotel_db.tb_reservas
WHERE is_canceled = 1
GROUP BY hotel;

-- Conclusión: El City Hotel tiende a presentar un precio promedio de
-- cancelación más alto que el Resort Hotel, lo que implica mayor impacto
-- financiero por cada cancelación en hoteles urbanos.
