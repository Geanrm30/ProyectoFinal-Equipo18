/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 08: pruebas

   Cada prueba corre en su propio lote (GO) y las que modifican datos usan
   una transacción con ROLLBACK, así la base queda igual que antes.
   Ejecutar DESPUÉS de los scripts 01 a 07. Capturar cada resultado.

   Nota: las órdenes de prueba consumen números de identidad aunque se
   deshagan; si luego se crean órdenes reales, sus Id saltarán esos números.
   ===================================================================== */

USE TallerAutomotriz;
GO

/* ---------------------------------------------------------------------
   PRUEBA 1: función fn_EstadoStock
   --------------------------------------------------------------------- */
SELECT dbo.fn_EstadoStock(0, 5)  AS Esperado_Agotado,
       dbo.fn_EstadoStock(3, 5)  AS Esperado_Bajo,
       dbo.fn_EstadoStock(50, 5) AS Esperado_Optimo;

SELECT TOP (10)
       Codigo, Nombre, Existencia, StockMinimo,
       dbo.fn_EstadoStock(Existencia, StockMinimo) AS EstadoStock
FROM dbo.Repuesto
ORDER BY Existencia;
GO

/* ---------------------------------------------------------------------
   PRUEBA 2: sp_HistorialVehiculo (consulta parametrizada)
   --------------------------------------------------------------------- */
DECLARE @Placa VARCHAR(10) = (SELECT Placa FROM dbo.Vehiculo WHERE IdVehiculo = 1);

-- Historial completo
EXEC dbo.sp_HistorialVehiculo @Placa = @Placa;

-- Con rango de fechas
EXEC dbo.sp_HistorialVehiculo @Placa = @Placa, @Desde = '2026-01-01', @Hasta = '2026-12-31';

-- Placa inexistente: debe fallar con el error 50012
BEGIN TRY
    EXEC dbo.sp_HistorialVehiculo @Placa = 'NOEXISTE';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH;
GO

/* ---------------------------------------------------------------------
   PRUEBA 3: sp_CambiarEstadoOrden + trigger de auditoría
   --------------------------------------------------------------------- */
BEGIN TRAN;

INSERT INTO dbo.OrdenTrabajo (IdVehiculo) VALUES (1);
DECLARE @IdOrden INT = SCOPE_IDENTITY();

-- Transiciones válidas
EXEC dbo.sp_CambiarEstadoOrden @IdOrden = @IdOrden, @NuevoEstado = 'EnDiagnostico';
EXEC dbo.sp_CambiarEstadoOrden @IdOrden = @IdOrden, @NuevoEstado = 'EnReparacion';
EXEC dbo.sp_CambiarEstadoOrden @IdOrden = @IdOrden, @NuevoEstado = 'Finalizada';

-- Transición inválida: Finalizada -> Recibida (error 50024)
BEGIN TRY
    EXEC dbo.sp_CambiarEstadoOrden @IdOrden = @IdOrden, @NuevoEstado = 'Recibida';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH;

-- Estado inexistente (error 50021)
BEGIN TRY
    EXEC dbo.sp_CambiarEstadoOrden @IdOrden = @IdOrden, @NuevoEstado = 'Volando';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH;

-- Auditoría generada: INSERT + 3 cambios de estado
SELECT IdAuditoria, IdOrden, Accion, EstadoAnterior, EstadoNuevo, Usuario, Fecha
FROM dbo.AuditoriaOrden
WHERE IdOrden = @IdOrden
ORDER BY IdAuditoria;

ROLLBACK;
GO

/* ---------------------------------------------------------------------
   PRUEBA 4: trigger de auditoría con VARIAS FILAS en una sola sentencia
   Debe registrar 3 filas de auditoría (una por orden modificada).
   --------------------------------------------------------------------- */
BEGIN TRAN;

UPDATE dbo.OrdenTrabajo
SET Total = Total + 1
WHERE IdOrden IN (1, 2, 3);

SELECT COUNT(*) AS FilasAuditadas_Esperado_3
FROM dbo.AuditoriaOrden
WHERE IdOrden IN (1, 2, 3) AND Accion = 'UPDATE';

ROLLBACK;
GO

/* ---------------------------------------------------------------------
   PRUEBA 5: trigger de stock - inserción de UNA fila
   --------------------------------------------------------------------- */
BEGIN TRAN;

INSERT INTO dbo.OrdenTrabajo (IdVehiculo) VALUES (1);
DECLARE @IdOrden INT = SCOPE_IDENTITY();
DECLARE @Antes INT = (SELECT Existencia FROM dbo.Repuesto WHERE IdRepuesto = 1);

INSERT INTO dbo.OrdenRepuesto (IdOrden, IdRepuesto, Cantidad, PrecioUnitario)
VALUES (@IdOrden, 1, 3, 10.00);

SELECT @Antes AS ExistenciaAntes,
       Existencia AS ExistenciaDespues,
       @Antes - Existencia AS Descontado_Esperado_3
FROM dbo.Repuesto
WHERE IdRepuesto = 1;

ROLLBACK;
GO

/* ---------------------------------------------------------------------
   PRUEBA 6: trigger de stock - VARIAS FILAS válidas en una sola sentencia
   Descuenta 2 del repuesto 1 y 5 del repuesto 2.
   --------------------------------------------------------------------- */
BEGIN TRAN;

INSERT INTO dbo.OrdenTrabajo (IdVehiculo) VALUES (1);
DECLARE @IdOrden INT = SCOPE_IDENTITY();

DECLARE @Antes TABLE (IdRepuesto INT PRIMARY KEY, Existencia INT);
INSERT INTO @Antes
SELECT IdRepuesto, Existencia FROM dbo.Repuesto WHERE IdRepuesto IN (1, 2);

INSERT INTO dbo.OrdenRepuesto (IdOrden, IdRepuesto, Cantidad, PrecioUnitario)
VALUES (@IdOrden, 1, 2, 10.00),
       (@IdOrden, 2, 5, 10.00);

SELECT r.IdRepuesto, a.Existencia AS Antes, r.Existencia AS Despues,
       a.Existencia - r.Existencia AS Descontado
FROM dbo.Repuesto r
JOIN @Antes a ON a.IdRepuesto = r.IdRepuesto
ORDER BY r.IdRepuesto;

ROLLBACK;
GO

/* ---------------------------------------------------------------------
   PRUEBA 7: trigger de stock - VARIAS FILAS donde UNA no alcanza
   Debe fallar con el error 50030 y NO descontar nada (ni el repuesto 1,
   cuya cantidad sí era válida): la operación completa se deshace.
   --------------------------------------------------------------------- */
DECLARE @Antes1 INT = (SELECT Existencia FROM dbo.Repuesto WHERE IdRepuesto = 1);
DECLARE @Antes2 INT = (SELECT Existencia FROM dbo.Repuesto WHERE IdRepuesto = 2);

BEGIN TRY
    BEGIN TRAN;

    INSERT INTO dbo.OrdenTrabajo (IdVehiculo) VALUES (1);
    DECLARE @IdOrden INT = SCOPE_IDENTITY();

    INSERT INTO dbo.OrdenRepuesto (IdOrden, IdRepuesto, Cantidad, PrecioUnitario)
    VALUES (@IdOrden, 1, 2, 10.00),
           (@IdOrden, 2, 100000, 10.00);

    COMMIT;   -- no debe alcanzarse
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
    IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;

SELECT @Antes1 AS Repuesto1_Antes,
       (SELECT Existencia FROM dbo.Repuesto WHERE IdRepuesto = 1) AS Repuesto1_Despues,
       @Antes2 AS Repuesto2_Antes,
       (SELECT Existencia FROM dbo.Repuesto WHERE IdRepuesto = 2) AS Repuesto2_Despues;
GO

/* ---------------------------------------------------------------------
   PRUEBA 8: trigger de stock - UPDATE y DELETE devuelven/ajustan existencia
   Inserta 3 (-3), sube a 5 (-2 más), elimina (devuelve 5): neto 0.
   --------------------------------------------------------------------- */
BEGIN TRAN;

INSERT INTO dbo.OrdenTrabajo (IdVehiculo) VALUES (1);
DECLARE @IdOrden INT = SCOPE_IDENTITY();
DECLARE @Inicial INT = (SELECT Existencia FROM dbo.Repuesto WHERE IdRepuesto = 1);

INSERT INTO dbo.OrdenRepuesto (IdOrden, IdRepuesto, Cantidad, PrecioUnitario)
VALUES (@IdOrden, 1, 3, 10.00);
SELECT 'Tras INSERT (3)' AS Paso, @Inicial AS Inicial,
       Existencia AS Existencia, @Inicial - Existencia AS Consumido
FROM dbo.Repuesto WHERE IdRepuesto = 1;

UPDATE dbo.OrdenRepuesto SET Cantidad = 5
WHERE IdOrden = @IdOrden AND IdRepuesto = 1;
SELECT 'Tras UPDATE (5)' AS Paso, @Inicial AS Inicial,
       Existencia AS Existencia, @Inicial - Existencia AS Consumido
FROM dbo.Repuesto WHERE IdRepuesto = 1;

DELETE FROM dbo.OrdenRepuesto
WHERE IdOrden = @IdOrden AND IdRepuesto = 1;
SELECT 'Tras DELETE' AS Paso, @Inicial AS Inicial,
       Existencia AS Existencia, @Inicial - Existencia AS Consumido
FROM dbo.Repuesto WHERE IdRepuesto = 1;

ROLLBACK;
GO

PRINT 'Script 08: pruebas ejecutadas. Revisar y capturar cada resultado.';
GO
