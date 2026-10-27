public with sharing class TechLarInventoryService {
    public static List<ProductOption> searchProducts(String searchTerm, String storeCode) {
        if (String.isBlank(storeCode)) {
            return searchAllProducts(searchTerm);
        }
        String likeTerm = toLike(searchTerm);
        List<Estoque__c> rows;
        if (likeTerm == null) {
            rows = [
                SELECT Produto__c, Produto__r.Name, Produto__r.ProductCode, Quantidade_Disponivel__c
                FROM Estoque__c
                WHERE Produto__r.IsActive = TRUE
                  AND Loja__r.Codigo__c = :storeCode
                ORDER BY Produto__r.Name
                LIMIT 20
            ];
        } else {
            rows = [
                SELECT Produto__c, Produto__r.Name, Produto__r.ProductCode, Quantidade_Disponivel__c
                FROM Estoque__c
                WHERE Produto__r.IsActive = TRUE
                  AND Loja__r.Codigo__c = :storeCode
                  AND (Produto__r.Name LIKE :likeTerm OR Produto__r.ProductCode LIKE :likeTerm)
                ORDER BY Produto__r.Name
                LIMIT 20
            ];
        }

        List<ProductOption> options = new List<ProductOption>();
        for (Estoque__c row : rows) {
            ProductOption option = new ProductOption();
            option.productId = row.Produto__c;
            option.name = row.Produto__r.Name;
            option.productCode = row.Produto__r.ProductCode;
            option.quantidade = row.Quantidade_Disponivel__c;
            options.add(option);
        }
        return options;
    }

    private static List<ProductOption> searchAllProducts(String searchTerm) {
        String likeTerm = toLike(searchTerm);
        List<AggregateResult> rows;
        if (likeTerm == null) {
            rows = [
                SELECT Produto__c productId, Produto__r.Name productName, Produto__r.ProductCode productCode
                FROM Estoque__c
                WHERE Produto__r.IsActive = TRUE
                GROUP BY Produto__c, Produto__r.Name, Produto__r.ProductCode
                ORDER BY Produto__r.Name
                LIMIT 20
            ];
        } else {
            rows = [
                SELECT Produto__c productId, Produto__r.Name productName, Produto__r.ProductCode productCode
                FROM Estoque__c
                WHERE Produto__r.IsActive = TRUE
                  AND (Produto__r.Name LIKE :likeTerm OR Produto__r.ProductCode LIKE :likeTerm)
                GROUP BY Produto__c, Produto__r.Name, Produto__r.ProductCode
                ORDER BY Produto__r.Name
                LIMIT 20
            ];
        }

        List<ProductOption> options = new List<ProductOption>();
        for (AggregateResult row : rows) {
            ProductOption option = new ProductOption();
            option.productId = (Id) row.get('productId');
            option.name = (String) row.get('productName');
            option.productCode = (String) row.get('productCode');
            options.add(option);
        }
        return options;
    }

    public static StoreContext getStore(String storeCode) {
        if (String.isBlank(storeCode)) {
            throw handled('Informe o código da loja.');
        }

        StoreContext context = new StoreContext();
        context.destinations = new List<StoreOption>();
        for (Loja__c store : [
            SELECT Id, Name, Codigo__c
            FROM Loja__c
            WHERE Status__c = 'Ativa'
            ORDER BY Name
        ]) {
            if (store.Codigo__c == storeCode) {
                context.lojaId = store.Id;
                context.name = store.Name;
                context.code = store.Codigo__c;
                continue;
            }
            StoreOption option = new StoreOption();
            option.lojaId = store.Id;
            option.name = store.Name;
            option.code = store.Codigo__c;
            context.destinations.add(option);
        }
        if (context.lojaId == null) {
            throw handled('A loja informada não existe.');
        }
        return context;
    }

    public static TransferView getTransferView(Id transferId) {
        if (transferId == null) {
            throw handled('A transferência informada não existe.');
        }
        List<Transferencia_Estoque__c> transfers = [
            SELECT Name, Quantidade__c, Produto__c, Produto__r.Name, Produto__r.ProductCode,
                   Loja_Origem__c, Loja_Origem__r.Name, Loja_Origem__r.Codigo__c,
                   Loja_Destino__c, Loja_Destino__r.Name, Loja_Destino__r.Codigo__c
            FROM Transferencia_Estoque__c
            WHERE Id = :transferId
            LIMIT 1
        ];
        if (transfers.isEmpty()) {
            throw handled('A transferência informada não existe.');
        }

        Transferencia_Estoque__c transferRecord = transfers[0];
        Map<Id, Decimal> balanceByStore = new Map<Id, Decimal>();
        for (Estoque__c row : [
            SELECT Loja__c, Quantidade_Disponivel__c
            FROM Estoque__c
            WHERE Produto__c = :transferRecord.Produto__c
              AND Loja__c IN :new Set<Id>{ transferRecord.Loja_Origem__c, transferRecord.Loja_Destino__c }
        ]) {
            balanceByStore.put(row.Loja__c, row.Quantidade_Disponivel__c);
        }

        Decimal quantity = transferRecord.Quantidade__c;
        Decimal originAfter = balanceByStore.get(transferRecord.Loja_Origem__c);
        Decimal destinationAfter = balanceByStore.get(transferRecord.Loja_Destino__c);
        TransferView view = new TransferView();
        view.transferId = transferRecord.Id;
        view.transferName = transferRecord.Name;
        view.productId = transferRecord.Produto__c;
        view.productName = transferRecord.Produto__r.Name;
        view.productCode = transferRecord.Produto__r.ProductCode;
        view.quantity = quantity;
        view.originName = transferRecord.Loja_Origem__r.Name;
        view.originCode = transferRecord.Loja_Origem__r.Codigo__c;
        view.originBefore = originAfter + quantity;
        view.originAfter = originAfter;
        view.destinationName = transferRecord.Loja_Destino__r.Name;
        view.destinationCode = transferRecord.Loja_Destino__r.Codigo__c;
        view.destinationBefore = destinationAfter - quantity;
        view.destinationAfter = destinationAfter;
        return view;
    }

    public static StockView getStock(Id productId) {
        if (productId == null) {
            throw handled('O produto informado não existe.');
        }
        List<Product2> products = [
            SELECT Id, Name, ProductCode
            FROM Product2
            WHERE Id = :productId
            LIMIT 1
        ];
        if (products.isEmpty()) {
            throw handled('O produto informado não existe.');
        }

        StockView view = new StockView();
        view.productId = products[0].Id;
        view.productName = products[0].Name;
        view.productCode = products[0].ProductCode;
        view.lines = new List<StockLine>();
        for (Estoque__c row : [
            SELECT Id, Quantidade_Disponivel__c, Loja__c, Loja__r.Name, Loja__r.Codigo__c
            FROM Estoque__c
            WHERE Produto__c = :productId
            ORDER BY Loja__r.Name
        ]) {
            StockLine line = new StockLine();
            line.estoqueId = row.Id;
            line.lojaId = row.Loja__c;
            line.lojaName = row.Loja__r.Name;
            line.lojaCodigo = row.Loja__r.Codigo__c;
            line.quantidade = row.Quantidade_Disponivel__c;
            view.lines.add(line);
        }
        return view;
    }

    public static TransferResult transfer(TransferRequest request) {
        if (request == null || request.productId == null) {
            throw handled('O produto informado não existe.');
        }
        if (request.originStoreId == null || request.destinationStoreId == null) {
            throw handled('Informe a loja de origem e a loja de destino.');
        }
        if (request.originStoreId == request.destinationStoreId) {
            throw handled('A loja de origem e a loja de destino devem ser diferentes.');
        }
        if (request.quantity == null || request.quantity <= 0 || request.quantity != request.quantity.intValue()) {
            throw handled('A quantidade deve ser um número inteiro maior que zero.');
        }

        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Id = :request.productId LIMIT 1];
        if (products.isEmpty()) {
            throw handled('O produto informado não existe.');
        }

        Map<Id, Estoque__c> byStore = new Map<Id, Estoque__c>();
        for (Estoque__c row : [
            SELECT Id, Quantidade_Disponivel__c, Loja__c, Loja__r.Name, Loja__r.Codigo__c
            FROM Estoque__c
            WHERE Produto__c = :request.productId
              AND Loja__c IN :new Set<Id>{ request.originStoreId, request.destinationStoreId }
            FOR UPDATE
        ]) {
            byStore.put(row.Loja__c, row);
        }
        if (!byStore.containsKey(request.originStoreId)) {
            throw handled('Não há estoque cadastrado para a loja de origem.');
        }
        if (!byStore.containsKey(request.destinationStoreId)) {
            throw handled('Não há estoque cadastrado para a loja de destino.');
        }

        Estoque__c origin = byStore.get(request.originStoreId);
        Estoque__c destination = byStore.get(request.destinationStoreId);
        if (origin.Quantidade_Disponivel__c < request.quantity) {
            throw handled('A loja de origem não possui estoque suficiente.');
        }
        Decimal originBefore = origin.Quantidade_Disponivel__c;
        Decimal destinationBefore = destination.Quantidade_Disponivel__c;

        Transferencia_Estoque__c transferRecord = new Transferencia_Estoque__c(
            Produto__c = request.productId,
            Loja_Origem__c = request.originStoreId,
            Loja_Destino__c = request.destinationStoreId,
            Quantidade__c = request.quantity,
            Status__c = 'Concluída',
            Data_Transferencia__c = System.now()
        );
        insert transferRecord;

        origin.Quantidade_Disponivel__c = originBefore - request.quantity;
        destination.Quantidade_Disponivel__c = destinationBefore + request.quantity;
        update new List<Estoque__c>{ origin, destination };

        insert new List<Movimentacao_Estoque__c>{
            new Movimentacao_Estoque__c(
                Produto__c = request.productId,
                Loja__c = request.originStoreId,
                Tipo__c = 'Saída',
                Quantidade__c = request.quantity,
                Data_Movimentacao__c = System.now(),
                Transferencia__c = transferRecord.Id
            ),
            new Movimentacao_Estoque__c(
                Produto__c = request.productId,
                Loja__c = request.destinationStoreId,
                Tipo__c = 'Entrada',
                Quantidade__c = request.quantity,
                Data_Movimentacao__c = System.now(),
                Transferencia__c = transferRecord.Id
            )
        };

        transferRecord = [SELECT Name FROM Transferencia_Estoque__c WHERE Id = :transferRecord.Id];
        TransferResult result = new TransferResult();
        result.transferId = transferRecord.Id;
        result.transferName = transferRecord.Name;
        result.productName = products[0].Name;
        result.originName = origin.Loja__r.Name;
        result.destinationName = destination.Loja__r.Name;
        result.quantity = request.quantity;
        result.originCode = origin.Loja__r.Codigo__c;
        result.destinationCode = destination.Loja__r.Codigo__c;
        result.originBalanceBefore = originBefore;
        result.originBalance = origin.Quantidade_Disponivel__c;
        result.destinationBalanceBefore = destinationBefore;
        result.destinationBalance = destination.Quantidade_Disponivel__c;
        result.message = transferRecord.Name + ' concluída. ' + result.originName + ' tinha ' + formatUnits(originBefore) + ' e ficou com ' + formatUnits(result.originBalance) + '.';
        return result;
    }

    private static String formatUnits(Decimal quantity) {
        return quantity.intValue() + (quantity == 1 ? ' unidade' : ' unidades');
    }

    private static String toLike(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return null;
        }
        return '%' + searchTerm.trim() + '%';
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

    public class ProductOption {
        @AuraEnabled public Id productId;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantidade;
    }

    public class StoreOption {
        @AuraEnabled public Id lojaId;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
    }

    public class StoreContext {
        @AuraEnabled public Id lojaId;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public List<StoreOption> destinations;
    }

    public class TransferView {
        @AuraEnabled public Id transferId;
        @AuraEnabled public String transferName;
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String originName;
        @AuraEnabled public String originCode;
        @AuraEnabled public Decimal originBefore;
        @AuraEnabled public Decimal originAfter;
        @AuraEnabled public String destinationName;
        @AuraEnabled public String destinationCode;
        @AuraEnabled public Decimal destinationBefore;
        @AuraEnabled public Decimal destinationAfter;
    }

    public class StockLine {
        @AuraEnabled public Id estoqueId;
        @AuraEnabled public Id lojaId;
        @AuraEnabled public String lojaName;
        @AuraEnabled public String lojaCodigo;
        @AuraEnabled public Decimal quantidade;
    }

    public class StockView {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public List<StockLine> lines;
    }

    public class TransferRequest {
        @AuraEnabled public Id productId;
        @AuraEnabled public Id originStoreId;
        @AuraEnabled public Id destinationStoreId;
        @AuraEnabled public Decimal quantity;
    }

    public class TransferResult {
        @AuraEnabled public Id transferId;
        @AuraEnabled public String transferName;
        @AuraEnabled public String productName;
        @AuraEnabled public String originName;
        @AuraEnabled public String destinationName;
        @AuraEnabled public String originCode;
        @AuraEnabled public String destinationCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal originBalanceBefore;
        @AuraEnabled public Decimal originBalance;
        @AuraEnabled public Decimal destinationBalanceBefore;
        @AuraEnabled public Decimal destinationBalance;
        @AuraEnabled public String message;
    }
}
