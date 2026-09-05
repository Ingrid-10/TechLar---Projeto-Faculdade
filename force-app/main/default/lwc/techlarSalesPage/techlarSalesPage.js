import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createSale from '@salesforce/apex/TechLarSalesController.createSale';

export default class TechlarSalesPage extends NavigationMixin(LightningElement) {
    @track customer;
    @track cartItems = [];
    @track delivery = {
        modalidadeRecebimento: '',
        shippingStreet: '',
        shippingCity: '',
        shippingState: '',
        shippingPostalCode: '',
        valorFrete: 0,
        prazoDias: null
    };
    @track confirmation;
    isSaving = false;
    errorMessage;

    get hasCustomer() {
        return Boolean(this.customer?.accountId);
    }

    get isCatalogLocked() {
        return !this.customer?.accountId;
    }

    get itemsTotal() {
        return this.cartItems.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
    }

    get freightTotal() {
        return this.delivery.modalidadeRecebimento === 'Entrega' ? Number(this.delivery.valorFrete || 0) : 0;
    }

    get grandTotal() {
        return this.itemsTotal + this.freightTotal;
    }

    handleCustomerSelected(event) {
        this.customer = event.detail;
        this.confirmation = null;
        this.errorMessage = undefined;
        if (this.customer && !this.delivery.shippingStreet) {
            this.delivery = {
                ...this.delivery,
                shippingStreet: this.customer.mailingStreet || '',
                shippingCity: this.customer.mailingCity || '',
                shippingState: this.customer.mailingState || '',
                shippingPostalCode: this.customer.mailingPostalCode || ''
            };
        }
    }

    handleProductAdded(event) {
        const product = event.detail;
        const existing = this.cartItems.find((item) => item.pricebookEntryId === product.pricebookEntryId);
        if (existing) {
            this.cartItems = this.cartItems.map((item) =>
                item.pricebookEntryId === product.pricebookEntryId
                    ? { ...item, quantity: item.quantity + 1 }
                    : item
            );
        } else {
            this.cartItems = [
                ...this.cartItems,
                {
                    pricebookEntryId: product.pricebookEntryId,
                    productId: product.productId,
                    name: product.name,
                    productCode: product.productCode,
                    unitPrice: product.unitPrice,
                    quantity: 1
                }
            ];
        }
        this.confirmation = null;
    }

    handleCartChanged(event) {
        this.cartItems = event.detail.items;
        this.confirmation = null;
    }

    handleDeliveryChanged(event) {
        this.delivery = { ...this.delivery, ...event.detail };
        this.confirmation = null;
    }

    async handleFinalize() {
        this.errorMessage = undefined;
        if (!this.customer?.accountId) {
            this.errorMessage = 'Selecione um cliente na lista para concluir a venda.';
            return;
        }
        if (!this.cartItems.length) {
            this.errorMessage = 'Adicione pelo menos um produto ao carrinho.';
            return;
        }
        if (!this.delivery.modalidadeRecebimento) {
            this.errorMessage = 'Selecione a modalidade de recebimento.';
            return;
        }

        this.isSaving = true;
        try {
            const result = await createSale({
                request: {
                    accountId: this.customer.accountId,
                    modalidadeRecebimento: this.delivery.modalidadeRecebimento,
                    shippingStreet: this.delivery.shippingStreet,
                    shippingCity: this.delivery.shippingCity,
                    shippingState: this.delivery.shippingState,
                    shippingPostalCode: this.delivery.shippingPostalCode,
                    items: this.cartItems.map((item) => ({
                        pricebookEntryId: item.pricebookEntryId,
                        quantity: item.quantity
                    }))
                }
            });
            this.confirmation = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Venda concluída',
                    message: result.message,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.errorMessage = this.reduceError(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Não foi possível finalizar',
                    message: this.errorMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isSaving = false;
        }
    }

    handleNewSale() {
        this.customer = null;
        this.cartItems = [];
        this.delivery = {
            modalidadeRecebimento: '',
            shippingStreet: '',
            shippingCity: '',
            shippingState: '',
            shippingPostalCode: '',
            valorFrete: 0,
            prazoDias: null
        };
        this.confirmation = null;
        this.errorMessage = undefined;
        const search = this.template.querySelector('c-techlar-customer-search');
        if (search && search.reset) {
            search.reset();
        }
    }

    handleOpenOrder() {
        if (!this.confirmation?.orderId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.confirmation.orderId,
                objectApiName: 'Order',
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
        return error?.message || 'Erro inesperado ao finalizar a venda.';
    }
}
