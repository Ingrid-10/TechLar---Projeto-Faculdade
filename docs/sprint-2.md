# Sprint 2 — Atendimento e Pós-venda Unificado

**Entrega:** AC2 — 13/10/2026  
**App:** TechLar → aba **Atendimento** (`/lightning/n/TechLar_Atendimento`)

A Sprint 2 **lê** Account, Order e OrderItem da Sprint 1 e grava o atendimento no **Case**, sem alterar a venda assistida.

## Workspace na LWC

Tudo fica na aba Atendimento, sem precisar abrir o registro padrão do Case para entender o atendimento:

1. Pesquisar e **selecionar** o cliente (botão Selecionar / Selecionado + check)
2. Ver a **Account** (nome, CPF, telefone, endereço)
3. Ver o **histórico de compras** (Order + itens)
4. Abrir o Case com motivo e descrição, ligado a Account, Order, OrderItem e Product2
5. Ver o **Path** Novo → Em análise → Resolvido na mesma tela
6. Ver fila, produto, pedido, descrição e concluir com resultado
7. Consultar o **histórico de atendimentos** do mesmo cliente

## Encaminhamento (Flow `TechLar_Case_Pos_Venda`)

- Produto com defeito / Solicitação de troca → fila **TechLar Pós-venda**, prioridade High
- Problema na entrega → fila **TechLar Logística**
- Cancelamento e demais → fila **TechLar Atendimento**

Status: `New` → Flow `Working` (Em análise) → atendente `Closed` (Resolvido).

## Evidência

- Front: LWC `techlarServicePage` + `techlarServiceOrders`, `techlarCaseForm`, `techlarCaseConfirmation`
- Back: `TechLarServiceController` / `TechLarServiceService`
- Automação: Flow `TechLar_Case_Pos_Venda`
- Permset: `TechLar_Atendente`
- Board: [Sprint 2](https://github.com/users/Ingrid-10/projects/1/views/4) · [Board](https://github.com/users/Ingrid-10/projects/1)

## Smoke na org

```bash
sf org assign permset --name TechLar_Atendente --target-org techlar
sf apex run --file scripts/apex/smokeService.apex --target-org techlar
```

Cenário: Ana Souza (CPF `700.000.001-59`) + notebook → Case “Produto com defeito”, status `Working`, fila **TechLar Pós-venda**.
