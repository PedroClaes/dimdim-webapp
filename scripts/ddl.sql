-- =========================================================
-- DimDim - DDL das tabelas (Azure SQL Database)
-- Relacionamento: cliente (1) ---- (N) conta
-- =========================================================

DROP TABLE IF EXISTS conta;
DROP TABLE IF EXISTS cliente;

CREATE TABLE cliente (
    id             BIGINT IDENTITY(1,1) NOT NULL,
    nome           VARCHAR(100)         NOT NULL,
    cpf            VARCHAR(11)          NOT NULL,
    email          VARCHAR(120)         NOT NULL,
    data_cadastro  DATE                 NOT NULL CONSTRAINT df_cliente_data DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT pk_cliente     PRIMARY KEY (id),
    CONSTRAINT uq_cliente_cpf UNIQUE (cpf)
);

CREATE TABLE conta (
    id          BIGINT IDENTITY(1,1) NOT NULL,
    numero      VARCHAR(20)          NOT NULL,
    agencia     VARCHAR(10)          NOT NULL,
    tipo        VARCHAR(20)          NOT NULL,
    saldo       NUMERIC(15,2)        NOT NULL CONSTRAINT df_conta_saldo DEFAULT 0,
    cliente_id  BIGINT               NOT NULL,
    CONSTRAINT pk_conta         PRIMARY KEY (id),
    CONSTRAINT uq_conta_numero  UNIQUE (numero),
    CONSTRAINT ck_conta_tipo    CHECK (tipo IN ('CORRENTE', 'POUPANCA')),
    CONSTRAINT ck_conta_saldo   CHECK (saldo >= 0),
    CONSTRAINT fk_conta_cliente FOREIGN KEY (cliente_id) REFERENCES cliente (id)
);

CREATE INDEX ix_conta_cliente ON conta (cliente_id);
