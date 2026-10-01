public with sharing class TechLarServiceController {
    @AuraEnabled(cacheable=false)
    public static List<TechLarServiceService.OrderDTO> getOrders(Id accountId) {
        try {
            return TechLarServiceService.getOrders(accountId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao consultar compras: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static TechLarServiceService.WorkspaceDTO getWorkspace(Id accountId) {
        try {
            return TechLarServiceService.getWorkspace(accountId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao consultar o histórico do cliente: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarServiceService.CaseResult createCase(TechLarServiceService.CaseRequest request) {
        try {
            return TechLarServiceService.createCase(request);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao abrir o atendimento: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarServiceService.CaseResult resolveCase(Id caseId, String resultado) {
        try {
            return TechLarServiceService.resolveCase(caseId, resultado);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao concluir o atendimento: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static TechLarServiceService.CaseResult getCase(Id caseId) {
        try {
            return TechLarServiceService.getCase(caseId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao carregar o atendimento: ' + ex.getMessage());
        }
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
