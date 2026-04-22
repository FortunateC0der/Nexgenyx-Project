import { LightningElement } from 'lwc';

export default class NxApplyLoan extends LightningElement {
    loanTypeOptions = [
        { label: 'Home Loan', value: 'home' },
        { label: 'Vehicle Loan', value: 'vehicle' },
        { label: 'Personal Loan', value: 'personal' }
    ];

    interestTypeOptions = [
        { label: 'Fixed', value: 'fixed' },
        { label: 'Variable', value: 'variable' }
    ];
}