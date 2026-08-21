public with sharing class TechLarSalesController {
    @AuraEnabled(cacheable=false)
    public static List<TechLarSalesService.CustomerDTO> searchCustomers(String searchTerm) {
        try {
            return TechLarSalesService.searchCustomers(searchTerm);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao pesquisar clientes: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarSalesService.CustomerDTO createCustomer(TechLarSalesService.CustomerDTO customer) {
        try {
            return TechLarSalesService.createCustomer(customer);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao cadastrar cliente: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<TechLarSalesService.ProductDTO> searchProducts(String searchTerm) {
        try {
            return TechLarSalesService.searchProducts(searchTerm);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao pesquisar produtos: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarSalesService.SaleResult createSale(TechLarSalesService.SaleRequest request) {
        try {
            return TechLarSalesService.createSale(request);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw handled('Erro ao finalizar a venda: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static TechLarCepService.EnderecoDTO consultarCep(String cep) {
        return TechLarCepService.consultarCep(cep);
    }

    @AuraEnabled(cacheable=true)
    public static TechLarCepService.FreteDTO cotarFrete(String uf) {
        return TechLarCepService.cotarFrete(uf);
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
