import { LightningElement, api, track } from 'lwc';
import uploadFileToSalesforce from '@salesforce/apex/FileUploadControllerInGallery.uploadFile';
import getUploadedImages from '@salesforce/apex/FileUploadControllerInGallery.getUploadedImages';
import updateImageOrder from '@salesforce/apex/FileUploadControllerInGallery.updateImageOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ImageUpload extends LightningElement {
    @api recordId;
    @track images = [];
    draggedIndex = null;

    connectedCallback() {
        this.fetchImages();
    }

    fetchImages() {
    getUploadedImages({ recordId: this.recordId })
        .then(result => {
            this.images = result.map((file, index) => ({
                id: file.Id,
                url: `/sfc/servlet.shepherd/document/download/${file.ContentDocumentId__c}`,
                serialNumber: index + 1 // Set the serial no according to order     
            }));
        })
        .catch(error => {
            console.error('Error fetching images', error);
        });
    }


    handleFileChange(event) {
    const files = Array.from(event.target.files);

    files.forEach(file => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            
            // Temporary ID for UI update
            const tempId = `temp-${Date.now()}`;
            this.images.push({
                id: tempId,
                url: URL.createObjectURL(file),
                serialNumber: this.images.length + 1 //Set the Serial Number directly on the basis of length.
            });

            uploadFileToSalesforce({ fileName: file.name, base64Data: base64, recordId: this.recordId })
                .then(() => {
                    this.showToast('Success', 'File uploaded successfully', 'success');
                    this.fetchImages(); //after refreshing the list get the actual order.
                })
                .catch(error => {
                    console.error('Upload Error:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to upload file: ' + (error.body?.message || 'Unknown Error'), 'error');

                    // remove the temp preview on failure.
                    this.images = this.images.filter(img => img.id !== tempId);
                });
            };
        });
    }


    handleDragStart(event) {
        this.draggedIndex = Number(event.currentTarget.dataset.index); //Type cast to number
        event.dataTransfer.effectAllowed = 'move';
    }

    handleDrop(event) {
    event.preventDefault();
    const droppedIndex = Number(event.currentTarget.dataset.index);

    if (this.draggedIndex !== null && this.draggedIndex !== droppedIndex) {
        const updatedImages = [...this.images];
        const temp = updatedImages[this.draggedIndex];
        updatedImages[this.draggedIndex] = updatedImages[droppedIndex];
        updatedImages[droppedIndex] = temp;

        //reorder the Serial number
        updatedImages.forEach((img, index) => {
            img.serialNumber = index + 1;
        });

        this.images = [...updatedImages];

        //update the Backend order
        updateImageOrder({ mediaList: updatedImages })
            .then(() => this.showToast('Success', 'Order updated successfully', 'success'))
            .catch(error => {
                this.showToast('Error', 'Failed to update order', 'error');
            });
    }
    this.draggedIndex = null;
   }


    allowDrop(event) {
        event.preventDefault();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}