-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Seguridad
-- Creacion de logins de SQL Server

USE master;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'login_consulta'
)
BEGIN
    DECLARE @PasswordConsulta NVARCHAR(128) =
        'Ta!9_' + CONVERT(VARCHAR(36), NEWID());

    DECLARE @SQLConsulta NVARCHAR(MAX) =
        N'CREATE LOGIN login_consulta WITH PASSWORD = '
        + QUOTENAME(@PasswordConsulta, '''')
        + N', CHECK_POLICY = ON,
             DEFAULT_DATABASE = TallerAutomotriz;';

    EXEC (@SQLConsulta);

    SELECT @PasswordConsulta AS PasswordConsulta;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'login_operacion'
)
BEGIN
    DECLARE @PasswordOperacion NVARCHAR(128) =
        'Ta!9_' + CONVERT(VARCHAR(36), NEWID());

    DECLARE @SQLOperacion NVARCHAR(MAX) =
        N'CREATE LOGIN login_operacion WITH PASSWORD = '
        + QUOTENAME(@PasswordOperacion, '''')
        + N', CHECK_POLICY = ON,
             DEFAULT_DATABASE = TallerAutomotriz;';

    EXEC (@SQLOperacion);

    SELECT @PasswordOperacion AS PasswordOperacion;
END;
GO

-- Verificacion de logins
SELECT
    name AS Login,
    type_desc AS Tipo,
    is_disabled AS Deshabilitado,
    default_database_name AS BaseDatos
FROM sys.server_principals
WHERE name IN ('login_consulta', 'login_operacion');
GO