import { LightningElement, api } from 'lwc';
import resolveCase from '@salesforce/apex/TechLarServiceController.resolveCase';

const RESULTADOS = [
    { label: 'Troca aprovada', value: 'Troca aprovada' },
    { label: 'Orientação prestada', value: 'Orientação prestada' },
    { label: 'Sem procedência', value: 'Sem procedência' }
];

export default class TechlarCaseConfirmation extends LightningElement {
    @api confirmation;
    resultado = 'Troca aprovada';
    options = RESULTADOS;
    isSaving = false;
    errorMessage;

    get isOpen() {
        return this.confirmation?.status && this.confirmation.status !== 'Closed';
    }

    get purchaseDateLabel() {
        if (!this.confirmation?.purchaseDate) {
            return '—';
        }
        const value = this.confirmation.purchaseDate;
        const date = typeof value === 'string' ? new Date(`${value}T00:00:00`) : new Date(value);
        return new Intl.DateTimeFormat('pt-BR').format(date);
    }

    get priorityLabel() {
        const value = this.confirmation?.priority;
        if (value === 'High') {
            return 'Alta';
        }
        if (value === 'Medium') {
            return 'Média';
        }
        if (value === 'Low') {
            return 'Baixa';
        }
        return value || '—';
    }

    handleResultado(event) {
        this.resultado = event.detail.value;
    }

    async handleResolve() {
        this.errorMessage = undefined;
        this.isSaving = true;
        try {
            const resolved = await resolveCase({
                caseId: this.confirmation.caseId,
                resultado: this.resultado
            });
            this.dispatchEvent(new CustomEvent('caseupdated', { detail: resolved }));
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível concluir o atendimento.';
        } finally {
            this.isSaving = false;
        }
    }
}
