/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 03: vista vw_HistorialVehiculo

   Historial completo de servicios por vehículo: cliente, orden, estado,
   servicio realizado y técnico que participó en cada servicio.
   Usa LEFT JOIN para que las órdenes sin servicios registrados
   (por ejemplo, recién recibidas) también aparezcan en el historial.
   ===================================================================== */

USE TallerAutomotriz;
GO

CREATE OR ALTER VIEW dbo.vw_HistorialVehiculo
AS
SELECT
    v.IdVehiculo,
    v.Placa,
    v.Marca,
    v.Modelo,
    c.IdCliente,
    c.Nombre + N' ' + c.Apellido AS Cliente,
    o.IdOrden,
    o.FechaIngreso,
    o.FechaSalida,
    o.Estado   AS EstadoOrden,
    s.Nombre   AS Servicio,
    s.Tipo     AS TipoServicio,
    t.Nombre   AS Tecnico,
    os.Precio  AS PrecioServicio,
    os.Horas
FROM dbo.Vehiculo v
JOIN dbo.Cliente c        ON c.IdCliente  = v.IdCliente
JOIN dbo.OrdenTrabajo o   ON o.IdVehiculo = v.IdVehiculo
LEFT JOIN dbo.OrdenServicio os ON os.IdOrden    = o.IdOrden
LEFT JOIN dbo.Servicio s       ON s.IdServicio  = os.IdServicio
LEFT JOIN dbo.Tecnico t        ON t.IdTecnico   = os.IdTecnico;
GO

PRINT 'Script 03 (objetos): vista vw_HistorialVehiculo creada.';
GO
