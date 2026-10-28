public with sharing class TechLarSalesService {
    public static final String CANAL_LOJA_FISICA = 'Loja Física';
    @TestVisible
    private static String appDeveloperNameOverride;
    private static final Map<String, String> STORE_CODE_BY_APP = new Map<String, String>{
        'TechLar_Paulista' => 'PAULISTA',
        'TechLar_Morumbi' => 'MORUMBI',
        'TechLar_Santana' => 'SANTANA'
    };
    public static final String MODALIDADE_RETIRADA = 'Retirada na Loja';
    public static final String MODALIDADE_ENTREGA = 'Entrega';

    public class CustomerDTO {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String cpf { get; set; }
        @AuraEnabled public String mailingStreet { get; set; }
        @AuraEnabled public String mailingCity { get; set; }
        @AuraEnabled public String mailingState { get; set; }
        @AuraEnabled public String mailingPostalCode { get; set; }
    }

    public class ProductDTO {
        @AuraEnabled public Id pricebookEntryId { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
    }

    public class SaleItemRequest {
        @AuraEnabled public Id pricebookEntryId { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
    }

    public class SaleRequest {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String modalidadeRecebimento { get; set; }
        @AuraEnabled public String shippingStreet { get; set; }
        @AuraEnabled public String shippingCity { get; set; }
        @AuraEnabled public String shippingState { get; set; }
        @AuraEnabled public String shippingPostalCode { get; set; }
        @AuraEnabled public List<SaleItemRequest> items { get; set; }
    }

    public class SaleResult {
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public Decimal itemsTotal { get; set; }
        @AuraEnabled public Decimal freightTotal { get; set; }
        @AuraEnabled public Decimal grandTotal { get; set; }
        @AuraEnabled public String modalidadeRecebimento { get; set; }
        @AuraEnabled public Integer prazoEntregaDias { get; set; }
        @AuraEnabled public String message { get; set; }
    }

    public static List<CustomerDTO> searchCustomers(String searchTerm) {
        String likeTerm = toLike(searchTerm);
        List<Account> records;

        if (likeTerm == null) {
            records = [
                SELECT Id, Name, Phone, CPF__c, PersonEmail, PersonContactId,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       (SELECT Id, FirstName, LastName, Email FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
                FROM Account
                WHERE ClienteTechLar__c = TRUE
                ORDER BY LastModifiedDate DESC
                LIMIT 20
            ];
        } else {
            Set<Id> accountIds = new Set<Id>();
            for (Account match : [
                SELECT Id
                FROM Account
                WHERE ClienteTechLar__c = TRUE
                  AND (
                      Name LIKE :likeTerm
                      OR Phone LIKE :likeTerm
                      OR CPF__c LIKE :likeTerm
                      OR PersonEmail LIKE :likeTerm
                  )
                LIMIT 50
            ]) {
                accountIds.add(match.Id);
            }
            for (Contact match : [
                SELECT AccountId
                FROM Contact
                WHERE AccountId != NULL
                  AND (Email LIKE :likeTerm OR CPF__c LIKE :likeTerm)
                LIMIT 50
            ]) {
                accountIds.add(match.AccountId);
            }
            if (accountIds.isEmpty()) {
                return new List<CustomerDTO>();
            }
            records = [
                SELECT Id, Name, Phone, CPF__c, PersonEmail, PersonContactId,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       (SELECT Id, FirstName, LastName, Email FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
                FROM Account
                WHERE Id IN :accountIds AND ClienteTechLar__c = TRUE
                ORDER BY Name
                LIMIT 20
            ];
        }

        List<CustomerDTO> result = new List<CustomerDTO>();
        for (Account record : records) {
            result.add(toCustomer(record));
        }
        return result;
    }

    public static CustomerDTO createCustomer(CustomerDTO input) {
        if (input == null || String.isBlank(input.lastName)) {
            throw handled('Informe o sobrenome do cliente.');
        }

        String fullName = joinName(input.firstName, input.lastName);
        Account account = new Account(
            Name = fullName,
            RecordTypeId = getTechLarAccountRecordTypeId(),
            Phone = input.phone,
            CPF__c = blankToNull(input.cpf),
            ClienteTechLar__c = true,
            BillingStreet = input.mailingStreet,
            BillingCity = input.mailingCity,
            BillingState = input.mailingState,
            BillingPostalCode = input.mailingPostalCode,
            BillingCountry = 'Brazil'
        );

        try {
            insert account;
        } catch (DmlException ex) {
            throw handled(friendlyDml(ex, 'Não foi possível cadastrar o cliente. Verifique se o CPF já existe.'));
        }

        Contact contact = new Contact(
            AccountId = account.Id,
            FirstName = input.firstName,
            LastName = input.lastName,
            Email = input.email,
            Phone = input.phone,
            CPF__c = blankToNull(input.cpf),
            MailingStreet = input.mailingStreet,
            MailingCity = input.mailingCity,
            MailingState = input.mailingState,
            MailingPostalCode = input.mailingPostalCode,
            MailingCountry = 'Brazil'
        );
        try {
            insert contact;
        } catch (DmlException ex) {
            throw handled(friendlyDml(ex, 'A conta foi criada, mas o contato complementar falhou.'));
        }

        return toCustomer(loadAccount(account.Id));
    }

    public static List<ProductDTO> searchProducts(String searchTerm) {
        Id catalogId = getCatalogPricebookId();
        String likeTerm = toLike(searchTerm);
        List<PricebookEntry> entries;

        if (likeTerm == null) {
            entries = [
                SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Description
                FROM PricebookEntry
                WHERE IsActive = TRUE
                  AND Product2.IsActive = TRUE
                  AND Product2.ClienteTechLar__c = TRUE
                  AND Pricebook2Id = :catalogId
                ORDER BY Product2.Name
                LIMIT 30
            ];
        } else {
            entries = [
                SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Description
                FROM PricebookEntry
                WHERE IsActive = TRUE
                  AND Product2.IsActive = TRUE
                  AND Product2.ClienteTechLar__c = TRUE
                  AND Pricebook2Id = :catalogId
                  AND (Product2.Name LIKE :likeTerm OR Product2.ProductCode LIKE :likeTerm)
                ORDER BY Product2.Name
                LIMIT 30
            ];
        }

        List<ProductDTO> result = new List<ProductDTO>();
        for (PricebookEntry entry : entries) {
            ProductDTO dto = new ProductDTO();
            dto.pricebookEntryId = entry.Id;
            dto.productId = entry.Product2Id;
            dto.name = entry.Product2.Name;
            dto.productCode = entry.Product2.ProductCode;
            dto.description = entry.Product2.Description;
            dto.unitPrice = entry.UnitPrice;
            result.add(dto);
        }
        return result;
    }

    public static ProductDTO getCatalogProduct(Id productId) {
        if (productId == null) {
            throw handled('O produto informado não existe.');
        }
        Id catalogId = getCatalogPricebookId();
        List<PricebookEntry> entries = [
            SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Description
            FROM PricebookEntry
            WHERE IsActive = TRUE
              AND Product2.IsActive = TRUE
              AND Product2Id = :productId
              AND Pricebook2Id = :catalogId
            LIMIT 1
        ];
        if (entries.isEmpty()) {
            throw handled('Este produto não está no catálogo de vendas.');
        }
        PricebookEntry entry = entries[0];
        ProductDTO dto = new ProductDTO();
        dto.pricebookEntryId = entry.Id;
        dto.productId = entry.Product2Id;
        dto.name = entry.Product2.Name;
        dto.productCode = entry.Product2.ProductCode;
        dto.description = entry.Product2.Description;
        dto.unitPrice = entry.UnitPrice;
        return dto;
    }

    public static SaleResult createSale(SaleRequest request) {
        validateSale(request);

        Account customer = loadAccount(request.accountId);
        if (customer == null) {
            throw handled('Selecione um cliente para concluir a venda.');
        }

        Map<Id, PricebookEntry> entries = loadEntries(request.items);
        Decimal itemsTotal = 0;
        List<OrderItem> orderItems = new List<OrderItem>();

        for (SaleItemRequest item : request.items) {
            PricebookEntry entry = entries.get(item.pricebookEntryId);
            if (entry == null) {
                throw handled('Um dos produtos selecionados não está disponível no catálogo.');
            }
            if (entry.UnitPrice == null || entry.UnitPrice < 0) {
                throw handled('O produto ' + entry.Product2.Name + ' não possui preço válido.');
            }
            Decimal quantity = item.quantity;
            itemsTotal += quantity * entry.UnitPrice;

            OrderItem oi = new OrderItem();
            oi.PricebookEntryId = entry.Id;
            oi.Product2Id = entry.Product2Id;
            oi.Quantity = quantity;
            oi.UnitPrice = entry.UnitPrice;
            orderItems.add(oi);
        }

        Decimal freightTotal = 0;
        Integer prazo = null;
        if (request.modalidadeRecebimento == MODALIDADE_ENTREGA) {
            TechLarCepService.FreteDTO frete = TechLarCepService.cotarFrete(request.shippingState);
            freightTotal = frete.valorFrete;
            prazo = frete.prazoDias;
        }

        Order pedido = new Order();
        pedido.AccountId = customer.Id;
        pedido.ClienteTechLar__c = true;
        Id relatedContactId = relatedContactId(customer);
        if (relatedContactId != null) {
            pedido.BillToContactId = relatedContactId;
            pedido.ShipToContactId = relatedContactId;
        }
        pedido.EffectiveDate = Date.today();
        pedido.Status = 'Draft';
        pedido.Pricebook2Id = entries.values()[0].Pricebook2Id;
        pedido.CanalVenda__c = CANAL_LOJA_FISICA;
        pedido.Loja__c = storeIdForCurrentApp();
        pedido.ModalidadeRecebimento__c = request.modalidadeRecebimento;
        pedido.ValorFrete__c = freightTotal;
        pedido.PrazoEntregaDias__c = prazo;
        pedido.BillingCountry = 'Brazil';
        pedido.ShippingCountry = 'Brazil';

        if (request.modalidadeRecebimento == MODALIDADE_ENTREGA) {
            pedido.ShippingStreet = request.shippingStreet;
            pedido.ShippingCity = request.shippingCity;
            pedido.ShippingState = request.shippingState;
            pedido.ShippingPostalCode = request.shippingPostalCode;
        } else {
            pedido.ShippingStreet = 'Retirada na loja TechLar';
            pedido.ShippingCity = customer.BillingCity;
            pedido.ShippingState = customer.BillingState;
            pedido.ShippingPostalCode = customer.BillingPostalCode;
        }

        try {
            insert pedido;
        } catch (DmlException ex) {
            if (isContractRequired(ex)) {
                pedido.ContractId = createActivatedContract(customer.Id);
                insert pedido;
            } else {
                throw handled(friendlyDml(ex, 'Não foi possível gravar o pedido. Verifique se Orders está habilitado no org.'));
            }
        }

        try {
            for (OrderItem oi : orderItems) {
                oi.OrderId = pedido.Id;
            }
            insert orderItems;
            pedido.Status = 'Activated';
            update pedido;
        } catch (DmlException ex) {
            throw handled(friendlyDml(ex, 'Não foi possível gravar o pedido. Verifique se Orders está habilitado no org.'));
        }

        pedido = [SELECT Id, OrderNumber FROM Order WHERE Id = :pedido.Id];

        SaleResult result = new SaleResult();
        result.orderId = pedido.Id;
        result.orderNumber = pedido.OrderNumber;
        result.itemsTotal = itemsTotal;
        result.freightTotal = freightTotal;
        result.grandTotal = itemsTotal + freightTotal;
        result.modalidadeRecebimento = request.modalidadeRecebimento;
        result.prazoEntregaDias = prazo;
        result.message = 'Venda ' + pedido.OrderNumber + ' registrada com sucesso.';
        return result;
    }

    private static Id storeIdForCurrentApp() {
        String appName = appDeveloperNameOverride;
        if (String.isBlank(appName)) {
            appName = currentAppDeveloperName();
        }
        String storeCode = STORE_CODE_BY_APP.get(appName);
        if (String.isBlank(storeCode)) {
            return null;
        }
        List<Loja__c> stores = [SELECT Id FROM Loja__c WHERE Codigo__c = :storeCode LIMIT 1];
        return stores.isEmpty() ? null : stores[0].Id;
    }

    private static String currentAppDeveloperName() {
        try {
            List<UserAppInfo> infos = [
                SELECT AppDefinitionId, FormFactor
                FROM UserAppInfo
                WHERE UserId = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            String appDefinitionId;
            for (UserAppInfo info : infos) {
                if (info.FormFactor == 'Large') {
                    appDefinitionId = info.AppDefinitionId;
                    break;
                }
            }
            if (String.isBlank(appDefinitionId) && !infos.isEmpty()) {
                appDefinitionId = infos[0].AppDefinitionId;
            }
            if (String.isBlank(appDefinitionId)) {
                return null;
            }
            List<AppDefinition> apps = [
                SELECT DeveloperName
                FROM AppDefinition
                WHERE DurableId = :appDefinitionId
                LIMIT 1
            ];
            return apps.isEmpty() ? null : apps[0].DeveloperName;
        } catch (Exception ex) {
            return null;
        }
    }

    private static void validateSale(SaleRequest request) {
        if (request == null || request.accountId == null) {
            throw handled('Selecione um cliente para concluir a venda.');
        }
        if (request.items == null || request.items.isEmpty()) {
            throw handled('Adicione pelo menos um produto ao carrinho.');
        }
        if (String.isBlank(request.modalidadeRecebimento)) {
            throw handled('Selecione a modalidade de recebimento.');
        }
        if (request.modalidadeRecebimento != MODALIDADE_RETIRADA &&
            request.modalidadeRecebimento != MODALIDADE_ENTREGA) {
            throw handled('Modalidade de recebimento inválida.');
        }
        if (request.modalidadeRecebimento == MODALIDADE_ENTREGA) {
            if (String.isBlank(request.shippingStreet) ||
                String.isBlank(request.shippingCity) ||
                String.isBlank(request.shippingState) ||
                String.isBlank(request.shippingPostalCode)) {
                throw handled('Informe o endereço completo para entrega.');
            }
        }
        for (SaleItemRequest item : request.items) {
            if (item == null || item.pricebookEntryId == null) {
                throw handled('Há um item inválido no carrinho.');
            }
            if (item.quantity == null || item.quantity <= 0) {
                throw handled('A quantidade deve ser maior que zero.');
            }
        }
    }

    private static Boolean isContractRequired(DmlException ex) {
        String message = ex.getMessage() + ' ' + ex.getDmlMessage(0);
        return message.contains('Contract') || message.contains('contrato');
    }

    private static Id createActivatedContract(Id accountId) {
        Contract contract = new Contract(
            AccountId = accountId,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        return contract.Id;
    }

    private static Map<Id, PricebookEntry> loadEntries(List<SaleItemRequest> items) {
        Set<Id> ids = new Set<Id>();
        for (SaleItemRequest item : items) {
            ids.add(item.pricebookEntryId);
        }
        return new Map<Id, PricebookEntry>([
            SELECT Id, UnitPrice, Product2Id, Product2.Name, IsActive, Pricebook2Id
            FROM PricebookEntry
            WHERE Id IN :ids AND IsActive = TRUE
        ]);
    }

    private static Id getCatalogPricebookId() {
        if (!Test.isRunningTest()) {
            List<Pricebook2> techlarBooks = [
                SELECT Id
                FROM Pricebook2
                WHERE Name = 'TechLar Pricebook' AND IsActive = TRUE
                LIMIT 1
            ];
            if (!techlarBooks.isEmpty()) {
                return techlarBooks[0].Id;
            }
        }
        return getStandardPricebookId();
    }

    private static Id getStandardPricebookId() {
        if (Test.isRunningTest()) {
            return Test.getStandardPricebookId();
        }
        return [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
    }

    private static Account loadAccount(Id accountId) {
        if (accountId == null) {
            return null;
        }
        List<Account> records = [
            SELECT Id, Name, Phone, CPF__c, PersonEmail, PersonContactId,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode,
                   (SELECT Id, FirstName, LastName, Email FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account
            WHERE Id = :accountId AND ClienteTechLar__c = TRUE
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    private static Id getTechLarAccountRecordTypeId() {
        List<RecordType> recordTypes = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Account' AND DeveloperName = 'TechLar_PF'
            LIMIT 1
        ];
        return recordTypes.isEmpty() ? null : recordTypes[0].Id;
    }

    private static Id relatedContactId(Account record) {
        if (record.PersonContactId != null) {
            return record.PersonContactId;
        }
        return record.Contacts.isEmpty() ? null : record.Contacts[0].Id;
    }

    private static CustomerDTO toCustomer(Account record) {
        Contact related = record.Contacts.isEmpty() ? null : record.Contacts[0];
        CustomerDTO dto = new CustomerDTO();
        dto.accountId = record.Id;
        dto.contactId = relatedContactId(record);
        dto.firstName = related == null ? null : related.FirstName;
        dto.lastName = related == null ? null : related.LastName;
        dto.name = record.Name;
        dto.email = String.isBlank(record.PersonEmail)
            ? (related == null ? null : related.Email)
            : record.PersonEmail;
        dto.phone = record.Phone;
        dto.cpf = record.CPF__c;
        dto.mailingStreet = record.BillingStreet;
        dto.mailingCity = record.BillingCity;
        dto.mailingState = record.BillingState;
        dto.mailingPostalCode = record.BillingPostalCode;
        return dto;
    }

    private static String toLike(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return null;
        }
        return '%' + searchTerm.trim() + '%';
    }

    private static String joinName(String firstName, String lastName) {
        if (String.isBlank(firstName)) {
            return lastName.trim();
        }
        return firstName.trim() + ' ' + lastName.trim();
    }

    private static String blankToNull(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    private static String friendlyDml(DmlException ex, String fallback) {
        String message = ex.getDmlMessage(0);
        return String.isBlank(message) ? fallback : message;
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
