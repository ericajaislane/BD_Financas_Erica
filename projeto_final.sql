-- #######################################################################
-- SCRIPT DE IMPLEMENTAÇÃO: SISTEMA DE CONTROLE FINANCEIRO PESSOAL
-- SGBD: MySQL
-- #######################################################################

-- 0. CONFIGURAÇÃO INICIAL (Obrigatório para evitar o Erro 1046)
CREATE DATABASE IF NOT EXISTS financas_pessoais_db;
USE financas_pessoais_db;


-- 1. DDL - Data Definition Language (Criação das Tabelas)

-- 1.1 Entidades Principais e Fortes
CREATE TABLE USUARIO (
    ID_Usuario INT PRIMARY KEY AUTO_INCREMENT,
    Primeiro_Nome VARCHAR(50) NOT NULL,
    Sobrenome VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Senha VARCHAR(255) NOT NULL 
);

CREATE TABLE CATEGORIA (
    ID_Categoria INT PRIMARY KEY AUTO_INCREMENT,
    Nome VARCHAR(50) NOT NULL UNIQUE,
    Tipo ENUM('Receita', 'Despesa') NOT NULL
);

CREATE TABLE CONTA_FINANCEIRA (
    ID_Conta INT PRIMARY KEY AUTO_INCREMENT,
    ID_Usuario INT NOT NULL,
    Nome VARCHAR(100) NOT NULL,
    Saldo_Atual DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    Tipo ENUM('Corrente', 'Poupanca', 'Investimento') NOT NULL,
    FOREIGN KEY (ID_Usuario) REFERENCES USUARIO(ID_Usuario) ON DELETE CASCADE
);

CREATE TABLE CARTAO_CREDITO (
    ID_Cartao INT PRIMARY KEY AUTO_INCREMENT,
    ID_Usuario INT NOT NULL,
    Bandeira VARCHAR(30),
    Limite DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (ID_Usuario) REFERENCES USUARIO(ID_Usuario) ON DELETE CASCADE
);

CREATE TABLE META_FINANCEIRA (
    ID_Meta INT PRIMARY KEY AUTO_INCREMENT,
    ID_Usuario INT NOT NULL,
    Nome VARCHAR(100) NOT NULL,
    Valor_Alvo DECIMAL(10, 2) NOT NULL,
    Valor_Atual DECIMAL(10, 2) DEFAULT 0.00,
    FOREIGN KEY (ID_Usuario) REFERENCES USUARIO(ID_Usuario) ON DELETE CASCADE
);

-- 1.2 Generalização/Especialização (TRANSAÇÃO, RECEITA, DESPESA)
CREATE TABLE TRANSACAO (
    ID_Transacao INT PRIMARY KEY AUTO_INCREMENT,
    ID_Usuario INT NOT NULL,
    Data DATE NOT NULL,
    Valor DECIMAL(10, 2) NOT NULL CHECK (Valor > 0),
    Observacao VARCHAR(255),
    FOREIGN KEY (ID_Usuario) REFERENCES USUARIO(ID_Usuario) ON DELETE CASCADE
);

CREATE TABLE DESPESA (
    ID_Transacao INT PRIMARY KEY,
    ID_Categoria INT,
    Local_Compra VARCHAR(100),
    Num_Comprovante VARCHAR(50) UNIQUE,
    FOREIGN KEY (ID_Transacao) REFERENCES TRANSACAO(ID_Transacao) ON DELETE CASCADE,
    FOREIGN KEY (ID_Categoria) REFERENCES CATEGORIA(ID_Categoria)
);

CREATE TABLE RECEITA (
    ID_Transacao INT PRIMARY KEY,
    ID_Categoria INT,
    Fonte VARCHAR(100) NOT NULL,
    Recorrente BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (ID_Transacao) REFERENCES TRANSACAO(ID_Transacao) ON DELETE CASCADE,
    FOREIGN KEY (ID_Categoria) REFERENCES CATEGORIA(ID_Categoria)
);

-- 1.3 Entidades Complexas (Fraca, Ternário, M:N e Multivalorado)

-- Entidade Fraca: PARCELA (Depende de DESPESA)
CREATE TABLE PARCELA (
    ID_Transacao INT,
    Num_Parcela TINYINT NOT NULL,
    Data_Vencimento DATE NOT NULL,
    Valor_Parcela DECIMAL(10, 2) NOT NULL, 
    Status ENUM('Paga', 'Pendente', 'Atrasada') NOT NULL,
    PRIMARY KEY (ID_Transacao, Num_Parcela),
    FOREIGN KEY (ID_Transacao) REFERENCES DESPESA(ID_Transacao) ON DELETE CASCADE
);

-- Relacionamento Ternário: ALOCACAO_DE_FUNDOS
CREATE TABLE ALOCACAO_DE_FUNDOS (
    ID_Alocacao INT PRIMARY KEY AUTO_INCREMENT,
    ID_Usuario INT NOT NULL,
    ID_Meta INT NOT NULL,
    ID_Conta INT NOT NULL,
    Valor_Alocado DECIMAL(10, 2) NOT NULL CHECK (Valor_Alocado > 0),
    Data_Alocacao DATE NOT NULL,
    FOREIGN KEY (ID_Usuario) REFERENCES USUARIO(ID_Usuario) ON DELETE CASCADE,
    FOREIGN KEY (ID_Meta) REFERENCES META_FINANCEIRA(ID_Meta) ON DELETE CASCADE,
    FOREIGN KEY (ID_Conta) REFERENCES CONTA_FINANCEIRA(ID_Conta) ON DELETE RESTRICT
);

-- Entidade Associativa M:N: ITEM_FATURA
CREATE TABLE ITEM_FATURA (
    ID_Despesa INT,
    ID_Cartao INT,
    Data_Faturacao DATE,
    Status_Pagamento ENUM('Pendente', 'Pago') NOT NULL,
    PRIMARY KEY (ID_Despesa, ID_Cartao),
    FOREIGN KEY (ID_Despesa) REFERENCES DESPESA(ID_Transacao) ON DELETE CASCADE,
    FOREIGN KEY (ID_Cartao) REFERENCES CARTAO_CREDITO(ID_Cartao) ON DELETE CASCADE
);

-- Mapeamento do Atributo Multivalorado: TAGS
CREATE TABLE TAG (
    ID_Tag INT PRIMARY KEY AUTO_INCREMENT,
    Nome_Tag VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE TRANSACAO_TAG (
    ID_Transacao INT,
    ID_Tag INT,
    PRIMARY KEY (ID_Transacao, ID_Tag),
    FOREIGN KEY (ID_Transacao) REFERENCES TRANSACAO(ID_Transacao) ON DELETE CASCADE,
    FOREIGN KEY (ID_Tag) REFERENCES TAG(ID_Tag) ON DELETE CASCADE
);


-- #######################################################################
-- 2. DML - Data Manipulation Language (População do Banco)
-- #######################################################################

-- Inserção 1: Usuário
INSERT INTO USUARIO (Primeiro_Nome, Sobrenome, Email, Senha) VALUES
('Erica Jaislane', 'Fernandes', 'erica.jaislane@ucb.br', 'hash_de_exemplo_123'); 

-- Inserção 2: Categorias
INSERT INTO CATEGORIA (Nome, Tipo) VALUES
('Salario', 'Receita'), ('Alimentacao', 'Despesa'), 
('Transporte', 'Despesa'), ('Investimentos', 'Receita');

-- Inserção 3: Contas, Cartão e Meta
INSERT INTO CONTA_FINANCEIRA (ID_Usuario, Nome, Saldo_Atual, Tipo) VALUES
(1, 'Conta Corrente Principal', 3500.00, 'Corrente'), (1, 'Poupanca Viagem', 1500.00, 'Poupanca');
INSERT INTO CARTAO_CREDITO (ID_Usuario, Bandeira, Limite) VALUES (1, 'Mastercard', 2500.00);
INSERT INTO META_FINANCEIRA (ID_Usuario, Nome, Valor_Alvo) VALUES (1, 'Reserva de Emergencia', 10000.00);

-- Inserção 4: Transações (RECEITA e DESPESA)
-- T1: Salário (RECEITA)
INSERT INTO TRANSACAO (ID_Usuario, Data, Valor) VALUES (1, '2025-10-01', 5000.00);
INSERT INTO RECEITA (ID_Transacao, ID_Categoria, Fonte, Recorrente) VALUES (1, 1, 'Trabalho Fixo', TRUE);
-- T2: Supermercado (DESPESA no Cartão)
INSERT INTO TRANSACAO (ID_Usuario, Data, Valor) VALUES (1, '2025-10-05', 800.00);
INSERT INTO DESPESA (ID_Transacao, ID_Categoria, Local_Compra) VALUES (2, 2, 'Supermercado Local');

-- Inserção 5: Entidades Complexas (Fraca, M:N, Ternário e Multivalorado)
-- Parcela
INSERT INTO PARCELA (ID_Transacao, Num_Parcela, Data_Vencimento, Valor_Parcela, Status) VALUES 
(2, 1, '2025-11-05', 800.00, 'Pendente');

-- Item Fatura (Associa Despesa T2 ao Cartão 1)
INSERT INTO ITEM_FATURA (ID_Despesa, ID_Cartao, Status_Pagamento) VALUES (2, 1, 'Pendente');
-- Alocação de Fundos (Ternário: Usuário 1, Meta 1, Conta 2)
INSERT INTO ALOCACAO_DE_FUNDOS (ID_Usuario, ID_Meta, ID_Conta, Valor_Alocado, Data_Alocacao) VALUES
(1, 1, 2, 500.00, '2025-10-02');
-- Tags e Associação (T2: 'Essencial' e 'Mensal')
INSERT INTO TAG (Nome_Tag) VALUES ('Essencial'), ('Mensal');
INSERT INTO TRANSACAO_TAG (ID_Transacao, ID_Tag) VALUES (2, 1), (2, 2); 


-- #######################################################################
-- 3. Consultas e Manipulação (Para Gerar as Evidências)
-- #######################################################################

-- 3.1 SELECT (COMPLEXO): Balanço de Receitas e Despesas por Categoria (Herança)
SELECT
    C.Tipo,
    C.Nome AS Categoria,
    SUM(T.Valor) AS Total_Movimentado
FROM
    TRANSACAO T
JOIN
    CATEGORIA C ON T.ID_Transacao IN (SELECT ID_Transacao FROM DESPESA WHERE ID_Categoria = C.ID_Categoria)
    OR T.ID_Transacao IN (SELECT ID_Transacao FROM RECEITA WHERE ID_Categoria = C.ID_Categoria)
WHERE
    T.ID_Usuario = 1
GROUP BY
    C.Tipo, C.Nome;

-- 3.2 SELECT (M:N): Despesas de Cartão de Crédito na próxima fatura
SELECT
    T.Data,
    T.Valor,
    D.Local_Compra,
    IFAT.Status_Pagamento
FROM
    ITEM_FATURA IFAT
JOIN
    DESPESA D ON IFAT.ID_Despesa = D.ID_Transacao
JOIN
    TRANSACAO T ON D.ID_Transacao = T.ID_Transacao
WHERE
    IFAT.ID_Cartao = 1;

-- 3.3 SELECT (Ternário): Contas que contribuíram para uma Meta específica
SELECT
    M.Nome AS Meta,
    CF.Nome AS Conta_Origem,
    A.Valor_Alocado
FROM
    ALOCACAO_DE_FUNDOS A
JOIN
    META_FINANCEIRA M ON A.ID_Meta = M.ID_Meta
JOIN
    CONTA_FINANCEIRA CF ON A.ID_Conta = CF.ID_Conta
WHERE
    M.ID_Meta = 1;

-- 3.4 UPDATE: Simulação de Pagamento de Item de Fatura
UPDATE ITEM_FATURA
SET Status_Pagamento = 'Pago'
WHERE ID_Despesa = 2 AND ID_Cartao = 1;