-- FASE 2 - ENUNCIADO 5
-- Conectado ao banco pelo psql do CloudShell, crie os schemas staging e dw e a tabela
-- staging.sales, com as colunas e os tipos da Tabela 2, NOT NULL em todas elas e row_id como
-- chave primária. Registre todo o SQL no script.sql.
------------------------------------------------------------------------------
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


------------------------------------------------------------------------------
-- ENUNCIADO 11 | Fase 6 | texto do enunciado da prova:
-- Crie e carregue dw.dim_date como na Seção 12.4 da apostila, com o calendário gerado por
-- generate_series a partir de subconsultas sobre a staging: do primeiro dia do ano da menor
-- data de pedido até o último dia do ano da maior data de envio. Explique em comentário por que
-- o fim do calendário é calculado com a data de envio, e não com a do pedido.

DROP TABLE IF EXISTS dw.carga_log;
DROP TABLE IF EXISTS dw.fact_sales CASCADE;
DROP TABLE IF EXISTS dw.dim_customer CASCADE;
DROP TABLE IF EXISTS dw.dim_product CASCADE;
DROP TABLE IF EXISTS dw.dim_location CASCADE;
DROP TABLE IF EXISTS dw.dim_ship_mode CASCADE;
DROP TABLE IF EXISTS dw.dim_date CASCADE;

CREATE TABLE dw.dim_date (
    date_sk      INTEGER PRIMARY KEY,
    full_date    DATE NOT NULL UNIQUE,
    day          SMALLINT NOT NULL,
    month        SMALLINT NOT NULL,
    month_name   VARCHAR(15) NOT NULL,
    quarter      SMALLINT NOT NULL,
    year         SMALLINT NOT NULL,
    day_of_week  VARCHAR(15) NOT NULL,
    is_weekend   BOOLEAN NOT NULL
);


TRUNCATE TABLE dw.dim_date;
INSERT INTO dw.dim_date
SELECT CAST(TO_CHAR(d, 'YYYYMMDD') AS INTEGER),
       d::DATE,
       EXTRACT(DAY FROM d)::SMALLINT,
       EXTRACT(MONTH FROM d)::SMALLINT,
       TO_CHAR(d, 'TMMonth'),
       EXTRACT(QUARTER FROM d)::SMALLINT,
       EXTRACT(YEAR FROM d)::SMALLINT,
       TO_CHAR(d, 'TMDay'),
       EXTRACT(DOW FROM d) IN (0, 6)
FROM generate_series(
       (SELECT date_trunc('year', MIN(order_date)) FROM staging.sales),
       (SELECT date_trunc('year', MAX(ship_date))
               + INTERVAL '1 year - 1 day' FROM staging.sales),
       INTERVAL '1 day'
) g(d);


SELECT MIN(full_date) AS data_inicial,
       MAX(full_date) AS data_final,
       COUNT(*) AS total_dias
FROM dw.dim_date;

-- Pedidos feitos no final do ano, podem ter envios no início do próximo ano;
-- Então ao usar a maior data de pedido podemos deixar datas de envio fora do
-- calendário, causando erros de chave estrangeira na carga da fato.


---------------------------------
------------------------------------------------------------------------------
-- Fase 6 - Enunciado 12
-- Escreva três consultas de verificação sobre a staging e registre os resultados em comentário:
-- quantos product_id aparecem com mais de um product_name; quantos customer_id aparecem com
-- mais de um customer_name ou mais de um segment; e quantas combinações de cidade, estado e
-- código postal aparecem com mais de uma região.
------------------------------------------------------------------------------

SELECT COUNT(*) AS product_id_nomes_distintos
FROM (
    SELECT product_id FROM staging.sales
    GROUP BY product_id
    HAVING COUNT(DISTINCT product_name) > 1
) divergencias_produt_name;

SELECT COUNT(*) AS customer_id_distintos
FROM (
    SELECT customer_id FROM staging.sales
    GROUP BY customer_id
    HAVING COUNT(DISTINCT customer_name) > 1
        OR COUNT(DISTINCT segment) > 1
) divergencias_customer;

SELECT COUNT(*) AS locais_com_regioes_distintas
FROM (
    SELECT city, state, postal_code FROM staging.sales
    GROUP BY city, state, postal_code
    HAVING COUNT(DISTINCT region) > 1
) divergencias_locais;

-- product_id com mais de um product_name: 32 ---------------------------------
-- customer_id com mais de um customer_name ou mais de um segment: 0 ----------
-- combinações de cidade, estado e código postal com mais de uma região: 0 ----


----------------------------------------------------------------------------
-- Fase 6 - Enunciado 13
-- Crie as tabelas dw.dim_customer, dw.dim_product, dw.dim_location, dw.dim_ship_mode e
-- dw.fact_sales conforme a Figura 4: chaves SERIAL, atributos naturais UNIQUE (em dim_location,
-- a combinação de país, estado, cidade e código postal), seis chaves estrangeiras NOT NULL na
-- fato, duas delas para dw.dim_date, métricas NOT NULL e um índice por chave estrangeira. Nesta
-- fase as tabelas ficam vazias.
------------------------------------------------------------------------------
CREATE TABLE dw.dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(60) NOT NULL,
    segment VARCHAR(20) NOT NULL
);

CREATE TABLE dw.dim_product (
    product_sk SERIAL PRIMARY KEY,
    product_id VARCHAR(20) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) NOT NULL
);

CREATE TABLE dw.dim_location (
    location_sk SERIAL PRIMARY KEY,
    country VARCHAR(40) NOT NULL,
    state VARCHAR(40) NOT NULL,
    city VARCHAR(60) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    region VARCHAR(20) NOT NULL,
    UNIQUE (country, state, city, postal_code)
);

CREATE TABLE dw.dim_ship_mode (
    ship_mode_sk SERIAL PRIMARY KEY,
    ship_mode VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE dw.fact_sales (
    sale_sk SERIAL PRIMARY KEY,
    row_nk INTEGER NOT NULL UNIQUE,
    order_nk VARCHAR(20) NOT NULL,
    order_date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    ship_date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    customer_sk INTEGER NOT NULL REFERENCES dw.dim_customer(customer_sk),
    product_sk INTEGER NOT NULL REFERENCES dw.dim_product(product_sk),
    location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
    ship_mode_sk INTEGER NOT NULL REFERENCES dw.dim_ship_mode(ship_mode_sk),
    sales NUMERIC(12,2) NOT NULL,
    ship_days INTEGER NOT NULL
);

CREATE INDEX ix_fs_order_date ON dw.fact_sales(order_date_sk);
CREATE INDEX ix_fs_ship_date ON dw.fact_sales(ship_date_sk);
CREATE INDEX ix_fs_customer ON dw.fact_sales(customer_sk);
CREATE INDEX ix_fs_product ON dw.fact_sales(product_sk);
CREATE INDEX ix_fs_location ON dw.fact_sales(location_sk);
CREATE INDEX ix_fs_ship_mode ON dw.fact_sales(ship_mode_sk);


-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------

-- FASE 7 - ENUNCIADO 14


CREATE OR REPLACE PROCEDURE dw.carrega_dw()
LANGUAGE plpgsql
AS $$
DECLARE
    v_linhas INTEGER;
    v_staging BIGINT;
    v_fato BIGINT;

BEGIN
    -- ETAPA 1: limpa o modelo dimensional E Reinicia as sequencias, sem apagar a dim_date. ( item A)

    TRUNCATE TABLE dw.fact_sales, dw.dim_customer,
                   dw.dim_product, dw.dim_location,
                   dw.dim_ship_mode
             RESTART IDENTITY CASCADE;

    RAISE NOTICE 'Modelo dimensional limpo';


    -- ETAPA 2: montando as dimensoes, a partir dos dados da staging (item b)


    INSERT INTO dw.dim_customer (customer_id, customer_name, segment)
    SELECT customer_id, MIN(customer_name), MIN(segment)
    FROM staging.sales
    GROUP BY customer_id;

    -- Contagem de linhas inseridas (item d)
    GET DIAGNOSTICS v_linhas = ROW_COUNT;
    RAISE NOTICE 'Clientes carregados: % linhas', v_linhas;


    INSERT INTO dw.dim_product (product_id, product_name, category, sub_category)
    SELECT product_id, MIN(product_name), MIN(category), MIN(sub_category)
    FROM staging.sales
    GROUP BY product_id;

    GET DIAGNOSTICS v_linhas = ROW_COUNT;
    RAISE NOTICE 'Produtos carregados: % linhas', v_linhas;


    INSERT INTO dw.dim_location (country, state, city, postal_code, region)
    SELECT country, state, city, postal_code, MIN(region)
    FROM staging.sales
    GROUP BY country, state, city, postal_code;

    GET DIAGNOSTICS v_linhas = ROW_COUNT;
    RAISE NOTICE 'Localizacoes carregadas: % linhas', v_linhas;


    INSERT INTO dw.dim_ship_mode (ship_mode)
    SELECT DISTINCT ship_mode FROM staging.sales;

    GET DIAGNOSTICS v_linhas = ROW_COUNT;
    RAISE NOTICE 'Modalidades carregadas: % linhas', v_linhas;

    RAISE NOTICE 'Dimensoes carregadas';


    -- ETAPA 3: montagem da fato (item c)
  

    INSERT INTO dw.fact_sales (
        row_nk, order_nk, order_date_sk, ship_date_sk,
        customer_sk, product_sk, location_sk, ship_mode_sk,
        sales, ship_days
    )
    SELECT
        s.row_id,
        s.order_id,
        CAST(TO_CHAR(s.order_date, 'YYYYMMDD') AS INTEGER),
        CAST(TO_CHAR(s.ship_date, 'YYYYMMDD') AS INTEGER),
        dc.customer_sk,
        dp.product_sk,
        dl.location_sk,
        dm.ship_mode_sk,
        s.sales,
        s.ship_date - s.order_date
    FROM staging.sales s
    JOIN dw.dim_customer dc
         ON dc.customer_id = s.customer_id
    JOIN dw.dim_product dp
         ON dp.product_id = s.product_id
    JOIN dw.dim_location dl
         ON dl.country = s.country
         AND dl.state = s.state
         AND dl.city = s.city
         AND dl.postal_code = s.postal_code
    JOIN dw.dim_ship_mode dm
         ON dm.ship_mode = s.ship_mode;


    GET DIAGNOSTICS v_linhas = ROW_COUNT;
    RAISE NOTICE 'Fato carregado: % linhas', v_linhas;


    -- ETAPA 4: confere se a fato equivale a stanging, se não, retorna erro (item e)


    SELECT COUNT(*) INTO v_staging FROM staging.sales;
    SELECT COUNT(*) INTO v_fato FROM dw.fact_sales;

    IF v_fato <> v_staging THEN
        RAISE EXCEPTION 'Carga inconsistente: staging=%; fato=%',
                        v_staging, v_fato;
    END IF;

    RAISE NOTICE 'Carga concluida com sucesso';

END;
$$;


-- EXECUTAR A PROCEDURE

CALL dw.carrega_dw();


-- Conferindo as quantidades de linhas das quatro dimensoes e da fato

SELECT 'dim_customer' AS tabela, COUNT(*) AS linhas FROM dw.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dw.dim_product
UNION ALL
SELECT 'dim_location', COUNT(*) FROM dw.dim_location
UNION ALL
SELECT 'dim_ship_mode', COUNT(*) FROM dw.dim_ship_mode
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dw.fact_sales;


--NOTICE:  Modelo dimensional limpo
--NOTICE:  Clientes carregados: 793 linhas
--NOTICE:  Produtos carregados: 1861 linhas
--NOTICE:  Localizacoes carregadas: 628 linhas
--NOTICE:  Modalidades carregadas: 4 linhas
--NOTICE:  Dimensoes carregadas
--NOTICE:  Fato carregado: 9800 linhas
--NOTICE:  Carga concluida com sucesso
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- Fase 8 - Enunciado 15
-- Crie a tabela dw.carga_log (identificador SERIAL, sale_sk, row_nk, operação, usuário e
-- momento), a função dw.audita_fact_sales() e o trigger trg_audita_fact_sales, BEFORE INSERT e
-- FOR EACH ROW sobre dw.fact_sales, como na Seção 14 da apostila. A função rejeita, com RAISE
-- EXCEPTION e mensagem que identifique a linha, vendas com valor menor ou igual a zero e vendas
-- com ship_days negativo, e registra no log toda linha aceita. Teste com uma inserção válida e
-- deixe comentada uma inválida, acompanhada do erro esperado. Por fim, esvazie o log
-- reiniciando a sequência, chame novamente a procedure e confira que o log tem exatamente uma
-- linha por linha da fato.

CREATE TABLE dw.carga_log (
    log_id SERIAL PRIMARY KEY,
    sale_sk INTEGER NOT NULL,
    row_nk INTEGER NOT NULL,
    operacao VARCHAR(10) NOT NULL,
    usuario VARCHAR(60) NOT NULL,
    momento TIMESTAMP NOT NULL
);

CREATE OR REPLACE FUNCTION dw.audita_fact_sales()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.sales <= 0 THEN
        RAISE EXCEPTION 'Venda row_nk=% rejeitada: valor invalido (%)',
                        NEW.row_nk, NEW.sales;
    END IF;
    IF NEW.ship_days < 0 THEN
        RAISE EXCEPTION 'Venda row_nk=% rejeitada: envio negativo (%)',
                        NEW.row_nk, NEW.ship_days;
    END IF;
    INSERT INTO dw.carga_log (sale_sk, row_nk, operacao, usuario, momento)
    VALUES (NEW.sale_sk, NEW.row_nk, TG_OP, CURRENT_USER, NOW());
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audita_fact_sales
BEFORE INSERT ON dw.fact_sales
FOR EACH ROW
EXECUTE FUNCTION dw.audita_fact_sales();

-- Insere uma unica linha VALIDA para testar o disparo do trigger.
-- Reusa chaves existentes; row_nk -1 nao colide com o CSV.
INSERT INTO dw.fact_sales (
    row_nk, order_nk, order_date_sk, ship_date_sk,
    customer_sk, product_sk, location_sk, ship_mode_sk, sales, ship_days
)
SELECT -1, 'TESTE-VALIDO', f.order_date_sk, f.ship_date_sk,
       f.customer_sk, f.product_sk, f.location_sk, f.ship_mode_sk,
       1.00, 0
FROM dw.fact_sales f
LIMIT 1;


------------------ Teste INVALIDO ----------------------------------------------
-- INSERT INTO dw.fact_sales (
--   row_nk, order_nk, order_date_sk, ship_date_sk,
--   customer_sk, product_sk, location_sk, ship_mode_sk, sales, ship_days
-- )
-- SELECT -2, 'TESTE', f.order_date_sk, f.ship_date_sk,
--        f.customer_sk, f.product_sk, f.location_sk, f.ship_mode_sk,
--        0.00, 0
-- FROM dw.fact_sales f LIMIT 1;
-- Erro esperado: Venda row_nk=-2 rejeitada: valor invalido (0.00)


TRUNCATE TABLE dw.carga_log RESTART IDENTITY;
CALL dw.carrega_dw();

-- Esperado: 9800 linhas na fato, 9800 no log, diferenca zero.
SELECT (SELECT COUNT(*) FROM dw.carga_log) AS linhas_log,
       (SELECT COUNT(*) FROM dw.fact_sales) AS linhas_fato,
       (SELECT COUNT(*) FROM dw.carga_log)
         - (SELECT COUNT(*) FROM dw.fact_sales) AS diferenca;