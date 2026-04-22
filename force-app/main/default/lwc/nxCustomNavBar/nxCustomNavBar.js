import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';

export default class NxCustomNavBar extends LightningElement {
    isGuestUser = isGuest;
    menuOpen = false;

    toggleMenu() {
        this.menuOpen = !this.menuOpen;
    }

    navigateTo(path) {
        window.location.href = path;
    }

    goHome() {
        this.navigateTo('/nexgenyxbank/');
    }

    goProducts() {
        this.navigateTo('/nexgenyxbank/loan-products');
    }

    goMyLoans() {
        this.navigateTo('/nexgenyxbank/my-loans');
    }

    goProfile() {
        this.navigateTo('/nexgenyxbank/profile');
    }

    goLogin() {
        this.navigateTo('/nexgenyxbank/login');
    }

    goRegister() {
        this.navigateTo('/nexgenyxbank/custom-register');
    }

    handleLogout() {
        window.location.href = '/nexgenyxbank/secur/logout.jsp?retUrl=/nexgenyxbank/';
    }
}