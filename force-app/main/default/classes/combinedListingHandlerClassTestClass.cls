@isTest
private class combinedListingHandlerClassTestClass {
    
    @testSetup
    static void setupTestData() {
        // Creating a Listing record for testing
        Listing__c listing = new Listing__c();
        listing.Name = 'Test Listing';
        listing.Private_Amenities__c = 'Pool;Gym;Parking';
        listing.Publish_on_On_The_Market__c = true;
        listing.Publish_on_Anywhere__c = true;
        listing.Publish_on_Zoopla_UK__c = true;
        listing.Publish_on_Lonres__c = true;
        insert listing;
    }

    @isTest
    static void testBeforeInsert() {
        Test.startTest();
        
        Listing__c newListing = new Listing__c();
        newListing.Name = 'Before Insert Listing';
        newListing.Private_Amenities__c = 'WiFi;Garden';
        
        insert newListing;
        
        Test.stopTest();
        
        // Verify that amenities were set correctly
        newListing = [SELECT Feature_1__c FROM Listing__c WHERE Id = :newListing.Id];
        System.assertEquals('WiFi', newListing.Feature_1__c);
        
    }
    
    @isTest
    static void testAfterInsert() {
        Test.startTest();
        
        Listing__c newListing = new Listing__c();
        newListing.Name = 'After Insert Listing';
        newListing.Publish_on_On_The_Market__c = true;
        newListing.Publish_on_Anywhere__c = true;
        newListing.Publish_on_Zoopla_UK__c = true;
        newListing.Publish_on_Lonres__c = true;
        
        insert newListing;
        
        Test.stopTest();
        
        // Verify that the listing was inserted correctly
        System.assertNotEquals(null, newListing.Id);
    }
    
    @isTest
    static void testBeforeUpdate() {
        Listing__c listing = [SELECT Id, Private_Amenities__c FROM Listing__c LIMIT 1];
        listing.Private_Amenities__c = 'Gym;Spa';
        
        Test.startTest();
        
        update listing;
        
        Test.stopTest();
        
        listing = [SELECT Feature_1__c FROM Listing__c WHERE Id = :listing.Id];
        System.assertEquals('Gym', listing.Feature_1__c);
  
    }
    
    @isTest
    static void testAfterUpdate() {
        Listing__c listing = [SELECT Id FROM Listing__c LIMIT 1];
        
        Test.startTest();
        
        listing.Name = 'Updated Listing Name';
        update listing;
        
        Test.stopTest();
        
        listing = [SELECT Name FROM Listing__c WHERE Id = :listing.Id];
        System.assertEquals('Updated Listing Name', listing.Name);
    }

    @isTest
    static void testAfterDelete() {
        Listing__c listing = [SELECT Id FROM Listing__c LIMIT 1];
        
        Test.startTest();
        
        delete listing;
        
        Test.stopTest();
        
        // Ensure that the listing was deleted
        Integer count = [SELECT COUNT() FROM Listing__c WHERE Id = :listing.Id];
        System.assertEquals(0, count);
    }
}