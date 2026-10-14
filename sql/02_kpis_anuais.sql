-- =====================================================================
-- 02 - KPIs anuais e crescimento
-- Pergunta: o negocio cresceu? Por causa de mais clientes ou de clientes gastando mais?
-- Periodo comparavel: dez/2009-nov/2010 (Ano 1) vs dez/2010-nov/2011 (Ano 2).
-- Dezembro de 2011 tem apenas 9 dias e fica fora.
-- Receita = vendas validas (bruta). Receita liquida = bruta - valor cancelado no periodo.
-- =====================================================================
WITH pedidos AS (
    SELECT
        *,
        CASE
            WHEN data BETWEEN DATE '2009-12-01' AND DATE '2010-11-30' THEN 'Ano 1 (dez/09-nov/10)'
            WHEN data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30' THEN 'Ano 2 (dez/10-nov/11)'
        END AS periodo
    FROM fato_pedidos
),
cancelado AS (
    SELECT
        CASE
            WHEN data BETWEEN DATE '2009-12-01' AND DATE '2010-11-30' THEN 'Ano 1 (dez/09-nov/10)'
            WHEN data BETWEEN DATE '2010-12-01' AND DATE '2011-11-30' THEN 'Ano 2 (dez/10-nov/11)'
        END        AS periodo,
        SUM(valor) AS valor_cancelado
    FROM fato_cancelamentos
    GROUP BY 1
),
kpis AS (
    SELECT
        periodo,
        SUM(valor)                                   AS receita,
        SUM(valor) - ANY_VALUE(c.valor_cancelado)    AS receita_liquida,
        COUNT(*)                                     AS pedidos,
        COUNT(DISTINCT cliente_id)                   AS clientes_identificados,
        SUM(valor) / COUNT(*)                        AS ticket_medio,
        COUNT(*) FILTER (WHERE cliente_id IS NOT NULL) * 1.0
            / COUNT(DISTINCT cliente_id)             AS pedidos_por_cliente,
        100.0 * SUM(valor) FILTER (WHERE cliente_id IS NULL) / SUM(valor)
                                                     AS pct_receita_sem_cliente
    FROM pedidos
    LEFT JOIN cancelado c USING (periodo)
    WHERE periodo IS NOT NULL
    GROUP BY periodo
)
SELECT
    periodo,
    ROUND(receita, 0)                                                    AS receita,
    ROUND(100.0 * (receita / LAG(receita) OVER (ORDER BY periodo) - 1), 1)  AS var_receita_pct,
    ROUND(receita_liquida, 0)                                            AS receita_liquida,
    ROUND(100.0 * (receita_liquida / LAG(receita_liquida) OVER (ORDER BY periodo) - 1), 1)
                                                                         AS var_receita_liquida_pct,
    pedidos,
    ROUND(100.0 * (pedidos * 1.0 / LAG(pedidos) OVER (ORDER BY periodo) - 1), 1) AS var_pedidos_pct,
    clientes_identificados,
    ROUND(100.0 * (clientes_identificados * 1.0 / LAG(clientes_identificados) OVER (ORDER BY periodo) - 1), 1)
                                                                         AS var_clientes_pct,
    ROUND(ticket_medio, 2)                                               AS ticket_medio,
    ROUND(100.0 * (ticket_medio / LAG(ticket_medio) OVER (ORDER BY periodo) - 1), 1)
                                                                         AS var_ticket_pct,
    ROUND(pedidos_por_cliente, 2)                                        AS pedidos_por_cliente,
    ROUND(pct_receita_sem_cliente, 1)                                    AS pct_receita_sem_cliente
FROM kpis
ORDER BY periodo;
