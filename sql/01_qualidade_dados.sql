-- =====================================================================
-- 01 - Qualidade dos dados: o que foi removido ou separado e por que
-- Pergunta: quanto da base bruta e confiavel para analise?
-- =====================================================================
WITH base AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice, stock_code, description, quantity,
                         invoice_date, price, customer_id, country
        ) AS rn
    FROM raw_vendas
),
regras AS (
    SELECT 'Linhas na base bruta' AS regra, COUNT(*) AS linhas, 1 AS ordem FROM base
    UNION ALL
    SELECT 'Linhas duplicadas identicas', COUNT(*) FILTER (WHERE rn > 1), 2 FROM base
    UNION ALL
    SELECT 'Codigos que nao sao produto (frete, taxas, testes)',
           COUNT(*) FILTER (WHERE stock_code IN (SELECT stock_code FROM dim_codigos_nao_produto)), 3 FROM base
    UNION ALL
    SELECT 'Preco unitario zerado ou negativo', COUNT(*) FILTER (WHERE price <= 0), 4 FROM base
    UNION ALL
    SELECT 'Linhas de cancelamento (nota iniciada em C)', COUNT(*) FILTER (WHERE invoice LIKE 'C%'), 5 FROM base
    UNION ALL
    SELECT 'Linhas sem cliente identificado', COUNT(*) FILTER (WHERE customer_id IS NULL), 6 FROM base
    UNION ALL
    SELECT 'Linhas de venda valida (fato_vendas)', (SELECT COUNT(*) FROM fato_vendas), 7
    UNION ALL
    SELECT 'Linhas de venda valida com cliente identificado',
           (SELECT COUNT(*) FROM fato_vendas WHERE cliente_id IS NOT NULL), 8
)
SELECT
    regra,
    linhas,
    ROUND(100.0 * linhas / FIRST_VALUE(linhas) OVER (ORDER BY ordem), 1) AS pct_da_base
FROM regras
ORDER BY ordem;
