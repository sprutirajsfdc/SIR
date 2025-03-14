import { LightningElement, wire, api, track } from 'lwc';
import getAllPortals from '@salesforce/apex/PortalListingsLWC_Controller.getAllPortals';
import publish_Or_Unpublish from '@salesforce/apex/PortalListingsLWC_Controller.publish_Or_Unpublish';
import getOTM_FieldsCustomSetting from '@salesforce/apex/PortalListingsLWC_Controller.getOTM_FieldsCustomSetting';
import getAnywhere_FieldsCustomSetting from '@salesforce/apex/PortalListingsLWC_Controller.getAnywhere_FieldsCustomSetting';
import getZoopla_FieldsCustomSetting from '@salesforce/apex/PortalListingsLWC_Controller.getZoopla_FieldsCustomSetting';
import fetchListingById from '@salesforce/apex/PortalListingsLWC_Controller.fetchListings';
import fetchPropertyMedia from '@salesforce/apex/PortalListingsLWC_Controller.fetchPropertyMedia';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PortalListingsLWC extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track customMetaDataOTM = [];
    @track customMetaDataAnywhere = [];
    @track customMetaDataZooplaUK = [];
    @track listing = [];
    @track isModalOpen = false;
    @track requiredFieldsMessage = '';
    

    // WORKS: -
    columns = [
        { label: 'Portal Name', fieldName: 'portalName', type: 'text' },
        //   { label: 'Portal Status', fieldName: 'PortalStatus', type: 'text' },
        {
            label: 'Portal Status',
            fieldName: 'PortalStatus',
            type: 'text',
            cellAttributes: {
                class: {
                    fieldName: 'statusColor'
                }
            }
        },
        /*
        {
            type: "button", typeAttributes: {
                label: {
                    fieldName: 'validateStatus'
                },
                class: {
                    fieldName: 'buttonColor'
                },
                disabled: {
                    fieldName: 'buttonActive'
                },

                variant: {
                    fieldName: 'buttonColor'
                },
                onclick: (event) => this.handleButtonClick(event, event.target.dataset.portalname) // Pass portalName value as parameter
            }
        },
       */
        {
            type: "button", typeAttributes: {
                label: {
                    fieldName: 'publishStatus'
                },
                class: {
                    fieldName: 'buttonColor'
                },
                disabled: {
                    fieldName: 'buttonActive'
                },

                variant: {
                    fieldName: 'buttonColor'
                },
                onclick: (event) => this.handleButtonClick(event, event.target.dataset.portalname) // Pass portalName value as parameter
            }
        }
    ];

    @track portalsList;


    @wire(getAllPortals, { recordId: "$recordId" })
    portalsListRec({ data, error }) {
        console.log('recordId = ' + this.recordId);

        if (data) {
            let dataCopy = JSON.parse(JSON.stringify(data));

            dataCopy.forEach(currentItem => {
                currentItem.statusColor = currentItem.PortalStatus == 'Inactive' ? "slds-text-color_error" : "slds-text-color_success";
            //    currentItem.statusColor = currentItem.PortalStatus == 'Inactive' ? "slds-text-color_error slds-badge" : "slds-theme--success slds-badge";
                //     currentItem.PortalStatus = currentItem.PortalStatus == 'Inactive' ? 'test1' : 'test2'; //works
                console.log('currentItem.isPublishedOnPortal = ' + currentItem.isPublishedOnPortal);
                currentItem.publishStatus = currentItem.isPublishedOnPortal ? 'Unpublish' : 'Publish';
                //   currentItem.buttonActive = false; //comment
                currentItem.buttonActive = currentItem.PortalStatus == 'Inactive' ? true : false;   //uncomment
                currentItem.buttonColor = currentItem.isPublishedOnPortal ? "destructive" : "success";



            });

            this.portalsList = dataCopy;
            console.log('this.portalsList = ' + this.portalsList);

        } else if (error) {

            this.data = undefined;
            this.error = error;
            console.log('The error is - ' , error);
        }


    }
    

    connectedCallback() {
    this.fetchCustomMetaDataForFields();
    this.fetchListingData();
    }

    fetchCustomMetaDataForFields(){
        getOTM_FieldsCustomSetting()
        .then(data => {
            console.log('data from getOTM_FieldsCustomSetting = ',data);
                this.customMetaDataOTM = data.map(item => {
                    return {
                        apiName: item.API_Name__c,
                        record: item
                    };
                });

            })
            .catch(error => {
                console.error('Error retrieving OTM custom setting:', error);
            });

            getAnywhere_FieldsCustomSetting()
        .then(data => {
            console.log('data from getAnywhere_FieldsCustomSetting = ',data);
                this.customMetaDataAnywhere = data.map(item => {
                    return {
                        apiName: item.API_Name__c,
                        record: item
                    };
                });

                

            })
            .catch(error => {
                console.error('Error retrieving Anywhere custom setting:', error);
            });

             getZoopla_FieldsCustomSetting()
        .then(data => {
            console.log('data from getZoopla_FieldsCustomSetting = ',data);
                this.customMetaDataZooplaUK = data.map(item => {
                    return {
                        apiName: item.Listing_Field_Api_Name__c,
                        record: item
                    };
                });

                

            })
            .catch(error => {
                console.error('Error retrieving Anywhere custom setting:', error);
            });
    }

    checkMediaForListing(){
        return new Promise((resolve, reject) => {
          fetchPropertyMedia({ listingId: this.recordId })
            .then(result => {
                console.log('result from fetchPropertyMedia = ',result);
            /*    if(result == 'No media associated with Listing'){
                    
                    this.requiredFieldsMessage = 'Please upload images before proceeding to publish.';
                    this.isModalOpen = true;
                  //  return 'error';
                    resolve('error');
                }else */
                
                if(result != 'Listing has media'){
                    console.log('inside else if, result = '+result);
                    this.requiredFieldsMessage = result;  
                    this.isModalOpen = true;
                  //  return 'error';  
                  resolve('error');
                }
              //  return 'success';  
              resolve('success');
            })
            .catch(error => {
                console.error('Error fetching media:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error fetching media data',
                        variant: 'error'
                    })
                );
              //  return 'error'; 
              reject(error);
            });
            });
            
    }

  async  handleRowAction(event) {
      
        //loader
        this.isLoading = true;
        console.log('spinner : on');
        // contains properties of the clicked row
        console.log('in handleRowAction, btn clicked!');
        const row = event.detail.row;

        //1. fetch Portal Name, publishStatus
        console.log('row name = ' + row.portalName);
        let portalName = row.portalName;
        let publishStatus = row.publishStatus;
        console.log('row publishStatus: ', row.publishStatus);

       if(publishStatus == 'Publish'){ // if status is 'Publish' look for required fields and image data  

       if(portalName == 'On The Market' || portalName == 'Rightmove UK' || portalName == 'SIR.com Anywhere' ||
          portalName == 'Zoopla UK'){
       let returnedResult = this.checkForRequiredFields(portalName, publishStatus);

        if(returnedResult == null || returnedResult == undefined){
            return;
        }

        if(returnedResult == 'error'){
            console.log('Req fields r missing');
            this.isLoading = false;
            return;
        }
       }



      try {  
          console.log('before call to checkMediaForListing method');
      let resultFromMedia = await this.checkMediaForListing();
      console.log('this.checkMediaForListing() = '+this.checkMediaForListing());
      console.log('resultForMedia back again = '+resultFromMedia);
      if(resultFromMedia == 'error'){
          this.isLoading = false;
          return;
      }
      } catch (error) {
        console.error('Error occurred in catch:', error);
        this.isLoading = false;
        this.showToast('Error','Something went wrong while publishing or unpublishing listing.','error'); 
        return;
        // Handle error if needed
    }

  }

        console.log('before publish_Or_Unpublish!');
        //2. send it to Apex method

        publish_Or_Unpublish({
            websiteName: portalName,
            actionName: publishStatus,
            listingRecordId: this.recordId
        })
            .then(result => {
                console.log('result = ' +result);

                let objResp = JSON.parse(result);
                console.log('objResp = ' ,objResp);
                console.log('objResp.isSuccess = ' ,objResp.isSuccess);
             //   if(result == 'failed'){
                if(!objResp.isSuccess){
                  this.showToast('Error',objResp.errorMsg,'error');      
                 // this.showToast('Error','Something went wrong while publishing the listing on Portal','error'); 
                  this.isLoading = false;
                  return;
                }

                this.isLoading = false;
                console.log('spinner : off');

                this.showToast('Listing ' + publishStatus + 'ed','Listing ' + publishStatus + 'ed successfully!','success'); 
                /*
                const event = new ShowToastEvent({
                    title: 'Listing ' + publishStatus + 'ed',
                    message: 'Listing ' + publishStatus + 'ed successfully!',
                    variant: 'success'
                });
                */
              //  this.dispatchEvent(event);
                window.location.reload(); //<--- Uncomment
                

            })
            .catch(error => {
                this.showToast('Error','Something went wrong while publishing the listing on Portal','error'); 
                this.isLoading = false;
                return;

                /*
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while publishing the listing on Portal',
                    variant: 'error'
                });
                this.dispatchEvent(event);  */
            });

    }
    

    handleButtonClick(event, portalName) {
        // Access the portalName value here
        console.log('Button clicked for portal: ', portalName);

    }


    fetchListingData() {
        // Call the Apex method imperatively
        fetchListingById({ listingId: this.recordId })
            .then(result => {
                console.log('result from fetchListingById = ',result);
                this.listing = result;
            })
            .catch(error => {
                console.error('Error fetching listing:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error fetching listing data',
                        variant: 'error'
                    })
                );
            });
    }

    checkForRequiredFields(portalName, publishStatus){
        console.log('portalName abc = '+portalName);
        console.log('publishStatus = '+publishStatus);
        console.log('this.listing.pba__PostalCode_pb__c] = ',this.listing.pba__PostalCode_pb__c);

        
        if(this.listing.pba__PostalCode_pb__c){

        let postalCodeString = this.listing.pba__PostalCode_pb__c;
        if(!(postalCodeString.includes(' '))){ //if postal code does not contain space
            console.log('postalCodeString does not contain space!');
                    this.isModalOpen = true;        
                    this.requiredFieldsMessage = `Please make sure Postal Code is in the following format and try again :- Outward code [space] Inward Code, example AA9A 9AA.`;
                    return 'error';
                
        }

        }   

        //Check for mandatory fields: -
        if(portalName == 'On The Market' || portalName == 'Rightmove UK'){
            if(publishStatus == 'Publish'){
            const requiredFields = this.customMetaDataOTM;
                const missingFields = requiredFields.filter(field => {
                   // return field.required && !this.listing[field.apiName];
                   return field.record.Is_Required__c && !this.listing[field.apiName];
                });
                console.log('missingFields = '+missingFields);
                if (missingFields.length > 0) {
                    this.isModalOpen = true;        
                    this.requiredFieldsMessage = `Before proceeding to publish this listing, please fill in the following fields : ${missingFields.map(field => field.record.Label).join(', ')}`;
                    return 'error';
                } else {
                     return 'success';
                }
            }
        }

        if(portalName == 'SIR.com Anywhere'){
            if(publishStatus == 'Publish'){
            const requiredFields = this.customMetaDataAnywhere;
                const missingFields = requiredFields.filter(field => {
                   // return field.required && !this.listing[field.apiName];
                   return field.record.Is_Required__c && !this.listing[field.apiName];
                });
                console.log('missingFields = '+missingFields);
                if (missingFields.length > 0) {
                    this.isModalOpen = true;        
                    this.requiredFieldsMessage = `Before proceeding to publish this listing, please fill in the following fields : ${missingFields.map(field => field.record.Label).join(', ')}`;
                    return 'error';
                } else {
                     return 'success';
                }
            }

             
        }

        if(portalName == 'Zoopla UK'){
            if(publishStatus == 'Publish'){
                console.log('portal is Zoopla UK');
            const requiredFields = this.customMetaDataZooplaUK;
                const missingFields = requiredFields.filter(field => {
                   // return field.required && !this.listing[field.apiName];
                   return field.record.Required__c && !this.listing[field.apiName];
                });
                console.log('missingFields = '+missingFields);
                if (missingFields.length > 0) {
                    this.isModalOpen = true;        
                    this.requiredFieldsMessage = `Before proceeding to publish this listing, please fill in the following fields : ${missingFields.map(field => field.record.Name).join(', ')}`;
                    return 'error';
                } else {
                     return 'success';
                }
            }

             
        }

    }


    showToast(title, message, variant) {
        console.log('inside showToast!');
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
}