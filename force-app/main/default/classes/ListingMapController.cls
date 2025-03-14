public with sharing class ListingMapController {
    @AuraEnabled
    public static Listing__c fetchListing(Id listingId){
        try {
            Listing__c listingObj=[SELECT City__c,Country__c,os_State_pb__c,os_PostalCode_pb__c,os_Street_pb__c FROM Listing__c WHERE Id =: ListingId ];
            return listingObj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}