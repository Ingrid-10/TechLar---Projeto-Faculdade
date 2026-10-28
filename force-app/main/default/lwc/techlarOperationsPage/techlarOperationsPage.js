import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import checkStores from '@salesforce/apex/TechLarOperationsController.checkStores';
import replenishStores from '@salesforce/apex/TechLarOperationsController.replenishStores';

const WELCOME = 'Posso verificar os mais vendidos e o estoque das lojas. A reposição só acontece quando você pedir.';

export default class TechlarOperationsPage extends NavigationMixin(LightningElement) {
    draft = '';
    busy = false;
    board;
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
        const normalized = text.toLowerCase();
        if (/repon|reposi|transfer/.test(normalized)) {
            await this.run(replenishStores);
            return;
        }
        if (/verif|estoque|vendid|loja|analis|situa/.test(normalized)) {
            await this.run(checkStores);
            return;
        }
        this.reply('Eu verifico os mais vendidos e o estoque das lojas, e reponho o que estiver abaixo de 5 quando você pedir.');
    }

    async run(action) {
        this.busy = true;
        try {
            const board = await action();
            this.board = this.decorate(board);
            this.reply(board.message);
        } catch (error) {
            this.reply(this.errorText(error));
        } finally {
            this.busy = false;
        }
    }

    decorate(board) {
        const stores = (board.stores || []).map((store) => ({
            ...store,
            products: (store.products || []).map((product) => ({
                ...product,
                toneClass: `product product_${product.tone || 'ok'}`,
                quantityLabel: this.quantityLabel(product),
                hasPath: Boolean(product.transferId)
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
