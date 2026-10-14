-- =====================================================================
-- 00 - Modelagem: da tabela bruta para as tabelas de analise
-- Banco: DuckDB (sintaxe compativel com PostgreSQL na maior parte)
-- =====================================================================

-- Codigos que nao sao produtos (frete, taxas, ajustes, testes, vales-presente)
CREATE OR REPLACE TABLE dim_codigos_nao_produto AS
SELECT DISTINCT stock_code
FROM raw_vendas
WHERE stock_code IN ('POST', 'DOT', 'M', 'm', 'C2', 'D', 'S', 'B', 'BANK CHARGES',
                     'ADJUST', 'ADJUST2', 'AMAZONFEE', 'CRUK', 'PADS')
   OR stock_code ILIKE 'TEST%'
   OR stock_code ILIKE 'gift_%';

-- Staging: tipagem, colunas derivadas e remocao de linhas duplicadas identicas
CREATE OR REPLACE TABLE stg_vendas AS
WITH tipado AS (
    SELECT
        invoice,
        stock_code,
        TRIM(description)                      AS descricao,
        quantity                               AS quantidade,
        invoice_date                           AS data_hora,
        CAST(invoice_date AS DATE)             AS data,
        price                                  AS preco_unitario,
        CAST(customer_id AS INTEGER)           AS cliente_id,
        country                                AS pais,
        CAST(quantity * price AS DECIMAL(18, 2)) AS valor,   -- decimal: somas exatas e reproduziveis
        invoice LIKE 'C%'                      AS is_cancelamento,
        ROW_NUMBER() OVER (
            PARTITION BY invoice, stock_code, description, quantity,
                         invoice_date, price, customer_id, country
        )                                      AS rn
    FROM raw_vendas
)
SELECT * EXCLUDE (rn)
FROM tipado
WHERE rn = 1                                        -- remove duplicatas exatas
  AND preco_unitario > 0                            -- remove precos zerados/ajustes de divida
  AND stock_code NOT IN (SELECT stock_code FROM dim_codigos_nao_produto);

-- Fato de vendas validas (sem cancelamentos e sem quantidades negativas)
CREATE OR REPLACE TABLE fato_vendas AS
SELECT *
FROM stg_vendas
WHERE NOT is_cancelamento
  AND quantidade > 0;

-- Fato de cancelamentos (valores ficam positivos para facilitar a leitura)
CREATE OR REPLACE TABLE fato_cancelamentos AS
SELECT * REPLACE (ABS(quantidade) AS quantidade, ABS(valor) AS valor)
FROM stg_vendas
WHERE is_cancelamento;

-- Pedidos (uma linha por nota fiscal), base para ticket medio e analises de cliente
CREATE OR REPLACE TABLE fato_pedidos AS
SELECT
    invoice,
    cliente_id,
    pais,
    MIN(data_hora)        AS data_hora,
    MIN(data)             AS data,
    COUNT(*)              AS itens,
    SUM(quantidade)       AS unidades,
    SUM(valor)            AS valor
FROM fato_vendas
GROUP BY invoice, cliente_id, pais;

-- Segmentacao RFM como macro de tabela: recebe a data de referencia e usa os 365 dias
-- anteriores a ela. Assim a mesma regra roda no presente (06) e no passado (12, validacao).
CREATE OR REPLACE MACRO rfm_clientes(data_ref) AS TABLE
WITH base_cliente AS (
    SELECT
        cliente_id,
        DATE_DIFF('day', MAX(data), data_ref) AS recencia_dias,
        COUNT(*)                              AS frequencia,
        SUM(valor)                            AS valor
    FROM fato_pedidos
    WHERE cliente_id IS NOT NULL
      AND data >= data_ref - INTERVAL 365 DAY
      AND data <  data_ref
    GROUP BY cliente_id
),
notas AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recencia_dias DESC, cliente_id) AS r,   -- 5 = comprou ha pouco tempo
        NTILE(5) OVER (ORDER BY frequencia ASC, cliente_id)     AS f,
        NTILE(5) OVER (ORDER BY valor ASC, cliente_id)          AS m
    FROM base_cliente
)
SELECT
    *,
    CASE
        WHEN r >= 4 AND f >= 4 AND m >= 4 THEN '1. Campeões'
        WHEN r >= 3 AND f >= 3            THEN '2. Leais'
        WHEN r >= 4 AND f <= 2            THEN '3. Novos / promissores'
        WHEN r <= 2 AND f >= 3            THEN '4. Em risco'
        WHEN r = 3                        THEN '5. Precisam de atenção'
        ELSE                                   '6. Hibernando / perdidos'
    END AS segmento
FROM notas;
