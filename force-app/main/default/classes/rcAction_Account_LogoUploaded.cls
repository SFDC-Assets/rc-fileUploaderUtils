global class rcAction_Account_LogoUploaded {

    @InvocableMethod(label='Action: Account Logo Uploaded')
    global static List<rcFileDetail_Invocable> imageUploaded(List<rcFileDetail_Invocable> fileDetails) {

        List<rcFileDetail_Invocable> updatedFileDetails = rcImageFileController.fileUploaded(fileDetails);
                
        // update record w/ the public link
        List<Account> accounts = new List<Account>();
        for (rcFileDetail_Invocable d : updatedFileDetails) {
            Account account = new Account(Id = d.recordID);
            account.rcLogo_URL__c = d.contentURL;
            accounts.add(account);
        }
        update accounts;

        return updatedFileDetails;
        
    } // end imageUploaded
    
}