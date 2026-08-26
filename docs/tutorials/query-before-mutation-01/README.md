# Tutorial 2: Query Before Mutation (WIP)

Demo assets for Tutorial 2 of the DevRel campaign.

## Argument

Agents managing infrastructure need to query live state before mutating, because state files represent intent rather than reality. The execution pattern is: query live state, identify delta, policy gate, mutate, query again, verify.

## Demo scenario

AWS S3 encryption policy: every bucket managed by the agent must use SSE-KMS with a customer-managed key. Demo shows detection of SSE-S3 default, mutation to SSE-KMS, and convergence verification.

## Status

- Read path validated (SELECT on aws.s3.bucket_encryptions works)
- Test bucket and KMS key created successfully via stackql
- Mutation path blocked: REPLACE on aws.s3.bucket_encryptions returns "xml: start tag with no name"
- Awaiting input on expected payload shape for put_bucket_encryption

See queries.sql for the full sequence with commented notes on what works and what does not.