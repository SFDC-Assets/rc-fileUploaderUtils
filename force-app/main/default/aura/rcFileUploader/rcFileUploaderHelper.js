({  
    getUploadedFiles : function(component, event){
        
        console.log('rcFileUploaderHelper > getUploadedFiles'); 
        
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
		var documentIds = ''; 
        uploadedFiles.forEach(file => { 
            console.log('file uploaded: ' + JSON.stringify(file)); 
            documentIds += file.documentId + ',';
        });
        console.log('rcFileUploaderHelper > getUploadedFiles - documentIds: ' + documentIds);
            
        var action = component.get("c.getUploadedFiles");  
        action.setParams({  
            "documentIds": documentIds 
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var filesInfo = response.getReturnValue();
                component.set("v.files", filesInfo.contentDocuments); 
                component.set("v.contentVersionIDs", filesInfo.contentVersionIds)
                
				this.updateHeaderText(component);                
            }  
        });  
        $A.enqueueAction(action);  
    },
    
    getRecordFiles : function(component, event){
        
        var action = component.get("c.getFiles");  
        action.setParams({  
            "recordId": component.get("v.recordId") 
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var filesInfo = response.getReturnValue();
                component.set("v.files", filesInfo.contentDocuments); 
                component.set("v.contentVersionIDs", filesInfo.contentVersionIds)
            }  
        });  
        $A.enqueueAction(action);  
    },    
    
    deleteUploadedFile : function(component, event) { 
        var documentId = event.currentTarget.id;
        //console.log('rcFileUploaderHelper > deleteUploadedFile - documentId: ' + documentId); 
        
        var action = component.get("c.deleteFile");           
        action.setParams({
            "contentDocumentId": documentId           
        });  
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                
                // remove the doc from v.files list
                var files = component.get("v.files");     
                for (var i = 0; i < files.length; i++){    
                    if (files[i].Id === documentId) {                 
                        files.splice(i, 1); 
                    }
                }
                component.set("v.files", files);
                this.updateHeaderText(component);
                
                component.set("v.showSpinner", false); 
                // show toast on file deleted successfully
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message": "File has been deleted successfully!",
                    "type": "success",
                    "duration" : 2000
                });
                toastEvent.fire();
            }  
        });  
        $A.enqueueAction(action);  
    },  
    
    updateHeaderText : function(component) { 
        console.log('rcFileUploaderHelper > updateHeaderText');
                    
    	// change header text if exactly one file is uploaded
        var uploadMultiple = component.get("v.uploadMultiple");
        var files = component.get("v.files");
        if (uploadMultiple == false && files.length == 1) {
            var fileHeaderText = component.get("v.fileUploadedHeaderText");
            component.set("v.theFileHeaderText", fileHeaderText);
        } else {
        	var fileHeaderText = component.get("v.fileHeaderText");
        	component.set("v.theFileHeaderText", fileHeaderText);
        }
    },
    
 })