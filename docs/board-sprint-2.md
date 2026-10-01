# Board — Sprint 2 (GitHub Projects)

Board público (mesmo project da Sprint 1): [Sprint 1 — Venda Assistida](https://github.com/users/Ingrid-10/projects/1)

View **Sprint 2** no project. Os cards Done da Sprint 1 não foram alterados.

## Épico

Como atendente da TechLar, quero localizar um cliente e suas compras e registrar um atendimento relacionado ao produto adquirido, para que o problema seja tratado de forma centralizada e vinculado ao histórico do cliente.

## Histórias

1. **Consulta** — pesquisar Account TechLar (nome, e-mail ou CPF) e listar Order + OrderItem.
2. **Atendimento** — selecionar pedido e produto, informar motivo e descrição; Apex grava o Case.
3. **Encaminhamento** — Flow classifica o motivo, atribui a fila (Pós-venda, Logística ou Atendimento) e coloca o status em Working.
4. **Resolução** — registrar o resultado e fechar o Case (Closed / Resolvido) na mesma tela.

## Critérios de aceitação

- Abertura de atendimento cria um Case ligado ao cliente e à compra, com Path e confirmação na LWC.
- Case com motivo “Produto com defeito” é encaminhado pelo Flow à fila Pós-venda e fica em análise.
- Sem pedido selecionado, o sistema não cria o Case.
