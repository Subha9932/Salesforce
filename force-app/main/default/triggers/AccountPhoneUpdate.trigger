trigger AccountPhoneUpdate on Account (after update) {
    // Collect account IDs where phone has changed
    Set<Id> accountIds = new Set<Id>();
    
    // Create a map to store account phone numbers for quick lookup
    Map<Id, String> accountPhoneMap = new Map<Id, String>();
    
    for (Account acc : Trigger.new) {
        Account oldAcc = Trigger.oldMap.get(acc.Id);
        if (oldAcc.Phone != acc.Phone) {
            accountIds.add(acc.Id);
            accountPhoneMap.put(acc.Id, acc.Phone);
        }
    }
    
    // If no accounts have phone changes, exit early
    if (accountIds.isEmpty()) {
        return;
    }
    
    // Query all contacts for these accounts
    List<Contact> contactsToUpdate = [
        SELECT Id, AccountId 
        FROM Contact 
        WHERE AccountId IN :accountIds
    ];
    
    // Update contacts with new phone number
    for (Contact cont : contactsToUpdate) {
        cont.Phone = accountPhoneMap.get(cont.AccountId);
    }
    
    // Perform bulk update
    if (!contactsToUpdate.isEmpty()) {
        update contactsToUpdate;
    }
}
