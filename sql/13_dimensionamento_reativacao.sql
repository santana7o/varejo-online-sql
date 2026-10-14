-- =====================================================================
-- 13 - Dimensionamento da campanha de reativacao do segmento "Em risco"
-- Pergunta: quanto vale reativar clientes "Em risco" antes do pico de fim de ano?
-- Base historica (consulta 12): dos clientes "Em risco" em dez/2010, uma parte voltou
-- sozinha no ano seguinte. A campanha so gera valor no que ela adiciona a essa taxa.
-- Cenarios: +5, +10 e +20 pontos percentuais de reativacao sobre a taxa natural.
-- Valor por cliente reativado: mediana (conservador) e media (otimista) do que os
-- clientes "Em risco" que voltaram gastaram no ano seguinte.
-- =====================================================================
WITH historico AS (
    SELECT
        COUNT(*)                                       AS clientes_em_risco_2010,
        COUNT(f.cliente_id)                            AS voltaram,
        MEDIAN(f.receita)                              AS mediana_receita,
        AVG(f.receita)                                 AS media_receita
    FROM rfm_clientes(DATE '2010-12-10') s
    LEFT JOIN (
        SELECT cliente_id, SUM(valor) AS receita
        FROM fato_pedidos
        WHERE data >= DATE '2010-12-10' AND data < DATE '2011-12-10'
        GROUP BY cliente_id
    ) f USING (cliente_id)
    WHERE s.segmento = '4. Em risco'
),
atual AS (
    SELECT COUNT(*) AS clientes_em_risco_hoje
    FROM rfm_clientes((SELECT MAX(data) + 1 FROM fato_pedidos))
    WHERE segmento = '4. Em risco'
),
cenarios AS (
    SELECT * FROM (VALUES ('Baixo', 5), ('Medio', 10), ('Alto', 20)) AS t(cenario, pp_adicionais)
)
SELECT
    c.cenario,
    c.pp_adicionais                                                     AS pp_reativacao_adicional,
    a.clientes_em_risco_hoje,
    ROUND(100.0 * h.voltaram / h.clientes_em_risco_2010, 1)             AS taxa_natural_historica_pct,
    ROUND(a.clientes_em_risco_hoje * c.pp_adicionais / 100.0)           AS clientes_reativados_extra,
    ROUND(h.mediana_receita, 0)                                         AS receita_por_reativado_mediana,
    ROUND(h.media_receita, 0)                                           AS receita_por_reativado_media,
    ROUND(ROUND(a.clientes_em_risco_hoje * c.pp_adicionais / 100.0) * h.mediana_receita, -3)
                                                                        AS receita_extra_pela_mediana,
    ROUND(ROUND(a.clientes_em_risco_hoje * c.pp_adicionais / 100.0) * h.media_receita, -3)
                                                                        AS receita_extra_pela_media
FROM cenarios c
CROSS JOIN historico h
CROSS JOIN atual a
ORDER BY c.pp_adicionais;
