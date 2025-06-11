trigger ProjectScoreWeightedScoreTrigger on Project_Score__c (before insert, before update) {
    for(Project_Score__c score : Trigger.new) {
        // Validate Score range
        if(score.Score__c != null && (score.Score__c < 0 || score.Score__c > 100)) {
            score.addError('Score must be between 0 and 100');
            continue;
        }
        
        // Calculate weighted score based on category
               if(score.Score__c != null && score.Category__c != null) {
            Decimal multiplier;
            switch on score.Category__c.toUpperCase() {
                when 'HIGH' {
                    multiplier = 1.5;  
                }
                when 'MEDIUM' {
                    multiplier = 1.0;
                }
                when 'LOW' {
                    multiplier = 0.5;
                }
                when else {
                    score.addError('Invalid category. Must be High, Medium, or Low');
                    continue;
                }
            }
            score.Weighted_Score__c = score.Score__c * multiplier;
        }
    }
}