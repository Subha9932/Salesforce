import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_FEEDBACK_OBJECT from '@salesforce/schema/Account_Feedback__c';
import AF_ACCOUNT_FIELD from '@salesforce/schema/Account_Feedback__c.Account__c';
import AF_RATING_FIELD from '@salesforce/schema/Account_Feedback__c.Rating__c';
import AF_COMMENTS_FIELD from '@salesforce/schema/Account_Feedback__c.Comments__c';
import { createRecord } from 'lightning/uiRecordApi';

export default class AccountFeedbackRating extends LightningElement {
    // Record Id of the Account from the record page
    @api recordId;

    // UI state
    stars = [1, 2, 3, 4, 5];
    @track hovered = 0;
    @track selected = 0;
    @track comments = '';
    @track message;
    @track error;

    // Configuration (public boolean must default to false per LWC1099)
    @api showComment = false;

    // Accessibility helper for CSS class on stars
    getStarClass = (event) => {
        // This function isn't used as a getter; keep for reference if using computed class through template.
        return '';
    };

    // compute class per star value
    computedClassFor(value) {
        const active = (this.hovered || this.selected) >= value;
        return 'star ' + (active ? 'active' : '');
    }

    // keyboard support on star
    handleKeyDown(event) {
        const value = Number(event.currentTarget?.dataset?.value || event.currentTarget?.dataset?.star);
        if (!value) return;
        switch (event.key) {
            case 'Enter':
            case ' ':
                this.setSelected(value);
                break;
            case 'ArrowLeft':
            case 'Left':
                this.setSelected(Math.max(1, (this.selected || 1) - 1));
                break;
            case 'ArrowRight':
            case 'Right':
                this.setSelected(Math.min(5, (this.selected || 0) + 1));
                break;
            default:
        }
    }

    handleMouseOver = (event) => {
        const value = Number(event.currentTarget?.dataset?.value);
        this.hovered = value || 0;
        this.updateStarClasses();
    };

    handleMouseLeave = () => {
        this.hovered = 0;
        this.updateStarClasses();
    };

    handleClick = (event) => {
        const value = Number(event.currentTarget?.dataset?.value);
        this.setSelected(value || 0);
    };

    setSelected(val) {
        this.selected = val;
        this.updateStarClasses();
    }

    handleCommentChange = (event) => {
        this.comments = event.target.value;
    };

    updateStarClasses() {
        // update class on each star element
        const stars = this.template.querySelectorAll('span[data-value]');
        stars.forEach((el) => {
            const value = Number(el.dataset.value);
            el.className = this.computedClassFor(value);
            // keep aria-label simple numeric for now to avoid template concat issues
            el.setAttribute('aria-label', String(value));
        });
    }

    get submitDisabled() {
        return !(this.selected >= 1 && this.selected <= 5);
    }

    async handleSubmit() {
        this.message = undefined;
        this.error = undefined;

        if (this.submitDisabled) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Rating required',
                    message: 'Please select a rating between 1 and 5.',
                    variant: 'warning'
                })
            );
            return;
        }

        try {
            // Build fields map
            const fields = {};
            fields[AF_ACCOUNT_FIELD.fieldApiName] = this.recordId;
            fields[AF_RATING_FIELD.fieldApiName] = String(this.selected); // picklist values are strings
            if (this.showComment && this.comments) {
                fields[AF_COMMENTS_FIELD.fieldApiName] = this.comments;
            }

            const recordInput = {
                apiName: ACCOUNT_FEEDBACK_OBJECT.objectApiName,
                fields
            };

            await createRecord(recordInput);

            this.message = 'Feedback submitted';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Your feedback was submitted.',
                    variant: 'success'
                })
            );

            // reset
            this.selected = 0;
            this.comments = '';
            this.updateStarClasses();
        } catch (e) {
            // Surface error
            const msg = e?.body?.message || e?.message || 'Unknown error';
            this.error = msg;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error submitting feedback',
                    message: msg,
                    variant: 'error'
                })
            );
        }
    }
}
