-- =====================================================================
-- 14 - Lista de acao: clientes "Em risco" priorizados para a campanha
-- Pergunta: por quem o time comercial deve comecar?
-- Prioridade = valor gasto nos ultimos 12 meses (quem mais tem a perder vem primeiro).
-- =====================================================================
WITH em_risco AS (
    SELECT *
    FROM rfm_clientes((SELECT MAX(data) + 1 FROM fato_pedidos))
    WHERE segmento = '4. Em risco'
),
ultimo_pedido AS (
    SELECT
        cliente_id,
        MAX(data)                                    AS data_ultima_compra,
        ARG_MAX(pais, data)                          AS pais
    FROM fato_pedidos
    WHERE cliente_id IN (SELECT cliente_id FROM em_risco)
    GROUP BY cliente_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY e.valor DESC, e.cliente_id)        AS prioridade,
    e.cliente_id,
    u.pais,
    u.data_ultima_compra,
    e.recencia_dias,
    e.frequencia                                                    AS pedidos_12m,
    ROUND(e.valor, 0)                                               AS receita_12m,
    ROUND(100.0 * SUM(e.valor) OVER (ORDER BY e.valor DESC, e.cliente_id) / SUM(e.valor) OVER (), 1)
                                                                    AS pct_receita_acumulada
FROM em_risco e
JOIN ultimo_pedido u USING (cliente_id)
ORDER BY prioridade;
