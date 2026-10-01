# Board — Sprint 2 (GitHub Projects)

Project existente: [Sprint 1 — Venda Assistida](https://github.com/users/Ingrid-10/projects/1)

A Sprint 2 usa a **view Sprint 2** e a coluna **Done** do Board. Os 6 cards Done da Sprint 1 não foram alterados.

Label: `sprint-2`

## Épico

- [#7 Épico: atendimento e pós-venda unificado](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/issues/7)

Como atendente da TechLar, quero localizar um cliente e suas compras e registrar um atendimento relacionado ao produto adquirido, para que o problema seja tratado de forma centralizada e vinculado ao histórico do cliente.

## Histórias

- [#8 Consulta: pesquisar cliente e histórico de compras](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/issues/8)
- [#9 Atendimento: selecionar pedido/produto e abrir Case](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/issues/9)
- [#10 Encaminhamento: Flow classifica motivo e atribui fila](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/issues/10)
- [#11 Resolução: atualizar status e concluir o Case](https://github.com/Ingrid-10/TechLar---Projeto-Faculdade/issues/11)

## Critérios de aceitação

- Abertura de atendimento cria um Case ligado ao cliente e à compra, com confirmação e Path na LWC.
- Case com motivo “Produto com defeito” é encaminhado pelo Flow à fila Pós-venda e fica em análise.
- Sem pedido selecionado, o sistema não cria o Case.
- O atendente conclui o Case na mesma tela (Closed + resultado).
