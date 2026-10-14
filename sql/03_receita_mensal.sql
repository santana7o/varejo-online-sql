-- =====================================================================
-- 03 - Receita mensal, media movel e comparacao com o mesmo mes do ano anterior
-- Pergunta: qual e a sazonalidade e o mes a mes esta acima do ano anterior?
-- =====================================================================
WITH mensal AS (
    SELECT
        DATE_TRUNC('month', data)       AS mes,
        SUM(valor)                      AS receita,
        COUNT(*)                        AS pedidos,
        COUNT(DISTINCT cliente_id)      AS clientes
    FROM fato_pedidos
    WHERE data < DATE '2011-12-01'      -- dez/2011 incompleto
    GROUP BY 1
)
SELECT
    STRFTIME(mes, '%Y-%m')                                              AS mes,
    ROUND(receita, 0)                                                   AS receita,
    pedidos,
    clientes,
    ROUND(AVG(receita) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0)
                                                                        AS media_movel_3m,
    ROUND(LAG(receita, 12) OVER (ORDER BY mes), 0)                      AS receita_ano_anterior,
    ROUND(100.0 * (receita / LAG(receita, 12) OVER (ORDER BY mes) - 1), 1)
                                                                        AS var_anual_pct,
    ROUND(100.0 * receita / SUM(receita) OVER (PARTITION BY
        CASE WHEN mes < DATE '2010-12-01' THEN 1 ELSE 2 END), 1)        AS pct_do_ano
FROM mensal
ORDER BY mes;
