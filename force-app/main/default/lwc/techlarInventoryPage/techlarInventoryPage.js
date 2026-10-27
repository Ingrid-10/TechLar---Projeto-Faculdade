import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getStore from '@salesforce/apex/TechLarInventoryController.getStore';
import getStock from '@salesforce/apex/TechLarInventoryController.getStock';
import searchProducts from '@salesforce/apex/TechLarInventoryController.searchProducts';
import transferStock from '@salesforce/apex/TechLarInventoryController.transferStock';
import getTransferView from '@salesforce/apex/TechLarInventoryController.getTransferView';

const STORE_APPS = {
    PAULISTA: { app: 'c__TechLar_Paulista', tab: 'TechLar_Estoque_Paulista' },
    MORUMBI: { app: 'c__TechLar_Morumbi', tab: 'TechLar_Estoque_Morumbi' },
    SANTANA: { app: 'c__TechLar_Santana', tab: 'TechLar_Estoque_Santana' }
};

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

    get otherAppLabel() {
        return this.confirmation ? `Abrir aplicativo ${this.confirmation.originName}` : '';
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
            this.confirmation = await transferStock({
                request: {
                    productId: this.product.productId,
                    originStoreId: this.originStoreId,
                    destinationStoreId: this.store.lojaId,
                    quantity: Number(this.quantity)
                }
            });
            this.product = {
                ...this.product,
                quantidade: this.confirmation.destinationBalance
            };
            await this.loadAllStock();
        } catch (error) {
            this.errorMessage = this.messageFrom(error, 'Não foi possível pedir o estoque.');
        } finally {
            this.isSaving = false;
        }
    }

    openOriginApp() {
        const target = STORE_APPS[this.confirmation?.originCode];
        if (!target) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__app',
            attributes: {
                appTarget: target.app,
                pageRef: {
                    type: 'standard__navItemPage',
                    attributes: {
                        apiName: target.tab
                    },
                    state: {
                        c__transferId: this.confirmation.transferId
                    }
                }
            }
        });
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
