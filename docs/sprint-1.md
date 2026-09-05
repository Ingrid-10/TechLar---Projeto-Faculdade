# Sprint 1 — Venda Assistida em Loja Física

**Entrega:** AC1 — 14/09/2026  
**Tema:** Sales / processo de venda

## Objetivo

Permitir que o vendedor da TechLar realize uma venda completa em loja física, em uma única página Lightning, gravando pedido e itens no CRM.

## Fluxo

1. Localizar ou cadastrar cliente (Account + Contact)
2. Pesquisar produtos no catálogo (Product2 + PricebookEntry)
3. Montar carrinho (quantidade, subtotal, total)
4. Escolher retirada na loja ou entrega no endereço
5. Finalizar: Apex valida e cria Order + OrderItem
6. Confirmar o número do pedido

## Modelo

| Conceito | Objeto Salesforce |
| --- | --- |
| Cliente (pessoa física) | Account (identificação) + Contact 1:1 |
| CPF | Account.CPF__c (e Contact.CPF__c, mesmo valor) |
| Produto | Product2 + PricebookEntry |
| Pedido | Order |
| Item | OrderItem |
| Canal | Order.CanalVenda__c = Loja Física |
| Recebimento | Order.ModalidadeRecebimento__c |

## Regras (Apex)

- Pedido exige cliente
- Pelo menos um produto
- Quantidade > 0
- Preço válido (consultado no catálogo, não só na tela)
- Modalidade obrigatória
- Entrega exige endereço
- Total recalculado no servidor

## Evidência Front + Back + Dados

- Front: LWC `techlarSalesPage`
- Back: `TechLarSalesController` / `TechLarSalesService`
- Dados: Order ativado com OrderItems ligados ao Contact
