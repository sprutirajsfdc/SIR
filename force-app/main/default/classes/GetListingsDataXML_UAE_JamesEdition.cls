@RestResource(urlMapping='/AllListingsUAE_JamesEdition/') //For UAE Website only

global class GetListingsDataXML_UAE_JamesEdition {
    
    @HttpGet
    global static List<pba__Listing__c> getListingsForUAE() {
        
        try {
            
            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('pba__Listing__c');
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            
            system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get('James_Edition_UAE'));
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get('James_Edition_UAE');
            
            List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
            
            if(fieldSetMemberList == null || fieldSetMemberList.size() <= 0){
             system.debug('empty field set');   
             return null;   
            }
            
            Set<String> setFields = new Set<String>();
            
            
            for(Schema.FieldSetMember obj:fieldSetMemberList){
                
                //  system.debug('getFieldPath = '+obj.getFieldPath());
                setFields.add(obj.getFieldPath());
            }
            system.debug('setFields = '+setFields);
            
            if(setFields == null || setFields.size() <= 0){
             system.debug('empty setFields');   
             return null;   
            }
            String fieldsString = String.join(new List<String>(setFields), ',');
            system.debug('fieldsString = '+fieldsString);
            
            if(String.isBlank(fieldsString)){
             system.debug('empty fieldsString');   
             return null;   
            }
            
            String query = 'SELECT ' + fieldsString + ' FROM pba__Listing__c where Publish_on_James_Edition__c = true and CurrencyIsoCode = \'AED\'';
            system.debug('query = '+query);
            List<pba__Listing__c> lstListings = Database.query(query);
            
            if(lstListings == null || lstListings.isEmpty()){
                system.debug('lstListings is empty!');
                return null; 
            }
            return lstListings;
        }catch (Exception e) {
            system.debug('error msg = '+e.getMessage()+' on line = '+e.getLineNumber());
            return null; 
        }
    }
    
    
    
}