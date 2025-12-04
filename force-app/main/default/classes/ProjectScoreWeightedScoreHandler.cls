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
                // Skip if Score is invalid (null, negative, or over 100)
                if (!isValidScore(record.Score__c)) {
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
     * Validates that a score is within the acceptable range
     * @param score The score value to validate
     * @return Boolean True if score is valid (not null, >= 0, and <= 100), false otherwise
     */
    public static Boolean isValidScore(Decimal score) {
        return score != null && score >= 0 && score <= 100;
    }
}