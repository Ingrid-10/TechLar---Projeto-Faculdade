import { LightningElement, api } from 'lwc';

export default class TechlarShoppingCart extends LightningElement {
    @api items = [];
    @api itemsTotal = 0;
    @api freightTotal = 0;
    @api grandTotal = 0;

    get isEmpty() {
        return !this.items || this.items.length === 0;
    }

    get rows() {
        return (this.items || []).map((item) => ({
            ...item,
            lineTotal: item.quantity * item.unitPrice,
            formattedUnit: this.formatPrice(item.unitPrice),
            formattedLine: this.formatPrice(item.quantity * item.unitPrice)
        }));
    }

    get formattedItemsTotal() {
        return this.formatPrice(this.itemsTotal);
    }

    get formattedFreight() {
        return this.formatPrice(this.freightTotal);
    }

    get formattedGrandTotal() {
        return this.formatPrice(this.grandTotal);
    }

    handleQty(event) {
        const pricebookEntryId = event.target.dataset.id;
        const quantity = Number(event.target.value);
        const next = this.items.map((item) =>
            item.pricebookEntryId === pricebookEntryId ? { ...item, quantity: quantity > 0 ? quantity : 1 } : item
        );
        this.emit(next);
    }

    handleRemove(event) {
        const pricebookEntryId = event.currentTarget.dataset.id;
        this.emit(this.items.filter((item) => item.pricebookEntryId !== pricebookEntryId));
    }

    emit(items) {
        this.dispatchEvent(new CustomEvent('cartchanged', { detail: { items } }));
    }

    formatPrice(value) {
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
    }
}
