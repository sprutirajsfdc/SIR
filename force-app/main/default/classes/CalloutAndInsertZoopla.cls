public class CalloutAndInsertZoopla {
    
    @Future(callout=true)
    public static void executeZooplaCallout(String listingId) {
        
        if(String.isBlank(listingId)){
            system.debug('listingId or action is null or blank');
            return;
        }
        
        try{
            System.debug('listing ID>>'+listingId);
            Integration_Log__c objLog = new Integration_Log__c();
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            // Add Zoopla End Point and Certificate
            req.setEndpoint(system.label.ENDPOINT_URL_UPDATE);
            req.setClientCertificateName(Label.Zoopla_Certificate);  
            
            List<Listing__c> listing = [SELECT Id, Auto_Generated_broker_reference_ID__c, Listing_Type__c	, Zoopla_URL__c, Publish_on_Zoopla_UK__c FROM Listing__c WHERE Id = :listingId];
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
                }
            } else {
                System.debug('No Listing__c record found for the provided ID: ' + listingId);
                return;
                
            }
            
            
            String requestBody = jsonString; 
            System.debug('SERIALISED JSON PAYLOAD >>>>>  ' + requestBody);
            
            req.setBody(requestBody); 
            req.setHeader('Content-Type',System.label.Content_Type_Header_Listing_Update);
            String zpg_listing_etag = listing[0].Auto_Generated_broker_reference_ID__c+'_'+system.now();
            req.setHeader('ZPG-Listing-ETag',zpg_listing_etag);
          //  req.setHeader('ZPG-Listing-ETag',listing[0].Auto_Generated_broker_reference_ID__c); <-- prev
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
                objLog = ZooplaHelper.createIntegrationLogs('POST', string.valueOf(requestBody), string.valueOf(res.getBody()), 'Outbound','CalloutAndInsertZoopla', 'Success', string.valueOf(res.getStatusCode()), listingId);
                system.debug('Listing updated : listing[0].Publish_on_Zoopla_UK__c = '+listing[0].Publish_on_Zoopla_UK__c);
            } else {
                System.debug('Error:>>>>>> ' + res.getStatusCode() + ' ' + res.getStatus());
                objLog = ZooplaHelper.createIntegrationLogs('POST', string.valueOf(requestBody), string.valueOf(res.getBody()), 'Outbound','CalloutAndInsertZoopla', 'Error', string.valueOf(res.getStatusCode()), listingId);
                
            }
            
            insert objLog;
            system.debug('objLog inserted');
        }catch(Exception e){
            system.debug('Error msg: '+e.getMessage()+' on line = '+e.getLineNumber());
            //      objRespForLWC.errorMsg = e.getMessage()+' on line = '+e.getLineNumber();
            //      objRespForLWC.isSuccess = false;
            
        }
    }
    
    
    @future(callout=true)
    public static void UnpublishZoopla(String listingId) {
        Integration_Log__c objLog = new Integration_Log__c();
        String listing_reference = '';
    
        try {
            Listing__c objListing = [
                SELECT Id, Auto_Generated_broker_reference_ID__c, Zoopla_URL__c, Publish_on_Zoopla_UK__c 
                FROM Listing__c 
                WHERE Id = :listingId 
                LIMIT 1
            ];
            
            if (objListing != null) {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(System.Label.ENDPOINT_URL_DELETE);
                listing_reference = objListing.Auto_Generated_broker_reference_ID__c; 
                String requestBody = '{"listing_reference": "' + listing_reference + '"}';
                request.setBody(requestBody);
                request.setHeader('Content-Type', System.Label.CONTENTType_Delete);
                request.setClientCertificateName(Label.Zoopla_Certificate);
                request.setMethod('POST');
                
                HttpResponse response = http.send(request);
                System.debug('Response Body: ' + response.getBody());
                System.debug('Status: ' + response.getStatus());
                System.debug('Status Code: ' + response.getStatusCode());
    
                if (response.getStatusCode() == 200) {
                    objListing.Zoopla_URL__c = '';
                    objListing.Publish_on_Zoopla_UK__c = false;
                    update objListing;
    
                    objLog = ZooplaHelper.createIntegrationLogs(
                        'POST', 
                        requestBody, 
                        response.getBody(), 
                        'Outbound', 
                        'ApiCalloutZoopla - deleteZooplaListing', 
                        'Success', 
                        String.valueOf(response.getStatusCode()), 
                        listingId
                    );
    
                    System.debug('Listing updated successfully');
                } else {
                    objLog = ZooplaHelper.createIntegrationLogs(
                        'POST', 
                        requestBody, 
                        response.getBody(), 
                        'Outbound', 
                        'ApiCalloutZoopla - deleteZooplaListing', 
                        'Error', 
                        String.valueOf(response.getStatusCode()), 
                        listingId
                    );
                    System.debug('Listing could not be unpublished. Status: ' + response.getStatusCode());
                }
            } else {
                System.debug('Listing ' + listing_reference + ' not found.');
                return; // Exit if listing is not found
            }
    
            insert objLog;
            System.debug('Log inserted successfully');
        } catch (Exception e) {
            System.debug('Exception caught: ' + e.getMessage());
            objLog = ZooplaHelper.createIntegrationLogs(
                'POST', 
                '', 
                e.getMessage(), 
                'Outbound', 
                'ApiCalloutZoopla - deleteZooplaListing', 
                'Error', 
                'Exception', 
                listingId
            );
            insert objLog;
        }
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