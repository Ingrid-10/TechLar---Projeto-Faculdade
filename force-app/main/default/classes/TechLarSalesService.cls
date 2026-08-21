public with sharing class TechLarSalesService {
    public static final String CANAL_LOJA_FISICA = 'Loja Física';
    public static final String MODALIDADE_RETIRADA = 'Retirada na Loja';
    public static final String MODALIDADE_ENTREGA = 'Entrega';

    public class CustomerDTO {
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String cpf;
        @AuraEnabled public String mailingStreet;
        @AuraEnabled public String mailingCity;
        @AuraEnabled public String mailingState;
        @AuraEnabled public String mailingPostalCode;
    }

    public class ProductDTO {
        @AuraEnabled public Id pricebookEntryId;
        @AuraEnabled public Id productId;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal unitPrice;
    }

    public class SaleItemRequest {
        @AuraEnabled public Id pricebookEntryId;
        @AuraEnabled public Decimal quantity;
    }

    public class SaleRequest {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String modalidadeRecebimento;
        @AuraEnabled public String shippingStreet;
        @AuraEnabled public String shippingCity;
        @AuraEnabled public String shippingState;
        @AuraEnabled public String shippingPostalCode;
        @AuraEnabled public List<SaleItemRequest> items;
    }

    public class SaleResult {
        @AuraEnabled public Id orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public Decimal itemsTotal;
        @AuraEnabled public Decimal freightTotal;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public String modalidadeRecebimento;
        @AuraEnabled public Integer prazoEntregaDias;
        @AuraEnabled public String message;
    }

    public static List<CustomerDTO> searchCustomers(String searchTerm) {
        String likeTerm = toLike(searchTerm);
        List<Contact> records;

        if (likeTerm == null) {
            records = [
                SELECT Id, AccountId, FirstName, LastName, Name, Email, Phone, CPF__c,
                       MailingStreet, MailingCity, MailingState, MailingPostalCode
                FROM Contact
                ORDER BY LastModifiedDate DESC
                LIMIT 20
            ];
        } else {
            records = [
                SELECT Id, AccountId, FirstName, LastName, Name, Email, Phone, CPF__c,
                       MailingStreet, MailingCity, MailingState, MailingPostalCode
                FROM Contact
                WHERE Name LIKE :likeTerm
                   OR Email LIKE :likeTerm
                   OR Phone LIKE :likeTerm
                   OR CPF__c LIKE :likeTerm
                ORDER BY Name
                LIMIT 20
            ];
        }

        List<CustomerDTO> result = new List<CustomerDTO>();
        for (Contact record : records) {
            result.add(toCustomer(record));
        }
        return result;
    }

    public static CustomerDTO createCustomer(CustomerDTO input) {
        if (input == null || String.isBlank(input.lastName)) {
            throw handled('Informe o sobrenome do cliente.');
        }

        String fullName = joinName(input.firstName, input.lastName);
        Account account = new Account(Name = fullName);
        insert account;

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
            throw handled(friendlyDml(ex, 'Não foi possível cadastrar o cliente. Verifique se o CPF já existe.'));
        }

        contact = [
            SELECT Id, AccountId, FirstName, LastName, Name, Email, Phone, CPF__c,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode
            FROM Contact
            WHERE Id = :contact.Id
        ];
        return toCustomer(contact);
    }

    public static List<ProductDTO> searchProducts(String searchTerm) {
        Id standardPbId = getStandardPricebookId();
        String likeTerm = toLike(searchTerm);
        List<PricebookEntry> entries;

        if (likeTerm == null) {
            entries = [
                SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Description
                FROM PricebookEntry
                WHERE IsActive = TRUE
                  AND Product2.IsActive = TRUE
                  AND Pricebook2Id = :standardPbId
                ORDER BY Product2.Name
                LIMIT 30
            ];
        } else {
            entries = [
                SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Description
                FROM PricebookEntry
                WHERE IsActive = TRUE
                  AND Product2.IsActive = TRUE
                  AND Pricebook2Id = :standardPbId
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

    public static SaleResult createSale(SaleRequest request) {
        validateSale(request);

        Contact customer = [
            SELECT Id, AccountId, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode
            FROM Contact
            WHERE Id = :request.contactId
            LIMIT 1
        ];
        if (customer.AccountId == null) {
            throw handled('O cliente precisa estar vinculado a uma conta.');
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
        pedido.AccountId = customer.AccountId;
        pedido.BillToContactId = customer.Id;
        pedido.ShipToContactId = customer.Id;
        pedido.EffectiveDate = Date.today();
        pedido.Status = 'Draft';
        pedido.Pricebook2Id = getStandardPricebookId();
        pedido.CanalVenda__c = CANAL_LOJA_FISICA;
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
            pedido.ShippingCity = customer.MailingCity;
            pedido.ShippingState = customer.MailingState;
            pedido.ShippingPostalCode = customer.MailingPostalCode;
        }

        try {
            insert pedido;
        } catch (DmlException ex) {
            if (isContractRequired(ex)) {
                pedido.ContractId = createActivatedContract(customer.AccountId);
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

    private static void validateSale(SaleRequest request) {
        if (request == null || request.contactId == null) {
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
            SELECT Id, UnitPrice, Product2Id, Product2.Name, IsActive
            FROM PricebookEntry
            WHERE Id IN :ids AND IsActive = TRUE
        ]);
    }

    private static Id getStandardPricebookId() {
        if (Test.isRunningTest()) {
            return Test.getStandardPricebookId();
        }
        return [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
    }

    private static CustomerDTO toCustomer(Contact record) {
        CustomerDTO dto = new CustomerDTO();
        dto.contactId = record.Id;
        dto.accountId = record.AccountId;
        dto.firstName = record.FirstName;
        dto.lastName = record.LastName;
        dto.name = record.Name;
        dto.email = record.Email;
        dto.phone = record.Phone;
        dto.cpf = record.CPF__c;
        dto.mailingStreet = record.MailingStreet;
        dto.mailingCity = record.MailingCity;
        dto.mailingState = record.MailingState;
        dto.mailingPostalCode = record.MailingPostalCode;
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
