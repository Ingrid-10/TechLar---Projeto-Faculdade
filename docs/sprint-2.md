# Sprint 2 — Atendimento e Pós-venda Unificado

**Entrega:** AC2 — 13/10/2026  
**App:** TechLar → aba **Atendimento**

## Fluxo

1. Localizar o cliente (Account TechLar da Sprint 1)
2. Ver pedidos e produtos comprados
3. Selecionar pedido + produto, motivo e descrição
4. Apex cria o Case ligado a Account, Order, OrderItem e Product2
5. Flow classifica o motivo, atribui a fila e coloca o Case em análise (`Working`)
6. Atendente conclui com resultado e status `Closed`

## Encaminhamento (Flow)

- Produto com defeito / Solicitação de troca → fila **TechLar Pós-venda**, prioridade High
- Problema na entrega → fila **TechLar Logística**
- Cancelamento e demais → fila **TechLar Atendimento**

Status: `New` → Flow `Working` (Em análise) → atendente `Closed` (Resolvido).

## Evidência

- Front: LWC `techlarServicePage`
- Back: `TechLarServiceController` / `TechLarServiceService`
- Automação: Flow `TechLar_Case_Pos_Venda`
- Dados: Case com cliente, pedido, produto, motivo e status
- Board: [Sprint 2 no Project](https://github.com/users/Ingrid-10/projects/1/views/4)

## Smoke na org

```bash
sf org assign permset --name TechLar_Atendente --target-org techlar
sf apex run --file scripts/apex/smokeService.apex --target-org techlar
```

Cenário: Ana Souza (CPF `700.000.001-59`) + notebook → Case “Produto com defeito”, status `Working`, fila **TechLar Pós-venda**.
