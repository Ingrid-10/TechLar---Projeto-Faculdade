# Sprint 3 — TechLar

## Gestão de Estoque e Transferência entre Lojas

**Entrega:** AC3  
**Data:** 08/11/2026  
**Foco:** Operação / Estoque  
**Status:** Central de Estoque no ar: LWC `techlarInventoryPage`, Apex `TechLarInventoryController` e objetos de loja, saldo, transferência e movimentação.

Os produtos reutilizam o catálogo da Sprint 1. O notebook do cenário é **Notebook TechLar X** (`TL-NB-001`), citado no planejamento como “Notebook TechLar Pro”.

---

# 1. Contexto da Sprint

A TechLar já possui duas funcionalidades implementadas nas etapas anteriores:

## Sprint 1 — Concluída

**Venda Assistida em Loja Física**

Dados gerados:

- clientes;
- produtos;
- pedidos;
- itens dos pedidos;
- histórico de vendas.

## Sprint 2 — Planejada / em desenvolvimento

**Atendimento e Pós-venda Unificado**

Dados previstos:

- Cases;
- histórico de atendimento;
- relacionamento entre cliente, pedido e produto.

## Sprint 3 — Nova proposta

**Gestão de Estoque e Transferência entre Lojas**

Nesta etapa, o foco deixa de ser apenas a relação com o cliente e passa a incluir a **operação interna da TechLar**, especialmente o controle de estoque nas diferentes unidades da empresa.

---

# 2. Problema de negócio

A TechLar vende produtos de tecnologia em lojas físicas.

Como a empresa possui mais de uma unidade, podem ocorrer situações como:

- uma loja possuir pouco estoque de um produto;
- outra loja possuir sobra do mesmo item;
- necessidade de consultar rapidamente a disponibilidade por unidade;
- necessidade de realizar movimentações internas entre lojas.

Sem um controle centralizado, isso gera:

- perda de venda;
- excesso de estoque em uma unidade;
- falta de produto em outra;
- dificuldade operacional.

---

# 3. Objetivo da Sprint

Desenvolver uma funcionalidade completa que permita:

1. consultar a disponibilidade de produtos por loja;
2. visualizar o saldo de estoque em cada unidade;
3. solicitar uma transferência entre lojas;
4. validar a disponibilidade na loja de origem;
5. atualizar os saldos após a movimentação;
6. registrar o histórico da transferência e da movimentação.

A Sprint deverá novamente demonstrar:

**Front-end → Back-end → Banco de Dados**

---

# 4. Funcionalidade principal

## Central de Estoque TechLar

O funcionário interno deverá conseguir pesquisar um produto e visualizar seu estoque distribuído nas lojas da TechLar.

Além disso, deverá ser possível realizar uma transferência entre unidades.

### Exemplo de uso

O funcionário identifica que:

- Loja Morumbi possui apenas **2 unidades** de um notebook;
- Loja Paulista possui **15 unidades** do mesmo produto.

Diante disso, ele solicita uma transferência de **5 unidades** da Loja Paulista para a Loja Morumbi.

O sistema:

- valida a quantidade disponível;
- cria a transferência;
- baixa o estoque da origem;
- aumenta o estoque do destino;
- registra a movimentação.

---

# 5. Atores

## Funcionário interno TechLar

Pode representar:

- vendedor;
- gerente;
- operador de estoque;
- supervisor da loja.

Esse usuário utilizará a funcionalidade de forma administrativa e operacional.

---

# 6. Fluxo principal da funcionalidade

```text
FUNCIONÁRIO
   │
   ▼
Central de Estoque TechLar
   │
   ▼
Pesquisar produto
   │
   ▼
Visualizar estoque por loja
   │
   ▼
Selecionar origem e destino
   │
   ▼
Informar quantidade
   │
   ▼
Solicitar transferência
   │
   ▼
Apex valida disponibilidade
   │
   ▼
Transferência criada
   │
   ▼
Estoque atualizado
   │
   ▼
Movimentação registrada
   │
   ▼
Confirmação exibida
```

---

# 7. Cenário principal

## Transferência de estoque

Produto do catálogo da Sprint 1: **Notebook TechLar X** (`TL-NB-001`). No texto do planejamento, o mesmo item aparece como Notebook TechLar Pro.

Estoque inicial:

- Loja Paulista: 15 unidades
- Loja Morumbi: 2 unidades
- Loja Santana: 6 unidades

Ação:

- origem: Paulista
- destino: Morumbi
- quantidade: 5

Resultado esperado:

- Loja Paulista: 10 unidades
- Loja Morumbi: 7 unidades
- registro da transferência salvo;
- registro da movimentação salvo.

---

# 8. Front-end

## Lightning Web Component — Central de Estoque TechLar

Será criada uma interface LWC para consulta e movimentação de estoque.

### Estrutura visual conceitual

```text
┌──────────────────────────────────────────────────────┐
│           CENTRAL DE ESTOQUE TECHLAR                 │
├──────────────────────────────────────────────────────┤
│ Produto: [ Notebook TechLar X.......... ] [Buscar]  │
├──────────────────────────────────────────────────────┤
│ ESTOQUE POR LOJA                                     │
│                                                      │
│ Paulista                15 unidades                  │
│ Morumbi                  2 unidades                  │
│ Santana                  6 unidades                  │
├──────────────────────────────────────────────────────┤
│ TRANSFERÊNCIA DE ESTOQUE                             │
│                                                      │
│ Origem:   [ Paulista ▼ ]                             │
│ Destino:  [ Morumbi  ▼ ]                             │
│ Quantidade: [ 5 ]                                    │
│                                                      │
│               [ REALIZAR TRANSFERÊNCIA ]             │
└──────────────────────────────────────────────────────┘
```

---

# 9. Possíveis componentes LWC

A tela poderá ser construída como um único componente ou dividida em partes menores.

### Estrutura conceitual

```text
techlarInventoryPage
│
├── productSearch
│
├── stockByStoreList
│
├── stockTransferForm
│
└── transferConfirmation
```

Se necessário, a estrutura poderá ser simplificada.

---

# 10. Back-end

## Apex

O Apex será responsável por toda a lógica principal da Sprint.

### Responsabilidades previstas

- pesquisar produtos;
- recuperar estoque por loja;
- validar origem e destino;
- validar quantidade disponível;
- impedir transferência inválida;
- criar registro de transferência;
- atualizar os estoques envolvidos;
- criar registro de movimentação;
- retornar resposta ao LWC;
- tratar erros.

---

# 11. Banco de dados

O banco continuará sendo o próprio Salesforce.

## Objetos principais previstos

### Produto

Objeto padrão:

- `Product2`

### Loja

Objeto customizado:

- `Loja__c`

### Estoque por loja

Objeto customizado:

- `Estoque__c`

### Transferência

Objeto customizado:

- `Transferencia_Estoque__c`

### Movimentação

Objeto customizado:

- `Movimentacao_Estoque__c`

---

# 12. Estrutura conceitual dos objetos

## Loja__c

Representa cada unidade física da TechLar.

### Campos

- Nome
- Código da loja (`Codigo__c`, external id)
- Cidade
- Status

## Estoque__c

Representa o saldo de um produto em uma determinada loja.

### Campos

- Produto (`Product2`)
- Loja (`Loja__c`)
- Quantidade Disponível
- Chave (`Chave__c`, external id `{ProductCode}-{CodigoLoja}`)

Quantidade reservada e estoque mínimo ficam fora do MVP.

## Transferencia_Estoque__c

Representa a solicitação/execução da transferência.

### Campos

- Produto
- Loja Origem
- Loja Destino
- Quantidade
- Status
- Data da transferência
- Observação

## Movimentacao_Estoque__c

Representa o histórico da movimentação.

### Campos

- Produto
- Loja
- Tipo de movimentação
- Quantidade
- Data
- Transferência relacionada

---

# 13. Relacionamentos

```text
PRODUTO
   │
   ├──────────────┐
   ▼              ▼
ESTOQUE        TRANSFERÊNCIA
   │              │
   ▼              ▼
 LOJA         MOVIMENTAÇÃO
```

De forma mais detalhada:

```text
Product2
   │
   ▼
Estoque__c
   │
   ├── Produto
   └── Loja__c

Transferencia_Estoque__c
   ├── Produto
   ├── Loja_Origem__c
   ├── Loja_Destino__c
   └── Quantidade__c

Movimentacao_Estoque__c
   ├── Produto
   ├── Loja__c
   ├── Tipo__c
   ├── Quantidade__c
   └── Transferencia__c
```

---

# 14. Regra de negócio principal

A transferência só poderá ser executada quando a loja de origem possuir quantidade suficiente.

### Regra

```text
Se quantidade solicitada <= estoque disponível
    então permitir transferência
senão
    impedir operação
```

---

# 15. Regras de negócio iniciais

- o produto deve existir;
- deve haver estoque cadastrado para a loja de origem;
- origem e destino devem ser diferentes;
- a quantidade deve ser maior que zero;
- a loja de origem deve possuir saldo suficiente;
- a transferência deve gerar atualização nos dois estoques;
- a transferência deve gerar pelo menos um registro de histórico;
- o sistema deve confirmar a operação ou informar o erro.

---

# 16. Regras de negócio opcionais

Se houver tempo, poderão ser adicionadas:

- [ ] impedir estoque negativo;
- [ ] controlar estoque mínimo;
- [ ] gerar alerta de estoque baixo;
- [ ] exigir aprovação da transferência;
- [ ] reservar estoque;
- [ ] vincular transferência a usuário responsável;
- [ ] registrar justificativa;
- [ ] atualizar estoque automaticamente após venda da Sprint 1;
- [ ] dashboard de estoque;
- [ ] Flow para notificação interna.

Esses itens não farão parte do MVP obrigatório.

---

# 17. Fluxo técnico da transferência

```text
LWC
 │
 ▼
Apex
 │
 ├── SOQL: busca estoque origem
 ├── SOQL: busca estoque destino
 ├── Validação
 ├── INSERT Transferencia_Estoque__c
 ├── UPDATE Estoque origem
 ├── UPDATE Estoque destino
 ├── INSERT Movimentacao_Estoque__c
 │
 ▼
Salesforce Database
 │
 ▼
Resposta ao LWC
```

---

# 18. Status da transferência

Inicialmente, para simplificar, a transferência poderá ser criada já como concluída.

## Status mínimos

- Concluída

## Status opcionais

- Solicitada
- Em processamento
- Concluída
- Cancelada

Para fins de MVP, usar apenas **Concluída** reduz a complexidade. O picklist do objeto traz somente esse valor.

---

# 19. MVP da Sprint 3

A Sprint será considerada funcional quando permitir:

## Consulta

- [ ] pesquisar um produto;
- [ ] visualizar o estoque por loja;

## Transferência

- [ ] selecionar origem;
- [ ] selecionar destino;
- [ ] informar quantidade;
- [ ] validar saldo disponível;
- [ ] criar transferência;

## Persistência

- [ ] atualizar estoque da loja de origem;
- [ ] atualizar estoque da loja de destino;
- [ ] registrar movimentação;

## Resultado

- [ ] exibir mensagem de sucesso;
- [ ] demonstrar registros no Salesforce.

---

# 20. Funcionalidades opcionais

Após o MVP:

- [ ] estoque mínimo;
- [ ] alerta de baixa;
- [ ] transferência com aprovação;
- [ ] vínculo com usuário;
- [ ] histórico por produto;
- [ ] histórico por loja;
- [ ] atualização automática após venda;
- [ ] integração com Sprint 1 em tempo real;
- [ ] visual mais elaborado;
- [ ] dashboard operacional.

---

# 21. User Story principal

**Como funcionário da TechLar,**  
quero consultar o estoque de um produto em diferentes lojas e transferir quantidades entre unidades,  
**para equilibrar a disponibilidade de produtos e melhorar a operação da empresa.**

---

# 22. Histórias auxiliares

## Consulta de estoque

**Como funcionário,**  
quero pesquisar um produto e ver sua quantidade em cada loja,  
**para entender onde existe disponibilidade.**

## Transferência

**Como funcionário,**  
quero transferir unidades de uma loja para outra,  
**para corrigir desequilíbrios de estoque.**

## Histórico

**Como gestor,**  
quero que as transferências fiquem registradas,  
**para acompanhar as movimentações realizadas.**

---

# 23. Critérios de aceitação

## Cenário — Transferência válida

**Dado que** o produto possui estoque na loja de origem  
**E** a quantidade solicitada é menor ou igual ao saldo disponível  
**Quando** o usuário realizar a transferência  
**Então** o sistema deverá atualizar o estoque da origem  
**E** atualizar o estoque do destino  
**E** criar o registro da transferência  
**E** registrar a movimentação  
**E** apresentar confirmação.

## Cenário — Estoque insuficiente

**Dado que** a quantidade solicitada é maior que o saldo disponível  
**Quando** o usuário tentar transferir  
**Então** o sistema não deverá executar a transferência  
**E** deverá informar que o estoque é insuficiente.

## Cenário — Origem e destino iguais

**Dado que** a loja de origem e a loja de destino são a mesma  
**Quando** o usuário tentar continuar  
**Então** o sistema deverá impedir a operação  
**E** informar que as lojas devem ser diferentes.

---

# 24. Dados mockados

Todos os dados da Sprint são fictícios e foram criados exclusivamente para fins acadêmicos.

Origem no repositório: [mock-data/estoque-inicial.csv](../mock-data/estoque-inicial.csv), carregado por [scripts/apex/loadEstoqueMock.apex](../scripts/apex/loadEstoqueMock.apex). Os produtos já existem na Sprint 1 (`scripts/apex/loadMockData.apex`).

### Lojas

- TechLar Paulista (`PAULISTA`)
- TechLar Morumbi (`MORUMBI`)
- TechLar Santana (`SANTANA`)

Todas em São Paulo, status Ativa.

### Produtos

| Planejamento | Catálogo Sprint 1 | Código |
| --- | --- | --- |
| Notebook TechLar Pro | Notebook TechLar X | `TL-NB-001` |
| Mouse Gamer | Mouse Gamer TechLar | `TL-MS-001` |
| Monitor 27” | Monitor 27 TechLar | `TL-MN-001` |
| Teclado Mecânico | Teclado Mecânico TechLar | `TL-KB-001` |

### Estoque inicial

Notebook TechLar X (`TL-NB-001`):

- Paulista: 15
- Morumbi: 2
- Santana: 6

Mouse Gamer TechLar (`TL-MS-001`): Paulista 20, Morumbi 8, Santana 12.

Monitor 27 TechLar (`TL-MN-001`): Paulista 4, Morumbi 10, Santana 3.

Teclado Mecânico TechLar (`TL-KB-001`): Paulista 9, Morumbi 9, Santana 7.

A origem dos dados deverá ser mencionada no vídeo e no repositório.

---

# 25. Evidência de Front + Back + Dados

## Front-end

**LWC Central de Estoque TechLar**

## Back-end

**Apex de consulta e transferência**

## Banco de dados

**Salesforce Objects e registros de estoque, transferência e movimentação**

## Fluxo completo

```text
FUNCIONÁRIO
   │
   ▼
LWC
   │
   ▼
APEX
   │
   ▼
SALESFORCE DATA
   │
   ▼
ESTOQUE ATUALIZADO
```

---

# 26. Integração com as Sprints anteriores

A Sprint 3 não será isolada.

## Relação com Sprint 1

Os produtos já existentes poderão ser reutilizados.

```text
SPRINT 1
Vendas / Product2
      │
      ▼
SPRINT 3
Estoque por loja
```

## Relação com Sprint 2

De forma futura, a operação de estoque poderá apoiar o atendimento e troca de produtos.

```text
SPRINT 2
Atendimento
      │
      ▼
SPRINT 3
Disponibilidade para troca
```

---

# 27. O que não será prioridade nesta Sprint

Inicialmente ficam fora do escopo obrigatório:

- Data 360;
- Agentforce;
- site;
- Experience Cloud;
- aprovação complexa;
- integração com fornecedor;
- logística externa;
- inventário por número de série;
- catálogo avançado;
- cálculo financeiro completo da operação.

---

# 28. Preparação para a Sprint 4

A Sprint 3 ajudará a enriquecer o contexto do Agentforce.

Após as três primeiras etapas, o sistema terá:

```text
SPRINT 1
Vendas
│
├── Cliente
├── Pedido
└── Produto

SPRINT 2
Atendimento
│
└── Case

SPRINT 3
Estoque
│
├── Loja
├── Estoque
├── Transferência
└── Movimentação
```

Isso permitirá que o Agentforce, na Sprint 4, consulte informações mais ricas, como:

- pedidos do cliente;
- atendimentos abertos;
- disponibilidade de produtos;
- estoque por loja.

---

# 29. Estrutura sugerida no GitHub

```text
force-app/main/default/
├── lwc/techlarInventoryPage/
├── classes/TechLarInventoryController.cls
└── objects/
    ├── Loja__c/
    ├── Estoque__c/
    ├── Transferencia_Estoque__c/
    └── Movimentacao_Estoque__c/

mock-data/estoque-inicial.csv
scripts/apex/loadEstoqueMock.apex
```

Nesta etapa, objetos, CSV e script de carga já estão no repositório. LWC e controller entram depois.

---

# 30. Possíveis commits

```text
Add store object for TechLar locations

Add inventory object structure

Add stock transfer custom object

Create inventory controller Apex class

Add stock by store query

Implement stock transfer validation

Add inventory transfer LWC

Add inventory movement tracking

Add mock inventory dataset

Update Sprint 3 documentation
```

---

# 31. Organização do board

Sugestão de colunas ou épicos:

## Modelagem de Dados

- criar Loja__c;
- criar Estoque__c;
- criar Transferencia_Estoque__c;
- criar Movimentacao_Estoque__c.

## Front-end

- componente de busca de produto;
- lista de estoque por loja;
- formulário de transferência;
- confirmação.

## Back-end

- consulta de estoque;
- validação de transferência;
- atualização de registros;
- criação de movimentação.

## Dados

- preparar dados mockados;
- cadastrar lojas;
- cadastrar produtos;
- cadastrar estoques iniciais.

## Testes

- cenário válido;
- estoque insuficiente;
- lojas iguais;
- quantidade inválida.

## Entrega

- revisar GitHub;
- gravar vídeo;
- montar PDF do Classroom.

---

# 32. Ordem recomendada de implementação

## Etapa 1

Definir e criar o modelo de dados.

## Etapa 2

Cadastrar lojas e estoques fictícios.

## Etapa 3

Implementar Apex de consulta.

## Etapa 4

Implementar Apex de transferência.

## Etapa 5

Criar a interface LWC.

## Etapa 6

Conectar LWC ao Apex.

## Etapa 7

Testar cenários de sucesso e erro.

## Etapa 8

Preparar demonstração da entrega.

As etapas 1 e 2 correspondem ao que já está no repositório.

---

# 33. Demonstração da AC3

O vídeo deverá continuar com aproximadamente **3 a 4 minutos**.

## Ordem sugerida

### 1. Board

Mostrar:

- Sprint 3;
- tarefas;
- itens concluídos.

### 2. GitHub

Mostrar:

- repositório;
- LWC;
- Apex;
- objetos;
- commits.

### 3. Funcionalidade

Abrir a tela de estoque.

Pesquisar um produto.

Mostrar o saldo por loja.

### 4. Transferência

Selecionar:

- loja origem;
- loja destino;
- quantidade.

Executar a transferência.

### 5. Banco de dados

Mostrar:

- registro da transferência;
- estoque atualizado na origem;
- estoque atualizado no destino;
- registro de movimentação.

### 6. Encerramento

Destacar que a Sprint entrega:

- front-end;
- back-end;
- banco de dados;
- regra de negócio;
- funcionalidade operacional completa.

---

# 34. Definição de pronto

A Sprint estará pronta quando for possível responder **SIM** para estas perguntas:

- [ ] Existe uma tela LWC funcional?
- [ ] É possível pesquisar produto?
- [ ] É possível visualizar estoque por loja?
- [ ] É possível solicitar transferência?
- [ ] O sistema valida quantidade?
- [ ] O sistema impede erros básicos?
- [ ] O estoque da origem é atualizado?
- [ ] O estoque do destino é atualizado?
- [ ] O registro da transferência é salvo?
- [ ] A movimentação é registrada?
- [ ] Os dados são mockados e documentados?
- [ ] O código está no GitHub?
- [ ] O board está atualizado?
- [ ] A funcionalidade pode ser demonstrada em até 4 minutos?

---

# 35. Resultado esperado da Sprint

Ao final da Sprint 3, a TechLar terá evoluído de uma solução focada apenas em vendas e atendimento para uma solução que também apoia a operação da empresa.

A progressão do projeto ficará assim:

```text
SPRINT 1
Como vender?

       ↓

SPRINT 2
Como atender o cliente?

       ↓

SPRINT 3
Como controlar e redistribuir os produtos entre lojas?
```

A resposta da Sprint 3 será representada pela:

# Central de Estoque TechLar

Essa funcionalidade criará uma base operacional útil para enriquecer a Sprint 4 com Agentforce.
