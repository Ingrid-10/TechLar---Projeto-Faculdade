# Dados mockados — Sprint 1

Todos os registros são **fictícios**, criados para o projeto acadêmico TechLar 360. Não há dados reais de clientes, CPFs ou transações.

**Origem:** elaborados para a AC1 com base no fluxo de venda assistida em loja física (clientes do PDF de exemplo, como Ana Souza, e catálogo de produtos de tecnologia).

## Arquivos

- `accounts.csv` — contas 1:1 com o cliente (amostra pequena)
- `contacts.csv` — pessoas (CPF, e-mail, telefone, endereço)
- `products.csv` — produtos do catálogo TechLar (`ClienteTechLar__c`) e preços do Standard Price Book
- [`inspector/`](inspector/) — import Salesforce Inspector: clientes (`01-accounts.csv`, `02-contacts.csv`) e produtos (`03-products.csv`, depois `04-pricebook-entries.csv`)

## Como carregar no org

Preferencial (resolve IDs e Pricebook automaticamente):

```bash
sf apex run --file scripts/apex/loadMockData.apex --target-org techlar
```

Alternativa: importar os CSVs com Data Loader / `sf data import` depois de criar os produtos e obter o Id do Standard Price Book.

## Comprovação na demonstração

No vídeo da AC1, mostrar este README e um pedido gerado a partir de um desses clientes/produtos.
