import { LightningElement, api, track } from 'lwc';
import linkFilesToApplication from '@salesforce/apex/DocumentUploadController.linkFilesToApplication';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DocumentUploadPortal extends LightningElement {
    @api recordId; // This must be passed from the Parent LWC or Flow
    @track uploadedFileIds = [];

    // This runs every time a user drops a file into one of your 3 cards
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.uploadedFileIds.push(file.documentId);
        });
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' Files uploaded successfully.',
                variant: 'success',
            })
        );
    }

    // This runs when the "Submit Documents" button is clicked
    handleSubmit() {
        if (this.uploadedFileIds.length > 0) {
            linkFilesToApplication({ 
                recordId: this.recordId, 
                documentIds: this.uploadedFileIds 
            })
            .then(() => {
                alert('All documents have been linked to your application!');
                // Logic to navigate to a "Thank You" page
            })
            .catch(error => {
                console.error('Error:', error);
            });
        } else {
            alert('Please upload at least one document before submitting.');
        }
    }
}