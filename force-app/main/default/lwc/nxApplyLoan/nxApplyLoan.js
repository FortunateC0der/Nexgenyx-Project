import { LightningElement } from 'lwc';

export default class NxApplyLoan extends LightningElement {
    currentStep = 1;

    firstName = '';
    lastName = '';
    email = '';
    phone = '';

    monthlyIncome = '';
    existingEmis = '';

    loanType = '';
    loanAmount = '';
    loanTenure = '';
    interestType = '';

    loanTypeOptions = [
        { label: 'Home Loan', value: 'Home Loan' },
        { label: 'Vehicle Loan', value: 'Vehicle Loan' },
        { label: 'Personal Loan', value: 'Personal Loan' }
    ];

    interestTypeOptions = [
        { label: 'Fixed', value: 'Fixed' },
        { label: 'Floating', value: 'Floating' }
    ];

    get isStep1() {
        return this.currentStep === 1;
    }

    get isStep2() {
        return this.currentStep === 2;
    }

    get isStep3() {
        return this.currentStep === 3;
    }

    get isStep4() {
        return this.currentStep === 4;
    }

    get isStep5() {
        return this.currentStep === 5;
    }

    get isFirstStep() {
        return this.currentStep === 1;
    }

    get step1Class() {
        return this.getStepClass(1);
    }

    get step2Class() {
        return this.getStepClass(2);
    }

    get step3Class() {
        return this.getStepClass(3);
    }

    get step4Class() {
        return this.getStepClass(4);
    }

    get step5Class() {
        return this.getStepClass(5);
    }

    getStepClass(step) {
        if (this.currentStep === step) {
            return 'progress-step active';
        }
        if (this.currentStep > step) {
            return 'progress-step completed';
        }
        return 'progress-step';
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleNext() {
        if (this.currentStep < 5) {
            this.currentStep += 1;
        }
    }

    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep -= 1;
        }
    }

    handleSubmit() {
        // Placeholder for later Salesforce save logic
        // eslint-disable-next-line no-alert
        alert('Application submitted successfully!');
    }
}