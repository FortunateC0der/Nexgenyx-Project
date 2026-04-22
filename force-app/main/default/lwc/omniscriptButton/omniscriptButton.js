import { LightningElement, api } from 'lwc';
 
export default class OmniscriptButton extends LightningElement {
 
     @api recordId;
 
     launchFlow(){
        const flowName = 'Upload_Documents';
        const url = `/flow/${flowName}?recordId=${this.recordId}`;
        window.open('/nexgenyxbank/upload-documents', '_self');
     }
}