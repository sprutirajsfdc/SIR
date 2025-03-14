public with sharing class ImageController {
    
    @AuraEnabled(cacheable=true)
    public static List<Property_Media__c> getImagesByRecordId(Id recordId) {
        return [SELECT Id, Name, os_BaseUrl__c, Sequence_Number__c FROM Property_Media__c WHERE Id = :recordId ORDER BY Sequence_Number__c];
    }
    
    @AuraEnabled
    public static void updateImageSequence(List<Property_Media__c> images) {
        update images;
    }
}