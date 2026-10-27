// Carga fictícia de lojas e saldos da Sprint 3.
// Origem documentada: mock-data/estoque-inicial.csv
// Exige os produtos da Sprint 1. Rodar de novo restaura estas quantidades.
// Não cria transferência nem movimentação.

List<String> productCodes = new List<String>{
    'TL-NB-001', 'TL-MS-001', 'TL-MN-001', 'TL-KB-001'
};

Map<String, Product2> productsByCode = new Map<String, Product2>();
for (Product2 product : [
    SELECT Id, ProductCode
    FROM Product2
    WHERE ProductCode IN :productCodes AND IsActive = TRUE
    ORDER BY ClienteTechLar__c DESC, CreatedDate ASC
]) {
    if (!productsByCode.containsKey(product.ProductCode)) {
        productsByCode.put(product.ProductCode, product);
    }
}

List<String> missing = new List<String>();
for (String code : productCodes) {
    if (!productsByCode.containsKey(code)) {
        missing.add(code);
    }
}
System.assert(
    missing.isEmpty(),
    'Produtos da Sprint 1 ausentes. Rode scripts/apex/loadMockData.apex antes. Faltando: ' + String.join(missing, ', ')
);

upsert new List<Loja__c>{
    new Loja__c(Name = 'TechLar Paulista', Codigo__c = 'PAULISTA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
    new Loja__c(Name = 'TechLar Morumbi', Codigo__c = 'MORUMBI', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
    new Loja__c(Name = 'TechLar Santana', Codigo__c = 'SANTANA', Cidade__c = 'São Paulo', Status__c = 'Ativa')
} Codigo__c;

Map<String, Id> lojaIdByCode = new Map<String, Id>();
for (Loja__c loja : [SELECT Id, Codigo__c FROM Loja__c WHERE Codigo__c IN ('PAULISTA', 'MORUMBI', 'SANTANA')]) {
    lojaIdByCode.put(loja.Codigo__c, loja.Id);
}

List<List<String>> rows = new List<List<String>>{
    new List<String>{ 'TL-NB-001', 'PAULISTA', '15' },
    new List<String>{ 'TL-NB-001', 'MORUMBI', '2' },
    new List<String>{ 'TL-NB-001', 'SANTANA', '6' },
    new List<String>{ 'TL-MS-001', 'PAULISTA', '20' },
    new List<String>{ 'TL-MS-001', 'MORUMBI', '8' },
    new List<String>{ 'TL-MS-001', 'SANTANA', '12' },
    new List<String>{ 'TL-MN-001', 'PAULISTA', '4' },
    new List<String>{ 'TL-MN-001', 'MORUMBI', '10' },
    new List<String>{ 'TL-MN-001', 'SANTANA', '3' },
    new List<String>{ 'TL-KB-001', 'PAULISTA', '9' },
    new List<String>{ 'TL-KB-001', 'MORUMBI', '9' },
    new List<String>{ 'TL-KB-001', 'SANTANA', '7' }
};

List<Estoque__c> estoques = new List<Estoque__c>();
for (List<String> row : rows) {
    String productCode = row[0];
    String storeCode = row[1];
    estoques.add(new Estoque__c(
        Chave__c = productCode + '-' + storeCode,
        Produto__c = productsByCode.get(productCode).Id,
        Loja__c = lojaIdByCode.get(storeCode),
        Quantidade_Disponivel__c = Integer.valueOf(row[2])
    ));
}
upsert estoques Chave__c;

System.debug('Lojas TechLar=' + lojaIdByCode.size() + ' Estoques=' + estoques.size());
