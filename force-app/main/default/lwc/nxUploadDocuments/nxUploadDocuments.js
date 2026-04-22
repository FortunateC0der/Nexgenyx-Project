import { LightningElement, api } from 'lwc';

export default class NxUploadDocuments extends LightningElement {
    flowApiName = 'Upload_Documents';

    @api recordId;

    get inputVariables() {
        const variables = [];

        if (this.recordId) {
            variables.push({
                name: 'recordId',
                type: 'String',
                value: this.recordId
            });
        }

        return variables;
    }

    handleStatusChange(event) {
        const status = event.detail.status;

        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            window.location.href = '/nexgenyxbank/my-loans';
        }
    }
}