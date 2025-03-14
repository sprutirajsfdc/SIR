public class CalloutAndInsertOTM_and_RMove {
    @Future(callout=true)
    public static void executeOTMCallout(String listingRecordID) {
        
        if(String.isNotBlank(listingRecordID)){
            
            //query Listing
            Listing__c objListing = [SELECT Id, SIR_Listing_ID__c, Feaure_4__c, Age__c, 
                                     os_NumberOfParkingSpaces__c, Locality__c, CreatedDate, Listing_Price_GBP__c, Feaure_3__c, Listing_Inquiry_Recipient__r.Phone, 
                                     Form_A_for_Photoshoot__c, Initial_Listed_Date__c, RERA_Permit_Number__c, gsir_form_a_expiry__c, 
                                     Form_ASales_Leasing_form_or_NOC__c, Property_Propertyfinder__c, House_Building_Name__c, os_Longitude_pb__c, 
                                     Listing_Verified_by_CC__c, Documents_Verified__c, os_Latitude_pb__c, Rightmove_Property_Type__c, 
                                     Website_Description_Short__c, os_State_pb__c, Commercial_Amenities__c, Listing_Agent_Phone__c, Country__c, 
                                     os_PostalCode_pb__c, Address__c, os_Street_pb__c, Name, os_ListingPrice_pb__c, CurrencyIsoCode, Listing_Type__c, os_LotSize_pb__c, Property_Type__c, Status__c, os_TotalArea_pb__c, Description__c, Bedrooms__c, Bathrooms__c, Listing_Agent_Email__c, os_ListingAgentName__c, os_Listing_Agent_Photo__c, Website_Description__c, Property_Lifestyle__c, City__c, Property_Owner_Address__c, Area_Town__c, For_Sale_Available_DateTime__c, Off_Plan_Developer__c, Signed_TOB_Received__c, Ownership_Type__c, System_Allowed_for_Portals__c, Broker_s_Listing_ID__c, Website_Title__c, Propertyfinder_Region__c, Listing_Count_AML_Approved__c, LastViewedDate, Listing_Category__c, Sub_Community__c, Pending_AML_DateTime__c, Property_Sub_Type__c, Auto_Generated_broker_reference_ID__c, Estimated_Listing_Revenue__c, Department__c, Listing_Initials__c, Completion_Status__c, Listing_Buyer_AML_Count__c, Listing_Price_Expiry__c, Is_Listing_price_changed__c, Year_Built_Text__c, Private_Amenities__c, Listing_Inquiry_Recipient__r.Name, os_Floor__c, Feaure_2__c, Marketing_Exposure__c, Furnished__c, Summary__c, Is_Primary_Agent__c, Land_Registry_Check_Verified__c, Mandate__c, Listing_Seller_AML_Count__c, Photo_Uploaded_Verify__c, Publish_Date__c, Listing_Inquiry_Recipient__c, All_AML_Documents_Verified__c, Listing_Manager_Read_Write__c, Listing_Sub_Status__c, os_UnitNumber__c, Title_Deed_No__c FROM Listing__c WHERE Id = :listingRecordID]; 
            
            if(objListing == null){
                system.debug('objListing is null or blank');
                return;
            }
            system.debug('objListing from PublishOnTheMarket = '+objListing);
            
            //query custom metadata to fetch credentials
            On_the_Market__mdt objCMetaOTM = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, network_id__c, certificate_name__c, channel__c  
                                              from On_the_Market__mdt
                                              where DeveloperName = 'sendpropertydetails'];
            
            system.debug('objCMetaOTM = '+objCMetaOTM);
            
            if(objCMetaOTM == null || String.isBlank(objCMetaOTM.endpoint__c) ||
               String.isBlank(objCMetaOTM.certificate_name__c)){
                   system.debug('objCMetaOTM is null');
                   return; 
               }
            
            Response_PortalListingLWC objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToSendProperty(objListing, 'On The Market');
            
            if(objResp == null || String.isBlank(objResp.serializedRequestBody)){
                system.debug('objResp is null');
                return;  
            }
            
            String methodName = 'POST';
            String requestBody = objResp.serializedRequestBody;
            
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setMethod(methodName);
            req.setEndpoint(objCMetaOTM.endpoint__c);
            req.setClientCertificateName(objCMetaOTM.certificate_name__c);
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug('res body =  '+res.getBody());
            system.debug('res code =  '+res.getStatusCode()); 
            
            if(res != null){
                
                // Deserialize JSON string into a Map<String, Object>
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Extract the 'success' field
                objResp.isSuccess = (Boolean) parsedJson.get('success');
                if(parsedJson.get('message') != null){
                    objResp.errorMsg = (String) parsedJson.get('message');      
                }  
                
                //update Listing
                if(parsedJson != null && objResp.isSuccess){
                    //   objListing.Publish_on_On_The_Market__c = objResp.isSuccess;
                    //    system.debug('portal_url = '+(String) ((Map<String, Object>) parsedJson.get('property')).get('portal_url'));
                    objListing.On_The_Market_URL__c = (String) ((Map<String, Object>) parsedJson.get('property')).get('portal_url');     
                    
                    update objListing;
                    system.debug('objListing updated from CalloutAndInsertOTM_and_RMove - executeOTMCallout');
                    
                }
                
                //create Integ log - call to createLogs method - 
                Integration_Log__c objLog = createIntegrationLogs(methodName, requestBody, res.getBody(),
                                                                  'Outbound','CalloutAndInsertOTM_and_RMove - executeOTMCallout', '', String.valueOf(res.getStatusCode()), objListing.Id); 
                
                try{
                    insert objLog; 
                    system.debug('objLog inserted');    
                }catch(Exception e){
                    system.debug('error during objLog insertion'); 
                } 
            }
            
        }else{
            system.debug('lstListingRecordID is empty : OTM callout');
        }
        
        
    }
    
    @Future(callout=true)
    public static void executeUnPublishOTM(String listingRecordID) {
        
        if(String.isNotBlank(listingRecordID)){
            
            //query Listing
            Listing__c objListing = [SELECT Id, SIR_Listing_ID__c, Feaure_4__c, Age__c, 
                                     os_NumberOfParkingSpaces__c, Locality__c, CreatedDate, Listing_Price_GBP__c, Feaure_3__c, Listing_Inquiry_Recipient__r.Phone, 
                                     Form_A_for_Photoshoot__c, Initial_Listed_Date__c, RERA_Permit_Number__c, gsir_form_a_expiry__c, 
                                     Form_ASales_Leasing_form_or_NOC__c, Property_Propertyfinder__c, House_Building_Name__c, os_Longitude_pb__c, 
                                     Listing_Verified_by_CC__c, Documents_Verified__c, os_Latitude_pb__c, Rightmove_Property_Type__c, 
                                     Website_Description_Short__c, os_State_pb__c, Commercial_Amenities__c, Listing_Agent_Phone__c, Country__c, 
                                     os_PostalCode_pb__c, Address__c, os_Street_pb__c, Name, os_ListingPrice_pb__c, CurrencyIsoCode, Listing_Type__c, os_LotSize_pb__c, Property_Type__c, Status__c, os_TotalArea_pb__c, Description__c, Bedrooms__c, Bathrooms__c, Listing_Agent_Email__c, os_ListingAgentName__c, os_Listing_Agent_Photo__c, Website_Description__c, Property_Lifestyle__c, City__c, Property_Owner_Address__c, Area_Town__c, For_Sale_Available_DateTime__c, Off_Plan_Developer__c, Signed_TOB_Received__c, Ownership_Type__c, System_Allowed_for_Portals__c, Broker_s_Listing_ID__c, Website_Title__c, Propertyfinder_Region__c, Listing_Count_AML_Approved__c, LastViewedDate, Listing_Category__c, Sub_Community__c, Pending_AML_DateTime__c, Property_Sub_Type__c, Auto_Generated_broker_reference_ID__c, Estimated_Listing_Revenue__c, Department__c, Listing_Initials__c, Completion_Status__c, Listing_Buyer_AML_Count__c, Listing_Price_Expiry__c, Is_Listing_price_changed__c, Year_Built_Text__c, Private_Amenities__c, Listing_Inquiry_Recipient__r.Name, os_Floor__c, Feaure_2__c, Marketing_Exposure__c, Furnished__c, Summary__c, Is_Primary_Agent__c, Land_Registry_Check_Verified__c, Mandate__c, Listing_Seller_AML_Count__c, Photo_Uploaded_Verify__c, Publish_Date__c, Listing_Inquiry_Recipient__c, All_AML_Documents_Verified__c, Listing_Manager_Read_Write__c, Listing_Sub_Status__c, os_UnitNumber__c, Title_Deed_No__c FROM Listing__c WHERE Id = :listingRecordID];
            
            if(objListing == null){
                system.debug('objListing is null or blank');
                return;
            }
            system.debug('objListing from executeUnPublishOTM = '+objListing);
            
            //query custom metadata to fetch credentials
            On_the_Market__mdt objCMetaOTM = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, certificate_name__c, channel__c  
                                              from On_the_Market__mdt
                                              where DeveloperName = 'removepropertyrequest'];
            
            system.debug('objCMetaOTM = '+objCMetaOTM);
            
            if(objCMetaOTM == null || String.isBlank(objCMetaOTM.endpoint__c) ||
               String.isBlank(objCMetaOTM.certificate_name__c)){
                   system.debug('objCMetaOTM is null');
                   return; 
               }
            
            Response_PortalListingLWC objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToRemoveProperty(objListing, 'On The Market');
            
            if(objResp == null || String.isBlank(objResp.serializedRequestBody)){
                system.debug('objResp is null');
                return;  
            }
            
            String methodName = 'POST';
            String requestBody = objResp.serializedRequestBody;
            
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setMethod(methodName);
            req.setEndpoint(objCMetaOTM.endpoint__c);
            req.setClientCertificateName(objCMetaOTM.certificate_name__c);
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug('res body =  '+res.getBody());
            system.debug('res code =  '+res.getStatusCode()); 
            
            if(res != null){
                
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Extract the 'success' field
                Boolean isSuccess = (Boolean) parsedJson.get('success');
                
                if(parsedJson != null && objResp.isSuccess){
                    objListing.Publish_on_On_The_Market__c = false;
                    objListing.On_The_Market_URL__c = '';  //prev
                    
                }
                
                //create Integ log - call to createLogs method - 
                Integration_Log__c objLog = createIntegrationLogs(methodName, requestBody, res.getBody(),
                                                                  'Outbound','CalloutAndInsertOTM_and_RMove - executeUnPublishOTM', '', String.valueOf(res.getStatusCode()), objListing.Id); 
                
                try{
                    update objListing;
                    system.debug('objListing updated from executeUnPublishOTM');
                    insert objLog; 
                    system.debug('objLog inserted from executeUnPublishOTM');    
                }catch(Exception e){
                    system.debug('error during objLog insertion'); 
                } 
            }
            
        }else{
            system.debug('lstListingRecordID is empty : OTM callout');
        }
        
        
    }
    
    @Future(callout=true)
    public static void executeUnPublishRM(String listingRecordID) {
        
        if(String.isNotBlank(listingRecordID)){
            
            //query Listing
            Listing__c objListing = [SELECT Id, SIR_Listing_ID__c, Feaure_4__c, Age__c, 
                                     os_NumberOfParkingSpaces__c, Locality__c, CreatedDate, Listing_Price_GBP__c, Feaure_3__c, Listing_Inquiry_Recipient__r.Phone, 
                                     Form_A_for_Photoshoot__c, Initial_Listed_Date__c, RERA_Permit_Number__c, gsir_form_a_expiry__c, 
                                     Form_ASales_Leasing_form_or_NOC__c, Property_Propertyfinder__c, House_Building_Name__c, os_Longitude_pb__c, 
                                     Listing_Verified_by_CC__c, Documents_Verified__c, os_Latitude_pb__c, Rightmove_Property_Type__c, 
                                     Website_Description_Short__c, os_State_pb__c, Commercial_Amenities__c, Listing_Agent_Phone__c, Country__c, 
                                     os_PostalCode_pb__c, Address__c, os_Street_pb__c, Name, os_ListingPrice_pb__c, CurrencyIsoCode, Listing_Type__c, os_LotSize_pb__c, Property_Type__c, Status__c, os_TotalArea_pb__c, Description__c, Bedrooms__c, Bathrooms__c, Listing_Agent_Email__c, os_ListingAgentName__c, os_Listing_Agent_Photo__c, Website_Description__c, Property_Lifestyle__c, City__c, Property_Owner_Address__c, Area_Town__c, For_Sale_Available_DateTime__c, Off_Plan_Developer__c, Signed_TOB_Received__c, Ownership_Type__c, System_Allowed_for_Portals__c, Broker_s_Listing_ID__c, Website_Title__c, Propertyfinder_Region__c, Listing_Count_AML_Approved__c, LastViewedDate, Listing_Category__c, Sub_Community__c, Pending_AML_DateTime__c, Property_Sub_Type__c, Auto_Generated_broker_reference_ID__c, Estimated_Listing_Revenue__c, Department__c, Listing_Initials__c, Completion_Status__c, Listing_Buyer_AML_Count__c, Listing_Price_Expiry__c, Is_Listing_price_changed__c, Year_Built_Text__c, Private_Amenities__c, Listing_Inquiry_Recipient__r.Name, os_Floor__c, Feaure_2__c, Marketing_Exposure__c, Furnished__c, Summary__c, Is_Primary_Agent__c, Land_Registry_Check_Verified__c, Mandate__c, Listing_Seller_AML_Count__c, Photo_Uploaded_Verify__c, Publish_Date__c, Listing_Inquiry_Recipient__c, All_AML_Documents_Verified__c, Listing_Manager_Read_Write__c, Listing_Sub_Status__c, os_UnitNumber__c, Title_Deed_No__c FROM Listing__c WHERE Id = :listingRecordID]; 
            
            if(objListing == null){
                system.debug('objListing is null or blank');
                return;
            }
            system.debug('objListing from executeUnPublishRM = '+objListing);
            
            //query custom metadata to fetch credentials
            RightMove__mdt objCMeta = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, network_id__c, certificate_name__c, channel__c  
                                       from RightMove__mdt
                                       where DeveloperName = 'removepropertyrequest'];
            
            system.debug('objCMeta = '+objCMeta);
            
            if(objCMeta == null || String.isBlank(objCMeta.endpoint__c) ||
               String.isBlank(objCMeta.certificate_name__c)){
                   system.debug('objCMeta is null');
                   return; 
               }
            
            Response_PortalListingLWC objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToRemoveProperty(objListing, 'Rightmove UK');
            
            if(objResp == null || String.isBlank(objResp.serializedRequestBody)){
                system.debug('objResp is null');
                return;  
            }
            
            String methodName = 'POST';
            String requestBody = objResp.serializedRequestBody;
            
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setMethod(methodName);
            req.setEndpoint(objCMeta.endpoint__c);
            req.setClientCertificateName(objCMeta.certificate_name__c);
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            //    system.debug('res body =  '+res.getBody());
            //    system.debug('res code =  '+res.getStatusCode()); 
            
            if(res != null){
                
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Extract the 'success' field
                Boolean isSuccess = (Boolean) parsedJson.get('success');
                
                if(parsedJson != null && objResp.isSuccess){
                    objListing.Publish_on_Rightmove_UK__c = false;
                    objListing.RightMove_URL__c = '';    
                }
                
                //create Integ log - call to createLogs method - 
                Integration_Log__c objLog = createIntegrationLogs(methodName, requestBody, res.getBody(),
                                                                  'Outbound','CalloutAndInsertOTM_and_RMove - executeUnPublishRM', '', String.valueOf(res.getStatusCode()), objListing.Id); 
                
                try{
                    update objListing;
                    system.debug('objListing updated from executeUnPublishOTM');
                    insert objLog; 
                    system.debug('objLog inserted from executeUnPublishOTM');    
                }catch(Exception e){
                    system.debug('error during objLog insertion'); 
                } 
            }
            
        }else{
            system.debug('lstListingRecordID is empty : OTM callout');
        }
        
        
    }
    
    @Future(callout=true)
    public static void executeRightMoveCallout(String listingRecordID) {
        
        //query Listing
        Listing__c objListing = [SELECT Id, SIR_Listing_ID__c, Feaure_4__c, Age__c, 
                                     os_NumberOfParkingSpaces__c, Locality__c, CreatedDate, Listing_Price_GBP__c, Feaure_3__c, Listing_Inquiry_Recipient__r.Phone, 
                                     Form_A_for_Photoshoot__c, Initial_Listed_Date__c, RERA_Permit_Number__c, gsir_form_a_expiry__c, 
                                     Form_ASales_Leasing_form_or_NOC__c, Property_Propertyfinder__c, House_Building_Name__c, os_Longitude_pb__c, 
                                     Listing_Verified_by_CC__c, Documents_Verified__c, os_Latitude_pb__c, Rightmove_Property_Type__c, 
                                     Website_Description_Short__c, os_State_pb__c, Commercial_Amenities__c, Listing_Agent_Phone__c, Country__c, 
                                     os_PostalCode_pb__c, Address__c, os_Street_pb__c, Name, os_ListingPrice_pb__c, CurrencyIsoCode, Listing_Type__c, os_LotSize_pb__c, Property_Type__c, Status__c, os_TotalArea_pb__c, Description__c, Bedrooms__c, Bathrooms__c, Listing_Agent_Email__c, os_ListingAgentName__c, os_Listing_Agent_Photo__c, Website_Description__c, Property_Lifestyle__c, City__c, Property_Owner_Address__c, Area_Town__c, For_Sale_Available_DateTime__c, Off_Plan_Developer__c, Signed_TOB_Received__c, Ownership_Type__c, System_Allowed_for_Portals__c, Broker_s_Listing_ID__c, Website_Title__c, Propertyfinder_Region__c, Listing_Count_AML_Approved__c, LastViewedDate, Listing_Category__c, Sub_Community__c, Pending_AML_DateTime__c, Property_Sub_Type__c, Auto_Generated_broker_reference_ID__c, Estimated_Listing_Revenue__c, Department__c, Listing_Initials__c, Completion_Status__c, Listing_Buyer_AML_Count__c, Listing_Price_Expiry__c, Is_Listing_price_changed__c, Year_Built_Text__c, Private_Amenities__c, Listing_Inquiry_Recipient__r.Name, os_Floor__c, Feaure_2__c, Marketing_Exposure__c, Furnished__c, Summary__c, Is_Primary_Agent__c, Land_Registry_Check_Verified__c, Mandate__c, Listing_Seller_AML_Count__c, Photo_Uploaded_Verify__c, Publish_Date__c, Listing_Inquiry_Recipient__c, All_AML_Documents_Verified__c, Listing_Manager_Read_Write__c, Listing_Sub_Status__c, os_UnitNumber__c, Title_Deed_No__c FROM Listing__c WHERE Id = :listingRecordID];
        
        if(objListing == null){
            system.debug('objListing is null or blank');
            return;
        }
        system.debug('objListing from PublishOnTheMarket = '+objListing);
        
        //query custom metadata to fetch credentials
        RightMove__mdt objCMeta = [SELECT Id, DeveloperName, endpoint__c, branch_id__c, network_id__c, certificate_name__c, channel__c  
                                   from RightMove__mdt
                                   where DeveloperName = 'sendpropertydetails'];
        
        system.debug('objCMeta= '+objCMeta);
        
        if(objCMeta == null || String.isBlank(objCMeta.endpoint__c) ||  String.isBlank(objCMeta.certificate_name__c)){
            system.debug('objCMeta is null');
            return; 
        }
        Response_PortalListingLWC objResp = Common_Integration_OTM_and_RMove.createRequestWrapperToSendProperty(objListing, 'Rightmove UK');
        
        system.debug('serializedObj = '+objResp.serializedRequestBody);
        String methodName = 'POST';
        String requestBody = objResp.serializedRequestBody;
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(methodName);
        req.setEndpoint(objCMeta.endpoint__c);
        req.setClientCertificateName(objCMeta.certificate_name__c);
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        //   system.debug('res body =  '+res.getBody());
        //   system.debug('res code =  '+res.getStatusCode()); 
        
        if(res != null){
            
            // Deserialize JSON string into a Map<String, Object>
            Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            // Extract the 'success' field
            objResp.isSuccess = (Boolean) parsedJson.get('success');
            if(parsedJson.get('message') != null){
                objResp.errorMsg = (String) parsedJson.get('message');      
            }  
            
            //update Listing
            if(parsedJson != null && objResp.isSuccess){
                objListing.Publish_on_Rightmove_UK__c = objResp.isSuccess;
                //   system.debug('portal_url = '+(String) ((Map<String, Object>) parsedJson.get('property')).get('rightmove_url'));
                objListing.RightMove_URL__c = (String) ((Map<String, Object>) parsedJson.get('property')).get('rightmove_url');     
                
                
                update objListing;
                system.debug('objListing updated from PublishRightMove');
            }
            
            //create Integ log - call to createLogs method - 
            Integration_Log__c objLog = createIntegrationLogs(methodName, requestBody, res.getBody(),
                                                              'Outbound','CalloutAndInsertOTM_and_RMove - executeRightMoveCallout', '', String.valueOf(res.getStatusCode()), objListing.Id); 
            
            try{
                insert objLog; 
                system.debug('objLog inserted');    
            }catch(Exception e){
                system.debug('error during objLog insertion'); 
            } 
            
            
        }else{
            system.debug('lstListingRecordID is empty : RMove callout');
        }
        
    }
    
    public static Integration_Log__c createIntegrationLogs(String sMethodName, String sReqBody, String sRespBody,
                                                           String sTypeOfIntegration,String sSource, String sStatus, String sStatusCode, String listingId){
                                                               Integer maxSize = 32768;                                         
                                                               Integration_Log__c objLog = new Integration_Log__c();
                                                               objLog.Method__c = sMethodName;
                                                               
                                                               if(sReqBody.length() > maxSize ){
                                                                   sReqBody = sReqBody.substring(0, maxSize);
                                                               }                                         
                                                               objLog.Request_Body__c = sReqBody;
                                                               
                                                               if(sRespBody.length() > maxSize ){
                                                                   sRespBody = sRespBody.substring(0, maxSize);
                                                               }  
                                                               
                                                               objLog.Response_Body__c = sRespBody;
                                                               objLog.Source_Class__c = sSource;
                                                               objLog.Status__c = sStatus;
                                                               objLog.Status_Code__c = sStatusCode;
                                                               objLog.Type__c = sTypeOfIntegration;
                                                               objLog.Listing__c = listingId;
                                                               
                                                               return objLog;
                                                           }
    
}