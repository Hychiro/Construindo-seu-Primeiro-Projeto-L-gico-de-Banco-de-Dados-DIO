-- Métodos de pagamento
INSERT INTO pagamento_metodo (nome) VALUES
  ('CARTAO_CREDITO'), ('PIX'), ('BOLETO'), ('PAYPAL');

-- Fornecedores
INSERT INTO fornecedor (razao_social, cnpj) VALUES
  ('Alpha Supply Ltda', '12.345.678/0001-90'),
  ('Beta Distribuidora SA', '98.765.432/0001-10');

-- Vendedores terceiros
INSERT INTO terceiros_vendedor (razao_social, local) VALUES
  ('Loja Parceira 1', 'São Paulo'),
  ('Loja Parceira 2', 'Rio de Janeiro'),
  ('Alpha Supply Ltda', 'Campinas'); -- mesmo nome para testar vendedor=fornecedor

-- Produtos
INSERT INTO produto (categoria, descricao, valor) VALUES
  ('Eletrônicos', 'Fone Bluetooth X', 199.90),
  ('Casa', 'Cafeteira Pro 500', 349.00),
  ('Games', 'Controle Pro GX', 299.50);

-- Mapeamentos de fornecimento
INSERT INTO disponibiliza (id_fornecedor, id_produto) VALUES
  (1, 1), (1, 3), (2, 2);

-- Estoques
INSERT INTO estoque (local) VALUES
  ('CD - SP'), ('CD - MG');

-- Quantidades em estoque
INSERT INTO produto_estoque (id_produto, id_estoque, quantidade) VALUES
  (1, 1, 100), (1, 2, 25),
  (2, 1, 60), (3, 2, 40);

-- Revenda de terceiros
INSERT INTO terceiros_revenda (id_vendedor, id_produto, quantidade) VALUES
  (1, 1, 10),
  (2, 2, 5),
  (3, 3, 15);

-- Clientes
INSERT INTO cliente (tipo, nome, documento, endereco) VALUES
  ('PF', 'Maria Silva', '123.456.789-00', 'Rua A, 100 - São Paulo'),
  ('PJ', 'Tech Co. Ltda', '12.345.678/0001-00', 'Av. B, 2000 - Belo Horizonte'),
  ('PF', 'João Souza', '987.654.321-00', 'Rua C, 50 - Juiz de Fora');

-- Subtipos: criar registros correspondentes e então atualizar cliente para validar trigger
INSERT INTO cliente_pf (id_cliente, data_nascimento) VALUES
  (1, '1990-05-12'),
  (3, '1985-11-23');

INSERT INTO cliente_pj (id_cliente, inscricao_estadual) VALUES
  (2, 'IS-55667788');

-- Reforçar trigger com atualização leve (opcional se AFTER INSERT já dispara)
UPDATE cliente SET nome = nome WHERE id_cliente IN (1,2,3);

-- Pedidos
INSERT INTO pedido (id_cliente, status) VALUES
  (1, 'ABERTO'),
  (2, 'ABERTO'),
  (1, 'ABERTO');

-- Itens dos pedidos (valor_unitario salvo no momento da venda)
INSERT INTO pedido_item (id_pedido, id_produto, quantidade, valor_unitario) VALUES
  (1, 1, 2, 199.90),  -- Maria compra 2 Fones
  (1, 3, 1, 299.50),  -- + 1 Controle
  (2, 2, 3, 349.00),  -- Tech Co compra 3 Cafeteiras
  (3, 1, 1, 189.90);  -- Maria compra 1 Fone (promo)

-- Pagamentos (multi-método no pedido 2)
INSERT INTO pagamento (id_pedido, id_cliente, id_metodo, status, valor) VALUES
  (1, 1, 2, 'APROVADO', 399.80),     -- PIX para pedido 1 (parcial)
  (1, 1, 1, 'APROVADO', 299.50),     -- Cartão para pedido 1 (restante)
  (2, 2, 1, 'APROVADO', 800.00),     -- Cartão para pedido 2 (parcial)
  (2, 2, 2, 'APROVADO', 247.00),     -- PIX para pedido 2 (complemento)
  (3, 1, 3, 'PENDENTE', 189.90);     -- Boleto pendente para pedido 3

-- Entregas
INSERT INTO entrega (codigo_rastreio, id_pedido, id_cliente, status, endereco_entrega) VALUES
  ('BR123-SP-0001', 1, 1, 'EM_TRANSPORTE', 'Rua A, 100 - São Paulo'),
  ('BR456-MG-0002', 2, 2, 'EM_PREPARO', 'Av. B, 2000 - Belo Horizonte'),
  ('BR789-MG-0003', 3, 1, 'CANCELADO', 'Rua A, 100 - São Paulo');