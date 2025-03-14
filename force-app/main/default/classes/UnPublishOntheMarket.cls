public class UnPublishOntheMarket {

    public static Response_PortalListingLWC calloutRemovePropertyDetails(String listingRecordID){
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = false;
        objResp.errorMsg = '';

        
        system.debug('listingRecordID from UnPublishOntheMarket = '+listingRecordID);
        if(String.isBlank(listingRecordID)){
            system.debug('listingRecordID is null or blank');
            objResp.errorMsg = 'listingRecordID is null or blank';
            return objResp;
        }
        
        //query custom metadata to fetch credentials
        On_the_Market__mdt objCMetaOTM = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, certificate_name__c, channel__c  
                                          from On_the_Market__mdt
                                          where DeveloperName = 'removepropertyrequest'];
        
        system.debug('objCMetaOTM = '+objCMetaOTM);
        
        if(objCMetaOTM == null || String.isBlank(objCMetaOTM.endpoint__c) || String.isBlank(objCMetaOTM.certificate_name__c)){
               system.debug('objCMetaOTM is null');
               objResp.errorMsg = 'On_the_Market__mdt is null or blank';
            return objResp;
           }
        
        //query Listing
        Listing__c objListing = [select id, Auto_Generated_broker_reference_ID__c, Listing_Type__c, Broker_s_Listing_ID__c from Listing__c
                                      where id =: listingRecordID]; 
        
        if(objListing == null){
            system.debug('objListing is null or blank');
            objResp.errorMsg = 'Listing__c is null or blank';
            return objResp;
        }
        system.debug('objListing from UnPublishOntheMarket = '+objListing);
        
         
            objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToRemoveProperty(objListing, 'On The Market');
        
        if((objResp == null || String.isBlank(objResp.serializedRequestBody)) && String.isBlank(objResp.errorMsg)){
            objResp.errorMsg = 'Request body could not be created';
            return objResp;
        }

        HttpResponse response = Common_Integration_OTM_and_RMove.makeCallout('POST', objResp.serializedRequestBody, objListing.Id, 'UnPublishOntheMarket',objCMetaOTM.endpoint__c,objCMetaOTM.certificate_name__c);

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
            objListing.Publish_on_On_The_Market__c = false;
            objListing.On_The_Market_URL__c = '';     
            
            try{
                update objListing;
                system.debug('objListing updated from UnPublishOntheMarket');
            }catch(Exception e){
                system.debug('error during objListing updation from UnPublishOntheMarket = '+e.getMessage()); 
            }
        }
        
       // Now 'isSuccess' contains the value of the 'success' field
        System.debug('Success status: ' + objResp.isSuccess); 
        return objResp;
        
    }
}