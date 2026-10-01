# TechLar 360

Plataforma Salesforce da TechLar para centralizar vendas em loja física, atendimento, visão única do cliente e inteligência artificial. Desenvolvida em 4 sprints para o projeto final de Análise e Desenvolvimento de Sistemas.

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

Documentação: [docs/sprint-2.md](docs/sprint-2.md) · Board: [docs/board-sprint-2.md](docs/board-sprint-2.md)

```bash
sf org assign permset --name TechLar_Atendente --target-org techlar
sf org open --target-org techlar --path /lightning/n/TechLar_Atendimento
```

Abra a aba **Atendimento**.

## Stack

- LWC (front-end)
- Apex (regras de negócio)
- Account, Contact, Product2, PricebookEntry, Order, OrderItem, Case (dados)
- Flow (encaminhamento do Case)
