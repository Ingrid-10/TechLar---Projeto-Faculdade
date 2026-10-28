public with sharing class TechLarInventoryController {
    @AuraEnabled(cacheable=false)
    public static List<TechLarInventoryService.ProductOption> searchProducts(String searchTerm, String storeCode) {
        try {
            return TechLarInventoryService.searchProducts(searchTerm, storeCode);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao pesquisar produtos: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static TechLarInventoryService.StoreContext getStore(String storeCode) {
        try {
            return TechLarInventoryService.getStore(storeCode);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao consultar a loja: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static TechLarInventoryService.TransferView getTransferView(Id transferId) {
        try {
            return TechLarInventoryService.getTransferView(transferId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao consultar a transferência: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static TechLarInventoryService.StockView getStock(Id productId) {
        try {
            return TechLarInventoryService.getStock(productId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao consultar o estoque: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarInventoryService.TransferResult transferStock(TechLarInventoryService.TransferRequest request) {
        try {
            return TechLarInventoryService.transfer(request);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao transferir o estoque: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarInventoryService.TransferResult requestStock(TechLarInventoryService.TransferRequest request) {
        try {
            return TechLarInventoryService.requestFromStore(request);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao pedir a transferência: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<TechLarInventoryService.OpenTransfer> listOpenTransfers(String storeCode) {
        try {
            return TechLarInventoryService.listOpenTransfers(storeCode);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao consultar as transferências em aberto: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarInventoryService.TransferResult resumeStock(Id transferId) {
        try {
            return TechLarInventoryService.resume(transferId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao abrir a transferência: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarInventoryService.TransferResult advanceStock(Id transferId) {
        try {
            return TechLarInventoryService.advance(transferId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao avançar a transferência: ' + ex.getMessage());
        }
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
