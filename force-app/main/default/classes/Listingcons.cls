public class Listingcons {
 @AuraEnabled(cacheable=True)
    public static List<Listing__c> getAccountList(){
         return ListingController.getAccount();
    }
}