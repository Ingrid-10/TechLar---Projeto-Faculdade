# Roteiro do vídeo — AC1 Sprint 1

**Duração:** 3 min 20 s a 3 min 50 s (máximo 4 min)  
**Destino:** YouTube (não listado ou público, conforme a entrega)  
**Ordem obrigatória:** board → GitHub → solução na org  
**Não fazer:** abrir classe Apex, LWC ou explicar linha de código. O professor vê isso no repositório.

---

## Antes de gravar (3 minutos)

Abas do navegador, nesta ordem, já logadas e em tela cheia:

1. **Board:** [Sprint 1 — Venda Assistida](https://github.com/users/Ingrid-10/projects/1) — visão Board, coluna **Done** visível.
2. **Código:** [repositório](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade) — pasta `force-app/main/default` aberta o suficiente para ver `classes/` e `lwc/`.
3. **Dados:** [data/README.md](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/blob/main/data/README.md) (ou `data/inspector/` no mesmo repo).
4. **Org:** app **TechLar** → aba **Nova Venda**. Tela limpa, sem venda pela metade.

Anotação ao lado do teclado:

| Campo | Valor |
| --- | --- |
| Cliente | Ana Souza |
| CPF | `700.000.001-59` |
| Produto 1 | Notebook TechLar X |
| Produto 2 | Mouse Gamer TechLar |
| Modalidade | Entrega no endereço |
| CEP | `01310-100` |

Feche notificações. Zoom do browser em 110–125%. Fale devagar. Se errar um clique, continue — não recomece o vídeo inteiro.

---

## Título e descrição do YouTube

**Título:** TechLar — AC1 Sprint 1 · Venda assistida em loja física

**Descrição:**

```
AC1 — Sprint 1 do projeto TechLar 360 (Análise e Desenvolvimento de Sistemas).
Venda assistida em loja física no Salesforce: localizar cliente, catálogo, carrinho, entrega com CEP e gravação do pedido no CRM.

Repositório: https://github.com/Ingrid-10/TechLar---Projeto-Faculdade
Board: https://github.com/users/Ingrid-10/projects/1
```

---

## Roteiro falado

Fale o texto em *itálico*. O que está em **negrito** é ação na tela, não é para ler.

---

### 1. Abertura — 0:00 a 0:18

**Tela:** board (ou um slide preto só com “TechLar · Sprint 1”).

*Olá. Eu sou Ingrid Costa. Este é o vídeo da AC1 da Sprint 1 do projeto TechLar: venda assistida em loja física no Salesforce. Em cerca de quatro minutos eu mostro o board da sprint, o repositório no GitHub e, na org, o fluxo completo até o pedido gravado no CRM.*

---

### 2. Board — 0:18 a 0:50

**Tela:** GitHub Projects, coluna Done.

**Percorra os cards com o mouse, sem abrir issue.**

*O trabalho foi organizado neste board público. O épico é: o vendedor localiza o cliente, escolhe os produtos e conclui a venda numa única interface, registrando o pedido no CRM.*

*As cinco histórias estão concluídas: cliente, produto, carrinho, entrega com consulta de CEP, e finalização do Order. Os critérios de aceitação são estes: a venda grava pedido, itens e vínculo com o cliente; carrinho vazio não cria pedido; entrega sem endereço pede os dados.*

---

### 3. GitHub (código e dados) — 0:50 a 1:25

**Tela:** repositório → role o README.

*O código está neste repositório público. A Sprint 1 é a página Nova Venda, com front em Lightning Web Components e regras de negócio em Apex. O professor tem o GitHub para inspecionar o detalhe.*

**Clique em `force-app/main/default`. Mostre `lwc/` e `classes/` (dois segundos em cada pasta). Não abra arquivo.**

*Aqui está o front, na pasta LWC, e o back, nas classes Apex. A tela principal é a de vendas; o servidor valida cliente, produtos, preço, modalidade e recalcula o total antes de gravar.*

**Abra `data/README.md` (ou a pasta `data/inspector/`). Role o texto “fictícios”.**

*Os dados da demonstração são fictícios: contas pessoa física com CPF, catálogo TechLar e entradas de preço. Eu vou usar a cliente Ana Souza e produtos desse catálogo.*

**Opcional (5 s):** aba Commits, só para o professor ver histórico. Sem ler mensagem de commit.

---

### 4. Solução na org — 1:25 a 3:25

**Tela:** Salesforce, app **TechLar**, aba **Nova Venda**.

#### 4.1 Cliente

*Agora a org. O vendedor está no app TechLar, na aba Nova Venda. O cliente é identificado pela conta pessoa física, o Account, com CPF.*

**Digite `700.000.001-59` → Pesquisar → selecione Ana Souza se a lista não selecionar sozinha.**

*Busquei pelo CPF e localizei a Ana Souza, já cadastrada nos dados mockados. Nome, e-mail, telefone e CPF ficam vinculados à venda.*

#### 4.2 Produto e carrinho

**Pesquisar produto: `Notebook` → adicionar. Depois `Mouse` → adicionar. No carrinho, suba o mouse para quantidade 2.**

*Pesquisei no catálogo TechLar, adicionei o notebook e o mouse. O carrinho mostra quantidade, subtotal e total. O preço não é só da tela: na finalização o Apex consulta de novo o catálogo.*

#### 4.3 Entrega e CEP

**Selecione Entrega no endereço. No CEP, `01310-100` → consultar.**

*Para recebimento, o vendedor escolhe retirada na loja ou entrega. Vou pela entrega. Consultei o CEP na ViaCEP: o endereço de São Paulo preenche sozinho e o frete mock entra no total, com prazo em dias úteis.*

**Aponte com o mouse o total com frete.**

*Se eu tivesse escolhido retirada, o frete seria zero e não exigiria endereço.*

#### 4.4 Finalizar

**Clique em Finalizar venda. Espere o toast e a confirmação com o número do pedido.**

*Finalizei. O Apex validou cliente, itens, preço e endereço, criou o pedido e os itens, e ativou o Order. A tela devolve o número da venda.*

---

### 5. Pedido no CRM — 3:25 a 3:50

**Clique para abrir o pedido (botão da confirmação). Na página do Order, role: Account = Ana Souza, Canal = Loja Física, Modalidade = Entrega, itens, valor de frete.**

*Este é o registro no CRM. A conta da Ana Souza está no pedido, o canal é loja física, a modalidade é entrega. Abaixo, os dois itens com quantidade e preço. Isso fecha o ciclo front, back e dados da Sprint 1.*

---

### 6. Encerramento — 3:50 a 4:00

**Volte um segundo ao número do pedido ou ao GitHub.**

*Resumindo: o vendedor conclui a venda assistida numa tela só, e o Salesforce grava Order e OrderItem ligados ao cliente. O board, o código e os dados estão no GitHub. Obrigada.*

---

## Se faltar ou sobrar tempo

| Situação | Ajuste |
| --- | --- |
| Passou de 3:40 antes de abrir o Order | Pule a frase da retirada. Vá direto ao pedido. |
| Terminou em menos de 3:10 | No Order, fale os três critérios: pedido gravado; sem cliente/carrinho a venda não fecha; entrega exige endereço. |
| CEP falhar | Troque para **Retirada na loja** e finalize. Diga: “a entrega usa ViaCEP; neste take mostro a retirada, que também grava o pedido.” |
| Cliente não achar | Use Amanda Vargas, CPF `700.000.049-01`. |

Não grave de novo só porque a fala saiu um pouco diferente. O que precisa aparecer na tela: board Done, GitHub, Nova Venda, pedido aberto com cliente e itens.

---

## Checklist de evidência (o professor precisa ver)

- [ ] Board com as histórias em Done
- [ ] Repositório GitHub (front LWC + back Apex, sem zoom em código)
- [ ] Dados fictícios (`data/README` ou pasta inspector)
- [ ] Busca de cliente por CPF → Account
- [ ] Produto do catálogo + carrinho com quantidade e total
- [ ] Entrega + CEP (ou retirada, se o CEP cair)
- [ ] Confirmação com número do pedido
- [ ] Order na org: cliente, canal Loja Física, itens
