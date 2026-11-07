# Roteiro do vídeo — AC4 Sprint 4

**Duração:** 3 min 30 s a 3 min 55 s (máximo 4 min)  
**Destino:** YouTube (não listado ou público, conforme a entrega)  
**Ordem:** board → GitHub → Agentforce → solução na org  
**Não fazer:** abrir código-fonte ou explicar linha por linha. O professor consulta o repositório.

A entrega precisa mostrar o Employee Agent e o fluxo completo: linguagem natural, análise dos mais vendidos, estoque por loja, regra de reposição, Estoque Central, transferências, saldos e registros no Salesforce.

---

## Antes de gravar

Deixe estas abas abertas, nesta ordem:

1. **Board:** [Sprint 4](https://github.com/users/Ingrid-10/projects/1/views/10) — cards em **Done**.
2. **Código:** [repositório](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade) — `force-app/main/default` à vista.
3. **Agentforce:** Employee Agent **TechLar Operations Employee Agent**.
4. **Org:** aplicativo **TechLar Operações** → aba **Operações**, antes de qualquer mensagem.
5. **Dados:** uma aba pronta para abrir transferências e movimentações pelo número `TRF`.

Confirme os dados iniciais antes da gravação:

| Loja | Notebook TechLar X |
| --- | ---: |
| Estoque Central | 100 |
| TechLar Paulista | 15 |
| TechLar Morumbi | 2 |
| TechLar Santana | 4 |

Resultado esperado após a reposição:

| Loja | Resultado |
| --- | ---: |
| Estoque Central | 86 |
| TechLar Paulista | 15 |
| TechLar Morumbi | 10 |
| TechLar Santana | 10 |

Morumbi recebe 8 e Santana recebe 6. A Paulista não muda porque já possui 5 ou mais unidades.

Feche notificações e painéis laterais. Use zoom entre 110% e 125%. Não execute a reposição antes de começar a gravação.

---

## Título e descrição do YouTube

**Título:** TechLar — AC4 Sprint 4 · Reposição inteligente com Agentforce

**Descrição:**

```text
AC4 — Sprint 4 do projeto TechLar (Análise e Desenvolvimento de Sistemas).
Employee Agent para analisar os produtos mais vendidos e repor estoques baixos a partir do Estoque Central, com Apex, LWC e dados persistidos no Salesforce.

Repositório: https://github.com/Ingrid-10/TechLar---Projeto-Faculdade
Board: https://github.com/users/Ingrid-10/projects/1/views/10
```

---

## Roteiro falado

O texto em *itálico* é fala. O **negrito** é ação na tela.

### 1. Abertura — 0:00 a 0:15

**Tela:** board da Sprint 4.

*Olá. Eu sou Ingrid Costa. Esta é a entrega final do TechLar, a AC4, Sprint 4. Nesta etapa, um Employee Agent analisa as vendas e o estoque das lojas e executa a reposição inteligente a partir do Estoque Central.*

### 2. Board — 0:15 a 0:35

**Percorra os cards da Sprint 4 em Done, sem abrir as issues.**

*O board está concluído. As demandas cobrem o Estoque Central, a identificação da loja da venda, os dados dos últimos 30 dias, o serviço de reposição, o aplicativo de Operações e o Employee Agent.*

### 3. GitHub — 0:35 a 1:00

**Abra `force-app/main/default`. Mostre rapidamente as pastas `aiAuthoringBundles`, `lwc`, `classes` e `objects`, sem abrir código.**

*O projeto está versionado no GitHub. O front-end está nos Lightning Web Components. O back-end em Apex calcula o ranking e a reposição. O Employee Agent e suas actions estão nos metadados do Agentforce. Os objetos guardam pedidos, lojas, estoques, transferências e movimentações.*

**Mostre `scripts/apex` e `mock-data` por dois segundos.**

*Os dados são fictícios e incluem vendas recentes por loja e os saldos usados nesta demonstração.*

### 4. Employee Agent — 1:00 a 1:20

**Na configuração do Agentforce, mostre o agente `TechLar Operations Employee Agent` e as actions de análise e reposição. Não publique nem altere configurações durante a gravação.**

*Este é o Employee Agent de Operações. Ele possui uma action para analisar sem alterar o estoque e outra para executar a reposição. A conversa usa um pedido por vez: primeiro verificar e depois repor.*

### 5. Análise sem transferência — 1:20 a 2:05

**Volte ao aplicativo `TechLar Operações`, aba `Operações`. Digite ou use a sugestão: `Verifique os produtos mais vendidos e o estoque das lojas.`**

*No primeiro pedido, eu solicito somente a análise. O sistema considera os três produtos mais vendidos de cada loja nos últimos 30 dias e mostra a situação sem fazer transferência.*

**Espere a resposta e a abertura dos cards. Aponte o Estoque Central e os cards Paulista, Morumbi e Santana.**

*O Notebook TechLar X possui 100 unidades no central. A Paulista tem 15 e não precisa de reposição. O Morumbi tem 2 e precisa de 8. Santana tem 4 e precisa de 6. Como a análise é somente leitura, os saldos ainda não mudaram.*

### 6. Reposição inteligente — 2:05 a 2:45

**Digite ou use a sugestão: `Reponha as lojas que precisam.`**

*Agora eu autorizo a execução. A regra repõe apenas estoque abaixo de 5, até o alvo de 10. A origem é sempre o Estoque Central e não existe transferência parcial.*

**Espere a resposta e mostre os cards atualizados.**

*Foram realizadas duas transferências: 8 unidades para o Morumbi e 6 para Santana. A Paulista permaneceu com 15. O central passou de 100 para 86, e as duas lojas chegaram a 10 unidades.*

### 7. Caminho e banco — 2:45 a 3:30

**Em uma transferência, clique em `Ver caminho`.**

*Cada reposição entrega um caminho visual. Esta transferência saiu do Estoque Central, passou por Separado e Em trânsito e aparece como Recebido porque a saída e a entrada já foram registradas.*

**Anote o número `TRF`. Use a busca global para abrir a transferência. Mostre origem, destino, quantidade e status. Depois mostre as movimentações relacionadas de Saída e Entrada.**

*No banco do Salesforce, a transferência guarda o produto, a origem central, a loja de destino, a quantidade e o status. As movimentações registram a saída no central e a entrada na loja. Assim, front-end, back-end e persistência participam do mesmo fluxo.*

### 8. Encerramento — 3:30 a 3:50

**Volte à tela de Operações e deixe os cards com os saldos finais visíveis.**

*A Sprint 4 conclui o projeto com uma operação inteligente: o Employee Agent interpreta o pedido, usa vendas reais do período, aplica as regras de estoque e executa ações rastreáveis no Salesforce. O board e o código estão no GitHub. Obrigada.*

---

## Se faltar ou sobrar tempo

| Situação | Ajuste |
| --- | --- |
| Passou de 3:20 antes do banco | Mostre somente o caminho e uma transferência com as duas movimentações. |
| Terminou antes de 3:30 | Leia os saldos finais: central 86, Paulista 15, Morumbi 10 e Santana 10. |
| O caminho não abrir | Anote o número TRF da resposta e abra o registro pela busca global. |
| A reposição não alterar os saldos | Não execute novamente. Mostre a mensagem de erro e verifique se os saldos iniciais já estavam abaixo do cenário esperado. |

Não regrave por uma frase diferente. Precisa aparecer: board, GitHub, Employee Agent, análise sem alteração, segundo pedido de reposição, saldos antes e depois, caminho e registros.

---

## Checklist de evidência

- [ ] Board da Sprint 4 em Done
- [ ] GitHub: `aiAuthoringBundles`, LWC, Apex, objetos e dados fictícios
- [ ] Employee Agent e as duas actions
- [ ] Aplicativo TechLar Operações
- [ ] Primeiro pedido apenas analisa, sem transferir
- [ ] Central 100, Paulista 15, Morumbi 2 e Santana 4
- [ ] Segundo pedido executa a reposição
- [ ] Morumbi recebe 8 e termina com 10
- [ ] Santana recebe 6 e termina com 10
- [ ] Paulista permanece com 15
- [ ] Estoque Central termina com 86
- [ ] Caminho Separado → Em trânsito → Recebido
- [ ] Transferência gravada com origem, destino, quantidade e status
- [ ] Movimentações de Saída e Entrada
