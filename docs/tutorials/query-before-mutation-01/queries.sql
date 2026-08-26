-- Tutorial 2: Query Before Mutation
-- Demo sequence, validated against real AWS account (us-east-1)
-- WIP - mutation payload serialization for put_bucket_encryption is the open blocker

-- Prerequisites:
-- 1. AWS credentials in .env with permissions for s3:*, kms:*
-- 2. A customer-managed KMS key in us-east-1
-- 3. stackql v0.10.601 or later

-- ============================================================
-- SETUP: Pull AWS provider (once per shell session)
-- ============================================================
REGISTRY PULL aws;

-- ============================================================
-- STEP 0: Create demo resources (one-time setup for tutorial reader)
-- ============================================================

-- Create the test bucket
-- Returns: "The operation was despatched successfully"
INSERT INTO aws.s3.buckets(bucket, region) 
SELECT 'stackql-tut2-demo-nirmal-01', 'us-east-1';

-- Create a customer-managed KMS key for the demo
-- Returns: "The operation was despatched successfully"
-- Reader captures the resulting KMS Key ARN for use in the REPLACE below
INSERT INTO aws.kms.keys(region, Description) 
SELECT 'us-east-1', 'KMS key for stackql Tutorial 2 S3 encryption demo';

-- ============================================================
-- STEP 1: Query live encryption state (the "query before mutation" step)
-- ============================================================

-- Returns rules column with current encryption configuration
-- Example current state: SSE-S3 (AES256), which does not match SSE-KMS policy
SELECT * 
FROM aws.s3.bucket_encryptions 
WHERE bucket = 'stackql-tut2-demo-nirmal-01' 
AND region = 'us-east-1';

-- Current live output:
-- rules: {"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},...}

-- ============================================================
-- STEP 2: Mutate to policy-compliant state (SSE-KMS)
-- ============================================================

-- BLOCKER: this REPLACE returns "xml: start tag with no name"
-- Confirmed via SHOW METHODS: put_bucket_encryption is exposed as REPLACE
-- with required params (bucket, ServerSideEncryptionConfiguration, region)
-- Kieran flagged that "some of the serialization stuff is not perfect"
-- Awaiting his input on the expected payload shape

-- Attempt A: REPLACE ... SET ... WHERE
-- Returns: xml: start tag with no name
REPLACE aws.s3.bucket_encryptions 
SET ServerSideEncryptionConfiguration = 
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"arn:aws:kms:us-east-1:824532806693:key/5784aa16-d7a5-4f78-9372-a85cd7784abc"},"BucketKeyEnabled":true}]}'
WHERE bucket = 'stackql-tut2-demo-nirmal-01' 
AND region = 'us-east-1';

-- Attempt B: UPDATE with data__ prefix
-- Returns: no appropriate method = 'update' for resource
UPDATE aws.s3.bucket_encryptions 
SET data__ServerSideEncryptionConfiguration = 
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"arn:aws:kms:us-east-1:824532806693:key/5784aa16-d7a5-4f78-9372-a85cd7784abc"},"BucketKeyEnabled":true}]}'
WHERE bucket = 'stackql-tut2-demo-nirmal-01' 
AND region = 'us-east-1';

-- ============================================================
-- STEP 3: Verify convergence (re-run STEP 1)
-- ============================================================

-- Expected after successful mutation:
-- rules: {"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"arn:aws:kms:us-east-1:..."},...}

SELECT * 
FROM aws.s3.bucket_encryptions 
WHERE bucket = 'stackql-tut2-demo-nirmal-01' 
AND region = 'us-east-1';

-- ============================================================
-- CLEANUP (post-tutorial)
-- ============================================================

DELETE FROM aws.s3.buckets 
WHERE bucket = 'stackql-tut2-demo-nirmal-01' 
AND region = 'us-east-1';

-- Note: KMS key scheduled for deletion via aws.kms.keys DELETE, 
-- with mandatory 7-30 day pending window