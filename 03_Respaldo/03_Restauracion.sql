-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Respaldo y recuperacion
-- Restauracion de informacion perdida

USE master;
GO

-- Verificar que existe la base de prueba
IF DB_ID('TallerAutomotriz_PruebaRecuperacion') IS NULL
    THROW 50004, 'No existe la base de prueba.', 1;

DECLARE @Archivo NVARCHAR(4000);
DECLARE @Posicion INT;

-- Identificar el respaldo utilizado en la simulacion
SELECT TOP 1
    @Archivo = m.physical_device_name,
    @Posicion = b.position
FROM msdb.dbo.restorehistory r
INNER JOIN msdb.dbo.backupset b
    ON r.backup_set_id = b.backup_set_id
INNER JOIN msdb.dbo.backupmediafamily m
    ON b.media_set_id = m.media_set_id
WHERE r.destination_database_name =
    'TallerAutomotriz_PruebaRecuperacion'
    AND b.database_name = 'TallerAutomotriz'
    AND b.type = 'D'
    AND m.device_type = 2
ORDER BY r.restore_history_id DESC;

IF @Archivo IS NULL
    THROW 50005, 'No se encontro el respaldo original.', 1;

-- Obtener las rutas de la copia de prueba
DECLARE @MDF NVARCHAR(4000);
DECLARE @LDF NVARCHAR(4000);

SELECT @MDF = physical_name
FROM sys.master_files
WHERE database_id =
    DB_ID('TallerAutomotriz_PruebaRecuperacion')
    AND type = 0;

SELECT @LDF = physical_name
FROM sys.master_files
WHERE database_id =
    DB_ID('TallerAutomotriz_PruebaRecuperacion')
    AND type = 1;

IF @MDF IS NULL OR @LDF IS NULL
    THROW 50006, 'No se encontraron los archivos de prueba.', 1;

-- Restaurar exclusivamente la copia de prueba
DECLARE @SQL NVARCHAR(MAX) =
    N'RESTORE DATABASE TallerAutomotriz_PruebaRecuperacion
    FROM DISK = N''' + REPLACE(@Archivo, '''', '''''') + N'''
    WITH FILE = ' + CAST(@Posicion AS NVARCHAR(10)) + N',
    MOVE ''TallerAutomotriz'' TO N'''
    + REPLACE(@MDF, '''', '''''') + N''',
    MOVE ''TallerAutomotriz_log'' TO N'''
    + REPLACE(@LDF, '''', '''''') + N''',
    REPLACE, CHECKSUM, RECOVERY, STATS = 10;';

EXEC (@SQL);

-- Verificar los registros recuperados
SELECT
    'Despues de la restauracion' AS Etapa,
    COUNT(*) AS Registros
FROM TallerAutomotriz_PruebaRecuperacion.dbo.TecnicoEspecialidad;

SELECT
    'Base original' AS Etapa,
    COUNT(*) AS Registros
FROM TallerAutomotriz.dbo.TecnicoEspecialidad;
GO