public with sharing class TechLarInventoryService {
    public static final String CENTRAL_STORE_CODE = 'CENTRAL';
    public static final String STATUS_REQUESTED = 'Pedido feito';
    public static final String STATUS_TRANSIT = 'Em transporte';
    public static final String STATUS_DONE = 'Concluída';
    private static final Set<String> OPEN_STATUSES = new Set<String>{ STATUS_REQUESTED, STATUS_TRANSIT };
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
            if (store.Codigo__c == CENTRAL_STORE_CODE) {
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
        Boolean received = [
            SELECT COUNT()
            FROM Movimentacao_Estoque__c
            WHERE Transferencia__c = :transferId
              AND Tipo__c = 'Entrada'
        ] > 0;
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
        view.destinationBefore = received ? destinationAfter - quantity : destinationAfter;
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
              AND Loja__r.Codigo__c != :CENTRAL_STORE_CODE
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
        StockPair pair = lockStock(request);
        Decimal originBefore = pair.origin.Quantidade_Disponivel__c;
        Decimal destinationBefore = pair.destination.Quantidade_Disponivel__c;

        Transferencia_Estoque__c transferRecord = newTransfer(pair, STATUS_DONE);
        insert transferRecord;

        pair.origin.Quantidade_Disponivel__c = originBefore - pair.quantity;
        pair.destination.Quantidade_Disponivel__c = destinationBefore + pair.quantity;
        update new List<Estoque__c>{ pair.origin, pair.destination };
        insert new List<Movimentacao_Estoque__c>{
            movement(pair, pair.origin.Loja__c, 'Saída', transferRecord.Id),
            movement(pair, pair.destination.Loja__c, 'Entrada', transferRecord.Id)
        };

        transferRecord = [SELECT Name, Status__c, Quantidade__c FROM Transferencia_Estoque__c WHERE Id = :transferRecord.Id];
        return buildResult(
            transferRecord,
            pair,
            originBefore,
            destinationBefore,
            transferRecord.Name + ' concluída. ' + pair.origin.Loja__r.Name + ' tinha ' + formatUnits(originBefore) + ' e ficou com ' + formatUnits(pair.origin.Quantidade_Disponivel__c) + '.',
            'concluido',
            null
        );
    }

    public static TransferResult requestFromStore(TransferRequest request) {
        StockPair pair = lockStock(request);
        Decimal originBefore = pair.origin.Quantidade_Disponivel__c;
        Decimal destinationBefore = pair.destination.Quantidade_Disponivel__c;

        Transferencia_Estoque__c transferRecord = newTransfer(pair, STATUS_REQUESTED);
        insert transferRecord;

        pair.origin.Quantidade_Disponivel__c = originBefore - pair.quantity;
        update pair.origin;
        insert movement(pair, pair.origin.Loja__c, 'Saída', transferRecord.Id);

        transferRecord = [SELECT Name, Status__c, Quantidade__c FROM Transferencia_Estoque__c WHERE Id = :transferRecord.Id];
        return buildResult(
            transferRecord,
            pair,
            originBefore,
            destinationBefore,
            transferRecord.Name + ' registrado. ' + pair.origin.Loja__r.Name + ' tinha ' + formatUnits(originBefore) + ' e ficou com ' + formatUnits(pair.origin.Quantidade_Disponivel__c) + '. O produto ainda não chegou nesta loja.',
            'pedido',
            'Marcar em transporte'
        );
    }

    public static TransferResult advance(Id transferId) {
        if (transferId == null) {
            throw handled('A transferência informada não existe.');
        }
        List<Transferencia_Estoque__c> transfers = [
            SELECT Name, Status__c, Quantidade__c, Produto__c, Produto__r.Name, Produto__r.ProductCode,
                   Loja_Origem__c, Loja_Destino__c
            FROM Transferencia_Estoque__c
            WHERE Id = :transferId
            FOR UPDATE
        ];
        if (transfers.isEmpty()) {
            throw handled('A transferência informada não existe.');
        }
        Transferencia_Estoque__c transferRecord = transfers[0];
        if (transferRecord.Status__c == STATUS_DONE) {
            throw handled('Esta transferência já foi recebida na loja.');
        }
        if (transferRecord.Status__c != STATUS_REQUESTED && transferRecord.Status__c != STATUS_TRANSIT) {
            throw handled('Esta transferência não pode avançar.');
        }

        Map<Id, Estoque__c> byStore = new Map<Id, Estoque__c>();
        for (Estoque__c row : [
            SELECT Id, Quantidade_Disponivel__c, Loja__c, Loja__r.Name, Loja__r.Codigo__c
            FROM Estoque__c
            WHERE Produto__c = :transferRecord.Produto__c
              AND Loja__c IN :new Set<Id>{ transferRecord.Loja_Origem__c, transferRecord.Loja_Destino__c }
            FOR UPDATE
        ]) {
            byStore.put(row.Loja__c, row);
        }
        Estoque__c origin = byStore.get(transferRecord.Loja_Origem__c);
        Estoque__c destination = byStore.get(transferRecord.Loja_Destino__c);
        if (origin == null || destination == null) {
            throw handled('Não há estoque cadastrado para concluir esta transferência.');
        }

        Decimal destinationBefore = destination.Quantidade_Disponivel__c;
        String step = 'transporte';
        String advanceLabel = 'Confirmar entrada na loja';
        String message = transferRecord.Name + ' em transporte. O saldo desta loja continua o mesmo até a entrada.';
        if (transferRecord.Status__c == STATUS_REQUESTED) {
            transferRecord.Status__c = STATUS_TRANSIT;
        } else {
            transferRecord.Status__c = STATUS_DONE;
            destination.Quantidade_Disponivel__c = destinationBefore + transferRecord.Quantidade__c;
            update destination;
            insert new Movimentacao_Estoque__c(
                Produto__c = transferRecord.Produto__c,
                Loja__c = destination.Loja__c,
                Tipo__c = 'Entrada',
                Quantidade__c = transferRecord.Quantidade__c,
                Data_Movimentacao__c = System.now(),
                Transferencia__c = transferRecord.Id
            );
            step = 'concluido';
            advanceLabel = null;
            message = transferRecord.Name + ' recebida. ' + destination.Loja__r.Name + ' tinha ' + formatUnits(destinationBefore) + ' e ficou com ' + formatUnits(destination.Quantidade_Disponivel__c) + '.';
        }
        update transferRecord;

        StockPair pair = new StockPair();
        pair.productId = transferRecord.Produto__c;
        pair.productName = transferRecord.Produto__r.Name;
        pair.productCode = transferRecord.Produto__r.ProductCode;
        pair.origin = origin;
        pair.destination = destination;
        pair.quantity = transferRecord.Quantidade__c;
        return buildResult(
            transferRecord,
            pair,
            origin.Quantidade_Disponivel__c + transferRecord.Quantidade__c,
            destinationBefore,
            message,
            step,
            advanceLabel
        );
    }

    private static StockPair lockStock(TransferRequest request) {
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

        List<Product2> products = [SELECT Id, Name, ProductCode FROM Product2 WHERE Id = :request.productId LIMIT 1];
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
        if (origin.Quantidade_Disponivel__c < request.quantity) {
            throw handled('A loja de origem não possui estoque suficiente.');
        }

        StockPair pair = new StockPair();
        pair.productId = products[0].Id;
        pair.productName = products[0].Name;
        pair.productCode = products[0].ProductCode;
        pair.origin = origin;
        pair.destination = byStore.get(request.destinationStoreId);
        pair.quantity = request.quantity;
        return pair;
    }

    private static Transferencia_Estoque__c newTransfer(StockPair pair, String status) {
        return new Transferencia_Estoque__c(
            Produto__c = pair.productId,
            Loja_Origem__c = pair.origin.Loja__c,
            Loja_Destino__c = pair.destination.Loja__c,
            Quantidade__c = pair.quantity,
            Status__c = status,
            Data_Transferencia__c = System.now()
        );
    }

    private static Movimentacao_Estoque__c movement(StockPair pair, Id storeId, String type, Id transferId) {
        return new Movimentacao_Estoque__c(
            Produto__c = pair.productId,
            Loja__c = storeId,
            Tipo__c = type,
            Quantidade__c = pair.quantity,
            Data_Movimentacao__c = System.now(),
            Transferencia__c = transferId
        );
    }

    private static TransferResult buildResult(
        Transferencia_Estoque__c transferRecord,
        StockPair pair,
        Decimal originBefore,
        Decimal destinationBefore,
        String message,
        String currentStep,
        String advanceLabel
    ) {
        TransferResult result = new TransferResult();
        result.transferId = transferRecord.Id;
        result.transferName = transferRecord.Name;
        result.productId = pair.productId;
        result.productCode = pair.productCode;
        result.productName = pair.productName;
        result.originName = pair.origin.Loja__r.Name;
        result.destinationName = pair.destination.Loja__r.Name;
        result.quantity = transferRecord.Quantidade__c;
        result.originCode = pair.origin.Loja__r.Codigo__c;
        result.destinationCode = pair.destination.Loja__r.Codigo__c;
        result.originBalanceBefore = originBefore;
        result.originBalance = pair.origin.Quantidade_Disponivel__c;
        result.destinationBalanceBefore = destinationBefore;
        result.destinationBalance = pair.destination.Quantidade_Disponivel__c;
        result.message = message;
        result.currentStep = currentStep;
        result.status = transferRecord.Status__c;
        result.advanceLabel = advanceLabel;
        return result;
    }

    public static List<OpenTransfer> listOpenTransfers(String storeCode) {
        if (String.isBlank(storeCode)) {
            throw handled('Informe o código da loja.');
        }
        List<OpenTransfer> rows = new List<OpenTransfer>();
        for (Transferencia_Estoque__c transferRecord : [
            SELECT Name, Status__c, Quantidade__c, Produto__r.Name, Loja_Origem__r.Name
            FROM Transferencia_Estoque__c
            WHERE Loja_Destino__r.Codigo__c = :storeCode
              AND Status__c IN :OPEN_STATUSES
            ORDER BY CreatedDate DESC
            LIMIT 50
        ]) {
            OpenTransfer row = new OpenTransfer();
            row.transferId = transferRecord.Id;
            row.transferName = transferRecord.Name;
            row.productName = transferRecord.Produto__r.Name;
            row.originName = transferRecord.Loja_Origem__r.Name;
            row.quantity = transferRecord.Quantidade__c;
            row.status = transferRecord.Status__c;
            row.summary = transferRecord.Produto__r.Name + ' · ' + formatUnits(transferRecord.Quantidade__c)
                + ' · ' + transferRecord.Loja_Origem__r.Name + ' · ' + transferRecord.Status__c;
            rows.add(row);
        }
        return rows;
    }

    public static TransferResult resume(Id transferId) {
        TransferState state = readState(transferId, true);
        String step = 'concluido';
        String advanceLabel = null;
        String message = state.transferRecord.Name + ' recebida. ' + state.pair.destination.Loja__r.Name
            + ' tinha ' + formatUnits(state.destinationBefore) + ' e ficou com ' + formatUnits(state.pair.destination.Quantidade_Disponivel__c) + '.';
        if (state.transferRecord.Status__c == STATUS_REQUESTED) {
            step = 'pedido';
            advanceLabel = 'Marcar em transporte';
            message = state.transferRecord.Name + ' registrado. ' + state.pair.origin.Loja__r.Name
                + ' tinha ' + formatUnits(state.originBefore) + ' e ficou com ' + formatUnits(state.pair.origin.Quantidade_Disponivel__c)
                + '. O produto ainda não chegou nesta loja.';
        } else if (state.transferRecord.Status__c == STATUS_TRANSIT) {
            step = 'transporte';
            advanceLabel = 'Confirmar entrada na loja';
            message = state.transferRecord.Name + ' em transporte. O saldo desta loja continua o mesmo até a entrada.';
        }
        return buildResult(
            state.transferRecord,
            state.pair,
            state.originBefore,
            state.destinationBefore,
            message,
            step,
            advanceLabel
        );
    }

    private static TransferState readState(Id transferId, Boolean receivedAdjustsDestination) {
        if (transferId == null) {
            throw handled('A transferência informada não existe.');
        }
        List<Transferencia_Estoque__c> transfers = [
            SELECT Name, Status__c, Quantidade__c, Produto__c, Produto__r.Name, Produto__r.ProductCode,
                   Loja_Origem__c, Loja_Destino__c
            FROM Transferencia_Estoque__c
            WHERE Id = :transferId
            LIMIT 1
        ];
        if (transfers.isEmpty()) {
            throw handled('A transferência informada não existe.');
        }
        Transferencia_Estoque__c transferRecord = transfers[0];
        Map<Id, Estoque__c> byStore = new Map<Id, Estoque__c>();
        for (Estoque__c row : [
            SELECT Id, Quantidade_Disponivel__c, Loja__c, Loja__r.Name, Loja__r.Codigo__c
            FROM Estoque__c
            WHERE Produto__c = :transferRecord.Produto__c
              AND Loja__c IN :new Set<Id>{ transferRecord.Loja_Origem__c, transferRecord.Loja_Destino__c }
        ]) {
            byStore.put(row.Loja__c, row);
        }
        if (!byStore.containsKey(transferRecord.Loja_Origem__c) || !byStore.containsKey(transferRecord.Loja_Destino__c)) {
            throw handled('Não há estoque cadastrado para esta transferência.');
        }
        StockPair pair = new StockPair();
        pair.productId = transferRecord.Produto__c;
        pair.productName = transferRecord.Produto__r.Name;
        pair.productCode = transferRecord.Produto__r.ProductCode;
        pair.origin = byStore.get(transferRecord.Loja_Origem__c);
        pair.destination = byStore.get(transferRecord.Loja_Destino__c);
        pair.quantity = transferRecord.Quantidade__c;
        TransferState state = new TransferState();
        state.transferRecord = transferRecord;
        state.pair = pair;
        state.originBefore = pair.origin.Quantidade_Disponivel__c + transferRecord.Quantidade__c;
        state.destinationBefore = pair.destination.Quantidade_Disponivel__c;
        if (receivedAdjustsDestination && transferRecord.Status__c == STATUS_DONE) {
            state.destinationBefore = pair.destination.Quantidade_Disponivel__c - transferRecord.Quantidade__c;
        }
        return state;
    }

    private class TransferState {
        Transferencia_Estoque__c transferRecord;
        StockPair pair;
        Decimal originBefore;
        Decimal destinationBefore;
    }

    private class StockPair {
        Id productId;
        String productName;
        String productCode;
        Estoque__c origin;
        Estoque__c destination;
        Decimal quantity;
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
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public Id originStoreId { get; set; }
        @AuraEnabled public Id destinationStoreId { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
    }

    public class TransferResult {
        @AuraEnabled public Id transferId;
        @AuraEnabled public String transferName;
        @AuraEnabled public Id productId;
        @AuraEnabled public String productCode;
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
        @AuraEnabled public String currentStep;
        @AuraEnabled public String status;
        @AuraEnabled public String advanceLabel;
    }

    public class OpenTransfer {
        @AuraEnabled public Id transferId;
        @AuraEnabled public String transferName;
        @AuraEnabled public String productName;
        @AuraEnabled public String originName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String status;
        @AuraEnabled public String summary;
    }
}
