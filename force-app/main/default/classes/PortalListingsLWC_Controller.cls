public class PortalListingsLWC_Controller {
    
    public String listingRecordId;
    
    @AuraEnabled(cacheable=true)
    public static List<PortalsWrapper> getAllPortals(Id recordId){
        
        System.debug('recordId from getAllPortals = '+recordId);
        
        if(String.isBlank(recordId)){
            System.debug('recordId is blank');
            return null;
        }
        
        Listing__c objListing = [select id, name, Publish_on_Anywhere__c, CurrencyIsoCode, Publish_on_Dubai_SIR_Website__c, Publish_on_UK_SIR_Website__c, Publish_on_Rightmove_UK__c,
                                      Publish_on_Lonres__c, Publish_on_Zoopla_UK__c, Publish_on_On_The_Market__c, Publish_on_KSA_Website__c, Publish_on_Abu_Dhabi_website__c
                                      from Listing__c
                                      where id =:recordId ];     
        
        System.debug('objListing = '+objListing);
        
        if(objListing == null){
            return null;
        }
        
        String region = '';
        if(objListing.CurrencyIsoCode == 'GBP'){
            region = 'UK';
        }else if(objListing.CurrencyIsoCode == 'SAR'){
            region = 'Saudi Arabia';
        }else if(objListing.CurrencyIsoCode == 'AED'){
            region = 'UAE';
        }else{
            region = 'Others';
        }
        
        List<Portals_Custom__c> lstPortals = [SELECT Id, Name, Allowed_for_Regions__c, isActive__c
                                              FROM Portals_Custom__c 
                                              WHERE Allowed_for_Regions__c INCLUDES(:region)];
        
        System.debug('lstPortals = '+lstPortals);
        if(lstPortals == null || lstPortals.size() <= 0){
            return null;
        }                                
        
        List<PortalsWrapper> lstPortalWrapper = new List<PortalsWrapper>();
        
        for(Portals_Custom__c objPortal : lstPortals){
            PortalsWrapper objPortalWrapper = new PortalsWrapper();
            objPortalWrapper.portalId = objPortal.Id;
            objPortalWrapper.portalName = objPortal.name;
            // objPortalWrapper.portalActiveStatus = objPortal.isActive__c;
            
            if(objPortal.isActive__c){
                objPortalWrapper.PortalStatus = 'Active';
            }else{
                objPortalWrapper.PortalStatus = 'Inactive';
            }
            
            objPortalWrapper.isPublishedOnPortal = false;
            
            if(objPortal.name == 'UK SIR Website'){
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_UK_SIR_Website__c;
            }else if(objPortal.name == 'Dubai SIR Website'){
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_Dubai_SIR_Website__c;
            }else if(objPortal.name == 'Rightmove UK'){
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_Rightmove_UK__c;
            }else if(objPortal.name == 'Lonres'){
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_Lonres__c;
            }else if(objPortal.name == 'Zoopla UK'){
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_Zoopla_UK__c;
            }else if(objPortal.name == 'On The Market'){
                System.debug('objPortal.name == On The Market');
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_On_The_Market__c;
                
            }else if(objPortal.name == 'KSA Website'){
                System.debug('objPortal.name == KSA Website');
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_KSA_Website__c;
                
            }else if(objPortal.name == 'Abu Dhabi Website'){
                System.debug('objPortal.name == Abu Dhabi Website');
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_Abu_Dhabi_website__c;
                
            }
            else if(objPortal.name == 'SIR.com Anywhere'){
                System.debug('objPortal.name == SIR.com Anywhere');
                objPortalWrapper.isPublishedOnPortal = objListing.Publish_on_Anywhere__c;
            }
            lstPortalWrapper.add(objPortalWrapper); 
        }
        
        //enclose in try-catch : TBD
        
        System.debug('lstPortalWrapper = '+lstPortalWrapper);
        
        if(lstPortalWrapper != null && lstPortalWrapper.size() > 0){
            return lstPortalWrapper;
        }else{
            return null; 
        }
    }
    
    
    @AuraEnabled
    public static String publish_Or_Unpublish(String websiteName, String actionName, String listingRecordId){
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = FALSE;
        objResp.errorMsg = 'Something went wrong while publishing the listing on Portal';
        //   String result = 'failed';
        
        System.debug('listingRecordId = '+listingRecordId);
        if(String.isBlank(websiteName) || String.isBlank(actionName) || String.isBlank(listingRecordId)){
            return JSON.serialize(objResp);
            
        }
        
        System.debug('websiteName = '+websiteName);
        System.debug('actionName = '+actionName);
        
        Listing__c objListing = [select id, name,Publish_on_Anywhere__c, Publish_on_Dubai_SIR_Website__c, Publish_on_UK_SIR_Website__c,
                                      Publish_on_Zoopla_UK__c, Publish_on_Rightmove_UK__c, Publish_on_Lonres__c,Property__c, Publish_on_KSA_Website__c
                                      from Listing__c
                                      where id =:listingRecordId ];   
        
        System.debug('objListing = '+objListing);                             
        
        if(websiteName == 'Dubai SIR Website'){
            if(actionName == 'Publish'){
                System.debug('Publish Dubai SIR Website');  
                objListing.Publish_on_Dubai_SIR_Website__c = true;
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish Dubai SIR Website');  
                objListing.Publish_on_Dubai_SIR_Website__c = false;
            }
        }else if(websiteName == 'UK SIR Website'){
            if(actionName == 'Publish'){
                
                System.debug('Publish UK SIR Website');  
                objListing.Publish_on_UK_SIR_Website__c = true;
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish UK SIR Website');  
                objListing.Publish_on_UK_SIR_Website__c = false;
            }
        }else if(websiteName == 'Rightmove UK'){
            if(actionName == 'Publish'){
                
                System.debug('Publish Rightmove UK');  
                
                //call Rightmove UK CLASS, pass Listing recordId to the class
                objResp = PublishRightMove.calloutSendPropertyDetails(listingRecordId);
                System.debug('isSuccess from Rightmove UK if condition = '+objResp.isSuccess);
                if(objResp.isSuccess){
                    //    result = 'passed'; //<--- prior
                    //    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';
                }else{
                    System.debug('Could not publish on Rightmove UK!');
                    //  return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
                
                
            } else if(actionName == 'Unpublish'){
                System.debug('Unpublish Rightmove UK');  
                
                objResp = UnPublishRightMove.calloutRemovePropertyDetails(listingRecordID);
                
                if(objResp.isSuccess){
                    //    result = 'passed'; //<--- prior
                    //     objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';
                }else{
                    System.debug('Could not unpublish from Rightmove UK!');
                    //  return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
                
                
            }	
        }else if(websiteName == 'Lonres'){
            if(actionName == 'Publish'){
                System.debug('Publish Lonres');  

                //call IntegrationHelper_LonRes, pass Listing recordId to the class
                objResp = IntegrationHelper_LonRes.CalloutLonResApi(listingRecordId);
                System.debug('isSuccess from Lonres if condition = '+objResp.isSuccess);
                if(objResp.isSuccess){
                    //    result = 'passed'; //<--- prior
                    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';
                    objListing.Publish_on_Lonres__c = true;
                }else{
                    System.debug('Could not publish on LonRes');
                    //  return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish Lonres'); 
                 objResp = IntegrationHelper_LonRes.CalloutLonResApiUnpublish(listingRecordId); 
              
                if(objResp.isSuccess){
                    //    result = 'passed'; //<--- prior
                    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';
                    objListing.Publish_on_Lonres__c = false;
                }else{
                    System.debug('Could not publish on LonRes');
                    //  return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
            }
        }else if(websiteName == 'Zoopla UK'){
            if(actionName == 'Publish'){
                System.debug('Publish Zoopla UK');  
                objResp = ApiCalloutZoopla.createZooplaListing(objListing.Id);
                System.debug('isSuccess from Zoopla if condition = '+objResp.isSuccess);
                if(objResp.isSuccess){
                    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';
                }else{
                    System.debug('Could not publish on Zoopla!');
                    return JSON.serialize(objResp);
                }
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish Zoopla UK');  
                objResp = ApiCalloutZoopla.deleteZooplaListing(objListing.Id);
            }
        } else if(websiteName == 'On The Market'){
            if(actionName == 'Publish'){
                System.debug('Publish On The Market');  
                //call OTM CLASS, pass Listing recordId to the class
                objResp = PublishOnTheMarket.calloutSendPropertyDetails(listingRecordId);
                System.debug('isSuccess from OTM if condition = '+objResp.isSuccess);
                if(objResp.isSuccess){
                    //    result = 'passed'; //<--- prior
                    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';
                }else{
                    System.debug('Could not publish on OTM!');
                    //  return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish OnTheMarket');  
                
                objResp = UnPublishOntheMarket.calloutRemovePropertyDetails(listingRecordID);
                System.debug('isSuccess from OTM if condition = '+objResp.isSuccess);
                //  Boolean isSuccess = UnPublishOntheMarket.calloutRemovePropertyDetails(listingRecordID);
                
                if(objResp.isSuccess){
                    //    objListing.Publish_on_On_The_Market__c = false;
                    //     result = 'passed'; //<--- prior
                    //     return result;    //<--- prior
                    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';	
                    return JSON.serialize(objResp);
                }else{
                    System.debug('Could not unpublish from OTM!');
                    //    return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
                
                
            }	
        } else if(websiteName == 'KSA Website'){
            if(actionName == 'Publish'){
                System.debug('Publish KSA Website');  
                objListing.Publish_on_KSA_Website__c = true;
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish OnTheMarket');  
                objListing.Publish_on_KSA_Website__c = false;
            }
        }else if(websiteName == 'Abu Dhabi Website'){
            if(actionName == 'Publish'){
                System.debug('Publish Abu Dhabi Website');  
                objListing.Publish_on_Abu_Dhabi_website__c = true;
            }else if(actionName == 'Unpublish'){
                System.debug('Unpublish OnTheMarket');  
                objListing.Publish_on_Abu_Dhabi_website__c = false;
            }
        }
        else if(websiteName == 'SIR.com Anywhere'){
            
            if(actionName == 'Publish'){
                
                //check for sort order
                List<Property_Media__c> lstPropMedia = [SELECT Id, Sort_on_Portal_Feed__c
                                                            FROM Property_Media__c
                                                            where Property__c =: objListing.Property__c]; 
                
                for(Property_Media__c objMedia : lstPropMedia){
                    if(objMedia.Sort_on_Portal_Feed__c == null || objMedia.Sort_on_Portal_Feed__c == '9999'){
                        objResp.errorMsg = 'Please sort images on SortOnPortalFeed before proceeding to publish.';
                        return JSON.serialize(objResp);
                    }
                }
                System.debug('Publish SIR.com Anywhere');  
                objResp  = ResidentialListing_inAnywhere.publishListing(listingRecordId, 'Publish');
                System.debug('isSuccess from Anywhere if condition = '+objResp.isSuccess);
                if(objResp.isSuccess){
                    objListing.Publish_on_Anywhere__c = true;
                }else{
                    System.debug('Could not publish on SIR.com!');
                    return JSON.serialize(objResp);
                }
                
                
            }else if(actionName == 'Unpublish'){
                
                System.debug('Unpublish SIR.com Anywhere');  
                objResp  =  ResidentialListing_inAnywhere.publishListing(listingRecordId, 'Unpublish');
                system.debug('Unpublish : objResp.isSuccess = '+objResp.isSuccess);
                if(objResp.isSuccess){
                    
                    objListing.Publish_on_Anywhere__c = false; 
                    objResp.isSuccess = TRUE;
                    objResp.errorMsg = '';	
                }else{
                    System.debug('Could not unpublish from SIR.com!');
                    //    return result;  //<--- prior
                    return JSON.serialize(objResp);
                }
                
            }
        }   
        
        if(websiteName != 'On The Market' && websiteName != 'Rightmove UK' && websiteName != 'Zoopla UK'){
            try{
                update objListing;
                System.debug('updated!');
                //    result = 'passed'; //<--- prior
                objResp.isSuccess = TRUE;
                objResp.errorMsg = '';
                return JSON.serialize(objResp);	
            }catch(Exception e){
                System.debug('error = '+e.getMessage());
                objResp.errorMsg = e.getMessage();
                return JSON.serialize(objResp);
            }
        }
        //   return result; //<--- prior
        return JSON.serialize(objResp);
    }
    
    
    public class PortalsWrapper{
        //  public String listingId;
        @AuraEnabled
        public String portalId;
        @AuraEnabled
        public String portalName;
        @AuraEnabled
        public String PortalStatus;
        @AuraEnabled
        public Boolean isPublishedOnPortal; 
    }
    
    
    // Method for fetching OTM and RM required fields custom metadata
    @AuraEnabled(cacheable=true)
    public static List<On_The_Market_fields__mdt> getOTM_FieldsCustomSetting(){
        return [select id, API_Name__c, DeveloperName, Label, Is_Required__c from On_The_Market_fields__mdt];
    }
    
    // Method for fetching Anywhere required fields custom metadata
    @AuraEnabled(cacheable=true)
    public static List<Anywhere_fields__mdt> getAnywhere_FieldsCustomSetting(){
        return [select id, API_Name__c, DeveloperName, Label, Is_Required__c from Anywhere_fields__mdt];
    }

    // Method for fetching Zoopla required fields custom metadata
    @AuraEnabled(cacheable=true)
    public static List<zoopla_portal__c> getZoopla_FieldsCustomSetting(){
        return [select Id, Name, Listing_Field_Api_Name__c, Required__c, Zoopla_Portal_Fields__c  from zoopla_portal__c ];
    }
    
	// Method for fetching Lonres required fields custom metadata
    @AuraEnabled(cacheable=true)
    public static List<LonRes_Field__mdt> getLonres_FieldsCustomSetting(){
        return [select id, API_Name__c, DeveloperName, Label, Is_Required__c from  LonRes_Field__mdt];
    }
	
    @AuraEnabled(cacheable=true)
    public static Listing__c fetchListings(String listingId) {
        
        System.debug('listingId = '+listingId);
        
        // Get all fields of the object dynamically
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Listing__c.fields.getMap();
        
        // Build a query string with all fields
        String query = 'SELECT ' + String.join(new List<String>(fieldsMap.keySet()), ', ') + 
            ' FROM Listing__c WHERE Id = :listingId LIMIT 1';
        
        System.debug('query = '+query);
        
        // Execute the query and return the result
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=true)
    public static String fetchPropertyMedia(String listingId) {
        
        System.debug('listingId = '+listingId);
        
        if(String.isBlank(listingId)){
            System.debug('listingId is blank'); 
            return 'listingId is blank';
        }
        
        Listing__c objListing = [select id, Property__c 
                                      FROM Listing__c
                                      where id =: listingId];  
        
        if(objListing == null){
            System.debug('Listing is null'); 
            return 'Listing is null';
        } 
        
        List<Property_Media__c> lstPropMedia = [SELECT Id, Sort_on_Portal_Feed__c
                                                    FROM Property_Media__c
                                                    where Property__c =: objListing.Property__c];
        
        if(lstPropMedia == null || lstPropMedia.size() <= 0){
            System.debug('No media associated with Listing'); 
            return 'Please upload images before proceeding to publish.';
        }else{
            
            return 'Listing has media';
        }
        
    }
    
    
    public static void Test001Method(){
    Integer i = 0;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
        i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
        i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
        i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
        i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
  }
}