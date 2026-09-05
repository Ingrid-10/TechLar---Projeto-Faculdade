Id adminPermsetId = [
    SELECT Id
    FROM PermissionSet
    WHERE Profile.Name = 'System Administrator' AND IsOwnedByProfile = true
    LIMIT 1
].Id;

List<String> fields = new List<String>{
    'Account.ClienteTechLar__c',
    'Account.CPF__c',
    'Contact.ClienteTechLar__c',
    'Contact.CPF__c',
    'Case.ClienteTechLar__c',
    'Product2.ClienteTechLar__c',
    'Order.ClienteTechLar__c'
};

Set<String> alreadyGranted = new Set<String>();
for (FieldPermissions existing : [
    SELECT Field FROM FieldPermissions WHERE ParentId = :adminPermsetId AND Field IN :fields
]) {
    alreadyGranted.add(existing.Field);
}

List<FieldPermissions> toInsert = new List<FieldPermissions>();
for (String fieldName : fields) {
    if (!alreadyGranted.contains(fieldName)) {
        toInsert.add(new FieldPermissions(
            ParentId = adminPermsetId,
            SobjectType = fieldName.substringBefore('.'),
            Field = fieldName,
            PermissionsRead = true,
            PermissionsEdit = true
        ));
    }
}
if (!toInsert.isEmpty()) {
    insert toInsert;
}
System.debug('FLS concedido no System Administrator: ' + toInsert.size() + ' campos.');
