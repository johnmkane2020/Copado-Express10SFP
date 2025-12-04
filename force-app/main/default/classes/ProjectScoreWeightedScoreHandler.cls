public class ProjectScoreWeightedScoreHandler {

    // Flag to prevent recursive trigger execution
    private static Boolean isExecuting = false;

    /**
     * Main method to handle the trigger logic
     * @param newRecords List of new Project Score Tracker records
     */
    public static void calculateWeightedScore(List<Project_Score_Tracker__c> newRecords) {
        // Prevent recursive execution. This is an update
        if (isExecuting) {
            return;
        }

        isExecuting = true;

        try {
            for (Project_Score_Tracker__c record : newRecords) {
                // Skip if Score is null
                if (record.Score__c == null) {
                    continue;
                }

                // Apply multiplier based on Category
                if (record.Category__c == 'High') {
                    record.Weighted_Score__c = record.Score__c * 1.5;
                } else if (record.Category__c == 'Medium') {
                    record.Weighted_Score__c = record.Score__c * 1.0;
                } else if (record.Category__c == 'Low') {
                    record.Weighted_Score__c = record.Score__c * 0.5;
                } else {
                    // If no category is selected, default to no multiplier
                    record.Weighted_Score__c = record.Score__c;
                }
            }
        } finally {
            isExecuting = false;
        }
    }

    /**
     * Calculates aggregate statistics for weighted scores across multiple Project Score Tracker records.
     * This method analyzes a collection of records and computes key statistical measures including
     * average, maximum, minimum, and total of the Weighted_Score__c field.
     * 
     * @param records List of Project_Score_Tracker__c records to analyze
     * @return Map<String, Decimal> containing statistical values with the following keys:
     *         - 'average': The mean of all weighted scores
     *         - 'max': The highest weighted score in the collection
     *         - 'min': The lowest weighted score in the collection
     *         - 'total': The sum of all weighted scores
     *         Returns an empty map if the input list is null or empty.
     *         Records with null Weighted_Score__c values are excluded from calculations.
     * 
     * @example
     * List<Project_Score_Tracker__c> trackers = [SELECT Weighted_Score__c FROM Project_Score_Tracker__c];
     * Map<String, Decimal> stats = ProjectScoreWeightedScoreHandler.calculateScoreStatistics(trackers);
     * Decimal avgScore = stats.get('average');
     */
    public static Map<String, Decimal> calculateScoreStatistics(List<Project_Score_Tracker__c> records) {
        // Initialize result map
        Map<String, Decimal> statistics = new Map<String, Decimal>();
        
        // Return empty map if input is null or empty
        if (records == null || records.isEmpty()) {
            return statistics;
        }
        
        // Initialize tracking variables
        Decimal total = 0;
        Integer count = 0;
        Decimal maxValue = null;
        Decimal minValue = null;
        
        // Iterate through records to calculate statistics
        for (Project_Score_Tracker__c record : records) {
            // Skip records with null Weighted_Score__c
            if (record.Weighted_Score__c == null) {
                continue;
            }
            
            Decimal currentScore = record.Weighted_Score__c;
            
            // Add to total and increment count
            total += currentScore;
            count++;
            
            // Update max value
            maxValue = (maxValue == null) ? currentScore : Math.max(maxValue, currentScore);
            
            // Update min value
            minValue = (minValue == null) ? currentScore : Math.min(minValue, currentScore);
        }
        
        // Populate statistics map
        if (count > 0) {
            statistics.put('average', total / count);
            statistics.put('max', maxValue);
            statistics.put('min', minValue);
            statistics.put('total', total);
        } else {
            // No valid records found - return defaults
            statistics.put('average', 0);
            statistics.put('max', 0);
            statistics.put('min', 0);
            statistics.put('total', 0);
        }
        
        return statistics;
    }
}