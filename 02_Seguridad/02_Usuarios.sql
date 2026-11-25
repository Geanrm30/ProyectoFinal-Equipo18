-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Seguridad
-- Creacion de usuarios de la base de datos

USE TallerAutomotriz;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_consulta'
)
BEGIN
    CREATE USER usuario_consulta
    FOR LOGIN login_consulta
    WITH DEFAULT_SCHEMA = dbo;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_operacion'
)
BEGIN
    CREATE USER usuario_operacion
    FOR LOGIN login_operacion
    WITH DEFAULT_SCHEMA = dbo;
END;
GO

-- Verificacion de usuarios y logins asociados
SELECT
    dp.name AS Usuario,
    sp.name AS Login,
    dp.type_desc AS Tipo,
    dp.default_schema_name AS Esquema
FROM sys.database_principals dp
INNER JOIN sys.server_principals sp
    ON dp.sid = sp.sid
WHERE dp.name IN (
    'usuario_consulta',
    'usuario_operacion'
);
GO