# Import via Salesforce Inspector — 50 clientes mock

Todos os registros são **fictícios** (projeto acadêmico). CPFs e e-mails não correspondem a pessoas reais.

O cliente é pessoa física identificada pela **Account** (`CPF__c` + `ClienteTechLar__c`). O Contact replica o mesmo CPF e guarda o e-mail.

## Ordem no Inspector

1. **Account** — importe [`01-accounts.csv`](01-accounts.csv)
   - Object: `Account`
   - Action: Insert
   - Campos: `Name`, `RecordType.Name` (**TechLar PF**), `CPF__c`, `ClienteTechLar__c`, telefone, endereço
   - No Inspector, mapeie `RecordType.Name` como lookup do Record Type (Name = `TechLar PF`)
   - `AccountNumber` (`TL-ACC-001` … `TL-ACC-050`) liga o Contact depois
2. **Contact** (próximo passo) — [`02-contacts.csv`](02-contacts.csv)
   - Object: `Contact`
   - Action: Insert
   - Relacione a conta por `Account.AccountNumber` (ou `Account.CPF__c`)
   - Campos: `CPF__c`, `Email`, `ClienteTechLar__c`

3. **Product2** — importe [`03-products.csv`](03-products.csv)
   - Object: `Product2`
   - Action: Insert
   - Inclui `ClienteTechLar__c` = `true` para filtrar a list view
4. **PricebookEntry (Standard)** — só se o produto ainda não tiver preço padrão: [`04-pricebook-entries-standard.csv`](04-pricebook-entries-standard.csv)
   - Object: `PricebookEntry`
   - Lookup: `Product2.ProductCode` e `Pricebook2.Name` = `Standard Price Book`
   - O Salesforce exige esse preço antes do catálogo custom
5. **PricebookEntry (TechLar)** — importe [`04-pricebook-entries.csv`](04-pricebook-entries.csv)
   - Object: `PricebookEntry`
   - Mapeie `Product2Id` e `Pricebook2Id` (Ids da org). Não use `Product2.ProductCode` — o Inspector não aceita esse lookup.

Depois do import, filtre as list views com **Cliente TechLar equals True** ou **CPF**.
