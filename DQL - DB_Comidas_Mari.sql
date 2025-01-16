


------------------------------ Comidas Marina - DQL ---------------------------------


-- Consulta de las ventas

SELECT *
FROM Venta;


-- Consulta de los platos

SELECT *
FROM Menu;


-- Consulta de las compras

SELECT *
FROM Compra;


-- Consulta de los cambios

SELECT *
FROM Auditoría
ORDER BY Fecha_Cambio;


-- Consulta de las recaudaciones de cada mes del año

SELECT *
FROM Recaudaciones_Por_Mes;


-- Consulta de las recaudaciones por mes-año, pero contemplando los diferentes precios al rededor del tiempo.

SELECT *
FROM Recaudaciones_Por_Mes;


-- Consulta de las inversiones realizadas en cada mes del año

SELECT *
FROM Inversiones_Por_Mes;


-- Consulta de las ganancias obtenidas en el mes de cada año (Recaudación - Inversión)

SELECT *
FROM Ganancias_Por_Mes;
