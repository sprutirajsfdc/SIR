public class InquiryRegionController {
public String selectedRegion { get; set; }
    public String selectedInquiryType { get; set; } // Added selectedListingType property
	public Boolean showEditPage { get; set; }
    
    private ApexPages.StandardController stdController;
    
    // Constructor to initialize properties with a StandardController for a specific object (optional)
    public InquiryRegionController(ApexPages.StandardController controller) {
        if (controller != null) {
            stdController = controller;
        }
        selectedRegion = '';
        selectedInquiryType = ''; 
    }
    
    public List<SelectOption> getRegionOptions() {
        List<SelectOption> regionOptions = new List<SelectOption>();
        
        // Get the field describe result for Listing_Region__c
        Schema.DescribeFieldResult fieldResult = Inquiry__c.Region__c.getDescribe();
        
        // Get the picklist values for Listing_Region__c
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add each picklist value to the dropdown options
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            regionOptions.add(new SelectOption(picklistValue.getValue(), picklistValue.getLabel()));
        }
        
        return regionOptions;
    }

    public List<SelectOption> getInquiryTypeOptions() {
        List<SelectOption> inquiryTypeOptions  = new List<SelectOption>();
        
        // Get the field describe result for Type_of_Inquiry__c
        Schema.DescribeFieldResult fieldResult = Inquiry__c.Type_of_Inquiry__c.getDescribe();
        
        // Get the picklist values for Type_of_Inquiry__c
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add each picklist value to the dropdown options
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            inquiryTypeOptions .add(new SelectOption(picklistValue.getValue(), picklistValue.getLabel()));
        }
        
        return inquiryTypeOptions ;
    }
}