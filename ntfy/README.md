# ntfy

## Description

[ntfy](https://ntfy.sh) is an open-source, self-hosted HTTP-based pub-sub push notification service. It allows scripts, services, and servers to send push notifications to phones or desktops via simple `PUT`/`POST` requests, with support for SQLite or PostgreSQL storage, access control, attachments, Prometheus metrics, OIDC SSO, outbound SMTP, and S3 backups.

## Application Information
- **Version:** `v2.32.0`
- **Official Website:** [https://ntfy.sh/](https://ntfy.sh/)
- **Upstream Project:** [https://github.com/binwiederhier/ntfy](https://github.com/binwiederhier/ntfy)
- **Container Base:**
  - ntfy Application: [docker.io/binwiederhier/ntfy](https://hub.docker.com/r/binwiederhier/ntfy) (`docker.io/binwiederhier/ntfy:v2.32.0`)
  - Database Backend (PostgreSQL): [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
  - PostgreSQL Init Wait: [docker.io/library/busybox](https://hub.docker.com/_/busybox) (`docker.io/library/busybox:1.37`)
  - Backup Archiver (optional): [docker.io/library/alpine](https://hub.docker.com/_/alpine) (`docker.io/library/alpine:3.22`)
  - Backup S3 Uploader (optional): [docker.io/helmforge/mc](https://hub.docker.com/r/helmforge/mc) (`docker.io/helmforge/mc:1.0.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **ntfy Server Workload (`ntfy`):** Core HTTP pub-sub notification server handling topics, subscriptions, attachments, and optional `/metrics` scraping on container port `2586`.
- **Deployment (`ntfy`):** Single-replica `Recreate` deployment with optional PostgreSQL wait `initContainer`, startup/liveness/readiness probes on `/v1/health`, and restricted non-root execution (`1000:1000`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`).
- **ConfigMap (`ntfy-config`):** Renders `/etc/ntfy/server.yml` from module values (`base-url`, `auth-default-access`, attachments, ban-feed, PostgreSQL/SQLite, OIDC, SMTP, and `extraConfig`).
- **Secrets (`ntfy-admin`, `ntfy-db`, `ntfy-oidc`, `ntfy-smtp`, `ntfy-backup-s3`):** Conditional Kubernetes Secrets for managed admin bootstrap credentials, PostgreSQL connection credentials, OIDC client secret, SMTP password, and S3 backup credentials.
- **Service (`ntfy`):** Kubernetes `ClusterIP` Service exposing the HTTP API and web UI on port `80` (with optional dual-stack configuration).
- **PersistentVolumeClaim (`ntfy-data`):** Persistent volume claim mounted at `/var/cache/ntfy` for SQLite databases, message cache, and attachments (`2Gi` default), or bounded `emptyDir` when persistence is disabled.
- **Bundled PostgreSQL (`ntfy-postgresql`):** Bundled standalone PostgreSQL (`docker.io/library/postgres:18.6-trixie`) with dedicated authentication Secret, configuration and initdb ConfigMaps, headless and ClusterIP Services, non-root execution (`999:999`), and persistent volume claim storage (`8Gi` default).
- **ServiceAccount (`ntfy` / `ntfy-backup`):** Optional dedicated ServiceAccount for the ntfy workload and optional dedicated ServiceAccount for S3 backups with `automountServiceAccountToken: false` and IRSA/Pod Identity annotation support.
- **Gateway API HTTPRoute (`ntfy`):** Optional Gateway API `HTTPRoute` resource for routing external traffic via Kubernetes Gateway API controllers.
- **ExternalSecret (`ntfy-*`):** Optional External Secrets Operator `ExternalSecret` resources (`externalSecrets.items`) for syncing secrets from external secret stores.
- **PodDisruptionBudget (`ntfy`):** Optional PDB protecting the ntfy pod during voluntary disruptions.
- **ServiceMonitor (`ntfy`):** Optional Prometheus Operator `ServiceMonitor` for scraping `/metrics` when `ntfy.enableMetrics` and `metrics.serviceMonitor.enabled` are enabled.
- **Backup CronJob (`ntfy-backup`):** Optional scheduled `CronJob` that archives `/var/cache/ntfy` and uploads backups to an S3-compatible bucket.

## Prerequisites

- Kubernetes cluster v1.20+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gateway.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active
- Optional: [Prometheus Operator](https://prometheus-operator.dev) if `metrics.serviceMonitor.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply ntfy ./ntfy
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	ntfy: {
		baseUrl:           "https://ntfy.example.com"
		authDefaultAccess: "deny-all"
		admin: {
			enabled:        true
			existingSecret: "ntfy-admin-secret"
		}
	}
	gateway: {
		enabled: true
		parentRefs: [{
			name: "traefik"
		}]
		hostnames: ["ntfy.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply ntfy ./ntfy \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete ntfy
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the module name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the complete resource name |
| `commonLabels` | `object` | `{}` | Additional labels applied to all module resources |
| `commonAnnotations` | `object` | `{}` | Additional annotations applied to all module resources |
| `image.repository` | `string` | `"docker.io/binwiederhier/ntfy"` | Container image repository |
| `image.tag` | `string` | `"v2.32.0"` | Container image release tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `containerPorts.http` | `int` | `2586` | Container HTTP listen port |
| `ntfy.baseUrl` | `string` | `""` | Public base URL of the instance |
| `ntfy.authDefaultAccess` | `string` | `"read-write"` | Default access for unauthenticated users (`read-write`, `read-only`, `write-only`, `deny-all`) |
| `ntfy.admin.enabled` | `bool` | `true` | Enable automatic administrator user creation |
| `ntfy.admin.username` | `string` | `"admin"` | Initial administrator username |
| `ntfy.admin.password` | `string` | `"Changeit@123."` | Initial administrator password (or supply `existingSecret`) |
| `ntfy.admin.role` | `string` | `"admin"` | Role assigned to the initial user (`admin`, `user`) |
| `ntfy.admin.existingSecret` | `string` | `""` | Existing Secret containing admin credentials |
| `ntfy.admin.existingSecretPasswordKey` | `string` | `"password"` | Key in existing Secret containing the admin password |
| `ntfy.behindProxy` | `bool` | `true` | Trust `X-Forwarded-For` headers from reverse proxy |
| `ntfy.enableMetrics` | `bool` | `false` | Enable Prometheus metrics endpoint at `/metrics` |
| `ntfy.metricsListenHttp` | `string` | `""` | Separate metrics listen address (e.g. `:9090`) |
| `ntfy.database.mode` | `string` | `"sqlite"` | Database backend mode (`sqlite`, `postgresql`) |
| `ntfy.database.external.host` | `string` | `""` | External PostgreSQL host |
| `ntfy.database.external.port` | `string` | `"5432"` | External PostgreSQL port |
| `ntfy.database.external.name` | `string` | `"ntfy"` | External PostgreSQL database name |
| `ntfy.database.external.username` | `string` | `"ntfy"` | External PostgreSQL username |
| `ntfy.database.external.existingSecret` | `string` | `""` | Existing Secret containing external PostgreSQL credentials |
| `ntfy.extraConfig` | `string` | `""` | Extra `server.yml` configuration lines |
| `ntfy.extraEnv` | `list` | `[]` | Extra container environment variables |
| `postgresql.enabled` | `bool` | `true` | Connect to an accompanying bundled PostgreSQL instance (`<name>-postgresql`) |
| `postgresql.image.repository` | `string` | `"docker.io/library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | `string` | `"18.6-trixie"` | PostgreSQL container image tag |
| `postgresql.auth.database` | `string` | `"ntfy"` | PostgreSQL database name |
| `postgresql.auth.username` | `string` | `"ntfy"` | PostgreSQL username |
| `postgresql.auth.password` | `string` | `"postgresql-password"` | PostgreSQL password |
| `postgresql.persistence.enabled` | `bool` | `true` | Enable persistent storage for PostgreSQL |
| `postgresql.persistence.size` | `string` | `"8Gi"` | PostgreSQL data volume storage capacity |
| `postgresql.resources.requests.cpu` | `string` | `"250m"` | PostgreSQL container CPU request |
| `postgresql.resources.requests.memory` | `string` | `"512Mi"` | PostgreSQL container memory request |
| `postgresql.resources.limits.cpu` | `string` | `"500m"` | PostgreSQL container CPU limit |
| `postgresql.resources.limits.memory` | `string` | `"1Gi"` | PostgreSQL container memory limit |
| `postgresql.podSecurityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution for PostgreSQL pod |
| `postgresql.podSecurityContext.runAsUser` | `int` | `999` | PostgreSQL pod user UID |
| `postgresql.podSecurityContext.fsGroup` | `int` | `999` | PostgreSQL pod filesystem group GID |
| `postgresql.securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount root filesystem as read-write for PostgreSQL |
| `postgresql.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from PostgreSQL container |
| `externalSecrets.enabled` | `bool` | `false` | Enable External Secrets Operator resources |
| `externalSecrets.refreshInterval` | `string` | `"1h"` | Refresh interval for ExternalSecret resources |
| `externalSecrets.items` | `list` | `[]` | ExternalSecret definitions |
| `persistence.enabled` | `bool` | `true` | Enable persistent storage for `/var/cache/ntfy` |
| `persistence.size` | `string` | `"2Gi"` | Storage capacity of the persistent volume claim |
| `persistence.storageClass` | `string` | `""` | StorageClass name for data claim |
| `persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.existingClaim` | `string` | `""` | Existing PVC name override |
| `persistence.emptyDirSizeLimit` | `string` | `"1Gi"` | Bounded `emptyDir` limit when persistence is disabled |
| `serviceAccount.create` | `bool` | `false` | Create dedicated Kubernetes ServiceAccount |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name override |
| `serviceAccount.annotations` | `object` | `{}` | Annotations applied to ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount ServiceAccount API credentials |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `80` | Application Service HTTP port |
| `service.annotations` | `object` | `{}` | Annotations applied to Service |
| `service.ipFamilyPolicy` | `string` | `null` | Service IP family policy (`SingleStack`, `PreferDualStack`, `RequireDualStack`) |
| `service.ipFamilies` | `list` | `[]` | Service requested address families |
| `gateway.enabled` | `bool` | `false` | Enable Gateway API `HTTPRoute` |
| `gateway.parentRefs` | `list` | `[]` | Parent Gateway references for `HTTPRoute` |
| `gateway.hostnames` | `list` | `[]` | Hostnames matched by `HTTPRoute` |
| `gateway.path` | `string` | `"/"` | `HTTPRoute` path prefix |
| `gateway.pathType` | `string` | `"PathPrefix"` | `HTTPRoute` path match type |
| `probes.startup.enabled` | `bool` | `true` | Enable container startup probe |
| `probes.startup.failureThreshold` | `int` | `30` | Startup probe failure threshold |
| `probes.startup.periodSeconds` | `int` | `5` | Startup probe period in seconds |
| `probes.startup.timeoutSeconds` | `int` | `3` | Startup probe timeout in seconds |
| `probes.readiness.enabled` | `bool` | `true` | Enable container readiness probe |
| `probes.readiness.failureThreshold` | `int` | `3` | Readiness probe failure threshold |
| `probes.readiness.periodSeconds` | `int` | `10` | Readiness probe period in seconds |
| `probes.readiness.timeoutSeconds` | `int` | `5` | Readiness probe timeout in seconds |
| `probes.liveness.enabled` | `bool` | `true` | Enable container liveness probe |
| `probes.liveness.failureThreshold` | `int` | `3` | Liveness probe failure threshold |
| `probes.liveness.periodSeconds` | `int` | `15` | Liveness probe period in seconds |
| `probes.liveness.timeoutSeconds` | `int` | `5` | Liveness probe timeout in seconds |
| `resources.requests.cpu` | `string` | `"50m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"64Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"500m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"256Mi"` | Container memory limit |
| `podSecurityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `podSecurityContext.runAsUser` | `int` | `1000` | Pod user UID |
| `podSecurityContext.runAsGroup` | `int` | `1000` | Pod group GID |
| `podSecurityContext.fsGroup` | `int` | `1000` | Pod filesystem group GID |
| `podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount container image root as read-only |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `runtimeStorage.tmpSizeLimit` | `string` | `"128Mi"` | Bounded `emptyDir` volume size for `/tmp` |
| `podDisruptionBudget.enabled` | `bool` | `false` | Enable `PodDisruptionBudget` |
| `metrics.serviceMonitor.enabled` | `bool` | `false` | Enable Prometheus Operator `ServiceMonitor` |
| `backup.enabled` | `bool` | `false` | Enable S3 backup `CronJob` |
| `backup.schedule` | `string` | `"0 3 * * *"` | Cron schedule for backups |
| `oidc.enabled` | `bool` | `false` | Enable OIDC Single Sign-On |
| `smtp.enabled` | `bool` | `false` | Enable outbound SMTP email notifications |

## Additional Resources
- [Official ntfy Website](https://ntfy.sh/)
- [Official ntfy Documentation](https://docs.ntfy.sh/)
- [ntfy GitHub Repository](https://github.com/binwiederhier/ntfy)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the ntfy module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| ntfy Server (`ntfy`) | Deployment | 12 points | ✅ |
| Database Backend (`ntfy-postgresql`) | StatefulSet | 13 points | ✅ |
