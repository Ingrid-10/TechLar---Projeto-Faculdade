# Sprint 4 — TechLar

## Employee Agent para Reposição Inteligente de Estoque

**Entrega:** Prova / Entrega Final  
**Data:** 22/11/2026  
**Foco:** Agentforce / Automação inteligente de processos  
**Status:** Planejamento detalhado. Ainda não há desenvolvimento na org.

O produto do cenário continua **Notebook TechLar X** (`TL-NB-001`). No texto de exemplo ele também aparece como Notebook TechLar Pro.

---

# 1. Contexto da Sprint

As três primeiras sprints construíram a base operacional da TechLar.

## Sprint 1 — Concluída

**Venda assistida em loja física**

- clientes;
- produtos;
- pedidos e itens;
- histórico comercial.

O pedido ainda não guarda a loja. O canal é apenas Loja Física ou Online.

## Sprint 2 — Concluída

**Atendimento e pós-venda**

- Cases;
- histórico de atendimento;
- ligação com cliente, pedido e produto;
- Flow de classificação.

Os Cases não entram na regra principal desta sprint.

## Sprint 3 — Concluída

**Gestão de estoque e transferência entre lojas**

- lojas Paulista, Morumbi e Santana, cada uma com o próprio aplicativo;
- saldo por produto e por loja em `Estoque__c`;
- consulta do estoque da loja e pedido de transferência no estoque geral;
- transferência concluída, com saída na origem e entrada no destino;
- a venda não baixa o estoque.

A transferência já existe em `TechLarInventoryService.transfer`. A Sprint 4 reutiliza esse método. Não cria outra regra de baixa e entrada.

---

# 2. Objetivo da Sprint 4

Criar um **Employee Agent** interno, no Agentforce, para os times de processos, compras, operações e gestão de estoque.

O funcionário pede, em linguagem natural, a análise dos produtos mais vendidos e a reposição do que estiver abaixo de 5 unidades. O agente consulta vendas e estoque já gravados no Salesforce e executa as transferências válidas a partir do Estoque Central.

O agente só conversa. A reposição depende de quatro peças que ainda não existem:

1. a loja **TechLar Estoque Central**;
2. o pedido ligado à loja do aplicativo, sem campo de seleção na tela;
3. vendas fictícias dos últimos 30 dias, por loja, para o ranking existir antes de novas vendas;
4. o serviço de reposição, que chama a transferência da Sprint 3.

---

# 3. Funcionalidade principal

## Reposição inteligente de estoque

O funcionário solicita ao Employee Agent:

> Verifique os produtos mais vendidos das lojas e reponha os que estiverem com estoque abaixo de 5 unidades.

O agente deve:

1. identificar os produtos mais vendidos de cada loja;
2. consultar o estoque atual desses produtos em cada loja;
3. identificar lojas com menos de 5 unidades;
4. consultar a disponibilidade no Estoque Central;
5. calcular a quantidade necessária para chegar a 10;
6. realizar a transferência quando o central cobrir a quantidade inteira;
7. atualizar os saldos;
8. registrar a transferência e as movimentações;
9. apresentar o resumo, inclusive as linhas que não foram transferidas.

---

# 4. Persona do agente

## TechLar Operations Employee Agent

O agente fica no aplicativo corporativo **TechLar Operações**, separado dos aplicativos de loja. Não fica dentro de Paulista, Morumbi ou Santana.

Usuários: equipe de processos, compras, responsáveis por estoque, supervisores e gestão operacional.

O objetivo é analisar e executar a reposição por linguagem natural, dentro do Salesforce.

```text
                  TECHLAR
                     |
        +------------+------------+
        |                         |
        v                         v
APLICATIVOS DAS LOJAS      TECHLAR OPERATIONS
 Paulista, Morumbi,             |
 Santana                        v
        |                  Employee Agent
        v                  Processos / Compras
 Operação local              / Operações
```

---

# 5. Estoque Central

Nova loja na mesma estrutura da Sprint 3. Não ganha aplicativo.

| Nome | Código |
| --- | --- |
| TechLar Estoque Central | `CENTRAL` |
| TechLar Paulista | `PAULISTA` |
| TechLar Morumbi | `MORUMBI` |
| TechLar Santana | `SANTANA` |

O saldo do central é um registro de `Estoque__c`, como o das lojas. No cenário do notebook, o central começa com 100 unidades.

O Estoque geral das lojas continua listando só Paulista, Morumbi e Santana. O central não aparece como origem da transferência manual. Quem transfere a partir dele é o agente.

---

# 6. A loja da venda

A tela de Vendas não ganha seletor de loja. Quem declara a unidade é o aplicativo aberto.

Na finalização da venda, o Apex lê o aplicativo da sessão (`UserAppInfo` e o nome do app) e grava `Order.Loja__c`:

| Aplicativo | Loja gravada |
| --- | --- |
| TechLar Paulista | Paulista |
| TechLar Morumbi | Morumbi |
| TechLar Santana | Santana |
| TechLar | nenhuma |
| TechLar Operações | nenhuma |

Venda sem loja não entra no ranking por unidade. O ranking da Sprint 4 usa `Order` e `OrderItem` reais dos últimos 30 dias, agrupados pela loja do pedido. Não há lista fixa de produtos no código.

Para a demonstração existir antes de novas vendas, a carga fictícia cria pedidos recentes já ligados a cada loja.

---

# 7. Regra de reposição

## Estoque mínimo

**5 unidades.** Se a quantidade da loja for menor que 5, o produto entra na reposição. Com 5 ou mais, não há transferência.

## Estoque-alvo

**10 unidades.** A quantidade pedida é `10 - estoque atual`.

Exemplo: Morumbi com 2 unidades precisa de 8. O agente transfere 8 do Estoque Central para o Morumbi.

## O que entra na análise

**Top 3 produtos mais vendidos de cada loja nos últimos 30 dias.** O agente só olha o estoque desses produtos.

A quantidade vendida vem de `OrderItem`, do pedido daquela loja, com data efetiva dentro do período.

## Estoque central insuficiente

Não há transferência parcial. Se a loja precisa de 8 e o central tem 3, essa transferência não acontece e o resumo explica a falta. As outras lojas continuam sendo avaliadas.

A ordem de processamento é estável, pelo código da loja. Se o central não alcançar todas, as primeiras na ordem recebem a quantidade inteira e as seguintes ficam no resumo como exceção.

---

# 8. Fluxo principal

```text
FUNCIONÁRIO
     |
     v
Employee Agent no TechLar Operações
     |
     | "Analise os produtos mais vendidos
     |  e reponha os estoques baixos."
     v
Agent Action
     |
     v
TechLarReplenishmentService
     |
     v
Vendas dos últimos 30 dias, por loja do pedido
     |
     v
Top 3 de cada loja
     |
     v
Estoque__c de cada loja
     |
     v
Quantidade < 5?
     |
   +-+---------------+
   |                 |
  NÃO               SIM
   |                 |
Ignorar              v
               10 - estoque atual
                     |
                     v
              Estoque Central
                     |
              cobre a quantidade inteira?
                /            \
              NÃO            SIM
               |              |
               v              v
          Informar       TechLarInventoryService.transfer
          no resumo            |
                               v
                        Saldos, transferência
                        e movimentações
                               |
                               v
                        Resumo ao funcionário
```

Os nomes de classe e método podem ser ajustados na implementação. A transferência em si não é reescrita.

---

# 9. Cenário de demonstração

Produto: Notebook TechLar X (`TL-NB-001`), entre os três mais vendidos das lojas com saldo baixo.

| Loja | Estoque inicial |
| --- | ---: |
| Paulista | 15 |
| Morumbi | 2 |
| Santana | 4 |
| Estoque Central | 100 |

Resultado:

- Morumbi: 2 + 8 = 10
- Santana: 4 + 6 = 10
- Paulista: 15, sem transferência
- Estoque Central: 100 - 14 = 86

Cada transferência concluída gera saída no central e entrada na loja.

---

# 10. Resposta esperada do agente

O texto é conceitual. O agente deve deixar claro o que mudou e o que foi recusado.

```text
Análise concluída.

Morumbi
Notebook TechLar X
2 para 10 unidades
Transferidas: 8

Santana
Notebook TechLar X
4 para 10 unidades
Transferidas: 6

Paulista
Notebook TechLar X
15 unidades
Nenhuma transferência

Total de transferências realizadas: 2.
```

Se o central não cobrir uma loja, essa linha aparece como não realizada, com o motivo de estoque central insuficiente.

---

# 11. Back-end

- Agentforce e Agent Action;
- Apex de ranking, cálculo e validação;
- `TechLarInventoryService.transfer` para a execução;
- Flow só se a ação do agente precisar de um invólucro. A regra de saldo fica no Apex.

Estrutura conceitual:

```text
Employee Agent
      |
      v
Agent Action
      |
      v
Serviço de reposição
      |
      +-- produtos mais vendidos por loja
      +-- saldo da loja
      +-- quantidade para chegar a 10
      +-- saldo do Estoque Central
      +-- transfer() da Sprint 3
```

---

# 12. Banco de dados

O banco continua sendo o Salesforce.

Sprint 1, com o campo novo no pedido:

- `Product2`
- `Order`, inclusive `Loja__c`
- `OrderItem`

Sprint 3:

- `Loja__c`, agora também com o Estoque Central
- `Estoque__c`
- `Transferencia_Estoque__c`
- `Movimentacao_Estoque__c`

```text
ORDER / ORDER ITEM
      |
      v
Top 3 por loja
      |
      v
Estoque__c da loja
      |
      v
Estoque__c do central
      |
      v
Transferencia_Estoque__c
      |
      v
Movimentacao_Estoque__c
```

---

# 13. Regras obrigatórias

- analisar só o Top 3 de cada loja nos últimos 30 dias;
- a loja do ranking é a loja gravada no pedido pelo aplicativo;
- estoque menor que 5 entra na reposição;
- estoque igual ou maior que 5 não gera transferência;
- o alvo é 10 unidades;
- a origem é sempre o Estoque Central;
- origem e destino são diferentes;
- não há transferência parcial;
- o saldo não fica negativo;
- toda reposição executada gera transferência e movimentação de saída e de entrada;
- o agente informa o resultado, inclusive as exceções;
- a venda continua sem baixar o estoque;
- Cases não participam da regra.

## Fora do MVP

- transferência parcial;
- mais de três produtos;
- período, mínimo ou alvo configuráveis;
- aprovação;
- prioridade entre lojas além da ordem estável;
- alerta ou compra de fornecedor;
- consulta de Cases;
- relatórios extras;
- o agente consultar estoque ou vendas fora da ação de reposição.

---

# 14. MVP

A sprint está funcional quando o Employee Agent consegue:

- receber o pedido em linguagem natural no TechLar Operações;
- identificar o Top 3 por loja nos últimos 30 dias;
- consultar o saldo e achar quantidade menor que 5;
- calcular o quanto falta para 10;
- verificar o Estoque Central;
- executar só as transferências inteiras;
- atualizar origem e destino;
- gravar transferência e movimentação;
- responder com o resumo.

---

# 15. User story principal

**Como funcionário do time de processos ou compras da TechLar,**  
quero pedir ao Employee Agent que analise os produtos mais vendidos e o estoque das lojas,  
**para que o que estiver abaixo de 5 unidades seja reposto pelo Estoque Central até 10.**

Histórias auxiliares:

- identificar os mais vendidos de cada loja, para priorizar a demanda real;
- consultar o saldo desses produtos sem pesquisa manual;
- transferir do central quando a quantidade inteira existir;
- receber o resumo do que mudou e do que foi recusado.

---

# 16. Critérios de aceitação

## Estoque abaixo do mínimo

Dado que o produto está no Top 3 da loja, a loja tem menos de 5 unidades e o central cobre a quantidade inteira, quando o funcionário pede a reposição, o sistema calcula `10 - estoque atual`, transfere do central, atualiza os dois saldos e grava transferência e movimentações.

## Estoque suficiente

Dado que o produto está no Top 3 e a loja tem 5 ou mais unidades, nenhuma transferência é feita para esse produto nessa loja.

## Estoque central insuficiente

Dado que a loja precisa de reposição e o central não tem a quantidade inteira, a transferência dessa loja não ocorre e o resumo informa a falta.

## Várias lojas

Dado que o mesmo produto está baixo em mais de uma loja, cada loja é avaliada em separado. Só as transferências válidas são executadas.

## Venda no aplicativo da loja

Dado que o funcionário finaliza uma venda no aplicativo TechLar Paulista, o pedido fica ligado à Paulista sem um campo de loja na tela. O mesmo vale para Morumbi e Santana.

---

# 17. Evidência de front, back e dados

- **Front-end:** Employee Agent no aplicativo TechLar Operações.
- **Back-end:** Agent Action e Apex. A execução da transferência é a da Sprint 3.
- **Banco:** `Order`, `OrderItem`, `Product2`, `Loja__c`, `Estoque__c`, `Transferencia_Estoque__c`, `Movimentacao_Estoque__c`.
- **Regra:** demanda dos últimos 30 dias, limite 5, alvo 10, origem no Estoque Central, sem parcial.

---

# 18. Dados fictícios

Continuar com dados fictícios, só para o trabalho acadêmico. A carga precisa permitir demonstrar:

- vendas nos últimos 30 dias em cada loja;
- um ranking em que o notebook entra no Top 3;
- Paulista com estoque suficiente;
- Morumbi e Santana abaixo de 5;
- central com 100 unidades no cenário principal;
- um caso separado em que o central não cobre a quantidade inteira.

---

# 19. Demonstração

Vídeo de cerca de 3 a 4 minutos:

1. Board da Sprint 4, com as tarefas.
2. GitHub: Apex, testes e metadados do agente.
3. Situação inicial: central 100, Paulista 15, Morumbi 2, Santana 4, e o notebook entre os mais vendidos.
4. No TechLar Operações, pedir a verificação dos mais vendidos e a reposição abaixo de 5.
5. Mostrar o resumo: Morumbi 2 para 10, Santana 4 para 10, Paulista sem alteração.
6. Abrir os registros: saldos, transferências e movimentações.

---

# 20. Definição de pronto

- Employee Agent acessível no aplicativo geral de operações;
- solicitação em linguagem natural;
- Top 3 por loja no período de 30 dias;
- saldo abaixo de 5 identificado;
- cálculo até 10;
- central consultado e validado;
- transferências válidas executadas pela Sprint 3;
- origem, destino, transferência e movimentação gravados;
- resumo com sucessos e exceções;
- código versionado e testes dos quatro cenários;
- board atualizado;
- demonstração em vídeo.

---

# 21. Resultado do projeto

```text
SPRINT 1    Vender        Sales
SPRINT 2    Atender       Service
SPRINT 3    Controlar     Estoque por loja
SPRINT 4    Analisar e agir   Agentforce
```

O Employee Agent não responde só perguntas. Ele lê a demanda já registrada nas vendas e executa a reposição no estoque que a Sprint 3 passou a controlar.

# TechLar Operations Employee Agent
