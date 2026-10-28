# Roteiro do vídeo — AC3 Sprint 3

**Duração:** 3 min 20 s a 3 min 50 s (máximo 4 min)  
**Destino:** YouTube (não listado ou público, conforme a entrega)  
**Ordem obrigatória:** board → GitHub → solução na org  
**Não fazer:** abrir classe Apex, LWC ou explicar linha de código. O professor vê isso no repositório.

A matéria pede, na tela: consulta de estoque por loja, transferência entre unidades, validação, saldos atualizados e o histórico gravado (transferência e movimentação). Front, back e banco no mesmo fluxo.

---

## Antes de gravar

Abas já logadas, nesta ordem:

1. **Board:** [Sprint 3](https://github.com/users/Ingrid-10/projects/1/views/9) — coluna **Done** visível.
2. **Código:** [repositório](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade) — `force-app/main/default` com `lwc/`, `classes/` e `objects/` à vista, sem abrir arquivo.
3. **Dados:** [mock-data/README.md](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/blob/main/mock-data/README.md).
4. **Org:** app **TechLar Morumbi** → aba **Estoque geral**. Tela limpa, sem transferência pela metade.

| Campo | Valor |
| --- | --- |
| App | TechLar Morumbi |
| Aba | Estoque geral |
| Produto | Notebook TechLar X |
| Origem | TechLar Paulista (15) |
| Destino | TechLar Morumbi (2) — a loja do aplicativo aberto |
| Quantidade | 5 |
| Ao pedir | Paulista 10. Morumbi continua 2. Caminho em Pedido feito |
| Em transporte | Morumbi continua 2 |
| Ao concluir | Morumbi 7. Status da transferência: Concluída |

O pedido sai da outra loja na hora. A entrada no Morumbi só acontece no fim do caminho. Por isso a gravação começa no Morumbi.

Feche notificações. Zoom em 110–125%. Se errar um clique, continue.

---

## Título e descrição do YouTube

**Título:** TechLar — AC3 Sprint 3 · Estoque e transferência entre lojas

**Descrição:**

```
AC3 — Sprint 3 do projeto TechLar (Análise e Desenvolvimento de Sistemas).
Gestão de estoque: consulta do saldo por loja, transferência entre unidades, atualização dos saldos e histórico da movimentação no Salesforce.

Repositório: https://github.com/Ingrid-10/TechLar---Projeto-Faculdade
Board: https://github.com/users/Ingrid-10/projects/1/views/9
```

---

## Roteiro falado

O texto em *itálico* é fala. O **negrito** é ação na tela.

### 1. Abertura — 0:00 a 0:15

**Tela:** board da Sprint 3.

*Olá. Eu sou Ingrid Costa. Este é o vídeo da AC3, Sprint 3 do TechLar: gestão de estoque e transferência entre lojas. Em cerca de quatro minutos eu mostro o board, o repositório e, na org, a consulta, a transferência e o registro no banco.*

### 2. Board — 0:15 a 0:40

**Percorra os cards em Done, sem abrir issue.**

*O board desta sprint está em Done. O épico é consultar o estoque de um produto nas lojas e transferir quantidade entre unidades. As histórias cobrem a modelagem, os dados fictícios, a consulta, a transferência com validação e a confirmação na tela.*

### 3. GitHub — 0:40 a 1:05

**Role o README só o bastante para a frase da Sprint 3. Abra `force-app/main/default` e passe dois segundos em `lwc/`, `classes/` e `objects/`. Não abra arquivo.**

*O código está neste repositório. O front é o Lightning Web Component da central de estoque. O back é o Apex, que consulta o saldo e valida a transferência. Os objetos são a loja, o estoque, a transferência e a movimentação.*

**Abra `mock-data/README.md` e aponte a frase de dados fictícios e a tabela do notebook.**

*Os saldos são fictícios, criados para a disciplina. O notebook começa com 15 na Paulista e 2 no Morumbi.*

### 4. Consulta na org — 1:05 a 1:45

**App TechLar Morumbi → Estoque geral. Pesquise `Notebook` e selecione Notebook TechLar X.**

*Na org, estou no aplicativo da loja Morumbi, na aba Estoque geral. Pesquisei o notebook do catálogo. A tela lista o saldo em cada loja: Paulista com 15, Morumbi com 2. O funcionário vê onde falta e onde sobra antes de pedir qualquer coisa.*

### 5. Transferência — 1:45 a 2:35

**Origem: TechLar Paulista. Quantidade: 5. Clique em Pedir transferência. Espere a confirmação com o número, no formato TRF.**

*O destino já é o Morumbi, a loja deste aplicativo. A origem é a Paulista. Peço 5 unidades. O pedido fica concluído e a Paulista baixa de 15 para 10. O Morumbi continua com 2, porque o produto ainda não chegou. O caminho começa em Pedido feito.*

**Anote o número TRF. Clique em Marcar em transporte. O caminho vai para Em transporte e o Morumbi segue em 2. Clique em Confirmar entrada na loja.**

*Em transporte o saldo desta loja não muda. Quando o caminho chega em Concluído, o estoquista dá entrada e o Morumbi passa de 2 para 7. O vendedor não abre o aplicativo da outra loja.*

### 6. Banco — 2:35 a 3:25

**Busca global pelo número TRF. Abra a transferência: origem Paulista, destino Morumbi, quantidade 5, status Concluída.**

*Este é o registro da transferência no Salesforce. O status Concluída é o fim do caminho, quando a loja recebeu.*

**Na página, abra as movimentações relacionadas. Mostre uma Saída na Paulista e uma Entrada no Morumbi.**

*A saída foi gravada quando o pedido saiu da Paulista. A entrada só foi gravada quando o caminho chegou em Concluído.*

**Volte ao Estoque geral do Morumbi. Na lista de estoque por loja, aponte Paulista 10 e Morumbi 7.**

*Os dois saldos fecham o fluxo: a Paulista baixou no pedido e o Morumbi só subiu na entrada.*

### 7. Encerramento — 3:25 a 3:45

**Fique no saldo atualizado ou no número da transferência.**

*A Sprint 3 entrega a operação de estoque: a tela consulta o saldo por loja, a regra valida a transferência e o banco grava o histórico com os saldos novos. O board e o código estão no GitHub. Obrigada.*

---

## Se faltar ou sobrar tempo

| Situação | Ajuste |
| --- | --- |
| Passou de 3:20 antes do registro | Pule a lista final. O saldo 7 na confirmação e a transferência aberta já fecham o banco. |
| Terminou antes de 3:10 | No registro, leia origem, destino, quantidade e as duas movimentações. |
| A busca do TRF não achar | No Estoque geral, pesquise o notebook de novo e mostre Morumbi 7 e Paulista 10. Diga que a confirmação na tela é o número da transferência gravada. |

Não regrave por uma frase diferente. Precisa aparecer: board em Done, pastas do GitHub, dados fictícios, saldo por loja, pedido de 5 da Paulista para o Morumbi, número da transferência, movimentação e saldo novo.

---

## Checklist de evidência

- [ ] Board da Sprint 3 em Done
- [ ] GitHub: LWC, Apex e objetos, sem abrir código
- [ ] Dados fictícios no `mock-data/README.md`
- [ ] Pesquisa do notebook e saldo por loja
- [ ] Origem Paulista, destino Morumbi, quantidade 5
- [ ] Confirmação com o número, caminho Pedido feito → Em transporte → Concluído, e Morumbi em 7 só no fim
- [ ] Registro da transferência em Concluída e movimentações de saída e entrada
- [ ] Paulista em 10 na mesma tela, sem abrir o aplicativo da outra loja
