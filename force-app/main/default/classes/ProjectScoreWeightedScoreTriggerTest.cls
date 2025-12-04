@isTest
private class ProjectScoreWeightedScoreTriggerTest {

    @isTest
    static void testHighCategoryMultiplier() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test High Category',
            Category__c = 'High',
            Score__c = 80
        );

        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();

        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];

        // Verify the weighted score is calculated correctly (80 * 1.5 = 120)
        System.assertEquals(120, tracker.Weighted_Score__c, 'Weighted score should be 120 for High category');
    }

    @isTest
    static void testMediumCategoryMultiplier() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test Medium Category',
            Category__c = 'Medium',
            Score__c = 80
        );

        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();

        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];

        // Verify the weighted score is calculated correctly (80 * 1.0 = 80)
        System.assertEquals(80, tracker.Weighted_Score__c, 'Weighted score should be 80 for Medium category');
    }

    @isTest
    static void testLowCategoryMultiplier() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test Low Category',
            Category__c = 'Low',
            Score__c = 80
        );

        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();

        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];

        // Verify the weighted score is calculated correctly (80 * 0.5 = 40)
        System.assertEquals(40, tracker.Weighted_Score__c, 'Weighted score should be 40 for Low category');
    }

    @isTest
    static void testNoCategoryMultiplier() {
        // Create test data with no category
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test No Category',
            Score__c = 80
        );

        // Insert the record to trigger the calculation
        Test.startTest();
        insert tracker;
        Test.stopTest();

        // Query the record to verify the weighted score
        tracker = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c WHERE Id = :tracker.Id];

        // Verify the weighted score is calculated correctly (80 * 1.0 = 80, default with no multiplier)
        System.assertEquals(80, tracker.Weighted_Score__c, 'Weighted score should be 80 for no category');
    }

    @isTest
    static void testUpdateRecord() {
        // Create test data
        Project_Score_Tracker__c tracker = new Project_Score_Tracker__c(
            Name = 'Test Update',
            Category__c = 'Low',
            Score__c = 60
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

        // Verify the weighted score is updated correctly (60 * 1.5 = 90)
        System.assertEquals(90, tracker.Weighted_Score__c, 'Weighted score should be updated to 90 after changing to High category');
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
                Score__c = 60
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
                System.assertEquals(90, tracker.Weighted_Score__c, 'Weighted score should be 90 for High category');
            } else if (tracker.Category__c == 'Medium') {
                System.assertEquals(60, tracker.Weighted_Score__c, 'Weighted score should be 60 for Medium category');
            } else if (tracker.Category__c == 'Low') {
                System.assertEquals(30, tracker.Weighted_Score__c, 'Weighted score should be 30 for Low category');
            }
        }
    }

    // ==================== NEW TESTS FOR US-0000079 ====================

    @isTest
    static void testCalculateStatisticsNormalCase() {
        // Create test data with multiple records
        List<Project_Score_Tracker__c> trackers = new List<Project_Score_Tracker__c>{
            new Project_Score_Tracker__c(
                Name = 'Stats Test 1',
                Category__c = 'High',
                Score__c = 60,
                Weighted_Score__c = 90
            ),
            new Project_Score_Tracker__c(
                Name = 'Stats Test 2',
                Category__c = 'Medium',
                Score__c = 50,
                Weighted_Score__c = 50
            ),
            new Project_Score_Tracker__c(
                Name = 'Stats Test 3',
                Category__c = 'Low',
                Score__c = 40,
                Weighted_Score__c = 20
            ),
            new Project_Score_Tracker__c(
                Name = 'Stats Test 4',
                Category__c = 'High',
                Score__c = 80,
                Weighted_Score__c = 120
            )
        };

        Test.startTest();
        Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(trackers);
        Test.stopTest();

        // Verify all expected keys are present
        System.assert(stats.containsKey('average'), 'Statistics map should contain average key');
        System.assert(stats.containsKey('max'), 'Statistics map should contain max key');
        System.assert(stats.containsKey('min'), 'Statistics map should contain min key');
        System.assert(stats.containsKey('total'), 'Statistics map should contain total key');

        // Verify calculated values
        // Total: 90 + 50 + 20 + 120 = 280
        // Average: 280 / 4 = 70
        // Max: 120
        // Min: 20
        System.assertEquals(280, stats.get('total'), 'Total should be 280');
        System.assertEquals(70, stats.get('average'), 'Average should be 70');
        System.assertEquals(120, stats.get('max'), 'Max should be 120');
        System.assertEquals(20, stats.get('min'), 'Min should be 20');
    }

    @isTest
    static void testCalculateStatisticsEmptyList() {
        // Test with empty list
        List<Project_Score_Tracker__c> emptyList = new List<Project_Score_Tracker__c>();

        Test.startTest();
        Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(emptyList);
        Test.stopTest();

        // Verify empty map is returned
        System.assertEquals(0, stats.size(), 'Statistics map should be empty for empty list');
    }

    @isTest
    static void testCalculateStatisticsWithNulls() {
        // Create test data with some null weighted scores
        List<Project_Score_Tracker__c> trackers = new List<Project_Score_Tracker__c>{
            new Project_Score_Tracker__c(
                Name = 'Stats Null Test 1',
                Category__c = 'High',
                Score__c = 60,
                Weighted_Score__c = 90
            ),
            new Project_Score_Tracker__c(
                Name = 'Stats Null Test 2',
                Category__c = 'Medium',
                Score__c = 50,
                Weighted_Score__c = null  // Null weighted score
            ),
            new Project_Score_Tracker__c(
                Name = 'Stats Null Test 3',
                Category__c = 'Low',
                Score__c = 40,
                Weighted_Score__c = 20
            )
        };

        Test.startTest();
        Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(trackers);
        Test.stopTest();

        // Verify statistics calculated only for non-null values
        // Total: 90 + 20 = 110 (ignoring null)
        // Average: 110 / 2 = 55
        // Max: 90
        // Min: 20
        System.assertEquals(110, stats.get('total'), 'Total should be 110 (excluding null)');
        System.assertEquals(55, stats.get('average'), 'Average should be 55 (excluding null)');
        System.assertEquals(90, stats.get('max'), 'Max should be 90');
        System.assertEquals(20, stats.get('min'), 'Min should be 20');
    }

    @isTest
    static void testCalculateStatisticsSingleRecord() {
        // Test with a single record
        List<Project_Score_Tracker__c> trackers = new List<Project_Score_Tracker__c>{
            new Project_Score_Tracker__c(
                Name = 'Stats Single Test',
                Category__c = 'High',
                Score__c = 60,
                Weighted_Score__c = 90
            )
        };

        Test.startTest();
        Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(trackers);
        Test.stopTest();

        // Verify all values equal the single record's weighted score
        System.assertEquals(90, stats.get('total'), 'Total should be 90');
        System.assertEquals(90, stats.get('average'), 'Average should be 90');
        System.assertEquals(90, stats.get('max'), 'Max should be 90');
        System.assertEquals(90, stats.get('min'), 'Min should be 90');
    }

    @isTest
    static void testCalculateStatisticsNullList() {
        // Test with null list
        Test.startTest();
        Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(null);
        Test.stopTest();

        // Verify empty map is returned
        System.assertEquals(0, stats.size(), 'Statistics map should be empty for null list');
    }

    @isTest
    static void testCalculateStatisticsAllNullScores() {
        // Test with all null weighted scores
        List<Project_Score_Tracker__c> trackers = new List<Project_Score_Tracker__c>{
            new Project_Score_Tracker__c(
                Name = 'All Null Test 1',
                Category__c = 'High',
                Score__c = 60,
                Weighted_Score__c = null
            ),
            new Project_Score_Tracker__c(
                Name = 'All Null Test 2',
                Category__c = 'Medium',
                Score__c = 50,
                Weighted_Score__c = null
            )
        };

        Test.startTest();
        Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(trackers);
        Test.stopTest();

        // Verify default values returned when all scores are null
        System.assertEquals(0, stats.get('total'), 'Total should be 0 when all scores are null');
        System.assertEquals(0, stats.get('average'), 'Average should be 0 when all scores are null');
        System.assertEquals(0, stats.get('max'), 'Max should be 0 when all scores are null');
        System.assertEquals(0, stats.get('min'), 'Min should be 0 when all scores are null');
    }
}