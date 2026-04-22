public with sharing class NxMyLoansController {

    public class DashboardSummary {
        @AuraEnabled public Integer totalApplications;
        @AuraEnabled public Integer approvedCount;
        @AuraEnabled public Integer inProgressCount;
        @AuraEnabled public Integer rejectedCount;
        @AuraEnabled public List<LoanRow> applications;
        @AuraEnabled public String message;
    }

    public class LoanRow {
        @AuraEnabled public String recordId;
        @AuraEnabled public String referenceNumber;
        @AuraEnabled public String loanType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public String badgeClass;

        @AuraEnabled public Boolean hasDocuments;
        @AuraEnabled public String documentsLabel;
        @AuraEnabled public String uploadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardSummary getMyLoansDashboard() {
        DashboardSummary summary = new DashboardSummary();
        summary.totalApplications = 0;
        summary.approvedCount = 0;
        summary.inProgressCount = 0;
        summary.rejectedCount = 0;
        summary.applications = new List<LoanRow>();
        summary.message = null;

        try {
            Id currentUserId = UserInfo.getUserId();

            List<User> userList = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :currentUserId
                LIMIT 1
            ];

            if (userList.isEmpty()) {
                summary.message = 'We could not find the logged-in user.';
                return summary;
            }

            User currentUser = userList[0];

            if (currentUser.ContactId == null) {
                summary.message = 'Your profile is not linked to a customer contact yet.';
                return summary;
            }

            List<Contact> contactList = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :currentUser.ContactId
                LIMIT 1
            ];

            if (contactList.isEmpty()) {
                summary.message = 'We could not find the customer contact linked to your profile.';
                return summary;
            }

            Contact borrowerContact = contactList[0];

            String objectApiName = getLoanObjectApiName();
            if (String.isBlank(objectApiName)) {
                summary.message = 'Loan application object could not be found.';
                return summary;
            }

            Schema.SObjectType loanTypeToken = Schema.getGlobalDescribe().get(objectApiName);
            Map<String, Schema.SObjectField> fieldMap = loanTypeToken.getDescribe().fields.getMap();

            String referenceField = pickField(fieldMap, new List<String>{
                'Name',
                'Application_Reference__c',
                'Reference_Number__c'
            });

            String loanTypeField = pickField(fieldMap, new List<String>{
                'Loan_Type__c',
                'LoanType__c',
                'Product_Type__c',
                'MortgageLoanType'
            });

            String amountField = pickField(fieldMap, new List<String>{
                'Loan_Amount__c',
                'LoanAmount__c',
                'Requested_Loan_Amount__c',
                'Amount__c'
            });

            String statusField = pickField(fieldMap, new List<String>{
                'Status',
                'Approval_Status__c',
                'Status__c',
                'Application_Status__c'
            });

            String relationshipField = pickField(fieldMap, new List<String>{
                'AccountId',
                'ContactId',
                'Borrower_Account__c',
                'Borrower__c',
                'Applicant__c'
            });

            if (String.isBlank(relationshipField)) {
                summary.message = 'No borrower relationship field was found on the loan application object.';
                return summary;
            }

            List<String> selectFields = new List<String>{ 'Id', 'LastModifiedDate' };

            if (!String.isBlank(referenceField)) selectFields.add(referenceField);
            if (!String.isBlank(loanTypeField)) selectFields.add(loanTypeField);
            if (!String.isBlank(amountField)) selectFields.add(amountField);
            if (!String.isBlank(statusField)) selectFields.add(statusField);

            String whereValue;
            if (relationshipField == 'ContactId' || relationshipField == 'Borrower__c' || relationshipField == 'Applicant__c') {
                whereValue = '\'' + String.escapeSingleQuotes(borrowerContact.Id) + '\'';
            } else {
                if (borrowerContact.AccountId == null) {
                    summary.message = 'Your contact is not linked to a customer account yet.';
                    return summary;
                }
                whereValue = '\'' + String.escapeSingleQuotes(borrowerContact.AccountId) + '\'';
            }

            String soql =
                'SELECT ' + String.join(selectFields, ', ') +
                ' FROM ' + objectApiName +
                ' WHERE ' + relationshipField + ' = ' + whereValue +
                ' ORDER BY LastModifiedDate DESC LIMIT 50';

            List<SObject> loanApps = Database.query(soql);

            Set<Id> loanIds = new Set<Id>();
            for (SObject app : loanApps) {
                loanIds.add((Id) app.get('Id'));
            }

            Set<Id> loanIdsWithAllRequiredDocs = getLoanIdsWithAllRequiredDocs(loanIds);

            for (SObject app : loanApps) {
                Id appId = (Id) app.get('Id');

                LoanRow row = new LoanRow();
                row.recordId = (String) appId;
                row.referenceNumber = !String.isBlank(referenceField) && app.get(referenceField) != null
                    ? String.valueOf(app.get(referenceField))
                    : 'Loan Application';
                row.loanType = !String.isBlank(loanTypeField) && app.get(loanTypeField) != null
                    ? String.valueOf(app.get(loanTypeField))
                    : '-';
                row.amount = !String.isBlank(amountField) && app.get(amountField) != null
                    ? (Decimal) app.get(amountField)
                    : null;
                row.status = !String.isBlank(statusField) && app.get(statusField) != null
                    ? String.valueOf(app.get(statusField))
                    : 'New';
                row.lastModifiedDate = (Datetime) app.get('LastModifiedDate');
                row.badgeClass = getBadgeClass(row.status);

                row.hasDocuments = loanIdsWithAllRequiredDocs.contains(appId);
                row.documentsLabel = row.hasDocuments ? '✓ Uploaded' : 'Upload';
                row.uploadUrl = row.hasDocuments ? null : '/nexgenyxbank/upload-documents?loanId=' + appId;

                summary.applications.add(row);
                summary.totalApplications++;

                if (isApproved(row.status)) {
                    summary.approvedCount++;
                } else if (isRejected(row.status)) {
                    summary.rejectedCount++;
                } else {
                    summary.inProgressCount++;
                }
            }

            return summary;

        } catch (Exception e) {
            summary.message = e.getMessage();
            return summary;
        }
    }

    private static Set<Id> getLoanIdsWithAllRequiredDocs(Set<Id> loanIds) {
        Set<Id> completedLoanIds = new Set<Id>();

        if (loanIds == null || loanIds.isEmpty()) {
            return completedLoanIds;
        }

        Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();
        if (!globalMap.containsKey('DocumentChecklistItem')) {
            return completedLoanIds;
        }

        Set<String> requiredDocs = new Set<String>{
            'id proof',
            'address proof',
            'income proof'
        };

        Map<Id, Set<String>> loanToDocsMap = new Map<Id, Set<String>>();

        for (DocumentChecklistItem dci : [
            SELECT Id, ParentRecordId, Name, ReceivedDocumentId, Status
            FROM DocumentChecklistItem
            WHERE ParentRecordId IN :loanIds
        ]) {
            Boolean isUploaded = dci.ReceivedDocumentId != null
                || (dci.Status != null && (
                    dci.Status.toLowerCase().contains('received') ||
                    dci.Status.toLowerCase().contains('uploaded') ||
                    dci.Status.toLowerCase().contains('complete')
                ));

            if (!isUploaded || dci.ParentRecordId == null || String.isBlank(dci.Name)) {
                continue;
            }

            String docName = dci.Name.trim().toLowerCase();

            if (requiredDocs.contains(docName)) {
                if (!loanToDocsMap.containsKey(dci.ParentRecordId)) {
                    loanToDocsMap.put(dci.ParentRecordId, new Set<String>());
                }
                loanToDocsMap.get(dci.ParentRecordId).add(docName);
            }
        }

        for (Id loanId : loanToDocsMap.keySet()) {
            Set<String> uploadedDocs = loanToDocsMap.get(loanId);
            if (uploadedDocs.contains('id proof')
                && uploadedDocs.contains('address proof')
                && uploadedDocs.contains('income proof')) {
                completedLoanIds.add(loanId);
            }
        }

        return completedLoanIds;
    }

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

    private static Boolean isApproved(String status) {
        String value = status == null ? '' : status.trim().toLowerCase();
        return value == 'approved' || value == 'completed';
    }

    private static Boolean isRejected(String status) {
        String value = status == null ? '' : status.trim().toLowerCase();
        return value == 'rejected';
    }

    private static String getBadgeClass(String status) {
        String value = status == null ? '' : status.trim().toLowerCase();

        if (value == 'approved' || value == 'completed') {
            return 'badge approved';
        }

        if (value == 'rejected') {
            return 'badge rejected';
        }

        return 'badge progress';
    }
}