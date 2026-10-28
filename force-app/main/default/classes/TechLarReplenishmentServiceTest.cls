@IsTest
private class TechLarReplenishmentServiceTest {
    @TestSetup
    static void setupData() {
        Account account = new Account(Name = 'Ana Souza', ClienteTechLar__c = true);
        insert account;
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Notebook TechLar X', ProductCode = 'TL-NB-001', IsActive = true),
            new Product2(Name = 'Mouse Gamer TechLar', ProductCode = 'TL-MS-001', IsActive = true),
            new Product2(Name = 'Monitor 27 TechLar', ProductCode = 'TL-MN-001', IsActive = true),
            new Product2(Name = 'Teclado Mecânico TechLar', ProductCode = 'TL-KB-001', IsActive = true)
        };
        insert products;
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 product : products) {
            entries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 10, IsActive = true));
        }
        insert entries;
        insert new List<Loja__c>{
            new Loja__c(Name = 'TechLar Paulista', Codigo__c = 'PAULISTA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Morumbi', Codigo__c = 'MORUMBI', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Santana', Codigo__c = 'SANTANA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Estoque Central', Codigo__c = 'CENTRAL', Cidade__c = 'São Paulo', Status__c = 'Ativa')
        };
    }

    @IsTest
    static void replenishesStoresBelowMinimumFromCentral() {
        stock('TL-NB-001', 'CENTRAL', 100);
        stock('TL-NB-001', 'PAULISTA', 15);
        stock('TL-NB-001', 'MORUMBI', 2);
        stock('TL-NB-001', 'SANTANA', 4);
        stock('TL-MS-001', 'PAULISTA', 20);
        stock('TL-MS-001', 'MORUMBI', 8);
        stock('TL-MS-001', 'SANTANA', 12);
        stock('TL-KB-001', 'PAULISTA', 9);
        stock('TL-KB-001', 'MORUMBI', 9);
        stock('TL-KB-001', 'SANTANA', 7);
        sell('PAULISTA', new Map<String, Integer>{ 'TL-NB-001' => 30, 'TL-MS-001' => 20, 'TL-KB-001' => 12, 'TL-MN-001' => 5 });
        sell('MORUMBI', new Map<String, Integer>{ 'TL-NB-001' => 25, 'TL-MS-001' => 19, 'TL-MN-001' => 16, 'TL-KB-001' => 4 });
        sell('SANTANA', new Map<String, Integer>{ 'TL-NB-001' => 22, 'TL-MS-001' => 14, 'TL-KB-001' => 11, 'TL-MN-001' => 6 });

        Test.startTest();
        TechLarReplenishmentService.Summary summary = TechLarReplenishmentService.replenish();
        Test.stopTest();

        System.assertEquals(2, summary.transferCount);
        System.assertEquals(86, balance('TL-NB-001', 'CENTRAL'));
        System.assertEquals(15, balance('TL-NB-001', 'PAULISTA'));
        System.assertEquals(10, balance('TL-NB-001', 'MORUMBI'));
        System.assertEquals(10, balance('TL-NB-001', 'SANTANA'));
        System.assert(summary.message.contains('Total de transferências realizadas: 2'));
        System.assertEquals(2, [SELECT COUNT() FROM Transferencia_Estoque__c]);
        System.assertEquals(4, [SELECT COUNT() FROM Movimentacao_Estoque__c]);
    }

    @IsTest
    static void analysisDoesNotTransfer() {
        stock('TL-NB-001', 'CENTRAL', 100);
        stock('TL-NB-001', 'PAULISTA', 15);
        stock('TL-NB-001', 'MORUMBI', 2);
        stock('TL-NB-001', 'SANTANA', 4);
        sell('MORUMBI', new Map<String, Integer>{ 'TL-NB-001' => 10 });
        sell('SANTANA', new Map<String, Integer>{ 'TL-NB-001' => 9 });
        sell('PAULISTA', new Map<String, Integer>{ 'TL-NB-001' => 8 });

        TechLarReplenishmentService.Summary summary = TechLarReplenishmentService.analyze();

        System.assertEquals(0, summary.transferCount);
        System.assertEquals(100, balance('TL-NB-001', 'CENTRAL'));
        System.assertEquals(2, balance('TL-NB-001', 'MORUMBI'));
        System.assertEquals(0, [SELECT COUNT() FROM Transferencia_Estoque__c]);
        System.assert(summary.message.contains('Nenhuma transferência foi feita'));
        System.assert(summary.message.contains('Estoque Central cobre'));
    }

    @IsTest
    static void skipsStoreAlreadyAtMinimum() {
        stock('TL-NB-001', 'CENTRAL', 100);
        stock('TL-NB-001', 'PAULISTA', 5);
        sell('PAULISTA', new Map<String, Integer>{ 'TL-NB-001' => 10 });

        TechLarReplenishmentService.Summary summary = TechLarReplenishmentService.replenish();

        System.assertEquals(0, summary.transferCount);
        System.assertEquals(5, balance('TL-NB-001', 'PAULISTA'));
        System.assertEquals(100, balance('TL-NB-001', 'CENTRAL'));
    }

    @IsTest
    static void doesNotTransferPartialQuantity() {
        stock('TL-NB-001', 'CENTRAL', 3);
        stock('TL-NB-001', 'MORUMBI', 2);
        sell('MORUMBI', new Map<String, Integer>{ 'TL-NB-001' => 10 });

        TechLarReplenishmentService.Summary summary = TechLarReplenishmentService.replenish();

        System.assertEquals(0, summary.transferCount);
        System.assertEquals(2, balance('TL-NB-001', 'MORUMBI'));
        System.assertEquals(3, balance('TL-NB-001', 'CENTRAL'));
        System.assert(summary.message.contains('insuficiente'));
    }

    @IsTest
    static void evaluatesEachStoreSeparately() {
        stock('TL-NB-001', 'CENTRAL', 8);
        stock('TL-NB-001', 'MORUMBI', 2);
        stock('TL-NB-001', 'SANTANA', 4);
        sell('MORUMBI', new Map<String, Integer>{ 'TL-NB-001' => 10 });
        sell('SANTANA', new Map<String, Integer>{ 'TL-NB-001' => 9 });

        TechLarReplenishmentService.Summary summary = TechLarReplenishmentService.replenish();

        System.assertEquals(1, summary.transferCount);
        System.assertEquals(10, balance('TL-NB-001', 'MORUMBI'));
        System.assertEquals(4, balance('TL-NB-001', 'SANTANA'));
        System.assertEquals(0, balance('TL-NB-001', 'CENTRAL'));
        System.assert(summary.message.contains('insuficiente'));
    }

    private static void stock(String productCode, String storeCode, Integer quantity) {
        insert new Estoque__c(
            Produto__c = productId(productCode),
            Loja__c = storeId(storeCode),
            Quantidade_Disponivel__c = quantity,
            Chave__c = productCode + '-' + storeCode
        );
    }

    private static void sell(String storeCode, Map<String, Integer> quantitiesByProduct) {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Order pedido = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today().addDays(-7),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Loja__c = storeId(storeCode)
        );
        insert pedido;
        List<OrderItem> items = new List<OrderItem>();
        for (String productCode : quantitiesByProduct.keySet()) {
            PricebookEntry entry = [
                SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.ProductCode = :productCode LIMIT 1
            ];
            items.add(new OrderItem(
                OrderId = pedido.Id,
                PricebookEntryId = entry.Id,
                Product2Id = productId(productCode),
                Quantity = quantitiesByProduct.get(productCode),
                UnitPrice = entry.UnitPrice
            ));
        }
        insert items;
        pedido.Status = 'Activated';
        update pedido;
    }

    private static Decimal balance(String productCode, String storeCode) {
        return [
            SELECT Quantidade_Disponivel__c
            FROM Estoque__c
            WHERE Chave__c = :(productCode + '-' + storeCode)
        ].Quantidade_Disponivel__c;
    }

    private static Id productId(String productCode) {
        return [SELECT Id FROM Product2 WHERE ProductCode = :productCode LIMIT 1].Id;
    }

    private static Id storeId(String storeCode) {
        return [SELECT Id FROM Loja__c WHERE Codigo__c = :storeCode LIMIT 1].Id;
    }
}
