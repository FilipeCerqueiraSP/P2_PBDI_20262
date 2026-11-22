-- FASE 2 - ENUNCIADO 5
-- Conectado ao banco pelo psql do CloudShell, crie os schemas staging e dw e a tabela
-- staging.sales, com as colunas e os tipos da Tabela 2, NOT NULL em todas elas e row_id como
-- chave primária. Registre todo o SQL no script.sql.
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

-- IF NOT EXISTS: a tabela ja deve existir antes do job do Glue (Fase 2).
CREATE TABLE IF NOT EXISTS staging.sales (
    row_id        INTEGER PRIMARY KEY,
    order_id      VARCHAR(20) NOT NULL,
    order_date    DATE NOT NULL,
    ship_date     DATE NOT NULL,
    ship_mode     VARCHAR(20) NOT NULL,
    customer_id   VARCHAR(20) NOT NULL,
    customer_name VARCHAR(60) NOT NULL,
    segment       VARCHAR(20) NOT NULL,
    country       VARCHAR(40) NOT NULL,
    city          VARCHAR(60) NOT NULL,
    state         VARCHAR(40) NOT NULL,
    postal_code   VARCHAR(10) NOT NULL,
    region        VARCHAR(20) NOT NULL,
    product_id    VARCHAR(20) NOT NULL,
    category      VARCHAR(30) NOT NULL,
    sub_category  VARCHAR(30) NOT NULL,
    product_name  VARCHAR(200) NOT NULL,
    sales         NUMERIC(12,2) NOT NULL
);

 ----------------------------------------------------------------------------
-- Fase 5 - Enunciado 10
-- Escreva uma única consulta sobre staging.sales que devolva, em uma linha: a quantidade de
-- linhas, a soma de sales, a menor data de pedido, a maior data de envio, a quantidade de
-- códigos postais 'N/D' e a quantidade de linhas com data de envio anterior à data do pedido.
-- Registre os valores em comentário. A quantidade de linhas e a de códigos postais 'N/D' devem
-- coincidir com as respostas (a) e (c) do Enunciado 2.

SELECT COUNT(*) AS quantidade_linhas,
       SUM(sales) AS soma_sales,
       MIN(order_date) AS menor_data_pedido,
       MAX(ship_date) AS maior_data_envio,
       (SELECT COUNT(*) FROM staging.sales
        WHERE postal_code = 'N/D') AS postais_nd,
       (SELECT COUNT(*) FROM staging.sales
        WHERE ship_date < order_date) AS envios_anteriores
FROM staging.sales;

------------------------------------------------
