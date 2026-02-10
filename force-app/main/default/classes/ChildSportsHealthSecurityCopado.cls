public without sharing class ChildSportsHealthSecurityCopado {
    public static void validateAccess(List<Child_Sports_Health__c> records) {
        // Checks object-level permissions
        if(!Schema.sObjectType.Child_Sports_Health__c.isUpdateable() || 
           !Schema.sObjectType.Child_Sports_Health__c.isCreateable()) {
            throw new SecurityException('Insufficient access rights');
        }
        
        // Checks field-level permissions
        Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Child_Sports_Health__c.fields.getMap();
        String[] fieldsToCheck = new String[]{
            'Child_Name__c',
            'Parent_Name__c',
            'Parent_Phone__c',  // Changed from Parent_Contact__c
            'Sports__c'
        };
        
        for(String fieldName : fieldsToCheck) {
            if(!fieldMap.get(fieldName).getDescribe().isAccessible()) {
                throw new SecurityException('Insufficient field level access: ' + fieldName);
            }
        }
    }
}