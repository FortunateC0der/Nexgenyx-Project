import { LightningElement } from 'lwc';

import FAST from '@salesforce/resourceUrl/fast';
import APPLY from '@salesforce/resourceUrl/Esay';
import EMI from '@salesforce/resourceUrl/calculator';
import LOAN from '@salesforce/resourceUrl/loan';
import SECURE from '@salesforce/resourceUrl/shield';
import TRACK from '@salesforce/resourceUrl/clock';

export default class nxCustomHome extends LightningElement {

    features = [
        {
            icon: FAST,
            title: 'Fast Loan Approval',
            description: 'Get pre-qualified instantly with our smart eligibility system.'
        },
        {
            icon: APPLY,
            title: 'Easy Online Application',
            description: 'Apply anytime with a simple digital process.'
        },
        {
            icon: EMI,
            title: 'Smart EMI Calculator',
            description: 'Plan repayments with accurate EMI calculations.'
        },
        {
            icon: LOAN,
            title: 'Flexible Loan Options',
            description: 'Choose from personal and auto loans.'
        },
        {
            icon: SECURE,
            title: 'Secure Process',
            description: 'Your data is protected with advanced security.'
        },
        {
            icon: TRACK,
            title: 'Real-Time Tracking',
            description: 'Monitor your loan status in real time.'
        }
    ];
}