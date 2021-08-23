/*
	This is the same payload as rcFileDetail_Invocable (for apex actions - invocable methods) 
	but AuraEnabled so that it can be used as an Apex-defined type in Flows.
*/
global class rcFileDetail_Aura {
        
    @AuraEnabled
    global String recordID; // record Id of any object 
        
    @AuraEnabled
    global String versionID; // ContentVersion record Id

    @AuraEnabled
    global String title; // the name to save the stored file as
        
    @AuraEnabled
    global String docId; // ContentDocument record Id
    
    @AuraEnabled
    global String path;
    
    @AuraEnabled
    global String contentBodyId; 
    
    @AuraEnabled
    global String link;
    
    @AuraEnabled
    global String contentURL;

}