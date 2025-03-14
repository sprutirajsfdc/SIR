@RestResource(urlMapping='/contactsByRegion')
global with sharing class ContactRegionAPI {
    
    @HttpGet
    global static Map<String, List<Map<String, String>>> getContactsByRegion() {
        RestRequest req = RestContext.request;
        String region = req.params.get('region');  // ✅ Correct way to get query parameter
        
        System.debug('Received Region Parameter: ' + region); // Debugging
        
        // If no region is specified, return an empty response
        if (String.isEmpty(region)) {
            return new Map<String, List<Map<String, String>>>();
        }

        Map<String, List<Map<String, String>>> regionContacts = new Map<String, List<Map<String, String>>>();

        // Fetch contacts for the given region
        List<Contact> contacts = [SELECT Id, Name, Email, Phone, MobilePhone, LeadSource, Region__c FROM Contact WHERE Region__c = :region];

        System.debug('Fetched Contacts: ' + contacts); // Debugging

        // Prepare a clean list of contacts
        List<Map<String, String>> contactList = new List<Map<String, String>>();
        
        for (Contact c : contacts) {
            Map<String, String> contactData = new Map<String, String>();
            contactData.put('Id', c.Id);
            contactData.put('Name', c.Name);
            contactData.put('Email', c.Email);
            contactData.put('Mobile', c.MobilePhone);
            contactData.put('LeadSource', c.LeadSource);
            contactData.put('Region', c.Region__c);
            
            if (c.Phone != null) {
                contactData.put('Phone', c.Phone);
            }
            
            contactList.add(contactData);
        }

        regionContacts.put(region, contactList);
        
        return regionContacts;
    }
}