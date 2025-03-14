import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

// Apex methods
import getAccountWithFilters from '@salesforce/apex/ListingController.getAccountWithFilters';
import getFilterFieldLabelAndAPI from '@salesforce/apex/ListingController.getFilterFieldLabelAndAPI';
import getTableFieldLabelAndAPI from '@salesforce/apex/ListingController.getTableFieldLabelAndAPI';

export default class ListingManager extends NavigationMixin(LightningElement) {
    // UI-related tracked variables
    @track columns = [];
    @track data = []; // Full dataset
    @track paginatedData = []; // Data for current page
    @track filterFieldsData = []; // Metadata for dynamic filter fields
    @track filters = {}; // Stores active filters

    // Pagination variables
    @track totalRecords = 0;
    @track pageSize = 10;
    @track currentPage = 1;
    totalPages = 1;

    // Dropdown for records per page
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];

    // Pagination button disable conditions
    get disablePrevious() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    // Lifecycle hook to fetch field metadata
    connectedCallback() {
        this.fetchMetadata();
    }

    // Reactive wire to auto-refresh records when filter changes
    @wire(getAccountWithFilters, { limitRecords: 100, filters: '$filters' })
    accountData({ data, error }) {
        if (data) {
            // Add custom fields for table (OwnerName and record URL)
            this.data = data.map(record => ({
                ...record,
                OwnerName: record.Owner?.Name || '',
                recordUrl: '/' + record.Id
            }));
            this.totalRecords = this.data.length;
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            this.currentPage = 1;
            this.applyPagination();
        } else if (error) {
            this.showError(error);
        }
    }

    // Fetches metadata for filters and datatable columns
    fetchMetadata() {
        getFilterFieldLabelAndAPI()
            .then(result => {
                const parsed = JSON.parse(result);

                // Build dynamic filter fields (excluding OwnerId)
                this.filterFieldsData = parsed
                    .filter(field => field.apiName !== 'OwnerId')
                    .map(field => ({
                        ...field,
                        isPicklist: field.type === 'PICKLIST',
                        isTextInput: field.type !== 'PICKLIST',
                        picklistOptions: field.picklistValues
                            ? field.picklistValues.map(value => ({ label: value, value }))
                            : []
                    }));
            })
            .catch(error => this.showError(error));

        getTableFieldLabelAndAPI()
            .then(result => {
                const parsed = JSON.parse(result);

                // Build datatable columns
                this.columns = parsed.map(field => {
                    if (field.apiName === 'OwnerId') {
                        return {
                            label: 'Owner Name',
                            fieldName: 'OwnerName',
                            type: 'text'
                        };
                    } else if (field.apiName === 'Name') {
                        return {
                            label: field.label,
                            fieldName: 'recordUrl',
                            type: 'url',
                            typeAttributes: {
                                label: { fieldName: 'Name' },
                                target: '_self'
                            }
                        };
                    } else {
                        return {
                            label: field.label,
                            fieldName: field.apiName,
                            type: 'text'
                        };
                    }
                });
            })
            .catch(error => this.showError(error));
    }

    // Handles changes in any filter field (text/picklist/record picker)
    handleFilterChange(event) {
        const { name } = event.target;
        let selectedValue;

        // Handle record picker (e.g., OwnerId)
        if (event.detail && event.detail.recordId !== undefined) {
            selectedValue = event.detail.recordId;
        } else {
            selectedValue = event.target.value;
        }

        // Update or remove filter value
        if (!selectedValue) {
            const updatedFilters = { ...this.filters };
            delete updatedFilters[name];
            this.filters = updatedFilters;
        } else {
            this.filters = { ...this.filters, [name]: selectedValue };
        }

        this.refreshData(); // Refresh data manually after change
    }

    // Resets all filters and reloads original data
    handleReset() {
        this.filters = {};
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-record-picker'
        );
        inputs.forEach(input => input.value = null);
        this.refreshData();
    }

    // Handles change in number of records per page
    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.currentPage = 1;
        this.applyPagination();
    }

    // Pagination: Previous button
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.applyPagination();
        }
    }

    // Pagination: Next button
    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.applyPagination();
        }
    }

    // Applies pagination to data
    applyPagination() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginatedData = this.data.slice(start, end);
    }

    // Manually fetches filtered records from server
    refreshData() {
        getAccountWithFilters({ limitRecords: 100, filters: this.filters })
            .then(data => {
                this.data = data.map(record => ({
                    ...record,
                    OwnerName: record.Owner?.Name || '',
                    recordUrl: '/' + record.Id
                }));
                this.totalRecords = this.data.length;
                this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                this.currentPage = 1;
                this.applyPagination();
            })
            .catch(error => this.showError(error));
    }

    // Displays error as a toast
    showError(error) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error.body?.message || error.message,
            variant: 'error'
        }));
    }
}