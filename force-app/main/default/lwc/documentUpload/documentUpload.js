import { LightningElement, api } from 'lwc';

export default class DocumentUpload extends LightningElement {
    @api recordId;

    // These MUST match the 'property name' in your .js-meta.xml
    @api idUploaded = false;
    @api addressUploaded = false;
    @api incomeUploaded = false;

    // Handler for ID Proof
    handleIdUpload(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.idUploaded = true;
        }
    }

    // Handler for Address Proof
    handleAddressUpload(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.addressUploaded = true;
        }
    }

    // Handler for Income Proof
    handleIncomeUpload(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.incomeUploaded = true;
        }
    }

    get acceptedFormats() {
    return ['.pdf', '.png', '.jpg', '.jpeg'];
    }
}