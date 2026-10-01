import { LightningElement, api } from 'lwc';
import resolveCase from '@salesforce/apex/TechLarServiceController.resolveCase';
import getCase from '@salesforce/apex/TechLarServiceController.getCase';

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

    handleResultado(event) {
        this.resultado = event.detail.value;
    }

    handleOpen() {
        this.dispatchEvent(new CustomEvent('opencase'));
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('newcase'));
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

    async handleRefresh() {
        try {
            const latest = await getCase({ caseId: this.confirmation.caseId });
            this.dispatchEvent(new CustomEvent('caseupdated', { detail: latest }));
        } catch (error) {
            this.errorMessage = error?.body?.message || 'Não foi possível atualizar o atendimento.';
        }
    }
}
