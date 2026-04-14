/**
 * @description Unit tests for StudentEmailValidator.
 *              Covers: duplicate detection, non-duplicate, null/blank input,
 *              and bulkification. Minimum coverage target: 75% (US-0000165).
 */
@IsTest
private class StudentEmailValidatorTest {

    // ─── Test Data Setup ────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        Student__c existing = new Student__c(
            First_Name__c   = 'Jane',
            Last_Name__c    = 'Doe',
            Email__c        = 'jane.doe@test.com',
            Date_of_Birth__c = Date.newInstance(2000, 1, 15),
            Grade_Level__c  = 'Undergraduate',
            School_Name__c  = 'Test University',
            Is_Active__c    = true,
            Academic_Status__c = 'Active',
            Enrollment_Date__c = Date.today()
        );
        insert existing;
    }

    // ─── Test: Duplicate Email ───────────────────────────────────────────────

    @IsTest
    static void testDuplicateEmail() {
        StudentEmailValidator.Request req = new StudentEmailValidator.Request();
        req.email = 'jane.doe@test.com'; // already exists

        Test.startTest();
        List<StudentEmailValidator.Result> results =
            StudentEmailValidator.validateEmail(new List<StudentEmailValidator.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        System.assertEquals(true, results[0].isDuplicate, 'Should detect duplicate email');
        System.assertNotEquals(null, results[0].errorMessage, 'Error message should be populated');
        System.assert(
            results[0].errorMessage.contains('jane.doe@test.com'),
            'Error message should contain the duplicate email address'
        );
    }

    // ─── Test: Duplicate Email (case-insensitive) ────────────────────────────

    @IsTest
    static void testDuplicateEmailCaseInsensitive() {
        StudentEmailValidator.Request req = new StudentEmailValidator.Request();
        req.email = 'JANE.DOE@TEST.COM'; // same email, different case

        Test.startTest();
        List<StudentEmailValidator.Result> results =
            StudentEmailValidator.validateEmail(new List<StudentEmailValidator.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].isDuplicate, 'Duplicate check must be case-insensitive');
    }

    // ─── Test: Unique Email ──────────────────────────────────────────────────

    @IsTest
    static void testUniqueEmail() {
        StudentEmailValidator.Request req = new StudentEmailValidator.Request();
        req.email = 'new.student@test.com'; // does not exist

        Test.startTest();
        List<StudentEmailValidator.Result> results =
            StudentEmailValidator.validateEmail(new List<StudentEmailValidator.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return exactly one result');
        System.assertEquals(false, results[0].isDuplicate, 'Should not flag a unique email as duplicate');
        System.assertEquals(null, results[0].errorMessage, 'Error message should be null for unique email');
    }

    // ─── Test: Null Email Input ──────────────────────────────────────────────

    @IsTest
    static void testNullEmail() {
        StudentEmailValidator.Request req = new StudentEmailValidator.Request();
        req.email = null;

        Test.startTest();
        List<StudentEmailValidator.Result> results =
            StudentEmailValidator.validateEmail(new List<StudentEmailValidator.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].isDuplicate, 'Null email should not be flagged as duplicate');
        System.assertEquals(null, results[0].errorMessage, 'Error message should be null for null input');
    }

    // ─── Test: Blank Email Input ─────────────────────────────────────────────

    @IsTest
    static void testBlankEmail() {
        StudentEmailValidator.Request req = new StudentEmailValidator.Request();
        req.email = '   '; // whitespace only

        Test.startTest();
        List<StudentEmailValidator.Result> results =
            StudentEmailValidator.validateEmail(new List<StudentEmailValidator.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].isDuplicate, 'Blank email should not be flagged as duplicate');
    }

    // ─── Test: Bulkification (multiple requests) ─────────────────────────────

    @IsTest
    static void testBulkRequests() {
        List<StudentEmailValidator.Request> requests = new List<StudentEmailValidator.Request>();

        // Request 1 — duplicate
        StudentEmailValidator.Request req1 = new StudentEmailValidator.Request();
        req1.email = 'jane.doe@test.com';
        requests.add(req1);

        // Request 2 — unique
        StudentEmailValidator.Request req2 = new StudentEmailValidator.Request();
        req2.email = 'another.student@test.com';
        requests.add(req2);

        // Request 3 — null
        StudentEmailValidator.Request req3 = new StudentEmailValidator.Request();
        req3.email = null;
        requests.add(req3);

        Test.startTest();
        List<StudentEmailValidator.Result> results =
            StudentEmailValidator.validateEmail(requests);
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return one result per request');
        System.assertEquals(true,  results[0].isDuplicate, 'Request 1 should be duplicate');
        System.assertEquals(false, results[1].isDuplicate, 'Request 2 should be unique');
        System.assertEquals(false, results[2].isDuplicate, 'Request 3 (null) should not be duplicate');
    }
}