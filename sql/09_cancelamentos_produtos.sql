-- =====================================================================
-- 09 - Produtos com maior valor cancelado (Ano 2) e taxa de cancelamento do produto
-- Pergunta: ha produtos com cancelamento muito acima da media?
-- =====================================================================
WITH vendido AS (
    SELECT stock_code, MAX(descricao) AS descricao, SUM(valor) AS receita_bruta
    FROM fato_vendas
    WHERE data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30'
    GROUP BY stock_code
),
cancelado AS (
    SELECT stock_code, SUM(valor) AS valor_cancelado, COUNT(DISTINCT invoice) AS notas_canceladas
    FROM fato_cancelamentos
    WHERE data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30'
    GROUP BY stock_code
)
SELECT
    v.stock_code,
    v.descricao,
    ROUND(v.receita_bruta, 0)                             AS receita_bruta,
    ROUND(c.valor_cancelado, 0)                           AS valor_cancelado,
    c.notas_canceladas,
    ROUND(100.0 * c.valor_cancelado / v.receita_bruta, 1) AS taxa_cancelamento_pct
FROM vendido v
JOIN cancelado c USING (stock_code)
ORDER BY c.valor_cancelado DESC
LIMIT 15;
