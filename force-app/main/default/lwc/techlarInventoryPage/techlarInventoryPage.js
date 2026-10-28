import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getStore from '@salesforce/apex/TechLarInventoryController.getStore';
import getStock from '@salesforce/apex/TechLarInventoryController.getStock';
import searchProducts from '@salesforce/apex/TechLarInventoryController.searchProducts';
import requestStock from '@salesforce/apex/TechLarInventoryController.requestStock';
import listOpenTransfers from '@salesforce/apex/TechLarInventoryController.listOpenTransfers';
import resumeStock from '@salesforce/apex/TechLarInventoryController.resumeStock';
import advanceStock from '@salesforce/apex/TechLarInventoryController.advanceStock';
import getTransferView from '@salesforce/apex/TechLarInventoryController.getTransferView';

export default class TechlarInventoryPage extends NavigationMixin(LightningElement) {
    @api storeCode;
    @api pageMode = 'loja';

    store;
    destinations = [];
    searchTerm = '';
    results = [];
    stockLines = [];
    product;
    originStoreId;
    quantity = 5;
    confirmation;
    receivedTransfer;
    errorMessage;
    isSearching = false;
    isSaving = false;
    searched = false;
    transferId;
    openTransfers = [];
    showOpenTransfers = false;

    @wire(CurrentPageReference)
    receivePage(pageRef) {
        const nextId = pageRef?.state?.c__transferId;
        if (!nextId || nextId === this.transferId) {
            return;
        }
        this.transferId = nextId;
        this.loadReceivedTransfer();
    }

    connectedCallback() {
        this.loadStore();
    }

    get isGeneral() {
        return this.pageMode === 'geral';
    }

    get storeName() {
        return this.store?.name || 'Loja';
    }

    get pageSubtitle() {
        return this.isGeneral ? 'Estoque geral — pedir de outra loja' : 'Estoque desta loja';
    }

    get searchLabel() {
        return this.isGeneral ? 'Pesquisar produto em todas as lojas' : 'Pesquisar produto nesta loja';
    }

    get emptyMessage() {
        return this.isGeneral ? 'Nenhum produto com estoque encontrado.' : 'Nenhum produto com estoque nesta loja.';
    }

    get resultItemClass() {
        return this.isGeneral ? '' : 'result-row';
    }

    get hasResults() {
        return this.results.length > 0;
    }

    get showEmpty() {
        return this.searched && !this.isSearching && !this.hasResults;
    }

    get hasProduct() {
        return Boolean(this.product);
    }

    get balanceLabel() {
        return this.formatUnits(this.product?.quantidade);
    }

    get originOptions() {
        return this.destinations.map((store) => ({
            label: store.name,
            value: store.lojaId
        }));
    }

    get transferDisabled() {
        return this.isSaving || !this.store || !this.originStoreId || !this.quantity;
    }

    get canAdvance() {
        return Boolean(this.confirmation && this.confirmation.advanceLabel);
    }

    get advanceLabel() {
        return this.confirmation ? this.confirmation.advanceLabel : '';
    }

    get openTransfersLabel() {
        const count = this.openTransfers.length;
        return count ? `Transferências em aberto (${count})` : 'Transferências em aberto';
    }

    get hasOpenTransfers() {
        return this.openTransfers.length > 0;
    }

    get noOpenTransfers() {
        return this.showOpenTransfers && !this.hasOpenTransfers;
    }

    get confirmationDecrease() {
        if (!this.confirmation) {
            return '';
        }
        return `${this.confirmation.originName}: ${this.formatUnits(this.confirmation.originBalanceBefore)} → ${this.formatUnits(this.confirmation.originBalance)}`;
    }

    get originDecrease() {
        const view = this.receivedTransfer;
        if (!view) {
            return '';
        }
        return `${view.originName}: ${this.formatUnits(view.originBefore)} → ${this.formatUnits(view.originAfter)}`;
    }

    get destinationIncrease() {
        const view = this.receivedTransfer;
        if (!view) {
            return '';
        }
        return `${view.destinationName}: ${this.formatUnits(view.destinationBefore)} → ${this.formatUnits(view.destinationAfter)}`;
    }

    handleTermChange(event) {
        this.searchTerm = event.target.value;
    }

    handleKey(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    handleQuantityChange(event) {
        this.quantity = event.target.value;
    }

    handleOriginChange(event) {
        this.originStoreId = event.detail.value;
    }

    handleAddToCart(event) {
        const productId = event.currentTarget.dataset.id;
        if (!productId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'TechLar_Venda_Assistida'
            },
            state: {
                c__productId: productId,
                c__cartToken: String(Date.now())
            }
        });
    }

    async loadStore() {
        try {
            const context = await getStore({ storeCode: this.storeCode });
            this.store = context;
            this.destinations = context.destinations || [];
            if (this.isGeneral) {
                this.refreshOpenTransfers();
            }
            if (this.transferId) {
                this.loadReceivedTransfer();
            }
        } catch (error) {
            this.errorMessage = this.messageFrom(error, 'Não foi possível abrir a loja.');
        }
    }

    async handleSearch() {
        this.isSearching = true;
        this.errorMessage = undefined;
        this.searched = true;
        try {
            this.results = (await searchProducts({
                searchTerm: this.searchTerm,
                storeCode: this.isGeneral ? null : this.storeCode
            })).map((item) => ({
                ...item,
                quantityLabel: item.quantidade == null ? item.productCode : `${item.productCode} · ${this.formatUnits(item.quantidade)} nesta loja`
            }));
        } catch (error) {
            this.results = [];
            this.errorMessage = this.messageFrom(error, 'Não foi possível pesquisar o produto.');
        } finally {
            this.isSearching = false;
        }
    }

    async handleSelect(event) {
        const productId = event.currentTarget.dataset.id;
        this.selectProduct(this.results.find((item) => item.productId === productId));
        if (this.isGeneral && this.product) {
            await this.loadAllStock();
        }
    }

    selectProduct(selected) {
        this.product = selected ? { ...selected } : undefined;
        this.stockLines = [];
        this.confirmation = undefined;
        this.originStoreId = undefined;
        this.errorMessage = undefined;
    }

    async loadAllStock() {
        try {
            const view = await getStock({ productId: this.product.productId });
            this.stockLines = (view.lines || []).map((line) => ({
                ...line,
                label: this.formatUnits(line.quantidade)
            }));
            const mine = this.stockLines.find((line) => line.lojaCodigo === this.storeCode);
            if (mine) {
                this.product = { ...this.product, quantidade: mine.quantidade };
            }
        } catch (error) {
            this.stockLines = [];
            this.errorMessage = this.messageFrom(error, 'Não foi possível consultar o estoque.');
        }
    }

    async handleTransfer() {
        this.isSaving = true;
        this.errorMessage = undefined;
        this.confirmation = undefined;
        try {
            this.applyConfirmation(await requestStock({
                request: {
                    productId: this.product.productId,
                    originStoreId: this.originStoreId,
                    destinationStoreId: this.store.lojaId,
                    quantity: Number(this.quantity)
                }
            }));
            await this.loadAllStock();
            await this.refreshOpenTransfers();
        } catch (error) {
            this.errorMessage = this.messageFrom(error, 'Não foi possível pedir o estoque.');
        } finally {
            this.isSaving = false;
        }
    }

    async handleAdvance() {
        if (!this.confirmation || !this.confirmation.transferId) {
            return;
        }
        this.isSaving = true;
        this.errorMessage = undefined;
        try {
            this.applyConfirmation(await advanceStock({ transferId: this.confirmation.transferId }));
            await this.loadAllStock();
            await this.refreshOpenTransfers();
        } catch (error) {
            this.errorMessage = this.messageFrom(error, 'Não foi possível avançar a transferência.');
        } finally {
            this.isSaving = false;
        }
    }

    toggleOpenTransfers() {
        this.showOpenTransfers = !this.showOpenTransfers;
    }

    async handleOpenTransfer(event) {
        const transferId = event.currentTarget.dataset.id;
        if (!transferId) {
            return;
        }
        this.isSaving = true;
        this.errorMessage = undefined;
        try {
            this.applyConfirmation(await resumeStock({ transferId }));
            await this.loadAllStock();
            this.refreshOpenTransfers();
        } catch (error) {
            this.errorMessage = this.messageFrom(error, 'Não foi possível abrir a transferência.');
        } finally {
            this.isSaving = false;
        }
    }

    async refreshOpenTransfers() {
        if (!this.isGeneral || !this.storeCode) {
            return;
        }
        try {
            this.decorateOpenTransfers(await listOpenTransfers({ storeCode: this.storeCode }));
        } catch (error) {
            this.openTransfers = [];
            this.errorMessage = this.messageFrom(error, 'Não foi possível consultar as transferências em aberto.');
        }
    }

    applyConfirmation(result) {
        this.confirmation = result;
        this.product = {
            ...(this.product || {}),
            productId: result.productId,
            name: result.productName,
            productCode: result.productCode,
            quantidade: result.destinationBalance
        };
        this.decorateOpenTransfers(this.openTransfers);
        Promise.resolve().then(() => {
            const node = this.template.querySelector('.confirmation');
            if (node) {
                node.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
        });
    }

    decorateOpenTransfers(rows) {
        const currentId = this.confirmation && this.confirmation.transferId;
        this.openTransfers = (rows || []).map((row) => ({
            ...row,
            rowClass: row.transferId === currentId ? 'result-btn result-btn_selected' : 'result-btn'
        }));
    }

    async loadReceivedTransfer() {
        try {
            const view = await getTransferView({ transferId: this.transferId });
            this.receivedTransfer = view;
            const isOrigin = view.originCode === this.storeCode;
            const isDestination = view.destinationCode === this.storeCode;
            if (isOrigin || isDestination) {
                this.product = {
                    productId: view.productId,
                    name: view.productName,
                    productCode: view.productCode,
                    quantidade: isOrigin ? view.originAfter : view.destinationAfter
                };
            }
        } catch (error) {
            this.errorMessage = this.messageFrom(error, 'Não foi possível abrir a transferência.');
        }
    }

    formatUnits(value) {
        const amount = Number(value || 0);
        return amount === 1 ? '1 unidade' : `${amount} unidades`;
    }

    messageFrom(error, fallback) {
        return error?.body?.message || fallback;
    }
}
