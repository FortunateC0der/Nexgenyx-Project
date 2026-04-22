public with sharing class nxCustomLogout {

    @AuraEnabled(cacheable=true)
    public static Boolean isUserLoggedIn() {
        return !String.isBlank(UserInfo.getUserId());
    }
}