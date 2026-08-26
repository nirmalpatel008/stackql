# Tutorial 2: Query Before Mutation

Demo assets for the query-before-mutation tutorial.

## Argument

Agents managing infrastructure should query live state before mutating.

State files still represent useful intent, but they are not authoritative for what exists in the cloud right now.

The execution pattern is:

1. Query live state
2. Identify the delta
3. Apply a policy gate
4. Mutate only the non-compliant resources
5. Query again to verify convergence

Correctness comes from querying live state before acting.

Safety comes from bounded execution through policy gates such as location locks, resource count caps, budget ceilings, and allowlists.

## Demo scenario

The demo uses Google Cloud Storage.

Policy:

Every bucket managed by the agent should use a customer-managed Cloud KMS key.

The demo starts with buckets using Google-managed encryption, represented by `encryption = null`.

The agent:

1. Queries the current bucket state
2. Identifies buckets without CMEK
3. Checks location and count policy gates
4. Updates the bucket encryption configuration
5. Queries again to confirm convergence
6. Skips mutation on subsequent runs when the resource already matches policy

## Requirements

- Docker
- Google Cloud project
- Credentials that can read and update Cloud Storage buckets
- Existing Cloud KMS key
- stackql

## Provider

The demo uses:

`google.storage.buckets`

The Google provider is pulled with:

```sql
REGISTRY PULL google;