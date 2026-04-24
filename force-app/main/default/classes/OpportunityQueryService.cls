/**
 * @description Bulkified Apex service class for the Opportunity Intelligence Agentforce Agent.
 *              Handles pipeline totals, segmentation, at-risk identification, deep-dive, and Top-N queries.
 *              File: OpportunityQueryService.cls (opportunity-query-service-copado per dev standards)
 *              Error logging: System.debug — swap to Logger.error/Logger.saveLog once Nebula Logger is installed.
 * @author      Copado AI Agent
 * @date        2026-04-24
 */
public with sharing class OpportunityQueryService {

    // ─────────────────────────────────────────────────────────────────────────
    // Inner Request / Response wrappers
    // ─────────────────────────────────────────────────────────────────────────

    public enum QueryType {
        PIPELINE_TOTALS,
        SEGMENTATION,
        AT_RISK,
        DEEP_DIVE,
        TOP_N
    }

    public class OpportunityQueryRequest {
        @InvocableVariable(label='Query Type' description='PIPELINE_TOTALS | SEGMENTATION | AT_RISK | DEEP_DIVE | TOP_N' required=true)
        public String queryType;

        @InvocableVariable(label='Opportunity Id' description='Required for DEEP_DIVE')
        public String opportunityId;

        @InvocableVariable(label='Stage Filter' description='Filter by Stage name')
        public String stageFilter;

        @InvocableVariable(label='Owner Id' description='Filter by Owner Id')
        public String ownerIdFilter;

        @InvocableVariable(label='Region Filter' description='Filter by Region custom field')
        public String regionFilter;

        @InvocableVariable(label='Min Amount' description='Minimum Amount filter')
        public Decimal minAmount;

        @InvocableVariable(label='Max Amount' description='Maximum Amount filter')
        public Decimal maxAmount;

        @InvocableVariable(label='Close Date Start' description='CloseDate range start')
        public Date closeDateStart;

        @InvocableVariable(label='Close Date End' description='CloseDate range end')
        public Date closeDateEnd;

        @InvocableVariable(label='Top N' description='Number of records for TOP_N query')
        public Integer topN;

        @InvocableVariable(label='Rank By' description='AMOUNT or PROBABILITY for TOP_N')
        public String rankBy;

        @InvocableVariable(label='Fiscal Quarter Start' description='Start date of fiscal quarter for PIPELINE_TOTALS')
        public Date fiscalQuarterStart;

        @InvocableVariable(label='Fiscal Quarter End' description='End date of fiscal quarter for PIPELINE_TOTALS')
        public Date fiscalQuarterEnd;
    }

    public class OpportunityQueryResponse {
        @InvocableVariable(label='Result JSON' description='JSON-serialised result payload')
        public String resultJson;

        @InvocableVariable(label='Total Pipeline Value')
        public Decimal totalPipelineValue;

        @InvocableVariable(label='Opportunity Count')
        public Integer opportunityCount;

        @InvocableVariable(label='Average Deal Size')
        public Decimal averageDealSize;

        @InvocableVariable(label='Opportunities JSON' description='JSON list of matching Opportunity records')
        public String opportunitiesJson;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Success')
        public Boolean success;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // @InvocableMethod entry point
    // ─────────────────────────────────────────────────────────────────────────

    @InvocableMethod(label='Query Opportunities' description='Bulkified Opportunity data retrieval for Agentforce Agent')
    public static List<OpportunityQueryResponse> queryOpportunities(List<OpportunityQueryRequest> requests) {
        List<OpportunityQueryResponse> responses = new List<OpportunityQueryResponse>();

        if (requests == null || requests.isEmpty()) {
            logError('queryOpportunities called with null or empty request list');
            OpportunityQueryResponse emptyResponse = new OpportunityQueryResponse();
            emptyResponse.success           = false;
            emptyResponse.errorMessage      = 'Request list is null or empty';
            emptyResponse.opportunitiesJson = '[]';
            responses.add(emptyResponse);
            return responses;
        }

        for (OpportunityQueryRequest req : requests) {
            responses.add(processRequest(req));
        }
        return responses;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private routing method
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryResponse processRequest(OpportunityQueryRequest req) {
        OpportunityQueryResponse response = new OpportunityQueryResponse();
        try {
            if (req == null || String.isBlank(req.queryType)) {
                response.success           = false;
                response.errorMessage      = 'queryType is required';
                response.opportunitiesJson = '[]';
                logError('queryType is null or blank');
                return response;
            }

            String qt = req.queryType.toUpperCase().trim();

            if (qt == QueryType.PIPELINE_TOTALS.name()) {
                response = getPipelineTotals(req);
            } else if (qt == QueryType.SEGMENTATION.name()) {
                response = getSegmentation(req);
            } else if (qt == QueryType.AT_RISK.name()) {
                response = getAtRisk();
            } else if (qt == QueryType.DEEP_DIVE.name()) {
                response = getDeepDive(req);
            } else if (qt == QueryType.TOP_N.name()) {
                response = getTopN(req);
            } else {
                response.success           = false;
                response.errorMessage      = 'Unknown queryType: ' + req.queryType;
                response.opportunitiesJson = '[]';
                logError('Unknown queryType: ' + req.queryType);
            }
        } catch (Exception e) {
            response.success           = false;
            response.errorMessage      = e.getMessage();
            response.opportunitiesJson = '[]';
            logError('processRequest exception: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
        return response;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Pipeline Totals & Aggregations
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryResponse getPipelineTotals(OpportunityQueryRequest req) {
        OpportunityQueryResponse response = new OpportunityQueryResponse();
        try {
            Date qStart = req.fiscalQuarterStart;
            Date qEnd   = req.fiscalQuarterEnd;

            String aggQuery;
            Map<String, Object> bindMap = new Map<String, Object>();

            if (qStart != null && qEnd != null) {
                aggQuery = 'SELECT StageName, SUM(Amount) totalAmount, COUNT(Id) oppCount, AVG(Amount) avgAmount '
                         + 'FROM Opportunity '
                         + 'WHERE IsClosed = false AND CloseDate >= :qStart AND CloseDate <= :qEnd '
                         + 'GROUP BY StageName';
                bindMap.put('qStart', qStart);
                bindMap.put('qEnd', qEnd);
            } else {
                aggQuery = 'SELECT StageName, SUM(Amount) totalAmount, COUNT(Id) oppCount, AVG(Amount) avgAmount '
                         + 'FROM Opportunity '
                         + 'WHERE IsClosed = false '
                         + 'GROUP BY StageName';
            }

            List<AggregateResult> results = Database.queryWithBinds(aggQuery, bindMap, AccessLevel.USER_MODE);

            Decimal totalPipeline = 0;
            Integer totalCount    = 0;
            List<Map<String, Object>> stageBreakdown = new List<Map<String, Object>>();

            // Use Map for O(1) stage lookups — no nested loops
            Map<String, AggregateResult> stageMap = new Map<String, AggregateResult>();
            for (AggregateResult ar : results) {
                stageMap.put((String) ar.get('StageName'), ar);
            }

            for (String stage : stageMap.keySet()) {
                AggregateResult ar = stageMap.get(stage);
                Decimal stageTotal = (Decimal) ar.get('totalAmount');
                Integer stageCount = Integer.valueOf(ar.get('oppCount'));
                Decimal stageAvg   = (Decimal) ar.get('avgAmount');

                if (stageTotal != null) { totalPipeline += stageTotal; }
                if (stageCount != null) { totalCount    += stageCount; }

                stageBreakdown.add(new Map<String, Object>{
                    'stage'   => stage,
                    'total'   => stageTotal,
                    'count'   => stageCount,
                    'average' => stageAvg
                });
            }

            Decimal avgDeal = (totalCount > 0) ? (totalPipeline / totalCount) : 0;

            response.totalPipelineValue = totalPipeline;
            response.opportunityCount   = totalCount;
            response.averageDealSize    = avgDeal;
            response.resultJson         = JSON.serialize(stageBreakdown);
            response.opportunitiesJson  = '[]';
            response.success            = true;
        } catch (Exception e) {
            response.success           = false;
            response.errorMessage      = e.getMessage();
            response.opportunitiesJson = '[]';
            logError('getPipelineTotals exception: ' + e.getMessage());
        }
        return response;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Segmentation
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryResponse getSegmentation(OpportunityQueryRequest req) {
        OpportunityQueryResponse response = new OpportunityQueryResponse();
        try {
            String baseQuery = 'SELECT Id, Name, StageName, Amount, CloseDate, OwnerId, Owner.Name, Probability '
                             + 'FROM Opportunity WHERE IsClosed = false';

            List<String> conditions = new List<String>();
            Map<String, Object> bindMap = new Map<String, Object>();

            if (String.isNotBlank(req.stageFilter)) {
                conditions.add('StageName = :stageFilter');
                bindMap.put('stageFilter', req.stageFilter);
            }
            if (String.isNotBlank(req.ownerIdFilter)) {
                conditions.add('OwnerId = :ownerIdFilter');
                bindMap.put('ownerIdFilter', req.ownerIdFilter);
            }
            if (req.minAmount != null) {
                conditions.add('Amount >= :minAmount');
                bindMap.put('minAmount', req.minAmount);
            }
            if (req.maxAmount != null) {
                conditions.add('Amount <= :maxAmount');
                bindMap.put('maxAmount', req.maxAmount);
            }
            if (req.closeDateStart != null) {
                conditions.add('CloseDate >= :closeDateStart');
                bindMap.put('closeDateStart', req.closeDateStart);
            }
            if (req.closeDateEnd != null) {
                conditions.add('CloseDate <= :closeDateEnd');
                bindMap.put('closeDateEnd', req.closeDateEnd);
            }

            if (!conditions.isEmpty()) {
                baseQuery += ' AND ' + String.join(conditions, ' AND ');
            }
            baseQuery += ' ORDER BY CloseDate ASC LIMIT 200';

            List<Opportunity> opps = Database.queryWithBinds(baseQuery, bindMap, AccessLevel.USER_MODE);

            response.opportunitiesJson = JSON.serialize(opps);
            response.opportunityCount  = opps.size();
            response.success           = true;
        } catch (Exception e) {
            response.success           = false;
            response.errorMessage      = e.getMessage();
            response.opportunitiesJson = '[]';
            logError('getSegmentation exception: ' + e.getMessage());
        }
        return response;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. At-Risk Identification
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryResponse getAtRisk() {
        OpportunityQueryResponse response = new OpportunityQueryResponse();
        try {
            Date today = Date.today();
            Map<String, Object> bindMap = new Map<String, Object>{ 'today' => today };

            String atRiskQuery = 'SELECT Id, Name, StageName, Amount, CloseDate, OwnerId, Owner.Name, Probability '
                               + 'FROM Opportunity '
                               + 'WHERE CloseDate < :today '
                               + 'AND StageName NOT IN (\'Closed Won\', \'Closed Lost\') '
                               + 'ORDER BY CloseDate ASC '
                               + 'LIMIT 200';

            List<Opportunity> atRiskOpps = Database.queryWithBinds(atRiskQuery, bindMap, AccessLevel.USER_MODE);

            // Enrich with overdue days — single pass, no nested loops
            List<Map<String, Object>> enriched = new List<Map<String, Object>>();
            for (Opportunity opp : atRiskOpps) {
                Integer overdueDays = opp.CloseDate.daysBetween(today);
                enriched.add(new Map<String, Object>{
                    'Id'          => opp.Id,
                    'Name'        => opp.Name,
                    'StageName'   => opp.StageName,
                    'Amount'      => opp.Amount,
                    'CloseDate'   => opp.CloseDate,
                    'OwnerId'     => opp.OwnerId,
                    'OwnerName'   => opp.Owner.Name,
                    'Probability' => opp.Probability,
                    'OverdueDays' => overdueDays
                });
            }

            response.opportunitiesJson = JSON.serialize(enriched);
            response.opportunityCount  = atRiskOpps.size();
            response.success           = true;
        } catch (Exception e) {
            response.success           = false;
            response.errorMessage      = e.getMessage();
            response.opportunitiesJson = '[]';
            logError('getAtRisk exception: ' + e.getMessage());
        }
        return response;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Deep-Dive (single Opportunity)
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryResponse getDeepDive(OpportunityQueryRequest req) {
        OpportunityQueryResponse response = new OpportunityQueryResponse();
        try {
            if (String.isBlank(req.opportunityId)) {
                response.success           = false;
                response.errorMessage      = 'opportunityId is required for DEEP_DIVE';
                response.opportunitiesJson = '[]';
                logError('getDeepDive: opportunityId is blank');
                return response;
            }

            Id oppId = Id.valueOf(req.opportunityId);
            Date today = Date.today();
            Map<String, Object> bindMap = new Map<String, Object>{ 'oppId' => oppId };

            String deepQuery = 'SELECT Id, Name, StageName, Amount, CloseDate, OwnerId, Owner.Name, '
                             + 'Probability, Description, LeadSource, Type, '
                             + 'AccountId, Account.Name, '
                             + 'CreatedDate, LastModifiedDate, IsClosed, IsWon '
                             + 'FROM Opportunity '
                             + 'WHERE Id = :oppId '
                             + 'LIMIT 1';

            List<Opportunity> opps = Database.queryWithBinds(deepQuery, bindMap, AccessLevel.USER_MODE);

            if (opps.isEmpty()) {
                response.success           = false;
                response.errorMessage      = 'Opportunity not found: ' + req.opportunityId;
                response.opportunitiesJson = '[]';
                return response;
            }

            Opportunity opp = opps[0];
            Boolean isAtRisk = (!opp.IsClosed && opp.CloseDate < today);

            Map<String, Object> deepDiveData = new Map<String, Object>{
                'Id'               => opp.Id,
                'Name'             => opp.Name,
                'StageName'        => opp.StageName,
                'Amount'           => opp.Amount,
                'CloseDate'        => opp.CloseDate,
                'OwnerId'          => opp.OwnerId,
                'OwnerName'        => opp.Owner.Name,
                'Probability'      => opp.Probability,
                'Description'      => opp.Description,
                'LeadSource'       => opp.LeadSource,
                'Type'             => opp.Type,
                'AccountId'        => opp.AccountId,
                'AccountName'      => opp.Account != null ? opp.Account.Name : null,
                'CreatedDate'      => opp.CreatedDate,
                'LastModifiedDate' => opp.LastModifiedDate,
                'IsClosed'         => opp.IsClosed,
                'IsWon'            => opp.IsWon,
                'IsAtRisk'         => isAtRisk
            };

            response.opportunitiesJson = JSON.serialize(deepDiveData);
            response.opportunityCount  = 1;
            response.success           = true;
        } catch (Exception e) {
            response.success           = false;
            response.errorMessage      = e.getMessage();
            response.opportunitiesJson = '[]';
            logError('getDeepDive exception: ' + e.getMessage());
        }
        return response;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Top-N Rankings
    // ─────────────────────────────────────────────────────────────────────────

    private static OpportunityQueryResponse getTopN(OpportunityQueryRequest req) {
        OpportunityQueryResponse response = new OpportunityQueryResponse();
        try {
            Integer n = (req.topN != null && req.topN > 0) ? req.topN : 10;
            // Whitelist rank field to prevent SOQL injection
            String rankField = (String.isNotBlank(req.rankBy) && req.rankBy.toUpperCase() == 'PROBABILITY')
                               ? 'Probability' : 'Amount';

            String query = 'SELECT Id, Name, StageName, Amount, CloseDate, OwnerId, Owner.Name, Probability '
                         + 'FROM Opportunity '
                         + 'WHERE IsClosed = false '
                         + 'ORDER BY ' + rankField + ' DESC NULLS LAST '
                         + 'LIMIT :n';

            Map<String, Object> bindMap = new Map<String, Object>{ 'n' => n };
            List<Opportunity> topOpps = Database.queryWithBinds(query, bindMap, AccessLevel.USER_MODE);

            response.opportunitiesJson = JSON.serialize(topOpps);
            response.opportunityCount  = topOpps.size();
            response.success           = true;
        } catch (Exception e) {
            response.success           = false;
            response.errorMessage      = e.getMessage();
            response.opportunitiesJson = '[]';
            logError('getTopN exception: ' + e.getMessage());
        }
        return response;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Utility: centralised error logging
    // Note: Replace System.debug with Nebula Logger (Logger.error / Logger.saveLog)
    //       once the Nebula Logger package is installed in this org.
    // ─────────────────────────────────────────────────────────────────────────

    private static void logError(String message) {
        System.debug(LoggingLevel.ERROR, '[OpportunityQueryService] ' + message);
    }
}