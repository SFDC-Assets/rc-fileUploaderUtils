public class rcFileUploadHandler {

    // based on code from: https://www.issacc.com/advanced-lightning-file-upload-component/

    @AuraEnabled  
    public static FilesInfo getUploadedFiles(String documentIds){ 
        
        //System.debug('rcFileUploadHandler > getUploadedFiles - documentIds: ' + documentIds);
        
        List<String> docIds = documentIds.split(',');
            
        // return
        FilesInfo info = new FilesInfo();
 
        List<ContentDocument> cds = [SELECT Id, Title, FileType FROM ContentDocument WHERE Id IN :docIds];
        //System.debug('rcFileUploadController > getFiles - content documents: ' + cds);
        info.contentDocuments = cds;

        // get content versions
        List<ContentVersion> cvs = [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :docIds];
        //System.debug('rcFileUploadController > getFiles - content versions: ' + cvs);
        
        List<String> versionIds = new List<String>();
        for (ContentVersion cv : cvs) {
            versionIds.add(cv.Id);
        }
        info.contentVersionIds = versionIds;
        
        return info;
    } 
    
    @AuraEnabled  
    public static FilesInfo getFiles(String recordId){ 
        
        // return
        FilesInfo info = new FilesInfo();
        
        // get content documents
        Set<Id> recordIds = new Set<Id>{recordId};
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :recordIds];                         
        Set<Id> documentIds = new Set<Id>(); 
        for (ContentDocumentLink cdl : cdlList) {  
            documentIds.add(cdl.ContentDocumentId);  
        }    

		List<ContentDocument> cds = [SELECT Id, Title, FileType FROM ContentDocument WHERE Id IN :documentIds];
        //System.debug('rcFileUploadController > getFiles - content documents: ' + cds);
        info.contentDocuments = cds;

        // get content versions
        List<ContentVersion> cvs = [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :documentIds];
        System.debug('rcFileUploadController > getFiles - content versions: ' + cvs);
        
        List<String> versionIds = new List<String>();
        for (ContentVersion cv : cvs) {
            versionIds.add(cv.Id);
        }
        info.contentVersionIds = versionIds;
        
        return info;
    } 
    
    @AuraEnabled  
    public static void deleteFile(String contentDocumentId){ 
        delete [SELECT Id from ContentDocument WHERE Id = :contentDocumentId];       
    }
    
    // FilesInfo - inner class
    public class FilesInfo {
        
        @AuraEnabled
        public List<ContentDocument> contentDocuments {get;set;}

        @AuraEnabled
        public List<String> contentVersionIds {get;set;}
    }    
    
    
} // end rcFileUploadHandler