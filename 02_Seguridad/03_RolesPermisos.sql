-- Equipo 18 - Gestion de Servicios Automotrices
-- Integrante B - Seguridad
-- Creacion de roles y asignacion de permisos

USE TallerAutomotriz;
GO

-- Crear roles
IF DATABASE_PRINCIPAL_ID('rol_consulta') IS NULL
    CREATE ROLE rol_consulta AUTHORIZATION dbo;
GO

IF DATABASE_PRINCIPAL_ID('rol_operacion') IS NULL
    CREATE ROLE rol_operacion AUTHORIZATION dbo;
GO

-- Permisos de consulta para ambos roles
GRANT SELECT ON dbo.Vehiculo TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.Cita TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.OrdenTrabajo TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.OrdenServicio TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.Servicio TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.Tecnico TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.Repuesto TO rol_consulta, rol_operacion;
GRANT SELECT ON dbo.OrdenRepuesto TO rol_consulta, rol_operacion;
GO

-- Permisos adicionales del rol operativo
GRANT INSERT, UPDATE ON dbo.OrdenTrabajo
TO rol_operacion;
GO

-- Restringir eliminacion de registros
DENY DELETE ON SCHEMA::dbo TO rol_consulta;
DENY DELETE ON SCHEMA::dbo TO rol_operacion;
GO

-- Asociar usuarios a los roles
IF IS_ROLEMEMBER('rol_consulta', 'usuario_consulta') = 0
    ALTER ROLE rol_consulta ADD MEMBER usuario_consulta;
GO

IF IS_ROLEMEMBER('rol_operacion', 'usuario_operacion') = 0
    ALTER ROLE rol_operacion ADD MEMBER usuario_operacion;
GO

-- Verificar miembros de los roles
SELECT
    r.name AS Rol,
    u.name AS Usuario
FROM sys.database_role_members drm
INNER JOIN sys.database_principals r
    ON drm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals u
    ON drm.member_principal_id = u.principal_id
WHERE r.name IN ('rol_consulta', 'rol_operacion');
GO

-- Verificar permisos asignados
SELECT
    dp.name AS Rol,
    p.permission_name AS Permiso,
    p.state_desc AS Estado,
    p.class_desc AS Clase,
    CASE
        WHEN p.class = 1 THEN OBJECT_NAME(p.major_id)
        WHEN p.class = 3 THEN SCHEMA_NAME(p.major_id)
    END AS Objeto
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp
    ON p.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('rol_consulta', 'rol_operacion')
ORDER BY dp.name, Objeto, p.permission_name;
GO