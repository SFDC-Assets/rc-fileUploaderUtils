({
	getFieldValue : function(component){
                    
        var recordId = component.get("v.recordId");
        var fieldName = component.get("v.fieldName");
        
        var action = component.get("c.getStringFieldValue");  
        action.setParams({  
            "recId": recordId, 
            "fieldName": fieldName
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                var fieldValue = response.getReturnValue();
                component.set("v.srcURL", fieldValue);       
            }
        });  
        $A.enqueueAction(action);
    },
    
})