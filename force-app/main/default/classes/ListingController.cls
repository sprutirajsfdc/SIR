public with sharing class ListingController {

    // Fetch Listing__c records based on filters and a record limit
    @AuraEnabled(Cacheable = true)
    public static List<Listing__c> getAccountWithFilters(Integer limitRecords, Map<String, String> filters) {
        try {
            Set<String> selectedFields = new Set<String>();
            selectedFields.add('Id');
            selectedFields.add('OwnerId');
            selectedFields.add('Owner.Name');

            // Include all fields from Field Set: Listing_Set
            for (Schema.FieldSetMember fieldSet : SObjectType.Listing__c.FieldSets.Listing_Set.getFields()) {
                selectedFields.add(fieldSet.getFieldPath());
            }

            // Start SOQL query
            String queryString = 'SELECT ' + String.join(new List<String>(selectedFields), ', ') + ' FROM Listing__c';

            // Add WHERE conditions based on filter values
            List<String> filterConditions = new List<String>();
            for (String fieldName : filters.keySet()) {
                String fieldValue = filters.get(fieldName);
                if (String.isNotBlank(fieldValue)) {
                    Schema.DescribeFieldResult fieldResult = Listing__c.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                    Schema.DisplayType fieldType = fieldResult.getType();

                    // Lookup or picklist: Use '='
                    if (fieldType == Schema.DisplayType.Reference || fieldType == Schema.DisplayType.Picklist) {
                        filterConditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(fieldValue) + '\'');
                    } else {
                        // Text fields: Use LIKE
                        filterConditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(fieldValue) + '%\'');
                    }
                }
            }

            // Append WHERE clause if any filters exist
            if (!filterConditions.isEmpty()) {
                queryString += ' WHERE ' + String.join(filterConditions, ' AND ');
            }

            // Add LIMIT clause if specified
            if (limitRecords != null && limitRecords > 0) {
                queryString += ' LIMIT ' + limitRecords;
            }

            System.debug('⚡ Generated SOQL: ' + queryString);
            return Database.query(queryString);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching data: ' + e.getMessage());
        }
    }

    // Get metadata (label, apiName, type, picklist values) for filters from FieldSet: Filter_Listing
    @AuraEnabled(Cacheable = true)
    public static String getFilterFieldLabelAndAPI() {
        List<Map<String, Object>> listOfFieldSet = new List<Map<String, Object>>();
        try {
            for (Schema.FieldSetMember fieldset : SObjectType.Listing__c.FieldSets.Filter_Listing.getFields()) {
                Map<String, Object> fieldMap = new Map<String, Object>();
                String fieldName = fieldset.getFieldPath();
                Schema.DescribeFieldResult fieldResult = Listing__c.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                String fieldType = fieldResult.getType().name();

                fieldMap.put('label', fieldset.getLabel());
                fieldMap.put('apiName', fieldName);
                fieldMap.put('type', fieldType);

                // Add picklist options if it's a picklist
                if (fieldResult.getType() == Schema.DisplayType.Picklist) {
                    List<String> picklistValues = new List<String>();
                    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                        picklistValues.add(entry.getValue());
                    }
                    fieldMap.put('picklistValues', picklistValues);
                }

                listOfFieldSet.add(fieldMap);
            }
        } catch (Exception e) {
            System.debug('❌ Error in getFilterFieldLabelAndAPI: ' + e.getMessage());
            throw new AuraHandledException('Error fetching filter field labels: ' + e.getMessage());
        }
        return JSON.serialize(listOfFieldSet);
    }

    // Get metadata for datatable columns from FieldSet: Listing_Set
    @AuraEnabled(Cacheable = true)
    public static String getTableFieldLabelAndAPI() {
        List<Map<String, String>> listOfFieldSet = new List<Map<String, String>>();
        try {
            for (Schema.FieldSetMember fieldset : SObjectType.Listing__c.FieldSets.Listing_Set.getFields()) {
                Map<String, String> labelAPIMap = new Map<String, String>();
                labelAPIMap.put('label', fieldset.getLabel());
                labelAPIMap.put('apiName', fieldset.getFieldPath());
                listOfFieldSet.add(labelAPIMap);
            }
        } catch (Exception e) {
            System.debug('❌ Error in getTableFieldLabelAndAPI: ' + e.getMessage());
            throw new AuraHandledException('Error fetching table field labels: ' + e.getMessage());
        }
        return JSON.serialize(listOfFieldSet);
    }
}