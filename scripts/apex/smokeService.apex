Account customer = [
    SELECT Id, Name FROM Account WHERE ClienteTechLar__c = TRUE AND CPF__c = '700.000.001-59' LIMIT 1
];
Order pedido = [
    SELECT Id, OrderNumber FROM Order WHERE AccountId = :customer.Id AND ClienteTechLar__c = TRUE ORDER BY EffectiveDate DESC LIMIT 1
];
OrderItem item = [
    SELECT Id, Product2Id, Product2.Name FROM OrderItem WHERE OrderId = :pedido.Id AND Product2.Name LIKE '%Notebook%' LIMIT 1
];
if (item == null) {
    item = [SELECT Id, Product2Id, Product2.Name FROM OrderItem WHERE OrderId = :pedido.Id LIMIT 1];
}

TechLarServiceService.CaseRequest request = new TechLarServiceService.CaseRequest();
request.accountId = customer.Id;
request.orderId = pedido.Id;
request.orderItemId = item.Id;
request.productId = item.Product2Id;
request.motivo = 'Produto com defeito';
request.description = 'Notebook apresentou defeito na tela após a compra em loja física.';

TechLarServiceService.CaseResult result = TechLarServiceController.createCase(request);
System.debug(
    'SMOKE Case=' + result.caseNumber +
    ' Status=' + result.status +
    ' Owner=' + result.ownerName +
    ' Produto=' + item.Product2.Name
);
