public class ListingPDFController {
 public Id recordId { get; set; }
    public List<Listing__c> listings { get; set; }

    public ListingPDFController(ApexPages.StandardController controller) {
        recordId = ApexPages.currentPage().getParameters().get('id'); // Fetch record ID from URL
        if (recordId != null) {
            listings = [SELECT Id, Name, os_ListingPrice_pb__c, os_State_pb__c, CreatedDate 
                        FROM Listing__c 
                        WHERE Id = :recordId 
                        LIMIT 10];  // Modify query as needed
        }
    }
}