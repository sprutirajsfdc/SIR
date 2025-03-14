public class PublishOnTheMarket {
    
    public static Response_PortalListingLWC calloutSendPropertyDetails(String listingRecordID){
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = false;
        objResp.errorMsg = '';
        
        system.debug('listingRecordID from PublishOnTheMarket = '+listingRecordID);
        if(String.isBlank(listingRecordID)){
            system.debug('listingRecordID is null or blank');
            objResp.errorMsg = 'listingRecordID is null or blank';
            return objResp;
        }
        try{
        //query custom metadata to fetch credentials
        On_the_Market__mdt objCMetaOTM = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, certificate_name__c, channel__c  
                                          from On_the_Market__mdt
                                          where DeveloperName = 'sendpropertydetails'];
        
        system.debug('objCMetaOTM = '+objCMetaOTM);
        
        if(objCMetaOTM == null || String.isBlank(objCMetaOTM.endpoint__c) || String.isBlank(objCMetaOTM.certificate_name__c)){
            system.debug('On_the_Market__mdt is null');
            objResp.errorMsg = 'On_the_Market__mdt is null or blank';
            return objResp;
        }	
        
        
        //query Listing
        Listing__c objListing = [SELECT Id, SIR_Listing_ID__c, Feaure_4__c, Age__c, 
        os_NumberOfParkingSpaces__c, Locality__c, CreatedDate, Listing_Price_GBP__c, Feaure_3__c, Listing_Inquiry_Recipient__r.Phone, 
        Form_A_for_Photoshoot__c, Initial_Listed_Date__c, RERA_Permit_Number__c, gsir_form_a_expiry__c, 
        Form_ASales_Leasing_form_or_NOC__c, Property_Propertyfinder__c, House_Building_Name__c, os_Longitude_pb__c, 
        Listing_Verified_by_CC__c, Documents_Verified__c, os_Latitude_pb__c, Rightmove_Property_Type__c, 
        Website_Description_Short__c, os_State_pb__c, Commercial_Amenities__c, Listing_Agent_Phone__c, Country__c, 
        os_PostalCode_pb__c, Address__c, os_Street_pb__c, Name, os_ListingPrice_pb__c, CurrencyIsoCode, Listing_Type__c, os_LotSize_pb__c, Property_Type__c, Status__c, os_TotalArea_pb__c, Description__c, Bedrooms__c, Bathrooms__c, Listing_Agent_Email__c, os_ListingAgentName__c, os_Listing_Agent_Photo__c, Website_Description__c, Property_Lifestyle__c, City__c, Property_Owner_Address__c, Area_Town__c, For_Sale_Available_DateTime__c, Off_Plan_Developer__c, Signed_TOB_Received__c, Ownership_Type__c, System_Allowed_for_Portals__c, Broker_s_Listing_ID__c, Website_Title__c, Propertyfinder_Region__c, Listing_Count_AML_Approved__c, LastViewedDate, Listing_Category__c, Sub_Community__c, Pending_AML_DateTime__c, Property_Sub_Type__c, Auto_Generated_broker_reference_ID__c, Estimated_Listing_Revenue__c, Department__c, Listing_Initials__c, Completion_Status__c, Listing_Buyer_AML_Count__c, Listing_Price_Expiry__c, Is_Listing_price_changed__c, Year_Built_Text__c, Private_Amenities__c, Listing_Inquiry_Recipient__r.Name, os_Floor__c, Feaure_2__c, Marketing_Exposure__c, Furnished__c, Summary__c, Is_Primary_Agent__c, Land_Registry_Check_Verified__c, Mandate__c, Listing_Seller_AML_Count__c, Photo_Uploaded_Verify__c, Publish_Date__c, Listing_Inquiry_Recipient__c, All_AML_Documents_Verified__c, Listing_Manager_Read_Write__c, Listing_Sub_Status__c, os_UnitNumber__c, Title_Deed_No__c FROM Listing__c WHERE Id = :listingRecordID]; 
        
        system.debug('objListing from PublishOnTheMarket = '+objListing);
        
        objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToSendProperty(objListing, 'On The Market');
        
        if((objResp == null || String.isBlank(objResp.serializedRequestBody)) && String.isBlank(objResp.errorMsg)){
            objResp.errorMsg = 'Request body could not be created';
            return objResp;
        }
        
        HttpResponse response = Common_Integration_OTM_and_RMove.makeCallout('POST', objResp.serializedRequestBody, objListing.Id,'PublishOnTheMarket', objCMetaOTM.endpoint__c, objCMetaOTM.certificate_name__c);
        
        if(response == null){
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
            objListing.Publish_on_On_The_Market__c = objResp.isSuccess;
            system.debug('portal_url = '+(String) ((Map<String, Object>) parsedJson.get('property')).get('portal_url'));
            objListing.On_The_Market_URL__c = (String) ((Map<String, Object>) parsedJson.get('property')).get('portal_url');     
            
                update objListing;
                system.debug('objListing updated from PublishOnTheMarket');
       
        }
        
        
        // Now 'isSuccess' contains the value of the 'success' field
        System.debug('Success status: ' + objResp.isSuccess); 
        return objResp;
        
        }catch(Exception e){
         system.debug('error msg = '+e.getMessage()+' on line = '+e.getLineNumber());   
         objResp.errorMsg = 'error msg = '+e.getMessage()+' on line = '+e.getLineNumber();
         return objResp;   
        }
    }
    
}