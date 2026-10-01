@IsTest
private class TechLarServiceControllerTest {
    @TestSetup
    static void setupData() {
        Account account = new Account(
            Name = 'Ana Souza',
            Phone = '11999990001',
            CPF__c = '111.111.111-11',
            ClienteTechLar__c = true,
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingCountry = 'Brazil'
        );
        insert account;

        insert new Contact(
            AccountId = account.Id,
            FirstName = 'Ana',
            LastName = 'Souza',
            Email = 'ana.souza@techlar.example',
            CPF__c = '111.111.111-11'
        );

        Product2 notebook = new Product2(
            Name = 'Notebook TechLar X',
            ProductCode = 'TL-NB-001',
            IsActive = true,
            ClienteTechLar__c = true
        );
        insert notebook;

        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = notebook.Id,
            UnitPrice = 4999,
            IsActive = true
        );
        insert pbe;

        Order pedido = new Order(
            AccountId = account.Id,
            ClienteTechLar__c = true,
            EffectiveDate = Date.today().addDays(-10),
            Status = 'Draft',
            Pricebook2Id = pbId,
            CanalVenda__c = 'Loja Física'
        );
        insert pedido;
        insert new OrderItem(
            OrderId = pedido.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = notebook.Id,
            Quantity = 1,
            UnitPrice = 4999
        );
        pedido.Status = 'Activated';
        update pedido;
    }

    @IsTest
    static void getOrdersReturnsPurchaseHistory() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        Test.startTest();
        List<TechLarServiceService.OrderDTO> orders = TechLarServiceController.getOrders(customer.Id);
        Test.stopTest();

        System.assertEquals(1, orders.size());
        System.assertEquals(1, orders[0].items.size());
        System.assertEquals('Notebook TechLar X', orders[0].items[0].productName);
    }

    @IsTest
    static void createCaseLinksCustomerAndPurchase() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        Order pedido = [SELECT Id FROM Order WHERE AccountId = :customer.Id LIMIT 1];
        OrderItem item = [SELECT Id, Product2Id FROM OrderItem WHERE OrderId = :pedido.Id LIMIT 1];

        TechLarServiceService.CaseRequest request = newRequest(customer.Id, pedido.Id, item.Id, item.Product2Id);

        Test.startTest();
        TechLarServiceService.CaseResult result = TechLarServiceController.createCase(request);
        Test.stopTest();

        System.assertNotEquals(null, result.caseId);
        Case stored = [
            SELECT AccountId, Pedido__c, PedidoItem__c, Produto__c, MotivoPosVenda__c,
                   ClienteTechLar__c, Status, Owner.Type, Owner.Name
            FROM Case
            WHERE Id = :result.caseId
        ];
        System.assertEquals(customer.Id, stored.AccountId);
        System.assertEquals(pedido.Id, stored.Pedido__c);
        System.assertEquals(item.Id, stored.PedidoItem__c);
        System.assertEquals(item.Product2Id, stored.Produto__c);
        System.assertEquals('Produto com defeito', stored.MotivoPosVenda__c);
        System.assertEquals(true, stored.ClienteTechLar__c);
        TechLarServiceService.CaseResult reloaded = TechLarServiceController.getCase(result.caseId);
        System.assertEquals(result.caseId, reloaded.caseId);
        System.assertEquals('Working', stored.Status, 'Flow deve colocar o Case em análise');
        System.assert(
            String.valueOf(stored.OwnerId).startsWith('00G'),
            'Flow deve atribuir a fila de Pós-venda. OwnerId=' + stored.OwnerId
        );
        Group fila = [SELECT Name FROM Group WHERE Id = :stored.OwnerId];
        System.assert(
            fila.Name.contains('Pós-venda') || fila.Name.contains('Pos-venda') || fila.Name.contains('Pós'),
            fila.Name
        );
    }

    @IsTest
    static void createCaseRejectsMissingOrder() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        TechLarServiceService.CaseRequest request = new TechLarServiceService.CaseRequest();
        request.accountId = customer.Id;
        request.motivo = 'Produto com defeito';
        request.description = 'Apresentou defeito na tela.';

        try {
            TechLarServiceController.createCase(request);
            System.assert(false, 'Sem pedido o Case não deve ser criado');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('pedido') || ex.getMessage().contains('Script-thrown'),
                ex.getMessage()
            );
            System.assertEquals(0, [SELECT COUNT() FROM Case]);
        }
    }

    @IsTest
    static void resolveCaseClosesRecord() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        Order pedido = [SELECT Id FROM Order WHERE AccountId = :customer.Id LIMIT 1];
        OrderItem item = [SELECT Id, Product2Id FROM OrderItem WHERE OrderId = :pedido.Id LIMIT 1];
        TechLarServiceService.CaseResult created = TechLarServiceController.createCase(
            newRequest(customer.Id, pedido.Id, item.Id, item.Product2Id)
        );

        Test.startTest();
        TechLarServiceService.CaseResult resolved = TechLarServiceController.resolveCase(
            created.caseId,
            'Troca aprovada'
        );
        Test.stopTest();

        System.assertEquals('Closed', resolved.status);
        System.assertEquals('Resolvido', resolved.statusLabel);
        System.assertEquals('Troca aprovada', [SELECT ResultadoAtendimento__c FROM Case WHERE Id = :created.caseId].ResultadoAtendimento__c);
    }

    @IsTest
    static void controllerSurfacesValidationErrors() {
        try {
            TechLarServiceController.getOrders(null);
            System.assert(false, 'Cliente vazio deve falhar');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('cliente') || ex.getMessage().contains('Script-thrown'), ex.getMessage());
        }
        try {
            TechLarServiceController.getCase(null);
            System.assert(false, 'Case vazio deve falhar');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('atendimento') || ex.getMessage().contains('Script-thrown'), ex.getMessage());
        }
        try {
            TechLarServiceController.resolveCase(null, 'Troca aprovada');
            System.assert(false, 'Case vazio deve falhar');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('atendimento') || ex.getMessage().contains('Script-thrown'), ex.getMessage());
        }
    }

    private static TechLarServiceService.CaseRequest newRequest(Id accountId, Id orderId, Id orderItemId, Id productId) {
        TechLarServiceService.CaseRequest request = new TechLarServiceService.CaseRequest();
        request.accountId = accountId;
        request.orderId = orderId;
        request.orderItemId = orderItemId;
        request.productId = productId;
        request.motivo = 'Produto com defeito';
        request.description = 'O notebook apresentou defeito na tela após a compra em loja.';
        return request;
    }
}
