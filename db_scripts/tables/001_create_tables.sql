-- Criação do esquema
CREATE SCHEMA IF NOT EXISTS ecommerce;
SET search_path TO ecommerce;

-- Tabela: Fornecedor
CREATE TABLE fornecedor (
  id_fornecedor SERIAL PRIMARY KEY,
  razao_social VARCHAR(100) NOT NULL,
  cnpj VARCHAR(18) NOT NULL UNIQUE
);

-- Tabela: Terceiros - Vendedor
CREATE TABLE terceiros_vendedor (
  id_vendedor SERIAL PRIMARY KEY,
  razao_social VARCHAR(100) NOT NULL,
  local VARCHAR(100)
);

-- Tabela: Terceiros - Revenda (associação vendedor-produto)
CREATE TABLE terceiros_revenda (
  id_revenda SERIAL PRIMARY KEY,
  id_vendedor INT NOT NULL REFERENCES terceiros_vendedor(id_vendedor) ON DELETE CASCADE,
  id_produto INT NOT NULL,
  quantidade INT NOT NULL CHECK (quantidade >= 0),
  UNIQUE (id_vendedor, id_produto)
);

-- Tabela: Estoque
CREATE TABLE estoque (
  id_estoque SERIAL PRIMARY KEY,
  local VARCHAR(100) NOT NULL
);

-- Tabela: Produto
CREATE TABLE produto (
  id_produto SERIAL PRIMARY KEY,
  categoria VARCHAR(45) NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  valor NUMERIC(12,2) NOT NULL CHECK (valor >= 0)
);

-- FK que foi adiada na criação de terceiros_revenda
ALTER TABLE terceiros_revenda
  ADD CONSTRAINT fk_revenda_produto
  FOREIGN KEY (id_produto) REFERENCES produto(id_produto) ON DELETE CASCADE;

-- Tabela: Disponibiliza (Fornecedor fornece Produto)
CREATE TABLE disponibiliza (
  id_fornecedor INT NOT NULL REFERENCES fornecedor(id_fornecedor) ON DELETE CASCADE,
  id_produto INT NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
  PRIMARY KEY (id_fornecedor, id_produto)
);

-- Tabela: Produto em Estoque (quantidade por estoque)
CREATE TABLE produto_estoque (
  id_produto INT NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
  id_estoque INT NOT NULL REFERENCES estoque(id_estoque) ON DELETE CASCADE,
  quantidade INT NOT NULL CHECK (quantidade >= 0),
  PRIMARY KEY (id_produto, id_estoque)
);

-- Tabela: Cliente (super-tipo)
CREATE TABLE cliente (
  id_cliente SERIAL PRIMARY KEY,
  tipo CHAR(2) NOT NULL CHECK (tipo IN ('PF','PJ')),
  nome VARCHAR(100) NOT NULL,
  documento VARCHAR(20) NOT NULL UNIQUE,
  endereco VARCHAR(200) NOT NULL
);

-- Subtipo: Cliente PF (1:1 com cliente quando tipo = 'PF')
CREATE TABLE cliente_pf (
  id_cliente INT PRIMARY KEY REFERENCES cliente(id_cliente) ON DELETE CASCADE,
  data_nascimento DATE NOT NULL
);

-- Subtipo: Cliente PJ (1:1 com cliente quando tipo = 'PJ')
CREATE TABLE cliente_pj (
  id_cliente INT PRIMARY KEY REFERENCES cliente(id_cliente) ON DELETE CASCADE,
  inscricao_estadual VARCHAR(30)
);

-- Trigger para garantir exclusividade PF/PJ conforme tipo
CREATE OR REPLACE FUNCTION trg_cliente_tipo_enforce()
RETURNS TRIGGER AS $$
BEGIN
  -- Na inserção/atualização, assegura a existência exclusiva do subtipo
  IF NEW.tipo = 'PF' THEN
    -- PF deve existir em cliente_pf e não existir em cliente_pj
    IF NOT EXISTS (SELECT 1 FROM cliente_pf WHERE id_cliente = NEW.id_cliente) THEN
      RAISE EXCEPTION 'Cliente PF requer registro em cliente_pf para id_cliente=%', NEW.id_cliente;
    END IF;
    IF EXISTS (SELECT 1 FROM cliente_pj WHERE id_cliente = NEW.id_cliente) THEN
      RAISE EXCEPTION 'Cliente PF não pode ter registro em cliente_pj para id_cliente=%', NEW.id_cliente;
    END IF;
  ELSIF NEW.tipo = 'PJ' THEN
    -- PJ deve existir em cliente_pj e não existir em cliente_pf
    IF NOT EXISTS (SELECT 1 FROM cliente_pj WHERE id_cliente = NEW.id_cliente) THEN
      RAISE EXCEPTION 'Cliente PJ requer registro em cliente_pj para id_cliente=%', NEW.id_cliente;
    END IF;
    IF EXISTS (SELECT 1 FROM cliente_pf WHERE id_cliente = NEW.id_cliente) THEN
      RAISE EXCEPTION 'Cliente PJ não pode ter registro em cliente_pf para id_cliente=%', NEW.id_cliente;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Dispara após inserção/atualização (deferrable por transação, se desejar)
CREATE TRIGGER cliente_tipo_enforce
AFTER INSERT OR UPDATE ON cliente
FOR EACH ROW EXECUTE FUNCTION trg_cliente_tipo_enforce();

-- Tabela: Pedido (sem atributos de produto; itens ficam em pedido_item)
CREATE TABLE pedido (
  id_pedido SERIAL PRIMARY KEY,
  id_cliente INT NOT NULL REFERENCES cliente(id_cliente),
  data_pedido TIMESTAMP NOT NULL DEFAULT NOW(),
  status VARCHAR(30) NOT NULL DEFAULT 'ABERTO'
);

-- Relação Produto x Pedido (itens)
CREATE TABLE pedido_item (
  id_pedido INT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
  id_produto INT NOT NULL REFERENCES produto(id_produto),
  quantidade INT NOT NULL CHECK (quantidade > 0),
  valor_unitario NUMERIC(12,2) NOT NULL CHECK (valor_unitario >= 0),
  PRIMARY KEY (id_pedido, id_produto)
);

-- Tabela: Métodos de Pagamento (domínio)
CREATE TABLE pagamento_metodo (
  id_metodo SERIAL PRIMARY KEY,
  nome VARCHAR(50) NOT NULL UNIQUE
);

-- Tabela: Pagamento (múltiplos por pedido)
CREATE TABLE pagamento (
  id_pagamento SERIAL PRIMARY KEY,
  id_pedido INT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
  id_cliente INT NOT NULL REFERENCES cliente(id_cliente),
  id_metodo INT NOT NULL REFERENCES pagamento_metodo(id_metodo),
  status VARCHAR(30) NOT NULL CHECK (status IN ('PENDENTE','APROVADO','RECUSADO','ESTORNADO','CANCELADO')),
  valor NUMERIC(12,2) NOT NULL CHECK (valor >= 0),
  data_pagamento TIMESTAMP DEFAULT NOW()
);

-- Index auxiliar para consultas por pedido
CREATE INDEX idx_pagamento_pedido ON pagamento(id_pedido);

-- Tabela: Entrega
CREATE TABLE entrega (
  codigo_rastreio VARCHAR(45) PRIMARY KEY,
  id_pedido INT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
  id_cliente INT NOT NULL REFERENCES cliente(id_cliente),
  status VARCHAR(30) NOT NULL CHECK (status IN ('EM_PREPARO','EM_TRANSPORTE','ENTREGUE','DEVOLVIDO','CANCELADO')),
  endereco_entrega VARCHAR(200) NOT NULL,
  data_atualizacao TIMESTAMP DEFAULT NOW()
);

-- View: total do pedido (derivado)
CREATE VIEW vw_pedido_totais AS
SELECT
  p.id_pedido,
  p.id_cliente,
  SUM(pi.quantidade * pi.valor_unitario)::NUMERIC(12,2) AS total_itens,
  COALESCE((
    SELECT SUM(pg.valor)
    FROM pagamento pg
    WHERE pg.id_pedido = p.id_pedido
      AND pg.status = 'APROVADO'
  ), 0)::NUMERIC(12,2) AS total_pago,
  (SUM(pi.quantidade * pi.valor_unitario) - COALESCE((
    SELECT SUM(pg.valor)
    FROM pagamento pg
    WHERE pg.id_pedido = p.id_pedido
      AND pg.status = 'APROVADO'
  ), 0))::NUMERIC(12,2) AS saldo_pendente
FROM pedido p
JOIN pedido_item pi ON pi.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.id_cliente;