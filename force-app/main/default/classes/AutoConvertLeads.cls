/**
* @File Name : AutoConvertLeads.cls
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

Public class AutoConvertLeads 
{     @InvocableMethod   
    public static void LeadAssign(List<Id> LeadIds)  
    {        
        System.debug('inside AutoConvertLeads - LeadAssign');   
        System.debug('LeadIds = '+LeadIds);      
        LeadStatus CLeadStatus= [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1];    
        List<Database.LeadConvert> MassLeadconvert = new List<Database.LeadConvert>();    
        for(id currentlead: LeadIds){                
            Database.LeadConvert Leadconvert = new Database.LeadConvert();    
            Leadconvert.setLeadId(currentlead);                               
            Leadconvert.setConvertedStatus(CLeadStatus.MasterLabel);             
            Leadconvert.setDoNotCreateOpportunity(TRUE); //Remove this line if you want to create an opportunity from Lead Conversion  
            MassLeadconvert.add(Leadconvert);    
        }                  
        if (!MassLeadconvert.isEmpty())
        {            
            List<Database.LeadConvertResult> lcr = Database.convertLead(MassLeadconvert); 
            System.debug('Leads converted = '+lcr);      
        }    
    } 
}