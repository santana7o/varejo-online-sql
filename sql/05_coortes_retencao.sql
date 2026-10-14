-- =====================================================================
-- 05 - Coortes de retencao mensal
-- Pergunta: de cada grupo de clientes que comprou pela primeira vez em um mes,
-- quantos voltaram a comprar 1, 2, 3... meses depois?
-- Coortes de jan/2010 a dez/2010 (dez/2009 mistura clientes antigos, pois e o inicio da base).
-- =====================================================================
WITH primeira_compra AS (
    SELECT cliente_id, DATE_TRUNC('month', MIN(data)) AS coorte
    FROM fato_pedidos
    WHERE cliente_id IS NOT NULL
    GROUP BY cliente_id
),
atividade AS (
    SELECT DISTINCT
        f.coorte,
        p.cliente_id,
        DATE_DIFF('month', f.coorte, DATE_TRUNC('month', p.data)) AS meses_desde_entrada
    FROM fato_pedidos p
    JOIN primeira_compra f USING (cliente_id)
    WHERE p.data < DATE '2011-12-01'
),
contagem AS (
    SELECT coorte, meses_desde_entrada, COUNT(*) AS clientes_ativos
    FROM atividade
    GROUP BY coorte, meses_desde_entrada
)
SELECT
    STRFTIME(coorte, '%Y-%m')                                          AS coorte,
    meses_desde_entrada,
    clientes_ativos,
    FIRST_VALUE(clientes_ativos) OVER (PARTITION BY coorte ORDER BY meses_desde_entrada)
                                                                       AS tamanho_coorte,
    ROUND(100.0 * clientes_ativos / FIRST_VALUE(clientes_ativos)
          OVER (PARTITION BY coorte ORDER BY meses_desde_entrada), 1)  AS retencao_pct
FROM contagem
WHERE coorte BETWEEN DATE '2010-01-01' AND DATE '2010-12-01'
  AND meses_desde_entrada <= 12
ORDER BY coorte, meses_desde_entrada;
