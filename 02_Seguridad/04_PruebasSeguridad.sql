-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Seguridad
-- Pruebas de permisos y minimo privilegio

USE TallerAutomotriz;
GO

-- PRUEBA 1: Consulta permitida
EXECUTE AS USER = 'usuario_consulta';

SELECT USER_NAME() AS Usuario;

SELECT TOP 5 *
FROM dbo.OrdenTrabajo;

REVERT;
GO

-- PRUEBA 2: Modificacion denegada
EXECUTE AS USER = 'usuario_consulta';

BEGIN TRY
    EXEC sys.sp_executesql N'
        UPDATE dbo.OrdenTrabajo
        SET Estado = ''Finalizada''
        WHERE 1 = 0;
    ';

    PRINT 'FALLO: se permitio modificar.';
END TRY
BEGIN CATCH
    SELECT
        USER_NAME() AS Usuario,
        ERROR_NUMBER() AS CodigoError,
        ERROR_MESSAGE() AS Mensaje;
END CATCH;

REVERT;
GO

-- PRUEBA 3: Modificacion permitida
EXECUTE AS USER = 'usuario_operacion';

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE dbo.OrdenTrabajo
    SET Estado = Estado
    WHERE IdOrden = (
        SELECT MIN(IdOrden)
        FROM dbo.OrdenTrabajo
    );

    SELECT
        USER_NAME() AS Usuario,
        @@ROWCOUNT AS FilasModificadas;

    ROLLBACK TRANSACTION;

    PRINT 'Prueba finalizada sin cambios permanentes.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT ERROR_MESSAGE() AS Error;
END CATCH;

REVERT;
GO

-- PRUEBA 4: Eliminacion denegada
EXECUTE AS USER = 'usuario_operacion';

BEGIN TRY
    EXEC sys.sp_executesql N'
        DELETE FROM dbo.OrdenTrabajo
        WHERE 1 = 0;
    ';

    PRINT 'FALLO: se permitio eliminar.';
END TRY
BEGIN CATCH
    SELECT
        USER_NAME() AS Usuario,
        ERROR_NUMBER() AS CodigoError,
        ERROR_MESSAGE() AS Mensaje;
END CATCH;

REVERT;
GO