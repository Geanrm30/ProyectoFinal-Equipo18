# Reto de diseño – Equipo 18: Gestión de Servicios Automotrices

Documento de análisis que traduce los requerimientos del negocio en decisiones técnicas de SQL Server.
Pertenece a la **Versión 1.0 – Base de datos funcional**.

## Flujo seguido

```
REQUERIMIENTO DEL NEGOCIO
          ↓
ANÁLISIS
          ↓
ENTIDADES Y RELACIONES
          ↓
TIPOS DE DATOS
          ↓
PK / FK
          ↓
CHECK / UNIQUE / NOT NULL
          ↓
ÍNDICES
          ↓
DATOS DE PRUEBA
          ↓
BASE DE DATOS FUNCIONAL
```

## 1. Análisis: sustantivos y verbos del negocio

| Del enunciado | Se convierte en |
|---|---|
| clientes, vehículos, técnicos, citas, órdenes de trabajo, servicios, repuestos | Entidades (tablas) |
| "un cliente registra varios vehículos" | Relación 1:N |
| "una orden incluye múltiples servicios" | Relación N:M resuelta con tabla intermedia |
| "una orden consume varios repuestos" | Relación N:M resuelta con tabla intermedia |
| "un técnico tiene diferentes especialidades" | Relación 1:N hacia una tabla de especialidades |
| "una orden puede originarse de una cita" | Relación 0..1 a 1 (cita opcional) |

## 2. Entidades y relaciones

```
Cliente 1──N Vehiculo 1──N Cita 1──0..1 OrdenTrabajo
                  │                          │
                  └───────────1──N───────────┤
                                             ├─N── OrdenServicio ──N─ Servicio
                                             │            │
                                             │            └──N─1─ Tecnico 1──N TecnicoEspecialidad
                                             └─N── OrdenRepuesto ──N─ Repuesto
```

10 tablas: Cliente, Vehiculo, Tecnico, TecnicoEspecialidad, Cita, OrdenTrabajo,
Servicio, OrdenServicio, Repuesto, OrdenRepuesto. Tabla de soporte (Paso 6): AuditoriaOrden.

## 3. Trazabilidad: requerimiento → decisión técnica

| # | Requerimiento del negocio | Decisión técnica en SQL Server |
|---|---|---|
| 1 | Un cliente puede registrar varios vehículos | `Vehiculo.IdCliente` con FK a `Cliente` (relación 1:N). |
| 2 | Cada vehículo con identificador único (placa o VIN) | `Placa` y `VIN` con `UNIQUE` y `NOT NULL`. Tipos `VARCHAR(10)` y `VARCHAR(17)` (el VIN estándar tiene 17 caracteres). |
| 3 | Citas asociadas a un vehículo y una fecha | `Cita.IdVehiculo` FK y `FechaHora DATETIME2(0) NOT NULL`. Índice `IX_Cita_FechaHora`. |
| 4 | Una orden puede originarse de una cita | `OrdenTrabajo.IdCita` FK **nullable** (la orden puede existir sin cita). Índice único filtrado `UX_Orden_Cita` para que una cita genere como máximo una orden. |
| 5 | Una orden puede incluir múltiples servicios | Tabla intermedia `OrdenServicio` con atributos propios (precio cobrado, horas) y `Servicio` como catálogo. |
| 6 | Los técnicos pueden tener diferentes especialidades | `TecnicoEspecialidad` con PK compuesta (`IdTecnico`, `Especialidad`) y `CHECK` con la lista de especialidades válidas. |
| 7 | Una orden puede consumir varios repuestos | `OrdenRepuesto` con PK compuesta (`IdOrden`, `IdRepuesto`) y `Cantidad` con `CHECK (> 0)`. |
| 8 | No usar más repuestos que la existencia | Doble protección: `CHECK (Existencia >= 0)` en `Repuesto` y trigger sobre `OrdenRepuesto` (Paso 6) que valida y descuenta existencias para operaciones de varias filas. |
| 9 | Conservar el historial de servicios por vehículo | Sin `ON DELETE CASCADE`: no se borra información. Una orden anulada pasa a estado `Cancelada`. Vista de historial y procedimiento `sp_HistorialVehiculo` (Paso 6). Índice `IX_Orden_Vehiculo`. |
| 10 | Las órdenes manejan diferentes estados | `OrdenTrabajo.Estado` con `CHECK` (Recibida, EnDiagnostico, EnReparacion, EsperandoRepuesto, Finalizada, Entregada, Cancelada), `sp_CambiarEstadoOrden` para validar transiciones y trigger de auditoría. |
| 11 | Saber qué técnico participó en cada servicio | `OrdenServicio.IdTecnico` FK y `NOT NULL`. |
| 12 | Consultas por placa, cliente, fecha y estado eficientes | Placa: índice del `UNIQUE`. Cliente: `IX_Cliente_Apellido_Nombre`. Fecha y estado: `IX_Orden_Estado_FechaIngreso`. Historial: `IX_Orden_Vehiculo` con columnas incluidas. |

## 4. Decisiones de tipos de datos

| Dato | Tipo | Motivo |
|---|---|---|
| Identificadores | `INT IDENTITY(1,1)` | Simple, compacto y suficiente para el volumen. |
| Dinero | `DECIMAL(10,2)` / `DECIMAL(12,2)` | Evita errores de redondeo de `FLOAT`. |
| Fechas con hora | `DATETIME2(0)` | Precisión de segundos, más preciso y liviano que `DATETIME`. |
| Fecha sin hora | `DATE` | Fecha de registro del cliente. |
| Texto con acentos | `NVARCHAR` | Nombres, marcas y descripciones. |
| Códigos (placa, cédula, VIN) | `VARCHAR` | Solo caracteres ASCII. |
| Banderas | `BIT` | `Tecnico.Activo`. |

## 5. Resumen de restricciones

- **PK:** una por tabla (compuestas en `TecnicoEspecialidad` y `OrdenRepuesto`).
- **FK (10):** Vehiculo→Cliente, TecnicoEspecialidad→Tecnico, Cita→Vehiculo, OrdenTrabajo→Cita,
  OrdenTrabajo→Vehiculo, OrdenServicio→OrdenTrabajo / Servicio / Tecnico, OrdenRepuesto→OrdenTrabajo / Repuesto.
- **UNIQUE:** Cedula (Cliente, Tecnico), Placa, VIN, Nombre (Servicio), Codigo (Repuesto).
- **CHECK:** año del vehículo, kilometraje, estados de cita y orden, fechas coherentes, precios, horas,
  cantidades y existencias no negativas.
- **NOT NULL:** en todos los datos obligatorios del negocio.

## 6. Estado de avance

| Etapa del flujo | Estado | Evidencia |
|---|---|---|
| Análisis, entidades y relaciones | Hecho | Este documento |
| Tipos, PK/FK, CHECK/UNIQUE/NOT NULL, índices | Hecho | `01_Database/01_CrearBaseDatos.sql` |
| Datos de prueba | Pendiente | `02_CargaDatos.sql` |
| Base de datos funcional (Versión 1.0) | Pendiente | Respaldo `.bak` y tag `v1.0` |
