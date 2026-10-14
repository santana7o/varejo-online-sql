-- =====================================================================
-- 04 - Receita de clientes novos vs recorrentes por mes
-- Pergunta: o crescimento vem de aquisicao ou da base que ja comprava?
-- Considera apenas pedidos com cliente identificado.
-- =====================================================================
WITH primeira_compra AS (
    SELECT cliente_id, DATE_TRUNC('month', MIN(data)) AS mes_entrada
    FROM fato_pedidos
    WHERE cliente_id IS NOT NULL
    GROUP BY cliente_id
),
pedidos AS (
    SELECT
        DATE_TRUNC('month', p.data)                                    AS mes,
        p.cliente_id,
        p.valor,
        CASE WHEN DATE_TRUNC('month', p.data) = f.mes_entrada
             THEN 'Novo' ELSE 'Recorrente' END                         AS tipo_cliente
    FROM fato_pedidos p
    JOIN primeira_compra f USING (cliente_id)
    WHERE p.data < DATE '2011-12-01'
)
SELECT
    STRFTIME(mes, '%Y-%m')                                                AS mes,
    COUNT(DISTINCT cliente_id) FILTER (WHERE tipo_cliente = 'Novo')       AS clientes_novos,
    COUNT(DISTINCT cliente_id) FILTER (WHERE tipo_cliente = 'Recorrente') AS clientes_recorrentes,
    ROUND(SUM(valor) FILTER (WHERE tipo_cliente = 'Novo'), 0)             AS receita_novos,
    ROUND(SUM(valor) FILTER (WHERE tipo_cliente = 'Recorrente'), 0)       AS receita_recorrentes,
    ROUND(100.0 * SUM(valor) FILTER (WHERE tipo_cliente = 'Recorrente') / SUM(valor), 1)
                                                                          AS pct_receita_recorrente
FROM pedidos
WHERE mes >= DATE '2010-01-01'   -- dez/2009 e o inicio da base: todo cliente aparece como "novo"
GROUP BY mes
ORDER BY mes;
