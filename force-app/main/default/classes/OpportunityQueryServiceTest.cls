/**
 * @description Comprehensive test class for OpportunityQueryService.
 *              Covers all @InvocableMethod entry points, positive/negative/edge cases.
 *              Target coverage: ≥85%
 * @author      Copado AI Agent
 * @date        2026-04-24
 */
@IsTest
private class OpportunityQueryServiceTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Test Data Setup
    // ─────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account Corp');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();

        // Open opportunities — future close dates
        opps.add(new Opportunity(
            Name        = 'Opp Prospecting',
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addDays(30),
            Amount      = 10000,
            Probability = 10,
            AccountId   = acc.Id
        ));
        opps.add(new Opportunity(
            Name        = 'Opp Qualification',
            StageName   = 'Qualification',
            CloseDate   = Date.today().addDays(60),
            Amount      = 25000,
            Probability = 20,
            AccountId   = acc.Id
        ));
        opps.add(new Opportunity(
            Name        = 'Opp Negotiation',
            StageName   = 'Negotiation/Review',
            CloseDate   = Date.today().addDays(15),
            Amount      = 75000,
            Probability = 80,
            AccountId   = acc.Id
        ));
        opps.add(new Opportunity(
            Name        = 'Opp High Value',
            StageName   = 'Value Proposition',
            CloseDate   = Date.today().addDays(45),
            Amount      = 150000,
            Probability = 50,
            AccountId   = acc.Id
        ));

        // At-risk opportunities — past close date, not closed
        opps.add(new Opportunity(
            Name        = 'Opp At Risk',
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addDays(-10),
            Amount      = 50000,
            Probability = 30,
            AccountId   = acc.Id
        ));
        opps.add(new Opportunity(
            Name        = 'Opp Very Overdue',
            StageName   = 'Qualification',
            CloseDate   = Date.today().addDays(-30),
            Amount      = 20000,
            Probability = 15,
            AccountId   = acc.Id
        ));

        insert opps;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryService.OpportunityQueryRequest buildRequest(String queryType) {
        OpportunityQueryService.OpportunityQueryRequest req = new OpportunityQueryService.OpportunityQueryRequest();
        req.queryType = queryType;
        return req;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. PIPELINE_TOTALS
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testPipelineTotals_positive() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ buildRequest('PIPELINE_TOTALS') }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assert(responses[0].success, 'Response should be successful');
        System.assertNotEquals(null, responses[0].totalPipelineValue, 'Total pipeline value should not be null');
        System.assert(responses[0].opportunityCount > 0, 'Should have opportunities');
    }

    @IsTest
    static void testPipelineTotals_withFiscalQuarter() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('PIPELINE_TOTALS');
        req.fiscalQuarterStart = Date.today();
        req.fiscalQuarterEnd   = Date.today().addDays(90);
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Should succeed with fiscal quarter filter');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. SEGMENTATION
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testSegmentation_byStage() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('SEGMENTATION');
        req.stageFilter = 'Prospecting';
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Segmentation by stage should succeed');
    }

    @IsTest
    static void testSegmentation_byAmountRange() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('SEGMENTATION');
        req.minAmount = 20000;
        req.maxAmount = 100000;
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Segmentation by amount range should succeed');
    }

    @IsTest
    static void testSegmentation_byCloseDateRange() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('SEGMENTATION');
        req.closeDateStart = Date.today();
        req.closeDateEnd   = Date.today().addDays(60);
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Segmentation by close date range should succeed');
    }

    @IsTest
    static void testSegmentation_noFilters() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ buildRequest('SEGMENTATION') }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'Segmentation with no filters should succeed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. AT_RISK
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testAtRisk_positive() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ buildRequest('AT_RISK') }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'AT_RISK query should succeed');
        System.assert(responses[0].opportunityCount >= 2, 'Should find at least 2 at-risk opportunities');
        System.assert(responses[0].opportunitiesJson.contains('OverdueDays'), 'Response should include OverdueDays');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. DEEP_DIVE
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testDeepDive_positive() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Opp Prospecting' LIMIT 1];

        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('DEEP_DIVE');
        req.opportunityId = opp.Id;
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'DEEP_DIVE should succeed for valid Id');
        System.assert(responses[0].opportunitiesJson.contains('IsAtRisk'), 'Should include IsAtRisk flag');
        System.assertEquals(1, responses[0].opportunityCount, 'Should return exactly 1 record');
    }

    @IsTest
    static void testDeepDive_atRiskFlag() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Opp At Risk' LIMIT 1];

        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('DEEP_DIVE');
        req.opportunityId = opp.Id;
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assert(responses[0].success, 'Should succeed');
        System.assert(responses[0].opportunitiesJson.contains('"IsAtRisk":true'), 'At-risk opp should have IsAtRisk=true');
    }

    @IsTest
    static void testDeepDive_blankId() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('DEEP_DIVE');
        req.opportunityId = '';
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(!responses[0].success, 'Should fail for blank opportunityId');
        System.assertNotEquals(null, responses[0].errorMessage, 'Should have error message');
    }

    @IsTest
    static void testDeepDive_notFound() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('DEEP_DIVE');
        req.opportunityId = '0061000000000001AAA';
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0], 'Response should not be null');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. TOP_N
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testTopN_byAmount() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('TOP_N');
        req.topN   = 3;
        req.rankBy = 'AMOUNT';
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'TOP_N by Amount should succeed');
        System.assert(responses[0].opportunityCount <= 3, 'Should return at most 3 records');
    }

    @IsTest
    static void testTopN_byProbability() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = buildRequest('TOP_N');
        req.topN   = 5;
        req.rankBy = 'PROBABILITY';
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'TOP_N by Probability should succeed');
    }

    @IsTest
    static void testTopN_defaultN() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ buildRequest('TOP_N') }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(responses[0].success, 'TOP_N with default N should succeed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Edge Cases & Negative Tests
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void testNullRequestList() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(null);
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one error response for null input');
        System.assert(!responses[0].success, 'Should not succeed for null input');
        System.assertEquals('[]', responses[0].opportunitiesJson, 'Should return empty JSON array');
    }

    @IsTest
    static void testEmptyRequestList() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>()
            );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return one error response for empty list');
        System.assert(!responses[0].success, 'Should not succeed for empty list');
    }

    @IsTest
    static void testUnknownQueryType() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ buildRequest('INVALID_TYPE') }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(!responses[0].success, 'Should fail for unknown query type');
        System.assert(responses[0].errorMessage.contains('Unknown queryType'), 'Error message should mention unknown queryType');
    }

    @IsTest
    static void testNullQueryType() {
        Test.startTest();
        OpportunityQueryService.OpportunityQueryRequest req = new OpportunityQueryService.OpportunityQueryRequest();
        req.queryType = null;
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(
                new List<OpportunityQueryService.OpportunityQueryRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assert(!responses[0].success, 'Should fail for null queryType');
    }

    @IsTest
    static void testBulkRequests() {
        Test.startTest();
        List<OpportunityQueryService.OpportunityQueryRequest> requests = new List<OpportunityQueryService.OpportunityQueryRequest>();
        requests.add(buildRequest('PIPELINE_TOTALS'));
        requests.add(buildRequest('AT_RISK'));
        requests.add(buildRequest('SEGMENTATION'));
        List<OpportunityQueryService.OpportunityQueryResponse> responses =
            OpportunityQueryService.queryOpportunities(requests);
        Test.stopTest();

        System.assertEquals(3, responses.size(), 'Should return 3 responses for 3 requests');
        for (OpportunityQueryService.OpportunityQueryResponse resp : responses) {
            System.assert(resp.success, 'All bulk requests should succeed');
        }
    }
}