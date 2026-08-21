List<String> productCodes = new List<String>{
    'TL-NB-001', 'TL-MS-001', 'TL-KB-001', 'TL-HS-001',
    'TL-MN-001', 'TL-SSD-001', 'TL-WC-001', 'TL-HB-001'
};

List<Product2> existingProducts = [
    SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :productCodes
];
Set<String> existingCodes = new Set<String>();
for (Product2 product : existingProducts) {
    existingCodes.add(product.ProductCode);
}

List<Product2> productsToInsert = new List<Product2>();
if (!existingCodes.contains('TL-NB-001')) {
    productsToInsert.add(new Product2(Name = 'Notebook TechLar X', ProductCode = 'TL-NB-001', IsActive = true, Family = 'Computadores', Description = 'Notebook 16GB RAM 512GB SSD'));
}
if (!existingCodes.contains('TL-MS-001')) {
    productsToInsert.add(new Product2(Name = 'Mouse Gamer TechLar', ProductCode = 'TL-MS-001', IsActive = true, Family = 'Periféricos', Description = 'Mouse óptico 12000 DPI'));
}
if (!existingCodes.contains('TL-KB-001')) {
    productsToInsert.add(new Product2(Name = 'Teclado Mecânico TechLar', ProductCode = 'TL-KB-001', IsActive = true, Family = 'Periféricos', Description = 'Teclado switch blue ABNT2'));
}
if (!existingCodes.contains('TL-HS-001')) {
    productsToInsert.add(new Product2(Name = 'Headset TechLar Pro', ProductCode = 'TL-HS-001', IsActive = true, Family = 'Áudio', Description = 'Headset com microfone e RGB'));
}
if (!existingCodes.contains('TL-MN-001')) {
    productsToInsert.add(new Product2(Name = 'Monitor 27 TechLar', ProductCode = 'TL-MN-001', IsActive = true, Family = 'Monitores', Description = 'Monitor IPS 27 polegadas 144Hz'));
}
if (!existingCodes.contains('TL-SSD-001')) {
    productsToInsert.add(new Product2(Name = 'SSD 1TB TechLar', ProductCode = 'TL-SSD-001', IsActive = true, Family = 'Armazenamento', Description = 'SSD NVMe 1TB'));
}
if (!existingCodes.contains('TL-WC-001')) {
    productsToInsert.add(new Product2(Name = 'Webcam Full HD TechLar', ProductCode = 'TL-WC-001', IsActive = true, Family = 'Periféricos', Description = 'Webcam 1080p com microfone'));
}
if (!existingCodes.contains('TL-HB-001')) {
    productsToInsert.add(new Product2(Name = 'Hub USB-C TechLar', ProductCode = 'TL-HB-001', IsActive = true, Family = 'Acessórios', Description = 'Hub 7 em 1 USB-C'));
}
if (!productsToInsert.isEmpty()) {
    insert productsToInsert;
}

Pricebook2 standardPb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
if (!standardPb.IsActive) {
    standardPb.IsActive = true;
    update standardPb;
}

Map<String, Decimal> prices = new Map<String, Decimal>{
    'TL-NB-001' => 4999,
    'TL-MS-001' => 299,
    'TL-KB-001' => 549,
    'TL-HS-001' => 799,
    'TL-MN-001' => 1899,
    'TL-SSD-001' => 459,
    'TL-WC-001' => 249,
    'TL-HB-001' => 189
};

Map<String, Id> productsByCode = new Map<String, Id>();
for (Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :prices.keySet()]) {
    productsByCode.put(product.ProductCode, product.Id);
}

Set<Id> productIds = new Set<Id>(productsByCode.values());
Set<Id> alreadyPriced = new Set<Id>();
for (PricebookEntry entry : [
    SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = :standardPb.Id AND Product2Id IN :productIds
]) {
    alreadyPriced.add(entry.Product2Id);
}

List<PricebookEntry> entries = new List<PricebookEntry>();
for (String code : prices.keySet()) {
    Id productId = productsByCode.get(code);
    if (productId != null && !alreadyPriced.contains(productId)) {
        entries.add(new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = productId,
            UnitPrice = prices.get(code),
            IsActive = true
        ));
    }
}
if (!entries.isEmpty()) {
    insert entries;
}

Map<String, Map<String, String>> customers = new Map<String, Map<String, String>>{
    '111.444.777-35' => new Map<String, String>{
        'first' => 'Ana', 'last' => 'Souza', 'email' => 'ana.souza@techlar.example', 'phone' => '11999990001',
        'street' => 'Av. Paulista, 1000', 'city' => 'São Paulo', 'state' => 'SP', 'cep' => '01310-100'
    },
    '222.333.444-05' => new Map<String, String>{
        'first' => 'Bruno', 'last' => 'Lima', 'email' => 'bruno.lima@techlar.example', 'phone' => '21988880002',
        'street' => 'Rua do Catete, 50', 'city' => 'Rio de Janeiro', 'state' => 'RJ', 'cep' => '22220-000'
    },
    '333.222.111-96' => new Map<String, String>{
        'first' => 'Carla', 'last' => 'Mendes', 'email' => 'carla.mendes@techlar.example', 'phone' => '31977770003',
        'street' => 'Av. Afonso Pena, 200', 'city' => 'Belo Horizonte', 'state' => 'MG', 'cep' => '30130-000'
    },
    '444.555.666-77' => new Map<String, String>{
        'first' => 'Diego', 'last' => 'Alves', 'email' => 'diego.alves@techlar.example', 'phone' => '41966660004',
        'street' => 'Rua XV de Novembro, 80', 'city' => 'Curitiba', 'state' => 'PR', 'cep' => '80020-000'
    },
    '555.666.777-88' => new Map<String, String>{
        'first' => 'Elena', 'last' => 'Rocha', 'email' => 'elena.rocha@techlar.example', 'phone' => '51955550005',
        'street' => 'Av. Borges de Medeiros, 300', 'city' => 'Porto Alegre', 'state' => 'RS', 'cep' => '90020-020'
    },
    '666.777.888-99' => new Map<String, String>{
        'first' => 'Felipe', 'last' => 'Castro', 'email' => 'felipe.castro@techlar.example', 'phone' => '85944440006',
        'street' => 'Av. Beira Mar, 150', 'city' => 'Fortaleza', 'state' => 'CE', 'cep' => '60165-121'
    }
};

Set<String> existingCpfs = new Set<String>();
for (Contact contact : [SELECT CPF__c FROM Contact WHERE CPF__c IN :customers.keySet()]) {
    existingCpfs.add(contact.CPF__c);
}

List<Account> accounts = new List<Account>();
List<String> newCpfs = new List<String>();
for (String cpf : customers.keySet()) {
    if (!existingCpfs.contains(cpf)) {
        Map<String, String> row = customers.get(cpf);
        accounts.add(new Account(Name = row.get('first') + ' ' + row.get('last')));
        newCpfs.add(cpf);
    }
}
if (!accounts.isEmpty()) {
    insert accounts;
    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < accounts.size(); i++) {
        Map<String, String> row = customers.get(newCpfs[i]);
        contacts.add(new Contact(
            AccountId = accounts[i].Id,
            FirstName = row.get('first'),
            LastName = row.get('last'),
            Email = row.get('email'),
            Phone = row.get('phone'),
            CPF__c = newCpfs[i],
            MailingStreet = row.get('street'),
            MailingCity = row.get('city'),
            MailingState = row.get('state'),
            MailingPostalCode = row.get('cep'),
            MailingCountry = 'Brazil'
        ));
    }
    insert contacts;
}

System.debug('Mock TechLar carregado. Produtos no catálogo: ' + [SELECT COUNT() FROM PricebookEntry WHERE Product2.ProductCode IN :productCodes]);
System.debug('Clientes TechLar: ' + [SELECT COUNT() FROM Contact WHERE CPF__c IN :customers.keySet()]);
