public with sharing class TechLarOperationsController {
    @AuraEnabled
    public static Board checkStores() {
        try {
            return toBoard(TechLarReplenishmentService.analyze());
        } catch (Exception ex) {
            throw handled(ex);
        }
    }

    @AuraEnabled
    public static Board replenishStores() {
        try {
            return toBoard(TechLarReplenishmentService.replenish());
        } catch (Exception ex) {
            throw handled(ex);
        }
    }

    @AuraEnabled
    public static PathView transferPath(Id transferId) {
        try {
            return buildPath(transferId);
        } catch (Exception ex) {
            throw handled(ex);
        }
    }

    public class Board {
        @AuraEnabled public String message;
        @AuraEnabled public Integer transferCount;
        @AuraEnabled public List<StoreCard> stores = new List<StoreCard>();
    }

    public class StoreCard {
        @AuraEnabled public String storeName;
        @AuraEnabled public String storeCode;
        @AuraEnabled public Boolean isCentral;
        @AuraEnabled public List<ProductCard> products = new List<ProductCard>();
    }

    public class ProductCard {
        @AuraEnabled public String key;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal afterQuantity;
        @AuraEnabled public String outcome;
        @AuraEnabled public String detail;
        @AuraEnabled public String tone;
        @AuraEnabled public Id transferId;
        @AuraEnabled public Boolean changed;
    }

    public class PathView {
        @AuraEnabled public String transferName;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String originName;
        @AuraEnabled public String destinationName;
        @AuraEnabled public String currentStep;
        @AuraEnabled public String note;
    }

    private static Board toBoard(TechLarReplenishmentService.Summary summary) {
        Board board = new Board();
        board.message = summary.message;
        board.transferCount = summary.transferCount;
        Map<String, StoreCard> stores = new Map<String, StoreCard>();
        Map<String, ProductCard> centralProducts = new Map<String, ProductCard>();
        for (String code : new List<String>{ 'PAULISTA', 'MORUMBI', 'SANTANA' }) {
            stores.put(code, storeCard(code, false));
        }
        for (TechLarReplenishmentService.Line line : summary.lines) {
            StoreCard store = stores.get(line.storeCode);
            if (store == null) {
                continue;
            }
            if (store.storeName == null) {
                store.storeName = line.storeName;
            }
            ProductCard product = productCard(line);
            store.products.add(product);
            if (!centralProducts.containsKey(line.productCode)) {
                ProductCard centralProduct = new ProductCard();
                centralProduct.key = 'CENTRAL-' + line.productCode;
                centralProduct.name = line.productName;
                centralProduct.code = line.productCode;
                centralProduct.quantity = line.centralQuantity;
                centralProduct.tone = 'ok';
                centralProduct.detail = line.centralQuantity == null ? 'Sem saldo' : line.centralQuantity.intValue() + ' unidades';
                centralProducts.put(line.productCode, centralProduct);
            } else if (line.outcome == 'Transferida') {
                centralProducts.get(line.productCode).quantity = line.centralQuantity;
                centralProducts.get(line.productCode).detail = line.centralQuantity.intValue() + ' unidades';
            }
        }
        StoreCard central = storeCard('CENTRAL', true);
        central.storeName = 'Estoque Central';
        central.products.addAll(centralProducts.values());
        board.stores.add(central);
        board.stores.add(stores.get('PAULISTA'));
        board.stores.add(stores.get('MORUMBI'));
        board.stores.add(stores.get('SANTANA'));
        return board;
    }

    private static StoreCard storeCard(String code, Boolean isCentral) {
        StoreCard card = new StoreCard();
        card.storeCode = code;
        card.isCentral = isCentral;
        if (code == 'PAULISTA') {
            card.storeName = 'TechLar Paulista';
        } else if (code == 'MORUMBI') {
            card.storeName = 'TechLar Morumbi';
        } else if (code == 'SANTANA') {
            card.storeName = 'TechLar Santana';
        }
        return card;
    }

    private static ProductCard productCard(TechLarReplenishmentService.Line line) {
        ProductCard product = new ProductCard();
        product.key = line.storeCode + '-' + line.productCode;
        product.name = line.productName;
        product.code = line.productCode;
        product.quantity = line.beforeQuantity;
        product.afterQuantity = line.afterQuantity;
        product.outcome = line.outcome;
        product.detail = line.detail;
        product.transferId = line.transferId;
        product.changed = line.outcome == 'Transferida';
        if (line.outcome == 'Transferida' || line.outcome == 'Precisa repor') {
            product.tone = line.outcome == 'Transferida' ? 'done' : 'alert';
        } else if (line.outcome == 'Sem necessidade') {
            product.tone = 'ok';
        } else {
            product.tone = 'refused';
        }
        return product;
    }

    private static PathView buildPath(Id transferId) {
        if (transferId == null) {
            throw new AuraHandledException('A transferência informada não existe.');
        }
        List<Transferencia_Estoque__c> transfers = [
            SELECT Name, Quantidade__c, Produto__r.Name, Produto__r.ProductCode,
                   Loja_Origem__r.Name, Loja_Destino__r.Name
            FROM Transferencia_Estoque__c
            WHERE Id = :transferId
            LIMIT 1
        ];
        if (transfers.isEmpty()) {
            throw new AuraHandledException('A transferência informada não existe.');
        }
        Boolean separated = false;
        Boolean received = false;
        for (Movimentacao_Estoque__c movement : [
            SELECT Tipo__c
            FROM Movimentacao_Estoque__c
            WHERE Transferencia__c = :transferId
        ]) {
            if (movement.Tipo__c == 'Saída') {
                separated = true;
            }
            if (movement.Tipo__c == 'Entrada') {
                received = true;
            }
        }
        Transferencia_Estoque__c transferRecord = transfers[0];
        PathView view = new PathView();
        view.transferName = transferRecord.Name;
        view.productName = transferRecord.Produto__r.Name;
        view.productCode = transferRecord.Produto__r.ProductCode;
        view.quantity = transferRecord.Quantidade__c;
        view.originName = transferRecord.Loja_Origem__r.Name;
        view.destinationName = transferRecord.Loja_Destino__r.Name;
        view.currentStep = received ? 'recebido' : (separated ? 'transito' : 'separado');
        view.note = 'A saída do central e a entrada na loja ficam registradas juntas. O caminho mostra essa movimentação, sem espera nem rastreio.';
        return view;
    }

    private static AuraHandledException handled(Exception ex) {
        AuraHandledException handledException = new AuraHandledException(ex.getMessage());
        handledException.setMessage(ex.getMessage());
        return handledException;
    }
}
