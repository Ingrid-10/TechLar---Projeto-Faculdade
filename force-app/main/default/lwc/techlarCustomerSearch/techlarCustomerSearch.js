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
            } else if (this.results.length === 1 && this.results[0]?.accountId) {
                this.selectCustomer(this.results[0]);
            }
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível pesquisar clientes.';
        } finally {
            this.isLoading = false;
        }
    }

    handleSelect(event) {
        const index = Number(event.currentTarget.dataset.index);
        this.selectCustomer(this.results[index]);
    }

    selectCustomer(customer) {
        if (!customer?.accountId) {
            this.errorMessage = 'Não foi possível selecionar este cliente. Pesquise novamente.';
            return;
        }
        this.dispatchEvent(
            new CustomEvent('customerselected', {
                detail: {
                    accountId: customer.accountId,
                    firstName: customer.firstName,
                    lastName: customer.lastName,
                    name: customer.name,
                    email: customer.email,
                    phone: customer.phone,
                    cpf: customer.cpf,
                    mailingStreet: customer.mailingStreet,
                    mailingCity: customer.mailingCity,
                    mailingState: customer.mailingState,
                    mailingPostalCode: customer.mailingPostalCode
                }
            })
        );
        this.showCreate = false;
        this.results = [];
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
            this.selectCustomer(customer);
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível cadastrar o cliente.';
        } finally {
            this.isSaving = false;
        }
    }
}
