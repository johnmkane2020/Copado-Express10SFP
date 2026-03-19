/**
 * Class: CaseCreationHelper
 * Purpose: Helper class to create Case records for children with low activity ratings
 * User Story: US-0000134
 * Created: 2026-03-18
 * 
 * This class provides methods to automatically generate Cases when children
 * are identified as having extremely low activity levels, enabling health
 * coordinators to provide timely intervention and support.
 */
public class CaseCreationHelper {
    
    /**
     * Creates Case records for children with extremely low activity ratings
     * @param children List of Child_Sports_Health__c records to process
     */
    public static void createLowActivityCases(List<Child_Sports_Health__c> children) {
        
        List<Case> casesToInsert = new List<Case>();
        Set<Id> childRecordIds = new Set<Id>();
        
        // Collect all child record IDs for querying existing cases
        for(Child_Sports_Health__c child : children) {
            childRecordIds.add(child.Id);
        }
        
        // Query existing cases to avoid duplicates
        Map<Id, Case> existingCasesMap = new Map<Id, Case>();
        for(Case existingCase : [SELECT Id, Child_Sports_Health__c 
                                 FROM Case 
                                 WHERE Child_Sports_Health__c IN :childRecordIds
                                 AND Status != 'Closed']) {
            existingCasesMap.put(existingCase.Child_Sports_Health__c, existingCase);
        }
        
        // Process each child record
        for(Child_Sports_Health__c child : children) {
            
            // Log processing details
            System.debug('Processing child record');
            System.debug('Child Name: ' + child.Child_First_Name__c + ' ' + child.Child_Last_Name__c);
            System.debug('Parent Name: ' + child.Parent_First_Name__c + ' ' + child.Parent_Last_Name__c);
            System.debug('Parent Phone: ' + child.Parent_Phone__c);
            System.debug('Activity Rating: ' + child.Activity_Rating__c);
            System.debug('Record ID: ' + child.Id);
            
            // Skip if case already exists for this child
            if(existingCasesMap.containsKey(child.Id)) {
                System.debug('Case already exists for child: ' + child.Child_First_Name__c);
                continue;
            }
            
            // Create new Case record with appropriate details
            Case newCase = new Case();
            newCase.Subject = 'Low Activity Alert: ' + child.Child_First_Name__c + ' ' + child.Child_Last_Name__c;
            newCase.Description = buildCaseDescription(child);
            newCase.Status = 'New';
            newCase.Priority = 'High';
            newCase.Origin = 'Automated Alert';
            newCase.Type = 'Health & Wellness';
            newCase.Child_Sports_Health__c = child.Id;
            
            System.debug('Creating case with subject: ' + newCase.Subject);
            System.debug('Case includes parent contact: ' + child.Parent_Phone__c);
            
            casesToInsert.add(newCase);
        }
        
        // Insert all new cases
        if(!casesToInsert.isEmpty()) {
            System.debug('Inserting ' + casesToInsert.size() + ' new cases');
            insert casesToInsert;
            System.debug('Cases inserted successfully');
        } else {
            System.debug('No new cases to insert');
        }
    }
    
    /**
     * Builds the case description with child and parent information
     * @param child Child_Sports_Health__c record
     * @return Formatted description string
     */
    private static String buildCaseDescription(Child_Sports_Health__c child) {
        String description = 'ALERT: Child has been flagged with an "Extremely Low" activity rating.\n\n';
        description += 'Child Information:\n';
        description += '- Name: ' + child.Child_First_Name__c + ' ' + child.Child_Last_Name__c + '\n';
        description += '- Activity Rating: ' + child.Activity_Rating__c + '\n';
        
        if(child.Sports__c != null) {
            description += '- Sports: ' + child.Sports__c + '\n';
        }
        
        description += '\nParent/Guardian Contact:\n';
        description += '- Name: ' + child.Parent_First_Name__c + ' ' + child.Parent_Last_Name__c + '\n';
        
        if(child.Parent_Phone__c != null) {
            description += '- Phone: ' + child.Parent_Phone__c + '\n';
        }
        
        description += '\nAction Required:\n';
        description += 'Please contact the parent/guardian to discuss activity level concerns and ';
        description += 'provide recommendations for increasing the child\'s physical activity.';
        
        return description;
    }
}