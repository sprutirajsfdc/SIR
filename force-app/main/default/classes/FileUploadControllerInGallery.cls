public with sharing class FileUploadControllerInGallery {
    @AuraEnabled
    public static void uploadFile(String fileName, String base64Data, String recordId) {
        try {
            System.debug('Starting file upload process');
            System.debug('RecordId: ' + recordId);

            // Step 1: Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            insert cv;

            System.debug('ContentVersion Created: ' + cv.Id);

            // Step 2: Fetch ContentDocumentId
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            System.debug('ContentDocumentId: ' + contentDocumentId);

            // Step 3: Check if link already exists
            List<ContentDocumentLink> existingLinks = [ SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId AND ContentDocumentId = :contentDocumentId];

            if (existingLinks.isEmpty()) {
                // Step 4: Create ContentDocumentLink only if not already linked
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = recordId;
                cdl.ContentDocumentId = contentDocumentId;
                cdl.ShareType = 'V';
                insert cdl;

                System.debug('### ContentDocumentLink Created');
            } else {
                System.debug('### ContentDocumentLink already exists');
            }

            // Step 5: Fetch Listing__c record
            Listing__c listing = [ SELECT Property__c, Name FROM Listing__c WHERE Id = :recordId LIMIT 1];

            System.debug('Listing Retrieved: ' + listing);

            Id propertyId;
            if (listing.Property__c == null) {
            System.debug('### Creating New Property__c Record');

            // Step 6: Create a new Property__c record
            Property__c newProperty = new Property__c();
            newProperty.Name = 'New Property for ' + listing.Name;
            insert newProperty;
    
            propertyId = newProperty.Id;
            System.debug('New Property__c Created: ' + propertyId);

             // Step 7: Update Listing__c with new Property__c value
            listing.Property__c = propertyId;
            update listing;

            System.debug('### Listing__c Updated with New Property__c');

            } else {

             propertyId = listing.Property__c;
            }

            // Step 8: Create Property_Media__c record with SAME Property__c value
            Decimal maxSortOrder = (Decimal) [ SELECT MAX(Sort_On_Website__c) maxSortOrder FROM Property_Media__c WHERE Property__c = :propertyId][0].get('maxSortOrder');

            Integer nextSortOrder = (maxSortOrder != null) ? maxSortOrder.intValue() + 1 : 1;

            Property_Media__c media = new Property_Media__c();
            media.Property__c = propertyId; // ✅ Assigning same value here
            media.Listing__c = listing.Id;
            media.Name = listing.Name;
            media.Sort_On_Website__c = nextSortOrder;
            media.ContentDocumentId__c = contentDocumentId;

            insert media;

            System.debug('Property_Media__c Record Created: ' + media.Id);


           } catch (Exception e) {
            System.debug('Upload Error: ' + e.getMessage());
            throw new AuraHandledException('Failed to upload file: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Property_Media__c> getUploadedImages(String recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID is required.');
        }

        Id propertyId = [ SELECT Property__c FROM Listing__c WHERE Id = :recordId LIMIT 1].Property__c;

        if (propertyId == null) {
            throw new AuraHandledException('Property__c is empty on Listing__c.');
        }

        // Fetch Property_Media__c records
        return [ SELECT Id, Sort_On_Website__c, ContentDocumentId__c FROM Property_Media__c WHERE Property__c = :propertyId ORDER BY Sort_On_Website__c ASC ];
    }

    // Update file order after swap
    @AuraEnabled
    public static void updateImageOrder(List<Map<String, Object>> mediaList) {
        if (mediaList != null && !mediaList.isEmpty()) {
            List<Property_Media__c> mediaRecords = new List<Property_Media__c>();

            for (Map<String, Object> item : mediaList) {
                Property_Media__c media = new Property_Media__c();
                media.Id = (String) item.get('id');
                media.Sort_On_Website__c = ((Decimal) item.get('serialNumber')).intValue(); // ✅ Fixed conversion
                mediaRecords.add(media);
            }

            if (!mediaRecords.isEmpty()) {
                update mediaRecords;
            }
        }
    }
}