import { LightningElement, api, track } from 'lwc';
import searchCustomers from '@salesforce/apex/TechLarSalesController.searchCustomers';
import createCustomer from '@salesforce/apex/TechLarSalesController.createCustomer';

export default class TechlarCustomerSearch extends LightningElement {
    @api selectedCustomer;
    searchTerm = '';
    @track results = [];
    @track draft = {
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        cpf: '',
        mailingStreet: '',
        mailingCity: '',
        mailingState: '',
        mailingPostalCode: ''
    };
    showCreate = false;
    isLoading = false;
    isSaving = false;
    errorMessage;

    @api
    reset() {
        this.searchTerm = '';
        this.results = [];
        this.showCreate = false;
        this.errorMessage = undefined;
    }

    get hasResults() {
        return this.results.length > 0;
    }

    handleTermChange(event) {
        this.searchTerm = event.target.value;
    }

    handleKey(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    async handleSearch() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            this.results = await searchCustomers({ searchTerm: this.searchTerm });
            if (!this.results.length) {
                this.showCreate = true;
            }
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível pesquisar clientes.';
        } finally {
            this.isLoading = false;
        }
    }

    handleSelect(event) {
        const contactId = event.currentTarget.dataset.id;
        const customer = this.results.find((item) => item.contactId === contactId);
        this.dispatchEvent(new CustomEvent('customerselected', { detail: customer }));
        this.showCreate = false;
    }

    toggleCreate() {
        this.showCreate = !this.showCreate;
    }

    handleDraftChange(event) {
        const field = event.target.dataset.field;
        this.draft = { ...this.draft, [field]: event.target.value };
    }

    async handleCreate() {
        this.isSaving = true;
        this.errorMessage = undefined;
        try {
            const customer = await createCustomer({ customer: this.draft });
            this.dispatchEvent(new CustomEvent('customerselected', { detail: customer }));
            this.showCreate = false;
            this.results = [customer];
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível cadastrar o cliente.';
        } finally {
            this.isSaving = false;
        }
    }
}
