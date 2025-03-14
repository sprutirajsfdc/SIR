import { LightningElement, track, wire } from 'lwc';
import getNewContactFields from '@salesforce/apex/duplicateContact.getNewContactFields';
import findDuplicateContact from '@salesforce/apex/duplicateContact.findDuplicateContact';
import createNewContact from '@salesforce/apex/duplicateContact.createNewContact';
import { NavigationMixin } from 'lightning/navigation';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Email', fieldName: 'Email' },
    { label: 'Mobile', fieldName: 'MobilePhone' },
    { label: 'Phone', fieldName: 'Phone' }
];

export default class ContactCreator extends NavigationMixin(LightningElement) {
     @track fields = [];
    @track contactData = {};
    @track duplicateContacts;
    columns = COLUMNS;

    // Fetch fields from the 'New_Contact' field set using wire method
    @wire(getNewContactFields)
    wiredFields({ error, data }) {
        if (data) {
            this.fields = data;
        } else if (error) {
            console.error('Error fetching field set fields: ', error);
        }
    }

    handleChange(event) {
        const field = event.target.name;
        this.contactData[field] = event.target.value;
    }

    handleSubmit() {
        // Check for duplicates first
        findDuplicateContact({ 
            email: this.contactData.Email, 
            phone: this.contactData.Phone, 
            mobile: this.contactData.MobilePhone 
        })
        .then(result => {
            if (result) {
                this.duplicateContacts = result;
            } else {
                // No duplicates found, create the contact
                createNewContact({ fieldValues: this.contactData })
                    .then(contact => {
                        this.navigateToRecord(contact.Id);
                    })
                    .catch(error => {
                        console.error('Error creating contact: ', error);
                    });
            }
        })
        .catch(error => {
            console.error('Error checking for duplicates: ', error);
        });
    }

    navigateToRecord(contactId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: contactId,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }
}