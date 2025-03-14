global class InquiryBatchApex implements Database.Batchable<String>, Database.AllowsCallouts {

    global Iterable<String> start(Database.BatchableContext BC) {
        return new List<String>{ 'Start' };
    }

    global void execute(Database.BatchableContext BC, List<String> scope) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://api.propertyfinder.com/v1/leads');
        req.setMethod('GET');

        // Use Named Credential or dynamic token from Custom Metadata
        req.setHeader('Authorization', 'Bearer YOUR_ACCESS_TOKEN');

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> leads = (List<Object>) responseMap.get('leads');

            List<Inquiry__c> inquiries = new List<Inquiry__c>();

            for (Object l : leads) {
                Map<String, Object> lead = (Map<String, Object>) l;

                Inquiry__c inq = new Inquiry__c();
                inq.Form_Name__c = (String) lead.get('name');
                //inq.Email__c = (String) lead.get('email');
                //inq.Phone__c = (String) lead.get('phone');
                //inq.Message__c = (String) lead.get('message');

                inquiries.add(inq);
            }

            if (!inquiries.isEmpty()) {
                insert inquiries;
            }

        } else {
            System.debug('Callout failed: ' + res.getBody());
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch finished');
    }
}