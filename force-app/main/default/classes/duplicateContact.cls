public class duplicateContact {
    
    // Method to fetch field set fields dynamically from the Contact object
    @AuraEnabled(cacheable=true)
    public static List<String> getNewContactFields() {
        // Describe the Contact object and the 'New_Contact' field set
        Schema.SObjectType contactType = Schema.getGlobalDescribe().get('Contact');
        Schema.DescribeSObjectResult describeResult = contactType.getDescribe();
        
        // Retrieve the field set 'New_Contact' for the Contact object
        Schema.FieldSet fieldSet = describeResult.fieldSets.getMap().get('New_Contact');
        
        // List to hold the field names in the field set
        List<String> fieldNames = new List<String>();
        
        // Loop through each field in the field set and add its API name to the list
        for (Schema.FieldSetMember f : fieldSet.getFields()) {
            fieldNames.add(f.getFieldPath());
        }
        
        return fieldNames;
    }

    // Method to check if a contact already exists based on email, phone, or mobile
    @AuraEnabled
    public static Contact findDuplicateContact(String email, String phone, String mobile) {
        List<Contact> contacts = [SELECT Id, Name, Email, Phone, MobilePhone 
                                  FROM Contact 
                                  WHERE (Email = :email OR Phone = :phone OR MobilePhone = :mobile)
                                  LIMIT 1];
        
        return contacts.isEmpty() ? null : contacts[0];
    }

    // Method to create a new contact dynamically by passing field values as a map
    @AuraEnabled
    public static Contact createNewContact(Map<String, Object> fieldValues) {
        Contact newContact = new Contact();
        
        for (String fieldName : fieldValues.keySet()) {
            if (newContact.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) {
                newContact.put(fieldName, fieldValues.get(fieldName));
            }
        }

        try {
            insert newContact;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating contact: ' + e.getMessage());
        }
        
        return newContact;
    }
}