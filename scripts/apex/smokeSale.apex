Contact customer = [
    SELECT Id FROM Contact WHERE CPF__c = '111.444.777-35' LIMIT 1
];
PricebookEntry notebook = [
    SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-NB-001' AND Pricebook2.IsStandard = TRUE LIMIT 1
];
PricebookEntry mouse = [
    SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'TL-MS-001' AND Pricebook2.IsStandard = TRUE LIMIT 1
];

TechLarSalesService.SaleRequest request = new TechLarSalesService.SaleRequest();
request.contactId = customer.Id;
request.modalidadeRecebimento = 'Retirada na Loja';
request.items = new List<TechLarSalesService.SaleItemRequest>();

TechLarSalesService.SaleItemRequest item1 = new TechLarSalesService.SaleItemRequest();
item1.pricebookEntryId = notebook.Id;
item1.quantity = 1;
request.items.add(item1);

TechLarSalesService.SaleItemRequest item2 = new TechLarSalesService.SaleItemRequest();
item2.pricebookEntryId = mouse.Id;
item2.quantity = 2;
request.items.add(item2);

TechLarSalesService.SaleResult result = TechLarSalesController.createSale(request);
System.debug('SMOKE OrderId=' + result.orderId + ' Number=' + result.orderNumber + ' Total=' + result.grandTotal);
