public without sharing class LoanStatusHelper {

    public static String getLoanStatus(Id messagingSessionId) {
        if (messagingSessionId == null) {
            return 'Invalid Messaging Session Id.';
        }

        try {
            // Step 1: Get AccountId or ContactId from MessagingSession
            MessagingSession session = [
                SELECT Id, 
                       EndUserAccountId, 
                       EndUserContactId,
                       Logged_In_Contact_Id__c
                FROM MessagingSession
                WHERE Id = :messagingSessionId
                LIMIT 1
            ];

            Id accountId = session.EndUserAccountId;
            Id contactId = session.Logged_In_Contact_Id__c != null 
                           ? session.Logged_In_Contact_Id__c 
                           : session.EndUserContactId;

            if (accountId == null && contactId == null) {
                return 'No Account or Contact found for this messaging session.';
            }

            // Step 2: Determine the correct Loan Object (same logic as NxMyLoansController)
            String objectApiName = getLoanObjectApiName();
            if (String.isBlank(objectApiName)) {
                return 'Loan application object could not be found.';
            }

            // Step 3: Get field map and detect relationship + status fields (reuse same logic)
            Schema.SObjectType loanTypeToken = Schema.getGlobalDescribe().get(objectApiName);
            Map<String, Schema.SObjectField> fieldMap = loanTypeToken.getDescribe().fields.getMap();

            String relationshipField = pickField(fieldMap, new List<String>{
                'AccountId', 'ContactId', 'Borrower_Account__c', 'Borrower__c', 'Applicant__c'
            });

            String statusField = pickField(fieldMap, new List<String>{
                'Approval_Status__c', 'Status__c', 'Application_Status__c', 'status'
            });

            if (String.isBlank(relationshipField)) {
                return 'No borrower relationship field found on the loan object.';
            }
            if (String.isBlank(statusField)) {
                return 'No status field found on the loan object.';
            }

            // Step 4: Build dynamic WHERE clause
            String whereClause;
            if (accountId != null && (relationshipField == 'AccountId' || relationshipField == 'Borrower_Account__c')) {
                whereClause = relationshipField + ' = \'' + String.escapeSingleQuotes(accountId) + '\'';
            } 
            else if (contactId != null && (relationshipField == 'ContactId' || relationshipField == 'Borrower__c' || relationshipField == 'Applicant__c')) {
                whereClause = relationshipField + ' = \'' + String.escapeSingleQuotes(contactId) + '\'';
            } 
            else {
                // If we have AccountId but relationship is Contact-based, fallback to Contact
                if (accountId != null && contactId == null) {
                    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1];
                    if (!contacts.isEmpty()) {
                        contactId = contacts[0].Id;
                        whereClause = relationshipField + ' = \'' + String.escapeSingleQuotes(contactId) + '\'';
                    } else {
                        return 'Could not find Contact linked to Account for loan query.';
                    }
                } else {
                    return 'Could not determine relationship for loan query.';
                }
            }

            // Step 5: Query loans dynamically
            String soql = 'SELECT Id, ' + statusField + 
                         ' FROM ' + objectApiName + 
                         ' WHERE ' + whereClause + 
                         ' ORDER BY LastModifiedDate DESC';

            List<SObject> loans = Database.query(soql);

            if (loans.isEmpty()) {
                return 'No loan record found for this customer.';
            }

            // Step 6: Build response
            List<String> statuses = new List<String>();
            for (SObject loan : loans) {
                String status = (String) loan.get(statusField);
                statuses.add(String.isNotBlank(status) ? status : 'Unknown');
            }

            if (statuses.size() == 1) {
                return 'Loan Status: ' + statuses[0];
            } else {
                return 'Loan Status(es): ' + String.join(statuses, ', ');
            }

        } catch (QueryException qe) {
            return 'Error retrieving loan information: ' + qe.getMessage();
        } catch (Exception e) {
            return 'Unexpected error: ' + e.getMessage();
        }
    }

    // ===================================================================
    // Reused helper methods from NxMyLoansController (kept identical)
    // ===================================================================
    private static String getLoanObjectApiName() {
        Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();

        List<String> candidates = new List<String>{
            'ResidentialLoanApplication',
            'Residential_Loan_Application__c'
        };

        for (String candidate : candidates) {
            if (globalMap.containsKey(candidate)) {
                return candidate;
            }
        }
        return null;
    }

    private static String pickField(Map<String, Schema.SObjectField> fieldMap, List<String> candidates) {
        for (String candidate : candidates) {
            if (fieldMap.containsKey(candidate)) {
                return candidate;
            }
        }
        return null;
    }
}