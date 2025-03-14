/**
* @File Name : GetMedia_ListingsXML_UAE.cls
* @Description :This REST resource class retrieves media listings for properties that  
*                       have been published on the Dubai SIR website. The class dynamically  
*                       queries fields from the "XML_feed_Property_Media_fields" field set  
*                       and returns the media data in a structured format.
* @Author : Spcreation
* @Last Modified By :Spcreation
* @Last Modified On : March 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 12, 2025 |  Spcreation | Initial Version
**/

@RestResource(urlMapping='/AllMediaUAE/') 
global class GetMedia_ListingsXML_UAE {
    
    @HttpGet
    global static List<Property_Media__c> getMediaForUAE() {
        try {
            // query to get Listings that have been published on KSA Website
            List<Listing__c> publishedListings = [select id, Property__c 
                                                       from Listing__c
                                                       where Publish_on_Dubai_SIR_Website__c = true];
            
            if(publishedListings == null || publishedListings.size() <= 0){
                system.debug('there r no publishedListings, no media to display!');
                return null;
            }
            
            Set<String> setOfPropertyIds = new Set<String>();
            
            for(Listing__c objListing : publishedListings){
                if(String.isNotBlank(objListing.Property__c)){
                    setOfPropertyIds.add(objListing.Property__c); 
                }
                
            }
            system.debug('setOfPropertyIds = '+setOfPropertyIds);
            
            if(setOfPropertyIds == null || setOfPropertyIds.size() <= 0){
                system.debug('there r no setOfPropertyIds, no media to display!');
                return null;
            }
            
            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Property_Media__c');
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            
            system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get('XML_feed_Property_Media_fields'));
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get('XML_feed_Property_Media_fields');
            
            List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
            
            Set<String> setFields = new Set<String>();
            
            
            for(Schema.FieldSetMember obj:fieldSetMemberList){
                
                //  system.debug('getFieldPath = '+obj.getFieldPath());
                setFields.add(obj.getFieldPath());
            }
            system.debug('setFields = '+setFields);
            String fieldsString = String.join(new List<String>(setFields), ',');
            system.debug('fieldsString = '+fieldsString);
            String query = 'SELECT ' + fieldsString + ' FROM Property_Media__c where Property__c in :setOfPropertyIds and os_IsOnWebsite__c = true order by Sort_on_Website__c	 asc';
            system.debug('query = '+query);
            
            List<Property_Media__c> lstPropertyMedia = Database.query(query);
            
            if(lstPropertyMedia == null || lstPropertyMedia.isEmpty()){
                system.debug('lstPropertyMedia is empty!');
                return null; 
            }
            return lstPropertyMedia;
            
        }catch (Exception e) {
            system.debug('error msg = '+e.getMessage()+' on line = '+e.getLineNumber());
            return null; 
        }
    }
}