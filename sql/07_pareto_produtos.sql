-- =====================================================================
-- 07 - Curva ABC / Pareto de produtos
-- Pergunta: quantos produtos concentram 80% da receita?
-- Periodo: Ano 2 (dez/2010-nov/2011).
-- =====================================================================
WITH produtos AS (
    SELECT
        stock_code,
        MAX(descricao)    AS descricao,
        SUM(valor)              AS receita,
        SUM(quantidade)         AS unidades,
        COUNT(DISTINCT invoice) AS pedidos
    FROM fato_vendas
    WHERE data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30'
    GROUP BY stock_code
),
acumulado AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY receita DESC, stock_code)                        AS ranking,
        100.0 * SUM(receita) OVER (ORDER BY receita DESC, stock_code
                                   ROWS UNBOUNDED PRECEDING) / SUM(receita) OVER () AS pct_acumulado,
        COUNT(*) OVER ()                                                   AS total_produtos
    FROM produtos
)
SELECT
    ranking,
    stock_code,
    descricao,
    ROUND(receita, 0)          AS receita,
    unidades,
    pedidos,
    ROUND(pct_acumulado, 2)    AS pct_receita_acumulada,
    CASE WHEN pct_acumulado <= 80 THEN 'A'
         WHEN pct_acumulado <= 95 THEN 'B'
         ELSE 'C' END          AS classe_abc,
    ROUND(100.0 * ranking / total_produtos, 2) AS pct_produtos_acumulado
FROM acumulado
ORDER BY ranking;
