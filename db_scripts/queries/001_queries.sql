-- Quantos pedidos foram feitos por cada cliente?
SELECT c.id_cliente, c.nome, COUNT(p.id_pedido) AS total_pedidos
FROM cliente c
LEFT JOIN pedido p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome
ORDER BY total_pedidos DESC;

-- Relação de nomes dos fornecedores e nomes dos produtos
SELECT f.razao_social AS fornecedor, pr.descricao AS produto
FROM disponibiliza d
JOIN fornecedor f ON f.id_fornecedor = d.id_fornecedor
JOIN produto pr ON pr.id_produto = d.id_produto
ORDER BY f.razao_social, pr.descricao;

-- Algum vendedor também é fornecedor? (match por razão social)
SELECT tv.razao_social AS vendedor_fornecedor
FROM terceiros_vendedor tv
JOIN fornecedor f ON f.razao_social = tv.razao_social
GROUP BY tv.razao_social;

-- Relação de produtos, fornecedores e estoques
SELECT pr.descricao AS produto,
       f.razao_social AS fornecedor,
       e.local AS estoque,
       pe.quantidade AS qtd_estoque
FROM produto pr
JOIN disponibiliza d ON d.id_produto = pr.id_produto
JOIN fornecedor f ON f.id_fornecedor = d.id_fornecedor
JOIN produto_estoque pe ON pe.id_produto = pr.id_produto
JOIN estoque e ON e.id_estoque = pe.id_estoque
ORDER BY pr.descricao, f.razao_social, e.local;

-- Pedidos com status 'ABERTO' e saldo pendente > 0 (usa view derivada)
SELECT vpt.id_pedido, c.nome, vpt.total_itens, vpt.total_pago, vpt.saldo_pendente
FROM vw_pedido_totais vpt
JOIN cliente c ON c.id_cliente = vpt.id_cliente
WHERE vpt.saldo_pendente > 0
ORDER BY vpt.saldo_pendente DESC;

-- Quantos pedidos foram feitos por cada cliente?
SELECT c.id_cliente, c.nome, COUNT(p.id_pedido) AS total_pedidos
FROM cliente c
LEFT JOIN pedido p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome
ORDER BY total_pedidos DESC;

-- Relação de nomes dos fornecedores e nomes dos produtos
SELECT f.razao_social AS fornecedor, pr.descricao AS produto
FROM disponibiliza d
JOIN fornecedor f ON f.id_fornecedor = d.id_fornecedor
JOIN produto pr ON pr.id_produto = d.id_produto
ORDER BY f.razao_social, pr.descricao;

-- Algum vendedor também é fornecedor? (match por razão social)
SELECT tv.razao_social AS vendedor_fornecedor
FROM terceiros_vendedor tv
JOIN fornecedor f ON f.razao_social = tv.razao_social
GROUP BY tv.razao_social;

-- Relação de produtos, fornecedores e estoques
SELECT pr.descricao AS produto,
       f.razao_social AS fornecedor,
       e.local AS estoque,
       pe.quantidade AS qtd_estoque
FROM produto pr
JOIN disponibiliza d ON d.id_produto = pr.id_produto
JOIN fornecedor f ON f.id_fornecedor = d.id_fornecedor
JOIN produto_estoque pe ON pe.id_produto = pr.id_produto
JOIN estoque e ON e.id_estoque = pe.id_estoque
ORDER BY pr.descricao, f.razao_social, e.local;

-- Pedidos com status 'ABERTO' e saldo pendente > 0 (usa view derivada)
SELECT vpt.id_pedido, c.nome, vpt.total_itens, vpt.total_pago, vpt.saldo_pendente
FROM vw_pedido_totais vpt
JOIN cliente c ON c.id_cliente = vpt.id_cliente
WHERE vpt.saldo_pendente > 0
ORDER BY vpt.saldo_pendente DESC;

-- Clientes com 2 ou mais pedidos
SELECT c.id_cliente, c.nome, COUNT(p.id_pedido) AS qtd_pedidos
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome
HAVING COUNT(p.id_pedido) >= 2
ORDER BY qtd_pedidos DESC;

-- Produtos cujo total vendido (qtd * valor) ultrapassa 500
SELECT pr.id_produto, pr.descricao,
       SUM(pi.quantidade * pi.valor_unitario)::NUMERIC(12,2) AS total_vendido
FROM pedido_item pi
JOIN produto pr ON pr.id_produto = pi.id_produto
GROUP BY pr.id_produto, pr.descricao
HAVING SUM(pi.quantidade * pi.valor_unitario) > 500
ORDER BY total_vendido DESC;

-- Quais pedidos têm entregas 'EM_TRANSPORTE' e pagamento parcialmente aprovado?
SELECT p.id_pedido,
       c.nome AS cliente,
       e.codigo_rastreio,
       e.status AS status_entrega,
       COALESCE(SUM(CASE WHEN pg.status = 'APROVADO' THEN pg.valor END), 0)::NUMERIC(12,2) AS total_pago,
       SUM(pi.quantidade * pi.valor_unitario)::NUMERIC(12,2) AS total_itens
FROM pedido p
JOIN cliente c ON c.id_cliente = p.id_cliente
JOIN entrega e ON e.id_pedido = p.id_pedido
JOIN pedido_item pi ON pi.id_pedido = p.id_pedido
LEFT JOIN pagamento pg ON pg.id_pedido = p.id_pedido
WHERE e.status = 'EM_TRANSPORTE'
GROUP BY p.id_pedido, c.nome, e.codigo_rastreio, e.status
HAVING COALESCE(SUM(CASE WHEN pg.status = 'APROVADO' THEN pg.valor END), 0)
       < SUM(pi.quantidade * pi.valor_unitario)
ORDER BY p.id_pedido;

-- Itens de pedido com estoque disponível no CD de MG (ilustra join multi-tabelas)
SELECT p.id_pedido, pr.descricao AS produto, pi.quantidade AS qtd_vendida,
       pe.quantidade AS qtd_disponivel, es.local AS deposito
FROM pedido p
JOIN pedido_item pi ON pi.id_pedido = p.id_pedido
JOIN produto pr ON pr.id_produto = pi.id_produto
JOIN produto_estoque pe ON pe.id_produto = pr.id_produto
JOIN estoque es ON es.id_estoque = pe.id_estoque
WHERE es.local ILIKE '%MG%'
ORDER BY p.id_pedido, produto;

-- Vendedores terceiros com portfólio e sobreposição com fornecedores
SELECT tv.razao_social AS vendedor,
       pr.descricao AS produto,
       tv.local,
       CASE WHEN EXISTS (
         SELECT 1 FROM fornecedor f WHERE f.razao_social = tv.razao_social
       ) THEN 'VENDEDOR_E_FORNECEDOR' ELSE 'APENAS_VENDEDOR' END AS classificacao
FROM terceiros_revenda tr
JOIN terceiros_vendedor tv ON tv.id_vendedor = tr.id_vendedor
JOIN produto pr ON pr.id_produto = tr.id_produto
ORDER BY vendedor, produto;
