public with sharing class AccountSummaryService {
    public class SummaryResult {
        @AuraEnabled public String accountId;
        @AuraEnabled public String summaryText;
        @AuraEnabled public String model;
        @AuraEnabled public String tokenUsage;
    }

    @AuraEnabled(cacheable=false)
    public static SummaryResult generateSummary(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('accountId is required');
        }

        // Query Account + related data (min fields to avoid FLS issues; rely on FLS at runtime)
        Account acc = [
            SELECT Id, Name, Industry, Rating
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        List<Contact> contacts = [
            SELECT Id, Name, Title, Email
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastModifiedDate DESC
            LIMIT 50
        ];

        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY CloseDate DESC
            LIMIT 50
        ];

        // Prepare variable bindings for Flex Prompt Template
        // Template DeveloperName as confirmed: Account_Summery_Generator
        Map<String, Object> vars = new Map<String, Object>{
            'account' => acc,
            'contacts' => contacts,
            'opportunities' => opps
        };

        // Execute the Flex Prompt using Prompt Builder service
        // Using Sync call for simplicity; adapt to async if needed.
        // The following class/method names align with GA/preview "PromptTemplateService" style APIs.
        // If your org uses a namespaced/older API, update the invocation accordingly.
        String templateApiName = 'Account_Summery_Generator';

        String output;
        String modelUsed;
        String tokenInfo;

        try {
            // Example invocation pattern. Adjust if your org exposes a slightly different API surface.
            // Expected behavior: service runs the Flex template with provided variables and returns text.
            // Pseudo-contract:
            // PromptTemplateService.Result res = PromptTemplateService.runTemplate(templateApiName, vars);
            // output = res.outputText; modelUsed = res.model; tokenInfo = res.tokenUsage;

            // Fallback generic pattern using an invocable-like service
            // Replace with your org's exact method if different.
            output = PromptTemplateService.runFlexTemplate(templateApiName, vars);

            // Optional: if your org supports structured result
            // PromptTemplateService.Result res = PromptTemplateService.runFlexTemplateEx(templateApiName, vars);
            // output = res.outputText; modelUsed = res.model; tokenInfo = res.tokenUsage;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate summary: ' + e.getMessage());
        }

        SummaryResult sr = new SummaryResult();
        sr.accountId = accountId;
        sr.summaryText = String.isBlank(output) ? 'No summary returned.' : output;
        sr.model = modelUsed;
        sr.tokenUsage = tokenInfo;
        return sr;
    }
}
