

------------------------------ Comidas Marina - DDL ---------------------------------

-- Creaci�n de la base de datos

CREATE DATABASE Comidas_Mari;


-- Creaci�n de las tablas

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
	descripci�n VARCHAR(100) NULL,
	gasto INT NOT NULL,
	fecha DATE NOT NULL
);


-- Inserci�n de la clave for�nea en Venta

ALTER TABLE dbo.Venta
ADD CONSTRAINT FK_Venta_Menu
FOREIGN KEY (id_plato) REFERENCES Menu(id_plato);


-- Creaci�n de la vista del c�lculo de las recaudaciones

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
						FROM Auditor�a
						WHERE Id_Plato = v.id_plato AND Fecha_Cambio <= v.fecha
						ORDER BY Fecha_Cambio DESC
					 ) AS a
),

-- La siguiente CTE recupera el precio de la media docena de emepanadas en de cada fecha registrada

Registro_Venta_Extensi�n_Empanadas AS(
	SELECT
		ID_PLATO,
		CANT,
		FECHA,
		PRECIO,
		(
			CASE
				WHEN ID_PLATO = 1 AND CANT > 5 THEN (
													SELECT TOP 1 Precio_Nuevo
													FROM Auditor�a
													WHERE Id_Plato = 6 AND Fecha_Cambio <= rv.FECHA
													ORDER BY Fecha_Cambio DESC
													)
				ELSE NULL
			END
		) AS PRECIOXDOCENA
	FROM
		Registro_Venta rv
)

-- (Devuelve los resultados obtenidos de ambas CTE y utilizados en la l�gica principal) SELECT * FROM Registro_Venta_Extensi�n_Empanadas

SELECT
	-- Recupero a�o, mes y monto
	DATEPART(YEAR,FECHA) AS N�mero_a�o,
	DATEPART(MONTH,FECHA) AS N�mero_mes,
	SUM(
		CASE
			-- Si en la venta se registran media docena de empanadas o m�s, el c�lculo se efectuar� con la ste. l�gica
			WHEN ID_PLATO = 1 AND CANT > 5 THEN ((CANT / 6) * PRECIOXDOCENA + (CANT - 6 * (CANT / 6)) * PRECIO)
			-- Caso contrario, el monto se calcula de la forma tradicional
			ELSE PRECIO *CANT
		END
		) AS Monto_total
FROM Registro_Venta_Extensi�n_Empanadas -- Extra�do de la CTE previa
GROUP BY DATEPART(YEAR,FECHA), DATEPART(MONTH,FECHA); -- Agrupado por A�o y Mes


/* Se requiere consultar la cantidad de dinero invertido en insumos en el mes de cada a�o.*/

CREATE VIEW Inversiones_Por_Mes AS
-- Recupero el a�o, el mes y la suma invertida en ese per�odo
SELECT 
	DATEPART(YEAR,fecha) as A�o,
	DATEPART(MONTH,fecha) as Mes,
	SUM(gasto) as Inversi�n
-- Los datos se extraen de la tabla 'Compra', la cual guarda los datos de las compras realizadas
FROM
	Compra
-- Agrupo los datos por a�o y mes
GROUP BY 
	DATEPART(YEAR,fecha), 
	DATEPART(MONTH,fecha);



/* Se requiere consultar las ganancias de cada mes de cada a�o.
Por 'ganancia' se entiende que es la diferencia entre la recaudaci�n y la inversi�n
*/


CREATE VIEW Ganancias_Por_Mes AS
SELECT
	ipm.A�o,
	ipm.Mes,
	(Monto_total - Inversi�n) as Ganancia
-- Uno las tablas de recaudaciones_por_mes e inversiones_por_mes
FROM Inversiones_Por_Mes ipm INNER JOIN Recaudaciones_Por_Mes rpm ON ipm.A�o = rpm.N�mero_a�o AND ipm.Mes = rpm.N�mero_mes;


/*	Adem�s se requiere almacenar en una tabla 'Auditor�a' los cambios que se hacen en los precios de cada plato
	Para as� poder llevar un registro de cu�ndo se cambi� el �ltimo precio y de cu�nto era
*/

CREATE TABLE Auditor�a(
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id_Plato INT NOT NULL,
	Fecha_Cambio DATE NOT NULL,
	Precio_Viejo INT NOT NULL

	CONSTRAINT FK_Auditor�a_Menu FOREIGN KEY (Id_plato) REFERENCES Menu(id_plato)
);

-- Se me olvid� crear la columna que guarda el nombre del platillo y el precio nuevo

ALTER TABLE Auditor�a
ADD Nombre VARCHAR(30) NOT NULL;


ALTER TABLE Auditor�a
ADD Precio_Nuevo INT NOT NULL;


-- El siguiente TRIGGER permite registrar los cambios en los precios los platos del men�

CREATE TRIGGER Actualizaci�n_Precio ON Menu
AFTER UPDATE
AS
BEGIN
	-- Inserto en la tabla auditor�a los datos del platillo que fue actualizado
	INSERT INTO Auditor�a(Id_Plato,Fecha_Cambio,Precio_Viejo,Precio_Nuevo)
	SELECT 
		m.id_plato as Id_Plato,
		GETDATE() as Fecha_Cambio,
		d.precio as Precio_Viejo,
		m.precio as Precio_Nuevo
	FROM
		Menu m INNER JOIN deleted d ON m.id_plato = d.id_plato
	PRINT 'Precio Actualizado!'
END;


/* Surge la necesidad de registrar los precios de cada platillo nuevo en la tabla de auditor�as */

CREATE TRIGGER Registrar_Nuevo_Producto ON Menu
AFTER INSERT
AS
BEGIN
	
	-- Debo copiar los datos insertados en la tabla de Auditor�a
	INSERT INTO Auditor�a(Id_Plato,Fecha_Cambio,Precio_Viejo,Precio_Nuevo)
	SELECT
		id_plato AS Id_Plato,
		GETDATE() AS Fecha_Cambio,
		0 AS PrecioViejo,
		precio AS Precio_Nuevo
	FROM inserted
	PRINT 'Producto nuevo registrado!'
END;