public with sharing class NxProfileController {

    public class ProfileData {
        @AuraEnabled public String userId;
        @AuraEnabled public String contactId;
        @AuraEnabled public String fullName;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String customerId;
        @AuraEnabled public String status;

        @AuraEnabled public String idNumber;
        @AuraEnabled public Date dateOfBirth;

        @AuraEnabled public String street;
        @AuraEnabled public String suburb;
        @AuraEnabled public String city;
        @AuraEnabled public String province;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;

        @AuraEnabled public String employmentType;
        @AuraEnabled public String employerName;
        @AuraEnabled public String jobTitle;
        @AuraEnabled public Decimal workExperienceYears;

        @AuraEnabled public String initials;
        @AuraEnabled public String message;
    }

    @AuraEnabled(cacheable=true)
    public static ProfileData getMyProfile() {
        ProfileData profile = new ProfileData();
        profile.status = 'Active Borrower';

        try {
            Id currentUserId = UserInfo.getUserId();

            List<User> users = [
                SELECT Id, ContactId, FirstName, LastName, Name, Email
                FROM User
                WHERE Id = :currentUserId
                LIMIT 1
            ];

            if (users.isEmpty()) {
                profile.message = 'Could not find the logged-in user.';
                return profile;
            }

            User currentUser = users[0];
            profile.userId = currentUser.Id;

            if (currentUser.ContactId == null) {
                profile.fullName = currentUser.Name;
                profile.firstName = currentUser.FirstName;
                profile.lastName = currentUser.LastName;
                profile.email = currentUser.Email;
                profile.initials = buildInitials(currentUser.FirstName, currentUser.LastName);
                profile.message = 'Your user profile is not linked to a Contact yet.';
                return profile;
            }

            profile.contactId = currentUser.ContactId;
            Id contactId = currentUser.ContactId;

            Map<String, Schema.SObjectField> contactFieldMap = Contact.SObjectType.getDescribe().fields.getMap();

            String idNumberField = pickField(contactFieldMap, new List<String>{
                'ID_Number__c',
                'Id_Number__c',
                'ID_Passport_Number__c',
                'Passport_Number__c'
            });

            String dobField = pickField(contactFieldMap, new List<String>{
                'Birthdate',
                'Date_of_Birth__c',
                'DOB__c'
            });

            String suburbField = pickField(contactFieldMap, new List<String>{
                'Suburb__c',
                'Neighborhood__c'
            });

            String provinceField = pickField(contactFieldMap, new List<String>{
                'Province__c',
                'State_Province__c'
            });

            String employmentTypeField = pickField(contactFieldMap, new List<String>{
                'Employment_Type__c'
            });

            String employerNameField = pickField(contactFieldMap, new List<String>{
                'Employer_Name__c',
                'Employer__c'
            });

            String jobTitleField = pickField(contactFieldMap, new List<String>{
                'Job_Title__c',
                'Title'
            });

            String workExperienceField = pickField(contactFieldMap, new List<String>{
                'Work_Experience_Years__c',
                'Years_of_Experience__c'
            });

            List<String> selectFields = new List<String>{
                'Id',
                'FirstName',
                'LastName',
                'Name',
                'Email',
                'Phone',
                'MailingStreet',
                'MailingCity',
                'MailingPostalCode',
                'MailingCountry'
            };

            if (contactFieldMap.containsKey('MailingState')) {
                selectFields.add('MailingState');
            }
            if (idNumberField != null) {
                selectFields.add(idNumberField);
            }
            if (dobField != null) {
                selectFields.add(dobField);
            }
            if (suburbField != null) {
                selectFields.add(suburbField);
            }
            if (provinceField != null && provinceField != 'MailingState') {
                selectFields.add(provinceField);
            }
            if (employmentTypeField != null) {
                selectFields.add(employmentTypeField);
            }
            if (employerNameField != null) {
                selectFields.add(employerNameField);
            }
            if (jobTitleField != null && !selectFields.contains(jobTitleField)) {
                selectFields.add(jobTitleField);
            }
            if (workExperienceField != null) {
                selectFields.add(workExperienceField);
            }

            String soql =
                'SELECT ' + String.join(selectFields, ', ') +
                ' FROM Contact WHERE Id = :contactId LIMIT 1';

            List<SObject> contacts = Database.query(soql);

            if (contacts.isEmpty()) {
                profile.fullName = currentUser.Name;
                profile.firstName = currentUser.FirstName;
                profile.lastName = currentUser.LastName;
                profile.email = currentUser.Email;
                profile.initials = buildInitials(currentUser.FirstName, currentUser.LastName);
                profile.message = 'Could not find the Contact linked to your user.';
                return profile;
            }

            Contact c = (Contact) contacts[0];

            profile.fullName = c.Name;
            profile.firstName = c.FirstName;
            profile.lastName = c.LastName;
            profile.email = c.Email != null ? c.Email : currentUser.Email;
            profile.phone = c.Phone;
            profile.customerId = 'NXG-' + String.valueOf(c.Id).right(6).toUpperCase();
            profile.initials = buildInitials(c.FirstName, c.LastName);

            if (idNumberField != null) {
                profile.idNumber = stringValue(c.get(idNumberField));
            }

            if (dobField != null && c.get(dobField) != null) {
                Object dobValue = c.get(dobField);
                if (dobValue instanceof Date) {
                    profile.dateOfBirth = (Date) dobValue;
                }
            }

            profile.street = c.MailingStreet;
            profile.city = c.MailingCity;
            profile.postalCode = c.MailingPostalCode;
            profile.country = c.MailingCountry;

            if (contactFieldMap.containsKey('MailingState')) {
                profile.province = c.MailingState;
            }

            if (suburbField != null) {
                profile.suburb = stringValue(c.get(suburbField));
            }

            if (provinceField != null) {
                profile.province = stringValue(c.get(provinceField));
            }

            if (employmentTypeField != null) {
                profile.employmentType = stringValue(c.get(employmentTypeField));
            }

            if (employerNameField != null) {
                profile.employerName = stringValue(c.get(employerNameField));
            }

            if (jobTitleField != null) {
                profile.jobTitle = stringValue(c.get(jobTitleField));
            }

            if (workExperienceField != null && c.get(workExperienceField) != null) {
                Object expValue = c.get(workExperienceField);
                if (expValue instanceof Decimal) {
                    profile.workExperienceYears = (Decimal) expValue;
                } else {
                    try {
                        profile.workExperienceYears = Decimal.valueOf(String.valueOf(expValue));
                    } catch (Exception ex) {
                    }
                }
            }

            return profile;

        } catch (Exception e) {
            profile.message = e.getMessage();
            return profile;
        }
    }

    private static String pickField(Map<String, Schema.SObjectField> fieldMap, List<String> candidates) {
        for (String candidate : candidates) {
            if (fieldMap.containsKey(candidate)) {
                return candidate;
            }
        }
        return null;
    }

    private static String buildInitials(String firstName, String lastName) {
        String initials = '';
        if (!String.isBlank(firstName)) {
            initials += firstName.substring(0, 1).toUpperCase();
        }
        if (!String.isBlank(lastName)) {
            initials += lastName.substring(0, 1).toUpperCase();
        }
        if (String.isBlank(initials)) {
            initials = 'NA';
        }
        return initials;
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}