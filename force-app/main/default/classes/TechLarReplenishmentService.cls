public with sharing class TechLarReplenishmentService {
    public static final Integer TOP_LIMIT = 3;
    public static final Integer MINIMUM = 5;
    public static final Integer TARGET = 10;
    public static final Integer WINDOW_DAYS = 30;
    public static final List<String> STORE_CODES = new List<String>{ 'MORUMBI', 'PAULISTA', 'SANTANA' };
    public static final String PATH_TAB = 'TechLar_Caminho_Transferencia';

    public class Line {
        public String storeCode;
        public String storeName;
        public Id productId;
        public String productName;
        public String productCode;
        public Decimal beforeQuantity;
        public Decimal afterQuantity;
        public Decimal transferredQuantity;
        public Decimal centralQuantity;
        public Id transferId;
        public String pathUrl;
        public String outcome;
        public String detail;
    }

    public class Summary {
        public Integer transferCount = 0;
        public String message;
        public List<Line> lines = new List<Line>();
    }

    public class AgentRequest {
        @InvocableVariable(required=false label='Pedido do funcionário')
        public String instruction;
    }

    public class AgentResponse {
        @InvocableVariable(label='Resumo da reposição')
        public String summary;
    }

    @InvocableMethod(
        label='Repor estoque das lojas TechLar'
        description='Repõe, a partir do Estoque Central, os produtos mais vendidos que estiverem abaixo de 5 unidades até chegar a 10. Use somente quando a pessoa pedir a reposição.'
        category='TechLar'
    )
    public static List<AgentResponse> replenishForAgent(List<AgentRequest> requests) {
        return responses(replenish().message, requests);
    }

    public static Summary analyze() {
        Context context = loadContext();
        Summary summary = new Summary();
        if (context.error != null) {
            summary.message = context.error;
            return summary;
        }
        summary.lines = describeLines(context, false);
        summary.message = buildAnalysisMessage(summary);
        return summary;
    }

    public static Summary replenish() {
        Context context = loadContext();
        Summary summary = new Summary();
        if (context.error != null) {
            summary.message = context.error;
            return summary;
        }
        summary.lines = describeLines(context, true);
        summary.message = buildReplenishmentMessage(summary);
        return summary;
    }

    private class Context {
        public String error;
        public Loja__c central;
        public Map<String, Loja__c> storesByCode = new Map<String, Loja__c>();
        public Map<Id, List<AggregateResult>> rankingByStore = new Map<Id, List<AggregateResult>>();
        public Map<String, Decimal> stockByKey = new Map<String, Decimal>();
    }

    private static Context loadContext() {
        Context context = new Context();
        String centralCode = TechLarInventoryService.CENTRAL_STORE_CODE;
        for (Loja__c store : [
            SELECT Id, Name, Codigo__c
            FROM Loja__c
            WHERE Codigo__c IN :STORE_CODES OR Codigo__c = :centralCode
        ]) {
            context.storesByCode.put(store.Codigo__c, store);
        }
        context.central = context.storesByCode.get(centralCode);
        if (context.central == null) {
            context.error = 'O Estoque Central não está cadastrado.';
            return context;
        }

        List<Id> storeIds = new List<Id>();
        for (String code : STORE_CODES) {
            if (context.storesByCode.containsKey(code)) {
                storeIds.add(context.storesByCode.get(code).Id);
            }
        }
        Date startDate = Date.today().addDays(-WINDOW_DAYS);
        for (AggregateResult row : [
            SELECT Order.Loja__c storeId, Product2Id productId, Product2.Name productName, Product2.ProductCode productCode, SUM(Quantity) sold
            FROM OrderItem
            WHERE Order.Loja__c IN :storeIds
              AND Order.EffectiveDate >= :startDate
              AND Order.Status = 'Activated'
            GROUP BY Order.Loja__c, Product2Id, Product2.Name, Product2.ProductCode
            ORDER BY SUM(Quantity) DESC, Product2.Name
        ]) {
            Id storeId = (Id) row.get('storeId');
            if (!context.rankingByStore.containsKey(storeId)) {
                context.rankingByStore.put(storeId, new List<AggregateResult>());
            }
            context.rankingByStore.get(storeId).add(row);
        }

        Set<Id> productIds = new Set<Id>();
        for (Id storeId : context.rankingByStore.keySet()) {
            List<AggregateResult> ranked = context.rankingByStore.get(storeId);
            Integer limitSize = Math.min(TOP_LIMIT, ranked.size());
            for (Integer i = 0; i < limitSize; i++) {
                productIds.add((Id) ranked[i].get('productId'));
            }
        }
        if (!productIds.isEmpty()) {
            for (Estoque__c row : [
                SELECT Produto__c, Loja__c, Quantidade_Disponivel__c
                FROM Estoque__c
                WHERE Produto__c IN :productIds
                  AND (Loja__c IN :storeIds OR Loja__c = :context.central.Id)
            ]) {
                context.stockByKey.put(stockKey(row.Produto__c, row.Loja__c), row.Quantidade_Disponivel__c);
            }
        }
        return context;
    }

    private static List<Line> describeLines(Context context, Boolean executeTransfer) {
        List<Line> lines = new List<Line>();
        for (String code : STORE_CODES) {
            Loja__c store = context.storesByCode.get(code);
            if (store == null) {
                continue;
            }
            List<AggregateResult> ranked = context.rankingByStore.containsKey(store.Id)
                ? context.rankingByStore.get(store.Id)
                : new List<AggregateResult>();
            Integer limitSize = Math.min(TOP_LIMIT, ranked.size());
            for (Integer i = 0; i < limitSize; i++) {
                lines.add(describeLine(store, context.central, ranked[i], context.stockByKey, executeTransfer));
            }
        }
        return lines;
    }

    private static Line describeLine(
        Loja__c store,
        Loja__c central,
        AggregateResult ranked,
        Map<String, Decimal> stockByKey,
        Boolean executeTransfer
    ) {
        Line line = new Line();
        line.storeCode = store.Codigo__c;
        line.storeName = store.Name;
        line.productId = (Id) ranked.get('productId');
        line.productName = (String) ranked.get('productName');
        line.productCode = (String) ranked.get('productCode');
        String storeKey = stockKey(line.productId, store.Id);
        String centralKey = stockKey(line.productId, central.Id);
        Decimal current = stockByKey.containsKey(storeKey) ? stockByKey.get(storeKey) : null;
        Decimal centralQty = stockByKey.containsKey(centralKey) ? stockByKey.get(centralKey) : 0;
        line.centralQuantity = centralQty;
        line.beforeQuantity = current == null ? 0 : current;
        line.afterQuantity = line.beforeQuantity;
        line.transferredQuantity = 0;

        if (current == null) {
            line.outcome = 'Sem saldo cadastrado';
            line.detail = 'Não há estoque cadastrado para esta loja.';
            return line;
        }
        if (current >= MINIMUM) {
            line.outcome = 'Sem necessidade';
            line.detail = 'A loja já tem ' + current.intValue() + ' unidades.';
            return line;
        }

        Decimal needed = TARGET - current;
        if (centralQty < needed) {
            line.outcome = 'Estoque central insuficiente';
            line.detail = 'Faltam ' + needed.intValue() + ' unidades e o central tem ' + centralQty.intValue() + '.';
            return line;
        }

        if (!executeTransfer) {
            stockByKey.put(centralKey, centralQty - needed);
            line.outcome = 'Precisa repor';
            line.detail = 'Faltam ' + needed.intValue() + ' unidades. O Estoque Central cobre essa quantidade.';
            return line;
        }

        TechLarInventoryService.TransferRequest request = new TechLarInventoryService.TransferRequest();
        request.productId = line.productId;
        request.originStoreId = central.Id;
        request.destinationStoreId = store.Id;
        request.quantity = needed;
        TechLarInventoryService.TransferResult result = TechLarInventoryService.transfer(request);
        stockByKey.put(centralKey, result.originBalance);
        stockByKey.put(storeKey, result.destinationBalance);
        line.beforeQuantity = result.destinationBalanceBefore;
        line.afterQuantity = result.destinationBalance;
        line.centralQuantity = result.originBalance;
        line.transferredQuantity = needed;
        line.transferId = result.transferId;
        line.pathUrl = pathUrl(result.transferId);
        line.outcome = 'Transferida';
        line.detail = result.message;
        return line;
    }

    private static String buildAnalysisMessage(Summary summary) {
        List<String> parts = new List<String>();
        parts.add('Situação das lojas nos últimos 30 dias.');
        if (summary.lines.isEmpty()) {
            parts.add('Nenhum produto vendido no período.');
        }
        for (Line line : summary.lines) {
            if (line.outcome == 'Precisa repor') {
                parts.add(line.storeName + ': ' + line.productName + ' com ' + line.beforeQuantity.intValue() + ' unidades. ' + line.detail);
            } else if (line.outcome == 'Sem necessidade') {
                parts.add(line.storeName + ': ' + line.productName + ' com ' + line.beforeQuantity.intValue() + ' unidades. Estoque suficiente.');
            } else {
                parts.add(line.storeName + ': ' + line.productName + '. ' + line.outcome + '. ' + line.detail);
            }
        }
        parts.add('Nenhuma transferência foi feita. Peça para repor as lojas que precisam.');
        return String.join(parts, '\n');
    }

    private static String buildReplenishmentMessage(Summary summary) {
        List<String> parts = new List<String>();
        parts.add('Reposição concluída.');
        if (summary.lines.isEmpty()) {
            parts.add('Nenhum produto vendido nos últimos 30 dias.');
        }
        for (Line line : summary.lines) {
            if (line.outcome == 'Transferida') {
                summary.transferCount++;
                parts.add(
                    line.storeName + ': ' + line.productName + ' de ' + line.beforeQuantity.intValue()
                    + ' para ' + line.afterQuantity.intValue() + '. Transferidas: ' + line.transferredQuantity.intValue() + '.'
                );
                parts.add('Caminho da transferência: ' + line.pathUrl);
            } else if (line.outcome == 'Sem necessidade') {
                parts.add(line.storeName + ': ' + line.productName + ' com ' + line.beforeQuantity.intValue() + ' unidades. Nenhuma transferência.');
            } else {
                parts.add(line.storeName + ': ' + line.productName + ' não foi reposto. Motivo: ' + line.outcome + '. ' + line.detail);
            }
        }
        parts.add('Total de transferências realizadas: ' + summary.transferCount + '.');
        return String.join(parts, '\n');
    }

    private static List<AgentResponse> responses(String message, List<AgentRequest> requests) {
        AgentResponse response = new AgentResponse();
        response.summary = message;
        List<AgentResponse> result = new List<AgentResponse>();
        Integer size = requests == null || requests.isEmpty() ? 1 : requests.size();
        for (Integer i = 0; i < size; i++) {
            result.add(response);
        }
        return result;
    }

    private static String pathUrl(Id transferId) {
        return URL.getOrgDomainUrl().toExternalForm()
            + '/lightning/n/' + PATH_TAB
            + '?c__transferId=' + transferId;
    }

    private static String stockKey(Id productId, Id storeId) {
        return String.valueOf(productId) + '-' + String.valueOf(storeId);
    }
}
