/**
* @File Name : InquiryController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 11, 2025 |   | Initial Version
**/

public class InquiryController {
	// Fetches Listing records with optional filters
    @AuraEnabled(Cacheable = true)
    public static List<Inquiry__c> getAccountWithFilters(Integer limitRecords, Map<String, String> filters) {
        try {
            // Use a Set to avoid duplicates
            Set<String> selectedFields = new Set<String>();
            selectedFields.add('Id');
            selectedFields.add('OwnerId');
            selectedFields.add('Owner.Name');

            // Add fields from the field set
            for (Schema.FieldSetMember fieldSet : SObjectType.Inquiry__c.FieldSets.Inquiry_Set.getFields()) {
                selectedFields.add(fieldSet.getFieldPath());
            }

            // Build the SOQL query string
            String queryString = 'SELECT ' + String.join(new List<String>(selectedFields), ', ') + ' FROM Inquiry__c';

            // Add dynamic filtering
            List<String> filterConditions = new List<String>();
            for (String fieldName : filters.keySet()) {
                String fieldValue = filters.get(fieldName);

                if (String.isNotBlank(fieldValue)) {
                    Schema.DescribeFieldResult fieldResult = Inquiry__c.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                    Schema.DisplayType fieldType = fieldResult.getType();

                    if (fieldType == Schema.DisplayType.Picklist) {
                        filterConditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(fieldValue) + '\'');
                    } else {
                        filterConditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(fieldValue) + '%\'');
                    }
                }
            }

            if (!filterConditions.isEmpty()) {
                queryString += ' WHERE ' + String.join(filterConditions, ' AND ');
            }

            if (limitRecords != null && limitRecords > 0) {
                queryString += ' LIMIT ' + limitRecords;
            }

            System.debug('⚡ Generated SOQL: ' + queryString);
            return Database.query(queryString);

        } catch (Exception e) {
            System.debug('❌ Error in getAccountWithFilters: ' + e.getMessage());
            throw new AuraHandledException('Error fetching data: ' + e.getMessage());
        }
    }

    @AuraEnabled(Cacheable = true)
    public static String getFilterFieldLabelAndAPI() {
        List<Map<String, Object>> listOfFieldSet = new List<Map<String, Object>>();
        try {
            for (Schema.FieldSetMember fieldset : SObjectType.Inquiry__c.FieldSets.Inquiry_Filter_set.getFields()) {
                Map<String, Object> fieldMap = new Map<String, Object>();
                String fieldName = fieldset.getFieldPath();

                Schema.DescribeFieldResult fieldResult = Inquiry__c.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                String fieldType = fieldResult.getType().name();

                fieldMap.put('label', fieldset.getLabel());
                fieldMap.put('apiName', fieldName);
                fieldMap.put('type', fieldType);

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

    @AuraEnabled(Cacheable = true)
    public static String getTableFieldLabelAndAPI() {
        List<Map<String, String>> listOfFieldSet = new List<Map<String, String>>();
        try {
            for (Schema.FieldSetMember fieldset : SObjectType.Inquiry__c.FieldSets.Inquiry_Set.getFields()) {
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