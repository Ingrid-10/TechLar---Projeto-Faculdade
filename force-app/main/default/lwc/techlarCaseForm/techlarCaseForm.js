import { LightningElement, api } from 'lwc';

const MOTIVOS = [
    { label: 'Produto com defeito', value: 'Produto com defeito' },
    { label: 'Solicitação de troca', value: 'Solicitação de troca' },
    { label: 'Problema na entrega', value: 'Problema na entrega' },
    { label: 'Dúvida sobre pedido', value: 'Dúvida sobre pedido' },
    { label: 'Cancelamento', value: 'Cancelamento' },
    { label: 'Outros', value: 'Outros' }
];

export default class TechlarCaseForm extends LightningElement {
    @api selectedItem;
    @api motivo = '';
    @api description = '';
    options = MOTIVOS;

    get hasSelection() {
        return Boolean(this.selectedItem?.orderItemId);
    }

    get productLabel() {
        return this.selectedItem?.productName || 'Nenhum produto selecionado';
    }

    get orderLabel() {
        return this.selectedItem?.orderNumber ? `Pedido ${this.selectedItem.orderNumber}` : '';
    }

    handleMotivo(event) {
        this.emit(event.detail.value, this.description);
    }

    handleDescription(event) {
        this.emit(this.motivo, event.target.value);
    }

    emit(motivo, description) {
        this.dispatchEvent(
            new CustomEvent('formchange', {
                detail: { motivo, description }
            })
        );
    }
}
