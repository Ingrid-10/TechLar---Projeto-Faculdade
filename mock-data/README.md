# Dados mockados — estoque TechLar (Sprint 3)

Os dados utilizados no projeto são **totalmente fictícios** e foram criados exclusivamente para fins acadêmicos. Não há lojas, saldos ou movimentações reais.

O arquivo [estoque-inicial.csv](estoque-inicial.csv) é a origem documentada dos saldos. O script [scripts/apex/loadEstoqueMock.apex](../scripts/apex/loadEstoqueMock.apex) grava as mesmas lojas e os mesmos saldos no Salesforce. Rodar o script de novo restaura essas quantidades.

Os produtos não são criados aqui. Eles vêm da Sprint 1 (`scripts/apex/loadMockData.apex`).

## Lojas

| Código | Nome | Cidade | Status |
| --- | --- | --- | --- |
| PAULISTA | TechLar Paulista | São Paulo | Ativa |
| MORUMBI | TechLar Morumbi | São Paulo | Ativa |
| SANTANA | TechLar Santana | São Paulo | Ativa |
| CENTRAL | TechLar Estoque Central | São Paulo | Ativa |

## Saldos

| Produto | Código | Paulista | Morumbi | Santana |
| --- | --- | --- | --- | --- |
| Notebook TechLar X | TL-NB-001 | 15 | 2 | 4 |
| Mouse Gamer TechLar | TL-MS-001 | 20 | 8 | 12 |
| Monitor 27 TechLar | TL-MN-001 | 4 | 10 | 3 |
| Teclado Mecânico TechLar | TL-KB-001 | 9 | 9 | 7 |

O notebook é o cenário principal. Na Sprint 4, Santana fica com 4 para ficar abaixo do mínimo, e o Estoque Central começa com 100. O central não aparece como origem no Estoque geral das lojas.

## Carga

```bash
sf apex run --file scripts/apex/loadMockData.apex --target-org techlar
sf apex run --file scripts/apex/loadEstoqueMock.apex --target-org techlar
sf apex run --file scripts/apex/loadVendasRecentes.apex --target-org techlar
```
