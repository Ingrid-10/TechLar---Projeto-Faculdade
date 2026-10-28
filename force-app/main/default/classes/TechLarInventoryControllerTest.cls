@IsTest
private class TechLarInventoryControllerTest {
    @TestSetup
    static void setupData() {
        Product2 notebook = new Product2(
            Name = 'Notebook TechLar X',
            ProductCode = 'TL-NB-001',
            IsActive = true
        );
        insert notebook;

        insert new List<Loja__c>{
            new Loja__c(Name = 'TechLar Paulista', Codigo__c = 'PAULISTA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Morumbi', Codigo__c = 'MORUMBI', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Santana', Codigo__c = 'SANTANA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Estoque Central', Codigo__c = 'CENTRAL', Cidade__c = 'São Paulo', Status__c = 'Ativa')
        };
    }

    @IsTest
    static void searchAndStockReturnStores() {
        Product2 notebook = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        insertStock(notebook.Id, 'PAULISTA', 15);
        insertStock(notebook.Id, 'MORUMBI', 2);
        insertStock(notebook.Id, 'SANTANA', 6);
        insertStock(notebook.Id, 'CENTRAL', 100);

        Test.startTest();
        List<TechLarInventoryService.ProductOption> found = TechLarInventoryController.searchProducts('Notebook', 'PAULISTA');
        TechLarInventoryService.StockView stock = TechLarInventoryController.getStock(notebook.Id);
        Test.stopTest();

        System.assertEquals(1, found.size());
        System.assertEquals(notebook.Id, found[0].productId);
        System.assertEquals(15, found[0].quantidade);
        System.assertEquals(1, TechLarInventoryController.searchProducts('Notebook', null).size());
        TechLarInventoryService.StoreContext paulista = TechLarInventoryController.getStore('PAULISTA');
        System.assertEquals('TechLar Paulista', paulista.name);
        System.assertEquals(2, paulista.destinations.size());
        for (TechLarInventoryService.StoreOption destination : paulista.destinations) {
            System.assertNotEquals('CENTRAL', destination.code);
        }
        System.assertEquals(3, stock.lines.size());
        Map<String, Decimal> quantityByStore = new Map<String, Decimal>();
        for (TechLarInventoryService.StockLine line : stock.lines) {
            quantityByStore.put(line.lojaCodigo, line.quantidade);
        }
        System.assertEquals(15, quantityByStore.get('PAULISTA'));
        System.assertEquals(2, quantityByStore.get('MORUMBI'));
        System.assertEquals(6, quantityByStore.get('SANTANA'));
    }

    @IsTest
    static void transferMovesBalanceAndWritesHistory() {
        Product2 notebook = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        Id paulista = storeId('PAULISTA');
        Id morumbi = storeId('MORUMBI');
        insertStock(notebook.Id, 'PAULISTA', 15);
        insertStock(notebook.Id, 'MORUMBI', 2);

        TechLarInventoryService.TransferRequest request = new TechLarInventoryService.TransferRequest();
        request.productId = notebook.Id;
        request.originStoreId = paulista;
        request.destinationStoreId = morumbi;
        request.quantity = 5;

        Test.startTest();
        TechLarInventoryService.TransferResult result = TechLarInventoryController.transferStock(request);
        Test.stopTest();

        System.assertEquals(15, result.originBalanceBefore);
        System.assertEquals(10, result.originBalance);
        System.assertEquals(7, result.destinationBalance);
        TechLarInventoryService.TransferView arrived = TechLarInventoryController.getTransferView(result.transferId);
        System.assertEquals(15, arrived.originBefore);
        System.assertEquals(10, arrived.originAfter);
        System.assertEquals(7, arrived.destinationAfter);
        System.assert(result.message.contains('concluída'));

        Transferencia_Estoque__c transferRecord = [
            SELECT Status__c, Quantidade__c, Loja_Origem__c, Loja_Destino__c
            FROM Transferencia_Estoque__c
            WHERE Id = :result.transferId
        ];
        System.assertEquals('Concluída', transferRecord.Status__c);
        System.assertEquals(5, transferRecord.Quantidade__c);
        System.assertEquals(paulista, transferRecord.Loja_Origem__c);
        System.assertEquals(morumbi, transferRecord.Loja_Destino__c);

        Map<String, Movimentacao_Estoque__c> movements = new Map<String, Movimentacao_Estoque__c>();
        for (Movimentacao_Estoque__c movement : [
            SELECT Tipo__c, Loja__c, Quantidade__c, Transferencia__c
            FROM Movimentacao_Estoque__c
            WHERE Transferencia__c = :result.transferId
        ]) {
            movements.put(movement.Tipo__c, movement);
        }
        System.assertEquals(2, movements.size());
        System.assertEquals(paulista, movements.get('Saída').Loja__c);
        System.assertEquals(morumbi, movements.get('Entrada').Loja__c);
        System.assertEquals(10, [SELECT Quantidade_Disponivel__c FROM Estoque__c WHERE Chave__c = 'TL-NB-001-PAULISTA'].Quantidade_Disponivel__c);
        System.assertEquals(7, [SELECT Quantidade_Disponivel__c FROM Estoque__c WHERE Chave__c = 'TL-NB-001-MORUMBI'].Quantidade_Disponivel__c);
    }

    @IsTest
    static void requestKeepsDestinationUntilReceived() {
        Product2 notebook = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        insertStock(notebook.Id, 'PAULISTA', 15);
        insertStock(notebook.Id, 'MORUMBI', 2);
        TechLarInventoryService.TransferRequest request = requestFor(notebook.Id, 'PAULISTA', 'MORUMBI', 5);

        Test.startTest();
        TechLarInventoryService.TransferResult requested = TechLarInventoryController.requestStock(request);
        TechLarInventoryService.TransferResult transit = TechLarInventoryController.advanceStock(requested.transferId);
        TechLarInventoryService.TransferResult received = TechLarInventoryController.advanceStock(requested.transferId);
        Test.stopTest();

        System.assertEquals('pedido', requested.currentStep);
        System.assertEquals('Pedido feito', requested.status);
        System.assertEquals(10, requested.originBalance);
        System.assertEquals(2, requested.destinationBalance);
        System.assertEquals('Marcar em transporte', requested.advanceLabel);
        System.assertEquals('transporte', transit.currentStep);
        System.assertEquals('Em transporte', transit.status);
        System.assertEquals(2, transit.destinationBalance);
        System.assertEquals('Confirmar entrada na loja', transit.advanceLabel);
        System.assertEquals('concluido', received.currentStep);
        System.assertEquals('Concluída', received.status);
        System.assertEquals(null, received.advanceLabel);
        System.assertEquals(2, received.destinationBalanceBefore);
        System.assertEquals(7, received.destinationBalance);
        System.assertEquals(10, [SELECT Quantidade_Disponivel__c FROM Estoque__c WHERE Chave__c = 'TL-NB-001-PAULISTA'].Quantidade_Disponivel__c);
        System.assertEquals(7, [SELECT Quantidade_Disponivel__c FROM Estoque__c WHERE Chave__c = 'TL-NB-001-MORUMBI'].Quantidade_Disponivel__c);

        Map<String, Integer> movements = new Map<String, Integer>();
        for (AggregateResult row : [
            SELECT Tipo__c type, COUNT(Id) total
            FROM Movimentacao_Estoque__c
            WHERE Transferencia__c = :requested.transferId
            GROUP BY Tipo__c
        ]) {
            movements.put((String) row.get('type'), (Integer) row.get('total'));
        }
        System.assertEquals(1, movements.get('Saída'));
        System.assertEquals(1, movements.get('Entrada'));

        try {
            TechLarInventoryController.advanceStock(requested.transferId);
            System.assert(false, 'Deveria recusar uma entrada repetida');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('já foi recebida'));
        }
    }

    @IsTest
    static void openTransfersStayAvailableForTheDestinationStore() {
        Product2 notebook = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        insertStock(notebook.Id, 'PAULISTA', 15);
        insertStock(notebook.Id, 'MORUMBI', 2);
        insertStock(notebook.Id, 'SANTANA', 6);
        TechLarInventoryService.TransferRequest request = requestFor(notebook.Id, 'PAULISTA', 'MORUMBI', 5);
        TechLarInventoryController.transferStock(requestFor(notebook.Id, 'SANTANA', 'MORUMBI', 1));

        Test.startTest();
        TechLarInventoryService.TransferResult requested = TechLarInventoryController.requestStock(request);
        List<TechLarInventoryService.OpenTransfer> openForMorumbi = TechLarInventoryController.listOpenTransfers('MORUMBI');
        TechLarInventoryService.TransferResult resumed = TechLarInventoryController.resumeStock(requested.transferId);
        TechLarInventoryController.advanceStock(requested.transferId);
        List<TechLarInventoryService.OpenTransfer> inTransit = TechLarInventoryController.listOpenTransfers('MORUMBI');
        TechLarInventoryController.advanceStock(requested.transferId);
        List<TechLarInventoryService.OpenTransfer> afterReceipt = TechLarInventoryController.listOpenTransfers('MORUMBI');
        Test.stopTest();

        System.assertEquals(0, TechLarInventoryController.listOpenTransfers('PAULISTA').size());
        System.assertEquals(1, openForMorumbi.size());
        System.assertEquals(requested.transferId, openForMorumbi[0].transferId);
        System.assertEquals('Pedido feito', openForMorumbi[0].status);
        System.assert(openForMorumbi[0].summary.contains('TechLar Paulista'));
        System.assertEquals('pedido', resumed.currentStep);
        System.assertEquals(notebook.Id, resumed.productId);
        System.assertEquals(3, resumed.destinationBalance);
        System.assertEquals(10, resumed.originBalance);
        System.assertEquals('Em transporte', inTransit[0].status);
        System.assertEquals(0, afterReceipt.size());
    }

    @IsTest
    static void transferRejectsInsufficientStock() {
        Product2 notebook = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        insertStock(notebook.Id, 'PAULISTA', 2);
        insertStock(notebook.Id, 'MORUMBI', 2);
        TechLarInventoryService.TransferRequest request = requestFor(notebook.Id, 'PAULISTA', 'MORUMBI', 5);

        try {
            TechLarInventoryController.transferStock(request);
            System.assert(false, 'Deveria recusar estoque insuficiente');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('estoque suficiente'));
        }

        System.assertEquals(0, [SELECT COUNT() FROM Transferencia_Estoque__c]);
        System.assertEquals(2, [SELECT Quantidade_Disponivel__c FROM Estoque__c WHERE Chave__c = 'TL-NB-001-PAULISTA'].Quantidade_Disponivel__c);
    }

    @IsTest
    static void transferRejectsSameStoreAndInvalidQuantity() {
        Product2 notebook = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        insertStock(notebook.Id, 'PAULISTA', 15);

        TechLarInventoryService.TransferRequest sameStore = requestFor(notebook.Id, 'PAULISTA', 'PAULISTA', 1);
        try {
            TechLarInventoryController.transferStock(sameStore);
            System.assert(false, 'Deveria recusar a mesma loja');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('diferentes'));
        }

        TechLarInventoryService.TransferRequest invalidQuantity = requestFor(notebook.Id, 'PAULISTA', 'MORUMBI', 0);
        try {
            TechLarInventoryController.transferStock(invalidQuantity);
            System.assert(false, 'Deveria recusar quantidade inválida');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('maior que zero'));
        }
    }

    private static Id storeId(String code) {
        return [SELECT Id FROM Loja__c WHERE Codigo__c = :code LIMIT 1].Id;
    }

    private static void insertStock(Id productId, String storeCode, Integer quantity) {
        insert new Estoque__c(
            Produto__c = productId,
            Loja__c = storeId(storeCode),
            Quantidade_Disponivel__c = quantity,
            Chave__c = 'TL-NB-001-' + storeCode
        );
    }

    private static TechLarInventoryService.TransferRequest requestFor(Id productId, String originCode, String destinationCode, Decimal quantity) {
        TechLarInventoryService.TransferRequest request = new TechLarInventoryService.TransferRequest();
        request.productId = productId;
        request.originStoreId = storeId(originCode);
        request.destinationStoreId = storeId(destinationCode);
        request.quantity = quantity;
        return request;
    }
}
