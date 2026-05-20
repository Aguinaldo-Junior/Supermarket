SELECT * FROM supermercado_dw.dim_promocao;

SELECT 
	MAX(sk_promocao)
FROM dim_promocao;

INSERT INTO dim_promocao(
	sk_promocao, codigo_promocao, nome_promocao, tipo_promocao, canal, desconto_pct,
    leva_qtd, paga_qtd, data_inicio, data_fim,  ativa
)
VALUES (
	0, "PRO00000", "Sem promoção", "Sem promoção", "Sem canal", 0 , NULL, NULL, "2023-01-10", "2023-01-14", 0
);

SELECT 
	MAX(codigo_promocao)
FROM dim_promocao;

SELECT * FROM dim_promocao WHERE codigo_promocao = "PRO00000";

UPDATE fato_vendas SET sk_promocao = 512 WHERE sk_promocao IS NULL;
