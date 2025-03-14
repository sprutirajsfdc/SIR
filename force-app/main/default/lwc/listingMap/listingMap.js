import { LightningElement, api, track } from 'lwc';
import fetchListing from "@salesforce/apex/ListingMapController.fetchListing";

export default class ListingMap extends LightningElement {
    @api recordId;
    @track mapMarkers;

    async connectedCallback(){
        let res=await fetchListing({listingId:this.recordId});
        this.mapMarkers = [
            {
                location: {
                    City: res.City__c,
                    Country: res.Country__c,
                    PostalCode: res.os_PostalCode_pb__c,
                    State: res.os_State_pb__c,
                    Street: res.os_Street_pb__c,
                },
            },
        ];
    }
}