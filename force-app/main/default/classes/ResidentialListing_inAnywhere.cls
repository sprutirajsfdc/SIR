public class ResidentialListing_inAnywhere {
    
    public static Response_PortalListingLWC publishListing(String listingRecordID, String action){
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        objResp.isSuccess = false;
        objResp.errorMsg = 'Something went wrong while publishing or unpublishing listing.';
        
        if(String.isBlank(listingRecordID) || String.isBlank(action)){
            system.debug('listingRecordID or action is null or blank');
            objResp.errorMsg = 'listingRecordID or action is null or blank';
            return objResp;
        }
        
        String listingRecID = listingRecordID;
        String actionVar = action;
        
        Wrapper_Anywhere objWrap = IntegrationHelper_Anywhere.publishListing(listingRecordID, actionVar);
        system.debug('objWrap from Resid = '+objWrap);
        
        if(objWrap == null){
            return objResp;  
        }
        
        if(String.isnotBlank(objWrap.errorMsg)){
            objResp.errorMsg = objWrap.errorMsg; 
            return objResp;
        }
        
        system.debug('objWrap.listingType = '+objWrap.listingType);
        //call method from Helper
        objResp.isSuccess = IntegrationHelper_Anywhere.calloutToAnywhere(objWrap.methodName,objWrap.requestBody, objWrap.listingType, objWrap.providerIdentifier, listingRecID); 
        return objResp;
        
    }
    
}