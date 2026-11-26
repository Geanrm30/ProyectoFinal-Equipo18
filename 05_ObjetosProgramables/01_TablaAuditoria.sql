/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 01: tabla de auditoría de órdenes

   Tabla de soporte para el trigger de auditoría (trg_OrdenTrabajo_Auditoria).
   No tiene llave foránea hacia OrdenTrabajo a propósito: la auditoría debe
   conservar el rastro aunque una orden llegara a eliminarse.
   ===================================================================== */

USE TallerAutomotriz;
GO

IF OBJECT_ID(N'dbo.AuditoriaOrden', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditoriaOrden (
        IdAuditoria    INT IDENTITY(1,1) NOT NULL,
        IdOrden        INT           NOT NULL,
        Accion         VARCHAR(10)   NOT NULL,
        EstadoAnterior VARCHAR(20)   NULL,
        EstadoNuevo    VARCHAR(20)   NULL,
        TotalAnterior  DECIMAL(12,2) NULL,
        TotalNuevo     DECIMAL(12,2) NULL,
        Usuario        SYSNAME       NOT NULL
            CONSTRAINT DF_AuditoriaOrden_Usuario DEFAULT (SUSER_SNAME()),
        Fecha          DATETIME2(0)  NOT NULL
            CONSTRAINT DF_AuditoriaOrden_Fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_AuditoriaOrden PRIMARY KEY (IdAuditoria),
        CONSTRAINT CK_AuditoriaOrden_Accion CHECK (Accion IN ('INSERT', 'UPDATE', 'DELETE'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_AuditoriaOrden_Orden_Fecha'
                 AND object_id = OBJECT_ID(N'dbo.AuditoriaOrden'))
    CREATE NONCLUSTERED INDEX IX_AuditoriaOrden_Orden_Fecha
        ON dbo.AuditoriaOrden (IdOrden, Fecha);
GO

PRINT 'Script 01 (objetos): tabla AuditoriaOrden lista.';
GO
