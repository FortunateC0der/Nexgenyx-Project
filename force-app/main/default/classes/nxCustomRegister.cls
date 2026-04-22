public without sharing class nxCustomRegister {

    public class RegisterResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String redirectUrl;
    }

    @AuraEnabled
    public static RegisterResponse registerUser(String firstName, String lastName, String email, String password) {
        RegisterResponse res = new RegisterResponse();
        res.success = false;
        res.redirectUrl = null;

        try {
            // Basic validation
            if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email) || String.isBlank(password)) {
                res.message = 'Please complete all fields.';
                return res;
            }

            firstName = firstName.trim();
            lastName = lastName.trim();
            email = email.trim().toLowerCase();

            if (!isValidEmail(email)) {
                res.message = 'Please enter a valid email address.';
                return res;
            }

            if (password.length() < 8) {
                res.message = 'Password must be at least 8 characters.';
                return res;
            }

            // Check if user already exists in this org
            List<User> existingUsers = [
                SELECT Id, Username
                FROM User
                WHERE Username = :email
                LIMIT 1
            ];

            if (!existingUsers.isEmpty()) {
                res.message = 'A user with this email already exists.';
                return res;
            }

            // Need an internal owner with a role for external user creation
            List<User> owners = [
                SELECT Id, UserRoleId
                FROM User
                WHERE IsActive = true
                AND UserRoleId != null
                AND UserType = 'Standard'
                LIMIT 1
            ];

            if (owners.isEmpty()) {
                res.message = 'No internal account owner with a role was found.';
                return res;
            }

            User accountOwner = owners[0];

            // Find a valid external profile
            List<Profile> profiles = [
                SELECT Id, Name
                FROM Profile
                WHERE Name IN (
                    'Customer Community Plus User Clone',
                    'Customer Community Plus Login Clone',
                    'Customer Community Plus User',
                    'Customer Community User',
                    'Customer Community Login User',
                    'Customer Community Plus Login User'
                )
                ORDER BY Name
            ];

            if (profiles.isEmpty()) {
                res.message = 'No valid community profile was found.';
                return res;
            }

            Profile externalProfile;
            for (Profile p : profiles) {
                if (p.Name == 'Customer Community Plus User Clone') {
                    externalProfile = p;
                    break;
                }
            }
            if (externalProfile == null) {
                externalProfile = profiles[0];
            }

            // Find a Person Account record type
            List<RecordType> personAccountRTs = [
                SELECT Id, Name, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Account'
                AND IsActive = true
                AND IsPersonType = true
                LIMIT 1
            ];

            if (personAccountRTs.isEmpty()) {
                res.message = 'No active Person Account record type was found.';
                return res;
            }

            Id personAccountRecordTypeId = personAccountRTs[0].Id;

            // Create Person Account
            Account pa = new Account(
                RecordTypeId = personAccountRecordTypeId,
                OwnerId = accountOwner.Id,
                FirstName = firstName,
                LastName = lastName,
                PersonEmail = email
            );
            insert pa;

            // Re-query to get PersonContactId
            pa = [
                SELECT Id, PersonContactId, IsPersonAccount
                FROM Account
                WHERE Id = :pa.Id
                LIMIT 1
            ];

            if (pa.PersonContactId == null) {
                res.message = 'Person Account was created, but Person Contact was not available.';
                return res;
            }

            // Alias max length 8
            String aliasBase = (firstName + lastName).replaceAll('[^a-zA-Z0-9]', '');
            if (String.isBlank(aliasBase)) {
                aliasBase = 'user';
            }
            String aliasValue = aliasBase.length() > 8 ? aliasBase.substring(0, 8) : aliasBase;

            // Community nickname must be unique
            String nicknameBase = (firstName + lastName).replaceAll('[^a-zA-Z0-9]', '');
            if (String.isBlank(nicknameBase)) {
                nicknameBase = 'borrower';
            }
            String communityNickname = nicknameBase + String.valueOf(DateTime.now().getTime());

            // Create Experience Cloud user linked to Person Account contact
            User portalUser = new User(
                Username = email,
                Email = email,
                FirstName = firstName,
                LastName = lastName,
                Alias = aliasValue,
                CommunityNickname = communityNickname,
                TimeZoneSidKey = 'Africa/Johannesburg',
                LocaleSidKey = 'en_ZA',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = externalProfile.Id,
                ContactId = pa.PersonContactId
            );

            String newUserId = Site.createExternalUser(portalUser, pa.Id, password);

            if (String.isBlank(newUserId)) {
                res.message = 'User could not be created.';
                return res;
            }

            // Log in immediately and redirect
            PageReference loginRef = Site.login(email, password, '/nexgenyxbank/my-loans');

            res.success = true;
            res.message = 'Registration successful.';
            res.redirectUrl = (loginRef != null) ? loginRef.getUrl() : '/nexgenyxbank/my-loans';
            return res;

        } catch (QueryException qe) {
            res.message = 'Configuration error: ' + qe.getMessage();
            return res;
        } catch (DmlException de) {
            res.message = 'Save failed: ' + de.getDmlMessage(0);
            return res;
        } catch (Exception e) {
            res.message = e.getMessage();
            return res;
        }
    }

    private static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }

        Pattern emailPattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        Matcher emailMatcher = emailPattern.matcher(email);
        return emailMatcher.matches();
    }
}