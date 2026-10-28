import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import transferPath from '@salesforce/apex/TechLarOperationsController.transferPath';

export default class TechlarTransferPath extends NavigationMixin(LightningElement) {
    view;
    errorMessage;
    transferId;

    @wire(CurrentPageReference)
    setPage(reference) {
        const nextId = reference && reference.state ? reference.state.c__transferId : null;
        if (!nextId || nextId === this.transferId) {
            return;
        }
        this.transferId = nextId;
        this.load();
    }

    async load() {
        this.errorMessage = null;
        try {
            this.view = await transferPath({ transferId: this.transferId });
        } catch (error) {
            this.view = null;
            this.errorMessage = error && error.body && error.body.message
                ? error.body.message
                : 'Não encontrei essa transferência.';
        }
    }

    get hasView() {
        return Boolean(this.view);
    }

    get quantityLabel() {
        return this.view ? `${this.view.quantity} unidades` : '';
    }

    back() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: { apiName: 'TechLar_Operacoes' }
        });
    }
}
