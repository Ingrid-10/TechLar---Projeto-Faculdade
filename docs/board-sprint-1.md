# Board — Sprint 1 (GitHub Projects)

Histórias da AC1. Espelhar estes cards no GitHub Projects do repositório.

## Épico

Como vendedor da TechLar, quero localizar um cliente, selecionar os produtos desejados e concluir uma venda em uma única interface, para que o pedido e seus itens sejam registrados no CRM.

## Histórias

1. **Cliente** — pesquisar por nome/e-mail/CPF e cadastrar Contact + Account.
2. **Produto** — pesquisar catálogo Product2/PricebookEntry e adicionar à venda.
3. **Carrinho** — quantidade, subtotal e total.
4. **Entrega** — retirada ou entrega; CEP ViaCEP + frete mock se entrega.
5. **Finalização** — Apex valida, cria Order + OrderItem e mostra confirmação.

## Critérios de aceitação

- Venda concluída grava pedido, itens e vínculo com o cliente.
- Carrinho vazio não cria pedido.
- Entrega sem endereço solicita os dados.
