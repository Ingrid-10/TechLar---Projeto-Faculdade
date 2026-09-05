Id techlarPbId = [
    SELECT Id FROM Pricebook2 WHERE Name = 'TechLar Pricebook' AND IsActive = TRUE LIMIT 1
].Id;

List<PricebookEntry> entries = [
    SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = :techlarPbId
];
Set<Id> productIds = new Set<Id>();
for (PricebookEntry entry : entries) {
    productIds.add(entry.Product2Id);
}

List<Product2> products = [
    SELECT Id, ClienteTechLar__c FROM Product2 WHERE Id IN :productIds AND ClienteTechLar__c = FALSE
];
for (Product2 product : products) {
    product.ClienteTechLar__c = true;
}
if (!products.isEmpty()) {
    update products;
}
System.debug('Produtos TechLar marcados: ' + products.size());
