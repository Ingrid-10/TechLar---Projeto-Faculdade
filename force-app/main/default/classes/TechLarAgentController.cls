public with sharing class TechLarAgentController {
    private static final String AGENT_API_NAME = 'TechLar_Operations_Employee_Agent';

    @TestVisible
    private static AgentInvoker invoker = new AgentInvoker();

    @AuraEnabled
    public static AgentReply sendMessage(String userMessage, String sessionId) {
        if (String.isBlank(userMessage)) {
            throw handled('Digite uma mensagem para o agente.');
        }

        Datetime startedAt = System.now().addSeconds(-5);
        AgentReply reply = invoker.send(userMessage.trim(), sessionId);
        reply.transfers = new List<AgentTransfer>();
        for (Transferencia_Estoque__c transferRecord : [
            SELECT Id, Produto__r.ProductCode, Loja_Destino__r.Codigo__c
            FROM Transferencia_Estoque__c
            WHERE Loja_Origem__r.Codigo__c = :TechLarInventoryService.CENTRAL_STORE_CODE
              AND CreatedDate >= :startedAt
            ORDER BY CreatedDate
        ]) {
            AgentTransfer transfer = new AgentTransfer();
            transfer.transferId = transferRecord.Id;
            transfer.productCode = transferRecord.Produto__r.ProductCode;
            transfer.destinationCode = transferRecord.Loja_Destino__r.Codigo__c;
            reply.transfers.add(transfer);
        }
        return reply;
    }

    public virtual class AgentInvoker {
        public virtual AgentReply send(String userMessage, String sessionId) {
            Invocable.Action action = Invocable.Action.createCustomAction(
                'generateAiAgentResponse',
                AGENT_API_NAME
            );
            action.setInvocationParameter('userMessage', userMessage);
            if (String.isNotBlank(sessionId)) {
                action.setInvocationParameter('sessionId', sessionId);
            }

            List<Invocable.Action.Result> results = action.invoke();
            if (results.isEmpty() || !results[0].isSuccess()) {
                String detail = results.isEmpty()
                    ? 'nenhum resultado retornado'
                    : String.valueOf(results[0].getErrors());
                throw handled('O Agentforce não conseguiu responder: ' + detail);
            }

            Map<String, Object> output = results[0].getOutputParameters();
            AgentReply reply = new AgentReply();
            reply.sessionId = (String) output.get('sessionId');
            reply.message = responseText(output.get('agentResponse'));
            return reply;
        }
    }

    private static String responseText(Object rawResponse) {
        if (rawResponse == null) {
            return 'O agente concluiu o pedido sem retornar uma mensagem.';
        }
        String rawText = String.valueOf(rawResponse);
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(rawText);
            if (payload != null && payload.get('value') != null) {
                return String.valueOf(payload.get('value'));
            }
        } catch (Exception ignored) {
            // Some Agentforce versions return plain text instead of a JSON envelope.
        }
        return rawText;
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException handledError = new AuraHandledException(message);
        handledError.setMessage(message);
        return handledError;
    }

    public class AgentReply {
        @AuraEnabled public String message;
        @AuraEnabled public String sessionId;
        @AuraEnabled public List<AgentTransfer> transfers;
    }

    public class AgentTransfer {
        @AuraEnabled public Id transferId;
        @AuraEnabled public String productCode;
        @AuraEnabled public String destinationCode;
    }
}
