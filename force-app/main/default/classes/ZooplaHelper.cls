public class ZooplaHelper {
    
    public static String qry = '';
    
    public static Map<string,string> getAllMapping() {
        
        //getAllMapping method will traverse zoopla_portal__c custom setting
        //to populate mapMappingTable where key is Zoopla JSON field and value is SF API field
        //same SF API fields r also added to the query
        
        qry ='';
        Map<String, String> mapMappingTable = new Map<String,String>();
        for (zoopla_portal__c mappingTableRec : zoopla_portal__c.getall().Values()) {
            if (mappingTableRec.Zoopla_Portal_Fields__c != null && mappingTableRec.Listing_Field_Api_Name__c != Null ) {
                //mapMappingTable.put(mappingTableRec.DeveloperName , mappingTableRec.FieldAPIName__c);
                mapMappingTable.put(mappingTableRec.Zoopla_Portal_Fields__c, mappingTableRec.Listing_Field_Api_Name__c);
                
                qry += mappingTableRec.Listing_Field_Api_Name__c + ',';
            }
        }
        
        return mapMappingTable;
    }
    /*
    public static String serializeToJson(Object data) {
        String jsonString = JSON.serialize(data);
        System.debug('Serialized JSON: ' + jsonString);
        return jsonString;
    }  
    */
    /*-----------------------Sale-------------------*/
    public static String createForSaleListing(ID listingId) {
        
        system.debug('inside createForSaleListing');
        
        List<zoopla_portal__c> zoopSettings = zoopla_portal__c.getAll().values();
        
        Map<String, String> fieldMappings = new Map<String, String>();
        Map<String, String> mapMappingTable = getAllMapping();
        
        Map<String,Object> ZooplaFieldmap = New Map<String,Object>();
        qry = 'Select ' + qry + 'id FROM pba__Listing__c where id =: listingId';
        
        List<Listing__c> listingPortal = Database.query(qry);  
        
        //collect custom metadata for branch_reference
        List<Zoopla_Stored_Values__mdt> lstZoopla_Stored_Values =  [select Id, DeveloperName, Label, value__c 
                                                                    from Zoopla_Stored_Values__mdt]; 
        
        if(lstZoopla_Stored_Values == null || lstZoopla_Stored_Values.size() <= 0){
            System.debug('lstZoopla_Stored_Values is empty');
            return null;
        }
        
        //collect custom metadata for ownership type
        List<Zoopla_Ownership_Tenure__mdt> lstZoopla_Ownership_Tenure_Values =  [select Id, DeveloperName, Label
                                                                    			from Zoopla_Ownership_Tenure__mdt]; 
        
        if(lstZoopla_Ownership_Tenure_Values == null || lstZoopla_Ownership_Tenure_Values.size() <= 0){
            System.debug('lstZoopla_Ownership_Tenure_Values is empty');
            return null;
        }
        
        Map<String, String> map_Label_TenureValues = new Map<String, String>();
        for(Zoopla_Ownership_Tenure__mdt objValues : lstZoopla_Ownership_Tenure_Values){
            map_Label_TenureValues.put(objValues.Label, objValues.DeveloperName);
        }
        
        if(map_Label_TenureValues == null || map_Label_TenureValues.size() <= 0){
            System.debug('map_Label_TenureValues is empty');
            return null;  
        }
        ///////////////////////////////////////////// Ownership type code
        Map<String, String> map_Label_StoredValue = new Map<String, String>();
        for(Zoopla_Stored_Values__mdt objValues : lstZoopla_Stored_Values){
            map_Label_StoredValue.put(objValues.Label, objValues.value__c);
        }
        
        if(map_Label_StoredValue == null || map_Label_StoredValue.size() <= 0){
            System.debug('map_Label_StoredValue is empty');
            return null;  
        }
        /////////////////////////////////////////////
        List<Zoopla_Property_Type__mdt> lstPropertyTypes =  [select Id, DeveloperName,  Label,  Zoopla_Value__c 
                                                             from Zoopla_Property_Type__mdt]; 
        
        if(lstPropertyTypes == null || lstPropertyTypes.size() <= 0){
            System.debug('lstPropertyTypes is empty');
            return null;
        } 
        
        Map<String, String> map_Label_PropValue = new Map<String, String>();
        for(Zoopla_Property_Type__mdt objTypes : lstPropertyTypes){
            map_Label_PropValue.put(objTypes.Label, objTypes.Zoopla_Value__c);
        }
        
        if(map_Label_PropValue == null || map_Label_PropValue.size() <= 0){
            System.debug('map_Label_StoredValue is empty');
            return null;  
        }
        
        List<Zoopla_Country_Code__mdt> lstZooplaCountryCodes =  [select Id, DeveloperName, Label, Country_Code__c  
                                                                 from Zoopla_Country_Code__mdt]; 
        
        Map<String, String> map_Label_CountryCode = new Map<String, String>();
        for(Zoopla_Country_Code__mdt objCode : lstZooplaCountryCodes){
            map_Label_CountryCode.put(objCode.Label, objCode.Country_Code__c);
        }
        
        if(map_Label_CountryCode == null || map_Label_CountryCode.size() <= 0){
            System.debug('map_Label_CountryCode is empty');
            return null;  
        }
        
        for(Listing__c pba : listingPortal){
            
            for (String zooplaField : mapMappingTable.keySet()) {
                
                
                String salesforceField = mapMappingTable.get(zooplaField);
                if (salesforceField != null) {
                    Object sfValue = pba.get(salesforceField); 
                    
                    
                    if (sfValue != null) {
                        ZooplaFieldmap.put(zooplaField, sfValue);
                    }
                }
            }
        }
        
        ZooplaSaleListingVariables Salepayload = new ZooplaSaleListingVariables(); 
        Salepayload.branch_reference = map_Label_StoredValue.get('branch_reference'); //1)
        Salepayload.category = map_Label_StoredValue.get('category');
        
        Salepayload.detailed_description = new List<ZooplaSaleListingVariables.Detailed_description>(); //2)
        ZooplaSaleListingVariables.Detailed_description description = new ZooplaSaleListingVariables.Detailed_description();
        description.heading = map_Label_StoredValue.get('heading');
        description.text = String.valueOf(ZooplaFieldmap.get('text')); 
        Salepayload.detailed_description.add(description);
        
        Salepayload.life_cycle_status = map_Label_StoredValue.get('life_cycle_status');//3)
        Salepayload.listing_reference = String.valueOf(ZooplaFieldmap.get('listing_reference')); //4)
        
        Salepayload.location = new ZooplaSaleListingVariables.Location(); //2)
        Salepayload.location.street_name = String.valueOf(ZooplaFieldmap.get('street_name'));
        Salepayload.location.town_or_city= String.valueOf(ZooplaFieldmap.get('town_or_city'));
        Salepayload.location.postal_code= String.valueOf(ZooplaFieldmap.get('postal_code'));
        Salepayload.location.country_code = map_Label_CountryCode.get(String.valueOf(ZooplaFieldmap.get('currency_code')));
        Salepayload.location.property_number_or_name= String.valueOf(ZooplaFieldmap.get('property_number_or_name'));
        SalePayLoad.shared_accommodation = false;
        
        // Set values for pricing
        Salepayload.pricing = new ZooplaSaleListingVariables.Pricing();
        Salepayload.pricing.currency_code = String.valueOf(ZooplaFieldmap.get('currency_code'));
        Salepayload.pricing.transaction_type = String.valueOf(ZooplaFieldmap.get('transaction_type')).toLowerCase();
        Salepayload.pricing.price = Integer.valueOf(ZooplaFieldmap.get('price'));
        
        Salepayload.local_authority = new ZooplaSaleListingVariables.Local_authority();
        Salepayload.local_authority.council_tax_band = String.valueOf(ZooplaFieldmap.get('council_tax_band'));
                
        Salepayload.tenure = new ZooplaSaleListingVariables.Tenure();
        Salepayload.tenure.type = map_Label_TenureValues.get(String.valueOf(ZooplaFieldmap.get('type')));
        
        if(Salepayload.tenure.type == 'leasehold'){
            Salepayload.tenure.years_remaining = Integer.valueOf(ZooplaFieldmap.get('years_remaining'));
        }
        
        if(map_Label_PropValue.containsKey(String.valueOf(ZooplaFieldmap.get('property_type')))){
            Salepayload.property_type = map_Label_PropValue.get(String.valueOf(ZooplaFieldmap.get('property_type'))); 
        }
        
        
        List<Zoopla_Furnished_Status__mdt> lstFurnishedMapping = [select Id, DeveloperName, Label, Zoopla_Value__c 
                                                                  from Zoopla_Furnished_Status__mdt];
        
        Map<String, String> map_Label_Furnished = new Map<String, String>();
        for(Zoopla_Furnished_Status__mdt objFurnish : lstFurnishedMapping){
            map_Label_Furnished.put(objFurnish.Label, objFurnish.Zoopla_Value__c );
        }
        
        if(map_Label_Furnished == null || map_Label_Furnished.size() <= 0){
            System.debug('map_Label_Furnished is empty');
            return null;  
        }
        
        Salepayload.furnished_state = map_Label_Furnished.get(String.valueOf(ZooplaFieldmap.get('furnished_state')));
        
        
        List<Property_Media__c> images = [ SELECT Id,Sort_on_Portal_Feed__c, os_Title__c, os_BaseUrl__c, Property__c, Tag__c	 
                                              FROM Property_Media__c 
                                              WHERE Property__c = :String.valueOf(ZooplaFieldmap.get('Property')) AND os_IsOnPortalFeed__c = TRUE
                                              order by Sort_on_Portal_Feed__c asc];
        System.debug('Property Media images >>'+images);
        
        List<Listing__c> listing = [SELECT Id,Broker_s_Listing_ID__c FROM Listing__c WHERE Id =:listingId];
        System.debug('listing >>'+listing);
        
        Salepayload.content = new List<ZooplaSaleListingVariables.Content>();
        
        
        List<Zoopla_Content_Type__mdt> lstContent_Type = [select Id, DeveloperName, Label, Zoopla_Value__c  
                                                          from Zoopla_Content_Type__mdt ];
        
        Map<String, String> map_Label_ContentType = new Map<String, String>();
        for(Zoopla_Content_Type__mdt objType : lstContent_Type){
            map_Label_ContentType.put(objType.Label, objType.Zoopla_Value__c );
        }
        
        if(map_Label_ContentType == null || map_Label_ContentType.size() <= 0){
            System.debug('map_Label_ContentType is empty');
            return null;  
        }    
        
        if(images != Null){
            for (Property_Media__c objMedia : images) {
                
                ZooplaSaleListingVariables.Content contents = new ZooplaSaleListingVariables.Content();
                contents.url = objMedia.os_BaseUrl__c ;
                if(String.isBlank(objMedia.Tag__c)){
                    contents.type = 'image'; 
                }else{
                    contents.type = map_Label_ContentType.get(objMedia.Tag__c);  
                }
                
                System.debug('COntent Type >>>>' + contents.type);
                Salepayload.Content.add(contents);
            }   
        }
        
        System.debug('feature_list Dynamic Value >>'+String.valueOf(ZooplaFieldmap.get('feature_list')));
        Salepayload.feature_list = new List<String>();
        if(ZooplaFieldmap.get('feature_list') != null){
            String featuresString = String.valueOf(ZooplaFieldmap.get('feature_list'));
            
            // Split the string by ';' to get individual features
            List<String> featuresList = featuresString.split(';');
            
            List<String> newList = new List<String>();
            
            for (Integer i = 0; i< featuresList.size(); i++) {
                newList.add(featuresList[i]);
            }
            Salepayload.feature_list = newList;
            system.debug('Salepayload.feature_list = '+Salepayload.feature_list);
        }
        
        Salepayload.bathrooms = Integer.valueOf(ZooplaFieldmap.get('bathrooms'));
        Salepayload.total_bedrooms = Integer.valueOf(ZooplaFieldmap.get('total_bedrooms'));
        
        Salepayload.display_address = String.valueOf(ZooplaFieldmap.get('display_address'));
        
        ZooplaSaleListingVariables.Internal internal = new ZooplaSaleListingVariables.Internal();
        internal.minimum = new ZooplaSaleListingVariables.Minimum();
        internal.minimum.value = Integer.valueOf(ZooplaFieldmap.get('value'));
        internal.minimum.units = String.valueOf(ZooplaFieldmap.get('units'));
        internal.maximum = new ZooplaSaleListingVariables.Maximum();
        internal.maximum.value = Integer.valueOf(ZooplaFieldmap.get('value'));
        internal.maximum.units = String.valueOf(ZooplaFieldmap.get('units'));
        
        Salepayload.areas = new ZooplaSaleListingVariables.Areas();
        Salepayload.areas.internal = internal; // Assign the Internal instance to Areas.internal
        
        System.debug('PAYLOAD>>>' + Salepayload);
        
        String serializedPayload = JSON.serialize(Salepayload);
        System.debug('Serialized payload = '+serializedPayload);
        
        if(serializedPayload.contains('"years_remaining":null,')){
            serializedPayload = serializedPayload.remove('"years_remaining":null,');
            System.debug('serializedPayload = '+serializedPayload); 
        }
        
        if(serializedPayload.contains(',"tenure":{"type":null},')){
            system.debug('contains tenure null! : '+serializedPayload);
            serializedPayload = serializedPayload.remove(',"tenure":{"type":null}');
            System.debug('serializedPayload = '+serializedPayload); 
        }
        
        return serializedPayload;
        
        
    }
    
    /*-----------------------Rent-------------------*/
    public static String createForRentListing(ID listingId) {
        
        List<zoopla_portal__c> zoopSettings = zoopla_portal__c.getAll().values();
        
        Map<String, String> fieldMappings = new Map<String, String>();
        Map<String, String> mapMappingTable = getAllMapping();
        
        Map<String,Object> ZooplaFieldmap = New Map<String,Object>();
        qry = 'Select ' + qry + 'id FROM Listing__c where id =: listingId';
        List<Listing__c> listingPortal = Database.query(qry);  
        System.debug('listingPortal'+listingPortal);
        
        //collect custom metadata for branch_reference
        List<Zoopla_Stored_Values__mdt> lstZoopla_Stored_Values =  [select Id, DeveloperName, Label, value__c 
                                                                    from Zoopla_Stored_Values__mdt]; 
        
        if(lstZoopla_Stored_Values == null || lstZoopla_Stored_Values.size() <= 0){
            System.debug('lstZoopla_Stored_Values is empty');
            return null;
        } 
        
        Map<String, String> map_Label_StoredValue = new Map<String, String>();
        for(Zoopla_Stored_Values__mdt objValues : lstZoopla_Stored_Values){
            map_Label_StoredValue.put(objValues.Label, objValues.value__c);
        }
        
        if(map_Label_StoredValue == null || map_Label_StoredValue.size() <= 0){
            System.debug('map_Label_StoredValue is empty');
            return null;  
        }
        
        List<Zoopla_Property_Type__mdt> lstPropertyTypes =  [select Id, DeveloperName,  Label,  Zoopla_Value__c 
                                                             from Zoopla_Property_Type__mdt]; 
        
        if(lstPropertyTypes == null || lstPropertyTypes.size() <= 0){
            System.debug('lstPropertyTypes is empty');
            return null;
        } 
        
        Map<String, String> map_Label_PropValue = new Map<String, String>();
        for(Zoopla_Property_Type__mdt objTypes : lstPropertyTypes){
            map_Label_PropValue.put(objTypes.Label, objTypes.Zoopla_Value__c);
        }
        
        if(map_Label_PropValue == null || map_Label_PropValue.size() <= 0){
            System.debug('map_Label_StoredValue is empty');
            return null;  
        }
        
        List<Zoopla_Country_Code__mdt> lstZooplaCountryCodes =  [select Id, DeveloperName, Label, Country_Code__c  
                                                                 from Zoopla_Country_Code__mdt]; 
        
        Map<String, String> map_Label_CountryCode = new Map<String, String>();
        for(Zoopla_Country_Code__mdt objCode : lstZooplaCountryCodes){
            map_Label_CountryCode.put(objCode.Label, objCode.Country_Code__c);
        }
        
        if(map_Label_CountryCode == null || map_Label_CountryCode.size() <= 0){
            System.debug('map_Label_CountryCode is empty');
            return null;  
        }
        
        for(Listing__c pba : listingPortal){
            
            System.debug('pba  .......' + mapMappingTable.keySet());
            System.debug('fieldMappings.keySet()  .......' + mapMappingTable.keySet());
            
            for (String zooplaField : mapMappingTable.keySet()) {
                
                
                String salesforceField = mapMappingTable.get(zooplaField);
                if (salesforceField != null) {
                    Object sfValue = pba.get(salesforceField); // Replace orderObj with your Salesforce object
                    
                    
                    if (sfValue != null) {
                        ZooplaFieldmap.put(zooplaField, sfValue);
                    }
                }
            }
        }
        
        ZooplaRentListingVariables RentPayLoad = new ZooplaRentListingVariables(); 
        RentPayLoad.branch_reference = map_Label_StoredValue.get('branch_reference'); //1)
        RentPayLoad.category = map_Label_StoredValue.get('category');
        
        RentPayLoad.shared_accommodation = false; //as per zooopla email this field should be default false
        
        RentPayLoad.detailed_description = new List<ZooplaRentListingVariables.Detailed_description>(); //2)
        ZooplaRentListingVariables.Detailed_description description = new ZooplaRentListingVariables.Detailed_description();
        description.heading = map_Label_StoredValue.get('heading'); 
        description.text = String.valueOf(ZooplaFieldmap.get('text')); //<--- uncomment
        RentPayLoad.detailed_description.add(description);
        
        RentPayLoad.life_cycle_status = map_Label_StoredValue.get('life_cycle_status');//3)
        RentPayLoad.listing_reference = String.valueOf(ZooplaFieldmap.get('listing_reference')); //4)
        
        RentPayLoad.location = new ZooplaRentListingVariables.Location(); //2)
        RentPayLoad.location.street_name = String.valueOf(ZooplaFieldmap.get('street_name'));
        RentPayLoad.location.town_or_city= String.valueOf(ZooplaFieldmap.get('town_or_city'));
        RentPayLoad.location.postal_code= String.valueOf(ZooplaFieldmap.get('postal_code'));
        RentPayLoad.location.country_code = map_Label_CountryCode.get(String.valueOf(ZooplaFieldmap.get('currency_code')));
        RentPayLoad.location.property_number_or_name= String.valueOf(ZooplaFieldmap.get('property_number_or_name'));
        
        // Set values for pricing
        RentPayLoad.pricing = new ZooplaRentListingVariables.Pricing();
        RentPayLoad.pricing.currency_code = String.valueOf(ZooplaFieldmap.get('currency_code'));
        RentPayLoad.pricing.transaction_type = String.valueOf(ZooplaFieldmap.get('transaction_type')).toLowerCase();
        RentPayLoad.pricing.price = Integer.valueOf(ZooplaFieldmap.get('price'));
        
        RentPayLoad.local_authority = new ZooplaRentListingVariables.Local_authority();
        RentPayLoad.local_authority.council_tax_band = String.valueOf(ZooplaFieldmap.get('council_tax_band'));
        
        List<Zoopla_Rent_Frequency__mdt> lstZooplaRent_Frequency =  [select id, Label, Zoopla_Value__c 
                                                                     from Zoopla_Rent_Frequency__mdt ]; 
        
        Map<String, String> map_Label_RentFreq = new Map<String, String>();
        for(Zoopla_Rent_Frequency__mdt objFreq : lstZooplaRent_Frequency){
            map_Label_RentFreq.put(objFreq.Label, objFreq.Zoopla_Value__c);
        }
        
        if(map_Label_RentFreq == null || map_Label_RentFreq.size() <= 0){
            System.debug('map_Label_RentFreq is empty');
            return null;  
        } 
        
        RentPayLoad.pricing.rent_frequency = map_Label_RentFreq.get(String.valueOf(ZooplaFieldmap.get('rent_frequency')));
        
        
        if(map_Label_PropValue.containsKey(String.valueOf(ZooplaFieldmap.get('property_type')))){
            RentPayLoad.property_type = map_Label_PropValue.get(String.valueOf(ZooplaFieldmap.get('property_type'))); //<-- put values here
        }
        
        
        List<Zoopla_Furnished_Status__mdt> lstFurnishedMapping = [select Id, DeveloperName, Label, Zoopla_Value__c 
                                                                  from Zoopla_Furnished_Status__mdt];
        
        Map<String, String> map_Label_Furnished = new Map<String, String>();
        for(Zoopla_Furnished_Status__mdt objFurnish : lstFurnishedMapping){
            map_Label_Furnished.put(objFurnish.Label, objFurnish.Zoopla_Value__c );
        }
        
        if(map_Label_Furnished == null || map_Label_Furnished.size() <= 0){
            System.debug('map_Label_Furnished is empty');
            return null;  
        }
        
        RentPayLoad.furnished_state = map_Label_Furnished.get(String.valueOf(ZooplaFieldmap.get('furnished_state')));
        
        
        List<Property_Media__c> images = [ SELECT Id,Sort_on_Portal_Feed__c, os_Title__c, os_BaseUrl__c, Property__c, Tag__c 
                                              FROM Property_Media__c 
                                              WHERE Property__c = :String.valueOf(ZooplaFieldmap.get('Property')) AND os_IsOnPortalFeed__c = TRUE 
                                              order by Sort_on_Portal_Feed__c asc];
        System.debug('Property Media images >>'+images);
        
        List<Listing__c> listing = [SELECT Id,Broker_s_Listing_ID__c FROM Listing__c WHERE Id =:listingId];
        System.debug('listing >>'+listing);
        
        RentPayLoad.content = new List<ZooplaRentListingVariables.Content>();
        
        
        List<Zoopla_Content_Type__mdt> lstContent_Type = [select Id, DeveloperName, Label, Zoopla_Value__c  
                                                          from Zoopla_Content_Type__mdt ];
        
        Map<String, String> map_Label_ContentType = new Map<String, String>();
        for(Zoopla_Content_Type__mdt objType : lstContent_Type){
            map_Label_ContentType.put(objType.Label, objType.Zoopla_Value__c );
        }
        
        if(map_Label_ContentType == null || map_Label_ContentType.size() <= 0){
            System.debug('map_Label_ContentType is empty');
            return null;  
        }    
        
        if(images != Null){
            for (Property_Media__c objMedia : images) {
                
                ZooplaRentListingVariables.Content contents = new ZooplaRentListingVariables.Content();
                contents.url = objMedia.os_BaseUrl__c ;
                if(String.isBlank(objMedia.Tag__c)){
                    contents.type = 'image'; 
                }else{
                    contents.type = map_Label_ContentType.get(objMedia.Tag__c);  
                }
                
                System.debug('COntent Type >>>>' + contents.type);
                RentPayLoad.Content.add(contents);
            }   
        }
        
        System.debug('feature_list Dynamic Value >>'+String.valueOf(ZooplaFieldmap.get('feature_list')));
        RentPayLoad.feature_list = new List<String>();
        if(ZooplaFieldmap.get('feature_list') != null){
            String featuresString = String.valueOf(ZooplaFieldmap.get('feature_list'));
            
            // Split the string by ';' to get individual features
            List<String> featuresList = featuresString.split(';');
            
            List<String> newList = new List<String>();
            
            for (Integer i = 0; i< featuresList.size(); i++) {
                newList.add(featuresList[i]);
            }
            RentPayLoad.feature_list = newList;
            system.debug('RentPayLoad.feature_list = '+RentPayLoad.feature_list);
        }
        
        RentPayLoad.bathrooms = Integer.valueOf(ZooplaFieldmap.get('bathrooms'));
        RentPayLoad.total_bedrooms = Integer.valueOf(ZooplaFieldmap.get('total_bedrooms'));
        
        RentPayLoad.display_address = String.valueOf(ZooplaFieldmap.get('display_address'));
        
        ZooplaRentListingVariables.Internal internal = new ZooplaRentListingVariables.Internal();
        internal.minimum = new ZooplaRentListingVariables.Minimum();
        internal.minimum.value = Integer.valueOf(ZooplaFieldmap.get('value'));
        internal.minimum.units = String.valueOf(ZooplaFieldmap.get('units'));
        internal.maximum = new ZooplaRentListingVariables.Maximum();
        internal.maximum.value = Integer.valueOf(ZooplaFieldmap.get('value'));
        internal.maximum.units = String.valueOf(ZooplaFieldmap.get('units'));
        
        RentPayLoad.areas = new ZooplaRentListingVariables.Areas();
        RentPayLoad.areas.internal = internal; // Assign the Internal instance to Areas.internal
        
        System.debug('PAYLOAD>>>' + RentPayLoad);
        
        String serializedPayload = JSON.serialize(RentPayLoad);
        return serializedPayload;
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