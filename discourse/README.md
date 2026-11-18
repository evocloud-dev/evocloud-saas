# Discourse

## Description

[Discourse](https://www.discourse.org/) is an open-source, modern discussion platform built for community collaboration, long-form discussion, and real-time chat. It features end-to-end conversation management, robust trust levels, full-text vector search capabilities via pgvector, high-performance Redis caching, and asynchronous job processing powered by Sidekiq and Unicorn web workers.

## Application Information
- **Version:** `2026.7.5`
- **Official Website:** [https://www.discourse.org/](https://www.discourse.org/)
- **Upstream Project:** [https://github.com/discourse/discourse](https://github.com/discourse/discourse)
- **Container Base:**
  - Discourse Application: [docker.io/discourse/discourse](https://hub.docker.com/r/discourse/discourse) (`discourse/discourse:2026.7.5@sha256:284bdb7b6fa0e932d0e8a862c730d024abfeeb85c872dd7833154a134eeaa403`)
  - Database Backend (PostgreSQL): [docker.io/pgvector/pgvector](https://hub.docker.com/r/pgvector/pgvector) (`pgvector/pgvector:0.8.7-pg18-trixie@sha256:5895949dfcdf308eb0cd31c950c93c14895c77f33fbedfecf1fa511ab1d4bcd2`)
  - Cache Backend (Redis/Valkey): [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`valkey:9.2`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Discourse Server Workload (`discourse`):** Core application server handling web requests, background workers (Unicorn and Sidekiq), API endpoints, asset precompilation, and database schema migrations running on HTTP port `80`.
- **Deployment (`discourse`):** Single-replica deployment enforcing `Recreate` upgrade strategy (required for database migrations and state consistency), dependency wait initContainer (`wait-for-services`), readiness/liveness/startup probes, and bounded Linux capabilities.
- **Dependency Wait InitContainer (`wait-for-services`):** Unprivileged BusyBox container verifying network socket reachability for PostgreSQL and Redis before Discourse boots.
- **Service (`discourse`):** Kubernetes Service exposing the Discourse web listener and API on port `80`.
- **PersistentVolumeClaim (`discourse`):** Persistent volume claim mounted at `/shared` for uploaded assets, backups, logs, and caches (`10Gi` default).
- **Application Secret (`discourse`):** Retained Kubernetes Secret storing the generated Rails `secret_key_base`.
- **ServiceAccount (`discourse`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **Bundled PostgreSQL (`discourse-postgresql`):** Bundled standalone PostgreSQL StatefulSet with `pgvector` extension (`pgvector/pgvector:0.8.7-pg18-trixie`), automated schema and extension initialization scripts (`02-discourse.sh`), dedicated service account, and persistent data storage (`8Gi`).
- **Bundled Redis (`discourse-redis`):** Bundled standalone Redis StatefulSet (`redis:8.10.2`) with optional authentication, dedicated service account, and persistent data storage (`1Gi`).
- **Gateway API HTTPRoute (`discourse`):** Optional Gateway API HTTPRoute resource for modern routing via Kubernetes Gateway API controllers.
- **ExternalSecret (`discourse`):** Optional External Secrets Operator v1 resource for syncing application, database, and Redis credentials from external secret stores.

## Prerequisites

- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active
- **Administrator Account Creation:** Because Discourse requires working SMTP to send activation emails or public HTTPS for Discourse ID, installations without SMTP (`skipEmailSetup: true`) require creating the initial admin account via `kubectl exec`:
  ```shell
  kubectl exec -it -n <namespace> deployment/<instance> -- rake admin:create
  ```

## Install

To create an instance using default values:

```shell
timoni -n default apply discourse ./discourse
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	discourse: {
		hostname: "forum.example.com"
		developerEmails: "admin@example.com"
	}
	gatewayAPI: {
		enabled: true
		hostnames: ["forum.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply discourse ./discourse \
  --values ./my-values.cue
```

### Initial Administrator Setup

Once the deployment completes its startup migrations, create the initial administrator account directly inside the container (required if SMTP is not configured):

```shell
kubectl exec -it -n default deployment/discourse -- rake admin:create
```

Follow the prompts to enter an email, username, and password, and confirm admin privileges (`Y`). You can then log in at `/login`.

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete discourse
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the chart name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the full release name used in resource names |
| `commonLabels` | `object` | `{}` | Additional labels applied to all module resources |
| `replicaCount` | `int` | `1` | Workload replica count (Discourse requires exactly 1 replica) |
| `image.repository` | `string` | `"docker.io/discourse/discourse"` | Official Discourse container image repository |
| `image.tag` | `string` | `"2026.7.5"` | Upstream ESR release tag |
| `image.digest` | `string` | `"sha256:284bdb7b6fa0e932d0e8a862c730d024abfeeb85c872dd7833154a134eeaa403"` | Immutable multi-architecture OCI index digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `discourse.hostname` | `string` | `"discourse.localhost"` | Public hostname for the forum |
| `discourse.developerEmails` | `string` | `"admin@example.com"` | Comma-separated developer and administrator email addresses |
| `discourse.secretKeyBase` | `string` | `""` | Rails secret key base (auto-generated in Secret when empty) |
| `discourse.existingSecret` | `string` | `""` | Existing Secret containing Discourse secret key base |
| `discourse.existingSecretKey` | `string` | `"secret-key-base"` | Key in existingSecret containing secret key base |
| `discourse.skipEmailSetup` | `bool` | `true` | Skip upstream SMTP validation during boot |
| `discourse.unicornWorkers` | `int` | `2` | Number of Unicorn web worker processes |
| `discourse.unicornSidekiqs` | `int` | `1` | Number of Sidekiq background worker processes |
| `discourse.extraEnv` | `list` | `[]` | Additional environment variables for Discourse container |
| `discourse.extraEnvFrom` | `list` | `[]` | Additional envFrom sources for Discourse container |
| `database.mode` | `string` | `"postgresql"` | Database mode: `postgresql` (bundled) or `external` |
| `database.external.host` | `string` | `""` | External PostgreSQL hostname |
| `database.external.port` | `int` | `5432` | External PostgreSQL port |
| `database.external.name` | `string` | `"discourse"` | External PostgreSQL database name |
| `database.external.username` | `string` | `"discourse"` | External PostgreSQL username |
| `database.external.password` | `string` | `""` | External PostgreSQL password (prefer existingSecret) |
| `database.external.existingSecret` | `string` | `""` | Existing Secret containing external PostgreSQL password |
| `database.external.existingSecretPasswordKey` | `string` | `"database-password"` | Key within Secret containing password |
| `postgresql.enabled` | `bool` | `true` | Deploy bundled standalone PostgreSQL subchart |
| `postgresql.architecture` | `string` | `"standalone"` | PostgreSQL architecture pattern |
| `postgresql.image.repository` | `string` | `"docker.io/pgvector/pgvector"` | Container image repository for PostgreSQL |
| `postgresql.image.tag` | `string` | `"0.8.7-pg18-trixie@sha256:5895..."` | Container image tag with pgvector extension |
| `postgresql.image.pullPolicy` | `string` | `"IfNotPresent"` | PostgreSQL image pull policy |
| `postgresql.podSecurityContext.fsGroup` | `int` | `999` | PostgreSQL pod filesystem group GID |
| `postgresql.podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `postgresql.podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `postgresql.securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `postgresql.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `postgresql.securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount container image root as read-only |
| `postgresql.securityContext.runAsGroup` | `int` | `999` | Container group GID |
| `postgresql.securityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `postgresql.securityContext.runAsUser` | `int` | `999` | Container user UID |
| `postgresql.resources.requests.cpu` | `string` | `"100m"` | PostgreSQL CPU request |
| `postgresql.resources.requests.memory` | `string` | `"256Mi"` | PostgreSQL memory request |
| `postgresql.resources.limits.cpu` | `string` | `"1000m"` | PostgreSQL CPU limit |
| `postgresql.resources.limits.memory` | `string` | `"1Gi"` | PostgreSQL memory limit |
| `postgresql.auth.database` | `string` | `"discourse"` | PostgreSQL database name |
| `postgresql.auth.username` | `string` | `"discourse"` | PostgreSQL application username |
| `postgresql.auth.password` | `string` | `""` | PostgreSQL application password (auto-generated when empty) |
| `postgresql.auth.postgresPassword` | `string` | `""` | PostgreSQL superuser password (auto-generated when empty) |
| `postgresql.standalone.persistence.enabled` | `bool` | `true` | Enable PostgreSQL data persistence |
| `postgresql.standalone.persistence.size` | `string` | `"8Gi"` | Storage capacity of PostgreSQL PVC |
| `redis.enabled` | `bool` | `true` | Deploy bundled standalone Redis subchart |
| `redis.architecture` | `string` | `"standalone"` | Redis architecture pattern |
| `redis.image.repository` | `string` | `"docker.io/valkey/valkey"` | Container image repository for Redis/Valkey |
| `redis.image.tag` | `string` | `"9.2"` | Container image tag for Redis/Valkey |
| `redis.image.pullPolicy` | `string` | `"IfNotPresent"` | Redis image pull policy |
| `redis.podSecurityContext.fsGroup` | `int` | `999` | Redis pod filesystem group GID |
| `redis.podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `redis.securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `redis.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `redis.securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount container image root as read-only |
| `redis.securityContext.runAsGroup` | `int` | `999` | Container group GID |
| `redis.securityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `redis.securityContext.runAsUser` | `int` | `999` | Container user UID |
| `redis.resources.requests.cpu` | `string` | `"50m"` | Redis CPU request |
| `redis.resources.requests.memory` | `string` | `"128Mi"` | Redis memory request |
| `redis.resources.limits.cpu` | `string` | `"500m"` | Redis CPU limit |
| `redis.resources.limits.memory` | `string` | `"512Mi"` | Redis memory limit |
| `redis.auth.enabled` | `bool` | `false` | Enable Redis password authentication |
| `redis.auth.password` | `string` | `""` | Redis authentication password |
| `redis.standalone.persistence.enabled` | `bool` | `true` | Enable Redis data persistence |
| `redis.standalone.persistence.size` | `string` | `"1Gi"` | Storage capacity of Redis PVC |
| `redis.external.host` | `string` | `""` | External Redis hostname |
| `redis.external.port` | `int` | `6379` | External Redis port |
| `redis.external.password` | `string` | `""` | External Redis password (prefer existingSecret) |
| `redis.external.existingSecret` | `string` | `""` | Existing Secret containing external Redis password |
| `redis.external.existingSecretPasswordKey` | `string` | `"redis-password"` | Key within Secret containing password |
| `persistence.enabled` | `bool` | `true` | Enable persistent storage for `/shared` |
| `persistence.size` | `string` | `"10Gi"` | Storage capacity of `/shared` PVC |
| `persistence.storageClass` | `string` | `""` | StorageClass name for `/shared` PVC |
| `persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.existingClaim` | `string` | `""` | Existing PVC name override |
| `persistence.annotations` | `object` | `{}` | Annotations applied to `/shared` PVC |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `80` | Application Service port |
| `service.annotations` | `object` | `{}` | Annotations applied to Service |
| `service.ipFamilyPolicy` | `string` | `""` | Service IP family policy |
| `service.ipFamilies` | `list` | `[]` | Service requested address families |
| `gatewayAPI.enabled` | `bool` | `true` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.apiVersion` | `string` | `"gateway.networking.k8s.io/v1"` | Gateway API HTTPRoute API version |
| `gatewayAPI.annotations` | `object` | `{}` | Annotations applied to HTTPRoute |
| `gatewayAPI.parentRefs` | `list` | `[{"name": "shared-gtw", "namespace": "kube-system"}]` | Gateway parent references |
| `gatewayAPI.hostnames` | `list` | `[]` | HTTPRoute hostnames |
| `gatewayAPI.matches` | `list` | `[...]` | HTTPRoute path matches and rules |
| `serviceAccount.create` | `bool` | `true` | Create dedicated Kubernetes ServiceAccount |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name override |
| `serviceAccount.annotations` | `object` | `{}` | Annotations applied to ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount ServiceAccount API credentials |
| `podSecurityContext.fsGroup` | `int` | `1000` | Pod filesystem group GID |
| `podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `securityContext.runAsUser` | `int` | `0` | Container user UID (upstream boot requirement) |
| `securityContext.runAsNonRoot` | `bool` | `false` | Enforce non-root execution |
| `securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount container image root as read-only |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `securityContext.capabilities.add` | `list` | `["CHOWN", ...]` | Linux capabilities retained for upstream entrypoint |
| `waitForServices.image.repository` | `string` | `"docker.io/library/busybox"` | BusyBox initContainer image repository |
| `waitForServices.image.tag` | `string` | `"1.37.0-uclibc"` | BusyBox release tag |
| `waitForServices.image.pullPolicy` | `string` | `"IfNotPresent"` | BusyBox image pull policy |
| `waitForServices.securityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution for initContainer |
| `waitForServices.securityContext.runAsUser` | `int` | `65534` | initContainer user UID (`nobody`) |
| `waitForServices.securityContext.runAsGroup` | `int` | `65534` | initContainer group GID (`nogroup`) |
| `waitForServices.securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount initContainer image root as read-only |
| `waitForServices.securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation for initContainer |
| `waitForServices.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped for initContainer |
| `startupProbe.enabled` | `bool` | `true` | Enable container startup probe |
| `startupProbe.path` | `string` | `"/srv/status"` | Startup probe HTTP path |
| `startupProbe.periodSeconds` | `int` | `10` | Seconds between startup checks |
| `startupProbe.timeoutSeconds` | `int` | `5` | Startup probe timeout |
| `startupProbe.failureThreshold` | `int` | `60` | Startup probe failure threshold |
| `livenessProbe.enabled` | `bool` | `true` | Enable container liveness probe |
| `livenessProbe.path` | `string` | `"/srv/status"` | Liveness probe HTTP path |
| `livenessProbe.periodSeconds` | `int` | `20` | Seconds between liveness checks |
| `livenessProbe.timeoutSeconds` | `int` | `5` | Liveness probe timeout |
| `livenessProbe.failureThreshold` | `int` | `6` | Liveness probe failure threshold |
| `readinessProbe.enabled` | `bool` | `true` | Enable container readiness probe |
| `readinessProbe.path` | `string` | `"/srv/status"` | Readiness probe HTTP path |
| `readinessProbe.periodSeconds` | `int` | `10` | Seconds between readiness checks |
| `readinessProbe.timeoutSeconds` | `int` | `5` | Readiness probe timeout |
| `readinessProbe.failureThreshold` | `int` | `6` | Readiness probe failure threshold |
| `resources.requests.cpu` | `string` | `"250m"` | Discourse CPU request |
| `resources.requests.memory` | `string` | `"1Gi"` | Discourse memory request |
| `resources.limits.cpu` | `string` | `"2000m"` | Discourse CPU limit |
| `resources.limits.memory` | `string` | `"3Gi"` | Discourse memory limit |
| `terminationGracePeriodSeconds` | `int` | `120` | Seconds allowed for graceful shutdown |
| `progressDeadlineSeconds` | `int` | `1800` | Seconds allowed for deployment progress |
| `externalSecrets.enabled` | `bool` | `false` | Enable External Secrets Operator resources |
| `externalSecrets.apiVersion` | `string` | `"external-secrets.io/v1"` | ExternalSecret API version |
| `externalSecrets.refreshInterval` | `string` | `"1h"` | Refresh interval for external secrets |

## Additional Resources
- [Official Discourse Website](https://www.discourse.org/)
- [Official Discourse Documentation](https://meta.discourse.org/)
- [Discourse GitHub Repository](https://github.com/discourse/discourse)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Discourse module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Discourse Server (`discourse`) | Deployment | 14 points | ✅ |
| Database Backend (`discourse-postgresql`) | StatefulSet | 13 points | ✅ |
| Cache Backend (`discourse-redis`) | StatefulSet | 13 points | ✅ |
