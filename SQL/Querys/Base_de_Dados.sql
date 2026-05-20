-- =========================================================
-- PROJETO: BASE REALISTA DE VAREJO SUPERMERCADISTA
-- BANCO: MySQL 8
-- OBJETIVO: criar uma base estrela para ETL em Python e Dashboard no Power BI
-- OBS.: execute este script inteiro de uma vez
-- =========================================================

DROP DATABASE IF EXISTS supermercado_dw;
CREATE DATABASE supermercado CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE supermercado_dw;

SET sql_safe_updates = 0;
SET foreign_key_checks = 0;

-- =========================================================
-- PARÂMETROS DE ESCALA
-- Ajuste aqui se quiser aumentar ou reduzir o volume
-- =========================================================
SET @qtd_lojas         = 85;
SET @qtd_fornecedores  = 650;
SET @qtd_produtos      = 12000;
SET @qtd_clientes      = 80000;
SET @qtd_funcionarios  = 3200;
SET @qtd_promocoes     = 350;
SET @qtd_vendas        = 500000;
SET @qtd_compras       = 120000;
SET @qtd_estoque       = 250000;

-- =========================================================
-- TABELA AUXILIAR DE NÚMEROS
-- Gera até 1.000.000 linhas
-- =========================================================
DROP TABLE IF EXISTS util_digits;
CREATE TABLE util_digits (
    d TINYINT NOT NULL PRIMARY KEY
);

INSERT INTO util_digits (d)
VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

DROP TABLE IF EXISTS util_numbers;
CREATE TABLE util_numbers (
    n INT NOT NULL PRIMARY KEY
);

INSERT INTO util_numbers (n)
SELECT
    (a.d + b.d*10 + c.d*100 + d.d*1000 + e.d*10000 + f.d*100000) + 1 AS n
FROM util_digits a
CROSS JOIN util_digits b
CROSS JOIN util_digits c
CROSS JOIN util_digits d
CROSS JOIN util_digits e
CROSS JOIN util_digits f;

-- =========================================================
-- DIMENSÕES
-- =========================================================
DROP TABLE IF EXISTS fato_estoque;
DROP TABLE IF EXISTS fato_compras;
DROP TABLE IF EXISTS fato_vendas;
DROP TABLE IF EXISTS dim_promocao;
DROP TABLE IF EXISTS dim_funcionario;
DROP TABLE IF EXISTS dim_cliente;
DROP TABLE IF EXISTS dim_produto;
DROP TABLE IF EXISTS dim_fornecedor;
DROP TABLE IF EXISTS dim_loja;
DROP TABLE IF EXISTS dim_tempo;

CREATE TABLE dim_tempo (
    sk_tempo            INT AUTO_INCREMENT PRIMARY KEY,
    data_completa       DATE NOT NULL,
    ano                 SMALLINT NOT NULL,
    semestre            TINYINT NOT NULL,
    trimestre           TINYINT NOT NULL,
    mes                 TINYINT NOT NULL,
    nome_mes            VARCHAR(20) NOT NULL,
    semana_ano          TINYINT NOT NULL,
    dia                 TINYINT NOT NULL,
    dia_semana_num      TINYINT NOT NULL,
    dia_semana_nome     VARCHAR(20) NOT NULL,
    fim_de_semana       TINYINT(1) NOT NULL,
    UNIQUE KEY uk_dim_tempo_data (data_completa)
);

CREATE TABLE dim_loja (
    sk_loja             INT AUTO_INCREMENT PRIMARY KEY,
    codigo_loja         VARCHAR(20) NOT NULL,
    nome_loja           VARCHAR(100) NOT NULL,
    tipo_loja           VARCHAR(30) NOT NULL,
    regiao              VARCHAR(20) NOT NULL,
    estado              CHAR(2) NOT NULL,
    cidade              VARCHAR(60) NOT NULL,
    bairro              VARCHAR(60) NOT NULL,
    area_m2             INT NOT NULL,
    data_abertura       DATE NOT NULL,
    status_loja         VARCHAR(20) NOT NULL,
    UNIQUE KEY uk_dim_loja_codigo (codigo_loja)
);

CREATE TABLE dim_fornecedor (
    sk_fornecedor       INT AUTO_INCREMENT PRIMARY KEY,
    codigo_fornecedor   VARCHAR(20) NOT NULL,
    nome_fornecedor     VARCHAR(120) NOT NULL,
    categoria_principal VARCHAR(60) NOT NULL,
    estado_origem       CHAR(2) NOT NULL,
    prazo_medio_dias    INT NOT NULL,
    lead_time_dias      INT NOT NULL,
    rating_fornecedor   DECIMAL(3,2) NOT NULL,
    ativo               TINYINT(1) NOT NULL,
    UNIQUE KEY uk_dim_fornecedor_codigo (codigo_fornecedor)
);

CREATE TABLE dim_produto (
    sk_produto              INT AUTO_INCREMENT PRIMARY KEY,
    codigo_produto          VARCHAR(30) NOT NULL,
    ean                     VARCHAR(20) NOT NULL,
    nome_produto            VARCHAR(150) NOT NULL,
    marca                   VARCHAR(80) NOT NULL,
    departamento            VARCHAR(60) NOT NULL,
    categoria               VARCHAR(60) NOT NULL,
    subcategoria            VARCHAR(60) NOT NULL,
    unidade_medida          VARCHAR(10) NOT NULL,
    peso_liquido_g          DECIMAL(10,2) NOT NULL,
    produto_marca_propria   TINYINT(1) NOT NULL,
    perecivel               TINYINT(1) NOT NULL,
    fornecedor_padrao_sk    INT NOT NULL,
    preco_lista             DECIMAL(10,2) NOT NULL,
    custo_unitario          DECIMAL(10,2) NOT NULL,
    margem_base_pct         DECIMAL(5,2) NOT NULL,
    ativo                   TINYINT(1) NOT NULL,
    UNIQUE KEY uk_dim_produto_codigo (codigo_produto),
    UNIQUE KEY uk_dim_produto_ean (ean),
    KEY idx_dim_produto_fornecedor (fornecedor_padrao_sk),
    CONSTRAINT fk_dim_produto_fornecedor FOREIGN KEY (fornecedor_padrao_sk) REFERENCES dim_fornecedor(sk_fornecedor)
);

CREATE TABLE dim_cliente (
    sk_cliente              INT AUTO_INCREMENT PRIMARY KEY,
    codigo_cliente          VARCHAR(20) NOT NULL,
    nome_cliente            VARCHAR(120) NOT NULL,
    sexo                    VARCHAR(15) NOT NULL,
    faixa_etaria            VARCHAR(20) NOT NULL,
    renda_faixa             VARCHAR(30) NOT NULL,
    estado                  CHAR(2) NOT NULL,
    cidade                  VARCHAR(60) NOT NULL,
    bairro                  VARCHAR(60) NOT NULL,
    canal_preferido         VARCHAR(20) NOT NULL,
    data_cadastro           DATE NOT NULL,
    cliente_ativo           TINYINT(1) NOT NULL,
    UNIQUE KEY uk_dim_cliente_codigo (codigo_cliente)
);

CREATE TABLE dim_funcionario (
    sk_funcionario          INT AUTO_INCREMENT PRIMARY KEY,
    codigo_funcionario      VARCHAR(20) NOT NULL,
    nome_funcionario        VARCHAR(120) NOT NULL,
    cargo                   VARCHAR(50) NOT NULL,
    departamento            VARCHAR(50) NOT NULL,
    loja_sk                 INT NOT NULL,
    data_admissao           DATE NOT NULL,
    turno                   VARCHAR(20) NOT NULL,
    salario                 DECIMAL(10,2) NOT NULL,
    status_funcionario      VARCHAR(20) NOT NULL,
    UNIQUE KEY uk_dim_funcionario_codigo (codigo_funcionario),
    KEY idx_dim_funcionario_loja (loja_sk),
    CONSTRAINT fk_dim_funcionario_loja FOREIGN KEY (loja_sk) REFERENCES dim_loja(sk_loja)
);

CREATE TABLE dim_promocao (
    sk_promocao             INT AUTO_INCREMENT PRIMARY KEY,
    codigo_promocao         VARCHAR(20) NOT NULL,
    nome_promocao           VARCHAR(120) NOT NULL,
    tipo_promocao           VARCHAR(40) NOT NULL,
    canal                   VARCHAR(20) NOT NULL,
    desconto_pct            DECIMAL(5,2) NOT NULL,
    leva_qtd                INT NULL,
    paga_qtd                INT NULL,
    data_inicio             DATE NOT NULL,
    data_fim                DATE NOT NULL,
    ativa                   TINYINT(1) NOT NULL,
    UNIQUE KEY uk_dim_promocao_codigo (codigo_promocao)
);

-- =========================================================
-- FATOS
-- =========================================================
CREATE TABLE fato_vendas (
    sk_venda                BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_transacao            VARCHAR(40) NOT NULL,
    sk_tempo                INT NOT NULL,
    sk_loja                 INT NOT NULL,
    sk_produto              INT NOT NULL,
    sk_cliente              INT NOT NULL,
    sk_funcionario          INT NOT NULL,
    sk_promocao             INT NULL,
    canal_venda             VARCHAR(20) NOT NULL,
    forma_pagamento         VARCHAR(20) NOT NULL,
    quantidade              INT NOT NULL,
    preco_unitario          DECIMAL(10,2) NOT NULL,
    desconto_unitario       DECIMAL(10,2) NOT NULL,
    custo_unitario          DECIMAL(10,2) NOT NULL,
    valor_bruto             DECIMAL(12,2) NOT NULL,
    valor_desconto          DECIMAL(12,2) NOT NULL,
    valor_liquido           DECIMAL(12,2) NOT NULL,
    lucro_bruto             DECIMAL(12,2) NOT NULL,
    margem_pct              DECIMAL(6,2) NOT NULL,
    KEY idx_fv_tempo (sk_tempo),
    KEY idx_fv_loja (sk_loja),
    KEY idx_fv_produto (sk_produto),
    KEY idx_fv_cliente (sk_cliente),
    KEY idx_fv_funcionario (sk_funcionario),
    KEY idx_fv_promocao (sk_promocao),
    KEY idx_fv_transacao (id_transacao),
    CONSTRAINT fk_fv_tempo FOREIGN KEY (sk_tempo) REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fv_loja FOREIGN KEY (sk_loja) REFERENCES dim_loja(sk_loja),
    CONSTRAINT fk_fv_produto FOREIGN KEY (sk_produto) REFERENCES dim_produto(sk_produto),
    CONSTRAINT fk_fv_cliente FOREIGN KEY (sk_cliente) REFERENCES dim_cliente(sk_cliente),
    CONSTRAINT fk_fv_funcionario FOREIGN KEY (sk_funcionario) REFERENCES dim_funcionario(sk_funcionario),
    CONSTRAINT fk_fv_promocao FOREIGN KEY (sk_promocao) REFERENCES dim_promocao(sk_promocao)
);

CREATE TABLE fato_compras (
    sk_compra               BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_pedido_compra        VARCHAR(40) NOT NULL,
    sk_tempo                INT NOT NULL,
    sk_loja                 INT NOT NULL,
    sk_produto              INT NOT NULL,
    sk_fornecedor           INT NOT NULL,
    quantidade              INT NOT NULL,
    custo_unitario          DECIMAL(10,2) NOT NULL,
    frete_unitario          DECIMAL(10,2) NOT NULL,
    impostos_unitario       DECIMAL(10,2) NOT NULL,
    valor_total             DECIMAL(12,2) NOT NULL,
    prazo_entrega_dias      INT NOT NULL,
    recebido_no_prazo       TINYINT(1) NOT NULL,
    KEY idx_fc_tempo (sk_tempo),
    KEY idx_fc_loja (sk_loja),
    KEY idx_fc_produto (sk_produto),
    KEY idx_fc_fornecedor (sk_fornecedor),
    KEY idx_fc_pedido (id_pedido_compra),
    CONSTRAINT fk_fc_tempo FOREIGN KEY (sk_tempo) REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fc_loja FOREIGN KEY (sk_loja) REFERENCES dim_loja(sk_loja),
    CONSTRAINT fk_fc_produto FOREIGN KEY (sk_produto) REFERENCES dim_produto(sk_produto),
    CONSTRAINT fk_fc_fornecedor FOREIGN KEY (sk_fornecedor) REFERENCES dim_fornecedor(sk_fornecedor)
);

CREATE TABLE fato_estoque (
    sk_estoque              BIGINT AUTO_INCREMENT PRIMARY KEY,
    sk_tempo                INT NOT NULL,
    sk_loja                 INT NOT NULL,
    sk_produto              INT NOT NULL,
    estoque_inicial         INT NOT NULL,
    entrada                 INT NOT NULL,
    saida                   INT NOT NULL,
    perda                   INT NOT NULL,
    ruptura                 TINYINT(1) NOT NULL,
    estoque_final           INT NOT NULL,
    cobertura_dias          DECIMAL(10,2) NOT NULL,
    KEY idx_fe_tempo (sk_tempo),
    KEY idx_fe_loja (sk_loja),
    KEY idx_fe_produto (sk_produto),
    CONSTRAINT fk_fe_tempo FOREIGN KEY (sk_tempo) REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fe_loja FOREIGN KEY (sk_loja) REFERENCES dim_loja(sk_loja),
    CONSTRAINT fk_fe_produto FOREIGN KEY (sk_produto) REFERENCES dim_produto(sk_produto)
);

-- =========================================================
-- CARGA DA DIM_TEMPO
-- Período: 2023-01-01 até 2025-12-31
-- =========================================================
INSERT INTO dim_tempo (
    data_completa, ano, semestre, trimestre, mes, nome_mes,
    semana_ano, dia, dia_semana_num, dia_semana_nome, fim_de_semana
)
SELECT
    dt,
    YEAR(dt),
    CASE WHEN MONTH(dt) <= 6 THEN 1 ELSE 2 END,
    QUARTER(dt),
    MONTH(dt),
    ELT(MONTH(dt),'Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'),
    WEEK(dt, 3),
    DAY(dt),
    DAYOFWEEK(dt),
    ELT(DAYOFWEEK(dt),'Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado'),
    CASE WHEN DAYOFWEEK(dt) IN (1,7) THEN 1 ELSE 0 END
FROM (
    SELECT DATE_ADD('2023-01-01', INTERVAL n-1 DAY) AS dt
    FROM util_numbers
    WHERE n <= DATEDIFF('2025-12-31','2023-01-01') + 1
) t;

-- =========================================================
-- CARGA DA DIM_LOJA
-- =========================================================
INSERT INTO dim_loja (
    codigo_loja, nome_loja, tipo_loja, regiao, estado, cidade, bairro,
    area_m2, data_abertura, status_loja
)
SELECT
    CONCAT('LJ', LPAD(n, 4, '0')),
    CONCAT('Supermercado Unidade ', n),
    CASE
        WHEN MOD(n, 10) IN (1,2) THEN 'Hipermercado'
        WHEN MOD(n, 10) IN (3,4,5) THEN 'Supermercado'
        WHEN MOD(n, 10) IN (6,7) THEN 'Atacarejo'
        ELSE 'Loja de Bairro'
    END,
    CASE
        WHEN MOD(n, 5) = 0 THEN 'Sudeste'
        WHEN MOD(n, 5) = 1 THEN 'Sul'
        WHEN MOD(n, 5) = 2 THEN 'Nordeste'
        WHEN MOD(n, 5) = 3 THEN 'Centro-Oeste'
        ELSE 'Norte'
    END,
    ELT(1 + MOD(n, 10), 'SP','RJ','MG','PR','SC','RS','BA','GO','PE','CE'),
    ELT(1 + MOD(n, 12), 'São Paulo','Rio de Janeiro','Belo Horizonte','Campinas','Curitiba','Porto Alegre','Salvador','Goiânia','Recife','Fortaleza','Santos','Ribeirão Preto'),
    ELT(1 + MOD(n, 15), 'Centro','Jardins','Moema','Tatuapé','Pinheiros','Vila Mariana','Santana','Ipiranga','Butantã','Lapa','Liberdade','Saúde','Morumbi','Perdizes','Bela Vista'),
    300 + MOD(n * 137, 7800),
    DATE_ADD('2008-01-01', INTERVAL MOD(n * 53, 6200) DAY),
    CASE WHEN MOD(n, 29) = 0 THEN 'Em reforma' ELSE 'Ativa' END
FROM util_numbers
WHERE n <= @qtd_lojas;

-- =========================================================
-- CARGA DA DIM_FORNECEDOR
-- =========================================================
INSERT INTO dim_fornecedor (
    codigo_fornecedor, nome_fornecedor, categoria_principal, estado_origem,
    prazo_medio_dias, lead_time_dias, rating_fornecedor, ativo
)
SELECT
    CONCAT('FOR', LPAD(n, 5, '0')),
    CONCAT(
        ELT(1 + MOD(n, 12), 'Alimentos','Bebidas','Higiene','Limpeza','Frios','Laticínios','Carnes','Padaria','Bazar','Pet','Farma','Congelados'),
        ' Distribuição ',
        n
    ),
    ELT(1 + MOD(n, 12), 'Mercearia','Bebidas','Higiene','Limpeza','Frios','Laticínios','Açougue','Padaria','Bazar','Pet','Perfumaria','Congelados'),
    ELT(1 + MOD(n, 10), 'SP','RJ','MG','PR','SC','RS','BA','GO','PE','CE'),
    7 + MOD(n, 35),
    3 + MOD(n, 18),
    ROUND(3.2 + (MOD(n * 17, 19) / 10), 2),
    CASE WHEN MOD(n, 41) = 0 THEN 0 ELSE 1 END
FROM util_numbers
WHERE n <= @qtd_fornecedores;

-- =========================================================
-- CARGA DA DIM_PRODUTO
-- =========================================================
INSERT INTO dim_produto (
    codigo_produto, ean, nome_produto, marca, departamento, categoria, subcategoria,
    unidade_medida, peso_liquido_g, produto_marca_propria, perecivel,
    fornecedor_padrao_sk, preco_lista, custo_unitario, margem_base_pct, ativo
)
SELECT
    CONCAT('PRD', LPAD(n, 6, '0')),
    CONCAT('789', LPAD(n, 10, '0')),
    CONCAT(
        ELT(1 + MOD(n, 20), 'Arroz','Feijão','Macarrão','Leite','Refrigerante','Sabonete','Detergente','Shampoo','Iogurte','Queijo','Pão','Biscoito','Café','Açúcar','Farinha','Óleo','Água','Chocolate','Ração','Absorvente'),
        ' ',
        ELT(1 + MOD(n, 18), 'Tradicional','Premium','Integral','Light','Zero','Família','Econômico','Natural','Suave','Extra','Max','Fresh','Plus','Caseiro','Artesanal','Fortificado','Kids','Original'),
        ' ',
        n
    ),
    ELT(1 + MOD(n, 15), 'Marca A','Marca B','Marca C','Marca D','Marca E','Marca F','Marca G','Marca H','Marca I','Marca J','Marca K','Marca L','Marca M','Marca N','Marca Própria'),
    CASE
        WHEN MOD(n, 10) IN (0,1) THEN 'Mercearia'
        WHEN MOD(n, 10) = 2 THEN 'Bebidas'
        WHEN MOD(n, 10) = 3 THEN 'Higiene'
        WHEN MOD(n, 10) = 4 THEN 'Limpeza'
        WHEN MOD(n, 10) = 5 THEN 'Laticínios'
        WHEN MOD(n, 10) = 6 THEN 'Açougue'
        WHEN MOD(n, 10) = 7 THEN 'Padaria'
        WHEN MOD(n, 10) = 8 THEN 'Bazar'
        ELSE 'Pet'
    END,
    ELT(1 + MOD(n, 12), 'Grãos','Sucos','Banho','Casa','Frios','Carnes','Pães','Utilidades','Animais','Doces','Cereais','Perfumaria'),
    ELT(1 + MOD(n, 16), 'Standard','Premium','Diet','Light','Zero','Tradicional','Orgânico','Sem Glúten','Sem Lactose','Kids','Família','Refil','Concentrado','Mini','Grande','Econômico'),
    ELT(1 + MOD(n, 6), 'UN','KG','G','L','ML','CX'),
    ROUND(50 + MOD(n * 73, 4850), 2),
    CASE WHEN MOD(n, 11) = 0 THEN 1 ELSE 0 END,
    CASE WHEN MOD(n, 9) IN (0,1,2) THEN 1 ELSE 0 END,
    1 + MOD(n - 1, @qtd_fornecedores),
    ROUND(
        CASE
            WHEN MOD(n, 10) IN (0,1) THEN 3 + (MOD(n * 13, 1500) / 10)
            WHEN MOD(n, 10) = 2 THEN 2 + (MOD(n * 17, 2500) / 10)
            WHEN MOD(n, 10) = 3 THEN 4 + (MOD(n * 19, 3000) / 10)
            WHEN MOD(n, 10) = 4 THEN 5 + (MOD(n * 23, 2200) / 10)
            WHEN MOD(n, 10) = 5 THEN 3 + (MOD(n * 29, 1800) / 10)
            WHEN MOD(n, 10) = 6 THEN 8 + (MOD(n * 31, 4500) / 10)
            WHEN MOD(n, 10) = 7 THEN 1 + (MOD(n * 37, 1200) / 10)
            WHEN MOD(n, 10) = 8 THEN 6 + (MOD(n * 41, 6500) / 10)
            ELSE 7 + (MOD(n * 43, 5500) / 10)
        END
    , 2),
    ROUND(
        CASE
            WHEN MOD(n, 10) IN (0,1) THEN (3 + (MOD(n * 13, 1500) / 10)) * 0.72
            WHEN MOD(n, 10) = 2 THEN (2 + (MOD(n * 17, 2500) / 10)) * 0.68
            WHEN MOD(n, 10) = 3 THEN (4 + (MOD(n * 19, 3000) / 10)) * 0.63
            WHEN MOD(n, 10) = 4 THEN (5 + (MOD(n * 23, 2200) / 10)) * 0.66
            WHEN MOD(n, 10) = 5 THEN (3 + (MOD(n * 29, 1800) / 10)) * 0.71
            WHEN MOD(n, 10) = 6 THEN (8 + (MOD(n * 31, 4500) / 10)) * 0.79
            WHEN MOD(n, 10) = 7 THEN (1 + (MOD(n * 37, 1200) / 10)) * 0.59
            WHEN MOD(n, 10) = 8 THEN (6 + (MOD(n * 41, 6500) / 10)) * 0.74
            ELSE (7 + (MOD(n * 43, 5500) / 10)) * 0.76
        END
    , 2),
    ROUND(18 + MOD(n * 7, 33), 2),
    CASE WHEN MOD(n, 97) = 0 THEN 0 ELSE 1 END
FROM util_numbers
WHERE n <= @qtd_produtos;

-- =========================================================
-- CARGA DA DIM_CLIENTE
-- =========================================================
INSERT INTO dim_cliente (
    codigo_cliente, nome_cliente, sexo, faixa_etaria, renda_faixa,
    estado, cidade, bairro, canal_preferido, data_cadastro, cliente_ativo
)
SELECT
    CONCAT('CLI', LPAD(n, 7, '0')),
    CONCAT(
        ELT(1 + MOD(n, 20), 'Ana','Bruno','Carlos','Daniela','Eduardo','Fernanda','Gabriel','Helena','Igor','Juliana','Karina','Lucas','Mariana','Nicolas','Patrícia','Rafael','Sabrina','Thiago','Vanessa','William'),
        ' ',
        ELT(1 + MOD(n, 20), 'Silva','Souza','Oliveira','Santos','Pereira','Lima','Costa','Almeida','Ribeiro','Carvalho','Gomes','Martins','Rocha','Dias','Araujo','Barbosa','Moura','Freitas','Mendes','Teixeira')
    ),
    CASE WHEN MOD(n, 2) = 0 THEN 'Feminino' ELSE 'Masculino' END,
    CASE
        WHEN MOD(n, 7) = 0 THEN '18-24'
        WHEN MOD(n, 7) = 1 THEN '25-34'
        WHEN MOD(n, 7) = 2 THEN '35-44'
        WHEN MOD(n, 7) = 3 THEN '45-54'
        WHEN MOD(n, 7) = 4 THEN '55-64'
        ELSE '65+'
    END,
    CASE
        WHEN MOD(n, 6) = 0 THEN 'Até 2 SM'
        WHEN MOD(n, 6) = 1 THEN '2 a 4 SM'
        WHEN MOD(n, 6) = 2 THEN '4 a 8 SM'
        WHEN MOD(n, 6) = 3 THEN '8 a 12 SM'
        WHEN MOD(n, 6) = 4 THEN '12 a 20 SM'
        ELSE '20+ SM'
    END,
    ELT(1 + MOD(n, 10), 'SP','RJ','MG','PR','SC','RS','BA','GO','PE','CE'),
    ELT(1 + MOD(n, 12), 'São Paulo','Rio de Janeiro','Belo Horizonte','Campinas','Curitiba','Porto Alegre','Salvador','Goiânia','Recife','Fortaleza','Santos','Ribeirão Preto'),
    ELT(1 + MOD(n, 15), 'Centro','Jardins','Moema','Tatuapé','Pinheiros','Vila Mariana','Santana','Ipiranga','Butantã','Lapa','Liberdade','Saúde','Morumbi','Perdizes','Bela Vista'),
    ELT(1 + MOD(n, 4), 'Loja Física','App','Site','WhatsApp'),
    DATE_ADD('2019-01-01', INTERVAL MOD(n * 11, 2555) DAY),
    CASE WHEN MOD(n, 23) = 0 THEN 0 ELSE 1 END
FROM util_numbers
WHERE n <= @qtd_clientes;

-- =========================================================
-- CARGA DA DIM_FUNCIONARIO
-- =========================================================
INSERT INTO dim_funcionario (
    codigo_funcionario, nome_funcionario, cargo, departamento, loja_sk,
    data_admissao, turno, salario, status_funcionario
)
SELECT
    CONCAT('FUN', LPAD(n, 6, '0')),
    CONCAT(
        ELT(1 + MOD(n, 20), 'André','Beatriz','Caio','Débora','Elisa','Fabio','Giovana','Hugo','Isabela','João','Kelly','Leandro','Michele','Natália','Otávio','Priscila','Renato','Simone','Tatiane','Vinicius'),
        ' ',
        ELT(1 + MOD(n, 20), 'Silva','Souza','Oliveira','Santos','Pereira','Lima','Costa','Almeida','Ribeiro','Carvalho','Gomes','Martins','Rocha','Dias','Araujo','Barbosa','Moura','Freitas','Mendes','Teixeira')
    ),
    CASE
        WHEN MOD(n, 8) = 0 THEN 'Gerente'
        WHEN MOD(n, 8) = 1 THEN 'Subgerente'
        WHEN MOD(n, 8) = 2 THEN 'Operador de Caixa'
        WHEN MOD(n, 8) = 3 THEN 'Repositor'
        WHEN MOD(n, 8) = 4 THEN 'Fiscal de Loja'
        WHEN MOD(n, 8) = 5 THEN 'Açougueiro'
        WHEN MOD(n, 8) = 6 THEN 'Padeiro'
        ELSE 'Auxiliar'
    END,
    CASE
        WHEN MOD(n, 7) = 0 THEN 'Administrativo'
        WHEN MOD(n, 7) = 1 THEN 'Frente de Caixa'
        WHEN MOD(n, 7) = 2 THEN 'Mercearia'
        WHEN MOD(n, 7) = 3 THEN 'Açougue'
        WHEN MOD(n, 7) = 4 THEN 'Padaria'
        WHEN MOD(n, 7) = 5 THEN 'Prevenção'
        ELSE 'Operações'
    END,
    1 + MOD(n - 1, @qtd_lojas),
    DATE_ADD('2016-01-01', INTERVAL MOD(n * 17, 3650) DAY),
    ELT(1 + MOD(n, 3), 'Manhã','Tarde','Noite'),
    ROUND(
        CASE
            WHEN MOD(n, 8) = 0 THEN 6500 + MOD(n * 13, 6000)
            WHEN MOD(n, 8) = 1 THEN 4200 + MOD(n * 11, 3000)
            WHEN MOD(n, 8) = 2 THEN 1700 + MOD(n * 7, 1200)
            WHEN MOD(n, 8) = 3 THEN 1800 + MOD(n * 5, 1000)
            WHEN MOD(n, 8) = 4 THEN 2200 + MOD(n * 3, 1500)
            WHEN MOD(n, 8) = 5 THEN 2300 + MOD(n * 19, 1700)
            WHEN MOD(n, 8) = 6 THEN 2400 + MOD(n * 23, 1800)
            ELSE 1600 + MOD(n * 29, 900)
        END
    , 2),
    CASE WHEN MOD(n, 37) = 0 THEN 'Inativo' ELSE 'Ativo' END
FROM util_numbers
WHERE n <= @qtd_funcionarios;

-- =========================================================
-- CARGA DA DIM_PROMOCAO
-- =========================================================
INSERT INTO dim_promocao (
    codigo_promocao, nome_promocao, tipo_promocao, canal, desconto_pct,
    leva_qtd, paga_qtd, data_inicio, data_fim, ativa
)
SELECT
    CONCAT('PRO', LPAD(n, 5, '0')),
    CONCAT(
        ELT(1 + MOD(n, 10), 'Semana do Cliente','Festival de Ofertas','Aniversário da Rede','Liquida Estoque','Preço Baixo','Feirão','Compre Mais','Volta às Aulas','Black Week','Natal Econômico'),
        ' ',
        n
    ),
    CASE
        WHEN MOD(n, 4) = 0 THEN 'Percentual'
        WHEN MOD(n, 4) = 1 THEN 'Leve Mais Pague Menos'
        WHEN MOD(n, 4) = 2 THEN 'Combo'
        ELSE 'Preço Especial'
    END,
    ELT(1 + MOD(n, 4), 'Loja Física','App','Site','Omnichannel'),
    ROUND(5 + MOD(n * 7, 35), 2),
    CASE WHEN MOD(n, 4) = 1 THEN 3 ELSE NULL END,
    CASE WHEN MOD(n, 4) = 1 THEN 2 ELSE NULL END,
    DATE_ADD('2023-01-01', INTERVAL MOD(n * 9, 1000) DAY),
    DATE_ADD(DATE_ADD('2023-01-01', INTERVAL MOD(n * 9, 1000) DAY), INTERVAL 3 + MOD(n, 20) DAY),
    CASE WHEN MOD(n, 5) = 0 THEN 0 ELSE 1 END
FROM util_numbers
WHERE n <= @qtd_promocoes;

-- =========================================================
-- FATO_VENDAS
-- Lógica:
-- - datas entre 2023 e 2025
-- - maior peso para loja física
-- - promoções em parte das linhas
-- - quantidades realistas para varejo alimentar
-- =========================================================
INSERT INTO fato_vendas (
    id_transacao, sk_tempo, sk_loja, sk_produto, sk_cliente, sk_funcionario,
    sk_promocao, canal_venda, forma_pagamento, quantidade, preco_unitario,
    desconto_unitario, custo_unitario, valor_bruto, valor_desconto,
    valor_liquido, lucro_bruto, margem_pct
)
SELECT
    CONCAT('TX', LPAD(n, 10, '0')),
    1 + MOD(n * 13, (SELECT COUNT(*) FROM dim_tempo)),
    1 + MOD(n * 17, @qtd_lojas),
    1 + MOD(n * 19, @qtd_produtos),
    1 + MOD(n * 23, @qtd_clientes),
    1 + MOD(n * 29, @qtd_funcionarios),
    CASE WHEN MOD(n, 4) = 0 THEN 1 + MOD(n * 31, @qtd_promocoes) ELSE NULL END,
    CASE
        WHEN MOD(n, 10) <= 6 THEN 'Loja Física'
        WHEN MOD(n, 10) IN (7,8) THEN 'App'
        ELSE 'Site'
    END,
    ELT(1 + MOD(n, 5), 'Cartão Crédito','Cartão Débito','PIX','Dinheiro','Vale Alimentação'),
    CASE
        WHEN MOD(n, 20) IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 1
        WHEN MOD(n, 20) IN (12,13,14,15,16) THEN 2
        WHEN MOD(n, 20) IN (17,18) THEN 3
        ELSE 4
    END AS qtd,
    p.preco_lista,
    ROUND(
        CASE
            WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
            ELSE 0
        END
    , 2),
    p.custo_unitario,
    ROUND(
        (
            CASE
                WHEN MOD(n, 20) IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 1
                WHEN MOD(n, 20) IN (12,13,14,15,16) THEN 2
                WHEN MOD(n, 20) IN (17,18) THEN 3
                ELSE 4
            END
        ) * p.preco_lista
    , 2),
    ROUND(
        (
            CASE
                WHEN MOD(n, 20) IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 1
                WHEN MOD(n, 20) IN (12,13,14,15,16) THEN 2
                WHEN MOD(n, 20) IN (17,18) THEN 3
                ELSE 4
            END
        ) *
        (
            CASE
                WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
                ELSE 0
            END
        )
    , 2),
    ROUND(
        (
            CASE
                WHEN MOD(n, 20) IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 1
                WHEN MOD(n, 20) IN (12,13,14,15,16) THEN 2
                WHEN MOD(n, 20) IN (17,18) THEN 3
                ELSE 4
            END
        ) * (p.preco_lista -
            CASE
                WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
                ELSE 0
            END)
    , 2),
    ROUND(
        (
            CASE
                WHEN MOD(n, 20) IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 1
                WHEN MOD(n, 20) IN (12,13,14,15,16) THEN 2
                WHEN MOD(n, 20) IN (17,18) THEN 3
                ELSE 4
            END
        ) * ((p.preco_lista -
            CASE
                WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
                ELSE 0
            END) - p.custo_unitario)
    , 2),
    ROUND(
        CASE
            WHEN ((p.preco_lista -
                CASE
                    WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
                    ELSE 0
                END)) > 0
            THEN (((p.preco_lista -
                CASE
                    WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
                    ELSE 0
                END) - p.custo_unitario) /
                (p.preco_lista -
                CASE
                    WHEN MOD(n, 4) = 0 THEN p.preco_lista * ((5 + MOD(n * 7, 25)) / 100)
                    ELSE 0
                END)) * 100
            ELSE 0
        END
    , 2)
FROM util_numbers u
JOIN dim_produto p
    ON p.sk_produto = 1 + MOD(u.n * 19, @qtd_produtos)
WHERE u.n <= @qtd_vendas;

-- =========================================================
-- FATO_COMPRAS
-- =========================================================
INSERT INTO fato_compras (
    id_pedido_compra, sk_tempo, sk_loja, sk_produto, sk_fornecedor,
    quantidade, custo_unitario, frete_unitario, impostos_unitario,
    valor_total, prazo_entrega_dias, recebido_no_prazo
)
SELECT
    CONCAT('PO', LPAD(n, 10, '0')),
    1 + MOD(n * 7, (SELECT COUNT(*) FROM dim_tempo)),
    1 + MOD(n * 11, @qtd_lojas),
    p.sk_produto,
    p.fornecedor_padrao_sk,
    10 + MOD(n * 13, 490),
    p.custo_unitario,
    ROUND(p.custo_unitario * (0.01 + (MOD(n, 8) / 100)), 2),
    ROUND(p.custo_unitario * (0.04 + (MOD(n, 6) / 100)), 2),
    ROUND(
        (10 + MOD(n * 13, 490)) *
        (
            p.custo_unitario +
            (p.custo_unitario * (0.01 + (MOD(n, 8) / 100))) +
            (p.custo_unitario * (0.04 + (MOD(n, 6) / 100)))
        )
    , 2),
    2 + MOD(n, 20),
    CASE WHEN MOD(n, 10) <= 7 THEN 1 ELSE 0 END
FROM util_numbers u
JOIN dim_produto p
    ON p.sk_produto = 1 + MOD(u.n * 5, @qtd_produtos)
WHERE u.n <= @qtd_compras;

-- =========================================================
-- FATO_ESTOQUE
-- Snapshot operacional
-- =========================================================
INSERT INTO fato_estoque (
    sk_tempo, sk_loja, sk_produto, estoque_inicial, entrada, saida,
    perda, ruptura, estoque_final, cobertura_dias
)
SELECT
    1 + MOD(n * 3, (SELECT COUNT(*) FROM dim_tempo)),
    1 + MOD(n * 5, @qtd_lojas),
    1 + MOD(n * 7, @qtd_produtos),
    20 + MOD(n * 11, 350),
    MOD(n * 13, 180),
    MOD(n * 17, 160),
    MOD(n, 8),
    CASE
        WHEN (20 + MOD(n * 11, 350) + MOD(n * 13, 180) - MOD(n * 17, 160) - MOD(n, 8)) <= 0 THEN 1
        ELSE 0
    END,
    GREATEST(0, (20 + MOD(n * 11, 350) + MOD(n * 13, 180) - MOD(n * 17, 160) - MOD(n, 8))),
    ROUND(
        GREATEST(0, (20 + MOD(n * 11, 350) + MOD(n * 13, 180) - MOD(n * 17, 160) - MOD(n, 8))) /
        GREATEST(1, MOD(n * 17, 160))
    , 2)
FROM util_numbers
WHERE n <= @qtd_estoque;

-- =========================================================
-- ÍNDICES COMPLEMENTARES
-- =========================================================
CREATE INDEX idx_produto_depto_categoria ON dim_produto (departamento, categoria, subcategoria);
CREATE INDEX idx_cliente_estado_cidade   ON dim_cliente (estado, cidade);
CREATE INDEX idx_loja_estado_cidade      ON dim_loja (estado, cidade);
CREATE INDEX idx_tempo_ano_mes           ON dim_tempo (ano, mes);
CREATE INDEX idx_promocao_periodo        ON dim_promocao (data_inicio, data_fim);

SET foreign_key_checks = 1;

-- =========================================================
-- CONSULTAS RÁPIDAS DE VALIDAÇÃO
-- =========================================================
SELECT 'dim_tempo' AS tabela, COUNT(*) AS linhas FROM dim_tempo
UNION ALL SELECT 'dim_loja', COUNT(*) FROM dim_loja
UNION ALL SELECT 'dim_fornecedor', COUNT(*) FROM dim_fornecedor
UNION ALL SELECT 'dim_produto', COUNT(*) FROM dim_produto
UNION ALL SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL SELECT 'dim_funcionario', COUNT(*) FROM dim_funcionario
UNION ALL SELECT 'dim_promocao', COUNT(*) FROM dim_promocao
UNION ALL SELECT 'fato_vendas', COUNT(*) FROM fato_vendas
UNION ALL SELECT 'fato_compras', COUNT(*) FROM fato_compras
UNION ALL SELECT 'fato_estoque', COUNT(*) FROM fato_estoque;

SELECT
    l.estado,
    p.departamento,
    SUM(v.valor_liquido) AS faturamento,
    SUM(v.lucro_bruto) AS lucro,
    SUM(v.quantidade) AS itens_vendidos
FROM fato_vendas v
JOIN dim_loja l     ON v.sk_loja = l.sk_loja
JOIN dim_produto p  ON v.sk_produto = p.sk_produto
GROUP BY l.estado, p.departamento
ORDER BY faturamento DESC
LIMIT 20;