-- =====================================================================
-- Testes de dados: cada linha e uma regra que precisa ser verdadeira.
-- Rodados por scripts/05_testar_dados.py; qualquer falha interrompe a execucao.
-- =====================================================================
SELECT 'stg_vendas nao tem linhas duplicadas identicas' AS teste,
       (SELECT COUNT(*) FROM stg_vendas)
     = (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM stg_vendas)) AS ok

UNION ALL
SELECT 'stg_vendas = fato_vendas + fato_cancelamentos (linhas)',
       (SELECT COUNT(*) FROM stg_vendas)
     = (SELECT COUNT(*) FROM fato_vendas) + (SELECT COUNT(*) FROM fato_cancelamentos)

UNION ALL
SELECT 'fato_vendas so tem preco e quantidade positivos',
       (SELECT COUNT(*) FROM fato_vendas WHERE preco_unitario <= 0 OR quantidade <= 0) = 0

UNION ALL
SELECT 'fato_vendas nao tem codigos que nao sao produto',
       (SELECT COUNT(*) FROM fato_vendas
        WHERE stock_code IN (SELECT stock_code FROM dim_codigos_nao_produto)) = 0

UNION ALL
SELECT 'fato_pedidos tem uma linha por nota fiscal',
       (SELECT COUNT(*) FROM fato_pedidos) = (SELECT COUNT(DISTINCT invoice) FROM fato_pedidos)

UNION ALL
SELECT 'receita de fato_pedidos = receita de fato_vendas',
       (SELECT SUM(valor) FROM fato_pedidos) = (SELECT SUM(valor) FROM fato_vendas)

UNION ALL
SELECT 'fato_cancelamentos so tem notas iniciadas em C e valores positivos',
       (SELECT COUNT(*) FROM fato_cancelamentos
        WHERE invoice NOT LIKE 'C%' OR valor < 0 OR quantidade < 0) = 0

UNION ALL
SELECT 'RFM: cada cliente ativo nos ultimos 12 meses esta em exatamente um segmento',
       (SELECT COUNT(*) FROM rfm_clientes((SELECT MAX(data) + 1 FROM fato_pedidos)))
     = (SELECT COUNT(DISTINCT cliente_id) FROM fato_pedidos
        WHERE cliente_id IS NOT NULL
          AND data >= (SELECT MAX(data) + 1 FROM fato_pedidos) - INTERVAL 365 DAY)

UNION ALL
SELECT 'RFM: notas R, F e M entre 1 e 5',
       (SELECT COUNT(*) FROM rfm_clientes((SELECT MAX(data) + 1 FROM fato_pedidos))
        WHERE r NOT BETWEEN 1 AND 5 OR f NOT BETWEEN 1 AND 5 OR m NOT BETWEEN 1 AND 5) = 0

UNION ALL
SELECT 'nenhum cliente tem pedido antes da propria primeira compra (coortes)',
       (SELECT COUNT(*) FROM fato_pedidos p
        JOIN (SELECT cliente_id, MIN(data) AS primeira FROM fato_pedidos
              WHERE cliente_id IS NOT NULL GROUP BY cliente_id) f USING (cliente_id)
        WHERE p.data < f.primeira) = 0;
