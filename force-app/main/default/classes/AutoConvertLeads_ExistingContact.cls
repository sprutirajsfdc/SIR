/**
* @File Name : leadConvertInto_existingContact.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 13, 2025 |   | Initial Version
**/

public class AutoConvertLeads_ExistingContact {
   
    @InvocableMethod(label = 'Convert Lead Method for existing Contact') 
    public static void leadConvertInto_existingContact(
        List<variableInnerClass> requestList){
            system.debug('leadConvertInto_existingContact method');
            system.debug('requestList >> ' + requestList);
            
            //   List<Lead> leadCollection = requestList[0].leadsList;
            Lead leadObj = requestList[0].objLead;
            system.debug('leadObj >> ' + leadObj);
            
            //    List<Contact> contactCollection = requestList[0].contactsList;
            Contact contactObj = requestList[0].objContact;
            system.debug('contactObj >> ' + contactObj);
            
            //   String accountName = requestList[0].accountName;
            //   system.debug('accountName >> ' + accountName);
            
            if(leadObj == null || contactObj == null){
                system.debug('leadObj or contactObj is empty!');
                return;
            }
            
            LeadStatus CLeadStatus= [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1]; 
            
            // Convert Lead
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadObj.id);
            lc.setConvertedStatus(CLeadStatus.MasterLabel); 
            lc.setContactId(contactObj.id); // Associate lead with existing contact
            lc.setAccountId(contactObj.AccountId); // Associate lead with existing contact
            lc.setDoNotCreateOpportunity(TRUE);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            system.debug('lead converted! - leadConvertInto_existingContact');
       
        }
    
    
    public class variableInnerClass{
        @InvocableVariable(required=true)
        public Lead objLead; 
        
        @InvocableVariable(required=true)
        public Contact objContact;
        
    }
}