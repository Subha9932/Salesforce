import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import generateSummary from '@salesforce/apex/AccountSummaryService.generateSummary';

const ACCOUNT_FIELDS = ['Account.Id', 'Account.Name'];

export default class AccountSummary extends LightningElement {
    @api recordId;
    @track loading = false;
    @track error;
    @track summary;
    @track model;
    @track tokenUsage;

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    accountRecord;

    connectedCallback() {
        // Optionally auto-run when on record page
        this.run();
    }

    get hasSummary() {
        return this.summary && this.summary.length > 0;
    }

    async run() {
        if (!this.recordId) return;
        this.loading = true;
        this.error = undefined;
        try {
            const res = await generateSummary({ accountId: this.recordId });
            this.summary = res?.summaryText || 'No summary returned.';
            this.model = res?.model;
            this.tokenUsage = res?.tokenUsage;
        } catch (e) {
            // Normalize error
            this.error = e?.body?.message || e?.message || 'Unknown error';
            this.summary = undefined;
        } finally {
            this.loading = false;
        }
    }

    handleRefresh() {
        this.run();
    }
}
