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

## Configuration

Key configuration options in `values.yaml`:

### Cleanup Settings
- `cleanup.maxAge`: Maximum age in hours before cleanup (default: 72)
- `cleanup.exemptionLabel`: Label to exempt namespaces from cleanup (default: "renku.io/cleanup-exempt=true")
- `cleanup.namespacePatterns`: List of regex patterns for namespace names (default: ["^renku-ci-.*", "^ci-.*-[0-9]+$", "^pr-[0-9]+-.*"])
- `cleanup.enforceNamePatterns`: Enable strict name pattern matching (default: true)
- `cleanup.dryRun`: Enable dry-run mode (default: false)

### CronJob Settings
- `cronJob.schedule`: Cron schedule (default: "0 */6 * * *" - every 6 hours)
- `cronJob.concurrencyPolicy`: Concurrency policy (default: "Forbid")

### Image Settings
- `image.repository`: Container image repository (default: "registry.renkulab.io/renku-dev-utils")
- `image.tag`: Image tag (default: "latest")

## Usage Examples

### Basic Installation
```bash
helm install renku-ci-cleanup ./renku-ci-cleanup
```

### Custom Configuration
```bash
helm install renku-ci-cleanup ./renku-ci-cleanup \
  --set cleanup.maxAge=48 \
  --set cronJob.schedule="0 */4 * * *" \
  --set cleanup.exemptionLabel="my-app/keep=true" \
  --set cleanup.namespacePatterns='{^my-ci-.*,^test-.*-[0-9]+$}'
```

### Custom Namespace Patterns
```bash
helm install renku-ci-cleanup ./renku-ci-cleanup \
  --set cleanup.namespacePatterns='{^feature-.*,^hotfix-.*,^release-.*}'
```

### Disable Name Pattern Enforcement
```bash
helm install renku-ci-cleanup ./renku-ci-cleanup \
  --set cleanup.enforceNamePatterns=false
```

### Exempt Specific Namespaces
```bash
# Exempt a namespace from cleanup
kubectl label namespace my-important-namespace renku.io/cleanup-exempt=true

# Remove exemption
kubectl label namespace my-important-namespace renku.io/cleanup-exempt-
```

### Dry Run Mode
```bash
helm install renku-ci-cleanup ./renku-ci-cleanup \
  --set cleanup.dryRun=true
```

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

## Requirements

- Kubernetes cluster with RBAC enabled
- Helm 3.x
- Access to the renku-dev-utils container image

## Security

The chart creates:
- A dedicated ServiceAccount
- ClusterRole with minimal required permissions
- ClusterRoleBinding to associate the ServiceAccount with the role

Required permissions:
- List, get, and delete namespaces
- List, get, and delete various Kubernetes resources (pods, services, deployments, etc.)
- Access to Helm releases for cleanup

## Monitoring

The cleanup script provides detailed logging including:
- Namespace discovery and age calculation
- Exemption label checking results
- Name pattern matching results for each namespace
- Detailed cleanup actions per namespace
- Success/failure status for each operation
- Summary of total cleanup activities

## Namespace Pattern Examples

The default patterns match common CI deployment naming conventions:

- `^renku-ci-.*` - Matches namespaces starting with "renku-ci-" (e.g., "renku-ci-feature-123")
- `^ci-.*-[0-9]+$` - Matches namespaces with "ci-" prefix and ending with numbers (e.g., "ci-branch-456")
- `^pr-[0-9]+-.*` - Matches pull request namespaces (e.g., "pr-123-feature-abc")

To customize for your environment, update the `cleanup.namespacePatterns` array in values.yaml or use Helm's `--set` flag.