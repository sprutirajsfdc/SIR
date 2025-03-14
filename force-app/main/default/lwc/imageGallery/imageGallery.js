import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import PROPERTY_MEDIA_OBJECT from '@salesforce/schema/Property_Media__c';
import FIELD_IMAGE from '@salesforce/schema/Property_Media__c.os_BaseUrl__c';
export default class ImageGallery extends LightningElement {
 @api recordId; // This will receive the recordId of the Listing object
    imageUrl;

    // Wire service to get the related Property Media record
    @wire(getRecord, { recordId: '$recordId', fields: [FIELD_IMAGE] })
    wiredListing({ error, data }) {
        if (data) {
            // Assuming the related Property Media is a field on the Listing object
            // and it has an Image URL or Image field.
            const propertyMedia = data.fields.Property_Media__r?.value; // This assumes there's a relationship field to Property Media
            if (propertyMedia) {
                this.imageUrl = propertyMedia.os_BaseUrl__c; // Extract image URL from Property Media object
            }
        } else if (error) {
            this.imageUrl = null; // Handle error case
        }
    }
}