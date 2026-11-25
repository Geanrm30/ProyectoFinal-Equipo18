/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   VERSIÓN 1.0 - BASE DE DATOS FUNCIONAL
   Script 01: creación de la base de datos, tablas, restricciones e índices
   Motor: SQL Server (SSMS)
   ===================================================================== */

USE master;
GO

IF DB_ID(N'TallerAutomotriz') IS NULL
    CREATE DATABASE TallerAutomotriz;
GO

USE TallerAutomotriz;
GO

/* ---------------------------------------------------------------------
   1. Cliente
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Cliente (
    IdCliente     INT IDENTITY(1,1) NOT NULL,
    Nombre        NVARCHAR(60)  NOT NULL,
    Apellido      NVARCHAR(60)  NOT NULL,
    Cedula        VARCHAR(16)   NOT NULL,
    Telefono      VARCHAR(20)   NOT NULL,
    Email         NVARCHAR(100) NULL,
    FechaRegistro DATE          NOT NULL
        CONSTRAINT DF_Cliente_FechaRegistro DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT PK_Cliente        PRIMARY KEY (IdCliente),
    CONSTRAINT UQ_Cliente_Cedula UNIQUE (Cedula)
);
GO

/* ---------------------------------------------------------------------
   2. Vehiculo  (un cliente puede tener varios vehículos)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Vehiculo (
    IdVehiculo  INT IDENTITY(1,1) NOT NULL,
    IdCliente   INT          NOT NULL,
    Placa       VARCHAR(10)  NOT NULL,
    VIN         VARCHAR(17)  NOT NULL,
    Marca       NVARCHAR(40) NOT NULL,
    Modelo      NVARCHAR(40) NOT NULL,
    Anio        SMALLINT     NOT NULL,
    Kilometraje INT          NOT NULL CONSTRAINT DF_Vehiculo_Km DEFAULT (0),
    CONSTRAINT PK_Vehiculo        PRIMARY KEY (IdVehiculo),
    CONSTRAINT UQ_Vehiculo_Placa  UNIQUE (Placa),
    CONSTRAINT UQ_Vehiculo_VIN    UNIQUE (VIN),
    CONSTRAINT FK_Vehiculo_Cliente FOREIGN KEY (IdCliente) REFERENCES dbo.Cliente (IdCliente),
    CONSTRAINT CK_Vehiculo_Anio   CHECK (Anio BETWEEN 1980 AND 2100),
    CONSTRAINT CK_Vehiculo_Km     CHECK (Kilometraje >= 0)
);
GO

/* ---------------------------------------------------------------------
   3. Tecnico
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Tecnico (
    IdTecnico INT IDENTITY(1,1) NOT NULL,
    Nombre    NVARCHAR(100) NOT NULL,
    Cedula    VARCHAR(16)   NOT NULL,
    Activo    BIT           NOT NULL CONSTRAINT DF_Tecnico_Activo DEFAULT (1),
    CONSTRAINT PK_Tecnico        PRIMARY KEY (IdTecnico),
    CONSTRAINT UQ_Tecnico_Cedula UNIQUE (Cedula)
);
GO

/* ---------------------------------------------------------------------
   4. TecnicoEspecialidad  (un técnico puede tener varias especialidades)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.TecnicoEspecialidad (
    IdTecnico    INT          NOT NULL,
    Especialidad VARCHAR(30)  NOT NULL,
    CONSTRAINT PK_TecnicoEspecialidad PRIMARY KEY (IdTecnico, Especialidad),
    CONSTRAINT FK_TecEsp_Tecnico FOREIGN KEY (IdTecnico) REFERENCES dbo.Tecnico (IdTecnico),
    CONSTRAINT CK_TecEsp_Especialidad CHECK (Especialidad IN
        ('Motor','Frenos','Suspension','Electricidad','Transmision','AireAcondicionado','Diagnostico'))
);
GO

/* ---------------------------------------------------------------------
   5. Cita  (asociada a un vehículo y una fecha)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Cita (
    IdCita     INT IDENTITY(1,1) NOT NULL,
    IdVehiculo INT           NOT NULL,
    FechaHora  DATETIME2(0)  NOT NULL,
    Motivo     NVARCHAR(200) NOT NULL,
    Estado     VARCHAR(15)   NOT NULL CONSTRAINT DF_Cita_Estado DEFAULT ('Programada'),
    CONSTRAINT PK_Cita PRIMARY KEY (IdCita),
    CONSTRAINT FK_Cita_Vehiculo FOREIGN KEY (IdVehiculo) REFERENCES dbo.Vehiculo (IdVehiculo),
    CONSTRAINT CK_Cita_Estado CHECK (Estado IN ('Programada','Atendida','Cancelada'))
);
GO

/* ---------------------------------------------------------------------
   6. OrdenTrabajo  (puede originarse de una cita; IdCita es opcional)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.OrdenTrabajo (
    IdOrden      INT IDENTITY(1,1) NOT NULL,
    IdCita       INT          NULL,
    IdVehiculo   INT          NOT NULL,
    FechaIngreso DATETIME2(0) NOT NULL CONSTRAINT DF_Orden_FechaIngreso DEFAULT (SYSDATETIME()),
    FechaSalida  DATETIME2(0) NULL,
    Estado       VARCHAR(20)  NOT NULL CONSTRAINT DF_Orden_Estado DEFAULT ('Recibida'),
    Total        DECIMAL(12,2) NOT NULL CONSTRAINT DF_Orden_Total DEFAULT (0),
    CONSTRAINT PK_OrdenTrabajo PRIMARY KEY (IdOrden),
    CONSTRAINT FK_Orden_Cita     FOREIGN KEY (IdCita)     REFERENCES dbo.Cita (IdCita),
    CONSTRAINT FK_Orden_Vehiculo FOREIGN KEY (IdVehiculo) REFERENCES dbo.Vehiculo (IdVehiculo),
    CONSTRAINT CK_Orden_Estado CHECK (Estado IN
        ('Recibida','EnDiagnostico','EnReparacion','EsperandoRepuesto','Finalizada','Entregada','Cancelada')),
    CONSTRAINT CK_Orden_Fechas CHECK (FechaSalida IS NULL OR FechaSalida >= FechaIngreso),
    CONSTRAINT CK_Orden_Total  CHECK (Total >= 0)
);
GO

/* ---------------------------------------------------------------------
   7. Servicio  (catálogo)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Servicio (
    IdServicio INT IDENTITY(1,1) NOT NULL,
    Nombre     NVARCHAR(80)  NOT NULL,
    Tipo       VARCHAR(12)   NOT NULL,
    PrecioBase DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Servicio PRIMARY KEY (IdServicio),
    CONSTRAINT UQ_Servicio_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Servicio_Tipo   CHECK (Tipo IN ('Preventivo','Correctivo')),
    CONSTRAINT CK_Servicio_Precio CHECK (PrecioBase >= 0)
);
GO

/* ---------------------------------------------------------------------
   8. OrdenServicio  (servicios de una orden y técnico que lo realizó)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.OrdenServicio (
    IdOrdenServicio INT IDENTITY(1,1) NOT NULL,
    IdOrden    INT           NOT NULL,
    IdServicio INT           NOT NULL,
    IdTecnico  INT           NOT NULL,
    Precio     DECIMAL(10,2) NOT NULL,
    Horas      DECIMAL(5,2)  NOT NULL CONSTRAINT DF_OrdenServicio_Horas DEFAULT (1),
    CONSTRAINT PK_OrdenServicio PRIMARY KEY (IdOrdenServicio),
    CONSTRAINT FK_OrdSrv_Orden    FOREIGN KEY (IdOrden)    REFERENCES dbo.OrdenTrabajo (IdOrden),
    CONSTRAINT FK_OrdSrv_Servicio FOREIGN KEY (IdServicio) REFERENCES dbo.Servicio (IdServicio),
    CONSTRAINT FK_OrdSrv_Tecnico  FOREIGN KEY (IdTecnico)  REFERENCES dbo.Tecnico (IdTecnico),
    CONSTRAINT CK_OrdSrv_Precio CHECK (Precio >= 0),
    CONSTRAINT CK_OrdSrv_Horas  CHECK (Horas > 0)
);
GO

/* ---------------------------------------------------------------------
   9. Repuesto
   --------------------------------------------------------------------- */
CREATE TABLE dbo.Repuesto (
    IdRepuesto     INT IDENTITY(1,1) NOT NULL,
    Codigo         VARCHAR(20)   NOT NULL,
    Nombre         NVARCHAR(80)  NOT NULL,
    Existencia     INT           NOT NULL,
    StockMinimo    INT           NOT NULL CONSTRAINT DF_Repuesto_StockMin DEFAULT (5),
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Repuesto PRIMARY KEY (IdRepuesto),
    CONSTRAINT UQ_Repuesto_Codigo UNIQUE (Codigo),
    CONSTRAINT CK_Repuesto_Existencia CHECK (Existencia >= 0),
    CONSTRAINT CK_Repuesto_StockMin   CHECK (StockMinimo >= 0),
    CONSTRAINT CK_Repuesto_Precio     CHECK (PrecioUnitario >= 0)
);
GO

/* ---------------------------------------------------------------------
   10. OrdenRepuesto  (repuestos consumidos por una orden)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.OrdenRepuesto (
    IdOrden        INT           NOT NULL,
    IdRepuesto     INT           NOT NULL,
    Cantidad       INT           NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_OrdenRepuesto PRIMARY KEY (IdOrden, IdRepuesto),
    CONSTRAINT FK_OrdRep_Orden    FOREIGN KEY (IdOrden)    REFERENCES dbo.OrdenTrabajo (IdOrden),
    CONSTRAINT FK_OrdRep_Repuesto FOREIGN KEY (IdRepuesto) REFERENCES dbo.Repuesto (IdRepuesto),
    CONSTRAINT CK_OrdRep_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_OrdRep_Precio   CHECK (PrecioUnitario >= 0)
);
GO

/* =====================================================================
   ÍNDICES ADICIONALES (además de PK y UNIQUE)
   Respaldan las consultas por placa, cliente, fecha y estado.
   La búsqueda por placa ya está cubierta por UQ_Vehiculo_Placa.
   ===================================================================== */

-- Búsqueda por cliente (apellido, nombre)
CREATE NONCLUSTERED INDEX IX_Cliente_Apellido_Nombre
    ON dbo.Cliente (Apellido, Nombre);
GO

-- Consultas por estado y fecha de ingreso
CREATE NONCLUSTERED INDEX IX_Orden_Estado_FechaIngreso
    ON dbo.OrdenTrabajo (Estado, FechaIngreso);
GO

-- Historial de un vehículo
CREATE NONCLUSTERED INDEX IX_Orden_Vehiculo
    ON dbo.OrdenTrabajo (IdVehiculo)
    INCLUDE (Estado, FechaIngreso, Total);
GO

-- Una cita genera como máximo una orden
CREATE UNIQUE NONCLUSTERED INDEX UX_Orden_Cita
    ON dbo.OrdenTrabajo (IdCita)
    WHERE IdCita IS NOT NULL;
GO

-- Citas por fecha
CREATE NONCLUSTERED INDEX IX_Cita_FechaHora
    ON dbo.Cita (FechaHora);
GO

PRINT 'Script 01 ejecutado: esquema de TallerAutomotriz creado.';
GO
