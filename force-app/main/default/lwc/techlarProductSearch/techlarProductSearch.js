import { LightningElement, api, track } from 'lwc';
import searchProducts from '@salesforce/apex/TechLarSalesController.searchProducts';

export default class TechlarProductSearch extends LightningElement {
    @api disabled = false;
    searchTerm = '';
    @track results = [];
    isLoading = false;
    errorMessage;

    get isDisabled() {
        return this.disabled;
    }

    get hasResults() {
        return this.results.length > 0;
    }

    connectedCallback() {
        this.loadProducts();
    }

    handleTermChange(event) {
        this.searchTerm = event.target.value;
    }

    handleKey(event) {
        if (event.key === 'Enter') {
            this.loadProducts();
        }
    }

    async loadProducts() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            this.results = (await searchProducts({ searchTerm: this.searchTerm })).map((item) => ({
                ...item,
                formattedPrice: this.formatPrice(item.unitPrice)
            }));
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível carregar o catálogo.';
        } finally {
            this.isLoading = false;
        }
    }

    handleAdd(event) {
        const pricebookEntryId = event.currentTarget.dataset.id;
        const product = this.results.find((item) => item.pricebookEntryId === pricebookEntryId);
        this.dispatchEvent(new CustomEvent('productadded', { detail: product }));
    }

    formatPrice(value) {
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
    }
}
