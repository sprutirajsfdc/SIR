public with sharing class RegionController {
    
    public String selectedRegion { get; set; }
    public String selectedListingType { get; set; } // Added selectedListingType property
	public Boolean showEditPage { get; set; }
    
    private ApexPages.StandardController stdController;
    
    // Constructor to initialize properties with a StandardController for a specific object (optional)
    public RegionController(ApexPages.StandardController controller) {
        if (controller != null) {
            stdController = controller;
        }
        selectedRegion = '';
        selectedListingType = ''; // Initialize selectedListingType
    }
    
    // Get region options for the dropdown dynamically from the Listing_Region__c field
    public List<SelectOption> getRegionOptions() {
        List<SelectOption> regionOptions = new List<SelectOption>();
        
        // Get the field describe result for Listing_Region__c
        Schema.DescribeFieldResult fieldResult = Listing__c.Listing_Region__c.getDescribe();
        
        // Get the picklist values for Listing_Region__c
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add each picklist value to the dropdown options
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            regionOptions.add(new SelectOption(picklistValue.getValue(), picklistValue.getLabel()));
        }
        
        return regionOptions;
    }

    // Get listing type options for the dropdown dynamically from the Listing_Type__c field
    public List<SelectOption> getListingTypeOptions() {
        List<SelectOption> listingTypeOptions = new List<SelectOption>();
        
        // Get the field describe result for Listing_Type__c
        Schema.DescribeFieldResult fieldResult = Listing__c.Listing_Type__c.getDescribe();
        
        // Get the picklist values for Listing_Type__c
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add each picklist value to the dropdown options
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            listingTypeOptions.add(new SelectOption(picklistValue.getValue(), picklistValue.getLabel()));
        }
        
        return listingTypeOptions;
    }
}