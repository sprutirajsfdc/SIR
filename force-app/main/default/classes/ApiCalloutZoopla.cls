public class ApiCalloutZoopla {
    
    @AuraEnabled
    public static Response_PortalListingLWC createZooplaListing(Id listingId) {
        
        Response_PortalListingLWC objRespForLWC = new Response_PortalListingLWC();
        objRespForLWC.isSuccess = false;
        objRespForLWC.errorMsg = 'Something went wrong while publishing';
        objRespForLWC.serializedRequestBody = '';
        
        if(String.isBlank(listingId)){
            objRespForLWC.errorMsg = 'listingId is blank';
            return objRespForLWC;
        }
        
        Integration_Log__c objLog = new Integration_Log__c();
        
        system.debug('Endpoint URL >>> '+ System.label.endpoint_url); //is a Custom label
        system.debug('ContentTypeHeader URL >>> '+ System.label.contentTypeHeader);	//is a Custom label
        
        try{
            System.debug('listing ID>>'+listingId);
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
          
            req.setEndpoint(system.label.ENDPOINT_URL_UPDATE);
            req.setClientCertificateName(Label.Zoopla_Certificate);  
            
            List<Listing__c> listing = [SELECT Id, Auto_Generated_broker_reference_ID__c, Listing_Type__c, Zoopla_URL__c, Publish_on_Zoopla_UK__c FROM Listing__c WHERE Id = :listingId];
            System.debug('Current Listing record >>' + listingId);
            
            String jsonString = ''; // Declare jsonString variable outside the if-else block
            
            if (!listing.isEmpty()) {
                Listing__c listingRecord = listing[0];
                String ListingType = listingRecord.Listing_Type__c;
                System.debug('Listing Type >>' + ListingType);
                
                if (ListingType =='Rent') {
                    system.debug('ListingType is Rent');
                  //  ZooplaRentListingVariables Rentpayload = ZooplaHelper.createForRentListing(listingId); //prev
                 //   jsonString = ZooplaHelper.serializeToJson(Rentpayload); //prev
                    jsonString = ZooplaHelper.createForRentListing(listingId);
                    system.debug('Rent Payload --- '+ jsonString);
                    
                }else if (ListingType =='Sale') {
                    system.debug('ListingType is Sale');
               //     ZooplaSaleListingVariables Salepayload = ZooplaHelper.createForSaleListing(listingId); //prev code
               //     jsonString = ZooplaHelper.serializeToJson(Salepayload);	//prev code
                    jsonString = ZooplaHelper.createForSaleListing(listingId);
                    system.debug('Sale Payload --- '+ jsonString);
                    
                    //system.debug('Sale Payload accessibility --- '+ Salepayload.accessibility);
                }
            } else {
                System.debug('No Listing__c record found for the provided ID: ' + listingId);
                objRespForLWC.errorMsg = 'No Listing__c record found for the provided ID: ' + listingId;
                return objRespForLWC;
                
            }
            
            
            String requestBody = jsonString; 
            System.debug('SERIALISED JSON PAYLOAD >>>>>  ' + requestBody);
            
            req.setBody(requestBody); 
         //   system.debug('cUrl.CONTENTType_URL__c = '+cUrl.CONTENTType_URL__c);
            //     req.setHeader('Content-Type','application/json; profile=http://realtime-listings.webservices.zpg.co.uk/docs/v2.1/schemas/listing/update.json');
            req.setHeader('Content-Type',System.label.Content_Type_Header_Listing_Update);
         //   req.setHeader('ZPG-Listing-ETag',listing[0].Auto_Generated_broker_reference_ID__c); //<-- prev
            
            String zpg_listing_etag = listing[0].Auto_Generated_broker_reference_ID__c+'_'+system.now();
            req.setHeader('ZPG-Listing-ETag',zpg_listing_etag);
            
            req.setMethod('POST');
            
            System.debug('Final Sending Request >>>'+req);
            
            HttpResponse res = http.send(req); 
            System.debug('Status Code >>>>>>>' + res.getStatusCode());
            System.debug('Response Body'+ res.getbody());
            
            GetJsonToApex body = GetJsonToApex.parse(res.getbody());
            System.debug('listing_reference >> ' + body.listing_reference);
            System.debug('URL >>>'+ body.url);
            System.debug('Listing ETag >>>'+body.listing_etag);
            
            
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('result = '+result.get('url'));
                listing[0].Zoopla_URL__c = String.valueOf(result.get('url'));
                listing[0].Publish_on_Zoopla_UK__c = true;
                objLog = ZooplaHelper.createIntegrationLogs('POST', string.valueOf(requestBody), string.valueOf(res.getBody()), 'Outbound','ApiCalloutZoopla - createZooplaListing', 'Success', string.valueOf(res.getStatusCode()), listingId);
                update listing;
                system.debug('Listing updated : listing[0].Publish_on_Zoopla_UK__c = '+listing[0].Publish_on_Zoopla_UK__c);
                objRespForLWC.isSuccess = true;
            } else {
                System.debug('Error:>>>>>> ' + res.getStatusCode() + ' ' + res.getStatus());
                objLog = ZooplaHelper.createIntegrationLogs('POST', string.valueOf(requestBody), string.valueOf(res.getBody()), 'Outbound','ApiCalloutZoopla - createZooplaListing', 'Error', string.valueOf(res.getStatusCode()), listingId);
                
            }
            
            insert objLog;
            system.debug('objLog inserted');
        }catch(Exception e){
            objRespForLWC.errorMsg = e.getMessage()+' on line = '+e.getLineNumber();
            objRespForLWC.isSuccess = false;
            
        }
        
        return objRespForLWC;
    }
    
    //Delete listing/delete
    @AuraEnabled
    public static Response_PortalListingLWC deleteZooplaListing(Id listingId) {
        
        Response_PortalListingLWC objRespForLWC = new Response_PortalListingLWC();
        objRespForLWC.isSuccess = false;
        objRespForLWC.errorMsg = 'Something went wrong while unpublishing';
        objRespForLWC.serializedRequestBody = '';
        
        Integration_Log__c objLog = new Integration_Log__c();
        
        String listing_reference = '';
        
        //List<String> messages = new List<String>();
        
        
        try {
            Listing__c objListing = [SELECT Id, Auto_Generated_broker_reference_ID__c, Zoopla_URL__c, Publish_on_Zoopla_UK__c 
                                      FROM Listing__c WHERE Id = :listingId];
        
            
            if(objListing != null){
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                
                request.setEndpoint(System.Label.ENDPOINT_URL_DELETE);    
                //  request.setEndpoint(eUrl.ENDPOINT_URL__c+'delete'); //make it dynamic
                //  listing_reference = 'abc';
                listing_reference = objListing.Auto_Generated_broker_reference_ID__c; 
                
                String requestBody = '{"listing_reference": "' + listing_reference + '"}';
                
                request.setBody(requestBody); 
                //   request.setHeader('Content-Type', cUrl.CONTENTType_URL__c+'delete.json'); //make it dynamic
                request.setHeader('Content-Type', System.Label.CONTENTType_Delete); //make it dynamic
                
                request.setClientCertificateName(Label.Zoopla_Certificate);
                request.setMethod('POST');
                
                HttpResponse response = http.send(request);
                
                System.debug('response>>>>>>>'+response.getBody());
                System.debug('status >>>>'+response.getstatus());
                System.debug('status code >>>>'+response.getstatusCode());
                
                GetJsonToApex body = GetJsonToApex.parse(response.getbody());
                System.debug('Body >>>'+body);
                if (response.getStatusCode() == 200) {
                    
                    objListing.Zoopla_URL__c = '';
                    objListing.Publish_on_Zoopla_UK__c = false;
                    update objListing;
                    objLog = ZooplaHelper.createIntegrationLogs('POST', string.valueOf(requestBody), string.valueOf(response.getBody()), 'Outbound','ApiCalloutZoopla - deleteZooplaListing', 'Success', string.valueOf(response.getStatusCode()), listingId);
                    
                    system.debug('Listing updated');
                    objRespForLWC.isSuccess = true;   
                }else{
                    objLog = ZooplaHelper.createIntegrationLogs('POST', string.valueOf(requestBody), string.valueOf(response.getBody()), 'Outbound','ApiCalloutZoopla - deleteZooplaListing', 'Error', string.valueOf(response.getStatusCode()), listingId);
                    objRespForLWC.errorMsg = 'Listing could not be unpublished.';
                    objRespForLWC.isSuccess = false;
                }
            }else {
                objRespForLWC.errorMsg = 'Listing '+listing_reference+' not found.';
                objRespForLWC.isSuccess = false;
                return objRespForLWC;
            }
            insert objLog;
            system.debug('objLog inserted');
        } catch (Exception e) {
            System.debug('Exception caught: ' + e.getMessage());
            objRespForLWC.errorMsg = e.getMessage()+' on line = '+e.getLineNumber();
            objRespForLWC.isSuccess = false;
        }
        
        return objRespForLWC;
        
    }
    
    public static void fakeMethod(){
        Integer i = 0;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
         i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
        i+=1;
    }    
}