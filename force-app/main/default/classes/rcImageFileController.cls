public class rcImageFileController {

    public static List<rcFileDetail_Invocable> fileUploaded(List<rcFileDetail_Invocable> fileDetails) {

        System.debug('rcImageFileController > fileUploaded - fileDetails: ' + fileDetails);
            
        // maps to use for processing
        // fileMap = content versionID to file detail map
        // titleFileMap = title to file detail map
		Map<String, rcFileDetail_Invocable> fileMap = new Map<String, rcFileDetail_Invocable>();
        Map<String, rcFileDetail_Invocable> titleFileMap = new Map<String, rcFileDetail_Invocable>();
        for (rcFileDetail_Invocable d : fileDetails) {
            fileMap.put(d.versionID, d);
            titleFileMap.put(d.title, d);
        }
        System.debug('rcImageFileController > fileUploaded - fileMap keys (versionIds): ' + fileMap.keySet());
        System.debug('rcImageFileController > fileUploaded - titleFileMap keys (titles): ' + titleFileMap.keySet());

        // get content version of existing file, if there is one that matches the title
        List<ContentVersion> existing_cvs = [SELECT Id, ContentDocumentId, Title, VersionNumber FROM ContentVersion WHERE Title IN :titleFileMap.keySet()];
        System.debug('rcImageFileController > fileUploaded - content versions for existing titles: ' + existing_cvs);

        // update fileMap with the existing ContentDocumentId
        for (ContentVersion cv : existing_cvs) {
            rcFileDetail_Invocable fileDetail = titleFileMap.get(cv.Title);
            fileDetail.docId = cv.ContentDocumentId;
            fileMap.put(fileDetail.versionID, fileDetail); 
        }
        
        // get content version of uploaded file
        List<ContentVersion> cvs = [SELECT Id, ContentDocumentId, ContentBodyId, ContentLocation, PathOnClient, Title, VersionData FROM ContentVersion WHERE Id IN :fileMap.keySet()];
        System.debug('rcImageFileController > fileUploaded - content versions: ' + cvs);
        
        List<ContentVersion> updated_cvs = new List<ContentVersion>();
        List<ContentVersion> to_create_cvs = new List<ContentVersion>();
        List<ContentDocument> to_delete_cds = new List<ContentDocument>();
        for (ContentVersion cv : cvs) {
            rcFileDetail_Invocable fileDetail = fileMap.get(cv.Id);
            if (fileDetail.docId == null) { 
                System.debug('rcImageFileController > fileUploaded - no existing file with title');
                // there is no file with this title for this record                 
                // update title of uploaded file
                cv.Title = fileMap.get(cv.Id).title;
                cv.VersionData = null; // removing VersionData. not need here and update of major version fails if this is set
                updated_cvs.add(cv);                
            } else { 
                System.debug('rcImageFileController > fileUploaded - existing file, creating new version');
                // there is an existing file with this title for this record                                
                // create a new version of this file with the new uploaded content
                ContentVersion new_cv = new ContentVersion(
                    ContentDocumentId = fileDetail.docId,
                    Title = fileDetail.title,
                    PathOnClient = cv.PathOnClient,
                    ReasonForChange = 'new version',
                    VersionData = cv.VersionData,
                    IsMajorVersion = true
                );
                to_create_cvs.add(new_cv); 
                
                // delete the uploaded file (ContentDocument + ContentVersion records)
                ContentDocument cd = new ContentDocument(Id = cv.ContentDocumentId);
                to_delete_cds.add(cd);
            }
        }
        System.debug('rcImageFileController > fileUploaded - updated_cvs: ' + updated_cvs);
        System.debug('rcImageFileController > fileUploaded - to_delete_cds: ' + to_delete_cds);
        
		// update cvs list
        if (updated_cvs.size() > 0) {
        	update updated_cvs;
        	System.debug('rcImageFileController > fileUploaded - updated content versions: ' + updated_cvs);
        }
        
        // create new content versions
        if (to_create_cvs.size() > 0) {
        	insert to_create_cvs;
        	System.debug('rcImageFileController > fileUploaded - created content versions: ' + to_create_cvs);
            
            List<Id> new_cvIDs = new List<String>();
            for (ContentVersion cv : to_create_cvs) {
                new_cvIDs.add(cv.Id);
            }
            
            List<ContentVersion> new_cvs = [SELECT Id, ContentDocumentId, ContentBodyId, ContentLocation, PathOnClient, Title FROM ContentVersion WHERE Id IN :new_cvIDs];
        	System.debug('rcImageFileController > fileUploaded - new_cvs: ' + new_cvs);
            
            // add new versions to the updated_cvs list
            updated_cvs.addAll(new_cvs);
        }
                
        // update fileDetails with the PathOnClient and ContentBodyId
        for (ContentVersion cv : updated_cvs) {
            rcFileDetail_Invocable fileDetail = fileMap.get(cv.Id);
            if (fileDetail == null) {
                // find fileDetail by title and replace the versionId w/ the new one
                fileDetail = titleFileMap.get(cv.Title);
                fileMap.remove(fileDetail.versionID);
                fileDetail.versionID = cv.Id;
            }
            fileDetail.path = cv.PathOnClient;
            fileDetail.contentBodyId = cv.ContentBodyId;
            fileMap.put(cv.Id, fileDetail);
        }
        
        // create file public link
        List<ContentDistribution> cds = new List<ContentDistribution>();
        for (ContentVersion cv : updated_cvs) {
            ContentDistribution cd = new ContentDistribution();
            cd.Name = cv.Title;
            cd.ContentVersionId = cv.Id;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesPasswordRequired = false;
            cd.PreferencesAllowOriginalDownload = true;
            cds.add(cd);
        }
        insert cds;
        System.debug('rcImageFileController > fileUploaded - ContentDistributions inserted: ' + cds);
        
        // content distribution id to file detail map
		Map<String, rcFileDetail_Invocable> linkFileMap = new Map<String, rcFileDetail_Invocable>();
        for (ContentDistribution cd : cds) {
            linkFileMap.put(cd.Id, fileMap.get(cd.ContentVersionId));
        }
        System.debug('rcImageFileController > fileUploaded - linkFileMap: ' + linkFileMap);
                
        // get public link
        cds = [SELECT Id, ContentVersionId, ContentDownloadUrl, DistributionPublicUrl, Password FROM ContentDistribution WHERE Id IN :linkFileMap.keySet()];
        System.debug('rcImageFileController > fileUploaded - ContentDistributions with links: ' + cds);
             
        // update fileDetails with the public link
        for (ContentDistribution cd : cds) {
            rcFileDetail_Invocable fileDetail = fileMap.get(cd.ContentVersionId);
            fileDetail.contentURL = getContentViewURL(cd.ContentDownloadUrl, fileDetail.contentBodyId);
            fileDetail.link = cd.DistributionPublicUrl;
            fileMap.put(cd.ContentVersionId, fileDetail);
        }
        
        // delete unneeded files
        if (to_delete_cds.size() > 0) {
        	delete to_delete_cds;
        	System.debug('rcImageFileController > fileUploaded - unneeded files deleted: ' + to_delete_cds);
        }
        
        List<rcFileDetail_Invocable> updatedFileDetails = fileMap.values();
        System.debug('rcImageFileController > fileUploaded - updatedFileDetails: ' + updatedFileDetails);        
        return updatedFileDetails;
        
    } // end fileUploaded
 
    public static String getContentViewURL(String contentDownloadUrl, String contentBodyId) {
        
        // the ContentDistribution.ContentDownloadUrl is a url for downloading the file content and looks like this:
        // 'https://dream-speed-4299-dev-ed--c.documentforce.com/sfc/dist/version/download/?oid=00D1g0000002ppf&ids=0681g000000sRY3&d=%2Fa%2F1g0000000Fj3%2FiVLxai2EHIdzsHNBod4ZuirRtR_oprJIizMce1P9WmQ&asPdf=false'
        // this method constructs a URL to the image content for viewing so that it can be used as the actual image address
        // the constructed URL will look like this: 
        // 'https://dream-speed-4299-dev-ed--c.documentforce.com/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Png&versionId=0681g000000sRY3&operationContext=DELIVERY&contentId=05T1g000002XlLb&page=0&d=/a/1g0000000Fj3/iVLxai2EHIdzsHNBod4ZuirRtR_oprJIizMce1P9WmQ&oid=00D1g0000002ppf&dpt=null&viewId='
        
        // base
        List<String> toks = contentDownloadUrl.split('download/');
        String base = toks.get(0) + 'renditionDownload';
        //System.debug('toks: ' + toks);
        
        // params
        String params = toks.get(1);
        toks = params.split('&');
        //System.debug('toks: ' + toks);
        
        String oid, ids, d;
        for (String tok : toks) {
            List<String> p = tok.split('=');
            switch on p.get(0) {
    			when '?oid' { oid = p.get(1); }
                when 'ids' { ids = p.get(1); }
                when 'd' { d = p.get(1); }
    			when else {}
			}
        }
        //System.debug('oid: ' + oid);
        //System.debug('ids: ' + ids);
        //System.debug('d: ' + d);
        
        // rendition
        String rendition = 'rendition=ORIGINAL_Png';
        
        // versionId
        String versionId = 'versionId=' + ids;
        
        // contentId
        String contentId = 'contentId=' + contentBodyId;
        
        // d
        d = 'd=' + d;
        
        // oid
        oid = 'oid=' + oid;       
        
        String contentViewURL = base + '?' + rendition 
            + '&' + versionId 
            + '&operationContext=DELIVERY'
            + '&' + contentId
            + '&page=0'
            + '&' + d 
            + '&' + oid
            + '&dpt=null&viewId='; 
        
        System.debug('contentViewURL: ' + contentViewURL);
        return contentViewURL;
        
    } // end getContentViewURL
    
    @AuraEnabled  
    public static String getStringFieldValue(ID recId, String fieldName){
        String fieldValue;
        if (recId != null) {
            String sObjectType = recId.getSobjectType().getDescribe().getName();
            String q = 'SELECT ' + fieldName + ' FROM ' + sObjectType + ' WHERE Id = \'' + recId + '\' LIMIT 1';
            sObject obj = Database.query(q);
            fieldValue = (String) obj.get(fieldName);
        }
        return fieldValue;
    }  
    
    
} // end rcImageFileController