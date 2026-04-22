public with sharing class nxLoginController {
    @AuraEnabled
    public static String loginUser(String email, String password) {
        try {
            // Attempt login
            PageReference homePage = Site.login(email, password, '/nexgenyxbank/');
            if (homePage == null) {
                return 'ERROR: Invalid credentials';
            }
            return 'SUCCESS';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }
}