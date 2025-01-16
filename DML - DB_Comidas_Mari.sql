

------------------------------ Comidas Marina - DML ---------------------------------



---------------- Recuperación de los datos de las tablas ---------------------

-- Ventas
SELECT *
FROM Venta;

-- Menú
SELECT *
FROM Menu;

-- Compras
SELECT *
FROM Compra;


-- Inserto la información de los platillos que conforman el menú del cliente

INSERT INTO Menu(nombre,precio) VALUES
	('Empanadas', 1000),
	('Milanesa c/ fritas', 8000),
	('Milanesa s/ fritas',0),
	('Tarta de acelga', 0);


-- Inserto los gastos del día de hoy

INSERT INTO Compra(descripción,gasto,fecha) VALUES
	('Aceite - 3l',7500,'2025-01-01'),
	('Harina - 2 x 500g',1400,'2025-01-01'),
	('Carne 2kg',15000,'2025-01-01'),
	('Pollo 1kg',7000,'2025-01-01'),
	('Huevos - 1 doc',2800,'2025-01-01'),
	('Cebollita de verdeo - 3 unidades',1000,'2025-01-01'),
	('Morrón - 2kg',2000,'2025-01-01'),
	('Papa - 3kg',2000,'2025-01-01');


-- Pruebas sobre el trigger Venta_de_Platillo_Inexistente

INSERT INTO Venta(id_plato,cantidad,fecha) VALUES
	(2, 10, GETDATE());

DELETE FROM Venta;


-- Pruebas sobre el triger Actualización_Precio

UPDATE Menu SET precio = 0 WHERE id_plato = 3;

