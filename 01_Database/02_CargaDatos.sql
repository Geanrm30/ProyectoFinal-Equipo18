/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   VERSIÓN 1.0 - BASE DE DATOS FUNCIONAL
   Script 02: carga de datos de prueba (generados por script)

   - Se puede ejecutar varias veces: limpia las tablas y vuelve a cargar.
   - Ejecutar ANTES de crear triggers y objetos de auditoría (Versión 1.0).
   - Los textos van sin acentos para evitar problemas de codificación.

   Volumen aproximado (2,867 registros):
     Cliente 150 | Vehiculo 250 | Tecnico 12 | TecnicoEspecialidad 24
     Servicio 25 | Repuesto 80 | Cita 400 | OrdenTrabajo 350
     OrdenServicio 701 | OrdenRepuesto 875
   ===================================================================== */

USE TallerAutomotriz;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @hoy DATE = CAST(GETDATE() AS DATE);

BEGIN TRY
    BEGIN TRAN;

    /* -----------------------------------------------------------------
       0. Limpieza (de hijas a padres). Los Id se insertan de forma explicita
          (IDENTITY_INSERT) para no depender del estado previo de las identidades
       ----------------------------------------------------------------- */
    DELETE FROM dbo.OrdenRepuesto;
    DELETE FROM dbo.OrdenServicio;
    DELETE FROM dbo.OrdenTrabajo;
    DELETE FROM dbo.Cita;
    DELETE FROM dbo.Vehiculo;
    DELETE FROM dbo.TecnicoEspecialidad;
    DELETE FROM dbo.Tecnico;
    DELETE FROM dbo.Repuesto;
    DELETE FROM dbo.Servicio;
    DELETE FROM dbo.Cliente;


    /* -----------------------------------------------------------------
       Tabla de números auxiliar (1..400)
       ----------------------------------------------------------------- */
    CREATE TABLE #N (n INT NOT NULL PRIMARY KEY);
    INSERT INTO #N (n)
    SELECT TOP (400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    /* -----------------------------------------------------------------
       1. Cliente (150)
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.Cliente ON;
    INSERT INTO dbo.Cliente (IdCliente, Nombre, Apellido, Cedula, Telefono, Email, FechaRegistro)
    SELECT
        n,
        CHOOSE(n % 10 + 1, N'Jose', N'Maria', N'Carlos', N'Ana', N'Luis',
                           N'Sofia', N'Jorge', N'Lucia', N'Miguel', N'Carmen'),
        CHOOSE((n / 10) % 10 + 1, N'Perez', N'Gonzalez', N'Rodriguez', N'Lopez', N'Martinez',
                                  N'Hernandez', N'Garcia', N'Ramirez', N'Flores', N'Castillo'),
        '001-' + RIGHT('000000' + CAST(100000 + n * 37 AS VARCHAR(10)), 6) + '-0001' + CHAR(65 + n % 26),
        '8' + RIGHT('0000000' + CAST((n * 7919) % 10000000 AS VARCHAR(10)), 7),
        N'cliente' + CAST(n AS NVARCHAR(10)) + N'@correo.com',
        DATEADD(DAY, -((n * 5) % 900), @hoy)
    FROM #N
    WHERE n <= 150
    ORDER BY n;
    SET IDENTITY_INSERT dbo.Cliente OFF;
    DBCC CHECKIDENT ('dbo.Cliente', RESEED, 150) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       2. Vehiculo (250) - cada cliente tiene al menos un vehículo
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.Vehiculo ON;
    INSERT INTO dbo.Vehiculo (IdVehiculo, IdCliente, Placa, VIN, Marca, Modelo, Anio, Kilometraje)
    SELECT
        n,
        ((n - 1) % 150) + 1,
        'M' + RIGHT('000000' + CAST(100000 + n * 13 AS VARCHAR(10)), 6),
        'VIN' + RIGHT('00000000000000' + CAST(n AS VARCHAR(14)), 14),
        CHOOSE(n % 8 + 1, N'Toyota', N'Toyota', N'Hyundai', N'Kia', N'Nissan', N'Suzuki', N'Mazda', N'Honda'),
        CHOOSE(n % 8 + 1, N'Corolla', N'Hilux', N'Accent', N'Rio', N'Sentra', N'Swift', N'Mazda 3', N'Civic'),
        2005 + (n % 20),
        (n * 3571) % 250000
    FROM #N
    WHERE n <= 250
    ORDER BY n;
    SET IDENTITY_INSERT dbo.Vehiculo OFF;
    DBCC CHECKIDENT ('dbo.Vehiculo', RESEED, 250) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       3. Tecnico (12) - el técnico 12 queda inactivo
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.Tecnico ON;
    INSERT INTO dbo.Tecnico (IdTecnico, Nombre, Cedula, Activo)
    SELECT
        n,
        CHOOSE(n, N'Roberto Medina', N'Daniel Ortega', N'Fernando Rivas', N'Alejandro Cruz',
                  N'Kevin Salgado', N'Marvin Blandon', N'Oscar Zeledon', N'Julio Espinoza',
                  N'Henry Talavera', N'Wilmer Acuna', N'Denis Altamirano', N'Freddy Sevilla'),
        '002-' + RIGHT('000000' + CAST(200000 + n * 53 AS VARCHAR(10)), 6) + '-0001' + CHAR(65 + n % 26),
        CASE WHEN n = 12 THEN 0 ELSE 1 END
    FROM #N
    WHERE n <= 12
    ORDER BY n;
    SET IDENTITY_INSERT dbo.Tecnico OFF;
    DBCC CHECKIDENT ('dbo.Tecnico', RESEED, 12) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       4. TecnicoEspecialidad (24) - 2 especialidades por técnico
       ----------------------------------------------------------------- */
    INSERT INTO dbo.TecnicoEspecialidad (IdTecnico, Especialidad)
    SELECT
        t.IdTecnico,
        CHOOSE((t.IdTecnico + x.k * 3) % 7 + 1,
               'Motor', 'Frenos', 'Suspension', 'Electricidad',
               'Transmision', 'AireAcondicionado', 'Diagnostico')
    FROM dbo.Tecnico t
    CROSS JOIN (VALUES (0), (1)) AS x(k);

    /* -----------------------------------------------------------------
       5. Servicio (25 = 12 preventivos + 13 correctivos)
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.Servicio ON;
    INSERT INTO dbo.Servicio (IdServicio, Nombre, Tipo, PrecioBase)
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), v.Nombre, v.Tipo, v.PrecioBase
    FROM (VALUES
        (N'Cambio de aceite y filtro',            'Preventivo',  35.00),
        (N'Rotacion de llantas',                  'Preventivo',  15.00),
        (N'Alineacion y balanceo',                'Preventivo',  40.00),
        (N'Cambio de filtro de aire',             'Preventivo',  12.00),
        (N'Cambio de filtro de combustible',      'Preventivo',  25.00),
        (N'Revision de 10,000 km',                'Preventivo',  50.00),
        (N'Revision de 20,000 km',                'Preventivo',  80.00),
        (N'Cambio de bujias',                     'Preventivo',  45.00),
        (N'Lavado de inyectores',                 'Preventivo',  60.00),
        (N'Revision de niveles y fluidos',        'Preventivo',  10.00),
        (N'Diagnostico computarizado',            'Preventivo',  30.00),
        (N'Servicio de aire acondicionado',       'Preventivo',  70.00),
        (N'Cambio de pastillas de freno',         'Correctivo',  55.00),
        (N'Rectificacion de discos de freno',     'Correctivo',  65.00),
        (N'Cambio de amortiguadores',             'Correctivo', 120.00),
        (N'Cambio de rotulas',                    'Correctivo',  85.00),
        (N'Reparacion de alternador',             'Correctivo', 150.00),
        (N'Cambio de bateria',                    'Correctivo',  20.00),
        (N'Reparacion de motor de arranque',      'Correctivo', 110.00),
        (N'Cambio de embrague',                   'Correctivo', 280.00),
        (N'Reparacion de caja de cambios',        'Correctivo', 450.00),
        (N'Cambio de correa de distribucion',     'Correctivo', 190.00),
        (N'Reparacion de radiador',               'Correctivo', 130.00),
        (N'Cambio de bomba de agua',              'Correctivo', 100.00),
        (N'Reparacion de sistema electrico',      'Correctivo',  90.00)
    ) AS v(Nombre, Tipo, PrecioBase);
    SET IDENTITY_INSERT dbo.Servicio OFF;
    DBCC CHECKIDENT ('dbo.Servicio', RESEED, 25) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       6. Repuesto (80) - algunos con existencia por debajo del mínimo
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.Repuesto ON;
    INSERT INTO dbo.Repuesto (IdRepuesto, Codigo, Nombre, Existencia, StockMinimo, PrecioUnitario)
    SELECT
        n,
        'REP-' + RIGHT('0000' + CAST(n AS VARCHAR(4)), 4),
        CHOOSE(n % 16 + 1,
               N'Filtro de aceite', N'Filtro de aire', N'Pastillas de freno', N'Disco de freno',
               N'Bujia', N'Bateria', N'Amortiguador', N'Rotula',
               N'Correa de distribucion', N'Bomba de agua', N'Aceite de motor 5W30 (litro)',
               N'Liquido de frenos', N'Refrigerante (litro)', N'Faro delantero',
               N'Alternador', N'Kit de embrague') + N' ref ' + CAST(n AS NVARCHAR(4)),
        CASE WHEN n % 10 = 0 THEN n % 4 ELSE 20 + (n * 37) % 180 END,
        5 + (n % 10),
        CAST(5 + (n * 17) % 245 AS DECIMAL(10,2)) + 0.50
    FROM #N
    WHERE n <= 80
    ORDER BY n;
    SET IDENTITY_INSERT dbo.Repuesto OFF;
    DBCC CHECKIDENT ('dbo.Repuesto', RESEED, 80) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       7. Cita (400) - pasadas (Atendida / Cancelada) y futuras (Programada)
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.Cita ON;
    INSERT INTO dbo.Cita (IdCita, IdVehiculo, FechaHora, Motivo, Estado)
    SELECT
        n,
        ((n - 1) % 250) + 1,
        DATEADD(HOUR, 8 + (n % 9),
                CAST(DATEADD(DAY,
                             CASE WHEN n % 7 = 0 THEN 1 + (n % 45)
                                  ELSE -(1 + (n * 7) % 359) END,
                             @hoy) AS DATETIME2(0))),
        CHOOSE(n % 8 + 1,
               N'Cambio de aceite y filtros', N'Revision de frenos', N'Ruido en la suspension',
               N'Luz de check engine encendida', N'Mantenimiento preventivo', N'Aire acondicionado no enfria',
               N'Falla al arrancar', N'Revision general antes de viaje'),
        CASE WHEN n % 7 = 0  THEN 'Programada'
             WHEN n % 10 = 0 THEN 'Cancelada'
             ELSE 'Atendida' END
    FROM #N
    WHERE n <= 400
    ORDER BY n;
    SET IDENTITY_INSERT dbo.Cita OFF;
    DBCC CHECKIDENT ('dbo.Cita', RESEED, 400) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       8. OrdenTrabajo (350): 280 originadas en citas atendidas + 70 sin cita
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.OrdenTrabajo ON;

    ;WITH CitasAtendidas AS (
        SELECT c.IdCita, c.IdVehiculo, c.FechaHora,
               ROW_NUMBER() OVER (ORDER BY c.IdCita) AS rn
        FROM dbo.Cita c
        WHERE c.Estado = 'Atendida'
    )
    INSERT INTO dbo.OrdenTrabajo (IdOrden, IdCita, IdVehiculo, FechaIngreso, FechaSalida, Estado, Total)
    SELECT rn, IdCita, IdVehiculo, FechaHora, NULL, 'Recibida', 0
    FROM CitasAtendidas
    WHERE rn <= 280
    ORDER BY IdCita;

    INSERT INTO dbo.OrdenTrabajo (IdOrden, IdCita, IdVehiculo, FechaIngreso, FechaSalida, Estado, Total)
    SELECT
        280 + n,
        NULL,
        ((n * 11) % 250) + 1,
        DATEADD(HOUR, 8 + (n % 9), CAST(DATEADD(DAY, -(1 + (n * 5) % 359), @hoy) AS DATETIME2(0))),
        NULL, 'Recibida', 0
    FROM #N
    WHERE n <= 70
    ORDER BY n;
    SET IDENTITY_INSERT dbo.OrdenTrabajo OFF;
    DBCC CHECKIDENT ('dbo.OrdenTrabajo', RESEED, 350) WITH NO_INFOMSGS;

    -- Estados: las órdenes recientes están en proceso; las antiguas, cerradas
    UPDATE o
    SET Estado = CASE
            WHEN o.FechaIngreso >= DATEADD(DAY, -14, @hoy)
                 THEN CHOOSE(o.IdOrden % 5 + 1,
                             'Recibida', 'EnDiagnostico', 'EnReparacion', 'EsperandoRepuesto', 'Finalizada')
            WHEN o.IdOrden % 12 = 0 THEN 'Cancelada'
            WHEN o.IdOrden % 6  = 1 THEN 'Finalizada'
            ELSE 'Entregada' END
    FROM dbo.OrdenTrabajo o;

    UPDATE dbo.OrdenTrabajo
    SET FechaSalida = DATEADD(HOUR, 2 + (IdOrden % 20), FechaIngreso)
    WHERE Estado IN ('Finalizada', 'Entregada');

    /* -----------------------------------------------------------------
       9. OrdenServicio (701): de 1 a 3 servicios por orden, con su técnico
          (técnicos 1..11, el 12 está inactivo)
       ----------------------------------------------------------------- */
    SET IDENTITY_INSERT dbo.OrdenServicio ON;
    INSERT INTO dbo.OrdenServicio (IdOrdenServicio, IdOrden, IdServicio, IdTecnico, Precio, Horas)
    SELECT
        ROW_NUMBER() OVER (ORDER BY o.IdOrden, x.j),
        o.IdOrden,
        sv.IdServicio,
        ((o.IdOrden + x.j * 5) % 11) + 1,
        sv.PrecioBase,
        CAST(0.5 + ((o.IdOrden + x.j) % 8) * 0.5 AS DECIMAL(5,2))
    FROM dbo.OrdenTrabajo o
    CROSS JOIN (VALUES (1), (2), (3)) AS x(j)
    JOIN dbo.Servicio sv
         ON sv.IdServicio = ((o.IdOrden * 3 + x.j * 7) % 25) + 1
    WHERE x.j <= 1 + (o.IdOrden % 3)
    ORDER BY o.IdOrden, x.j;
    SET IDENTITY_INSERT dbo.OrdenServicio OFF;

    DECLARE @maxOS INT = (SELECT MAX(IdOrdenServicio) FROM dbo.OrdenServicio);
    DBCC CHECKIDENT ('dbo.OrdenServicio', RESEED, @maxOS) WITH NO_INFOMSGS;

    /* -----------------------------------------------------------------
       10. OrdenRepuesto (875): de 1 a 4 repuestos por orden
       ----------------------------------------------------------------- */
    INSERT INTO dbo.OrdenRepuesto (IdOrden, IdRepuesto, Cantidad, PrecioUnitario)
    SELECT
        o.IdOrden,
        rp.IdRepuesto,
        1 + ((o.IdOrden + x.j) % 4),
        rp.PrecioUnitario
    FROM dbo.OrdenTrabajo o
    CROSS JOIN (VALUES (1), (2), (3), (4)) AS x(j)
    JOIN dbo.Repuesto rp
         ON rp.IdRepuesto = ((o.IdOrden * 5 + x.j * 11) % 80) + 1
    WHERE x.j <= 1 + (o.IdOrden % 4)
    ORDER BY o.IdOrden, x.j;

    /* -----------------------------------------------------------------
       11. Total de cada orden = servicios + repuestos (0 si está cancelada)
       ----------------------------------------------------------------- */
    UPDATE o
    SET Total = CASE WHEN o.Estado = 'Cancelada' THEN 0
                     ELSE ISNULL(s.Subtotal, 0) + ISNULL(r.Subtotal, 0) END
    FROM dbo.OrdenTrabajo o
    OUTER APPLY (SELECT SUM(os.Precio) AS Subtotal
                 FROM dbo.OrdenServicio os
                 WHERE os.IdOrden = o.IdOrden) s
    OUTER APPLY (SELECT SUM(orp.Cantidad * orp.PrecioUnitario) AS Subtotal
                 FROM dbo.OrdenRepuesto orp
                 WHERE orp.IdOrden = o.IdOrden) r;

    DROP TABLE #N;

    COMMIT TRAN;
    PRINT 'Script 02 ejecutado: datos de prueba cargados.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
END CATCH;
GO

/* =====================================================================
   VERIFICACIÓN: conteos por tabla (el total debe estar entre 1,000 y 3,000)
   ===================================================================== */
SELECT 'Cliente' AS Tabla, COUNT(*) AS Registros FROM dbo.Cliente
UNION ALL SELECT 'Vehiculo',            COUNT(*) FROM dbo.Vehiculo
UNION ALL SELECT 'Tecnico',             COUNT(*) FROM dbo.Tecnico
UNION ALL SELECT 'TecnicoEspecialidad', COUNT(*) FROM dbo.TecnicoEspecialidad
UNION ALL SELECT 'Servicio',            COUNT(*) FROM dbo.Servicio
UNION ALL SELECT 'Repuesto',            COUNT(*) FROM dbo.Repuesto
UNION ALL SELECT 'Cita',                COUNT(*) FROM dbo.Cita
UNION ALL SELECT 'OrdenTrabajo',        COUNT(*) FROM dbo.OrdenTrabajo
UNION ALL SELECT 'OrdenServicio',       COUNT(*) FROM dbo.OrdenServicio
UNION ALL SELECT 'OrdenRepuesto',       COUNT(*) FROM dbo.OrdenRepuesto
UNION ALL SELECT 'TOTAL', (SELECT COUNT(*) FROM dbo.Cliente) + (SELECT COUNT(*) FROM dbo.Vehiculo)
    + (SELECT COUNT(*) FROM dbo.Tecnico) + (SELECT COUNT(*) FROM dbo.TecnicoEspecialidad)
    + (SELECT COUNT(*) FROM dbo.Servicio) + (SELECT COUNT(*) FROM dbo.Repuesto)
    + (SELECT COUNT(*) FROM dbo.Cita) + (SELECT COUNT(*) FROM dbo.OrdenTrabajo)
    + (SELECT COUNT(*) FROM dbo.OrdenServicio) + (SELECT COUNT(*) FROM dbo.OrdenRepuesto);

-- Distribución de órdenes por estado
SELECT Estado, COUNT(*) AS Ordenes
FROM dbo.OrdenTrabajo
GROUP BY Estado
ORDER BY Ordenes DESC;

-- Repuestos por debajo del mínimo (sirven para el reporte del Job)
SELECT COUNT(*) AS RepuestosBajoMinimo
FROM dbo.Repuesto
WHERE Existencia < StockMinimo;
GO
