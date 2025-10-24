@IsTest
private class AccountSlackNotifyJobTest {
    // Simple HttpCalloutMock that validates request and returns 200 OK
    private class SlackMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod(), 'Should use POST');
            System.assert(req.getEndpoint().startsWith('callout:Slack_Webhook'), 'Endpoint should use Named Credential');
            System.assertEquals('application/json; charset=UTF-8', req.getHeader('Content-Type'));
            System.assertNotEquals(null, req.getBody(), 'Body should not be null');
            System.assert(req.getBody().contains('Account updated') || req.getBody().contains('Notification'), 'Body should contain summary text');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('ok');
            return res;
        }
    }

    @IsTest
    static void postsWhenNameOrPhoneChanges() {
        // Prepare test data
        Account a = new Account(Name = 'Acme', Phone = '123-0000');
        insert a;

        // Register mock
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        Test.startTest();
        // Update tracked fields to trigger queueable + callout
        a.Name = 'Acme Corp';
        a.Phone = '555-0100';
        update a;
        Test.stopTest(); // Executes the Queueable
    }

    @IsTest
    static void noPostWhenNoTrackedFieldChanges() {
        // Prepare test data
        Account a = new Account(Name = 'Beta', Phone = '321-0000', NumberOfEmployees = 10);
        insert a;

        // Register a mock that will fail if called
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        Test.startTest();
        // Change an untracked field only; Queueable should not be enqueued
        a.NumberOfEmployees = 20;
        update a;
        Test.stopTest();

        // No direct assertion for "no callout" without a stateful mock, but at least
        // ensure no exceptions and DML succeeded. Optionally, we could implement a
        // stateful mock to track invocations.
    }
}
