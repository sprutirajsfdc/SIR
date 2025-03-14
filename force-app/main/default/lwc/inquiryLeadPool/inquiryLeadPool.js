import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAccountWithFilters from '@salesforce/apex/InquiryController.getAccountWithFilters';
import getFilterFieldLabelAndAPI from '@salesforce/apex/InquiryController.getFilterFieldLabelAndAPI';
import getTableFieldLabelAndAPI from '@salesforce/apex/InquiryController.getTableFieldLabelAndAPI';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class InquiryLeadPool extends NavigationMixin(LightningElement) {
    @track columns = [];
    @track data = [];
    @track paginatedData = [];
    @track filterFieldsData = [];
    @track filters = {};
    @track totalRecords = 0;
    @track pageSize = 10;
    @track currentPage = 1;
    totalPages = 1;

    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];

    get disablePrevious() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    connectedCallback() {
        this.fetchMetadata();
    }

    @wire(getAccountWithFilters, { limitRecords: 100, filters: '$filters' })
    accountData({ data, error }) {
        if (data) {
            console.log('Fetched Data:', data);
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

    fetchMetadata() {
        getFilterFieldLabelAndAPI()
            .then(data => {
                let parsedData = JSON.parse(data);
                this.filterFieldsData = parsedData.map(field => ({
                    ...field,
                    isPicklist: field.type === 'PICKLIST',
                    picklistOptions: field.picklistValues
                        ? field.picklistValues.map(value => ({ label: value, value }))
                        : []
                }));
            })
            .catch(error => this.showError(error));

        getTableFieldLabelAndAPI()
            .then(data => {
                let fieldSet = JSON.parse(data);
                this.columns = fieldSet.map(field => {
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

    handleFilterChange(event) {
        const { name, value } = event.target;
        this.filters = { ...this.filters, [name]: value };
        this.refreshData();
    }

    handleReset() {
        this.filters = {};
        this.refreshData();
    }

    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.currentPage = 1;
        this.applyPagination();
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.applyPagination();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.applyPagination();
        }
    }

    applyPagination() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginatedData = this.data.slice(start, end);
    }

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

    showError(error) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error.body ? error.body.message : error.message,
            variant: 'error'
        }));
    }
}