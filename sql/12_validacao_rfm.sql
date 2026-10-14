-- =====================================================================
-- 12 - Validacao da segmentacao RFM (backtest)
-- Pergunta: os segmentos preveem o comportamento futuro, ou sao so uma foto do passado?
-- Metodo: segmenta os clientes com a mesma regra em 10/12/2010 (usando os 12 meses
-- anteriores) e mede o que cada segmento fez nos 12 meses seguintes (10/12/2010 a 09/12/2011).
-- =====================================================================
WITH segmentos AS (
    SELECT * FROM rfm_clientes(DATE '2010-12-10')
),
futuro AS (
    SELECT cliente_id, COUNT(*) AS pedidos, SUM(valor) AS receita
    FROM fato_pedidos
    WHERE cliente_id IS NOT NULL
      AND data >= DATE '2010-12-10'
      AND data <  DATE '2011-12-10'
    GROUP BY cliente_id
)
SELECT
    s.segmento,
    COUNT(*)                                                         AS clientes,
    ROUND(SUM(s.valor) / COUNT(*), 0)                                AS receita_antes_por_cliente,
    ROUND(100.0 * COUNT(f.cliente_id) / COUNT(*), 1)                 AS pct_voltou_a_comprar,
    ROUND(SUM(COALESCE(f.receita, 0)) / COUNT(*), 0)                 AS receita_depois_por_cliente,
    ROUND(100.0 * (SUM(COALESCE(f.receita, 0)) / SUM(s.valor) - 1), 1)
                                                                     AS var_receita_por_cliente_pct,
    ROUND(MEDIAN(f.receita), 0)                                      AS mediana_receita_quem_voltou,
    ROUND(100.0 * SUM(COALESCE(f.receita, 0))
          / SUM(SUM(COALESCE(f.receita, 0))) OVER (), 1)             AS pct_receita_depois
FROM segmentos s
LEFT JOIN futuro f USING (cliente_id)
GROUP BY s.segmento
ORDER BY s.segmento;
