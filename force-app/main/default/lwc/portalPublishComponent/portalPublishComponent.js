import { LightningElement, wire, track, api } from 'lwc';
import getPortalsByRegion from '@salesforce/apex/PortalController.getPortalsByRegion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PortalPublishComponent extends LightningElement {
    @api recordId; // Receive the Listing recordId dynamically
    @track portalData = [];
    isLoading = true;

    columns = [
        { label: 'Portal Name', fieldName: 'portalName', type: 'text' },
        { label: 'Portal Status', fieldName: 'portalStatus', type: 'text' },
        {
            label: 'Portal Action',
            type: 'button',
            fixedWidth: 150,
            typeAttributes: {
                label: { fieldName: 'buttonLabel' },
                name: 'toggleStatus',
                variant: { fieldName: 'buttonVariant' },
                class: 'custom-button',
            },
            cellAttributes: { alignment: 'middle' }
        }
    ];

    @wire(getPortalsByRegion, { recordId: "$recordId" })
    wiredPortals({ data, error }) {
        if (data) {
            this.portalData = data.map(portal => this.updateButtonAttributes(portal));
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error fetching portals', 'error');
            console.error('Error fetching portals:', error);
            this.isLoading = false;
        }
    }

    updateButtonAttributes(portal) {
        const isPublished = portal.portalStatus === 'Active';
        return {
            ...portal,
            buttonLabel: isPublished ? 'Unpublish' : 'Publish',
            buttonVariant: isPublished ? 'destructive' : 'success'
        };
    }

    handleButtonClick(event) {
        const rowId = event.detail.row.Id;
        this.portalData = this.portalData.map(portal => {
            if (portal.Id === rowId) {
                portal.portalStatus = portal.portalStatus === 'Active' ? 'Inactive' : 'Active';
                return this.updateButtonAttributes(portal);
            }
            return portal;
        });

        this.showToast('Portal status updated successfully', 'success');
    }

    showToast(message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: variant === 'success' ? 'Success' : 'Error',
                message: message,
                variant: variant,
            })
        );
    }
}