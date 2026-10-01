import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import searchCustomers from '@salesforce/apex/TechLarSalesController.searchCustomers';
import getOrders from '@salesforce/apex/TechLarServiceController.getOrders';
import createCase from '@salesforce/apex/TechLarServiceController.createCase';
import getCase from '@salesforce/apex/TechLarServiceController.getCase';

export default class TechlarServicePage extends NavigationMixin(LightningElement) {
    searchTerm = '';
    @track customer;
    @track results = [];
    @track orders = [];
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
        this.isLoadingOrders = true;
        this.errorMessage = undefined;
        try {
            this.orders = await getOrders({ accountId: customer.accountId });
        } catch (error) {
            this.orders = [];
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

    handleCaseUpdated(event) {
        this.confirmation = event.detail;
    }

    handleNewCase() {
        this.confirmation = null;
        this.selectedItem = null;
        this.motivo = '';
        this.description = '';
        this.errorMessage = undefined;
    }

    handleOpenRecord() {
        if (!this.confirmation?.caseId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.confirmation.caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
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
