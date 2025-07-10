# Renku CI Deployment Cleanup

A Helm chart that provides automated cleanup of old Renku CI deployments using a CronJob that leverages the [renku-dev-utils](https://github.com/SwissDataScienceCenter/renku-dev-utils) utilities.

## Features

- Automated cleanup of CI deployments older than a configurable age threshold
- Uses the `rdu cleanupdeployment` command for comprehensive cleanup
- Configurable cron schedule
- Dry-run mode for testing
- RBAC configuration for secure cluster access
- Comprehensive logging and age reporting

## Installation

Install the Helm chart:
```bash
helm install renku-ci-cleanup ./renku-ci-cleanup
```

The chart will automatically create a service account with the necessary RBAC permissions to manage namespaces and resources.

## How It Works

1. The CronJob runs on the specified schedule
2. It queries Kubernetes for ALL namespaces in the cluster
3. For each namespace found:
   - Checks if the namespace has the exemption label (if so, skips it)
   - Checks if the namespace name matches any of the configured patterns (if enforcement is enabled)
   - Calculates the age based on creation timestamp
   - If the namespace is older than the configured threshold AND matches the naming patterns AND is not exempt, it uses `rdu cleanupdeployment` to:
     - Delete all sessions
     - Uninstall all Helm releases
     - Delete all jobs and PVCs
     - Optionally delete the entire namespace
4. Comprehensive logging shows what actions were taken, including exemption and pattern matching results

## Key Configuration

The main configuration options in `values.yaml`:

- `cleanup.maxAge`: Maximum age in hours before cleanup (default: 72)
- `cleanup.dryRun`: Enable dry-run mode (default: false)
- `cleanup.namespacePatterns`: List of regex patterns for namespace names
- `cronJob.schedule`: Cron schedule (default: "0 */6 * * *" - every 6 hours)

**Warning**: By default, namespaces will be deleted when they exceed the age threshold. Set `cleanup.dryRun: true` to test without actual deletions.