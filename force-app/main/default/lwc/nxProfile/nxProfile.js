import { LightningElement, wire } from 'lwc';
import getMyProfile from '@salesforce/apex/NxProfileController.getMyProfile';

export default class NxProfile extends LightningElement {
    profile;
    error;
    isLoading = true;

    @wire(getMyProfile)
    wiredProfile({ error, data }) {
        this.isLoading = false;

        if (data) {
            this.profile = data;
            this.error = undefined;
            console.log('NxProfile data:', JSON.stringify(data));
        } else if (error) {
            this.error = error;
            this.profile = undefined;
            console.error('NxProfile error:', JSON.stringify(error));
        }
    }

    get hasError() {
        return !!this.error;
    }

    get errorMessage() {
        if (this.error?.body?.message) {
            return this.error.body.message;
        }
        if (this.profile?.message) {
            return this.profile.message;
        }
        return 'An unexpected error occurred while loading your profile.';
    }

    get contactId() {
        return this.profile?.contactId || '';
    }

    get initials() {
        return this.profile?.initials || 'NA';
    }

    get fullName() {
        return this.profile?.fullName || 'Customer Profile';
    }

    get customerId() {
        return this.profile?.customerId || '-';
    }

    get firstName() {
        return this.profile?.firstName || '';
    }

    get lastName() {
        return this.profile?.lastName || '';
    }

    get email() {
        return this.profile?.email || '';
    }

    get phone() {
        return this.profile?.phone || '';
    }

    get idNumber() {
        return this.profile?.idNumber || '';
    }

    get dateOfBirth() {
        return this.profile?.dateOfBirth || null;
    }

    get street() {
        return this.profile?.street || '';
    }

    get suburb() {
        return this.profile?.suburb || '';
    }

    get city() {
        return this.profile?.city || '';
    }

    get province() {
        return this.profile?.province || '';
    }

    get postalCode() {
        return this.profile?.postalCode || '';
    }

    get country() {
        return this.profile?.country || '';
    }

    get employmentType() {
        return this.profile?.employmentType || '';
    }

    get employerName() {
        return this.profile?.employerName || '';
    }

    get jobTitle() {
        return this.profile?.jobTitle || '';
    }

    get workExperienceYears() {
        return this.profile?.workExperienceYears ?? null;
    }

    get emailDisplay() {
        return this.email || '-';
    }

    get phoneDisplay() {
        return this.phone || '-';
    }

    get statusDisplay() {
        return this.profile?.status || 'Active Borrower';
    }
}