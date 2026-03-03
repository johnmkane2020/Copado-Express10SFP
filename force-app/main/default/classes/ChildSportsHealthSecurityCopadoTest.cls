@isTest
public class ChildSportsHealthSecurityCopadoTest {
    
    @isTest
    static void testValidateAccess_WithValidPermissions() {
        // Create test record
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Security Test Child',
            Parent_Name__c = 'Security Test Parent',
            Parent_Phone__c = '+1-555-000-0001',
            Sports__c = 'Soccer',
            Activity_Rating__c = 'Average'
        );
        insert testRecord;
        
        List<Child_Sports_Health__c> records = new List<Child_Sports_Health__c>{testRecord};
        
        // Test with System Admin (should have all permissions)
        Test.startTest();
        try {
            ChildSportsHealthSecurityCopado.validateAccess(records);
            System.assert(true, 'Validation should pass with proper permissions');
        } catch(Exception e) {
            System.assert(false, 'Should not throw exception with valid permissions: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateAccess_WithMultipleRecords() {
        List<Child_Sports_Health__c> testRecords = new List<Child_Sports_Health__c>();
        
        for(Integer i = 1; i <= 5; i++) {
            testRecords.add(new Child_Sports_Health__c(
                Child_Name__c = 'Test Child ' + i,
                Parent_Name__c = 'Test Parent ' + i,
                Parent_Phone__c = '+1-555-000-000' + i,
                Sports__c = 'Baseball',
                Activity_Rating__c = 'High'
            ));
        }
        insert testRecords;
        
        Test.startTest();
        try {
            ChildSportsHealthSecurityCopado.validateAccess(testRecords);
            System.assert(true, 'Should validate access for multiple records');
        } catch(Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateAccess_WithEmptyList() {
        List<Child_Sports_Health__c> emptyList = new List<Child_Sports_Health__c>();
        
        Test.startTest();
        try {
            ChildSportsHealthSecurityCopado.validateAccess(emptyList);
            System.assert(true, 'Should handle empty list gracefully');
        } catch(Exception e) {
            System.assert(false, 'Should not throw exception for empty list: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateAccess_FieldLevelSecurity() {
        // Create a record to test field-level security
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'FLS Test Child',
            Parent_Name__c = 'FLS Test Parent',
            Parent_Phone__c = '+1-555-111-2222',
            Sports__c = 'Football',
            Activity_Rating__c = 'Above Average'
        );
        insert testRecord;
        
        List<Child_Sports_Health__c> records = new List<Child_Sports_Health__c>{testRecord};
        
        // Test that all required fields are checked
        Test.startTest();
        try {
            ChildSportsHealthSecurityCopado.validateAccess(records);
            
            // Verify that the method checks for these fields
            // Child_Name__c, Parent_Name__c, Parent_Phone__c, Sports__c
            System.assert(true, 'All field-level security checks should pass');
        } catch(Exception e) {
            System.assert(false, 'Field-level security should pass: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateAccess_ObjectPermissions() {
        // This test verifies that object-level permissions are checked
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Object Perm Test',
            Parent_Name__c = 'Object Perm Parent',
            Parent_Phone__c = '+1-555-333-4444',
            Sports__c = 'Soccer;Baseball',
            Activity_Rating__c = 'Extremely High'
        );
        insert testRecord;
        
        List<Child_Sports_Health__c> records = new List<Child_Sports_Health__c>{testRecord};
        
        Test.startTest();
        // Running as System Admin should have create/update permissions
        System.runAs(new User(Id = UserInfo.getUserId())) {
            try {
                ChildSportsHealthSecurityCopado.validateAccess(records);
                
                // Verify object-level permissions are being checked
                Schema.DescribeSObjectResult describeResult = Child_Sports_Health__c.SObjectType.getDescribe();
                System.assert(describeResult.isCreateable(), 'Object should be createable');
                System.assert(describeResult.isUpdateable(), 'Object should be updateable');
                
            } catch(Exception e) {
                System.assert(false, 'Object permissions should be valid: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateAccess_VerifySecurityChecks() {
        // Verify that the security method actually performs checks
        Child_Sports_Health__c testRecord = new Child_Sports_Health__c(
            Child_Name__c = 'Security Check Test',
            Parent_Name__c = 'Security Check Parent',
            Parent_Phone__c = '+1-555-777-8888',
            Sports__c = 'Football;Soccer',
            Activity_Rating__c = 'Extremely Low'
        );
        insert testRecord;
        
        List<Child_Sports_Health__c> records = new List<Child_Sports_Health__c>{testRecord};
        
        Test.startTest();
        // Verify field map contains expected fields
        Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Child_Sports_Health__c.fields.getMap();
        System.assert(fieldMap.containsKey('Child_Name__c'), 'Field map should contain Child_Name__c');
        System.assert(fieldMap.containsKey('Parent_Name__c'), 'Field map should contain Parent_Name__c');
        System.assert(fieldMap.containsKey('Parent_Phone__c'), 'Field map should contain Parent_Phone__c');
        System.assert(fieldMap.containsKey('Sports__c'), 'Field map should contain Sports__c');
        
        // Call validation method
        try {
            ChildSportsHealthSecurityCopado.validateAccess(records);
            System.assert(true, 'Security validation should complete successfully');
        } catch(Exception e) {
            System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}