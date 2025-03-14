public class CombinedListingTriggerHandler {
    
    public static void beforeInsertUpdate(List<Listing__c> newListings, Map<Id, Listing__c> oldListings) {
        for (Listing__c lstUpd : newListings) {
            // Handle Private Amenities logic
            if (lstUpd.Private_Amenities__c != null) {
                String[] tmpString = lstUpd.Private_Amenities__c.split(';');
                Integer cntr = 0;
                for (String s : tmpString) {
                    cntr++;
                    if (cntr <= 10) {
                        lstUpd.put('Feature_' + cntr + '__c', s);
                    }
                }
            }
        }

        // Concatenate Address logic for UK Address
        if (!Trigger_Setting__c.getInstance().Is_UK_Address_Trigger_Inactive__c) {
            ConcateListingAddressController.concatAddress(newListings, oldListings);
        }
    }

    public static void afterInsertUpdate(List<Listing__c> newListings, Map<Id, Listing__c> oldListings) {
        // Fetch monitored fields from metadata
        Set<String> monitoredFieldsOTM = getMetadataFields('On_The_Market_fields__mdt', 'API_Name__c');
        Set<String> monitoredFieldsAnywhere = getMetadataFields('Anywhere_fields__mdt', 'API_Name__c');
        Set<String> monitoredFieldsZoopla = getMetadataFields('zoopla_portal__c', 'Listing_Field_Api_Name__c');
        Set<String> monitoredFieldsLonRes = getMetadataFields('LonRes_Field__mdt', 'API_Name__c');

        // Initialize sets for updates
        Set<Listing__c> updatedListingsOTM = new Set<Listing__c>();
        Set<Listing__c> updatedListingsAnywhere = new Set<Listing__c>();
        Set<Listing__c> updatedListingsZoopla = new Set<Listing__c>();
        Set<Listing__c> updatedListingsLonRes = new Set<Listing__c>();

        for (Listing__c newListing : newListings) {
            Listing__c oldListing = oldListings != null ? oldListings.get(newListing.Id) : null;

            if (oldListing != null) {
                // Check updates for each portal
                checkFieldUpdates(newListing, oldListing, monitoredFieldsOTM, updatedListingsOTM);
                checkFieldUpdates(newListing, oldListing, monitoredFieldsAnywhere, updatedListingsAnywhere);
                checkFieldUpdates(newListing, oldListing, monitoredFieldsZoopla, updatedListingsZoopla);
                checkFieldUpdates(newListing, oldListing, monitoredFieldsLonRes, updatedListingsLonRes);
            }
        }

        // Execute callouts for updated records
        executeOTMCallouts(updatedListingsOTM);
        executeAnywhereCallouts(updatedListingsAnywhere);
        executeZooplaCallouts(updatedListingsZoopla);
        executeLonResCallouts(updatedListingsLonRes);
    }

    private static Set<String> getMetadataFields(String objectName, String fieldName) {
        Set<String> fields = new Set<String>();
        String query = 'SELECT ' + fieldName + ' FROM ' + objectName;
        for (SObject record : Database.query(query)) {
            fields.add((String) record.get(fieldName));
        }
        return fields;
    }

    private static void checkFieldUpdates(Listing__c newListing, Listing__c oldListing, 
                                          Set<String> monitoredFields, Set<Listing__c> updatedListings) {
        for (String fieldName : monitoredFields) {
            if (newListing.get(fieldName) != oldListing.get(fieldName)) {
                updatedListings.add(newListing);
                break;
            }
        }
    }

    private static void executeOTMCallouts(Set<Listing__c> listings) {
        for (Listing__c listing : listings) {
            if (listing.Publish_on_On_The_Market__c) {
                CalloutAndInsertOTM_and_RMove.executeOTMCallout(listing.Id);
            }
            if (listing.Publish_on_Rightmove_UK__c) {
                CalloutAndInsertOTM_and_RMove.executeRightMoveCallout(listing.Id);
            }
        }
    }

    private static void executeAnywhereCallouts(Set<Listing__c> listings) {
        for (Listing__c listing : listings) {
            if (listing.Publish_on_Anywhere__c) {
                CalloutAndInsertAnywhere.executeAnywhereCallout(listing.Id);
            }
        }
    }

    private static void executeZooplaCallouts(Set<Listing__c> listings) {
        for (Listing__c listing : listings) {
            if (listing.Publish_on_Zoopla_UK__c) {
                CalloutAndInsertZoopla.executeZooplaCallout(listing.Id);
            }
        }
    }

    private static void executeLonResCallouts(Set<Listing__c> listings) {
        for (Listing__c listing : listings) {
            if (listing.Publish_on_Lonres__c) {
                IntegrationHelper_LonRes.publishListingAsync(listing.Id);
            }
        }
    }
}