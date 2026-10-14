-- =====================================================================
-- 06 - Segmentacao RFM (Recencia, Frequencia, Valor)
-- Pergunta: quem sao os clientes mais valiosos e quem esta prestes a ser perdido?
-- Janela: ultimos 12 meses da base (10/12/2010 a 09/12/2011).
-- A regra de segmentacao esta na macro rfm_clientes (sql/00_modelagem.sql).
-- =====================================================================
WITH segmentos AS (
    SELECT * FROM rfm_clientes((SELECT MAX(data) + 1 FROM fato_pedidos))
)
SELECT
    segmento,
    COUNT(*)                                                         AS clientes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)               AS pct_clientes,
    ROUND(SUM(valor), 0)                                             AS receita,
    ROUND(100.0 * SUM(valor) / SUM(SUM(valor)) OVER (), 1)           AS pct_receita,
    ROUND(AVG(recencia_dias), 0)                                     AS recencia_media_dias,
    ROUND(AVG(frequencia), 1)                                        AS frequencia_media,
    ROUND(AVG(valor), 0)                                             AS valor_medio_cliente
FROM segmentos
GROUP BY segmento
ORDER BY segmento;
