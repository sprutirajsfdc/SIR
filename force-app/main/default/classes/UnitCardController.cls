public class UnitCardController {
    public Listing__c property { get; set; } 
    public String logoUrl { get; set; } 
    public List<String> propertyImages { get; set; }
    public List<String> amenities { get; set; }
    public String formattedCompletionDate { get; set; }
    public String formattedPropertyAvailableFrom { get; set; }
    
    public UnitCardController() {
        amenities = new List<String>();
        propertyImages = new List<String>();

        String propertyId = ApexPages.currentPage().getParameters().get('propertyId');

        // Check if propertyId is null or empty
        if (String.isBlank(propertyId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Property ID is missing.'));
            return;
        }

        try {
            List<Listing__c> properties = [
                SELECT Auto_Generated_broker_reference_ID__c, Features__c, Completed_DateTime__c, 
                       Listing_Agent_Email__c, os_ListingAgentName__c, Listing_Agent_Phone__c,Unit_Type__c,
                       View__c,Rent_Frequency__c,Community__c,Sub_Community__c,Private_Amenities__c	,
                       Name, Listing_Type__c 
                FROM Listing__c 
                WHERE Id = :propertyId 
                LIMIT 1
            ];
            
            if (!properties.isEmpty()) {
                property = properties[0];
                
                if (property.Completed_DateTime__c != null) {
                    formattedCompletionDate = property.Completed_DateTime__c.format();
                }
                
                if (property.Private_Amenities__c	 != null) {
                    amenities = property.Private_Amenities__c	.split(';');  
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No property found for the given ID.'));
                return;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred: ' + e.getMessage()));
            return;
        }

        // Fetch Property Images
        List<ContentDocumentLink> documentLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :propertyId
        ];

        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink docLink : documentLinks) {
            contentDocumentIds.add(docLink.ContentDocumentId);
        }

        if (!contentDocumentIds.isEmpty()) {
            List<ContentDocument> contentDocuments = [
                SELECT Id, LatestPublishedVersionId 
                FROM ContentDocument 
                WHERE Id IN :contentDocumentIds
                AND FileType IN ('JPG', 'PNG','jpeg') 
                
            ];
            
            for (ContentDocument doc : contentDocuments) {
                if (doc.LatestPublishedVersionId != null) {
                    String imageUrl = '/sfc/servlet.shepherd/version/download/' + doc.LatestPublishedVersionId;
                    propertyImages.add(imageUrl);
                }
            }
        }
    }
}