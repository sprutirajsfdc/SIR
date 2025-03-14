public class UnPublishRightMove {

    public static Response_PortalListingLWC calloutRemovePropertyDetails(String listingRecordID){
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = false;
        objResp.errorMsg = '';
        
        system.debug('listingRecordID from UnPublishRightMove = '+listingRecordID);
        if(String.isBlank(listingRecordID)){
            system.debug('listingRecordID is null or blank');
            objResp.errorMsg = 'listingRecordID is null or blank';
            return objResp;
        }
        
        //query custom metadata to fetch credentials
        RightMove__mdt objCMeta = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, network_id__c, certificate_name__c, channel__c  
                                          from RightMove__mdt
                                          where DeveloperName = 'removepropertyrequest'];
        
        system.debug('objCMeta = '+objCMeta);
        
        if(objCMeta == null || String.isBlank(objCMeta.endpoint__c) || String.isBlank(objCMeta.certificate_name__c)){
              objResp.errorMsg = 'RightMove__mdt is null or blank';
            return objResp;
            }
        
        //query Listing
        Listing__c objListing = [select id, Auto_Generated_broker_reference_ID__c, Listing_Type__c	, Broker_s_Listing_ID__c from Listing__c
                                      where id =: listingRecordID]; 
        
        if(objListing == null){
            system.debug('objListing is null or blank');
            objResp.errorMsg = 'Listing__c is null or blank';
            return objResp;
        }
        system.debug('objListing from UnPublishRightMove = '+objListing);
        
		objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToRemoveProperty(objListing, 'Rightmove UK');
        
        if((objResp == null || String.isBlank(objResp.serializedRequestBody)) && String.isBlank(objResp.errorMsg)){
            objResp.errorMsg = 'Request body could not be created';
            return objResp;
        }
                
        HttpResponse response = Common_Integration_OTM_and_RMove.makeCallout('POST', objResp.serializedRequestBody, objListing.Id, 'UnPublishRightMove',objCMeta.endpoint__c,objCMeta.certificate_name__c);
        
        if(response == null){ //<--- uncomment
          system.debug('response is empty!');  
          objResp.errorMsg = 'response is empty!';
            return objResp;
        }	
        // Deserialize JSON string into a Map<String, Object>
        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
        // Extract the 'success' field
        objResp.isSuccess = (Boolean) parsedJson.get('success');
        
        if(parsedJson.get('message') != null){
         objResp.errorMsg = (String) parsedJson.get('message');      
        }
        
        
        //update Listing
        if(parsedJson != null && objResp.isSuccess){
            objListing.Publish_on_Rightmove_UK__c = false;
            objListing.RightMove_URL__c = '';     
            
            try{
                update objListing;
                system.debug('objListing updated from UnPublishRightMove');
            }catch(Exception e){
                system.debug('error during objListing updation from UnPublishRightMove = '+e.getMessage()); 
            }
        }
        
        // Now 'isSuccess' contains the value of the 'success' field
        System.debug('Success status: ' + objResp.isSuccess); 
        return objResp;
        
    }
}