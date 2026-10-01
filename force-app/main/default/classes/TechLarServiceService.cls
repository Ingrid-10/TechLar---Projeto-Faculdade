public with sharing class TechLarServiceService {
    public static final String MOTIVO_DEFEITO = 'Produto com defeito';
    public static final String MOTIVO_TROCA = 'Solicitação de troca';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String ORIGIN_PHONE = 'Phone';

    private static final Set<String> MOTIVOS = new Set<String>{
        MOTIVO_DEFEITO,
        MOTIVO_TROCA,
        'Problema na entrega',
        'Dúvida sobre pedido',
        'Cancelamento',
        'Outros'
    };

    private static final Set<String> RESULTADOS = new Set<String>{
        'Troca aprovada',
        'Orientação prestada',
        'Sem procedência'
    };

    public class OrderItemDTO {
        @AuraEnabled public Id orderItemId { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String productCode { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal lineTotal { get; set; }
    }

    public class OrderDTO {
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public Date effectiveDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public List<OrderItemDTO> items { get; set; }
    }

    public class CaseRequest {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public Id orderItemId { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String motivo { get; set; }
        @AuraEnabled public String description { get; set; }
    }

    public class CaseResult {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String statusLabel { get; set; }
        @AuraEnabled public String motivo { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public String resultado { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public String message { get; set; }
    }

    public static List<OrderDTO> getOrders(Id accountId) {
        if (accountId == null) {
            throw handled('Selecione um cliente para consultar as compras.');
        }

        List<Order> pedidos = [
            SELECT Id, OrderNumber, EffectiveDate, Status, TotalAmount,
                   (SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Quantity, UnitPrice, TotalPrice
                    FROM OrderItems
                    ORDER BY CreatedDate ASC)
            FROM Order
            WHERE AccountId = :accountId AND ClienteTechLar__c = TRUE
            ORDER BY EffectiveDate DESC, CreatedDate DESC
            LIMIT 50
        ];

        List<OrderDTO> result = new List<OrderDTO>();
        for (Order pedido : pedidos) {
            OrderDTO dto = new OrderDTO();
            dto.orderId = pedido.Id;
            dto.orderNumber = pedido.OrderNumber;
            dto.effectiveDate = pedido.EffectiveDate;
            dto.status = pedido.Status;
            dto.totalAmount = pedido.TotalAmount;
            dto.items = new List<OrderItemDTO>();
            for (OrderItem item : pedido.OrderItems) {
                OrderItemDTO row = new OrderItemDTO();
                row.orderItemId = item.Id;
                row.productId = item.Product2Id;
                row.productName = item.Product2.Name;
                row.productCode = item.Product2.ProductCode;
                row.quantity = item.Quantity;
                row.unitPrice = item.UnitPrice;
                row.lineTotal = item.TotalPrice;
                dto.items.add(row);
            }
            result.add(dto);
        }
        return result;
    }

    public static CaseResult createCase(CaseRequest request) {
        validateCreate(request);

        Account customer = [
            SELECT Id, Name, PersonContactId,
                   (SELECT Id FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account
            WHERE Id = :request.accountId AND ClienteTechLar__c = TRUE
            LIMIT 1
        ];

        Order pedido = [
            SELECT Id, OrderNumber, AccountId, EffectiveDate
            FROM Order
            WHERE Id = :request.orderId AND AccountId = :customer.Id AND ClienteTechLar__c = TRUE
            LIMIT 1
        ];

        OrderItem item = [
            SELECT Id, OrderId, Product2Id, Product2.Name
            FROM OrderItem
            WHERE Id = :request.orderItemId AND OrderId = :pedido.Id
            LIMIT 1
        ];

        if (request.productId != null && request.productId != item.Product2Id) {
            throw handled('O produto selecionado não corresponde ao item do pedido.');
        }

        Case atendimento = new Case();
        atendimento.RecordTypeId = techLarRecordTypeId();
        atendimento.AccountId = customer.Id;
        atendimento.ContactId = relatedContactId(customer);
        atendimento.Origin = ORIGIN_PHONE;
        atendimento.Status = STATUS_NEW;
        atendimento.Subject = request.motivo + ' — ' + item.Product2.Name;
        atendimento.Description = request.description;
        atendimento.ClienteTechLar__c = true;
        atendimento.Pedido__c = pedido.Id;
        atendimento.PedidoItem__c = item.Id;
        atendimento.Produto__c = item.Product2Id;
        atendimento.MotivoPosVenda__c = request.motivo;
        atendimento.DataDaCompra__c = pedido.EffectiveDate;

        try {
            insert atendimento;
        } catch (DmlException ex) {
            throw handled(friendlyDml(ex, 'Não foi possível abrir o atendimento.'));
        }

        Case stored = loadCase(atendimento.Id);
        return toResult(stored, 'Atendimento ' + stored.CaseNumber + ' registrado com sucesso.');
    }

    public static CaseResult resolveCase(Id caseId, String resultado) {
        if (caseId == null) {
            throw handled('Informe o atendimento a concluir.');
        }
        if (String.isBlank(resultado) || !RESULTADOS.contains(resultado)) {
            throw handled('Informe o resultado do atendimento.');
        }

        Case atendimento = [
            SELECT Id
            FROM Case
            WHERE Id = :caseId AND ClienteTechLar__c = TRUE
            LIMIT 1
        ];
        atendimento.ResultadoAtendimento__c = resultado;
        atendimento.Status = STATUS_CLOSED;
        try {
            update atendimento;
        } catch (DmlException ex) {
            throw handled(friendlyDml(ex, 'Não foi possível concluir o atendimento.'));
        }
        return toResult(loadCase(caseId), 'Atendimento concluído.');
    }

    public static CaseResult getCase(Id caseId) {
        if (caseId == null) {
            throw handled('Informe o atendimento.');
        }
        return toResult(loadCase(caseId), null);
    }

    private static void validateCreate(CaseRequest request) {
        if (request == null || request.accountId == null) {
            throw handled('Selecione um cliente para abrir o atendimento.');
        }
        if (request.orderId == null) {
            throw handled('Selecione um pedido para abrir o atendimento.');
        }
        if (request.orderItemId == null) {
            throw handled('Selecione um produto da compra para abrir o atendimento.');
        }
        if (String.isBlank(request.motivo) || !MOTIVOS.contains(request.motivo)) {
            throw handled('Informe o motivo do atendimento.');
        }
        if (String.isBlank(request.description)) {
            throw handled('Descreva o problema do cliente.');
        }
    }

    private static Case loadCase(Id caseId) {
        return [
            SELECT Id, CaseNumber, Status, MotivoPosVenda__c, ResultadoAtendimento__c,
                   Owner.Name, Produto__r.Name, Pedido__r.OrderNumber
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    private static CaseResult toResult(Case record, String message) {
        CaseResult result = new CaseResult();
        result.caseId = record.Id;
        result.caseNumber = record.CaseNumber;
        result.status = record.Status;
        result.statusLabel = statusLabel(record.Status);
        result.motivo = record.MotivoPosVenda__c;
        result.ownerName = record.Owner.Name;
        result.resultado = record.ResultadoAtendimento__c;
        result.productName = record.Produto__r == null ? null : record.Produto__r.Name;
        result.orderNumber = record.Pedido__r == null ? null : record.Pedido__r.OrderNumber;
        result.message = message;
        return result;
    }

    private static String statusLabel(String status) {
        if (status == 'Working') {
            return 'Em análise';
        }
        if (status == 'Closed') {
            return 'Resolvido';
        }
        if (status == 'New') {
            return 'Novo';
        }
        return status;
    }

    private static Id techLarRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> types = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
        if (types.containsKey('TechLar_Atendimento') && types.get('TechLar_Atendimento').isAvailable()) {
            return types.get('TechLar_Atendimento').getRecordTypeId();
        }
        return null;
    }

    private static Id relatedContactId(Account record) {
        if (record.PersonContactId != null) {
            return record.PersonContactId;
        }
        return record.Contacts.isEmpty() ? null : record.Contacts[0].Id;
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
