public with sharing class DocumentUploadController {
    @AuraEnabled
    public static void linkFilesToApplication(Id recordId, List<String> documentIds) {
        try {
            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            
            for(String docId : documentIds) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = docId;
                cdl.LinkedEntityId = recordId; // This connects it to your Loan App
                cdl.ShareType = 'V'; // V = Viewer permission
                linksToInsert.add(cdl);
            }
            
            if(!linksToInsert.isEmpty()) {
                insert linksToInsert;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error linking documents: ' + e.getMessage());
        }
    }
}