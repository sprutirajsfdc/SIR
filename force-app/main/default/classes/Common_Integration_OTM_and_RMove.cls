public class Common_Integration_OTM_and_RMove {
    
    public static Response_PortalListingLWC createRequestWrapperToSendProperty(Listing__c objListing, String portalName){
        
        system.debug('inside Common_Integration_OTM_and_RMove!');
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = false;
        objResp.errorMsg = '';
        
        if(objListing == null){
            system.debug('objListing is null or blank');
            objResp.errorMsg = 'objListing is null or blank';
            return objResp;
        }
        try{
            //query custom metadata : UK Active Branches for OTM and RightMove
            UK_Active_Branch__mdt objCMetaBranch = [SELECT Id, DeveloperName, network_id__c, branch_id__c, To_use__c 
                                                    from UK_Active_Branch__mdt 
                                                    where To_use__c = true and Portal_Name__c =:portalName ];	
            
            if(objCMetaBranch == null || objCMetaBranch.network_id__c == null || objCMetaBranch.branch_id__c == null){
                system.debug('Cannot proceed, no UK_Active_Branch__mdt custom metadata information'); 
                objResp.errorMsg = 'Cannot proceed, no UK_Active_Branch__mdt custom metadata information';
                return objResp;
            } 
            
            //query custom metadata for property_type
            List<Property_Type__mdt> propertyTypes = [SELECT MasterLabel, property_type_code__c, SF_Picklist_Value__c 
                                                      FROM Property_Type__mdt];
            
            if(propertyTypes == null || propertyTypes.size() <= 0){
                system.debug('propertyTypes custom meta data is null or blank');
                objResp.errorMsg = 'Cannot proceed, propertyTypes custom meta data is null or blank';
                return objResp;
            }
            // Convert the list into a map using SF_Picklist_Value__c as the key and property_type_code__c as the value
            Map<String, Decimal> propertyTypeMap = new Map<String, Decimal>();
            for(Property_Type__mdt propertyType : propertyTypes) {
                if(string.isNotBlank(propertyType.SF_Picklist_Value__c) && propertyType.property_type_code__c != null ){
                    propertyTypeMap.put(propertyType.SF_Picklist_Value__c, propertyType.property_type_code__c);
                }
            }
            if(propertyTypeMap == null || propertyTypeMap.size() <= 0){
                system.debug('propertyTypeMap custom meta data is null or blank');
                objResp.errorMsg = 'Cannot proceed, propertyTypes custom meta data is null or blank';
                return objResp;
            }
            
            if(String.isBlank(objListing.Listing_Type__c)){
                system.debug('Cannot proceed, Listing Type is not provided.'); 
                objResp.errorMsg = 'Cannot proceed, Listing Type is not provided.';
                return objResp;
            }
            
            //query custom metadata for channel_type
            List<channel_type__mdt> channelTypes = [SELECT Id, MasterLabel, SF_Picklist_Value__c, channel_type_code__c  
                                                    from channel_type__mdt ];
            
            if(channelTypes == null || channelTypes.size() <= 0){
                system.debug('channelTypes custom meta data is null or blank');
                objResp.errorMsg = 'channelTypes custom meta data is null or blank';
                return objResp;
            }
            // Convert the list into a map using SF_Picklist_Value__c as the key and property_type_code__c as the value
            Map<String, Integer> channelTypeMap = new Map<String, Integer>();
            for(channel_type__mdt channelType : channelTypes) {
                if(string.isNotBlank(channelType.SF_Picklist_Value__c) && channelType.channel_type_code__c != null ){
                    channelTypeMap.put(channelType.SF_Picklist_Value__c, Integer.valueOf(channelType.channel_type_code__c));
                }
            }
            if(channelTypeMap == null || channelTypeMap.size() <= 0){
                system.debug('channelTypeMap custom meta data is null or blank');
                objResp.errorMsg = 'channelTypes custom meta data is null or blank';
                return objResp;
            }
            Integer channel;
            if(channelTypeMap.containsKey(objListing.Listing_Type__c)){
                channel = channelTypeMap.get(objListing.Listing_Type__c); 
            }else{
                system.debug('Cannot proceed, channelTypeMap doesnt contain Listing_Type__c as key');
                objResp.errorMsg = 'Cannot proceed, channelTypeMap doesnt contain Listing_Type__c as key';
                return objResp;
            }
            
            if(channel == null){
                system.debug('Cannot proceed, Channel is invalid'); 
                objResp.errorMsg = 'Cannot proceed, Channel is invalid';
                return objResp;
            }
            
            //create JSON request body
            Wrapper_PublishOntheMarket wrapper = new Wrapper_PublishOntheMarket();
            
            
            //network wrapper
            wrapper.network = new Wrapper_PublishOntheMarket.Network();
            wrapper.network.network_id = (Integer)objCMetaBranch.network_id__c;
            
            //branch wrapper
            wrapper.branch = new Wrapper_PublishOntheMarket.Branch();
            wrapper.branch.branch_id = (Integer)objCMetaBranch.branch_id__c;
            wrapper.branch.channel = channel;
            
            //property wrapper
            wrapper.property = new Wrapper_PublishOntheMarket.Property();
            wrapper.property.agent_ref = objListing.Broker_s_Listing_ID__c;
            wrapper.property.published = true;
            wrapper.property.status = 1;	//indicates Available
            
            if(propertyTypeMap.containsKey(objListing.Property_Type__c)){
                wrapper.property.property_type = Integer.valueOf(propertyTypeMap.get(objListing.Property_Type__c));
            }else{
                system.debug('cannot make callout, improper property_type');
                objResp.errorMsg = 'cannot make callout, improper property_type';
                return objResp;
            }
            
            wrapper.property.address = new Wrapper_PublishOntheMarket.Address();
            
            if(String.isnotblank(objListing.os_UnitNumber__c) && 
               String.isnotblank(objListing.Propertyfinder_Region__c) && 
               String.isnotblank(objListing.Sub_Community_for_Propertyfinder__c) && 
               String.isnotblank(objListing.Community_Propertyfinder__c)  && 
               String.isnotblank(objListing.City__c)){
                   
                   //  String addressString = objListing.pba_uaefields__Propertyfinder_Region__c; <--- before
                   String display_address = truncateToChars(objListing.Propertyfinder_Region__c, 120);
                   String house_name_number = truncateToChars(objListing.os_UnitNumber__c, 60);
                   String address_2 = truncateToChars(objListing.Sub_Community_for_Propertyfinder__c, 60);   
                   String address_3 = truncateToChars(objListing.Community_Propertyfinder__c, 60);
                   String town = truncateToChars(objListing.City__c, 60);   
                   wrapper.property.address.display_address = display_address;   
                   wrapper.property.address.house_name_number = house_name_number;
                   wrapper.property.address.address_2 = address_2;
                   wrapper.property.address.address_3 = address_3;
                   wrapper.property.address.town = town;
                   
                   
               }else{
                   system.debug('cannot make callout, Apartment Number or Sub community or community or city - propertyfinder is blank!');
                   objResp.errorMsg = 'cannot make callout, Apartment Number or Sub community or community or city - propertyfinder is blank!';
                   return objResp;
               }
            
            if(String.isblank(objListing.os_PostalCode_pb__c) || (!objListing.os_PostalCode_pb__c.contains(' '))){
                system.debug('cannot make callout, PostalCode is blank or of improper format! objListing.os_PostalCode_pb__c = '+objListing.os_PostalCode_pb__c);
                objResp.errorMsg = 'cannot make callout, PostalCode is blank or of improper format!';
                return objResp;
            }
            
            String postCodeString = (objListing.os_PostalCode_pb__c);
            List<String> postCodeParts = postCodeString.split(' ');
            
            String postcode_1 = postCodeParts[0];
            String postcode_2 = postCodeParts[1];
            
            system.debug('postcode_1 = '+postcode_1);
            system.debug('postcode_2= '+postcode_2);
            
            if(String.isblank(postcode_1) && String.isblank(postcode_2)){
                system.debug('cannot make callout, PostalCode is blank or improper!');
                objResp.errorMsg = 'cannot make callout, PostalCode is blank or of improper format!';
                return objResp;
            }
            
            wrapper.property.address.postcode_1 = postcode_1;
            wrapper.property.address.postcode_2 = postcode_2;
            
            
            
            if(objListing.os_ListingPrice_pb__c == null){
                system.debug('os_ListingPrice_pb__c is null'); 
                objResp.errorMsg = 'cannot make callout, os_ListingPrice_pb__c is null!';
                return objResp;
            }
            
            wrapper.property.price_information = new Wrapper_PublishOntheMarket.PriceInformation();
            wrapper.property.price_information.price = objListing.os_ListingPrice_pb__c;
            
            system.debug('objListing.Price_Unit__c = '+objListing.Price_Unit__c);
            
            if(objListing.Price_Unit__c != null){
                
                //RENT FREQ
                List<OTM_Rental_Frequency__mdt> lstRentalFreq = [select id, Label, Code__c, Code_Description__c 
                                                                 from OTM_Rental_Frequency__mdt];
                system.debug('lstRentalFreq = '+lstRentalFreq);
                Map<String, Integer> map_Label_FreqCode = new Map<String, Integer>();
                
                for(OTM_Rental_Frequency__mdt obj:lstRentalFreq){
                    map_Label_FreqCode.put(obj.Label,Integer.valueOf(obj.Code__c));
                    
                }
                
                system.debug('map_Label_FreqCode = '+map_Label_FreqCode);
                
                if(map_Label_FreqCode != null && map_Label_FreqCode.containsKey(objListing.Price_Unit__c)){
                    wrapper.property.price_information.rent_frequency = Integer.valueOf(map_Label_FreqCode.get(objListing.Price_Unit__c)); 
                }
                
                if(String.isNotBlank(objListing.Ownership_Type__c)){
                    //TENURE
                    List<OTM_Ownership_Tenure__mdt> lstOwnership_Tenure = [select id, Label, Code__c, Code_Description__c 
                                                                           from OTM_Ownership_Tenure__mdt];
                    system.debug('lstOwnership_Tenure = '+lstOwnership_Tenure);
                    
                    Map<String, Integer> map_Label_TenureCode = new Map<String, Integer>();
                    
                    for(OTM_Ownership_Tenure__mdt obj:lstOwnership_Tenure){
                        map_Label_TenureCode.put(obj.Label,Integer.valueOf(obj.Code__c));
                    }
                    
                    system.debug('map_Label_TenureCode = '+map_Label_TenureCode);
                    
                    if(map_Label_TenureCode != null && map_Label_TenureCode.containsKey(objListing.Ownership_Type__c) &&
                       String.isNotBlank(objListing.Ownership_Type__c)){
                           
                           wrapper.property.price_information.tenure_type = map_Label_TenureCode.get(objListing.Ownership_Type__c); 
                           
                       }
                }
                
                
                
            }
            
            if(objListing.Tenure_Remaining_Years__c != null){
                wrapper.property.price_information.tenure_unexpired_years = Integer.valueOf(objListing.Tenure_Remaining_Years__c);  
            }
            
            if(objListing.Summary__c == null || objListing.Description__c == null || objListing.Bedrooms__c == null){
                system.debug('Summary or Description or Bedrooms is null'); 
                objResp.errorMsg = 'cannot make callout, Summary or Description or Bedrooms is null!';
                return objResp;
            }
            
            wrapper.property.details = new Wrapper_PublishOntheMarket.Details();
            wrapper.property.details.summary = objListing.Summary__c;
            wrapper.property.details.description = objListing.Description__c;
            wrapper.property.details.bedrooms = Integer.valueOf(objListing.Bedrooms__c);
            
            if(objListing.Bedrooms__c != null){
                wrapper.property.details.bathrooms = Integer.valueOf(objListing.Bedrooms__c);
            }
            
            
            
            if(objListing.os_TotalArea_pb__c != null){
                
                system.debug('objListing.Price_Unit__c = '+objListing.Price_Unit__c);
                //query to get area_unit__mdt custom meta data
                List<area_unit__mdt> lstAreaUnitCustom = [select id, DeveloperName, label, Code__c 
                                                          from area_unit__mdt
                                                          where DeveloperName =: objListing.Price_Unit__c limit 1];
                //  system.debug('lstAreaUnitCustom = '+lstAreaUnitCustom);
                if(lstAreaUnitCustom != null && lstAreaUnitCustom.size() > 0 && lstAreaUnitCustom[0].Code__c != null){
                    wrapper.property.details.sizing = new Wrapper_PublishOntheMarket.Sizing();
                    wrapper.property.details.sizing.maximum = objListing.os_TotalArea_pb__c; 
                    wrapper.property.details.sizing.area_unit = Integer.valueOf(lstAreaUnitCustom[0].Code__c);
                }
                
            }
            
            if(String.isNotBlank(objListing.Private_Amenities__c)){
                String featuresString = objListing.Private_Amenities__c;
                
                // Split the string by ';' to get individual features
                List<String> featuresList = featuresString.split(';');
                
                List<String> newList = new List<String>();
                
                if (featuresList.size() > 10) {
                    
                    for (Integer i = 0; i< 10; i++) {
                        newList.add(featuresList[i]);
                    }
                    wrapper.property.details.features = newList;
                }
            }            
            
            List<Property_Media__c> lstPropMedia = [SELECT Id, Name, Property__r.Name, os_BaseUrl__c, os_Title__c, Tag__c, Sort_on_Portal_Feed__c 
                                                        FROM Property_Media__c
                                                        where Property__c =: objListing.Property__c 
                                                        and os_IsOnPortalFeed__c = true];
            
            //collect property_type__mdt records
            List<media_type__mdt> lstMediaTypes = [SELECT Id, media_type_code__c, SF_Picklist_Value__c
                                                   from media_type__mdt];
            
            if(lstPropMedia == null || lstPropMedia.size() <= 0 || lstMediaTypes == null || lstMediaTypes.size() <= 0){
                system.debug('Cannot proceed to callout, lstPropMedia or media type metadata is empty'); 
                objResp.errorMsg = 'cannot make callout, lstPropMedia or media type metadata is empty!';
                return objResp;
            } 
            
            // Convert the list into a map using SF_Picklist_Value__c as the key and media_type_code__c as the value
            Map<String, Integer> mediaTypeMap = new Map<String, Integer>();
            for(media_type__mdt objMediaType : lstMediaTypes) {
                if(string.isNotBlank(objMediaType.SF_Picklist_Value__c) && objMediaType.media_type_code__c != null ){
                    mediaTypeMap.put(objMediaType.SF_Picklist_Value__c, Integer.valueOf(objMediaType.media_type_code__c));
                }
            }	
            if(mediaTypeMap == null || mediaTypeMap.size() <= 0){
                system.debug('propertyTypeMap custom meta data is null or blank');
                objResp.errorMsg = 'cannot make callout, propertyTypeMap custom meta data is null or blank!';
                return objResp;
            }
            
            // Create Media objects and populate them
            List<Wrapper_PublishOntheMarket.Media> mediaList = new List<Wrapper_PublishOntheMarket.Media>();
            
            for(Property_Media__c objPropMedia : lstPropMedia) {
                
                if(objPropMedia.Tag__c == null){ //no tag
                    
                    Wrapper_PublishOntheMarket.Media media1 = new Wrapper_PublishOntheMarket.Media();   
                    media1.media_type = Integer.valueOf(mediaTypeMap.get('no tag'));    
                    media1.media_url = objPropMedia.os_BaseUrl__c;
                    
                    if(objPropMedia.Sort_on_Portal_Feed__c != null){
                        media1.sort_order = Integer.valueOf(objPropMedia.Sort_on_Portal_Feed__c);   
                    }
                    
                    mediaList.add(media1);
                    
                }else if(mediaTypeMap.containsKey(objPropMedia.Tag__c)){
                    
                    Wrapper_PublishOntheMarket.Media media1 = new Wrapper_PublishOntheMarket.Media();   
                    media1.media_type = Integer.valueOf(mediaTypeMap.get(objPropMedia.Tag__c));    
                    media1.media_url = objPropMedia.os_BaseUrl__c;
                    mediaList.add(media1);
                }
                
            }
            
            if(mediaList == null || mediaList.size() <= 0){
                system.debug('Cannot proceed to callout, mediaList is empty'); 
            }
            
            // Create Property object and set media list
            wrapper.property.media = mediaList;
            
            //    system.debug('wrapper = '+wrapper);
            
            String serializedObj = JSON.serialize(wrapper); //<--- uncomment, dont need anymore
            //   system.debug('serializedObj = '+serializedObj);
            
            objResp.isSuccess = true;
            objResp.errorMsg = '';
            objResp.serializedRequestBody = serializedObj;
            system.debug('objResp.serializedRequestBody = '+objResp.serializedRequestBody);
            return objResp;
        }catch(Exception e){
            system.debug('error msg = '+e.getMessage()+' on line = '+e.getLineNumber());   
            objResp.errorMsg = 'error msg = '+e.getMessage()+' on line = '+e.getLineNumber();
            return objResp;  
        }
    }
    
    public static HttpResponse makeCallout(String methodName, String requestBody, String listingId, String sourceClass, String endpoint, String certificate_name){
        system.debug('requestBody = '+requestBody);       
        if(String.isBlank(methodName) || String.isBlank(requestBody) || String.isBlank(endpoint) || String.isBlank(certificate_name)){
            system.debug('developer Name or methodName or requestBody is blank');
            return null;
        }
        system.debug('from calloutTo_OnTheMarket method'); 
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(methodName);
        req.setEndpoint(endpoint);
        req.setClientCertificateName(certificate_name);
        
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse res;
        try{
            res = http.send(req); 
            system.debug('res body =  '+res.getBody());
            system.debug('res code =  '+res.getStatusCode());
            
            //create logs
            createIntegrationLogs(methodName, requestBody, res.getBody(), 'Outbound', sourceClass, '',String.valueOf(res.getStatusCode()), listingId);
            return res;
            
        }catch(Exception e){
            system.debug('error during callout =  '+e.getMessage()); 
            return res;
        }
        
        
    }
    
    
    public static void createIntegrationLogs(String sMethodName, String sReqBody, String sRespBody,
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
                                                 
                                                 try{
                                                     insert objLog; 
                                                     system.debug('objLog inserted');    
                                                 }catch(Exception e){
                                                     system.debug('error during objLog insertion'); 
                                                 }
                                             }
    
    public static Response_PortalListingLWC createRequestWrapperToRemoveProperty(Listing__c objListing, String portalName){
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = false;
        objResp.errorMsg = '';
        
        if(objListing == null || String.isBlank(portalName)){
            system.debug('objListing is null or blank');
            objResp.errorMsg = 'objListing is null or blank';
            return objResp;
        }
        system.debug('objListing from UnPublishOntheMarket = '+objListing);
        
        try{
            //query custom metadata : UK Active Branches
            UK_Active_Branch__mdt objCMetaBranch = [SELECT Id, DeveloperName, network_id__c, branch_id__c, To_use__c 
                                                    from UK_Active_Branch__mdt 
                                                    where To_use__c = true and Portal_Name__c =:portalName];	
            
            if(objCMetaBranch == null){
                system.debug('Cannot proceed, no UK_Active_Branch__mdt custom metadata information'); 
                objResp.errorMsg = 'Cannot proceed, no UK_Active_Branch__mdt custom metadata information';
                return objResp;
            }
            
            //query custom metadata for channel_type
            List<channel_type__mdt> channelTypes = [SELECT Id, MasterLabel, SF_Picklist_Value__c, channel_type_code__c  
                                                    from channel_type__mdt ];
            
            if(channelTypes == null || channelTypes.size() <= 0){
                system.debug('channelTypes custom meta data is null or blank');
                objResp.errorMsg = 'Cannot proceed, channelTypes custom meta data is null or blank';
                return objResp;
            }
            // Convert the list into a map using SF_Picklist_Value__c as the key and property_type_code__c as the value
            Map<String, Integer> channelTypeMap = new Map<String, Integer>();
            for(channel_type__mdt channelType : channelTypes) {
                if(string.isNotBlank(channelType.SF_Picklist_Value__c) && channelType.channel_type_code__c != null ){
                    channelTypeMap.put(channelType.SF_Picklist_Value__c, Integer.valueOf(channelType.channel_type_code__c));
                }
            }
            if(channelTypeMap == null || channelTypeMap.size() <= 0){
                system.debug('channelTypeMap custom meta data is null or blank');
                objResp.errorMsg = 'Cannot proceed, channelTypes custom meta data is null or blank';
                return objResp;
            }
            Integer channel;
            if(channelTypeMap.containsKey(objListing.Listing_Type__c	)){
                channel = channelTypeMap.get(objListing.Listing_Type__c	); 
            }else{
                system.debug('Cannot proceed, channelTypeMap doesnt contain Listing_Type__c	 as key');
                objResp.errorMsg = 'Cannot proceed, channelTypeMap doesnt contain Listing_Type__c as key';
                return objResp;
            }
            
            if(channel == null){
                system.debug('Cannot proceed, Channel is invalid'); 
                objResp.errorMsg = 'Cannot proceed, Channel is invalid';
                return objResp;
            }
            
            //create JSON request body
            Wrapper_UnPublish_OTM_and_RMove wrapper = new Wrapper_UnPublish_OTM_and_RMove();
            
            
            //network wrapper
            wrapper.network = new Wrapper_UnPublish_OTM_and_RMove.Network();
            wrapper.network.network_id = (Integer)objCMetaBranch.network_id__c;
            
            //branch wrapper
            wrapper.branch = new Wrapper_UnPublish_OTM_and_RMove.Branch();
            wrapper.branch.branch_id = (Integer)objCMetaBranch.branch_id__c;
            
            wrapper.branch.channel = channel;
            
            //property wrapper
            wrapper.property = new Wrapper_UnPublish_OTM_and_RMove.Property();
            wrapper.property.agent_ref = objListing.Broker_s_Listing_ID__c;
            wrapper.property.removal_reason = 11;
            
            system.debug('wrapper = '+wrapper);
            //  String serializedObj = JSON.serialize(wrapper);
            objResp.isSuccess = true;
            objResp.errorMsg = '';
            objResp.serializedRequestBody = JSON.serialize(wrapper);
            system.debug('objResp.serializedRequestBody from CmnInteg = '+objResp.serializedRequestBody);
            return objResp;
        }catch(Exception e){
            system.debug('error msg = '+e.getMessage()+' on line = '+e.getLineNumber());   
            objResp.errorMsg = 'error msg = '+e.getMessage()+' on line = '+e.getLineNumber();
            return objResp; 
        }
    }
    
    public static String truncateToChars(String inputString, Integer characLen) {
        if (inputString != null && inputString.length() > characLen) {
            return inputString.substring(0, characLen);
        }
        return inputString;
    }
}