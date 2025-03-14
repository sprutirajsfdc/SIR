public class IntegrationHelper_Anywhere {
    
    public static Anywhere_Token_Information__c objToken;
    
    public static String getToken(){
        system.debug('from getToken method'); 
        
        //query custom metadata to fetch credentials
        Anywhere_Dash__mdt objCMetaAnywhere = [SELECT Id, DeveloperName, clientId__c, clientSecret__c, endpoint__c, scope__c  
                                               from Anywhere_Dash__mdt
                                               where DeveloperName = 'Token_Dash_Sandbox_Salesforce_Sandbox'];
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        
        if(objCMetaAnywhere == null || String.isBlank(objCMetaAnywhere.clientId__c) ||
           String.isBlank(objCMetaAnywhere.clientSecret__c) || String.isBlank(objCMetaAnywhere.endpoint__c) ||
           String.isBlank(objCMetaAnywhere.scope__c)){
               system.debug('objCMetaAnywhere is null');
               return '';
           }
        
        
        String auth = EncodingUtil.base64Encode(Blob.valueOf(objCMetaAnywhere.clientId__c + ':' + objCMetaAnywhere.clientSecret__c));
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(objCMetaAnywhere.endpoint__c);
        req.setHeader('Authorization', 'Basic ' + auth);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=client_credentials&scope=' + objCMetaAnywhere.scope__c);
        
        Http http = new Http();
        
        HttpResponse res = http.send(req);
        system.debug('res body =  '+res.getBody());
        system.debug('res code =  '+res.getStatusCode());
        
        
        
        if(res.getStatusCode() == 200){
            TokenResponseAnywhere token = (TokenResponseAnywhere)JSON.deserialize(res.getBody(), TokenResponseAnywhere.class);
            system.debug('access_token = '+token.access_token);
            
            return token.access_token;
        }
        
        return null;
    }
    
    public static Boolean calloutToAnywhere(String methodName, String requestBody, String developerName, String providerIdentifier, String listingId){
        Boolean isSuccess = false;
        system.debug('developer Name = '+developerName);
        if(String.isBlank(methodName) || String.isBlank(requestBody) || String.isBlank(developerName)){
            system.debug('developer Name or methodName or requestBody is blank');
            return isSuccess;
        }
        system.debug('from calloutToAnywhere method');  
        
        //query custom metadata to fetch credentials
        Anywhere_Dash__mdt objCMetaAnywhere = [SELECT Id, DeveloperName, clientId__c, clientSecret__c, endpoint__c, scope__c, apiKey__c  
                                               from Anywhere_Dash__mdt
                                               where DeveloperName =:developerName];
        
        system.debug('objCMetaAnywhere = '+objCMetaAnywhere);
        
        if(objCMetaAnywhere == null || String.isBlank(objCMetaAnywhere.clientId__c) ||
           String.isBlank(objCMetaAnywhere.clientSecret__c) || String.isBlank(objCMetaAnywhere.endpoint__c) ||
           String.isBlank(objCMetaAnywhere.scope__c)){
               system.debug('objCMetaAnywhere is null');
               return isSuccess;
           }
        
        //HANDLE TOKEN
        //method that will handle checking, comparing token
        String token = fetchToken();
        
        if(string.isBlank(token)){
            system.debug('no token');
            return isSuccess;
        }
        
        HttpRequest req = new HttpRequest();
        req.setMethod(methodName);
        
        if(methodName == 'PUT' && String.isNotBlank(providerIdentifier)){
            
            String putEndpoint = objCMetaAnywhere.endpoint__c+'/'+providerIdentifier+'?idType=providerid';
            system.debug('enpoint for PUT = '+putEndpoint);   
            req.setEndpoint(putEndpoint);   
        }else{
            //method is POST, set endpoint for POST
            req.setEndpoint(objCMetaAnywhere.endpoint__c);
        }
        // Authorization header
        req.setHeader('Authorization', 'Bearer ' + token);
        // apiKey
        req.setHeader('apiKey', objCMetaAnywhere.apiKey__c);
        req.setHeader('Content-Type', 'application/json');
        // x-hous-version header
        req.setHeader('x-hous-version', 'v4.0');
        req.setTimeout(30000); // 30 seconds
        
        // Calculate Content-Length
        Integer contentLength = Blob.valueOf(requestBody).size();
        req.setHeader('Content-Length', '0');
        req.setBody(requestBody); //Setting req body
        
        Http http = new Http();
        HttpResponse response = http.send(req);  //2nd callout
        system.debug('response code = '+response.getStatusCode());
        system.debug('response body = '+response.getBody());
        
        Integration_Log__c objLog;
        
        if(response.getStatusCode() == 201 || response.getStatusCode() == 204){
            objLog = createIntegrationLogs('POST',req.getBody(),response.getBody(),'Outbound','IntegrationHelper_Anywhere', 'Success',
                                           String.valueOf(response.getStatusCode()),listingId);  
            isSuccess = true;        
        }else{
            objLog = createIntegrationLogs('POST',req.getBody(),response.getBody(),'Outbound','IntegrationHelper_Anywhere', 'Error',
                                           String.valueOf(response.getStatusCode()),listingId);  
        }
        
        try{
            if(objLog != null){
                insert objLog;
                system.debug('objLog inserted successfully!');  
            }
            
            if(objToken != null){
                update objToken;
                system.debug('objToken updated successfully!');  
            }
            
        }catch(Exception e){
            system.debug('error while inserting error objLog or objToken : '+e.getMessage());
        }
        return isSuccess;
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
                                                               
                                                               if(String.isnotBlank(listingId)){
                                                                   objLog.Listing__c = listingId;
                                                               }
                                                               
                                                               return objLog;   
                                                           }
    
    public static Wrapper_Anywhere publishListing(String listingRecordID, String action){
        
        Wrapper_Anywhere objListingWrapper = new Wrapper_Anywhere();
        
        if(String.isBlank(listingRecordID) || String.isBlank(action)){
            system.debug('listingRecordID or action is null or blank');
            objListingWrapper.errorMsg = 'listingRecordID or action is null or blank';
            return objListingWrapper;
        }
        
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
            objListingWrapper.errorMsg = 'pba__Listing__c is null or blank';
            return objListingWrapper;
        }
        
        if(objListing.os_Longitude_pb__c == null || objListing.os_Longitude_pb__c == null || objListing.os_PostalCode_pb__c	 == null ||
           objListing.Propertyfinder_Region__c == null || objListing.City_County__c == null || objListing.os_ListingPrice_pb__c == null ||
           objListing.Broker_s_Listing_ID__c == null || objListing.Listing_Type__c == null){
               system.debug('os_Longitude_pb__c or pba__Latitude_pb__c or County__c or Propertyfinder_Region__c or os_ListingPrice_pb__c or Listing_Type__c is null or blank');
               objListingWrapper.errorMsg = 'os_Longitude_pb__c or pba__Latitude_pb__c or County__c or Propertyfinder_Region__c or os_ListingPrice_pb__c or Listing_Type__c is null or blank';
               return objListingWrapper;
           }
        
        String listingType;
        String metaDevName;
        String methodName;
        String providerIdentifier = '';
        
        // Create instance of PropertyListingWrapper_Anywhere_forSale
        PropertyListingWrapper_Anywhere propListingWrapper = new PropertyListingWrapper_Anywhere();
        
        if(objListing.Listing_Type__c == 'Sale'){
            
            listingType = 'ResidentialSale';
            
            if(action == 'Publish'){
                metaDevName = 'Publish_Sale';   
                methodName = 'POST';    
            }else if(action == 'Unpublish'){ //Update in case of field update to update Listing info
                metaDevName = 'Unpublish';    
                methodName = 'PUT';  
                providerIdentifier = objListing.Broker_s_Listing_ID__c; 
                
            }else if(action == 'Update'){
                metaDevName = 'Update_Sale'; 
                methodName = 'PUT';  
                providerIdentifier = objListing.Broker_s_Listing_ID__c;
            }else{
                system.debug('action value is improper');
                objListingWrapper.errorMsg = 'action value is improper';
                return objListingWrapper;  
            }
        }else if(objListing.Listing_Type__c == 'Rent'){
            List<Anywhere_Rental_Frequency__mdt> lstRentalFreq = [select id, DeveloperName, label, Rental_Frequency_Value__c 
                                                                  from Anywhere_Rental_Frequency__mdt];
            system.debug('lstRentalFreq = '+lstRentalFreq);
            
            if(lstRentalFreq == null){
                system.debug('lstRentalFreq is null or blank');
                objListingWrapper.errorMsg = 'Anywhere_Rental_Frequency__mdt is null or blank';
                return objListingWrapper;  
            }
            
            Map<String, String> mapSFVal_RentalFreq = new Map<String, String>();
            for(Anywhere_Rental_Frequency__mdt objRentalFreq : lstRentalFreq){
                mapSFVal_RentalFreq.put(objRentalFreq.Label,objRentalFreq.Rental_Frequency_Value__c);
            }
            
            system.debug('mapSFVal_RentalFreq = '+mapSFVal_RentalFreq);
            
            propListingWrapper.rent = objListing.os_ListingPrice_pb__c	;
            system.debug('objListing.Price_Unit__c = '+objListing.Price_Unit__c	);
            propListingWrapper.rentalFrequencyDescription = mapSFVal_RentalFreq.get(objListing.Price_Unit__c);
            
            listingType = 'ResidentialRental';
            
            if(action == 'Publish'){
                metaDevName = 'Publish_Rental';   
                methodName = 'POST';    
            }else if(action == 'Unpublish'){
                metaDevName = 'Unpublish'; 
                methodName = 'PUT';  
                providerIdentifier = objListing.Broker_s_Listing_ID__c;     
            }else if(action == 'Update'){
                metaDevName = 'Update_Rental'; 
                methodName = 'PUT';  
                providerIdentifier = objListing.Broker_s_Listing_ID__c;
            }else{
                
                system.debug('action value is improper');
                objListingWrapper.errorMsg = 'action value is improper';
                return objListingWrapper; 
            }
        }else{
            
            system.debug('objListing.Listing_Type__c value is improper');
            objListingWrapper.errorMsg = 'Listing_Type__c value is improper';
            return objListingWrapper;    
        }
        
        if(listingType == null){
            system.debug('value of Listing_Type__c is improper');
            objListingWrapper.errorMsg = 'Listing_Type__c value is improper';
            return objListingWrapper; 
        }
        
        //fetch meta data info
        Anywhere_Listing_Status__mdt objMetaStatus = [select DeveloperName,  Code__c, Description__c 
                                                      from Anywhere_Listing_Status__mdt
                                                      where DeveloperName =:metaDevName];
        
        //fetch user info of agent/owner
        User objOwner1 = [select id, name, FirstName, LastName, Email, Company_Staff_GUID__c 
                          from user 
                          where id =: objListing.OwnerId];
        
        
        if(objOwner1 == null || String.isBlank(objOwner1.Company_Staff_GUID__c)){
            system.debug('No agent info or Company_Staff_GUID is provided');
            objListingWrapper.errorMsg = 'No agent info or Company_Staff_GUID is provided';
            return objListingWrapper; 
        }
        
        if(objMetaStatus == null){
            system.debug('objMetaStatus is null or blank');
            objListingWrapper.errorMsg = 'Anywhere_Listing_Status__mdt is null or blank';
            return objListingWrapper;
        }
        
        
        List<Anywhere_Office_Information__mdt> lstMetaOffice = [select Currency_ISO_Code__c,  Is_Active__c, Location__c,
                                                                Office_Guid__c, Office_ID__c, Office_Name__c
                                                                from Anywhere_Office_Information__mdt
                                                                where Is_Active__c = true];
        if(lstMetaOffice == null){
            system.debug('lstMetaOffice is null or blank');
            objListingWrapper.errorMsg = 'Anywhere_Office_Information__mdt is null or blank';
            return objListingWrapper;
        }
        
        Map<String, Anywhere_Office_Information__mdt> officeCodeMap = new Map<String, Anywhere_Office_Information__mdt>();
        
        for(Anywhere_Office_Information__mdt objMetaOffice : lstMetaOffice) {
            if(string.isNotBlank(objMetaOffice.Currency_ISO_Code__c)){
                officeCodeMap.put(objMetaOffice.Currency_ISO_Code__c, objMetaOffice);
            }
        }	
        if(officeCodeMap == null || officeCodeMap.size() <= 0){
            system.debug('officeCodeMap custom meta data is null or blank');
            objListingWrapper.errorMsg = 'Anywhere_Office_Information__mdt is null or blank';
            return objListingWrapper;
        }
        
        
        List<Country_Code_Anywhere__mdt> lstMetaCountryCode = [select DeveloperName,  Country_Code__c, Country_Name__c
                                                               from Country_Code_Anywhere__mdt];
        if(lstMetaCountryCode == null){
            system.debug('lstMetaCountryCode is null or blank');
            objListingWrapper.errorMsg = 'Country_Code_Anywhere__mdt is null or blank';
            return objListingWrapper;
        }
        
        Map<String, Country_Code_Anywhere__mdt> countryCodeMap = new Map<String, Country_Code_Anywhere__mdt>();
        
        for(Country_Code_Anywhere__mdt objCountryCode : lstMetaCountryCode) {
            if(string.isNotBlank(objCountryCode.DeveloperName) && string.isNotBlank(objCountryCode.Country_Code__c) &&
               string.isNotBlank(objCountryCode.Country_Name__c)){
                   countryCodeMap.put(objCountryCode.DeveloperName, objCountryCode);
               }
        }	
        
        system.debug('countryCodeMap = '+countryCodeMap);
        
        if(countryCodeMap == null || countryCodeMap.size() <= 0){
            system.debug('countryCodeMap custom meta data is null or blank');
            objListingWrapper.errorMsg = 'Country_Code_Anywhere__mdt is null or blank';
            return objListingWrapper;
        }
        
        //Metadata BuildingAreaUnit
        List<buildingAreaUnit__mdt> lstMetaBuildingAreaUnit = [select DeveloperName,  Code__c, Description__c
                                                               from buildingAreaUnit__mdt];
        if(lstMetaBuildingAreaUnit == null){
            system.debug('lstMetaBuildingAreaUnit is null or blank');
            objListingWrapper.errorMsg = 'buildingAreaUnit__mdt is null or blank';
            return objListingWrapper;
        }
        
        Map<String, buildingAreaUnit__mdt> buildingAreaMap = new Map<String, buildingAreaUnit__mdt>();
        
        for(buildingAreaUnit__mdt objBuildingArea : lstMetaBuildingAreaUnit) {
            if(string.isNotBlank(objBuildingArea.DeveloperName) && string.isNotBlank(objBuildingArea.Code__c) &&
               string.isNotBlank(objBuildingArea.Description__c)){
                   buildingAreaMap.put(objBuildingArea.DeveloperName, objBuildingArea);
               }
        }	
        
        system.debug('buildingAreaMap = '+buildingAreaMap);
        
        if(buildingAreaMap == null || buildingAreaMap.size() <= 0){
            system.debug('buildingAreaMap custom meta data is null or blank');
            objListingWrapper.errorMsg = 'buildingAreaUnit__mdt is null or blank';
            return objListingWrapper;
        }
        
        //create Request Body for callout
        
        propListingWrapper.statusCode = objMetaStatus.Code__c; //<--- uncomment
        propListingWrapper.statusDescription = objMetaStatus.Description__c;	//<--- uncomment    
        
        if(objListing.gsir_form_a_expiry__c != null){
            propListingWrapper.additionalDetails = new PropertyListingWrapper_Anywhere.cls_additionalDetails();
            Date expiryDate = objListing.gsir_form_a_expiry__c.date();
            propListingWrapper.additionalDetails.expiresOn = String.valueOf(expiryDate);	 
            system.debug('String.valueOf(expiryDate) = '+String.valueOf(expiryDate));
            //   propListingWrapper.additionalDetails.expiresOn = '2025-01-15';  
        }
        
        propListingWrapper.propertyDetails = new PropertyListingWrapper_Anywhere.cls_propertyDetails();
        propListingWrapper.propertyDetails.typeCode = 'R'; //Residential : will always be Residential
        propListingWrapper.propertyDetails.typeDescription = 'Residential';
        propListingWrapper.propertyDetails.propertyName = objListing.Name;
        propListingWrapper.propertyDetails.noOfBedrooms = objListing.Bedrooms__c;
        propListingWrapper.propertyDetails.fullBath = objListing.Bathrooms__c;
        propListingWrapper.propertyDetails.buildingArea = objListing.os_TotalArea_pb__c	; 
        
        
        Map<String, PropertySubType__mdt> mapLabel_Meta = new Map<String, PropertySubType__mdt>();
        try{
            List<PropertySubType__mdt> lstPropSubType = [select id, Label, DeveloperName, Code__c, Description__c 
                                                         from PropertySubType__mdt];
            
            if(lstPropSubType != null && lstPropSubType.size() > 0){
                
                for(PropertySubType__mdt objMeta:lstPropSubType){
                    mapLabel_Meta.put(objMeta.Label, objMeta);
                }
            }
        }catch(Exception e){
            system.debug('error msg = '+e.getMessage()+' on line = '+e.getLineNumber());
        }
        
        if(mapLabel_Meta != null && String.isNotBlank(objListing.Property_Sub_Type__c) &&
           mapLabel_Meta.containsKey(objListing.Property_Sub_Type__c)){
               
               propListingWrapper.propertyDetails.subtypeCode = Integer.valueOf(mapLabel_Meta.get(objListing.Property_Sub_Type__c).Code__c) ;//1; //<--- TBD
               propListingWrapper.propertyDetails.subtypeDescription = mapLabel_Meta.get(objListing.Property_Sub_Type__c).Description__c;// 'Apartment'; //<--- TBD
               
           }
        
        if(buildingAreaMap.containsKey(objListing.Price_Unit__c)){
            propListingWrapper.propertyDetails.buildingAreaUnitCode = buildingAreaMap.get(objListing.Price_Unit__c).Code__c;
            propListingWrapper.propertyDetails.buildingAreaUnitDescription = buildingAreaMap.get(objListing.Price_Unit__c).Description__c;
        }else{
            system.debug('no mapping is present for Price_Unit__c');
            objListingWrapper.errorMsg = 'no mapping is present for Price_Unit__c';
            return objListingWrapper;
        }
        
        propListingWrapper.propertyDetails.location = new PropertyListingWrapper_Anywhere.cls_location();
        propListingWrapper.propertyDetails.location.latitude = Double.valueOf(objListing.os_Latitude_pb__c);
        propListingWrapper.propertyDetails.location.longitude = Double.valueOf(objListing.os_Longitude_pb__c);
        
        propListingWrapper.neighborhood = new List<String>{objListing.Community_Propertyfinder__c};  //<--- added :26/8/24
        
      //  String addressString = objListing.pba_uaefields__Propertyfinder_Region__c;	//<--- previously
        String addressString = objListing.Sub_Community_for_Propertyfinder__c; //<--- added
        propListingWrapper.propertyDetails.location.addressLine1 = addressString;
        
        if(addressString.length() <= 200) {
            propListingWrapper.propertyDetails.location.addressLine1 = addressString;
        } else {
            // Calculate the number of chunks required
            Integer chunks = (addressString.length() + 199) / 200;
            
            // Store the chunks into the available variables
            for(Integer i = 0; i < chunks; i++) {
                Integer start = i * 200;
                Integer endVar = Math.min((i + 1) * 200, addressString.length());
                
                // Distribute the chunks into available variables
                switch on i {
                    //   when 0 { house_name_number = addressString.substring(start, endVar); }
                    when 0 { propListingWrapper.propertyDetails.location.addressLine2 = addressString.substring(start, endVar); }
                    when 1 { propListingWrapper.propertyDetails.location.addressLine3 = addressString.substring(start, endVar); }
                }
            }
        }
        
        
        propListingWrapper.propertyDetails.location.city = objListing.City_County__c;
        propListingWrapper.propertyDetails.location.postalCode = objListing.os_PostalCode_pb__c;
        propListingWrapper.propertyDetails.location.countryCode = countryCodeMap.get(objListing.CurrencyIsoCode).Country_Code__c;
        propListingWrapper.propertyDetails.location.countryName = countryCodeMap.get(objListing.CurrencyIsoCode).Country_Name__c;
        system.debug('countryCode = '+propListingWrapper.propertyDetails.location.countryCode);
        
        
        
        ///MEDIA
        List<Anywhere_Listing_Media_Format_Category__mdt> lstMediaFormat = [select id, DeveloperName, Code_Description__c, Category__c, Category_Code__c 
                                                                            from Anywhere_Listing_Media_Format_Category__mdt];
        
        
        if(lstMediaFormat != null && lstMediaFormat.size() > 0){
            
            Map<String, Anywhere_Listing_Media_Format_Category__mdt> mapDevName_MediaFormat = new Map<String, Anywhere_Listing_Media_Format_Category__mdt>();
            
            for(Anywhere_Listing_Media_Format_Category__mdt obj:lstMediaFormat){
                mapDevName_MediaFormat.put(obj.DeveloperName,obj);
            }
            
            List<Property_Media__c> lstPropMedia = [SELECT Id, Name, Property__r.Name, os_BaseUrl__c, os_Title__c, Tag__c, Sort_on_Portal_Feed__c, os_IsOnPortalFeed__c  
                                                        FROM Property_Media__c
                                                        where
                                                         os_IsOnPortalFeed__c = true
                                                        and Tag__c != 'EPC'];
            
            List<Anywhere_Media_Category__mdt> lstMediaCategory = [select id,Label, Code__c, Description__c from Anywhere_Media_Category__mdt]; 
            
            Map<String, Anywhere_Media_Category__mdt> map_Label_MediaCategory = new Map<String, Anywhere_Media_Category__mdt>();
            
            if(map_Label_MediaCategory != null){
                for(Anywhere_Media_Category__mdt objMediaCat : lstMediaCategory){
                    map_Label_MediaCategory.put(objMediaCat.Label,objMediaCat);
                }
            }
            
            system.debug('map_Label_MediaCategory = '+map_Label_MediaCategory);
            
            if(lstMediaFormat != null && lstMediaFormat.size() > 0 &&
               lstPropMedia != null && lstPropMedia.size() > 0){
                   
                   //MEDIA
                   propListingWrapper.media = new List<PropertyListingWrapper_Anywhere.cls_media>();
                   
                   Integer maxNumber = 0;
                   
                   for(Property_Media__c objPropMedia : lstPropMedia){
                       
                       
                       PropertyListingWrapper_Anywhere.cls_media objMedia = new PropertyListingWrapper_Anywhere.cls_media();	
                       objMedia.sequenceNumber = Integer.valueOf(objPropMedia.Sort_on_Portal_Feed__c);
                       
                       if (objMedia.sequenceNumber > maxNumber) {
                           maxNumber = objMedia.sequenceNumber;
                       }
                       
                       if(objPropMedia.Tag__c == 'EPC' || objPropMedia.Tag__c == 'Floorplan' ||
                          objPropMedia.Tag__c == 'Interior' || objPropMedia.Tag__c == 'Exterior'|| 
                          String.isBlank(objPropMedia.Tag__c)){
                              objMedia.category = mapDevName_MediaFormat.get('IM').Category__c;
                              objMedia.formatCode = 'IM';    
                              
                              if(objPropMedia.Tag__c == 'Floorplan' && map_Label_MediaCategory != null &&
                                 map_Label_MediaCategory.containsKey(objPropMedia.Tag__c)){
                                     
                                     objMedia.category = String.valueOf(map_Label_MediaCategory.get(objPropMedia.Tag__c).Description__c);
                                     //     system.debug('map_Label_MediaCategory = '+map_Label_MediaCategory);    
                                 }
                              
                          }
                       objMedia.caption = objPropMedia.os_Title__c;
                       objMedia.url = objPropMedia.os_BaseUrl__c;
                       objMedia.sequenceNumber = Integer.valueOf(objPropMedia.Sort_on_Portal_Feed__c);
                       
                       
                       propListingWrapper.media.add(objMedia);
                   }
                   
                   system.debug('maxNumber = '+maxNumber);
                   
                   if(String.isNotBlank(objListing.Website_Listing_URL_When_Published__c)){
                       
                       PropertyListingWrapper_Anywhere.cls_media objMedia2 = new PropertyListingWrapper_Anywhere.cls_media();
                       objMedia2.category = map_Label_MediaCategory.get('Website_Listing_URL_When_Published__c').Description__c;
                       objMedia2.caption = 'Local Listing Link';
                       objMedia2.url = objListing.Website_Listing_URL_When_Published__c;
                       objMedia2.sequenceNumber = maxNumber + 1;
                       objMedia2.formatCode = 'UR';
                       propListingWrapper.media.add(objMedia2);
                   }
               }
        }
        if(String.isNotBlank(objListing.Description__c)){
            //REMARKS
            propListingWrapper.remarks = new List<PropertyListingWrapper_Anywhere.cls_remarks>();
            PropertyListingWrapper_Anywhere.cls_remarks objRemarks = new PropertyListingWrapper_Anywhere.cls_remarks();
            objRemarks.remarkTypeCode = 14;
            objRemarks.remarkTypeDescription = 'Property Description';
            objRemarks.languageCode = 'en';
            objRemarks.languageName = 'English';
            objRemarks.remark = objListing.Description__c	;
            propListingWrapper.remarks.add(objRemarks);
        }
        
        //Agents info
        propListingWrapper.listingAgents = new List<PropertyListingWrapper_Anywhere.cls_listingAgents>();
        PropertyListingWrapper_Anywhere.cls_listingAgents agent = new PropertyListingWrapper_Anywhere.cls_listingAgents();
        
        agent.primaryOffice = new PropertyListingWrapper_Anywhere.cls_primaryOffice();
        system.debug('office guid = '+officeCodeMap.get(objListing.CurrencyIsoCode).Office_Guid__c);
        system.debug('office name = '+officeCodeMap.get(objListing.CurrencyIsoCode).Office_Name__c);
        agent.primaryOffice.officeGuid = officeCodeMap.get(objListing.CurrencyIsoCode).Office_Guid__c;
        agent.companyStaffGuid = objOwner1.Company_Staff_GUID__c;   
        agent.sequenceNumber = 1; //if only 1 agent info is to be sent
        agent.isPrimary = true; //if only 1 agent info is to be sent
        propListingWrapper.listingAgents.add(agent);
        
        if(String.isNotBlank(objListing.Co_Owner__c)){
            User objOwner2 = [select id, name, FirstName, LastName, Email, Company_Staff_GUID__c 
                              from user 
                              where id =: objListing.Co_Owner__c];  
            
            PropertyListingWrapper_Anywhere.cls_listingAgents agent2 = new PropertyListingWrapper_Anywhere.cls_listingAgents();
            
            agent2.primaryOffice = new PropertyListingWrapper_Anywhere.cls_primaryOffice();
            system.debug('office guid = '+officeCodeMap.get(objListing.CurrencyIsoCode).Office_Guid__c);
            system.debug('office name = '+officeCodeMap.get(objListing.CurrencyIsoCode).Office_Name__c);
            agent2.primaryOffice.officeGuid = officeCodeMap.get(objListing.CurrencyIsoCode).Office_Guid__c;
            agent2.companyStaffGuid = objOwner2.Company_Staff_GUID__c;   
            agent2.sequenceNumber = 2; 
            agent2.isPrimary = false; 
            propListingWrapper.listingAgents.add(agent2);
        }
        
        
        
        
        propListingWrapper.office = new PropertyListingWrapper_Anywhere.cls_office();
        propListingWrapper.office.officeGuid = officeCodeMap.get(objListing.CurrencyIsoCode).Office_Guid__c; //office will be selected based on CurrencyISO
        
        propListingWrapper.listPrice = objListing.os_ListingPrice_pb__c;
        propListingWrapper.currencyCode = objListing.CurrencyIsoCode;
        propListingWrapper.isShowAddressOnInternet = true;
        propListingWrapper.isHideListPrice = false; //by default setting it to False
        propListingWrapper.isNewConstruction = false; // default value
        propListingWrapper.isShowOnInternet = true;	//by default setting it to True
        propListingWrapper.providerIdentifier = objListing.Broker_s_Listing_ID__c;
        propListingWrapper.primaryMLS = objListing.Broker_s_Listing_ID__c;
        
        // Use the instance as needed
        // Serialize the PropertyListingWrapper_Anywhere instance
        String requestbody = System.JSON.serialize(propListingWrapper);
        
        // Use the serialized data as needed
        System.debug('requestbody = '+requestbody);
        System.debug('methodName = '+methodName);
        System.debug('listingType = '+listingType);
        
        
        objListingWrapper.methodName = methodName;
        objListingWrapper.requestBody = requestbody;
        objListingWrapper.listingType = listingType;
        objListingWrapper.providerIdentifier = providerIdentifier;
        return objListingWrapper;
    }
    
    public static String fetchToken(){
        //fetch custom object for token
        Anywhere_Token_Information__c objTokenCustomSet = [select  Id,  Name, Token__c, Generated_On__c 
                                                    	   from Anywhere_Token_Information__c 
                                                           order by CreatedDate desc limit 1];
        
        DateTime startDate = objTokenCustomSet.Generated_On__c;
        DateTime endDate = DateTime.now();
        
        // Calculate the difference in milliseconds
        Long differenceInMilliseconds = endDate.getTime() - startDate.getTime();

        // Convert milliseconds to hours
        Long differenceInHours = differenceInMilliseconds / (1000 * 60 * 60);
        
        // Output the result
        System.debug('Difference in Hours: ' + differenceInHours);

        
        if(differenceInHours > 1 || differenceInHours == 1){
            //update token info custom setting
            objTokenCustomSet.Token__c = getToken(); //replace token by calling the endpoint and store token
            objTokenCustomSet.Generated_On__c = DateTime.now(); //replace generated on info
            objToken = objTokenCustomSet;
            return objTokenCustomSet.Token__c;
        }
        return objTokenCustomSet.Token__c;
    }
    
    
}