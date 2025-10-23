@isTest
public class AccountPhoneUpdateTriggerTest {
    
    @isTest
    static void testAccountPhoneUpdateTrigger() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890'
        );
        insert testAccount;
        
        // Create test contact associated with the account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Phone = '098-765-4321'
        );
        insert testContact;
        
        // Verify initial phone numbers
        Account updatedAccount = [SELECT Id, Phone FROM Account WHERE Id = :testAccount.Id];
        Contact updatedContact = [SELECT Id, Phone FROM Contact WHERE Id = :testContact.Id];
        
        System.assertEquals('123-456-7890', updatedAccount.Phone, 'Account phone should be 123-456-7890');
        System.assertEquals('098-765-4321', updatedContact.Phone, 'Contact phone should be 098-765-4321');
        
        // Update account phone number
        updatedAccount.Phone = '555-555-5555';
        update updatedAccount;
        
        // Verify contact phone was updated
        Contact updatedContactAfter = [SELECT Id, Phone FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('555-555-5555', updatedContactAfter.Phone, 'Contact phone should be updated to 555-555-5555');
    }
    
    @isTest
    static void testAccountPhoneUpdateTriggerWithNoChange() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account 2',
            Phone = '123-456-7890'
        );
        insert testAccount;
        
        // Create test contact associated with the account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 2',
            AccountId = testAccount.Id,
            Phone = '098-765-4321'
        );
        insert testContact;
        
        // Update account with same phone number (no change)
        testAccount.Phone = '123-456-7890'; // Same as original
        update testAccount;
        
        // Verify contact phone was NOT updated
        Contact updatedContact = [SELECT Id, Phone FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('098-765-4321', updatedContact.Phone, 'Contact phone should remain unchanged');
    }
    
    @isTest
    static void testAccountPhoneUpdateTriggerMultipleContacts() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account 3',
            Phone = '123-456-7890'
        );
        insert testAccount;
        
        // Create multiple test contacts associated with the account
        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1',
            AccountId = testAccount.Id,
            Phone = '098-765-4321'
        );
        Contact testContact2 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 2',
            AccountId = testAccount.Id,
            Phone = '111-222-3333'
        );
        insert new List<Contact>{testContact1, testContact2};
        
        // Verify initial phone numbers
        List<Contact> updatedContacts = [SELECT Id, Phone FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(2, updatedContacts.size(), 'Should have 2 contacts');
        
        // Update account phone number
        testAccount.Phone = '555-555-5555';
        update testAccount;
        
        // Verify both contacts phone numbers were updated
        updatedContacts = [SELECT Id, Phone FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(2, updatedContacts.size(), 'Should still have 2 contacts');
        
        for (Contact c : updatedContacts) {
            System.assertEquals('555-555-5555', c.Phone, 'All contact phones should be updated to 555-555-5555');
        }
    }
}
