public with sharing class documentsUpload {
    @AuraEnabled(cacheable=false)
    public static String processFiles(List<String> documentIds, Id recordId) {
        try {
            // Logic to link files or rename them
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}