import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchCustomers from '@salesforce/apex/TechLarSalesController.searchCustomers';
import getWorkspace from '@salesforce/apex/TechLarServiceController.getWorkspace';
import createCase from '@salesforce/apex/TechLarServiceController.createCase';
import getCase from '@salesforce/apex/TechLarServiceController.getCase';

export default class TechlarServicePage extends LightningElement {
    searchTerm = '';
    @track customer;
    @track results = [];
    @track orders = [];
    @track cases = [];
    @track selectedItem;
    @track confirmation;
    motivo = '';
    description = '';
    isSearching = false;
    isLoadingOrders = false;
    isSaving = false;
    errorMessage;

    get hasCustomer() {
        return Boolean(this.customer?.accountId);
    }

    get hasResults() {
        return this.results.length > 0;
    }

    get hasConfirmation() {
        return Boolean(this.confirmation?.caseId);
    }

    get hasCases() {
        return this.cases.length > 0;
    }

    get showEmptyCases() {
        return this.hasCustomer && !this.isLoadingOrders && this.cases.length === 0;
    }

    get customerRows() {
        return (this.results || []).map((row, index) => {
            const selected = this.customer?.accountId === row.accountId;
            return {
                ...row,
                index,
                selected,
                buttonLabel: selected ? 'Selecionado' : 'Selecionar',
                buttonVariant: selected ? 'brand' : 'neutral',
                buttonIcon: selected ? 'utility:success' : undefined,
                rowClass: selected ? 'result-row result-row_selected' : 'result-row'
            };
        });
    }

    get caseRows() {
        return (this.cases || []).map((row) => ({
            ...row,
            buttonClass:
                this.confirmation?.caseId === row.caseId ? 'result-btn result-btn_selected' : 'result-btn'
        }));
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
        this.isSearching = true;
        this.errorMessage = undefined;
        try {
            this.results = await searchCustomers({ searchTerm: this.searchTerm });
            if (this.results.length === 1 && this.results[0]?.accountId) {
                await this.selectCustomer(this.results[0]);
            }
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isSearching = false;
        }
    }

    async handleSelect(event) {
        const index = Number(event.currentTarget.dataset.index);
        await this.selectCustomer(this.results[index]);
    }

    async selectCustomer(customer) {
        this.customer = customer;
        this.confirmation = null;
        this.selectedItem = null;
        this.motivo = '';
        this.description = '';
        this.errorMessage = undefined;
        await this.loadWorkspace(customer.accountId);
    }

    async loadWorkspace(accountId) {
        this.isLoadingOrders = true;
        try {
            const workspace = await getWorkspace({ accountId });
            this.orders = workspace?.orders || [];
            this.cases = workspace?.cases || [];
        } catch (error) {
            this.orders = [];
            this.cases = [];
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoadingOrders = false;
        }
    }

    handleItemSelected(event) {
        this.selectedItem = event.detail;
        this.confirmation = null;
        this.errorMessage = undefined;
    }

    async handleSelectCase(event) {
        const caseId = event.currentTarget.dataset.id;
        this.errorMessage = undefined;
        try {
            this.confirmation = await getCase({ caseId });
            this.selectedItem = null;
        } catch (error) {
            this.errorMessage = this.reduceError(error);
        }
    }

    handleFormChange(event) {
        this.motivo = event.detail.motivo;
        this.description = event.detail.description;
    }

    async handleOpenCase() {
        this.errorMessage = undefined;
        if (!this.customer?.accountId) {
            this.errorMessage = 'Selecione um cliente para abrir o atendimento.';
            return;
        }
        if (!this.selectedItem?.orderId) {
            this.errorMessage = 'Selecione um pedido para abrir o atendimento.';
            return;
        }
        if (!this.selectedItem?.orderItemId) {
            this.errorMessage = 'Selecione um produto da compra para abrir o atendimento.';
            return;
        }
        if (!this.motivo) {
            this.errorMessage = 'Informe o motivo do atendimento.';
            return;
        }
        if (!this.description) {
            this.errorMessage = 'Descreva o problema do cliente.';
            return;
        }

        this.isSaving = true;
        try {
            const created = await createCase({
                request: {
                    accountId: this.customer.accountId,
                    orderId: this.selectedItem.orderId,
                    orderItemId: this.selectedItem.orderItemId,
                    productId: this.selectedItem.productId,
                    motivo: this.motivo,
                    description: this.description
                }
            });
            this.confirmation = await getCase({ caseId: created.caseId });
            this.confirmation = { ...this.confirmation, message: created.message };
            await this.loadWorkspace(this.customer.accountId);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Atendimento aberto',
                    message: created.message,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.errorMessage = this.reduceError(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Não foi possível abrir o atendimento',
                    message: this.errorMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isSaving = false;
        }
    }

    async handleCaseUpdated(event) {
        this.confirmation = event.detail;
        if (this.customer?.accountId) {
            await this.loadWorkspace(this.customer.accountId);
        }
    }

    handleNewCase() {
        this.confirmation = null;
        this.selectedItem = null;
        this.motivo = '';
        this.description = '';
        this.errorMessage = undefined;
    }

    reduceError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.message || 'Erro inesperado no atendimento.';
    }
}
