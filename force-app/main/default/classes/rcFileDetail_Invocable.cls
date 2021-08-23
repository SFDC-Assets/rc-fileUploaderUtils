global class rcFileDetail_Invocable {

    // payload for the invocable method: rcBusinessUnit_LogoUploaded

    // input to invocable methods
    
    @InvocableVariable
    global String recordID; // record Id of any object 
        
    @InvocableVariable
    global String versionID; // ContentVersion record Id

    @InvocableVariable
    global String title; // the name to save the stored file as
    
    // output from invocable methods
    
    @InvocableVariable
    global String docId; // ContentDocument record Id
    
    @InvocableVariable
    global String path;
    
    @InvocableVariable
    global String contentBodyId; 
    
    @InvocableVariable
    global String link;
    
    @InvocableVariable
    global String contentURL;

}