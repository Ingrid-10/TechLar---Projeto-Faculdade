import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import checkStores from '@salesforce/apex/TechLarOperationsController.checkStores';
import sendAgentMessage from '@salesforce/apex/TechLarAgentController.sendMessage';

const WELCOME = 'Posso verificar os mais vendidos e o estoque das lojas. A reposição só acontece quando você pedir.';

export default class TechlarOperationsPage extends NavigationMixin(LightningElement) {
    draft = '';
    busy = false;
    board;
    sessionId;
    recentTransfers = [];
    messages = [{ id: 'welcome', role: 'agent', text: WELCOME }];

    get hasBoard() {
        return this.board && this.board.stores;
    }

    get storeCards() {
        if (!this.hasBoard) {
            return [];
        }
        return this.board.stores.map((store) => ({
            ...store,
            cardClass: store.isCentral ? 'store-card store-card_central' : 'store-card',
            empty: !store.products || store.products.length === 0
        }));
    }

    handleDraft(event) {
        this.draft = event.target.value;
    }

    handleKey(event) {
        if (event.key === 'Enter') {
            this.handleSend();
        }
    }

    askSituation() {
        this.draft = 'Verifique os produtos mais vendidos e o estoque das lojas.';
        this.handleSend();
    }

    askReplenishment() {
        this.draft = 'Reponha as lojas que precisam.';
        this.handleSend();
    }

    async handleSend() {
        const text = (this.draft || '').trim();
        if (!text || this.busy) {
            return;
        }
        this.draft = '';
        this.messages = [...this.messages, { id: this.nextId(), role: 'user', text }];
        await this.runAgent(text);
    }

    async runAgent(text) {
        this.busy = true;
        try {
            const response = await sendAgentMessage({
                userMessage: text,
                sessionId: this.sessionId
            });
            this.sessionId = response.sessionId;
            this.recentTransfers = response.transfers || [];
            this.reply(response.message);
            const board = await checkStores();
            this.board = this.decorate(board);
        } catch (error) {
            this.reply(this.errorText(error));
        } finally {
            this.busy = false;
        }
    }

    decorate(board) {
        const transferByProduct = new Map(
            this.recentTransfers.map((transfer) => [
                `${transfer.destinationCode}-${transfer.productCode}`,
                transfer.transferId
            ])
        );
        const stores = (board.stores || []).map((store) => ({
            ...store,
            products: (store.products || []).map((product) => ({
                ...product,
                toneClass: `product product_${product.tone || 'ok'}`,
                quantityLabel: this.quantityLabel(product),
                transferId: product.transferId || transferByProduct.get(product.key),
                hasPath: Boolean(product.transferId || transferByProduct.get(product.key))
            }))
        }));
        return { ...board, stores };
    }

    quantityLabel(product) {
        if (product.changed) {
            return `${this.units(product.quantity)} → ${this.units(product.afterQuantity)}`;
        }
        return this.units(product.quantity);
    }

    units(value) {
        const amount = value == null ? 0 : value;
        return `${amount} un.`;
    }

    reply(text) {
        this.messages = [...this.messages, { id: this.nextId(), role: 'agent', text }];
    }

    openPath(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: { apiName: 'TechLar_Caminho_Transferencia' },
            state: { c__transferId: event.currentTarget.dataset.id }
        });
    }

    errorText(error) {
        return error && error.body && error.body.message
            ? error.body.message
            : 'Não consegui concluir este pedido.';
    }

    nextId() {
        return `${Date.now()}-${Math.random()}`;
    }
}
