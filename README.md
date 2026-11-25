# Proyecto Final – Administración y Gestión de Bases de Datos

**Equipo 18 – Gestión de Servicios Automotrices**
Universidad Americana (UAM) – SQL Server

## Integrantes

| Integrante | Áreas principales |
|---|---|
| Integrante A: Geanfranco Rodriguez Mendieta | Base de datos, objetos programables, optimización, documentación |
| Integrante B: Anthony Sying Gonzalez Chow | Seguridad, respaldo, interoperabilidad, automatización, monitoreo |

## Descripción del negocio

Empresa dedicada al mantenimiento preventivo y correctivo de vehículos. Administra clientes,
vehículos, técnicos, citas, órdenes de trabajo, servicios realizados y repuestos utilizados,
y conserva el historial completo de reparaciones.

## Estructura del repositorio

```
ProyectoFinal/
├── 01_Database/               Creación y carga de la base de datos (versión 1.0)
├── 02_Seguridad/              Logins, usuarios, roles y permisos
├── 03_Respaldo/               Respaldo y recuperación
├── 04_Interoperabilidad/      Linked server, autenticación y sinónimo
├── 05_ObjetosProgramables/    Función, procedimientos y triggers
├── 06_Automatizacion/         SQL Server Agent: Job, Steps, Schedule y Database Mail
├── 07_Monitoreo/              Monitoreo, concurrencia y Extended Events
├── 08_Optimizacion/           Caso de optimización (antes / después)
├── 09_Documentacion/          Reto de diseño, catálogo del sistema y diccionario de datos
├── README.md
└── CHANGELOG.md
```

## Cómo reproducir el proyecto

Ejecutar los scripts en SSMS en el orden de las carpetas:

1. `01_Database/01_CrearBaseDatos.sql`
2. `01_Database/02_CargaDatos.sql`
3. Scripts de cada carpeta, en orden numérico.

## Versiones

- **Versión 1.0 – Base de datos funcional:** esquema de 10 tablas, restricciones, índices y datos de prueba.
- **Versión 2.0 – Base de datos administrada y optimizada:** seguridad, respaldo, interoperabilidad,
  objetos programables, automatización, monitoreo y optimización.

Los cambios entre versiones se registran en `CHANGELOG.md`.
