public with sharing class AccountSlackNotifyJob implements Queueable, Database.AllowsCallouts {
    private List<Account> newList;
    private Map<Id, Account> oldMap;

    public AccountSlackNotifyJob(List<Account> newList, Map<Id, Account> oldMap) {
        this.newList = new List<Account>(newList);
        this.oldMap = new Map<Id, Account>(oldMap);
    }

    public void execute(QueueableContext qc) {
        List<String> lines = new List<String>();
        for (Account a : newList) {
            Account oldA = oldMap.get(a.Id);
            if (oldA == null) continue;

            List<String> changes = new List<String>();
            if (a.Name != oldA.Name) {
                changes.add('Name: "' + oldA.Name + '" \u2192 "' + a.Name + '"');
            }
            if (a.Phone != oldA.Phone) {
                changes.add('Phone: "' + oldA.Phone + '" \u2192 "' + a.Phone + '"');
            }

            if (!changes.isEmpty()) {
                String line = 'Account updated: ' + a.Name + ' (Id: ' + a.Id + ')\n' +
                              '- ' + String.join(changes, '\n- ');
                lines.add(line);
            }
        }

        if (!lines.isEmpty()) {
            String message = 'Salesforce Notification: ' + lines.size() + ' Account update(s)\n' + String.join(lines, '\n\n');
            SlackNotifier.postMessage(message);
        }
    }
}
