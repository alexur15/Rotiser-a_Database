

------------------------------ Comidas Marina - DDL ---------------------------------

-- Creación de la base de datos

CREATE DATABASE Comidas_Mari;


-- Creación de las tablas

CREATE TABLE Venta(
	id_venta INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	id_plato INT NOT NULL,
	cantidad INT NOT NULL,
	fecha DATE NOT NULL
);

CREATE TABLE Menu(
	id_plato INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	nombre VARCHAR(30) NOT NULL,
	precio INT NOT NULL
);

CREATE TABLE Compra(
	id_compra INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	descripción VARCHAR(100) NULL,
	gasto INT NOT NULL,
	fecha DATE NOT NULL
);


-- Inserción de la clave foránea en Venta

ALTER TABLE dbo.Venta
ADD CONSTRAINT FK_Venta_Menu
FOREIGN KEY (id_plato) REFERENCES Menu(id_plato);


-- Creación de la vista del cálculo de las recaudaciones

ALTER VIEW Recaudaciones_Por_Mes AS

-- La siguiente CTE une cada venta con el respectivo precio de su producto
WITH Registro_Venta AS(
	SELECT 
		v.id_plato as ID_PLATO,
		v.cantidad as CANT,
		v.fecha as FECHA,
		a.Precio_Nuevo as PRECIO
	FROM
		Venta v CROSS APPLY (
						SELECT TOP 1 Precio_Nuevo
						FROM Auditoría
						WHERE Id_Plato = v.id_plato AND Fecha_Cambio <= v.fecha
						ORDER BY Fecha_Cambio DESC
					 ) AS a
),

-- La siguiente CTE recupera el precio de la media docena de emepanadas en de cada fecha registrada

Registro_Venta_Extensión_Empanadas AS(
	SELECT
		ID_PLATO,
		CANT,
		FECHA,
		PRECIO,
		(
			CASE
				WHEN ID_PLATO = 1 AND CANT > 5 THEN (
													SELECT TOP 1 Precio_Nuevo
													FROM Auditoría
													WHERE Id_Plato = 6 AND Fecha_Cambio <= rv.FECHA
													ORDER BY Fecha_Cambio DESC
													)
				ELSE NULL
			END
		) AS PRECIOXDOCENA
	FROM
		Registro_Venta rv
)

-- (Devuelve los resultados obtenidos de ambas CTE y utilizados en la lógica principal) SELECT * FROM Registro_Venta_Extensión_Empanadas

SELECT
	-- Recupero año, mes y monto
	DATEPART(YEAR,FECHA) AS Número_año,
	DATEPART(MONTH,FECHA) AS Número_mes,
	SUM(
		CASE
			-- Si en la venta se registran media docena de empanadas o más, el cálculo se efectuará con la ste. lógica
			WHEN ID_PLATO = 1 AND CANT > 5 THEN ((CANT / 6) * PRECIOXDOCENA + (CANT - 6 * (CANT / 6)) * PRECIO)
			-- Caso contrario, el monto se calcula de la forma tradicional
			ELSE PRECIO *CANT
		END
		) AS Monto_total
FROM Registro_Venta_Extensión_Empanadas -- Extraído de la CTE previa
GROUP BY DATEPART(YEAR,FECHA), DATEPART(MONTH,FECHA); -- Agrupado por Año y Mes


/* Se requiere consultar la cantidad de dinero invertido en insumos en el mes de cada año.*/

CREATE VIEW Inversiones_Por_Mes AS
-- Recupero el año, el mes y la suma invertida en ese período
SELECT 
	DATEPART(YEAR,fecha) as Año,
	DATEPART(MONTH,fecha) as Mes,
	SUM(gasto) as Inversión
-- Los datos se extraen de la tabla 'Compra', la cual guarda los datos de las compras realizadas
FROM
	Compra
-- Agrupo los datos por año y mes
GROUP BY 
	DATEPART(YEAR,fecha), 
	DATEPART(MONTH,fecha);



/* Se requiere consultar las ganancias de cada mes de cada año.
Por 'ganancia' se entiende que es la diferencia entre la recaudación y la inversión
*/


CREATE VIEW Ganancias_Por_Mes AS
SELECT
	ipm.Año,
	ipm.Mes,
	(Monto_total - Inversión) as Ganancia
-- Uno las tablas de recaudaciones_por_mes e inversiones_por_mes
FROM Inversiones_Por_Mes ipm INNER JOIN Recaudaciones_Por_Mes rpm ON ipm.Año = rpm.Número_año AND ipm.Mes = rpm.Número_mes;


/*	Además se requiere almacenar en una tabla 'Auditoría' los cambios que se hacen en los precios de cada plato
	Para así poder llevar un registro de cuándo se cambió el último precio y de cuánto era
*/

CREATE TABLE Auditoría(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id_Plato INT NOT NULL,
	Fecha_Cambio DATE NOT NULL,
	Precio_Viejo INT NOT NULL

	CONSTRAINT FK_Auditoría_Menu FOREIGN KEY (Id_plato) REFERENCES Menu(id_plato)
);

-- Se me olvidó crear la columna que guarda el nombre del platillo y el precio nuevo

ALTER TABLE Auditoría
ADD Nombre VARCHAR(30) NOT NULL;


ALTER TABLE Auditoría
ADD Precio_Nuevo INT NOT NULL;


-- El siguiente TRIGGER permite registrar los cambios en los precios los platos del menú

CREATE TRIGGER Actualización_Precio ON Menu
AFTER UPDATE
AS
BEGIN
	-- Inserto en la tabla auditoría los datos del platillo que fue actualizado
	INSERT INTO Auditoría(Id_Plato,Fecha_Cambio,Precio_Viejo,Precio_Nuevo)
	SELECT 
		m.id_plato as Id_Plato,
		GETDATE() as Fecha_Cambio,
		d.precio as Precio_Viejo,
		m.precio as Precio_Nuevo
	FROM
		Menu m INNER JOIN deleted d ON m.id_plato = d.id_plato
	PRINT 'Precio Actualizado!'
END;


/* Surge la necesidad de registrar los precios de cada platillo nuevo en la tabla de auditorías */

CREATE TRIGGER Registrar_Nuevo_Producto ON Menu
AFTER INSERT
AS
BEGIN
	
	-- Debo copiar los datos insertados en la tabla de Auditoría
	INSERT INTO Auditoría(Id_Plato,Fecha_Cambio,Precio_Viejo,Precio_Nuevo)
	SELECT
		id_plato AS Id_Plato,
		GETDATE() AS Fecha_Cambio,
		0 AS PrecioViejo,
		precio AS Precio_Nuevo
	FROM inserted
	PRINT 'Producto nuevo registrado!'
END;