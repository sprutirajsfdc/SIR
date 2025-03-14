import { LightningElement, api, wire } from 'lwc';
import updateListingStatus1 from '@salesforce/apex/ListingSubStatusController.updateListingStatus1';
import getStatus from '@salesforce/apex/ListingSubStatusController.getStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPicklistValues from '@salesforce/apex/ListingSubStatusController.getPicklistValues';

export default class ListingSubstatus extends LightningElement {
    @api recordId;
    currentvalue = '';  // This will be dynamically set
    selectedvalue = ''; // Initially empty
    picklistValues = [];

    // Fetch picklist values dynamically from Apex
    @wire(getPicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            // Map the picklist values to the format needed for the progress indicator
            this.picklistValues = data.map((value, index) => ({
                label: value,
                value: String(index + 1) // Assign sequential values for progress steps
            }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    // Path Handler to handle step clicks in progress indicator
    pathHandler(event) {
        const newStepValue = event.target.value;
        this.selectedvalue = event.target.label;  // Update the selected value based on clicked step
        this.currentvalue = newStepValue;  // Update the current value of the progress indicator to the clicked step

        this.updateStatus();  // Update status when a step is clicked
    }

    // Update the status based on user selection
    updateStatus() {
        const fields = {
            Id: this.recordId,
            Listing_Sub_Status__c: this.selectedvalue // Update the selected value
        };

        updateListingStatus1({ fields })
            .then(result => {
                console.log('Record updated successfully:', result);
                this.showToast('Success', 'Listing Sub status updated successfully', 'success');
                this.loadStatus();  // Refresh the status after update
            })
            .catch(error => {
                console.error('Error updating record:', error);
                this.showToast('Error', 'Error updating Listing Sub status', 'error');
            });
    }

    // Fetch the current status for the Listing record
    connectedCallback() {
        this.loadStatus();
    }

    // Load the current status of the record
    loadStatus() {
        getStatus({ recordId: this.recordId })
            .then(result => {
                console.log('Current Status:', result);
                this.selectedvalue = result;
                this.currentvalue = this.mapStatusToValue(result); // Dynamically set currentvalue based on status
            })
            .catch(error => {
                console.error('Error fetching status:', error);
                this.showToast('Error', 'Error fetching inquiry status', 'error');
            });
    }

    // Map the status text to its corresponding progress step value
    mapStatusToValue(status) {
        switch(status) {
            case 'New': return '1';
            case 'Contact In Progress': return '2';
            case 'Interested': return '3';
            case 'Pipeline': return '4';
            case 'Won': return '5';
            case 'Lost': return '6';
         
        }
    }

    // Utility to show toast messages for success/error
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    // Determine the CSS class for each step based on the current value
    getStepClass(stepValue) {
        if (parseInt(this.currentvalue) >= parseInt(stepValue)) {
            return 'completed';  // Class for completed steps
        } else if (parseInt(this.currentvalue) === parseInt(stepValue)) {
            return 'current';  // Class for the current step
        } else {
            return 'upcoming';  // Class for upcoming steps
        }
    }
}