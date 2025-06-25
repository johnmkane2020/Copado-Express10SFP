@isTest
private class ProjectScoreWeightedScoreTriggerTest {
    
    @isTest
    static void testHighCategoryMultiplier() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test High Category',
            Category__c = 'High',
            Score__c = 100
        );
        
        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();
        
        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];
        
        // Verify the weighted score is calculated correctly (100 * 1.5 = 150)
        System.assertEquals(150, tracker.Weighted_Score__c, 'Weighted score should be 150 for High category');
    }
    
    @isTest
    static void testMediumCategoryMultiplier() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test Medium Category',
            Category__c = 'Medium',
            Score__c = 100
        );
        
        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();
        
        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];
        
        // Verify the weighted score is calculated correctly (100 * 1.0 = 100)
        System.assertEquals(100, tracker.Weighted_Score__c, 'Weighted score should be 100 for Medium category');
    }
    
    @isTest
    static void testLowCategoryMultiplier() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test Low Category',
            Category__c = 'Low',
            Score__c = 100
        );
        
        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();
        
        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];
        
        // Verify the weighted score is calculated correctly (100 * 0.5 = 50)
        System.assertEquals(50, tracker.Weighted_Score__c, 'Weighted score should be 50 for Low category');
    }
    
    @isTest
    static void testNoCategoryMultiplier() {
        // Create test data with no category
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test No Category',
            Score__c = 100
        );
        
        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();
        
        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];
        
        // Verify the weighted score is calculated correctly (100 * 1.0 = 100, default with no multiplier)
        System.assertEquals(100, tracker.Weighted_Score__c, 'Weighted score should be 100 for no category');
    }
    
    @isTest
    static void testUpdateRecord() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test Update',
            Category__c = 'Low',
            Score__c = 100
        );
        
        // Insert the record
        insert tracker;
        
        // Update the record to change category
        tracker.Category__c = 'High';
        
        Test.startTest();
        update tracker;
        Test.stopTest();
        
        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];
        
        // Verify the weighted score is updated correctly (100 * 1.5 = 150)
        System.assertEquals(150, tracker.Weighted_Score__c, 'Weighted score should be updated to 150 after changing to High category');
    }
    
    @isTest
    static void testBulkInsert() {
        // Create a list of 200 records with different categories
        List<Project_Score_Tracker__c> trackers = new List<Project_Score_Tracker__c>();
        
        for (Integer i = 0; i < 200; i++) {
            String category;
            if (Math.mod(i, 3) == 0) {
                category = 'High';
            } else if (Math.mod(i, 3) == 1) {
                category = 'Medium';
            } else {
                category = 'Low';
            }
            
            trackers.add(new Project_Score_Tracker__c(
                Name = 'Bulk Test ' + i,
                Category__c = category,
                Score__c = 100
            ));
        }
        
        // Insert the records in bulk
        Test.startTest();
        insert trackers;
        Test.stopTest();
        
        // Query the records to verify the weighted scores
        List<Project_Score_Tracker__c> insertedTrackers = [
            SELECT Category__c, Score__c, Weighted_Score__c 
            FROM Project_Score_Tracker__c 
            WHERE Name LIKE 'Bulk Test%'
        ];
        
        // Verify each record has the correct weighted score
        for (Project_Score_Tracker__c tracker : insertedTrackers) {
            if (tracker.Category__c == 'High') {
                System.assertEquals(150, tracker.Weighted_Score__c, 'Weighted score should be 150 for High category');
            } else if (tracker.Category__c == 'Medium') {
                System.assertEquals(100, tracker.Weighted_Score__c, 'Weighted score should be 100 for Medium category');
            } else if (tracker.Category__c == 'Low') {
                System.assertEquals(50, tracker.Weighted_Score__c, 'Weighted score should be 50 for Low category');
            }
        }
    }
}