# Board — Sprint 3 (GitHub Projects)

Board público (mesmo project das Sprints 1 e 2): [Projeto TechLar](https://github.com/users/Ingrid-10/projects/1)

A Sprint 3 passou de Customer 360 / Data 360 para **Gestão de Estoque e Transferência entre Lojas**. Os cards antigos de Customer 360 no GitHub Projects não foram alterados por este repositório; a view e os cards precisam ser atualizados manualmente. Os cards Done das Sprints 1 e 2 permanecem como estão.

Planejamento: [sprint-3.md](sprint-3.md).

## Épico

Como funcionário da TechLar, quero consultar o estoque de um produto em diferentes lojas e transferir quantidades entre unidades, para equilibrar a disponibilidade de produtos e melhorar a operação da empresa.

## Histórias

1. **Modelagem** — criar `Loja__c`, `Estoque__c`, `Transferencia_Estoque__c` e `Movimentacao_Estoque__c`.
2. **Dados** — cadastrar lojas fictícias e saldos iniciais sobre os produtos da Sprint 1.
3. **Consulta** — pesquisar um produto e listar a quantidade em cada loja.
4. **Transferência** — escolher origem, destino e quantidade; o Apex valida o saldo, grava a transferência, atualiza os dois estoques e registra a movimentação.
5. **Confirmação** — a LWC informa sucesso ou o motivo da recusa (saldo insuficiente, lojas iguais, quantidade inválida).

## Critérios de aceitação

- Com saldo suficiente, a transferência baixa a origem, aumenta o destino, grava `Transferencia_Estoque__c` e `Movimentacao_Estoque__c` e confirma na tela.
- Quantidade maior que o saldo disponível não altera registros e informa estoque insuficiente.
- Origem e destino iguais são recusados.

## Recorte atual

Modelagem, dados mockados, consulta, transferência e a LWC `techlarInventoryPage` estão no repositório. A aba do app é **Estoque**.
