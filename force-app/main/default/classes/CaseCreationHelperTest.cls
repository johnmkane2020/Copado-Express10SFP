/**
 * Test Class: CaseCreationHelperTest
 * Purpose: Test coverage for ChildSportsHealthTrigger and CaseCreationHelper
 * User Story: US-0000134
 * Created: 2026-03-18
 * 
 * Provides comprehensive test coverage for the automated case creation
 * functionality when children are flagged with extremely low activity ratings.
 */
@isTest
private class CaseCreationHelperTest {
    
    /**
     * Test: Verify that a Case is created when a Child record is inserted with Extremely Low activity
     */
    @isTest
    static void testCaseCreationOnInsert_ExtremelyLow() {
        // Create test data
        Child_Sports_Health__c testChild = new Child_Sports_Health__c(
            Child_First_Name__c = 'John',
            Child_Last_Name__c = 'Doe',
            Parent_First_Name__c = 'Jane',
            Parent_Last_Name__c = 'Doe',
            Parent_Phone__c = '1234567890',
            Activity_Rating__c = 'Extremely Low',
            Sports__c = 'Soccer'
        );
        
        Test.startTest();
        insert testChild;
        Test.stopTest();
        
        // Verify Case was created
        List<Case> createdCases = [SELECT Id, Subject, Status, Priority, Description, Child_Sports_Health__c
                                   FROM Case 
                                   WHERE Child_Sports_Health__c = :testChild.Id];
        
        System.assertEquals(1, createdCases.size(), 'Expected exactly one Case to be created');
        System.assertEquals('New', createdCases[0].Status, 'Case status should be New');
        System.assertEquals('High', createdCases[0].Priority, 'Case priority should be High');
        System.assert(createdCases[0].Subject.contains('John Doe'), 'Subject should contain child name');
    }
    
    /**
     * Test: Verify that a Case is created when Activity Rating is updated to Extremely Low
     */
    @isTest
    static void testCaseCreationOnUpdate_ExtremelyLow() {
        // Create test data with different activity rating
        Child_Sports_Health__c testChild = new Child_Sports_Health__c(
            Child_First_Name__c = 'Sarah',
            Child_Last_Name__c = 'Smith',
            Parent_First_Name__c = 'Robert',
            Parent_Last_Name__c = 'Smith',
            Parent_Phone__c = '9876543210',
            Activity_Rating__c = 'Average',
            Sports__c = 'Baseball;Football'
        );
        insert testChild;
        
        // Verify no case exists yet
        List<Case> casesBefore = [SELECT Id FROM Case WHERE Child_Sports_Health__c = :testChild.Id];
        System.assertEquals(0, casesBefore.size(), 'No cases should exist before update');
        
        // Update activity rating to Extremely Low
        Test.startTest();
        testChild.Activity_Rating__c = 'Extremely Low';
        update testChild;
        Test.stopTest();
        
        // Verify Case was created
        List<Case> casesAfter = [SELECT Id, Subject, Description 
                                 FROM Case 
                                 WHERE Child_Sports_Health__c = :testChild.Id];
        
        System.assertEquals(1, casesAfter.size(), 'Expected exactly one Case to be created after update');
        System.assert(casesAfter[0].Subject.contains('Sarah Smith'), 'Subject should contain child name');
    }
    
    /**
     * Test: Verify that NO Case is created for other activity ratings
     */
    @isTest
    static void testNoCaseCreation_OtherRatings() {
        // Create test data with different activity ratings
        List<Child_Sports_Health__c> testChildren = new List<Child_Sports_Health__c>();
        
        testChildren.add(new Child_Sports_Health__c(
            Child_First_Name__c = 'Alice',
            Child_Last_Name__c = 'Johnson',
            Parent_First_Name__c = 'Mark',
            Parent_Last_Name__c = 'Johnson',
            Activity_Rating__c = 'Low',
            Sports__c = 'Soccer'
        ));
        
        testChildren.add(new Child_Sports_Health__c(
            Child_First_Name__c = 'Bob',
            Child_Last_Name__c = 'Williams',
            Parent_First_Name__c = 'Lisa',
            Parent_Last_Name__c = 'Williams',
            Activity_Rating__c = 'Average',
            Sports__c = 'Baseball'
        ));
        
        testChildren.add(new Child_Sports_Health__c(
            Child_First_Name__c = 'Charlie',
            Child_Last_Name__c = 'Brown',
            Parent_First_Name__c = 'Tom',
            Parent_Last_Name__c = 'Brown',
            Activity_Rating__c = 'High',
            Sports__c = 'Football'
        ));
        
        Test.startTest();
        insert testChildren;
        Test.stopTest();
        
        // Verify no Cases were created
        List<Case> createdCases = [SELECT Id FROM Case 
                                   WHERE Child_Sports_Health__c IN :testChildren];
        
        System.assertEquals(0, createdCases.size(), 'No cases should be created for non-Extremely Low ratings');
    }
    
    /**
     * Test: Verify that duplicate Cases are not created
     */
    @isTest
    static void testNoDuplicateCases() {
        // Create test child with Extremely Low rating
        Child_Sports_Health__c testChild = new Child_Sports_Health__c(
            Child_First_Name__c = 'Emily',
            Child_Last_Name__c = 'Davis',
            Parent_First_Name__c = 'Michael',
            Parent_Last_Name__c = 'Davis',
            Parent_Phone__c = '5551239999',
            Activity_Rating__c = 'Extremely Low',
            Sports__c = 'Soccer'
        );
        insert testChild;
        
        // Verify first case was created
        List<Case> firstCases = [SELECT Id FROM Case WHERE Child_Sports_Health__c = :testChild.Id];
        System.assertEquals(1, firstCases.size(), 'First case should be created');
        
        // Update the record again (not changing activity rating)
        Test.startTest();
        testChild.Parent_Phone__c = '5551238888';
        update testChild;
        Test.stopTest();
        
        // Verify no duplicate case was created
        List<Case> allCases = [SELECT Id FROM Case WHERE Child_Sports_Health__c = :testChild.Id];
        System.assertEquals(1, allCases.size(), 'Should still have only one case, no duplicates');
    }
    
    /**
     * Test: Bulk insert scenario - verify Cases created for multiple children
     */
    @isTest
    static void testBulkInsert_MultipleLowActivity() {
        // Create multiple test children with Extremely Low activity
        List<Child_Sports_Health__c> testChildren = new List<Child_Sports_Health__c>();
        
        for(Integer i = 1; i <= 10; i++) {
            testChildren.add(new Child_Sports_Health__c(
                Child_First_Name__c = 'Child' + i,
                Child_Last_Name__c = 'Test' + i,
                Parent_First_Name__c = 'Parent' + i,
                Parent_Last_Name__c = 'Test' + i,
                Parent_Phone__c = '555000000' + i,
                Activity_Rating__c = 'Extremely Low',
                Sports__c = 'Soccer'
            ));
        }
        
        Test.startTest();
        insert testChildren;
        Test.stopTest();
        
        // Verify 10 Cases were created
        List<Case> createdCases = [SELECT Id FROM Case 
                                   WHERE Child_Sports_Health__c IN :testChildren];
        
        System.assertEquals(10, createdCases.size(), 'Should create 10 cases for 10 children with low activity');
    }
    
    /**
     * Test: Direct helper method call
     */
    @isTest
    static void testHelperMethod_DirectCall() {
        // Create test child record
        Child_Sports_Health__c testChild = new Child_Sports_Health__c(
            Child_First_Name__c = 'Direct',
            Child_Last_Name__c = 'Test',
            Parent_First_Name__c = 'Parent',
            Parent_Last_Name__c = 'Test',
            Activity_Rating__c = 'Extremely Low',
            Sports__c = 'Baseball'
        );
        insert testChild;
        
        // Reload with all fields
        testChild = [SELECT Id, Child_First_Name__c, Child_Last_Name__c, 
                     Parent_First_Name__c, Parent_Last_Name__c, Parent_Phone__c,
                     Activity_Rating__c, Sports__c
                     FROM Child_Sports_Health__c 
                     WHERE Id = :testChild.Id];
        
        // Delete any cases that might have been created by trigger
        delete [SELECT Id FROM Case WHERE Child_Sports_Health__c = :testChild.Id];
        
        // Call helper method directly
        Test.startTest();
        CaseCreationHelper.createLowActivityCases(new List<Child_Sports_Health__c>{testChild});
        Test.stopTest();
        
        // Verify Case was created
        List<Case> createdCases = [SELECT Id FROM Case WHERE Child_Sports_Health__c = :testChild.Id];
        System.assertEquals(1, createdCases.size(), 'Helper method should create one case');
    }
}