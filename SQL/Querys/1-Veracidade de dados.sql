USE supermercado_dw;

-- 1 Verificando a quantidade de linhas em fatos
SELECT COUNT(*) FROM fato_vendas;
SELECT COUNT(DISTINCT sk_venda) FROM fato_vendas;

SELECT COUNT(*) FROM fato_estoque;
SELECT COUNT(DISTINCT sk_estoque) FROM fato_estoque;

SELECT COUNT(*) FROM fato_compras;
SELECT COUNT(DISTINCT sk_compra) FROM fato_compras;

-- 2 Verificando a quantidade valores Nullos
SELECT
	SUM(sk_venda IS NULL) AS id_venda,
    SUM(id_transacao IS NULL) AS id_transacao,
    SUM(sk_tempo IS NULL) AS tempo,
    SUM(sk_loja IS NULL) AS id_loja,
    SUM(sk_produto IS NULL) AS id_produto,
    SUM(sk_cliente IS NULL) AS id_cliente,
    SUM(sk_funcionario IS NULL) AS id_funcionario,
    SUM(sk_promocao IS NULL) AS id_promocao
FROM fato_vendas;

SELECT 
	SUM(sk_estoque IS NULL) AS id_estoque,
    SUM(sk_tempo IS NULL) AS id_tempo,
    SUM(sk_loja IS NULL) AS id_kloja,
    SUM(sk_produto IS NULL) AS id_produto
FROM fato_estoque;



SELECT
	SUM(sk_compra IS NULL) AS id,
    SUM(id_pedido_compra IS NULL) AS compra,
    SUM(sk_tempo IS NULL) AS tempo,
    SUM(sk_loja IS NULL) AS loja,
    SUM(sk_produto IS NULL) AS pr,
    SUM(sk_fornecedor IS NULL) AS fornecedor
FROM fato_compras;

-- 3 Verificação de quantidade com valores negativos
SELECT 
	SUM(quantidade < 0) AS qtd,
    SUM(preco_unitario  < 0) AS pruni,
    SUM(desconto_unitario < 0) AS dsuni,
    SUM(custo_unitario < 0) AS csuni,
    SUM(valor_bruto < 0) AS vabru,
    SUM(valor_liquido < 0) AS valiq,
    SUM(lucro_bruto < 0) AS lubru,
    SUM(margem_pct < 0) AS mapct
FROM fato_vendas;

SELECT 
	SUM(estoque_inicial < 0) AS esini,
    SUM(entrada < 0) AS ent,
    SUM(saida < 0) AS sai,
    SUM(perda < 0) AS per,
    SUM(ruptura < 0) AS rup,
    SUM(estoque_final < 0) AS esfin,
    SUM(cobertura_dias < 0) AS codia
FROM fato_estoque;

SELECT 
	SUM(quantidade < 0) AS qtd,
    SUM(custo_unitario < 0) AS cuuni,
    SUM(frete_unitario < 0) AS fruni,
    SUM(impostos_unitario < 0) AS imuni,
    SUM(valor_total < 0) AS vatot,
    SUM(prazo_entrega_dias < 0) AS prent,
    SUM(recebido_no_prazo < 0) AS repra
FROM fato_compras;

