public with sharing class TechLarCepService {
    public class EnderecoDTO {
        @AuraEnabled public String cep;
        @AuraEnabled public String logradouro;
        @AuraEnabled public String bairro;
        @AuraEnabled public String localidade;
        @AuraEnabled public String uf;
        @AuraEnabled public Decimal valorFrete;
        @AuraEnabled public Integer prazoDias;
    }

    public class FreteDTO {
        @AuraEnabled public Decimal valorFrete;
        @AuraEnabled public Integer prazoDias;
    }

    @AuraEnabled(cacheable=false)
    public static EnderecoDTO consultarCep(String cep) {
        String digits = onlyDigits(cep);
        if (digits.length() != 8) {
            throw handled('Informe um CEP com 8 dígitos.');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://viacep.com.br/ws/' + digits + '/json/');
        req.setMethod('GET');
        req.setTimeout(8000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw handled('Não foi possível consultar o CEP. Tente novamente.');
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Object erro = payload.get('erro');
        if (erro == true || String.valueOf(erro) == 'true') {
            throw handled('CEP não encontrado.');
        }

        EnderecoDTO dto = new EnderecoDTO();
        dto.cep = (String) payload.get('cep');
        dto.logradouro = (String) payload.get('logradouro');
        dto.bairro = (String) payload.get('bairro');
        dto.localidade = (String) payload.get('localidade');
        dto.uf = (String) payload.get('uf');

        FreteDTO frete = cotarFrete(dto.uf);
        dto.valorFrete = frete.valorFrete;
        dto.prazoDias = frete.prazoDias;
        return dto;
    }

    public static FreteDTO cotarFrete(String uf) {
        FreteDTO frete = new FreteDTO();
        String estado = uf == null ? '' : uf.trim().toUpperCase();

        if (estado == 'SP' || estado == 'RJ') {
            frete.valorFrete = 19.90;
            frete.prazoDias = 3;
        } else if (estado == 'MG' || estado == 'ES' || estado == 'PR' || estado == 'SC' || estado == 'RS') {
            frete.valorFrete = 29.90;
            frete.prazoDias = 5;
        } else if (String.isBlank(estado)) {
            frete.valorFrete = 39.90;
            frete.prazoDias = 7;
        } else {
            frete.valorFrete = 49.90;
            frete.prazoDias = 8;
        }
        return frete;
    }

    private static String onlyDigits(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        return value.replaceAll('[^0-9]', '');
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
