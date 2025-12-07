# E-commerce DB – Projeto Lógico (PostgreSQL)

## Contexto
Modelagem lógica de um banco de dados de e-commerce com suporte a fornecedores, vendedores terceiros, produtos, estoques, clientes PF/PJ, pedidos, pagamentos multi-método e entregas com rastreio e status.

## Decisões de modelagem
- Super-tipo `cliente` com subtipos `cliente_pf` e `cliente_pj`, garantindo exclusividade via trigger EER.
- Normalização do pedido com `pedido_item` para multiplos produtos e conservação de preço no momento da venda.
- `pagamento` permite múltiplas formas por pedido (chaves para `pagamento_metodo`), status por parcela e data.
- `entrega` possui `codigo_rastreio` único, status e endereço de entrega.
- Relacionamentos:
  - `disponibiliza` (fornecedor × produto)
  - `produto_estoque` (produto × estoque, com quantidade)
  - `terceiros_revenda` (vendedor × produto, com quantidade)

## Scripts
- Em tables: criação de tabelas, constraints, triggers e view derivada de totais de pedido.
- Em seeds: inserções para testes.
- Em queries: consultas com SELECT/WHERE, atributos derivados, ORDER BY, HAVING e JOINs.

## Perguntas respondidas
- Quantos pedidos foram feitos por cada cliente?
- Algum vendedor também é fornecedor?
- Relação de produtos, fornecedores e estoques.
- Relação de nomes dos fornecedores e nomes dos produtos.
- Pedidos com entrega em transporte e pagamento parcial.

## Observações
- Desenvolvido para PostgreSQL 13+ (CHECKs e triggers).
- View `vw_pedido_totais` facilita auditoria de saldos.