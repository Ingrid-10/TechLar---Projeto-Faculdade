import { LightningElement, api } from 'lwc';
import consultarCep from '@salesforce/apex/TechLarSalesController.consultarCep';
import cotarFrete from '@salesforce/apex/TechLarSalesController.cotarFrete';

const OPTIONS = [
    { label: 'Retirada na loja', value: 'Retirada na Loja' },
    { label: 'Entrega no endereço', value: 'Entrega' }
];

export default class TechlarDeliveryOptions extends LightningElement {
    @api delivery = {};
    @api customer;
    options = OPTIONS;
    isLookingCep = false;
    errorMessage;

    get isDelivery() {
        return this.delivery?.modalidadeRecebimento === 'Entrega';
    }

    get formattedFreight() {
        if (!this.isDelivery) {
            return 'Sem frete';
        }
        const value = Number(this.delivery?.valorFrete || 0);
        const prazo = this.delivery?.prazoDias;
        const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
        return prazo ? `${money} · ${prazo} dia(s) úteis` : money;
    }

    handleMode(event) {
        const modalidadeRecebimento = event.detail.value;
        const next = { ...this.delivery, modalidadeRecebimento };
        if (modalidadeRecebimento === 'Retirada na Loja') {
            next.valorFrete = 0;
            next.prazoDias = null;
        } else if (this.customer) {
            next.shippingStreet = next.shippingStreet || this.customer.mailingStreet || '';
            next.shippingCity = next.shippingCity || this.customer.mailingCity || '';
            next.shippingState = next.shippingState || this.customer.mailingState || '';
            next.shippingPostalCode = next.shippingPostalCode || this.customer.mailingPostalCode || '';
        }
        this.emit(next);
        if (modalidadeRecebimento === 'Entrega' && next.shippingState) {
            this.refreshFreight(next);
        }
    }

    handleField(event) {
        const field = event.target.dataset.field;
        const next = { ...this.delivery, [field]: event.target.value };
        this.emit(next);
        if (field === 'shippingState' && this.isDelivery) {
            this.refreshFreight(next);
        }
    }

    async handleCep() {
        const cep = this.delivery?.shippingPostalCode;
        this.isLookingCep = true;
        this.errorMessage = undefined;
        try {
            const address = await consultarCep({ cep });
            this.emit({
                ...this.delivery,
                shippingStreet: address.logradouro,
                shippingCity: address.localidade,
                shippingState: address.uf,
                shippingPostalCode: address.cep || cep,
                valorFrete: address.valorFrete,
                prazoDias: address.prazoDias
            });
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível consultar o CEP.';
        } finally {
            this.isLookingCep = false;
        }
    }

    async refreshFreight(current) {
        try {
            const quote = await cotarFrete({ uf: current.shippingState });
            this.emit({
                ...current,
                valorFrete: quote.valorFrete,
                prazoDias: quote.prazoDias
            });
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível calcular o frete.';
        }
    }

    emit(detail) {
        this.dispatchEvent(new CustomEvent('deliverychanged', { detail }));
    }
}
