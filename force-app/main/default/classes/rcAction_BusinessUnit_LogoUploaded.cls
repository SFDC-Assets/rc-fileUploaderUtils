global class rcAction_BusinessUnit_LogoUploaded {

    @InvocableMethod(label='Action: Business Unit Logo Uploaded')
    global static List<rcFileDetail_Invocable> imageUploaded(List<rcFileDetail_Invocable> fileDetails) {

        List<rcFileDetail_Invocable> updatedFileDetails = rcImageFileController.fileUploaded(fileDetails);
                
        // update record w/ the public link
        List<rcBusiness_Unit__c> businessUnits = new List<rcBusiness_Unit__c>();
        for (rcFileDetail_Invocable d : updatedFileDetails) {
            rcBusiness_Unit__c bu = new rcBusiness_Unit__c(Id = d.recordID);
            bu.Logo_URL__c = d.contentURL;
            businessUnits.add(bu);
        }
        update businessUnits;
        
        return updatedFileDetails;

    } // end imageUploaded
    
}