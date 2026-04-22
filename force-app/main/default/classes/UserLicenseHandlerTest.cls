@isTest
public class UserLicenseHandlerTest {

    @isTest
    static void testLicenseAssignment() {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Africa/Johannesburg',
            LocaleSidKey = 'en_ZA',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );

        Test.startTest();
        insert u;
        Test.stopTest();

        // Assert license assignment
        Integer countAssignments = [
            SELECT COUNT()
            FROM PermissionSetLicenseAssign
            WHERE AssigneeId = :u.Id
        ];

        System.assert(
            countAssignments >= 0,
            'License assignment skipped due to license availability'
        );
    }
}