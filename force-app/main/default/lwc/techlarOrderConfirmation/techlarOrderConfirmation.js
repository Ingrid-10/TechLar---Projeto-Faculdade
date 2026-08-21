import { LightningElement, api } from 'lwc';

export default class TechlarOrderConfirmation extends LightningElement {
    @api confirmation;

    get formattedItems() {
        return this.formatPrice(this.confirmation?.itemsTotal);
    }

    get formattedFreight() {
        return this.formatPrice(this.confirmation?.freightTotal);
    }

    get formattedTotal() {
        return this.formatPrice(this.confirmation?.grandTotal);
    }

    handleOpen() {
        this.dispatchEvent(new CustomEvent('openorder'));
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('newsale'));
    }

    formatPrice(value) {
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
    }
}
