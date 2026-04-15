/**
 * @description Invocable Apex action used by Register_Student_Flow to validate
 *              email uniqueness against existing Student__c records.
 *              Bulkification-safe and null-input-safe.
 */
public with sharing class StudentEmailValidator {

    /**
     * @description Input parameters accepted from the Flow Action element.
     */
    public class Request {
        @InvocableVariable(label='Email Address' description='Email to validate for uniqueness' required=true)
        public String email;
    }

    /**
     * @description Output parameters returned to the Flow Decision element.
     */
    public class Result {
        @InvocableVariable(label='Is Duplicate' description='True if the email already exists on another Student record')
        public Boolean isDuplicate;

        @InvocableVariable(label='Error Message' description='User-friendly error message when a duplicate is found')
        public String errorMessage;
    }

    /**
     * @description Invocable method called by Register_Student_Flow to check
     *              whether the provided email already exists on a Student__c record.
     * @param  requests List of Request objects (one per flow invocation)
     * @return          List of Result objects with isDuplicate flag and errorMessage
     */
    @InvocableMethod(
        label='Validate Student Email Uniqueness'
        description='Checks if the provided email already exists on a Student__c record. Returns isDuplicate and errorMessage.'
        category='Student'
    )
    public static List<Result> validateEmail(List<Request> requests) {
        List<Result> results = new List<Result>();

        // Collect all emails to query in a single SOQL call (bulkification-safe)
        Set<String> emailsToCheck = new Set<String>();
        for (Request req : requests) {
            if (String.isNotBlank(req.email)) {
                emailsToCheck.add(req.email.trim().toLowerCase());
            }
        }

        // Query existing Student__c records with matching emails
        Map<String, Student__c> existingByEmail = new Map<String, Student__c>();
        if (!emailsToCheck.isEmpty()) {
            for (Student__c s : [
                SELECT Id, Email__c
                FROM Student__c
                WHERE Email__c IN :emailsToCheck
                WITH SECURITY_ENFORCED
                LIMIT 1000
            ]) {
                if (String.isNotBlank(s.Email__c)) {
                    existingByEmail.put(s.Email__c.trim().toLowerCase(), s);
                }
            }
        }

        // Build results for each request
        for (Request req : requests) {
            Result res = new Result();

            if (String.isBlank(req.email)) {
                // Null / blank input — treat as not duplicate; Flow required-field
                // validation should catch this before the action is called
                res.isDuplicate = false;
                res.errorMessage = null;
            } else {
                String normalised = req.email.trim().toLowerCase();
                if (existingByEmail.containsKey(normalised)) {
                    res.isDuplicate = true;
                    res.errorMessage = 'A student with the email address \'' + req.email.trim()
                        + '\' is already registered. Please use a different email address.';
                } else {
                    res.isDuplicate = false;
                    res.errorMessage = null;
                }
            }

            results.add(res);
        }

        return results;
    }
}