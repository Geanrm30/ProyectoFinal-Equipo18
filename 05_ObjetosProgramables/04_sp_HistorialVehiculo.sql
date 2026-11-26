/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 04: sp_HistorialVehiculo

   Procedimiento de CONSULTA PARAMETRIZADA.
   Devuelve el historial de servicios de un vehículo por placa, con
   filtro opcional por rango de fechas de ingreso.
   Sin SQL dinámico: todos los valores viajan como parámetros.
   ===================================================================== */

USE TallerAutomotriz;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialVehiculo
    @Placa VARCHAR(10),
    @Desde DATE = NULL,
    @Hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Placa = UPPER(LTRIM(RTRIM(@Placa)));

    IF @Placa IS NULL OR @Placa = ''
        THROW 50010, N'Debe indicar la placa del vehiculo.', 1;

    IF @Desde IS NOT NULL AND @Hasta IS NOT NULL AND @Desde > @Hasta
        THROW 50011, N'La fecha inicial no puede ser mayor que la fecha final.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Vehiculo WHERE Placa = @Placa)
        THROW 50012, N'La placa indicada no esta registrada.', 1;

    SELECT
        Placa, Marca, Modelo, Cliente,
        IdOrden, FechaIngreso, FechaSalida, EstadoOrden,
        Servicio, TipoServicio, Tecnico, PrecioServicio, Horas
    FROM dbo.vw_HistorialVehiculo
    WHERE Placa = @Placa
      AND (@Desde IS NULL OR FechaIngreso >= @Desde)
      AND (@Hasta IS NULL OR FechaIngreso <  DATEADD(DAY, 1, @Hasta))
    ORDER BY FechaIngreso DESC, IdOrden DESC;
END;
GO

PRINT 'Script 04 (objetos): procedimiento sp_HistorialVehiculo creado.';
GO
