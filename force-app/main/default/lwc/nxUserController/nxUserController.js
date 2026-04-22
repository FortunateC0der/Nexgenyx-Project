import { LightningElement, wire } from 'lwc';
import getLoggedInUserName from '@salesforce/apex/nxUserController.getLoggedInUserName';

export default class nxUserHeader extends LightningElement {

    userName;

    @wire(getLoggedInUserName)
    wiredUser({ data, error }) {
        if (data) {
            this.userName = data;
        }
    }
}