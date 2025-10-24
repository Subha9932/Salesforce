public with sharing class SlackNotifier {
    /**
     * Posts a simple text message to Slack using a Named Credential that contains the FULL incoming webhook URL.
     * Prerequisite:
     * - Named Credential:
     *   - Label: Slack Webhook
     *   - Name (DeveloperName): Slack_Webhook
     *   - URL: https://hooks.slack.com/services/XXX/YYY/ZZZ (your exact webhook URL)
     *   - Identity Type: Anonymous
     *   - Authentication Protocol: No Authentication
     */
    public static void postMessage(String text) {
        if (String.isBlank(text)) return;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Slack_Webhook');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('text', text);
        req.setBody(JSON.serialize(payload));

        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Slack post exception: ' + e.getMessage());
            return;
        }

        if (res == null || res.getStatusCode() >= 300) {
            System.debug(LoggingLevel.ERROR, 'Slack post failed: ' + (res == null ? 'null response' : res.getStatus() + ' ' + res.getBody()));
        }
    }
}
