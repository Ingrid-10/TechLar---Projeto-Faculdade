import { LightningElement, api } from 'lwc';

export default class TechlarServiceOrders extends LightningElement {
    @api orders = [];
    @api selectedItem;
    @api isLoading = false;
    @api hasCustomer = false;
    @api readOnly = false;

    get showEmptyCustomer() {
        return !this.hasCustomer;
    }

    get showEmptyOrders() {
        return this.hasCustomer && !this.isLoading && (!this.orders || this.orders.length === 0);
    }

    get rows() {
        return (this.orders || []).map((order) => ({
            ...order,
            formattedDate: this.formatDate(order.effectiveDate),
            formattedTotal: this.formatPrice(order.totalAmount),
            items: (order.items || []).map((item) => ({
                ...item,
                key: item.orderItemId,
                selected: this.selectedItem?.orderItemId === item.orderItemId,
                buttonLabel: this.selectedItem?.orderItemId === item.orderItemId ? 'Selecionado' : 'Selecionar',
                buttonVariant: this.selectedItem?.orderItemId === item.orderItemId ? 'brand' : 'neutral',
                formattedLine: this.formatPrice(item.lineTotal)
            }))
        }));
    }

    handleSelect(event) {
        const orderItemId = event.currentTarget.dataset.item;
        for (const order of this.orders || []) {
            const item = (order.items || []).find((row) => row.orderItemId === orderItemId);
            if (item) {
                this.dispatchEvent(
                    new CustomEvent('itemselected', {
                        detail: {
                            orderId: order.orderId,
                            orderNumber: order.orderNumber,
                            effectiveDate: order.effectiveDate,
                            orderItemId: item.orderItemId,
                            productId: item.productId,
                            productName: item.productName,
                            productCode: item.productCode
                        }
                    })
                );
                return;
            }
        }
    }

    formatDate(value) {
        if (!value) {
            return '';
        }
        const date = typeof value === 'string' ? new Date(`${value}T00:00:00`) : new Date(value);
        return new Intl.DateTimeFormat('pt-BR').format(date);
    }

    formatPrice(value) {
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
    }
}
