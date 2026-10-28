// Vendas fictícias dos últimos 30 dias, já ligadas à loja.
// O notebook fica no Top 3 e é o único item abaixo de 5 nesse ranking.
// Rodar de novo apaga os pedidos marcados com ShippingStreet = Carga fictícia Sprint 4.

Account customer = [SELECT Id FROM Account WHERE ClienteTechLar__c = TRUE ORDER BY CreatedDate ASC LIMIT 1];
Id pricebookId = [SELECT Id FROM Pricebook2 WHERE Name = 'TechLar Pricebook' AND IsActive = TRUE LIMIT 1].Id;

Map<String, Id> productIds = new Map<String, Id>();
for (Product2 product : [
    SELECT Id, ProductCode FROM Product2
    WHERE ProductCode IN ('TL-NB-001', 'TL-MS-001', 'TL-MN-001', 'TL-KB-001') AND IsActive = TRUE
    ORDER BY ClienteTechLar__c DESC, CreatedDate ASC
]) {
    if (!productIds.containsKey(product.ProductCode)) {
        productIds.put(product.ProductCode, product.Id);
    }
}
Map<String, PricebookEntry> entries = new Map<String, PricebookEntry>();
for (PricebookEntry entry : [
    SELECT Id, UnitPrice, Product2.ProductCode
    FROM PricebookEntry
    WHERE Pricebook2Id = :pricebookId AND Product2Id IN :productIds.values() AND IsActive = TRUE
]) {
    entries.put(entry.Product2.ProductCode, entry);
}
Map<String, Id> storeIds = new Map<String, Id>();
for (Loja__c store : [SELECT Id, Codigo__c FROM Loja__c WHERE Codigo__c IN ('PAULISTA', 'MORUMBI', 'SANTANA')]) {
    storeIds.put(store.Codigo__c, store.Id);
}

List<Order> previous = [SELECT Id FROM Order WHERE ShippingStreet = 'Carga fictícia Sprint 4'];
if (!previous.isEmpty()) {
    for (Order pedido : previous) {
        pedido.Status = 'Draft';
    }
    update previous;
    delete [SELECT Id FROM OrderItem WHERE OrderId IN :previous];
    delete previous;
}

Map<String, Map<String, Integer>> sales = new Map<String, Map<String, Integer>>{
    'PAULISTA' => new Map<String, Integer>{ 'TL-NB-001' => 30, 'TL-MS-001' => 20, 'TL-KB-001' => 12, 'TL-MN-001' => 5 },
    'MORUMBI' => new Map<String, Integer>{ 'TL-NB-001' => 25, 'TL-MS-001' => 19, 'TL-MN-001' => 16, 'TL-KB-001' => 4 },
    'SANTANA' => new Map<String, Integer>{ 'TL-NB-001' => 22, 'TL-MS-001' => 14, 'TL-KB-001' => 11, 'TL-MN-001' => 6 }
};

for (String storeCode : sales.keySet()) {
    Order pedido = new Order(
        AccountId = customer.Id,
        ClienteTechLar__c = true,
        EffectiveDate = Date.today().addDays(-7),
        Status = 'Draft',
        Pricebook2Id = pricebookId,
        Loja__c = storeIds.get(storeCode),
        CanalVenda__c = 'Loja Física',
        ShippingStreet = 'Carga fictícia Sprint 4',
        ShippingCity = 'São Paulo',
        ShippingState = 'SP',
        ShippingCountry = 'Brazil'
    );
    insert pedido;
    List<OrderItem> items = new List<OrderItem>();
    for (String productCode : sales.get(storeCode).keySet()) {
        PricebookEntry entry = entries.get(productCode);
        if (entry == null) {
            throw new IllegalArgumentException('Sem preço no TechLar Pricebook para ' + productCode);
        }
        items.add(new OrderItem(
            OrderId = pedido.Id,
            PricebookEntryId = entry.Id,
            Product2Id = productIds.get(productCode),
            Quantity = sales.get(storeCode).get(productCode),
            UnitPrice = entry.UnitPrice
        ));
    }
    insert items;
    pedido.Status = 'Activated';
    update pedido;
}

System.debug('Vendas fictícias da Sprint 4 gravadas para ' + sales.size() + ' lojas.');
