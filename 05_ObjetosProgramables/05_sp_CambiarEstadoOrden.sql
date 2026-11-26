/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 05: sp_CambiarEstadoOrden

   Procedimiento de MODIFICACIÓN CON VALIDACIONES.
   Cambia el estado de una orden de trabajo respetando el flujo operativo:

     Recibida          -> EnDiagnostico, Cancelada
     EnDiagnostico     -> EnReparacion, EsperandoRepuesto, Cancelada
     EnReparacion      -> EsperandoRepuesto, Finalizada, Cancelada
     EsperandoRepuesto -> EnReparacion, Cancelada
     Finalizada        -> Entregada
     Entregada, Cancelada -> (estados finales)

   Al pasar a Finalizada registra la fecha de salida si aún no existe.
   Funciona tanto solo como dentro de una transacción externa (usa un
   savepoint en ese caso, para no deshacer el trabajo de quien lo llama).
   ===================================================================== */

USE TallerAutomotriz;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CambiarEstadoOrden
    @IdOrden     INT,
    @NuevoEstado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EstadoActual VARCHAR(20),
            @Mensaje      NVARCHAR(2048),
            @TranExterna  BIT = CASE WHEN @@TRANCOUNT > 0 THEN 1 ELSE 0 END;

    -- Validaciones de parámetros
    IF @IdOrden IS NULL OR @IdOrden <= 0
        THROW 50020, N'El identificador de la orden no es valido.', 1;

    SET @NuevoEstado = LTRIM(RTRIM(@NuevoEstado));

    IF @NuevoEstado IS NULL OR @NuevoEstado NOT IN
       ('Recibida', 'EnDiagnostico', 'EnReparacion', 'EsperandoRepuesto',
        'Finalizada', 'Entregada', 'Cancelada')
        THROW 50021, N'El estado indicado no existe.', 1;

    BEGIN TRY
        IF @TranExterna = 1
            SAVE TRANSACTION sp_CambiarEstadoOrden;
        ELSE
            BEGIN TRAN;

        -- Bloquea la fila para que dos sesiones no cambien la misma orden a la vez
        SELECT @EstadoActual = Estado
        FROM dbo.OrdenTrabajo WITH (UPDLOCK, HOLDLOCK)
        WHERE IdOrden = @IdOrden;

        IF @EstadoActual IS NULL
            THROW 50022, N'La orden indicada no existe.', 1;

        IF @EstadoActual = @NuevoEstado
            THROW 50023, N'La orden ya se encuentra en ese estado.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM (VALUES
                ('Recibida',          'EnDiagnostico'),
                ('Recibida',          'Cancelada'),
                ('EnDiagnostico',     'EnReparacion'),
                ('EnDiagnostico',     'EsperandoRepuesto'),
                ('EnDiagnostico',     'Cancelada'),
                ('EnReparacion',      'EsperandoRepuesto'),
                ('EnReparacion',      'Finalizada'),
                ('EnReparacion',      'Cancelada'),
                ('EsperandoRepuesto', 'EnReparacion'),
                ('EsperandoRepuesto', 'Cancelada'),
                ('Finalizada',        'Entregada')
            ) AS t (Origen, Destino)
            WHERE t.Origen = @EstadoActual AND t.Destino = @NuevoEstado)
        BEGIN
            SET @Mensaje = CONCAT(N'Transicion no permitida: ', @EstadoActual, N' -> ', @NuevoEstado);
            THROW 50024, @Mensaje, 1;
        END;

        UPDATE dbo.OrdenTrabajo
        SET Estado = @NuevoEstado,
            FechaSalida = CASE
                WHEN @NuevoEstado = 'Finalizada' AND FechaSalida IS NULL
                    THEN CASE WHEN SYSDATETIME() < FechaIngreso
                              THEN FechaIngreso
                              ELSE CAST(SYSDATETIME() AS DATETIME2(0)) END
                ELSE FechaSalida END
        WHERE IdOrden = @IdOrden;

        IF @TranExterna = 0
            COMMIT TRAN;

        SELECT IdOrden,
               @EstadoActual AS EstadoAnterior,
               Estado        AS EstadoNuevo,
               FechaSalida
        FROM dbo.OrdenTrabajo
        WHERE IdOrden = @IdOrden;
    END TRY
    BEGIN CATCH
        IF @TranExterna = 0 AND @@TRANCOUNT > 0
            ROLLBACK TRAN;
        ELSE IF @TranExterna = 1 AND XACT_STATE() = 1
            ROLLBACK TRAN sp_CambiarEstadoOrden;

        THROW;
    END CATCH;
END;
GO

PRINT 'Script 05 (objetos): procedimiento sp_CambiarEstadoOrden creado.';
GO
