import { LightningElement, wire } from 'lwc';
import isUserLoggedIn from '@salesforce/apex/nxCustomLogout.isUserLoggedIn';

export default class NxHeader extends LightningElement {

    isLoggedIn = false;

    @wire(isUserLoggedIn)
    wiredUser({ data }) {
        if (data) {
            this.isLoggedIn = data;
        }
    }
    handleLogout() {
    window.location.href = '/nexgenyxbank/secur/logout.jsp?retUrl=/nexgenyxbank/custom-login';
}
}