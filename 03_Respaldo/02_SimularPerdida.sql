-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Respaldo y recuperacion
-- Simulacion controlada de perdida de datos

USE master;
GO

-- Evitar sobrescribir una base de prueba existente
IF DB_ID('TallerAutomotriz_PruebaRecuperacion') IS NOT NULL
BEGIN
    PRINT 'La base de prueba ya existe. No se realizaron cambios.';
    RETURN;
END;

-- Localizar el ultimo respaldo completo COPY_ONLY
DECLARE @Archivo NVARCHAR(4000);
DECLARE @Posicion INT;

SELECT TOP 1
    @Archivo = m.physical_device_name,
    @Posicion = b.position
FROM msdb.dbo.backupset b
INNER JOIN msdb.dbo.backupmediafamily m
    ON b.media_set_id = m.media_set_id
WHERE b.database_name = 'TallerAutomotriz'
    AND b.type = 'D'
    AND b.is_copy_only = 1
    AND m.device_type = 2
ORDER BY b.backup_finish_date DESC, b.backup_set_id DESC;

IF @Archivo IS NULL
    THROW 50002, 'No se encontro el respaldo.', 1;

-- Obtener rutas predeterminadas de SQL Server
DECLARE @RutaDatos NVARCHAR(4000) =
    CAST(SERVERPROPERTY('InstanceDefaultDataPath')
    AS NVARCHAR(4000));

DECLARE @RutaLog NVARCHAR(4000) =
    CAST(SERVERPROPERTY('InstanceDefaultLogPath')
    AS NVARCHAR(4000));

IF @RutaDatos IS NULL OR @RutaLog IS NULL
    THROW 50003, 'No se encontraron las rutas de datos.', 1;

IF RIGHT(@RutaDatos, 1) <> '\'
    SET @RutaDatos = @RutaDatos + '\';

IF RIGHT(@RutaLog, 1) <> '\'
    SET @RutaLog = @RutaLog + '\';

DECLARE @MDF NVARCHAR(4000) =
    @RutaDatos + 'TallerAutomotriz_PruebaRecuperacion.mdf';

DECLARE @LDF NVARCHAR(4000) =
    @RutaLog + 'TallerAutomotriz_PruebaRecuperacion_log.ldf';

-- Restaurar una copia independiente
DECLARE @SQL NVARCHAR(MAX) =
    N'RESTORE DATABASE TallerAutomotriz_PruebaRecuperacion
    FROM DISK = N''' + REPLACE(@Archivo, '''', '''''') + N'''
    WITH FILE = ' + CAST(@Posicion AS NVARCHAR(10)) + N',
    MOVE ''TallerAutomotriz'' TO N''' 
    + REPLACE(@MDF, '''', '''''') + N''',
    MOVE ''TallerAutomotriz_log'' TO N''' 
    + REPLACE(@LDF, '''', '''''') + N''',
    CHECKSUM, RECOVERY, STATS = 10;';

EXEC (@SQL);

-- Conteo antes de la perdida
SELECT
    'Antes de la perdida' AS Etapa,
    COUNT(*) AS Registros
FROM TallerAutomotriz_PruebaRecuperacion.dbo.TecnicoEspecialidad;

-- Simular eliminacion accidental
DELETE FROM
    TallerAutomotriz_PruebaRecuperacion.dbo.TecnicoEspecialidad;

-- Conteo despues de la perdida
SELECT
    'Despues de la perdida' AS Etapa,
    COUNT(*) AS Registros
FROM TallerAutomotriz_PruebaRecuperacion.dbo.TecnicoEspecialidad;

-- Comprobar que la base original sigue intacta
SELECT
    'Base original' AS Etapa,
    COUNT(*) AS Registros
FROM TallerAutomotriz.dbo.TecnicoEspecialidad;
GO