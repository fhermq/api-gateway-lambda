# Production Deployment Guide

This guide provides step-by-step instructions for deploying the serverless monorepo application to production, including rollback procedures and incident response.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Procedures](#deployment-procedures)
3. [Post-Deployment Validation](#post-deployment-validation)
4. [Rollback Procedures](#rollback-procedures)
5. [Incident Response](#incident-response)
6. [Monitoring & Alerting](#monitoring--alerting)

## Pre-Deployment Checklist

### Code Quality

- [ ] All tests pass locally: `npm test`
- [ ] Code coverage meets minimum (80%): `npm run test:coverage`
- [ ] Linting passes: `npm run lint`
- [ ] No security vulnerabilities: `npm audit`
- [ ] Code review approved by at least 2 team members
- [ ] All commits are signed

### Infrastructure Validation

- [ ] Terraform validation passes: `terraform validate`
- [ ] Terraform formatting is correct: `terraform fmt -check`
- [ ] Terraform plan reviewed: `terraform plan`
- [ ] No unexpected resource changes in plan
- [ ] Infrastructure scripts pass: `npm run validate:infrastructure`
- [ ] No orphaned resources detected: `npm run detect:orphans`

### Documentation

- [ ] CHANGELOG.md updated with changes
- [ ] README.md updated if needed
- [ ] API documentation updated
- [ ] Configuration changes documented
- [ ] Deployment notes prepared

### Security

- [ ] No hardcoded secrets in code
- [ ] All environment variables configured
- [ ] IAM roles and policies reviewed
- [ ] CORS settings appropriate for production
- [ ] HTTPS enforced
- [ ] Rate limiting configured

### Backup & Recovery

- [ ] Database backup created
- [ ] Terraform state backup created
- [ ] Rollback plan documented
- [ ] Recovery procedures tested

## Deployment Procedures

### Phase 1: Infrastructure Deployment

#### Step 1: Prepare Infrastructure Changes

```bash
# Navigate to production environment
cd infrastructure/environments/prod

# Initialize Terraform
terraform init

# Review planned changes
terraform plan -out=tfplan

# Save plan for review
terraform show tfplan > tfplan.txt
```

#### Step 2: Review and Approve Changes

1. Review `tfplan.txt` for unexpected changes
2. Verify all resources are expected
3. Check for any destructive operations
4. Get approval from infrastructure team lead
5. Document approval in deployment ticket

#### Step 3: Apply Infrastructure Changes

```bash
# Apply the planned changes
terraform apply tfplan

# Verify outputs
terraform output

# Save outputs for reference
terraform output -json > infrastructure-outputs.json
```

#### Step 4: Validate Infrastructure

```bash
# Run post-deployment validation
./infrastructure/scripts/01-post-deployment-validation.sh prod

# Check for orphaned resources
./infrastructure/scripts/03-detect-orphaned-resources.sh prod all

# Analyze costs
./infrastructure/scripts/04-cost-analysis.sh prod
```

### Phase 2: Lambda Deployment

#### Step 1: Build and Package Lambda Code

```bash
# Navigate to Lambda application
cd apps/api-handler

# Install dependencies
npm install

# Run tests
npm test

# Run linting
npm run lint

# Build/package code
npm run build
```

#### Step 2: Upload Code to S3

```bash
# Package Lambda function
zip -r api-handler.zip dist/ node_modules/

# Upload to S3
aws s3 cp api-handler.zip s3://lambda-code-prod/api-handler-$(date +%Y%m%d-%H%M%S).zip

# Update Lambda function
aws lambda update-function-code \
  --function-name api-handler-prod \
  --s3-bucket lambda-code-prod \
  --s3-key api-handler-$(date +%Y%m%d-%H%M%S).zip
```

#### Step 3: Verify Lambda Deployment

```bash
# Check function status
aws lambda get-function --function-name api-handler-prod

# Check recent invocations
aws logs tail /aws/lambda/api-handler-prod --follow --since 5m
```

### Phase 3: Smoke Testing

#### Step 1: Run Smoke Tests

```bash
# Run smoke tests
npm run test:smoke

# Check API Gateway endpoints
curl https://api-id.execute-api.us-east-1.amazonaws.com/prod/items

# Test CRUD operations
curl -X POST https://api-id.execute-api.us-east-1.amazonaws.com/prod/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Item"}'
```

#### Step 2: Monitor Logs

```bash
# Monitor Lambda logs
aws logs tail /aws/lambda/api-handler-prod --follow

# Monitor API Gateway logs
aws logs tail /aws/apigateway/api-id --follow

# Monitor DynamoDB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value=items-prod \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

#### Step 3: Verify Metrics

```bash
# Check Lambda metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=api-handler-prod \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Check error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=api-handler-prod \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

## Post-Deployment Validation

### Immediate Validation (First 5 minutes)

- [ ] Lambda function is responding to requests
- [ ] API Gateway endpoints are accessible
- [ ] No error spikes in CloudWatch logs
- [ ] DynamoDB operations are successful
- [ ] CORS headers are present in responses
- [ ] Request/response logging is working

### Short-term Validation (First hour)

- [ ] Error rate is below 1%
- [ ] Response time is acceptable (< 1 second)
- [ ] No database throttling
- [ ] No Lambda timeouts
- [ ] CloudWatch logs are being written
- [ ] Metrics are being collected

### Extended Validation (First 24 hours)

- [ ] No unusual error patterns
- [ ] Performance is stable
- [ ] Cost is within expected range
- [ ] No security issues detected
- [ ] User feedback is positive
- [ ] All monitoring alerts are functioning

### Validation Commands

```bash
# Check Lambda function status
aws lambda get-function --function-name api-handler-prod

# Check recent errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/api-handler-prod \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000

# Check API Gateway status
aws apigateway get-stage \
  --rest-api-id api-id \
  --stage-name prod

# Check DynamoDB table status
aws dynamodb describe-table --table-name items-prod

# Check CloudWatch alarms
aws cloudwatch describe-alarms \
  --alarm-names api-handler-prod-errors \
  --query 'MetricAlarms[0].StateValue'
```

## Rollback Procedures

### Scenario 1: Lambda Code Issues

**Symptoms**: High error rate, timeouts, or incorrect responses

**Rollback Steps**:

```bash
# Step 1: Identify previous working version
aws lambda list-versions-by-function --function-name api-handler-prod

# Step 2: Get previous code from S3
aws s3 ls s3://lambda-code-prod/ | sort | tail -2

# Step 3: Rollback to previous version
aws lambda update-function-code \
  --function-name api-handler-prod \
  --s3-bucket lambda-code-prod \
  --s3-key api-handler-PREVIOUS-VERSION.zip

# Step 4: Verify rollback
aws logs tail /aws/lambda/api-handler-prod --follow

# Step 5: Monitor metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=api-handler-prod \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

### Scenario 2: Infrastructure Issues

**Symptoms**: API Gateway errors, DynamoDB throttling, or connectivity issues

**Rollback Steps**:

```bash
# Step 1: Check Terraform state
cd infrastructure/environments/prod
terraform state list

# Step 2: Review recent changes
terraform state show aws_dynamodb_table.items

# Step 3: Rollback to previous state
terraform state pull > current-state.json
# Edit current-state.json to revert changes
terraform state push current-state.json

# Step 4: Verify rollback
terraform plan

# Step 5: Apply rollback
terraform apply -auto-approve

# Step 6: Validate infrastructure
./infrastructure/scripts/01-post-deployment-validation.sh prod
```

### Scenario 3: Database Issues

**Symptoms**: Data corruption, missing data, or query failures

**Rollback Steps**:

```bash
# Step 1: Check DynamoDB backups
aws dynamodb list-backups --table-name items-prod

# Step 2: Restore from backup
aws dynamodb restore-table-from-backup \
  --target-table-name items-prod-restored \
  --backup-arn arn:aws:dynamodb:us-east-1:ACCOUNT:table/items-prod/backup/BACKUP_ID

# Step 3: Verify restored data
aws dynamodb scan --table-name items-prod-restored

# Step 4: Switch to restored table
# Update Lambda environment variable to point to restored table
aws lambda update-function-configuration \
  --function-name api-handler-prod \
  --environment Variables={DYNAMODB_TABLE_NAME=items-prod-restored}

# Step 5: Monitor for issues
aws logs tail /aws/lambda/api-handler-prod --follow

# Step 6: Once verified, delete old table and rename restored table
aws dynamodb delete-table --table-name items-prod
aws dynamodb update-table --table-name items-prod-restored --new-table-name items-prod
```

### Rollback Checklist

- [ ] Identified root cause of issue
- [ ] Prepared rollback plan
- [ ] Notified stakeholders
- [ ] Executed rollback steps
- [ ] Verified rollback was successful
- [ ] Monitored for issues
- [ ] Documented incident
- [ ] Scheduled post-mortem

## Incident Response

### Incident Classification

**Severity 1 (Critical)**
- Complete service outage
- Data loss or corruption
- Security breach
- Response time: Immediate

**Severity 2 (High)**
- Partial service degradation
- High error rate (> 5%)
- Performance issues
- Response time: 15 minutes

**Severity 3 (Medium)**
- Minor functionality issues
- Low error rate (1-5%)
- Slow response times
- Response time: 1 hour

**Severity 4 (Low)**
- Non-critical issues
- Cosmetic problems
- Documentation issues
- Response time: 24 hours

### Incident Response Workflow

#### Step 1: Detect Incident

```bash
# Monitor CloudWatch alarms
aws cloudwatch describe-alarms --state-value ALARM

# Check logs for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/api-handler-prod \
  --filter-pattern "ERROR"

# Check metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=api-handler-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

#### Step 2: Assess Impact

1. Determine severity level
2. Identify affected users/systems
3. Estimate time to resolution
4. Notify stakeholders

#### Step 3: Investigate Root Cause

```bash
# Check recent deployments
git log --oneline -10

# Check Lambda logs
aws logs tail /aws/lambda/api-handler-prod --follow --since 1h

# Check API Gateway logs
aws logs tail /aws/apigateway/api-id --follow --since 1h

# Check DynamoDB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value=items-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

#### Step 4: Implement Fix

1. Develop fix or rollback plan
2. Test fix in staging environment
3. Get approval from team lead
4. Deploy fix to production
5. Monitor for issues

#### Step 5: Verify Resolution

```bash
# Check error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=api-handler-prod \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# Check response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=api-handler-prod \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

#### Step 6: Post-Incident

1. Document incident details
2. Schedule post-mortem meeting
3. Identify preventive measures
4. Update runbooks and documentation
5. Close incident ticket

### Incident Response Checklist

- [ ] Incident detected and classified
- [ ] Stakeholders notified
- [ ] Root cause identified
- [ ] Fix implemented and tested
- [ ] Fix deployed to production
- [ ] Resolution verified
- [ ] Incident documented
- [ ] Post-mortem scheduled
- [ ] Preventive measures identified
- [ ] Documentation updated

## Monitoring & Alerting

### CloudWatch Alarms

**Lambda Error Rate**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name api-handler-prod-errors \
  --alarm-description "Alert when Lambda error rate exceeds 5%" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=api-handler-prod
```

**Lambda Duration**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name api-handler-prod-duration \
  --alarm-description "Alert when Lambda duration exceeds 10 seconds" \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 300 \
  --threshold 10000 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=api-handler-prod
```

**DynamoDB Throttling**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name items-prod-throttling \
  --alarm-description "Alert when DynamoDB is throttled" \
  --metric-name UserErrors \
  --namespace AWS/DynamoDB \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions Name=TableName,Value=items-prod
```

### CloudWatch Dashboard

```bash
# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name api-gateway-lambda-prod \
  --dashboard-body file://dashboard.json
```

**dashboard.json**:
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Lambda", "Invocations", {"stat": "Sum"}],
          [".", "Errors", {"stat": "Sum"}],
          [".", "Duration", {"stat": "Average"}],
          ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", {"stat": "Sum"}],
          [".", "ConsumedReadCapacityUnits", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Production Metrics"
      }
    }
  ]
}
```

### Log Insights Queries

**Error Analysis**
```
fields @timestamp, @message, @logStream
| filter @message like /ERROR/
| stats count() by @logStream
```

**Performance Analysis**
```
fields @duration
| stats avg(@duration), max(@duration), pct(@duration, 99) by bin(5m)
```

**Request Analysis**
```
fields @timestamp, @message, statusCode
| stats count() as requests, avg(statusCode) as avg_status by bin(5m)
```

## Related Documentation

- [README.md](./README.md) - Project overview
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [CONFIGURATION.md](./CONFIGURATION.md) - Configuration guide
- [infrastructure/bootstrap/README.md](./infrastructure/bootstrap/README.md) - OIDC setup
- [infrastructure/scripts/README.md](./infrastructure/scripts/README.md) - Infrastructure scripts
