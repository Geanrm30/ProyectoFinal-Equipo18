-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Respaldo y recuperacion
-- Respaldo completo de la base de datos

USE master;
GO

-- Obtener la ruta de respaldos de la instancia
DECLARE @Ruta NVARCHAR(4000) =
    CAST(SERVERPROPERTY('InstanceDefaultBackupPath')
    AS NVARCHAR(4000));

IF @Ruta IS NULL OR @Ruta = ''
BEGIN
    THROW 50001, 'No se encontro la ruta de respaldos.', 1;
END;

IF RIGHT(@Ruta, 1) <> '\'
    SET @Ruta = @Ruta + '\';

-- Generar un nombre unico para el respaldo
DECLARE @Archivo NVARCHAR(4000) =
    @Ruta + 'TallerAutomotriz_FULL_'
    + CONVERT(VARCHAR(8), GETDATE(), 112)
    + '_'
    + CONVERT(VARCHAR(36), NEWID())
    + '.bak';

-- Ejecutar respaldo completo
BACKUP DATABASE TallerAutomotriz
TO DISK = @Archivo
WITH
    COPY_ONLY,
    CHECKSUM,
    STATS = 10;

-- Verificar la integridad del respaldo
RESTORE VERIFYONLY
FROM DISK = @Archivo
WITH CHECKSUM;

-- Mostrar informacion del respaldo
SELECT
    'TallerAutomotriz' AS BaseDatos,
    @Archivo AS ArchivoRespaldo,
    SYSDATETIME() AS FechaRespaldo;
GO