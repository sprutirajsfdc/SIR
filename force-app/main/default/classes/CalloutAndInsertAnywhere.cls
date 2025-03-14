public class CalloutAndInsertAnywhere {
    @Future(callout=true)
    public static void executeAnywhereCallout(String listingRecordID) {
        
        if(String.isBlank(listingRecordID)){
            system.debug('listingRecordID or action is null or blank');
            return;
        }
        
        String listingRecID = listingRecordID;
        Wrapper_Anywhere objWrap = IntegrationHelper_Anywhere.publishListing(listingRecordID, 'Update');
        
        if(objWrap == null || String.isBlank(objWrap.requestBody)){
            system.debug('requestBody is null or blank');
            return;  
        }
        
        calloutToAnywhere(objWrap.methodName,objWrap.requestBody, objWrap.listingType, objWrap.providerIdentifier, listingRecID);
    }
    
    public static String getToken(){
        system.debug('from getToken method'); 
        
        //query custom metadata to fetch credentials
        Anywhere_Dash__mdt objCMetaAnywhere = [SELECT Id, DeveloperName, clientId__c, clientSecret__c, endpoint__c, scope__c  
                                               from Anywhere_Dash__mdt
                                               where DeveloperName = 'Token_Dash_Sandbox_Salesforce_Sandbox'];
        
        if(objCMetaAnywhere == null || String.isBlank(objCMetaAnywhere.clientId__c) ||
           String.isBlank(objCMetaAnywhere.clientSecret__c) || String.isBlank(objCMetaAnywhere.endpoint__c) ||
           String.isBlank(objCMetaAnywhere.scope__c)){
               system.debug('objCMetaAnywhere is null');
               return null;
           }
        
        
        String auth = EncodingUtil.base64Encode(Blob.valueOf(objCMetaAnywhere.clientId__c + ':' + objCMetaAnywhere.clientSecret__c));
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(objCMetaAnywhere.endpoint__c);
        req.setHeader('Authorization', 'Basic ' + auth);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=client_credentials&scope=' + objCMetaAnywhere.scope__c);
        
        Http http = new Http();
        
        
        HttpResponse res = http.send(req);
        
        system.debug('res body =  '+res.getBody());
        system.debug('res code =  '+res.getStatusCode());
        
        
        
        if(res.getStatusCode() == 200){
            TokenResponseAnywhere token = (TokenResponseAnywhere)JSON.deserialize(res.getBody(), TokenResponseAnywhere.class);
            system.debug('access_token = '+token.access_token);
            //create Integration Logs: Success
            //     Integration_Log__c objLog = createIntegrationLogs('POST',req.getBody(),res.getBody(),'Outbound','IntegrationHelper_Anywhere', 'Success',
            //                                                     String.valueOf(res.getStatusCode()),'');
            
            return token.access_token;
        }
        
        return null;
    }
    
    public static void calloutToAnywhere(String methodName, String requestBody, String developerName, String providerIdentifier, String listingId){
        system.debug('developer Name = '+developerName);
        if(String.isBlank(methodName) || String.isBlank(requestBody) || String.isBlank(developerName)){
            system.debug('developer Name or methodName or requestBody is blank');
            return;
        }
        system.debug('from calloutToAnywhere method');  
        try{
            //query custom metadata to fetch credentials
            Anywhere_Dash__mdt objCMetaAnywhere = [SELECT Id, DeveloperName, clientId__c, clientSecret__c, endpoint__c, scope__c, apiKey__c  
                                                   from Anywhere_Dash__mdt
                                                   where DeveloperName =:developerName];
            
            system.debug('objCMetaAnywhere = '+objCMetaAnywhere);
            
            if(objCMetaAnywhere == null || String.isBlank(objCMetaAnywhere.clientId__c) ||
               String.isBlank(objCMetaAnywhere.clientSecret__c) || String.isBlank(objCMetaAnywhere.endpoint__c) ||
               String.isBlank(objCMetaAnywhere.scope__c)){
                   system.debug('objCMetaAnywhere is null');
                   return;
               }
            
            //get token - check if token is expired or not
            Anywhere_Token_Information__c objToken;
            String token;
            
            //fetch custom object for token
            Anywhere_Token_Information__c objTokenCustomSet = [select  Id,  Name, Token__c, Generated_On__c 
                                                               from Anywhere_Token_Information__c 
                                                               order by CreatedDate desc limit 1];
            
            DateTime startDate = objTokenCustomSet.Generated_On__c;
            DateTime endDate = DateTime.now();
            
            // Calculate the difference in milliseconds
            Long differenceInMilliseconds = endDate.getTime() - startDate.getTime();
            
            // Convert milliseconds to hours
            Long differenceInHours = differenceInMilliseconds / (1000 * 60 * 60);
            
            // Output the result
            System.debug('Difference in Hours : from trigger cls: ' + differenceInHours);
            
            
            if(differenceInHours > 1 || differenceInHours == 1){
                //update token info custom setting
                objTokenCustomSet.Token__c = getToken(); //replace token by calling the endpoint and store token
                objTokenCustomSet.Generated_On__c = DateTime.now(); //replace generated on info
                objToken = objTokenCustomSet;
                token = objTokenCustomSet.Token__c;
            }else{
                token = objTokenCustomSet.Token__c;
            }
            
            if(string.isBlank(token)){
                system.debug('no token');
                return;
            }
            
            HttpRequest req = new HttpRequest();
            req.setMethod(methodName);
            
            if(methodName == 'PUT' && String.isNotBlank(providerIdentifier)){
                
                String putEndpoint = objCMetaAnywhere.endpoint__c+'/'+providerIdentifier+'?idType=providerid';
                system.debug('enpoint for PUT = '+putEndpoint);   
                req.setEndpoint(putEndpoint);   
            }else{
                //method is POST, set endpoint for POST
                req.setEndpoint(objCMetaAnywhere.endpoint__c);
            }
            // Authorization header
            //  req.setHeader('Authorization', objCMetaAnywhere.apiKey__c);
            req.setHeader('Authorization', 'Bearer ' + token);
            // apiKey
            req.setHeader('apiKey', objCMetaAnywhere.apiKey__c);
            req.setHeader('Content-Type', 'application/json');
            // x-hous-version header
            req.setHeader('x-hous-version', 'v4.0');
            //  req.setBody('grant_type=client_credentials&scope=' + objCMetaAnywhere.scope__c);
            req.setTimeout(90000); // 90 seconds
            
            // Calculate Content-Length
            Integer contentLength = Blob.valueOf(requestBody).size();
            //   req.setHeader('Content-Length', String.valueOf(contentLength));
            req.setHeader('Content-Length', '0');
            req.setBody(requestBody); //Setting req body
            
            Http http = new Http();
            HttpResponse response = http.send(req);  //2nd callout
            system.debug('response code = '+response.getStatusCode());
            system.debug('response body = '+response.getBody());
            
            Integration_Log__c objLog;
            
            if(response.getStatusCode() == 201 || response.getStatusCode() == 204){
                objLog = createIntegrationLogs('POST',req.getBody(),response.getBody(),'Outbound','CalloutAndInsertAnywhere', 'Success',
                                               String.valueOf(response.getStatusCode()),listingId,'','');  
            }else{
                objLog = createIntegrationLogs('POST',req.getBody(),response.getBody(),'Outbound','CalloutAndInsertAnywhere', 'Error',
                                               String.valueOf(response.getStatusCode()),listingId,'','');  
            }
            
            if(objLog != null){
                insert objLog;
                system.debug('objLog inserted successfully from trigger cls!');  
                
            }
            
            if(objToken != null){
                update objToken;
                system.debug('objToken updated successfully from trigger cls!');  
            }
            
        }catch(Exception e){
            
            system.debug('error from calloutToAnywhere  : '+e.getMessage()+' at line '+e.getLineNumber());
            
            String errorType = 'Internal Salesforce Error';
            String errorMsg = 'error from calloutToAnywhere  : '+e.getMessage()+' at line '+e.getLineNumber();
            Integration_Log__c objLog = createIntegrationLogs('','','','','', 'Error',
                                                              '','',errorType,errorMsg);  
            insert objLog;
        }
    }
    
    
    public static Integration_Log__c createIntegrationLogs(String sMethodName, String sReqBody, String sRespBody,
                                                           String sTypeOfIntegration,String sSource, String sStatus, String sStatusCode, String listingId,
                                                           String errorType, String errorMessage){
                                                               Integer maxSize = 32768;                                         
                                                               Integration_Log__c objLog = new Integration_Log__c();
                                                               objLog.Method__c = sMethodName;
                                                               
                                                               if(String.isNotBlank(sReqBody) && sReqBody.length() > maxSize ){
                                                                   sReqBody = sReqBody.substring(0, maxSize);
                                                               }                                         
                                                               objLog.Request_Body__c = sReqBody;
                                                               
                                                               if(String.isNotBlank(sRespBody) && sRespBody.length() > maxSize ){
                                                                   sRespBody = sRespBody.substring(0, maxSize);
                                                               }  
                                                               
                                                               objLog.Response_Body__c = sRespBody;
                                                               objLog.Source_Class__c = sSource;
                                                               objLog.Status__c = sStatus;
                                                               objLog.Status_Code__c = sStatusCode;
                                                               objLog.Type__c = sTypeOfIntegration;
                                                               if(string.isNotBlank(listingId)){
                                                                   objLog.Listing__c = listingId;
                                                               }
                                                               
                                                               if(String.isNotBlank(errorType) && String.isNotBlank(errorMessage)){
                                                                   objLog.Error_Type__c = errorType;
                                                                   objLog.Error_Message__c = errorMessage;
                                                               }
                                                               return objLog;
                                                           }
    
    
}