# TechLar 360

Plataforma Salesforce da TechLar para centralizar vendas em loja física, atendimento, estoque entre lojas e inteligência artificial. Desenvolvida em 4 sprints para o projeto final de Análise e Desenvolvimento de Sistemas.

## Sprint 1 — Venda Assistida em Loja Física (AC1 — 14/09)

Interface LWC para o vendedor localizar ou cadastrar o cliente, montar o carrinho, escolher retirada ou entrega e gravar `Order` + `OrderItem` no Salesforce.

Documentação da sprint: [docs/sprint-1.md](docs/sprint-1.md)

Board: [Sprint 1 — Venda Assistida](https://github.com/users/Ingrid-10/projects/1)

Dados fictícios: [data/README.md](data/README.md)

## Pré-requisitos

- Salesforce CLI (`sf`)
- Org Salesforce com Orders habilitado (Developer Edition ou equivalente)
- Permissão para criar produtos, catálogo de preços, contas, contatos e pedidos

## Como usar

```bash
sf org login web --alias techlar
sf project deploy start --target-org techlar
sf org assign permset --name TechLar_Vendedor --target-org techlar
sf apex run --file scripts/apex/loadMockData.apex --target-org techlar
sf org open --target-org techlar --path /lightning/app/c__TechLar
```

Abra o app **TechLar** e a aba **Nova Venda**.

## Sprint 2 — Atendimento e Pós-venda (AC2 — 13/10)

Workspace LWC para o atendente localizar o cliente da Sprint 1, ver Account e compras, abrir um Case com Path na mesma tela e concluir o atendimento. Um Flow classifica o motivo e envia para a fila.

Documentação: [docs/sprint-2.md](docs/sprint-2.md)

Board: [mesmo Project da Sprint 1](https://github.com/users/Ingrid-10/projects/1) (view **Sprint 2**)

```bash
sf org assign permset --name TechLar_Atendente --target-org techlar
sf org open --target-org techlar --path /lightning/n/TechLar_Atendimento
```

Abra a aba **Atendimento**.

## Sprint 3 — Gestão de Estoque e Transferência entre Lojas (AC3 — 08/11)

Aba **Estoque** para pesquisar um produto, ver o saldo por loja e transferir unidades. O Apex valida a quantidade, grava a transferência, atualiza os dois saldos e registra a movimentação.

Documentação: [docs/sprint-3.md](docs/sprint-3.md)

Board: [mesmo Project](https://github.com/users/Ingrid-10/projects/1) (view **Sprint 3**)

Dados fictícios: [mock-data/README.md](mock-data/README.md)

Os dados utilizados no projeto são totalmente fictícios e foram criados exclusivamente para fins acadêmicos.

```bash
sf org assign permset --name TechLar_Estoque --target-org techlar
sf apex run --file scripts/apex/loadMockData.apex --target-org techlar
sf apex run --file scripts/apex/loadEstoqueMock.apex --target-org techlar
sf org open --target-org techlar --path /lightning/n/TechLar_Estoque
```

Abra a aba **Estoque**.

## Stack

- LWC (front-end)
- Apex (regras de negócio)
- Account, Contact, Product2, PricebookEntry, Order, OrderItem, Case (CRM)
- Loja__c, Estoque__c, Transferencia_Estoque__c, Movimentacao_Estoque__c
- Flow (encaminhamento do Case)
