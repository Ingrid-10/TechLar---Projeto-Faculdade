# TechLar 360

Plataforma Salesforce da TechLar para centralizar vendas em loja física, atendimento, visão única do cliente e inteligência artificial. Desenvolvida em 4 sprints para o projeto final de Análise e Desenvolvimento de Sistemas.

## Sprint 1 — Venda Assistida em Loja Física (AC1 — 14/09)

Interface LWC para o vendedor localizar ou cadastrar o cliente, montar o carrinho, escolher retirada ou entrega e gravar `Order` + `OrderItem` no Salesforce.

Documentação da sprint: [docs/sprint-1.md](docs/sprint-1.md)

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
sf org open --target-org techlar --path /lightning/app/c__TechLar360
```

Abra o app **TechLar 360** e a aba **Nova Venda**.

## Stack

- LWC (front-end)
- Apex (regras de negócio)
- Account, Contact, Product2, PricebookEntry, Order, OrderItem (dados)
