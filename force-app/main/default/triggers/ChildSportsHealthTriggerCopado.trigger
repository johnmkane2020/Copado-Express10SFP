trigger ChildSportsHealthTriggerCopado on Child_Sports_Health__c (before insert, before update) {
    // Validates phone numbers before records are saved
    for(Child_Sports_Health__c record : Trigger.new) {
        if(String.isNotBlank(record.Parent_Phone__c)) {
            String phoneRegex = '^\\+?[0-9-().\\s]+$';
            if (!Pattern.matches(phoneRegex, record.Parent_Phone__c)) {
                record.Parent_Phone__c.addError('Please enter a valid phone number');
            }
        }
    }
}