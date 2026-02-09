public with sharing class ChildSportsHealthControllerCopado {
    @AuraEnabled(cacheable=true)
    public static List<Child_Sports_Health__c> getRecords() {
        try {
            ChildSportsHealthSecurityCopado.validateAccess(new List<Child_Sports_Health__c>());
            return [SELECT Id, Child_Name__c, Parent_Name__c, Parent_Phone__c, Sports__c, Activity_Rating__c
                   FROM Child_Sports_Health__c
                   ORDER BY Child_Name__c
                   LIMIT 1000];
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in ChildSportsHealthController: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while retrieving records.');
        }
    }

    @AuraEnabled
    public static Child_Sports_Health__c saveRecord(Child_Sports_Health__c record) {
        try {
            ChildSportsHealthSecurityCopado.validateAccess(new List<Child_Sports_Health__c>{record});
            upsert record;
            // Re-query to get the updated record with all fields
            return [SELECT Id, Child_Name__c, Parent_Name__c, Parent_Phone__c, Sports__c, Activity_Rating__c
                   FROM Child_Sports_Health__c
                   WHERE Id = :record.Id
                   LIMIT 1];
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error saving record: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while saving the record: ' + e.getMessage());
        }
    }
}