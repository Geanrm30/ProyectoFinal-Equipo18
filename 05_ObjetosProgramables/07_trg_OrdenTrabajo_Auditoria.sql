/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 07: trg_OrdenTrabajo_Auditoria

   TRIGGER DE AUDITORÍA sobre OrdenTrabajo.
   Registra en AuditoriaOrden quién y cuándo creó una orden, cambió su
   estado o su total, o la eliminó (estado y total anterior y nuevo).

   Funciona con operaciones de varias filas: cada INSERT ... SELECT trabaja
   sobre inserted y deleted como conjuntos.
   ===================================================================== */

USE TallerAutomotriz;
GO

CREATE OR ALTER TRIGGER dbo.trg_OrdenTrabajo_Auditoria
ON dbo.OrdenTrabajo
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Órdenes nuevas
    INSERT INTO dbo.AuditoriaOrden
        (IdOrden, Accion, EstadoAnterior, EstadoNuevo, TotalAnterior, TotalNuevo)
    SELECT i.IdOrden, 'INSERT', NULL, i.Estado, NULL, i.Total
    FROM inserted i
    LEFT JOIN deleted d ON d.IdOrden = i.IdOrden
    WHERE d.IdOrden IS NULL;

    -- Cambios de estado o de total
    INSERT INTO dbo.AuditoriaOrden
        (IdOrden, Accion, EstadoAnterior, EstadoNuevo, TotalAnterior, TotalNuevo)
    SELECT i.IdOrden, 'UPDATE', d.Estado, i.Estado, d.Total, i.Total
    FROM inserted i
    JOIN deleted d ON d.IdOrden = i.IdOrden
    WHERE i.Estado <> d.Estado
       OR i.Total  <> d.Total;

    -- Órdenes eliminadas
    INSERT INTO dbo.AuditoriaOrden
        (IdOrden, Accion, EstadoAnterior, EstadoNuevo, TotalAnterior, TotalNuevo)
    SELECT d.IdOrden, 'DELETE', d.Estado, NULL, d.Total, NULL
    FROM deleted d
    LEFT JOIN inserted i ON i.IdOrden = d.IdOrden
    WHERE i.IdOrden IS NULL;
END;
GO

PRINT 'Script 07 (objetos): trigger trg_OrdenTrabajo_Auditoria creado.';
GO
