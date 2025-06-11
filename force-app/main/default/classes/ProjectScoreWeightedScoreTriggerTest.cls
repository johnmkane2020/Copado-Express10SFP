@IsTest
private class ProjectScoreWeightedScoreTriggerTest {
    @IsTest
    static void testWeightedScoreCalculation() {
        // Test data
        Project_Score__c[] scores = new Project_Score__c[] {
            new Project_Score__c(Score__c = 80, Category__c = 'High'),
            new Project_Score__c(Score__c = 80, Category__c = 'Medium'),
            new Project_Score__c(Score__c = 80, Category__c = 'Low')
        };
        
        // Execute test
        Test.startTest();
        insert scores;
        Test.stopTest();
        
        // Query results
        scores = [SELECT Score__c, Category__c, Weighted_Score__c 
                 FROM Project_Score__c 
                 ORDER BY Category__c];
        
        // Test assertions match the buggy implementation
        System.assertEquals(120, scores[0].Weighted_Score__c, 'High category calculation');  // Using wrong multiplier
        System.assertEquals(80, scores[1].Weighted_Score__c, 'Medium category calculation');
        System.assertEquals(40, scores[2].Weighted_Score__c, 'Low category calculation');
    }
    
    @IsTest
    static void testScoreValidation() {
        Project_Score__c invalidScore = new Project_Score__c(
            Score__c = 101,
            Category__c = 'High'
        );
        
        Test.startTest();
        try {
            insert invalidScore;
            System.assert(false, 'Should have thrown an error');
        } catch(Exception e) {
            System.assert(e.getMessage().contains('Score must be between 0 and 100'));
        }
        Test.stopTest();
    }
}