-- =====================================================================
-- 11 - Pedidos por dia da semana e hora
-- Pergunta: quando os clientes compram? (apoio a escala de atendimento e campanhas)
-- =====================================================================
SELECT
    ISODOW(data_hora)                                   AS dia_semana_num,   -- 1 = segunda
    CASE ISODOW(data_hora)
        WHEN 1 THEN 'Seg' WHEN 2 THEN 'Ter' WHEN 3 THEN 'Qua' WHEN 4 THEN 'Qui'
        WHEN 5 THEN 'Sex' WHEN 6 THEN 'Sab' ELSE 'Dom' END AS dia_semana,
    HOUR(data_hora)                                     AS hora,
    COUNT(*)                                            AS pedidos,
    ROUND(SUM(valor), 0)                                AS receita
FROM fato_pedidos
GROUP BY 1, 2, 3
ORDER BY 1, 3;
