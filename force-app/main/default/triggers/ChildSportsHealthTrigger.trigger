/**
 * Trigger: ChildSportsHealthTrigger
 * Purpose: Automatically create Case records when a child's activity rating is "Extremely Low"
 * User Story: US-0000134
 * Created: 2026-03-18
 */
trigger ChildSportsHealthTrigger on Child_Sports_Health__c (after insert, after update) {
    
    List<Child_Sports_Health__c> lowActivityChildren = new List<Child_Sports_Health__c>();
    
    System.debug('ChildSportsHealthTrigger Started');
    System.debug('Processing ' + Trigger.new.size() + ' Child Sports & Health records');
    
    // Iterate through all records to identify children with extremely low activity
    for(Child_Sports_Health__c child : Trigger.new) {
        
        System.debug('Checking child: ' + child.Child_First_Name__c + ' ' + 
                     child.Child_Last_Name__c + ', Parent: ' + 
                     child.Parent_First_Name__c + ' ' + child.Parent_Last_Name__c + 
                     ', Phone: ' + child.Parent_Phone__c);
        
        // Check if this is a new record or if activity rating changed
        if(Trigger.isInsert || 
           (Trigger.isUpdate && 
            child.Activity_Rating__c != Trigger.oldMap.get(child.Id).Activity_Rating__c)) {
            
            // Flag children with extremely low activity for case creation
            if(child.Activity_Rating__c == 'Extremely Low') {
                System.debug('Low activity detected for child: ' + child.Child_First_Name__c);
                lowActivityChildren.add(child);
            }
        }
    }
    
    // Process low activity children through helper class
    if(!lowActivityChildren.isEmpty()) {
        System.debug('Creating cases for ' + lowActivityChildren.size() + ' children with low activity');
        CaseCreationHelper.createLowActivityCases(lowActivityChildren);
    }
    
    System.debug('ChildSportsHealthTrigger Completed');
}