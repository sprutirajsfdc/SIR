public with sharing class PortalController {
    @AuraEnabled(cacheable=true)
    public static List<PortalDTO> getPortalsByRegion(String recordId) {
        try {
            // Fetch Listing's Region using recordId
            Listing__c listing = [SELECT Listing_Region__c FROM Listing__c WHERE Id = :recordId LIMIT 1];

            if (listing == null || String.isEmpty(listing.Listing_Region__c)) {
                return new List<PortalDTO>(); // Return empty if no region is found
            }

            // Convert Listing Region to match Allowed_for_Regions__c values
            String mappedRegion = mapListingRegion(listing.Listing_Region__c);

            if (String.isEmpty(mappedRegion)) {
                return new List<PortalDTO>(); // If no valid mapping, return empty list
            }

            // Fetch Portals where Allowed_for_Regions__c includes the mapped region
            List<Portals_Custom__c> portals = [
                SELECT Id, Name, isActive__c 
                FROM Portals_Custom__c 
                WHERE Allowed_for_Regions__c INCLUDES (:mappedRegion)
            ];

            // Convert to DTO for LWC
            List<PortalDTO> portalList = new List<PortalDTO>();
            for (Portals_Custom__c portal : portals) {
                portalList.add(new PortalDTO(portal.Id, portal.Name, portal.isActive__c));
            }

            return portalList;
        } catch (Exception e) {
            System.debug('Error fetching portals: ' + e.getMessage());
            return new List<PortalDTO>();
        }
    }

    // Function to map Listing Region values to Allowed_for_Regions__c values
    private static String mapListingRegion(String listingRegion) {
        Map<String, String> regionMapping = new Map<String, String>{
            'Saudi Listing' => 'Saudi Arabia',
            'UK Listing' => 'UK',
            'Dubai Listing' => 'UAE'
        };

        return regionMapping.containsKey(listingRegion) ? regionMapping.get(listingRegion) : '';
    }

    // DTO (Data Transfer Object) for LWC
    public class PortalDTO {
        @AuraEnabled public String Id;
        @AuraEnabled public String portalName;
        @AuraEnabled public String portalStatus;

        public PortalDTO(String Id, String portalName, Boolean isActive) {
            this.Id = Id;
            this.portalName = portalName;
            this.portalStatus = isActive ? 'Active' : 'Inactive';
        }
    }
}