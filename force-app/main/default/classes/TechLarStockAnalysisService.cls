public with sharing class TechLarStockAnalysisService {
    public class AgentRequest {
        @InvocableVariable(required=false label='Pedido do funcionário')
        public String instruction;
    }

    public class AgentResponse {
        @InvocableVariable(label='Resumo da situação')
        public String summary;
    }

    @InvocableMethod(
        label='Analisar estoque das lojas TechLar'
        description='Mostra os três produtos mais vendidos de cada loja nos últimos 30 dias e o que está abaixo de 5 unidades. Não transfere estoque.'
        category='TechLar'
    )
    public static List<AgentResponse> analyzeForAgent(List<AgentRequest> requests) {
        AgentResponse response = new AgentResponse();
        response.summary = TechLarReplenishmentService.analyze().message;
        List<AgentResponse> result = new List<AgentResponse>();
        Integer size = requests == null || requests.isEmpty() ? 1 : requests.size();
        for (Integer i = 0; i < size; i++) {
            result.add(response);
        }
        return result;
    }
}
