public class ListingSubStatusController {
    @AuraEnabled
    public static void updateListingStatus1(Map<String, Object> fields) {
        System.debug('fields = '+fields);
        try {
            Listing__c recordToUpdate = new Listing__c(
                Id = (Id)fields.get('Id'),
                Listing_Sub_Status__c = (String)fields.get('Listing_Sub_Status__c')
            );
            System.debug('recordToUpdate = '+recordToUpdate);
            update recordToUpdate;
        } catch(Exception e) {
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String getStatus(String recordId) {
        try {
            Listing__c record = [SELECT Id, Listing_Sub_Status__c FROM Listing__c WHERE Id = :recordId LIMIT 1];
            return record.Listing_Sub_Status__c;
        } catch(Exception e) {
            throw new AuraHandledException('Error fetching status: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues() {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Listing__c.Listing_Sub_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }

        return picklistValues;
    }
}