public class IntegrationHelper_LonRes {
    @future(callout=true)
    public static void publishListingAsync(String listingRecordId) {
        CalloutLonResApi(listingRecordId);
    }
    Public static Response_PortalListingLWC CalloutLonResApi(string listingRecordId){
        
        LonRes__mdt objCMetaLonRes = [SELECT Id,apiKey__c, Branch_code__c, endpoint__c  
                                      from LonRes__mdt
                                      where DeveloperName = 'LonRes_Token'];
        
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        
        if(objCMetaLonRes == null || String.isBlank(objCMetaLonRes.Id) ||
           String.isBlank(objCMetaLonRes.apiKey__c) || String.isBlank(objCMetaLonRes.endpoint__c)){
               system.debug('objCMetaLonRes is null');
           }
        
        string payload = createpayload(listingRecordId, objCMetaLonRes.Branch_code__c );
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(objCMetaLonRes.endpoint__c);
        req.setHeader('APIkey', objCMetaLonRes.apiKey__c);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);
        
        system.debug('Payload Body =  '+ payload);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        system.debug('res body =  '+res.getBody());
        system.debug('res code =  '+res.getStatusCode()); 
        
        Integration_Log__c objLog;
        if (res.getStatusCode() == 202) {
            objResp.isSuccess = true;
            objResp.errorMsg = '';
            objLog = createIntegrationLogs('POST', req.getBody(), res.getBody(),
                                           'Outbound', 'CalloutAndInsertLonres', 'Success',
                                           String.valueOf(res.getStatusCode()), listingRecordId);
            
        } else {
            System.debug('Request failed: ' + res.getStatus());
            objResp.isSuccess = false;
            objResp.errorMsg = 'Request failed';
            objLog = createIntegrationLogs('POST', req.getBody(), res.getBody(),
                                           'Outbound', 'CalloutAndInsertLonres', 'Failure',
                                           String.valueOf(res.getStatusCode()), listingRecordId);
            
        }
        if(objLog != null){
            insert objLog;
            system.debug('objLog inserted successfully!');  
        }
        return objResp;
    }
    
    public static String createpayload(string listingRecordId, Decimal Branchcode){
        Listing__c objlist = [SELECT Id, Auto_Generated_broker_reference_ID__c,Furnished__c, 
                              gsir_form_a_expiry__c,Description__c,Rent_Frequency__c	,Website_Title__c,
                              os_UnitNumber__c	,Property_Type__c,City__c,UKPostal_Code__c,Address__c,
                              Ownership_Type__c,Council_Tax__c, os_ListingPrice_pb__c,Bedrooms__c,Bathrooms__c	,Listing_Category__c	
                              from Listing__c
                              where id =: listingRecordId ]; 
        
        system.debug('Check' + objlist);
        PropertyListingWrapper_LonRes propListingWrapper = new PropertyListingWrapper_LonRes();
        propListingWrapper.branch_code = Branchcode;
        propListingWrapper.id = objlist.Auto_Generated_broker_reference_ID__c; 
        
        List<Property_Media__c> lstPropMedia1 = [SELECT ThumbnailURL__c  
                                                 FROM Property_Media__c
                                                 where Tag__c  = 'Floorplan'        
                                                ]; 
        
        //Property 
        PropertyListingWrapper_LonRes.property prop = new   PropertyListingWrapper_LonRes.property();
        prop.floor_area = null ;
        prop.floor_level = objlist.os_UnitNumber__c;
        Map<String, Boolean> categoryMapping = new Map<String, Boolean>();
        for (Listing_Category_Mapping__mdt mapping : [SELECT Listing_Category__c, New_Home_Value__c FROM Listing_Category_Mapping__mdt]) {
            categoryMapping.put(mapping.Listing_Category__c, mapping.New_Home_Value__c);
        }
        
        if (objlist.Listing_Category__c != null && categoryMapping.containsKey(objlist.Listing_Category__c)) {
            prop.new_home = categoryMapping.get(objlist.Listing_Category__c);
        }
        
        prop.type = objlist.Property_Type__c.toLowerCase(); 
        
        //epc 
        PropertyListingWrapper_LonRes.epc ep = new PropertyListingWrapper_LonRes.epc();
        ep.eer = Null;
        ep.eir = Null;
        prop.epc = ep;
        propListingWrapper.property = prop;
        
        PropertyListingWrapper_LonRes.location Loc = new PropertyListingWrapper_LonRes.location();
        Loc.address_1 = objlist.Address__c; 
        Loc.address_2 = null;
        Loc.city = objlist.City__c;  
        Loc.postcode = objlist.os_PostalCode_pb__c; 
        prop.location = Loc;
        propListingWrapper.property = prop;
        
        //Room 
        PropertyListingWrapper_LonRes.rooms Rms = new PropertyListingWrapper_LonRes.rooms();
        Rms.bathrooms =  Integer.valueOf(objlist.Bathrooms__c); 
        Rms.bedrooms = objlist.Bedrooms__c; 
        Rms.reception_rooms = null; 
        prop.rooms = Rms;
        propListingWrapper.property = prop;
        
        //features 
        PropertyListingWrapper_LonRes.features fea = new PropertyListingWrapper_LonRes.features();
        Map<String, String> furnishedMapping = new Map<String, String>();
        for (Furnished_Mapping__mdt mapping : [SELECT Source_Value__c, Target_Value__c FROM Furnished_Mapping__mdt]) {
            furnishedMapping.put(mapping.Source_Value__c, mapping.Target_Value__c);
        }
        
        if (furnishedMapping.containsKey(objlist.Furnished__c)) {
            fea.furnished = furnishedMapping.get(objlist.Furnished__c);
        }
        
        prop.features = fea;
        propListingWrapper.property = prop;
        
        // tenure 
        PropertyListingWrapper_LonRes.tenure ten = new PropertyListingWrapper_LonRes.tenure();
        ten.expiry_date = objlist.gsir_form_a_expiry__c;     
        if(objlist.Ownership_Type__c != null){
            String tenturetype = objlist.Ownership_Type__c.toLowerCase(); 
            ten.type = tenturetype;  
        }
        prop.tenure = ten;
        propListingWrapper.property = prop;
        
        //details 
        PropertyListingWrapper_LonRes.details dts = new PropertyListingWrapper_LonRes.details();
        dts.description = objlist.Description__c; 
        dts.summary = objlist.Website_Title__c; 
        propListingWrapper.details = dts;
        
        PropertyListingWrapper_LonRes.status sts = new PropertyListingWrapper_LonRes.status();
        sts.final_date = null; 
        sts.hidden = false; 
        sts.status = 'available'; 
        Map<String, String> listingTypeMapping = new Map<String, String>();
        for (Listing_Type_Mapping__mdt mapping : [SELECT Listing_Type__c, Transaction_Type__c FROM Listing_Type_Mapping__mdt]) {
            listingTypeMapping.put(mapping.Listing_Type__c, mapping.Transaction_Type__c);
        }
        
        if (objlist.Listing_Type__c != null && listingTypeMapping.containsKey(objlist.Listing_Type__c)) {
            sts.transaction_type = listingTypeMapping.get(objlist.Listing_Type__c);
        }
        
        propListingWrapper.status = sts;
        PropertyListingWrapper_LonRes.pricing pr = new PropertyListingWrapper_LonRes.pricing();
        pr.asking_price = Integer.valueOf(objlist.os_ListingPrice_pb__c);     
        pr.final_price = Integer.valueOf(objlist.os_ListingPrice_pb__c); 
        pr.ground_rent = null; 
        pr.price_qualifier = null;
        
        Map<String, String> taxBandMapping = new Map<String, String>();
        for (CouncilTaxMapping__mdt mapping : [SELECT Label, API_Key__c FROM CouncilTaxMapping__mdt]) {
            taxBandMapping.put(mapping.Label, mapping.API_Key__c);
        }
        
        String councilTaxLabel = (String) objlist.get('Council_Tax__c');
        String councilTaxApiKey = taxBandMapping.get(councilTaxLabel);
        
        if (councilTaxApiKey != null) {
            pr.council_tax_band = councilTaxApiKey; 
        }  
        
        Map<String, String> rentFrequencyMapping = new Map<String, String>();
        for (Rent_Frequency_Mapping__mdt mapping : [SELECT Rent_Frequency__c, Modified_Frequency__c FROM Rent_Frequency_Mapping__mdt]) {
            rentFrequencyMapping.put(mapping.Rent_Frequency__c, mapping.Modified_Frequency__c);
        }
        
        if (objlist.Rent_Frequency__c != null && objlist.Listing_Type__c == 'Rent') {
            String originalRentFrequency = objlist.Rent_Frequency__c;
            
            if (rentFrequencyMapping.containsKey(originalRentFrequency)) {
                pr.rent_frequency = rentFrequencyMapping.get(originalRentFrequency);
            }
        }
        
        pr.service_charge = null; 
        propListingWrapper.pricing = pr;        
        
        PropertyListingWrapper_LonRes.commission cmn = new PropertyListingWrapper_LonRes.commission();
        cmn.commission = null; 
        cmn.negotiator_bonus = null; 
        propListingWrapper.commission = cmn;
        
        PropertyListingWrapper_LonRes.media md = new PropertyListingWrapper_LonRes.media();
        md.brochure = null;
        if (!lstPropMedia1.isEmpty()) {
            md.floor_plan = lstPropMedia1[0].ThumbnailURL__c	 ; 
        }
        
        md.virtual_tour = null;
        
        List<Property_Media__c> lstPropMedia = [SELECT ThumbnailURL__c	  
                                                FROM Property_Media__c
                                                where Tag__c  != 'EPC'      
                                               ]; 
        
        List<Property_Media__c> lstPropMedia2 = [SELECT ThumbnailURL__c  
                                                 FROM Property_Media__c
                                                 where Tag__c  = 'EPC'        
                                                ]; 
        
        List <String> proprtymd = new List<String>();
        for(Property_Media__c prop1 : lstPropMedia){
            If(prop1 != null){
                proprtymd.add(prop1.ThumbnailURL__c);
            }
        }
        
        md.photographs = proprtymd;
        if(lstPropMedia2 != null && !lstPropMedia2.isEmpty()){
            md.epc = lstPropMedia2[0].ThumbnailURL__c ; 
        }
        propListingWrapper.media = md;
        
        String jsonString = JSON.serialize(propListingWrapper);
        System.debug('JSON Body: ' + jsonString);
        return jsonString;
    }
    
    @future(callout=true)
    public static void unpublishListingAsync(String listingRecordId) {
        CalloutLonResApiUnpublish(listingRecordId);
    }
    Public static Response_PortalListingLWC CalloutLonResApiUnpublish(string listingRecordId){
        
        //query custom metadata to fetch credentials
        LonRes__mdt objCMetaLonRes = [SELECT Id,apiKey__c, Branch_code__c, endpoint__c  
                                      from LonRes__mdt
                                      where DeveloperName = 'LonRes_Token'];
        
        
        Response_PortalListingLWC objResp = new Response_PortalListingLWC();
        
        if(objCMetaLonRes == null || String.isBlank(objCMetaLonRes.Id) ||
           String.isBlank(objCMetaLonRes.apiKey__c) || String.isBlank(objCMetaLonRes.endpoint__c)){
               system.debug('objCMetaLonRes is null');
           }
        
        string payload = createpayloadUnpublish(listingRecordId, objCMetaLonRes.Branch_code__c );
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(objCMetaLonRes.endpoint__c);
        req.setHeader('APIkey', objCMetaLonRes.apiKey__c);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);
        
        system.debug('Payload Body =  '+ payload);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        system.debug('res body =  '+res.getBody());
        system.debug('res code =  '+res.getStatusCode()); 
        
        Integration_Log__c objLog;
        if (res.getStatusCode() == 202) {
            objResp.isSuccess = true;
            objResp.errorMsg = '';
            
            objLog = createIntegrationLogs('POST', req.getBody(), res.getBody(),
                                           'Outbound', 'CalloutAndUnplishLonres', 'Success',
                                           String.valueOf(res.getStatusCode()), listingRecordId);
            // return objResp;
        } else {
            System.debug('Request failed: ' + res.getStatus());
            objResp.isSuccess = false;
            objResp.errorMsg = 'Request failed';
            objLog = createIntegrationLogs('POST', req.getBody(), res.getBody(),
                                           'Outbound', 'CalloutAndUnplishLonres', 'Failure',
                                           String.valueOf(res.getStatusCode()), listingRecordId);
            // return objResp;
        }
        if(objLog != null){
            insert objLog;
            system.debug('objLog Unpublished successfully!');  
        }
        return objResp;
    }
    
    public static String createpayloadUnpublish(string listingRecordId, Decimal Branchcode){
        
        Listing__c objlist = [SELECT Id, Auto_Generated_broker_reference_ID__c,Furnished__c, 
                              gsir_form_a_expiry__c,Description__c,Rent_Frequency__c	,Website_Title__c,
                              os_UnitNumber__c	,Property_Type__c,City__c,UKPostal_Code__c,Address__c,
                              Ownership_Type__c,Council_Tax__c, os_ListingPrice_pb__c,Bedrooms__c,Bathrooms__c	,Listing_Category__c	
                              from Listing__c
                              where id =: listingRecordId  ]; 
        
        
        PropertyListingWrapper_LonRes propListingWrapper = new PropertyListingWrapper_LonRes();
        propListingWrapper.branch_code = Branchcode;
        propListingWrapper.id = objlist.Auto_Generated_broker_reference_ID__c; 
        
        Property_Media__c lstPropMedia1 = [SELECT ThumbnailURL__c	  
                                           FROM Property_Media__c
                                           where Tag__c  = 'Floorplan'        
                                          ]; 
        
        //Property 
        PropertyListingWrapper_LonRes.property prop = new   PropertyListingWrapper_LonRes.property();
        prop.floor_area = null ;
        prop.floor_level = objlist.os_UnitNumber__c	;
        Map<String, Boolean> categoryMapping = new Map<String, Boolean>();
        for (Listing_Category_Mapping__mdt mapping : [SELECT Listing_Category__c, New_Home_Value__c FROM Listing_Category_Mapping__mdt]) {
            categoryMapping.put(mapping.Listing_Category__c, mapping.New_Home_Value__c);
        }
        
        if (objlist.Listing_Category__c != null && categoryMapping.containsKey(objlist.Listing_Category__c)) {
            prop.new_home = categoryMapping.get(objlist.Listing_Category__c);
        }
        
        prop.type = objlist.Property_Type__c.toLowerCase(); 
        
        
        //epc 
        PropertyListingWrapper_LonRes.epc ep = new PropertyListingWrapper_LonRes.epc();
        ep.eer = Null;
        ep.eir = Null;
        prop.epc = ep;
        propListingWrapper.property = prop;
        
        PropertyListingWrapper_LonRes.location Loc = new PropertyListingWrapper_LonRes.location();
        Loc.address_1 = objlist.Address__c; 
        Loc.address_2 = null;
        Loc.city = objlist.City__c;  
        Loc.postcode = objlist.UKPostal_Code__c; 
        prop.location = Loc;
        propListingWrapper.property = prop;
        
        //Room 
        PropertyListingWrapper_LonRes.rooms Rms = new PropertyListingWrapper_LonRes.rooms();
        Rms.bathrooms =  Integer.valueOf(objlist.Bathrooms__c); 
        Rms.bedrooms = objlist.Bedrooms__c; 
        Rms.reception_rooms = null; 
        prop.rooms = Rms;
        propListingWrapper.property = prop;
        
        //features 
        PropertyListingWrapper_LonRes.features fea = new PropertyListingWrapper_LonRes.features();
        Map<String, String> furnishedMapping = new Map<String, String>();
        for (Furnished_Mapping__mdt mapping : [SELECT Source_Value__c, Target_Value__c FROM Furnished_Mapping__mdt]) {
            furnishedMapping.put(mapping.Source_Value__c, mapping.Target_Value__c);
        }
        
        if (furnishedMapping.containsKey(objlist.Furnished__c)) {
            fea.furnished = furnishedMapping.get(objlist.Furnished__c);
        }
        
        prop.features = fea;
        propListingWrapper.property = prop;
        
        // tenure 
        PropertyListingWrapper_LonRes.tenure ten = new PropertyListingWrapper_LonRes.tenure();
        ten.expiry_date = objlist.gsir_form_a_expiry__c;     
        if(objlist.Ownership_Type__c != null){
            String tenturetype = objlist.Ownership_Type__c.toLowerCase(); 
            ten.type = tenturetype;  
        }
        prop.tenure = ten;
        propListingWrapper.property = prop;
        
        //details 
        PropertyListingWrapper_LonRes.details dts = new PropertyListingWrapper_LonRes.details();
        dts.description = objlist.Description__c; 
        dts.summary = objlist.Website_Title__c; 
        propListingWrapper.details = dts;
        
        PropertyListingWrapper_LonRes.status sts = new PropertyListingWrapper_LonRes.status();
        sts.final_date = null; 
        sts.hidden = false;
        sts.status = 'withdrawn'; //Means Unpublish
        
        Map<String, String> listingTypeMapping = new Map<String, String>();
        for (Listing_Type_Mapping__mdt mapping : [SELECT Listing_Type__c, Transaction_Type__c FROM Listing_Type_Mapping__mdt]) {
            listingTypeMapping.put(mapping.Listing_Type__c, mapping.Transaction_Type__c);
        }
        
        if (objlist.Listing_Type__c != null && listingTypeMapping.containsKey(objlist.Listing_Type__c)) {
            sts.transaction_type = listingTypeMapping.get(objlist.Listing_Type__c);
        }
        
        propListingWrapper.status = sts;
        
        PropertyListingWrapper_LonRes.pricing pr = new PropertyListingWrapper_LonRes.pricing();
        pr.asking_price = Integer.valueOf(objlist.os_ListingPrice_pb__c	);     
        pr.final_price = Integer.valueOf(objlist.os_ListingPrice_pb__c	); 
        pr.ground_rent = null; 
        pr.price_qualifier = null;
        Map<String, String> taxBandMapping = new Map<String, String>();
        for (CouncilTaxMapping__mdt mapping : [SELECT Label, API_Key__c FROM CouncilTaxMapping__mdt]) {
            taxBandMapping.put(mapping.Label, mapping.API_Key__c);
        }
        
        String councilTaxLabel = (String) objlist.get('Council_Tax__c');
        String councilTaxApiKey = taxBandMapping.get(councilTaxLabel);
        
        if (councilTaxApiKey != null) {
            pr.council_tax_band = councilTaxApiKey; 
        }   
        
        Map<String, String> rentFrequencyMapping = new Map<String, String>();
        for (Rent_Frequency_Mapping__mdt mapping : [SELECT Rent_Frequency__c, Modified_Frequency__c FROM Rent_Frequency_Mapping__mdt]) {
            rentFrequencyMapping.put(mapping.Rent_Frequency__c, mapping.Modified_Frequency__c);
        }
        
        if (objlist.Rent_Frequency__c != null && objlist.Listing_Type__c == 'Rent') {
            String originalRentFrequency = objlist.Rent_Frequency__c;
            
            if (rentFrequencyMapping.containsKey(originalRentFrequency)) {
                pr.rent_frequency = rentFrequencyMapping.get(originalRentFrequency);
            }
        }
        
        pr.service_charge = null; 
        propListingWrapper.pricing = pr;     
        
        PropertyListingWrapper_LonRes.commission cmn = new PropertyListingWrapper_LonRes.commission();
        cmn.commission = null; 
        cmn.negotiator_bonus = null;
        propListingWrapper.commission = cmn;
        
        PropertyListingWrapper_LonRes.media md = new PropertyListingWrapper_LonRes.media();
        md.brochure = null; 
        if(lstPropMedia1 != null){
            md.floor_plan = lstPropMedia1.ThumbnailURL__c ;       
        }
        
        md.virtual_tour = null;
        
        List<Property_Media__c> lstPropMedia = [SELECT ThumbnailURL__c  
                                                FROM Property_Media__c
                                                where  Tag__c  != 'EPC'      
                                               ]; 
        
        List <String> proprtymd = new List<String>();
        for(Property_Media__c prop1 : lstPropMedia){
            if(prop1 != null){  
                proprtymd.add(prop1.ThumbnailURL__c);
            }
        }
        
        md.photographs = proprtymd;
        md.epc = null ;   
        propListingWrapper.media = md;
        
        String jsonString = JSON.serialize(propListingWrapper);
        System.debug('JSON Body: ' + jsonString);
        return jsonString;
    }
    
    public static Integration_Log__c createIntegrationLogs(String sMethodName, String sReqBody, String sRespBody,
                                                           String sTypeOfIntegration,String sSource, String sStatus, String sStatusCode, String listingRecordId){
                                                               Integer maxSize = 32768;                                         
                                                               Integration_Log__c objLog = new Integration_Log__c();
                                                               objLog.Method__c = sMethodName;
                                                               
                                                               if(sReqBody.length() > maxSize ){
                                                                   sReqBody = sReqBody.substring(0, maxSize);
                                                               }                                         
                                                               objLog.Request_Body__c = sReqBody;
                                                               
                                                               if(sRespBody.length() > maxSize ){
                                                                   sRespBody = sRespBody.substring(0, maxSize);
                                                               }  
                                                               
                                                               objLog.Response_Body__c = sRespBody;
                                                               objLog.Source_Class__c = sSource;
                                                               objLog.Status__c = sStatus;
                                                               objLog.Status_Code__c = sStatusCode;
                                                               objLog.Type__c = sTypeOfIntegration;
                                                               
                                                               if(String.isnotBlank(listingRecordId)){
                                                                   objLog.Listing__c = listingRecordId;
                                                               }
                                                               
                                                               return objLog;   
                                                           }
}