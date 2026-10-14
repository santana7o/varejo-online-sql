-- =====================================================================
-- 10 - Desempenho por pais (Ano 2)
-- Pergunta: onde esta a receita fora do Reino Unido e como o ticket se compara?
-- =====================================================================
WITH paises AS (
    SELECT
        pais,
        SUM(valor)                  AS receita,
        COUNT(*)                    AS pedidos,
        COUNT(DISTINCT cliente_id)  AS clientes,
        SUM(valor) / COUNT(*)       AS ticket_medio
    FROM fato_pedidos
    WHERE data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30'
    GROUP BY pais
)
SELECT
    RANK() OVER (ORDER BY receita DESC)                     AS ranking,
    pais,
    ROUND(receita, 0)                                       AS receita,
    ROUND(100.0 * receita / SUM(receita) OVER (), 1)        AS pct_receita,
    pedidos,
    clientes,
    ROUND(ticket_medio, 0)                                  AS ticket_medio,
    ROUND(ticket_medio / (SELECT SUM(valor) / COUNT(*) FROM fato_pedidos
                          WHERE data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30'
                            AND pais = 'United Kingdom'), 2) AS ticket_vs_reino_unido
FROM paises
ORDER BY receita DESC
LIMIT 15;
