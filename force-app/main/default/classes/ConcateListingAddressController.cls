public class ConcateListingAddressController {
 public static void concatAddress(List<Listing__c> newRecords, Map<Id, Listing__c> oldMap)
  {
      
      List<Listing__c> ltobUpdate = new List<Listing__c>();
       
      for (Listing__c newRecord : newRecords)
      {
          
          List<String> propertyFinderRegion = new List<String>();
    			List<String> subcommunity = new List<String>();
    			List<String> community = new List<String>();
    			String propertyFinderRegioncombinedValues ='';
    			String subcommunitycombinedValues ='';
    			String communitycombinedValues ='';
          if (newRecord.Sharing_Rule__c =='United Kingdom SIR' &&  hasFieldsUpdated(newRecord, oldMap.get(newRecord.Id))) {
               
              
              
              	if (!String.isBlank(newRecord.os_Street_pb__c	)) {
            		propertyFinderRegion.add(newRecord.os_Street_pb__c	);
            		subcommunity.add(newRecord.os_Street_pb__c	);
        		}
        		if (!String.isBlank(newRecord.Street_2__c)) {
            		propertyFinderRegion.add(newRecord.Street_2__c);
            		subcommunity.add(newRecord.Street_2__c);
        		}
        		if (!String.isBlank(newRecord.Village__c)) {
            		propertyFinderRegion.add(newRecord.Village__c);
            		subcommunity.add(newRecord.Village__c);
        		}
        		if (!String.isBlank(newRecord.Area_Town__c)) {
            		propertyFinderRegion.add(newRecord.Area_Town__c);
            		community.add(newRecord.Area_Town__c);
        		}
        		if (!String.isBlank(newRecord.City_County__c)) {
            		propertyFinderRegion.add(newRecord.City_County__c);
                    if (!String.isBlank(newRecord.Area_Town__c) && newRecord.City_County__c !='London')
                    {
                        community.add(newRecord.City_County__c);
                    }
            		
        		}
        		if (!String.isBlank(newRecord.UKPostal_Code__c)) {
            		List<String> code = newRecord.UKPostal_Code__c.split(' ');
            		propertyFinderRegion.add(code[0]);
        		}
        		if (!String.isBlank(newRecord.Country__c)) {
            		propertyFinderRegion.add(newRecord.Country__c);
        		}
        
        		if (!propertyFinderRegion.isEmpty()) {
            		propertyFinderRegioncombinedValues = String.join(propertyFinderRegion, ', ');
            		System.debug('combinedValues' + propertyFinderRegioncombinedValues);
            
        		}
    			if (!subcommunity.isEmpty()) {
            		subcommunitycombinedValues = String.join(subcommunity, ', ');
            		System.debug('combinedValues' + subcommunitycombinedValues);
            
        		}
    			if (!community.isEmpty()) {
            		communitycombinedValues = String.join(community, ', ');
            		System.debug('combinedValues' + communitycombinedValues);
            
        		}
             
              	newRecord.Propertyfinder_Region__c = propertyFinderRegioncombinedValues;
        		newRecord.Sub_Community_for_Propertyfinder__c = subcommunitycombinedValues;
        		newRecord.Community_Propertyfinder__c = communitycombinedValues;
        		//newRecord.pba__State_pb__c = newRecord.County__c;
        		newRecord.City__c = newRecord.City_County__c;
              	//newRecord.pba_uaefields__City_Propertyfinder__c = newRecord.Area_Town_City__c;
        		if(!String.isBlank(newRecord.UKPostal_Code__c) )
        		{
         			List<String> code = newRecord.UKPostal_Code__c.split(' ');
         			newRecord.os_PostalCode_pb__c = code[0];   
        		}
        		else
        		{
          			newRecord.os_PostalCode_pb__c =  newRecord.UKPostal_Code__c; 
        		}
         //newRecord.addError('newRecord in if'+newRecord.pba_uaefields__Propertyfinder_Region__c +' '+ newRecord.pba_uaefields__Sub_Community_Propertyfinder__c +' '+newRecord.pba_uaefields__Community_Propertyfinder__c);
        		ltobUpdate.add(newRecord);
              
            }
      }
      		try
    		{
                
        		update ltobUpdate;
    		}
    		catch (Exception E)
    		{
        		System.debug('Exception' + E);
    		}
      
  }
    public static Boolean hasFieldsUpdated(Listing__c newRecord, Listing__c oldRecord) {
        

        // Compare each field to check for updates
        if (newRecord.Street_2__c != oldRecord.Street_2__c ||
           newRecord.os_Street_pb__c	 != oldRecord.os_Street_pb__c	 ||
           newRecord.Village__c != oldRecord.Village__c ||
           newRecord.Area_Town__c	 != oldRecord.Area_Town__c	 ||
           newRecord.City_County__c	 != oldRecord.City_County__c	 ||
           newRecord.UKPostal_Code__c != oldRecord.UKPostal_Code__c ||
           newRecord.Country__c	 != oldRecord.Country__c)
        {
            return true; // At least one field is updated
        }

        return false; // No fields have been updated
    }
}