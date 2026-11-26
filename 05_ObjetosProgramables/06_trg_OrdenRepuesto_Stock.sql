/* =====================================================================
   Equipo 18 - Gestión de Servicios Automotrices
   Objetos programables - Script 06: trg_OrdenRepuesto_Stock

   TRIGGER DE REGLA DE NEGOCIO: "No debe utilizarse una cantidad de
   repuestos superior a la existencia disponible".

   - INSERT : descuenta la cantidad de la existencia.
   - UPDATE : descuenta (o devuelve) solo la diferencia.
   - DELETE : devuelve la cantidad a la existencia.
   - Si algún repuesto no alcanza, se deshace TODA la operación.

   Funciona con operaciones de varias filas: calcula el consumo neto por
   repuesto con inserted/deleted como conjuntos (sin variables escalares),
   incluso si el mismo repuesto aparece en varias filas.
   La restricción CHECK (Existencia >= 0) de Repuesto queda como última
   barrera de seguridad.
   ===================================================================== */

USE TallerAutomotriz;
GO

CREATE OR ALTER TRIGGER dbo.trg_OrdenRepuesto_Stock
ON dbo.OrdenRepuesto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        RETURN;

    -- Consumo neto por repuesto (inserted suma, deleted resta)
    DECLARE @Delta TABLE (
        IdRepuesto INT NOT NULL PRIMARY KEY,
        Consumo    INT NOT NULL
    );

    INSERT INTO @Delta (IdRepuesto, Consumo)
    SELECT x.IdRepuesto, SUM(x.Cantidad)
    FROM (
        SELECT IdRepuesto,  Cantidad FROM inserted
        UNION ALL
        SELECT IdRepuesto, -Cantidad FROM deleted
    ) AS x
    GROUP BY x.IdRepuesto
    HAVING SUM(x.Cantidad) <> 0;

    -- Validación: ningún repuesto puede quedar con existencia negativa
    IF EXISTS (SELECT 1
               FROM @Delta d
               JOIN dbo.Repuesto r WITH (UPDLOCK, HOLDLOCK)
                    ON r.IdRepuesto = d.IdRepuesto
               WHERE r.Existencia - d.Consumo < 0)
    BEGIN
        DECLARE @Detalle NVARCHAR(1500) =
            (SELECT STRING_AGG(
                        CONCAT(r.Codigo, N' (disponible ', r.Existencia,
                               N', requerido ', d.Consumo, N')'), N'; ')
             FROM @Delta d
             JOIN dbo.Repuesto r ON r.IdRepuesto = d.IdRepuesto
             WHERE r.Existencia - d.Consumo < 0);

        DECLARE @Mensaje NVARCHAR(2048) =
            CONCAT(N'Existencia insuficiente de repuestos: ', @Detalle);

        ROLLBACK TRANSACTION;
        THROW 50030, @Mensaje, 1;
    END;

    -- Aplica el descuento (o la devolución) en una sola sentencia
    UPDATE r
    SET r.Existencia = r.Existencia - d.Consumo
    FROM dbo.Repuesto r
    JOIN @Delta d ON d.IdRepuesto = r.IdRepuesto;
END;
GO

PRINT 'Script 06 (objetos): trigger trg_OrdenRepuesto_Stock creado.';
GO
