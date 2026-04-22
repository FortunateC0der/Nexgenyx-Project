import { LightningElement, track } from 'lwc';
import loginUser from '@salesforce/apex/nxLoginController.loginUser';

export default class nxCustomLogin extends LightningElement {

    email = '';
    password = '';
    @track accountName = '';
    @track isLoggedIn = false;

    handleEmail(event) {
        this.email = event.target.value;
    }

    handlePassword(event) {
        this.password = event.target.value;
    }

    handleLogin() {
    loginUser({ email: this.email, password: this.password })
        .then(result => {
            if (result.startsWith('ERROR')) {
                alert(result);
            } else {

                // ✅ STORE SESSION
                sessionStorage.setItem('username', result);

                // ✅ REDIRECT TO HOME
                window.location.href = '/nexgenyxbank/';
            }
        })
        .catch(error => {
            console.error(error);
        });
}
}