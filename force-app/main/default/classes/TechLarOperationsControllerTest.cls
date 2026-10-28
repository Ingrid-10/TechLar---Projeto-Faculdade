@IsTest
private class TechLarOperationsControllerTest {
    @IsTest
    static void boardAndPathFollowTheTwoRequests() {
        Account account = new Account(Name = 'Ana Souza', ClienteTechLar__c = true);
        insert account;
        Product2 product = new Product2(Name = 'Notebook TechLar X', ProductCode = 'TL-NB-001', IsActive = true);
        insert product;
        insert new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 10,
            IsActive = true
        );
        insert new List<Loja__c>{
            new Loja__c(Name = 'TechLar Paulista', Codigo__c = 'PAULISTA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Morumbi', Codigo__c = 'MORUMBI', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Santana', Codigo__c = 'SANTANA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Estoque Central', Codigo__c = 'CENTRAL', Cidade__c = 'São Paulo', Status__c = 'Ativa')
        };
        insert new List<Estoque__c>{
            stock(product.Id, 'CENTRAL', 100),
            stock(product.Id, 'PAULISTA', 15),
            stock(product.Id, 'MORUMBI', 2),
            stock(product.Id, 'SANTANA', 4)
        };
        sell(account.Id, product.Id, 'MORUMBI', 10);

        TechLarOperationsController.Board situation = TechLarOperationsController.checkStores();
        System.assertEquals(0, situation.transferCount);
        System.assertEquals(4, situation.stores.size());
        System.assertEquals(2, balance('MORUMBI'));

        TechLarOperationsController.Board replenished = TechLarOperationsController.replenishStores();
        System.assertEquals(1, replenished.transferCount);
        System.assertEquals(10, balance('MORUMBI'));
        Id transferId = [
            SELECT Id FROM Transferencia_Estoque__c LIMIT 1
        ].Id;

        TechLarOperationsController.PathView path = TechLarOperationsController.transferPath(transferId);
        System.assertEquals('recebido', path.currentStep);
        System.assertEquals('TechLar Morumbi', path.destinationName);
        System.assertEquals('TechLar Estoque Central', path.originName);
    }

    private static Estoque__c stock(Id productId, String storeCode, Integer quantity) {
        return new Estoque__c(
            Produto__c = productId,
            Loja__c = [SELECT Id FROM Loja__c WHERE Codigo__c = :storeCode LIMIT 1].Id,
            Quantidade_Disponivel__c = quantity,
            Chave__c = 'TL-NB-001-' + storeCode
        );
    }

    private static void sell(Id accountId, Id productId, String storeCode, Integer quantity) {
        PricebookEntry entry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :productId LIMIT 1];
        Order pedido = new Order(
            AccountId = accountId,
            EffectiveDate = Date.today().addDays(-3),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Loja__c = [SELECT Id FROM Loja__c WHERE Codigo__c = :storeCode LIMIT 1].Id
        );
        insert pedido;
        insert new OrderItem(
            OrderId = pedido.Id,
            PricebookEntryId = entry.Id,
            Product2Id = productId,
            Quantity = quantity,
            UnitPrice = entry.UnitPrice
        );
        pedido.Status = 'Activated';
        update pedido;
    }

    private static Decimal balance(String storeCode) {
        return [
            SELECT Quantidade_Disponivel__c
            FROM Estoque__c
            WHERE Chave__c = :('TL-NB-001-' + storeCode)
        ].Quantidade_Disponivel__c;
    }
}
