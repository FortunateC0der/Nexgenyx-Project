import { LightningElement, wire, track } from 'lwc';
import getMyLoansDashboard from '@salesforce/apex/NxMyLoansController.getMyLoansDashboard';

export default class NxMyLoans extends LightningElement {
    @track dashboard;
    @track message;
    @track errorMessage;

    @wire(getMyLoansDashboard)
    wiredDashboard({ error, data }) {
        if (data) {
            this.errorMessage = null;
            this.message = data.message ? data.message : null;

            this.dashboard = {
                ...data,
                applications: (data.applications || []).map((app) => ({
                    ...app,
                    formattedAmount: this.formatCurrency(app.amount),
                    formattedLastUpdated: this.formatDate(app.lastModifiedDate)
                }))
            };
        } else if (error) {
            this.dashboard = null;
            this.message = null;
            this.errorMessage = this.reduceError(error);
            // eslint-disable-next-line no-console
            console.error('NxMyLoans error:', error);
        }
    }

    get hasDashboard() {
        return this.dashboard && !this.message && !this.errorMessage;
    }

    get hasApplications() {
        return this.dashboard
            && this.dashboard.applications
            && this.dashboard.applications.length > 0;
    }

    formatCurrency(amount) {
        if (amount === null || amount === undefined) {
            return '-';
        }

        return new Intl.NumberFormat('en-ZA', {
            style: 'currency',
            currency: 'ZAR',
            minimumFractionDigits: 2
        }).format(amount);
    }

    formatDate(value) {
        if (!value) {
            return '-';
        }

        return new Intl.DateTimeFormat('en-ZA', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(new Date(value));
    }

    reduceError(error) {
        if (!error) {
            return 'Unknown error';
        }

        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }

        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }

        if (typeof error.message === 'string') {
            return error.message;
        }

        return 'An unexpected error occurred while loading your loans.';
    }
}