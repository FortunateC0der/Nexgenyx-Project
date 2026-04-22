public with sharing class nxUserController {

    @AuraEnabled(cacheable=true)
    public static String getLoggedInUserName() {

        User u = [
            SELECT Contact.Account.Name, Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        return u.Contact.Account.Name;
    }
}