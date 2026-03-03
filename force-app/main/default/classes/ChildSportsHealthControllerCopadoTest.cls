@isTest
public class ChildSportsHealthControllerCopadoTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test records
        List<Child_Sports_Health__c> testRecords = new List<Child_Sports_Health__c>();
        
        for(Integer i = 1; i <= 5; i++) {
            testRecords.add(new Child_Sports_Health__c(
                Child_Name__c = 'Test Child ' + i,
                Parent_Name__c = 'Test Parent ' + i,
                Parent_Phone__c = '+1-555-000-000' + i,
                Sports__c = 'Soccer;Baseball',
                Activity_Rating__c = 'Average'
            ));
        }
        
        insert testRecords;
    }
    
    @isTest
    static void testGetRecords_Success() {
        Test.startTest();
        List<Child_Sports_Health__c> records = ChildSportsHealthControllerCopado.getRecords();
        Test.stopTest();
        
        System.assertNotEquals(null, records, 'Records should not be null');
        System.assertEquals(5, records.size(), 'Should return 5 test records');
        System.assertEquals('Test Child 1', records[0].Child_Name__c, 'Should be ordered by Child Name');
    }
    
    @isTest
    static void testGetRecords_NoRecords() {
        // Delete all records
        delete [SELECT Id FROM Child_Sports_Health__c];
        
        Test.startTest();
        List<Child_Sports_Health__c> records = ChildSportsHealthControllerCopado.getRecords();
        Test.stopTest();
        
        System.assertNotEquals(null, records, 'Should return empty list, not null');
        System.assertEquals(0, records.size(), 'Should return empty list when no records exist');
    }
    
    @isTest
    static void testSaveRecord_Insert() {
        Child_Sports_Health__c newRecord = new Child_Sports_Health__c(
            Child_Name__c = 'New Child',
            Parent_Name__c = 'New Parent',
            Parent_Phone__c = '+1-555-999-9999',
            Sports__c = 'Football',
            Activity_Rating__c = 'High'
        );
        
        Test.startTest();
        Child_Sports_Health__c savedRecord = ChildSportsHealthControllerCopado.saveRecord(newRecord);
        Test.stopTest();
        
        System.assertNotEquals(null, savedRecord.Id, 'Record should have an Id after insert');
        System.assertEquals('New Child', savedRecord.Child_Name__c, 'Child name should match');
        System.assertEquals('New Parent', savedRecord.Parent_Name__c, 'Parent name should match');
        
        // Verify record was actually inserted
        Child_Sports_Health__c queriedRecord = [SELECT Id, Child_Name__c FROM Child_Sports_Health__c WHERE Id = :savedRecord.Id];
        System.assertEquals('New Child', queriedRecord.Child_Name__c, 'Record should exist in database');
    }
    
    @isTest
    static void testSaveRecord_Update() {
        Child_Sports_Health__c existingRecord = [SELECT Id, Child_Name__c, Parent_Name__c FROM Child_Sports_Health__c LIMIT 1];
        
        existingRecord.Child_Name__c = 'Updated Child';
        existingRecord.Parent_Name__c = 'Updated Parent';
        
        Test.startTest();
        Child_Sports_Health__c updatedRecord = ChildSportsHealthControllerCopado.saveRecord(existingRecord);
        Test.stopTest();
        
        System.assertEquals(existingRecord.Id, updatedRecord.Id, 'Record Id should remain the same');
        System.assertEquals('Updated Child', updatedRecord.Child_Name__c, 'Child name should be updated');
        System.assertEquals('Updated Parent', updatedRecord.Parent_Name__c, 'Parent name should be updated');
    }
    
    @isTest
    static void testSaveRecord_WithInvalidPhoneFormat() {
        Child_Sports_Health__c newRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Test Child',
            Parent_Name__c = 'Test Parent',
            Parent_Phone__c = 'INVALID@PHONE#',
            Sports__c = 'Soccer',
            Activity_Rating__c = 'Average'
        );
        
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            Child_Sports_Health__c savedRecord = ChildSportsHealthControllerCopado.saveRecord(newRecord);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should have thrown exception for invalid phone format');
    }
    
    @isTest
    static void testSaveRecord_WithoutRequiredField() {
        Child_Sports_Health__c newRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Test Child',
            Parent_Name__c = 'Test Parent',
            Parent_Phone__c = '+1-555-123-4567'
            // Sports field is required but not provided
        );
        
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            Child_Sports_Health__c savedRecord = ChildSportsHealthControllerCopado.saveRecord(newRecord);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should have thrown exception for missing required field');
    }
    
    @isTest
    static void testGetRecords_LargeDataSet() {
        // Delete existing records
        delete [SELECT Id FROM Child_Sports_Health__c];
        
        // Create a large dataset to test limit
        List<Child_Sports_Health__c> largeDataSet = new List<Child_Sports_Health__c>();
        for(Integer i = 1; i <= 100; i++) {
            largeDataSet.add(new Child_Sports_Health__c(
                Child_Name__c = 'Child ' + String.valueOf(i).leftPad(3, '0'),
                Parent_Name__c = 'Parent ' + i,
                Parent_Phone__c = '+1-555-000-0001',
                Sports__c = 'Soccer',
                Activity_Rating__c = 'Average'
            ));
        }
        insert largeDataSet;
        
        Test.startTest();
        List<Child_Sports_Health__c> records = ChildSportsHealthControllerCopado.getRecords();
        Test.stopTest();
        
        System.assertEquals(100, records.size(), 'Should return all 100 records');
        // Verify ordering
        System.assertEquals('Child 001', records[0].Child_Name__c, 'Should be ordered alphabetically by Child Name');
    }
    
    @isTest
    static void testSaveRecord_WithValidationSuccess() {
        Child_Sports_Health__c newRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Valid Record',
            Parent_Name__c = 'Valid Parent',
            Parent_Phone__c = '(555) 123-4567',
            Sports__c = 'Soccer;Basketball',
            Activity_Rating__c = 'High'
        );
        
        Test.startTest();
        Child_Sports_Health__c savedRecord = ChildSportsHealthControllerCopado.saveRecord(newRecord);
        Test.stopTest();
        
        System.assertNotEquals(null, savedRecord.Id, 'Record should be saved successfully');
        System.assertEquals('Valid Record', savedRecord.Child_Name__c, 'Child name should be saved');
        System.assertEquals('(555) 123-4567', savedRecord.Parent_Phone__c, 'Phone should be saved');
    }
}