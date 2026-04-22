import { LightningElement, track } from 'lwc';
import registerUser from '@salesforce/apex/nxCustomRegister.registerUser';

export default class NxCustomRegister extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track password = '';
    @track errorMessage = '';
    @track isLoading = false;

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    async handleRegister() {
        this.errorMessage = '';
        this.isLoading = true;

        try {
            const result = await registerUser({
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                password: this.password
            });

            if (result && result.success) {
                window.location.href = result.redirectUrl || '/my-loans';
            } else {
                this.errorMessage = result?.message || 'Registration failed.';
            }
        } catch (error) {
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Something went wrong during registration.';
        } finally {
            this.isLoading = false;
        }
    }
}