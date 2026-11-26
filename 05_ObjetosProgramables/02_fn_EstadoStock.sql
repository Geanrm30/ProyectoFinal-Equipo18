/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 02: función fn_EstadoStock

   Necesidad real: clasificar las existencias de un repuesto para el
   reporte de reabastecimiento (por ejemplo, el reporte del Job nocturno).
     Agotado : existencia en 0
     Bajo    : existencia menor al stock mínimo
     Optimo  : existencia igual o mayor al stock mínimo
   ===================================================================== */

USE TallerAutomotriz;
GO

CREATE OR ALTER FUNCTION dbo.fn_EstadoStock
(
    @Existencia  INT,
    @StockMinimo INT
)
RETURNS VARCHAR(10)
WITH SCHEMABINDING
AS
BEGIN
    RETURN CASE
        WHEN @Existencia IS NULL OR @StockMinimo IS NULL THEN NULL
        WHEN @Existencia <= 0              THEN 'Agotado'
        WHEN @Existencia < @StockMinimo    THEN 'Bajo'
        ELSE 'Optimo'
    END;
END;
GO

PRINT 'Script 02 (objetos): función fn_EstadoStock creada.';
GO
