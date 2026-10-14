-- =====================================================================
-- 08 - Cancelamentos: taxa mensal e produtos com mais valor cancelado
-- Pergunta: quanto da receita se perde em cancelamentos e onde?
-- =====================================================================
WITH vendas_mes AS (
    SELECT DATE_TRUNC('month', data) AS mes, SUM(valor) AS receita_bruta
    FROM fato_vendas
    GROUP BY 1
),
canc_mes AS (
    SELECT DATE_TRUNC('month', data) AS mes,
           SUM(valor)                AS valor_cancelado,
           COUNT(DISTINCT invoice)   AS notas_canceladas
    FROM fato_cancelamentos
    GROUP BY 1
)
SELECT
    STRFTIME(v.mes, '%Y-%m')                                   AS mes,
    ROUND(v.receita_bruta, 0)                                  AS receita_bruta,
    ROUND(COALESCE(c.valor_cancelado, 0), 0)                   AS valor_cancelado,
    COALESCE(c.notas_canceladas, 0)                            AS notas_canceladas,
    ROUND(100.0 * COALESCE(c.valor_cancelado, 0) / v.receita_bruta, 1) AS taxa_cancelamento_pct
FROM vendas_mes v
LEFT JOIN canc_mes c USING (mes)
WHERE v.mes < DATE '2011-12-01'
ORDER BY v.mes;
