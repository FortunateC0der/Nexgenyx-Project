import { LightningElement, track } from 'lwc';

export default class NxEMIcal extends LightningElement {
    loanAmount = '';
    loanTerm = '12';
    interestRate = '';
    startDate = '';

    balloonAmount = '';
    interval = '12';
    stepAmount = '';

    repaymentType = 'amortization';

    monthlyPayment = 'R 0.00';
    totalPayment = 'R 0.00';
    totalInterest = 'R 0.00';
    maturityDate = '';

    repaymentOptions = [
        { label: 'Amortization', value: 'amortization' },
        { label: 'Balloon', value: 'balloon' },
        { label: 'Bullet', value: 'bullet' },
        { label: 'Step Up', value: 'stepUp' },
        { label: 'Step Down', value: 'stepDown' }
    ];

    loanTermOptions = [
        { label: '12', value: '12' },
        { label: '24', value: '24' },
        { label: '36', value: '36' },
        { label: '48', value: '48' },
        { label: '60', value: '60' },
        { label: '72', value: '72' },
        { label: '84', value: '84' }
    ];

    intervalOptions = [
        { label: '12', value: '12' },
        { label: '24', value: '24' },
        { label: '36', value: '36' },
        { label: '48', value: '48' },
        { label: '60', value: '60' },
        { label: '72', value: '72' },
        { label: '84', value: '84' }
    ];

    @track schedule = [];

    columns = [
        { label: 'Month', fieldName: 'month' },
        { label: 'Date', fieldName: 'date' },
        { label: 'Payment', fieldName: 'payment' },
        { label: 'Interest', fieldName: 'interest' },
        { label: 'Principal', fieldName: 'principal' },
        { label: 'Balance', fieldName: 'balance' }
    ];

    get isBalloon() {
        return this.repaymentType === 'balloon';
    }

    get isStep() {
        return this.repaymentType === 'stepUp' || this.repaymentType === 'stepDown';
    }

    handleTypeChange(event) {
        this.repaymentType = event.detail.value;
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-ZA', {
            style: 'currency',
            currency: 'ZAR',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value || 0);
    }

    calculate() {
        const P = parseFloat(this.loanAmount);
        const annualRate = parseFloat(this.interestRate);
        const n = parseInt(this.loanTerm, 10);

        if (!P || !annualRate || !n || !this.startDate) {
            return;
        }

        const r = annualRate / 100 / 12;

        let balance = P;
        let totalInterest = 0;
        let totalPayment = 0;
        let rows = [];
        let paymentForDisplay = 0;

        let date = new Date(this.startDate);

        let baseEMI = 0;

        if (r === 0) {
            baseEMI = P / n;
        } else {
            baseEMI = (P * r) / (1 - Math.pow(1 + r, -n));
        }

        paymentForDisplay = baseEMI;

        for (let i = 1; i <= n; i++) {
            let interest = balance * r;
            let payment = 0;
            let principal = 0;

            switch (this.repaymentType) {
                case 'amortization':
                    payment = baseEMI;
                    break;

                case 'balloon':
                    payment = baseEMI * 0.6;
                    if (i === n) {
                        payment += parseFloat(this.balloonAmount || 0);
                    }
                    break;

                case 'bullet':
                    payment = interest;
                    if (i === n) {
                        payment += balance;
                    }
                    break;

                case 'stepUp':
                    payment =
                        baseEMI +
                        Math.floor((i - 1) / parseInt(this.interval || 1, 10)) *
                            parseFloat(this.stepAmount || 0);
                    break;

                case 'stepDown':
                    payment =
                        baseEMI -
                        Math.floor((i - 1) / parseInt(this.interval || 1, 10)) *
                            parseFloat(this.stepAmount || 0);
                    if (payment < interest) {
                        payment = interest;
                    }
                    break;

                default:
                    payment = baseEMI;
            }

            principal = payment - interest;
            balance -= principal;

            if (balance < 0) {
                principal += balance;
                payment = principal + interest;
                balance = 0;
            }

            totalInterest += interest;
            totalPayment += payment;

            rows.push({
                month: i,
                date: date.toLocaleDateString('en-ZA', {
                    month: 'short',
                    year: 'numeric'
                }),
                payment: this.formatCurrency(payment),
                interest: this.formatCurrency(interest),
                principal: this.formatCurrency(principal),
                balance: this.formatCurrency(balance)
            });

            date.setMonth(date.getMonth() + 1);
        }

        const maturity = new Date(this.startDate);
        maturity.setMonth(maturity.getMonth() + n);

        this.schedule = rows;
        this.monthlyPayment = this.formatCurrency(paymentForDisplay);
        this.totalInterest = this.formatCurrency(totalInterest);
        this.totalPayment = this.formatCurrency(totalPayment);
        this.maturityDate = maturity.toISOString().split('T')[0];
    }
}