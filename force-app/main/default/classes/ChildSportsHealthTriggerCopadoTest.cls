@isTest
public class ChildSportsHealthTriggerCopadoTest {
    
    @isTest
    static void testInsert_WithValidPhoneFormat() {
        List<Child_Sports_Health__c> testRecords = new List<Child_Sports_Health__c>();
        
        // Test various valid phone formats
        testRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 1',
            Parent_Name__c = 'Parent 1',
            Parent_Phone__c = '+1-555-123-4567',
            Sports__c = 'Soccer',
            Activity_Rating__c = 'Average'
        ));
        
        testRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 2',
            Parent_Name__c = 'Parent 2',
            Parent_Phone__c = '(555) 123-4567',
            Sports__c = 'Baseball',
            Activity_Rating__c = 'High'
        ));
        
        testRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 3',
            Parent_Name__c = 'Parent 3',
            Parent_Phone__c = '555.123.4567',
            Sports__c = 'Football',
            Activity_Rating__c = 'Low'
        ));
        
        testRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 4',
            Parent_Name__c = 'Parent 4',
            Parent_Phone__c = '5551234567',
            Sports__c = 'Soccer;Baseball',
            Activity_Rating__c = 'Extremely High'
        ));
        
        Test.startTest();
        insert testRecords;
        Test.stopTest();
        
        // Verify all records were inserted successfully
        List<Child_Sports_Health__c> insertedRecords = [SELECT Id, Parent_Phone__c FROM Child_Sports_Health__c WHERE Id IN :testRecords];
        System.assertEquals(4, insertedRecords.size(), 'All records with valid phone formats should be inserted');
    }
    
    @isTest
    static void testInsert_WithInvalidPhoneFormat() {
        Child_Sports_Health__c invalidRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Invalid Child',
            Parent_Name__c = 'Invalid Parent',
            Parent_Phone__c = 'INVALID@PHONE#',
            Sports__c = 'Soccer',
            Activity_Rating__c = 'Average'
        );
        
        Test.startTest();
        Database.SaveResult result = Database.insert(invalidRecord, false);
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess(), 'Insert should fail for invalid phone format');
        System.assert(result.getErrors().size() > 0, 'Should have error messages');
        System.assert(result.getErrors()[0].getMessage().contains('valid phone number'), 
                     'Error message should mention valid phone number');
    }
    
    @isTest
    static void testInsert_WithMultipleInvalidFormats() {
        List<Child_Sports_Health__c> invalidRecords = new List<Child_Sports_Health__c>();
        
        // Various invalid phone formats
        invalidRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 1',
            Parent_Name__c = 'Parent 1',
            Parent_Phone__c = 'ABC-DEF-GHIJ',
            Sports__c = 'Soccer'
        ));
        
        invalidRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 2',
            Parent_Name__c = 'Parent 2',
            Parent_Phone__c = '###-###-####',
            Sports__c = 'Baseball'
        ));
        
        invalidRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Child 3',
            Parent_Name__c = 'Parent 3',
            Parent_Phone__c = 'phone@email.com',
            Sports__c = 'Football'
        ));
        
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(invalidRecords, false);
        Test.stopTest();
        
        // Verify all inserts failed
        for(Database.SaveResult result : results) {
            System.assertEquals(false, result.isSuccess(), 'Insert should fail for invalid phone formats');
            System.assert(result.getErrors()[0].getMessage().contains('valid phone number'), 
                         'Error should mention valid phone number');
        }
    }
    
    @isTest
    static void testInsert_WithBlankPhone() {
        Child_Sports_Health__c blankPhoneRecord = new Child_Sports_Health__c(
            Child_Name__c = 'No Phone Child',
            Parent_Name__c = 'No Phone Parent',
            Parent_Phone__c = '',
            Sports__c = 'Soccer',
            Activity_Rating__c = 'Average'
        );
        
        Test.startTest();
        insert blankPhoneRecord;
        Test.stopTest();
        
        // Verify record was inserted (blank phone becomes null and is allowed)
        Child_Sports_Health__c insertedRecord = [SELECT Id, Parent_Phone__c FROM Child_Sports_Health__c WHERE Id = :blankPhoneRecord.Id];
        System.assertEquals(null, insertedRecord.Parent_Phone__c, 'Blank phone should become null and be allowed');
    }
    
    @isTest
    static void testInsert_WithNullPhone() {
        Child_Sports_Health__c nullPhoneRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Null Phone Child',
            Parent_Name__c = 'Null Phone Parent',
            Parent_Phone__c = null,
            Sports__c = 'Baseball',
            Activity_Rating__c = 'High'
        );
        
        Test.startTest();
        insert nullPhoneRecord;
        Test.stopTest();
        
        // Verify record was inserted (null phone is allowed)
        Child_Sports_Health__c insertedRecord = [SELECT Id, Parent_Phone__c FROM Child_Sports_Health__c WHERE Id = :nullPhoneRecord.Id];
        System.assertEquals(null, insertedRecord.Parent_Phone__c, 'Null phone should be allowed');
    }
    
    @isTest
    static void testUpdate_WithValidPhoneFormat() {
        // Insert record with valid phone
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Update Test Child',
            Parent_Name__c = 'Update Test Parent',
            Parent_Phone__c = '+1-555-000-0001',
            Sports__c = 'Soccer',
            Activity_Rating__c = 'Average'
        );
        insert testRecord;
        
        // Update with another valid format
        testRecord.Parent_Phone__c = '(555) 999-9999';
        
        Test.startTest();
        update testRecord;
        Test.stopTest();
        
        // Verify update was successful
        Child_Sports_Health__c updatedRecord = [SELECT Id, Parent_Phone__c FROM Child_Sports_Health__c WHERE Id = :testRecord.Id];
        System.assertEquals('(555) 999-9999', updatedRecord.Parent_Phone__c, 'Phone should be updated');
    }
    
    @isTest
    static void testUpdate_WithInvalidPhoneFormat() {
        // Insert record with valid phone
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Update Test Child',
            Parent_Name__c = 'Update Test Parent',
            Parent_Phone__c = '+1-555-000-0001',
            Sports__c = 'Football',
            Activity_Rating__c = 'Low'
        );
        insert testRecord;
        
        // Try to update with invalid format
        testRecord.Parent_Phone__c = 'INVALID!!!';
        
        Test.startTest();
        Database.SaveResult result = Database.update(testRecord, false);
        Test.stopTest();
        
        System.assertEquals(false, result.isSuccess(), 'Update should fail for invalid phone format');
        System.assert(result.getErrors().size() > 0, 'Should have error messages');
        System.assert(result.getErrors()[0].getMessage().contains('valid phone number'), 
                     'Error message should mention valid phone number');
    }
    
    @isTest
    static void testUpdate_ChangingFromValidToBlank() {
        // Insert record with valid phone
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Blank Update Child',
            Parent_Name__c = 'Blank Update Parent',
            Parent_Phone__c = '+1-555-111-2222',
            Sports__c = 'Baseball;Soccer',
            Activity_Rating__c = 'Above Average'
        );
        insert testRecord;
        
        // Update to blank (which becomes null)
        testRecord.Parent_Phone__c = '';
        
        Test.startTest();
        update testRecord;
        Test.stopTest();
        
        // Verify update was successful (blank becomes null and is allowed)
        Child_Sports_Health__c updatedRecord = [SELECT Id, Parent_Phone__c FROM Child_Sports_Health__c WHERE Id = :testRecord.Id];
        System.assertEquals(null, updatedRecord.Parent_Phone__c, 'Blank phone should become null and be allowed on update');
    }
    
    @isTest
    static void testBulkInsert_MixedValidAndInvalid() {
        List<Child_Sports_Health__c> mixedRecords = new List<Child_Sports_Health__c>();
        
        // Valid records
        for(Integer i = 1; i <= 50; i++) {
            mixedRecords.add(new Child_Sports_Health__c(
                Child_Name__c = 'Valid Child ' + i,
                Parent_Name__c = 'Valid Parent ' + i,
                Parent_Phone__c = '+1-555-000-00' + String.valueOf(i).leftPad(2, '0'),
                Sports__c = 'Soccer',
                Activity_Rating__c = 'Average'
            ));
        }
        
        // Invalid records
        for(Integer i = 1; i <= 10; i++) {
            mixedRecords.add(new Child_Sports_Health__c(
                Child_Name__c = 'Invalid Child ' + i,
                Parent_Name__c = 'Invalid Parent ' + i,
                Parent_Phone__c = 'BAD@PHONE' + i,
                Sports__c = 'Baseball',
                Activity_Rating__c = 'High'
            ));
        }
        
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(mixedRecords, false);
        Test.stopTest();
        
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for(Database.SaveResult result : results) {
            if(result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
            }
        }
        
        System.assertEquals(50, successCount, 'Valid records should be inserted');
        System.assertEquals(10, failureCount, 'Invalid records should fail');
    }
    
    @isTest
    static void testInternationalPhoneFormats() {
        List<Child_Sports_Health__c> internationalRecords = new List<Child_Sports_Health__c>();
        
        // International valid formats
        internationalRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'UK Child',
            Parent_Name__c = 'UK Parent',
            Parent_Phone__c = '+44 20 7123 4567',
            Sports__c = 'Soccer'
        ));
        
        internationalRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'France Child',
            Parent_Name__c = 'France Parent',
            Parent_Phone__c = '+33 1 23 45 67 89',
            Sports__c = 'Football'
        ));
        
        internationalRecords.add(new Child_Sports_Health__c(
            Child_Name__c = 'Japan Child',
            Parent_Name__c = 'Japan Parent',
            Parent_Phone__c = '+81-3-1234-5678',
            Sports__c = 'Baseball'
        ));
        
        Test.startTest();
        insert internationalRecords;
        Test.stopTest();
        
        // Verify all international formats were accepted
        List<Child_Sports_Health__c> insertedRecords = [SELECT Id FROM Child_Sports_Health__c WHERE Id IN :internationalRecords];
        System.assertEquals(3, insertedRecords.size(), 'International phone formats should be accepted');
    }
    
    @isTest
    static void testUpdate_ChangingFromValidToNull() {
        // Insert record with valid phone
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Null Update Child',
            Parent_Name__c = 'Null Update Parent',
            Parent_Phone__c = '+1-555-222-3333',
            Sports__c = 'Soccer;Football',
            Activity_Rating__c = 'High'
        );
        insert testRecord;
        
        // Update to null
        testRecord.Parent_Phone__c = null;
        
        Test.startTest();
        update testRecord;
        Test.stopTest();
        
        // Verify update was successful
        Child_Sports_Health__c updatedRecord = [SELECT Id, Parent_Phone__c FROM Child_Sports_Health__c WHERE Id = :testRecord.Id];
        System.assertEquals(null, updatedRecord.Parent_Phone__c, 'Null phone should be allowed on update');
    }
}