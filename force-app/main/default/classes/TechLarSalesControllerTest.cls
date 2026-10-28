@IsTest
private class TechLarSalesControllerTest {
    private class ViaCepSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"cep":"01310-100","logradouro":"Avenida Paulista","bairro":"Bela Vista",' +
                '"localidade":"São Paulo","uf":"SP"}'
            );
            return res;
        }
    }

    private class ViaCepNotFoundMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"erro": true}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account account = new Account(
            Name = 'Ana Souza',
            Phone = '11999990001',
            CPF__c = '111.111.111-11',
            ClienteTechLar__c = true,
            BillingStreet = 'Av. Paulista, 1000',
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingPostalCode = '01310-100',
            BillingCountry = 'Brazil'
        );
        insert account;

        Contact customer = new Contact(
            AccountId = account.Id,
            FirstName = 'Ana',
            LastName = 'Souza',
            Email = 'ana.souza@techlar.example',
            Phone = '11999990001',
            CPF__c = '111.111.111-11',
            MailingStreet = 'Av. Paulista, 1000',
            MailingCity = 'São Paulo',
            MailingState = 'SP',
            MailingPostalCode = '01310-100',
            MailingCountry = 'Brazil'
        );
        insert customer;

        Product2 notebook = new Product2(
            Name = 'Notebook TechLar X',
            ProductCode = 'TL-NB-001',
            IsActive = true,
            ClienteTechLar__c = true,
            Description = 'Notebook para uso profissional'
        );
        Product2 mouse = new Product2(
            Name = 'Mouse Gamer TechLar',
            ProductCode = 'TL-MS-001',
            IsActive = true,
            ClienteTechLar__c = true
        );
        insert new List<Product2>{ notebook, mouse };

        Id pbId = Test.getStandardPricebookId();
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pbId, Product2Id = notebook.Id, UnitPrice = 4999, IsActive = true),
            new PricebookEntry(Pricebook2Id = pbId, Product2Id = mouse.Id, UnitPrice = 299, IsActive = true)
        };
    }

    @IsTest
    static void searchCustomersByNameAndCpf() {
        Test.startTest();
        List<TechLarSalesService.CustomerDTO> byName = TechLarSalesController.searchCustomers('Ana');
        List<TechLarSalesService.CustomerDTO> byCpf = TechLarSalesController.searchCustomers('111.111');
        List<TechLarSalesService.CustomerDTO> recent = TechLarSalesController.searchCustomers('');
        Test.stopTest();

        System.assertEquals(1, byName.size(), 'Deve localizar Ana Souza pelo nome da Account');
        System.assertEquals(1, byCpf.size(), 'Deve localizar o cliente pelo CPF da Account');
        System.assert(recent.size() >= 1, 'Busca vazia deve retornar clientes recentes');
        System.assertEquals('ana.souza@techlar.example', byName[0].email);
        System.assertNotEquals(null, byName[0].accountId);
        System.assertEquals('111.111.111-11', byCpf[0].cpf);
    }

    @IsTest
    static void createCustomerPersistsAccountAndContact() {
        TechLarSalesService.CustomerDTO input = new TechLarSalesService.CustomerDTO();
        input.firstName = 'Bruno';
        input.lastName = 'Lima';
        input.email = 'bruno.lima@techlar.example';
        input.phone = '21988887777';
        input.cpf = '222.222.222-22';
        input.mailingCity = 'Rio de Janeiro';
        input.mailingState = 'RJ';

        Test.startTest();
        TechLarSalesService.CustomerDTO created = TechLarSalesController.createCustomer(input);
        Test.stopTest();

        System.assertNotEquals(null, created.accountId);
        Account storedAccount = [
            SELECT Name, CPF__c, ClienteTechLar__c
            FROM Account
            WHERE Id = :created.accountId
        ];
        System.assertEquals('Bruno Lima', storedAccount.Name);
        System.assertEquals('222.222.222-22', storedAccount.CPF__c);
        System.assertEquals(true, storedAccount.ClienteTechLar__c);
        Contact stored = [SELECT AccountId, Email, CPF__c FROM Contact WHERE AccountId = :created.accountId LIMIT 1];
        System.assertEquals('222.222.222-22', stored.CPF__c);
        System.assertEquals(created.accountId, stored.AccountId);
    }

    @IsTest
    static void createCustomerRequiresLastName() {
        TechLarSalesService.CustomerDTO input = new TechLarSalesService.CustomerDTO();
        input.firstName = 'SemSobrenome';

        try {
            TechLarSalesController.createCustomer(input);
            System.assert(false, 'Deveria exigir sobrenome');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('sobrenome') || ex.getMessage().contains('Script-thrown'),
                ex.getMessage()
            );
        }
    }

    @IsTest
    static void searchProductsReturnsCatalogPrices() {
        Test.startTest();
        List<TechLarSalesService.ProductDTO> allProducts = TechLarSalesController.searchProducts('');
        List<TechLarSalesService.ProductDTO> notebook = TechLarSalesController.searchProducts('Notebook');
        Test.stopTest();

        System.assert(allProducts.size() >= 2, 'Catálogo mock deve listar os produtos ativos');
        System.assertEquals(1, notebook.size());
        System.assertEquals(4999, notebook[0].unitPrice);
        System.assertNotEquals(null, notebook[0].pricebookEntryId);
        Product2 stored = [SELECT Id FROM Product2 WHERE ProductCode = 'TL-NB-001' LIMIT 1];
        TechLarSalesService.ProductDTO fromStock = TechLarSalesController.getCatalogProduct(stored.Id);
        System.assertEquals(notebook[0].pricebookEntryId, fromStock.pricebookEntryId);
        System.assertEquals(4999, fromStock.unitPrice);
    }

    @IsTest
    static void createSalePersistsOrderAndItems() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        PricebookEntry notebook = [
            SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-NB-001' LIMIT 1
        ];
        PricebookEntry mouse = [
            SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-MS-001' LIMIT 1
        ];

        TechLarSalesService.SaleRequest request = newRequest(customer.Id, 'Retirada na Loja');
        request.items.add(item(notebook.Id, 1));
        request.items.add(item(mouse.Id, 2));

        Test.startTest();
        TechLarSalesService.SaleResult result = TechLarSalesController.createSale(request);
        Test.stopTest();

        System.assertNotEquals(null, result.orderId);
        System.assertEquals(4999 + 598, result.itemsTotal);
        System.assertEquals(0, result.freightTotal);
        System.assertEquals('Activated', [SELECT Status FROM Order WHERE Id = :result.orderId].Status);
        System.assertEquals(2, [SELECT COUNT() FROM OrderItem WHERE OrderId = :result.orderId]);
        Order stored = [
            SELECT AccountId, CanalVenda__c, ModalidadeRecebimento__c, ClienteTechLar__c, Loja__c
            FROM Order
            WHERE Id = :result.orderId
        ];
        System.assertEquals('Loja Física', stored.CanalVenda__c);
        System.assertEquals('Retirada na Loja', stored.ModalidadeRecebimento__c);
        System.assertEquals(customer.Id, stored.AccountId);
        System.assertEquals(true, stored.ClienteTechLar__c);
        System.assertEquals(null, stored.Loja__c);
    }

    @IsTest
    static void createSaleStoresTheAppStoreWithoutAPicker() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        PricebookEntry notebook = [
            SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-NB-001' LIMIT 1
        ];
        insert new List<Loja__c>{
            new Loja__c(Name = 'TechLar Paulista', Codigo__c = 'PAULISTA', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Morumbi', Codigo__c = 'MORUMBI', Cidade__c = 'São Paulo', Status__c = 'Ativa'),
            new Loja__c(Name = 'TechLar Santana', Codigo__c = 'SANTANA', Cidade__c = 'São Paulo', Status__c = 'Ativa')
        };
        Map<String, Id> storeByApp = new Map<String, Id>();
        for (Loja__c store : [SELECT Id, Codigo__c FROM Loja__c]) {
            storeByApp.put(store.Codigo__c, store.Id);
        }

        assertSaleStore(customer.Id, notebook.Id, 'TechLar_Paulista', storeByApp.get('PAULISTA'));
        assertSaleStore(customer.Id, notebook.Id, 'TechLar_Morumbi', storeByApp.get('MORUMBI'));
        assertSaleStore(customer.Id, notebook.Id, 'TechLar_Santana', storeByApp.get('SANTANA'));
        assertSaleStore(customer.Id, notebook.Id, 'TechLar', null);
        assertSaleStore(customer.Id, notebook.Id, 'TechLar_Operations', null);
    }

    @IsTest
    static void createSaleRejectsEmptyCart() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        TechLarSalesService.SaleRequest request = newRequest(customer.Id, 'Retirada na Loja');

        try {
            TechLarSalesController.createSale(request);
            System.assert(false, 'Carrinho vazio não deve criar pedido');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('produto') || ex.getMessage().contains('Script-thrown'),
                ex.getMessage()
            );
            System.assertEquals(0, [SELECT COUNT() FROM Order]);
        }
    }

    @IsTest
    static void createSaleRequiresAddressWhenDelivery() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        PricebookEntry mouse = [
            SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-MS-001' LIMIT 1
        ];
        TechLarSalesService.SaleRequest request = newRequest(customer.Id, 'Entrega');
        request.items.add(item(mouse.Id, 1));

        try {
            TechLarSalesController.createSale(request);
            System.assert(false, 'Entrega sem endereço deve falhar');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('endereço') || ex.getMessage().contains('Script-thrown'),
                ex.getMessage()
            );
            System.assertEquals(0, [SELECT COUNT() FROM Order]);
        }
    }

    @IsTest
    static void createSaleDeliveryRecalculatesFreight() {
        Account customer = [SELECT Id FROM Account WHERE CPF__c = '111.111.111-11' LIMIT 1];
        PricebookEntry mouse = [
            SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-MS-001' LIMIT 1
        ];
        TechLarSalesService.SaleRequest request = newRequest(customer.Id, 'Entrega');
        request.shippingStreet = 'Av. Paulista, 1000';
        request.shippingCity = 'São Paulo';
        request.shippingState = 'SP';
        request.shippingPostalCode = '01310-100';
        request.items.add(item(mouse.Id, 1));

        Test.startTest();
        TechLarSalesService.SaleResult result = TechLarSalesController.createSale(request);
        Test.stopTest();

        System.assertEquals(19.90, result.freightTotal);
        System.assertEquals(3, result.prazoEntregaDias);
        System.assertEquals(299 + 19.90, result.grandTotal);
        Order stored = [SELECT ValorFrete__c, PrazoEntregaDias__c, ShippingCity FROM Order WHERE Id = :result.orderId];
        System.assertEquals(19.90, stored.ValorFrete__c);
        System.assertEquals('São Paulo', stored.ShippingCity);
    }

    @IsTest
    static void consultarCepReturnsAddressAndFreight() {
        Test.setMock(HttpCalloutMock.class, new ViaCepSuccessMock());
        Test.startTest();
        TechLarCepService.EnderecoDTO dto = TechLarSalesController.consultarCep('01310-100');
        Test.stopTest();

        System.assertEquals('São Paulo', dto.localidade);
        System.assertEquals('SP', dto.uf);
        System.assertEquals(19.90, dto.valorFrete);
        System.assertEquals(3, dto.prazoDias);
    }

    @IsTest
    static void consultarCepNotFound() {
        Test.setMock(HttpCalloutMock.class, new ViaCepNotFoundMock());
        Test.startTest();
        try {
            TechLarSalesController.consultarCep('00000000');
            System.assert(false, 'CEP inexistente deve falhar');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('não encontrado') || ex.getMessage().contains('Script-thrown'),
                ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void cotarFreteByRegion() {
        TechLarCepService.FreteDTO sp = TechLarSalesController.cotarFrete('SP');
        TechLarCepService.FreteDTO rs = TechLarSalesController.cotarFrete('RS');
        TechLarCepService.FreteDTO am = TechLarSalesController.cotarFrete('AM');
        System.assertEquals(19.90, sp.valorFrete);
        System.assertEquals(29.90, rs.valorFrete);
        System.assertEquals(49.90, am.valorFrete);
        System.assertEquals(8, am.prazoDias);
    }

    private static void assertSaleStore(Id accountId, Id pricebookEntryId, String appName, Id expectedStoreId) {
        TechLarSalesService.appDeveloperNameOverride = appName;
        TechLarSalesService.SaleRequest request = newRequest(accountId, 'Retirada na Loja');
        request.items.add(item(pricebookEntryId, 1));
        TechLarSalesService.SaleResult result = TechLarSalesController.createSale(request);
        Order stored = [SELECT Loja__c FROM Order WHERE Id = :result.orderId];
        System.assertEquals(expectedStoreId, stored.Loja__c, appName);
    }

    private static TechLarSalesService.SaleRequest newRequest(Id accountId, String modalidade) {
        TechLarSalesService.SaleRequest request = new TechLarSalesService.SaleRequest();
        request.accountId = accountId;
        request.modalidadeRecebimento = modalidade;
        request.items = new List<TechLarSalesService.SaleItemRequest>();
        return request;
    }

    private static TechLarSalesService.SaleItemRequest item(Id pricebookEntryId, Decimal quantity) {
        TechLarSalesService.SaleItemRequest row = new TechLarSalesService.SaleItemRequest();
        row.pricebookEntryId = pricebookEntryId;
        row.quantity = quantity;
        return row;
    }
}
