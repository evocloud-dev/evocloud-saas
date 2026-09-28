# OpenCut

## Description

[OpenCut](https://opencut.app) is an open-source, web-based video editor, featuring video timeline editing, PostgreSQL for persistence, and Redis (via an Upstash-compatible Redis-over-HTTP bridge) for cache and session state.

## Application Information

- **Version:** 0.3.0
- **Official Website:** [https://opencut.app](https://opencut.app)
- **Upstream Project:** [https://github.com/OpenCut-app/OpenCut](https://github.com/OpenCut-app/OpenCut)
- **Container Base:** [docker.io/helmforge/opencut](https://hub.docker.com/r/helmforge/opencut) (`docker.io/helmforge/opencut:v0.3.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **OpenCut Web Application (`opencut`):** Core Next.js video editor runtime, web frontend, and API endpoints running on port `3000`.
- **Deployment (`opencut`):** Scalable deployment with init containers (`prepare-runtime-app`, `wait-for-postgresql`, `wait-for-redis-http`) to handle schema migrations and dependency readiness.
- **Service (`opencut`):** Kubernetes Service exposing the OpenCut web application on port `80` (target port `3000`).
- **Redis HTTP Bridge (`opencut-redis-http`):** Serverless Redis HTTP bridge (`docker.io/hiett/serverless-redis-http:0.0.10`) exposing an Upstash-compatible REST API on port `80` for `UPSTASH_REDIS_REST_*`.
- **Redis HTTP Service (`opencut-redis-http`):** ClusterIP Service routing REST traffic to the Redis HTTP proxy.
- **Bundled PostgreSQL (`opencut-postgresql`):** Bundled PostgreSQL database StatefulSet (`docker.io/library/postgres:18.6-trixie`) with persistent storage, headless service, and initialization ConfigMaps.
- **Bundled Redis (`opencut-redis`):** Bundled standalone/replication Redis StatefulSet (`docker.io/library/redis:8.10.2`) with persistent storage and client service.
- **Secret (`opencut-app`):** Managed application Secret holding BetterAuth secrets, database URLs, and Redis REST tokens.
- **ServiceAccount (`opencut`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **Gateway API HTTPRoute (`opencut`):** Optional Gateway API HTTPRoute definition for routing traffic via Kubernetes Gateway API controllers.
- **HorizontalPodAutoscaler (`opencut`):** Optional HPA resource for autoscaling web application replicas based on CPU and memory utilization.
- **PodDisruptionBudget (`opencut`):** Availability guardrail ensuring high availability during cluster maintenance.
- **ExternalSecret (`opencut`):** Optional External Secrets Operator v1 resource for syncing database and auth credentials from external secret stores.

## Prerequisites

- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gateway.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active

## Install

To create an instance using default values:

```bash
timoni -n default apply opencut ./opencut
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	opencut: {
		siteUrl:          "https://opencut.example.com"
		betterAuthSecret: "a-secure-random-token-with-at-least-32-chars"
	}
	resources: {
		requests: {
			cpu:    "200m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1Gi"
		}
	}
}
```

Apply the custom values to the instance:

```bash
timoni -n default apply opencut ./opencut \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```bash
timoni -n default delete opencut
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the module name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the complete resource name |
| `commonLabels` | `object` | `{}` | Additional labels applied to all module resources |
| `replicaCount` | `int` | `1` | Number of OpenCut web replicas |
| `revisionHistoryLimit` | `int` | `3` | Number of old ReplicaSets retained by the Deployment |
| `image.repository` | `string` | `"docker.io/helmforge/opencut"` | OpenCut image repository maintained by HelmForge |
| `image.tag` | `string` | `"v0.3.0"` | OpenCut container image tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private container mirrors |
| `opencut.siteUrl` | `string` | `""` | Public URL used by authentication callbacks and browser-facing links |
| `opencut.betterAuthSecret` | `string` | `""` | Better Auth secret; set explicitly for production |
| `opencut.marbleApiUrl` | `string` | `"https://api.marblecms.com"` | Marble CMS API URL consumed by OpenCut |
| `opencut.marbleWorkspaceKey` | `string` | `"placeholder"` | Marble workspace key placeholder |
| `opencut.freesoundClientId` | `string` | `""` | Optional Freesound API client ID |
| `opencut.freesoundApiKey` | `string` | `""` | Optional Freesound API key |
| `opencut.extraEnv` | `list` | `[]` | Extra environment variables appended to the OpenCut container |
| `database.mode` | `string` | `"auto"` | Database selection mode (`auto` or `external`) |
| `database.external.host` | `string` | `""` | External PostgreSQL hostname |
| `database.external.port` | `int` | `5432` | External PostgreSQL port |
| `database.external.name` | `string` | `"opencut"` | External PostgreSQL database name |
| `database.external.username` | `string` | `"opencut"` | External PostgreSQL username |
| `database.external.password` | `string` | `""` | External PostgreSQL password |
| `database.external.existingSecret` | `string` | `""` | Existing Secret containing the external PostgreSQL password |
| `database.external.existingSecretPasswordKey` | `string` | `"database-password"` | Secret key containing the external PostgreSQL password |
| `postgresql.enabled` | `bool` | `true` | Enable the bundled HelmForge PostgreSQL subchart |
| `postgresql.nameOverride` | `string` | `""` | PostgreSQL subchart name override |
| `postgresql.fullnameOverride` | `string` | `""` | PostgreSQL subchart full name override |
| `postgresql.image.repository` | `string` | `"docker.io/library/postgres"` | PostgreSQL image repository |
| `postgresql.image.tag` | `string` | `"18.6-trixie"` | PostgreSQL image tag |
| `postgresql.image.pullPolicy` | `string` | `"IfNotPresent"` | PostgreSQL image pull policy |
| `postgresql.extraEnv` | `list` | `[...]` | Extra PostgreSQL environment variables (e.g. `POSTGRES_INITDB_ARGS`) |
| `postgresql.architecture` | `string` | `"standalone"` | PostgreSQL architecture (`standalone` or `replication`) |
| `postgresql.auth.database` | `string` | `"opencut"` | PostgreSQL database created for OpenCut |
| `postgresql.auth.username` | `string` | `"opencut"` | PostgreSQL user created for OpenCut |
| `postgresql.auth.password` | `string` | `""` | PostgreSQL user password (empty auto-generates) |
| `postgresql.auth.postgresPassword` | `string` | `""` | PostgreSQL superuser password (empty auto-generates) |
| `postgresql.auth.existingSecret` | `string` | `""` | Existing Secret consumed by the PostgreSQL subchart |
| `postgresql.auth.existingSecretUserPasswordKey` | `string` | `"user-password"` | Key containing the PostgreSQL user password |
| `postgresql.standalone.resourcesPreset` | `string` | `"small"` | PostgreSQL standalone resource preset |
| `postgresql.standalone.persistence.enabled` | `bool` | `true` | Enable PostgreSQL persistence |
| `postgresql.standalone.persistence.size` | `string` | `"8Gi"` | PostgreSQL PVC capacity |
| `postgresql.replication.primary.resourcesPreset` | `string` | `"small"` | PostgreSQL primary resource preset when architecture=replication |
| `postgresql.replication.readReplicas.resourcesPreset` | `string` | `"small"` | PostgreSQL replica resource preset when architecture=replication |
| `postgresql.externalSecrets.enabled` | `bool` | `false` | Enable PostgreSQL subchart External Secrets support |
| `postgresql.externalSecrets.auth.enabled` | `bool` | `false` | Render a PostgreSQL auth ExternalSecret from the subchart |
| `postgresql.externalSecrets.auth.targetName` | `string` | `""` | Target Secret name rendered by the PostgreSQL auth ExternalSecret |
| `externalSecrets.enabled` | `bool` | `false` | Enable External Secrets Operator integration for database credentials |
| `externalSecrets.apiVersion` | `string` | `"external-secrets.io/v1"` | ExternalSecret API version |
| `externalSecrets.refreshInterval` | `string` | `"0"` | ExternalSecret refresh interval |
| `externalSecrets.secretStoreRef.name` | `string` | `""` | Existing SecretStore or ClusterSecretStore name |
| `externalSecrets.secretStoreRef.kind` | `string` | `"SecretStore"` | Secret store kind (`SecretStore` or `ClusterSecretStore`) |
| `externalSecrets.target.creationPolicy` | `string` | `"Owner"` | ExternalSecret target creation policy |
| `externalSecrets.data` | `list` | `[]` | Data mappings from remote secret store |
| `redis.enabled` | `bool` | `true` | Enable bundled Redis for cache and session state |
| `redis.nameOverride` | `string` | `""` | Redis subchart name override |
| `redis.fullnameOverride` | `string` | `""` | Redis subchart full name override |
| `redis.image.repository` | `string` | `"docker.io/library/redis"` | Redis image repository |
| `redis.image.tag` | `string` | `"8.10.2"` | Redis image tag |
| `redis.image.pullPolicy` | `string` | `"IfNotPresent"` | Redis image pull policy |
| `redis.architecture` | `string` | `"standalone"` | Redis architecture (`standalone` or `replication`) |
| `redis.auth.enabled` | `bool` | `true` | Enable Redis password authentication |
| `redis.auth.password` | `string` | `""` | Redis password (empty auto-generates) |
| `redis.auth.existingSecret` | `string` | `""` | Existing Secret containing the Redis password |
| `redis.auth.existingSecretPasswordKey` | `string` | `"redis-password"` | Key containing the Redis password |
| `redis.standalone.persistence.enabled` | `bool` | `true` | Enable Redis persistence |
| `redis.standalone.persistence.size` | `string` | `"1Gi"` | Redis PVC capacity |
| `redis.standalone.resources.requests.cpu` | `string` | `"50m"` | Standalone Redis CPU request |
| `redis.standalone.resources.requests.memory` | `string` | `"128Mi"` | Standalone Redis memory request |
| `redis.standalone.resources.limits.cpu` | `string` | `"250m"` | Standalone Redis CPU limit |
| `redis.standalone.resources.limits.memory` | `string` | `"256Mi"` | Standalone Redis memory limit |
| `redis.replication.primary.persistence.enabled` | `bool` | `true` | Enable Redis primary persistence |
| `redis.replication.primary.resources` | `object` | `{...}` | Redis primary resource requests and limits |
| `redis.replication.replica.persistence.enabled` | `bool` | `true` | Enable Redis replica persistence |
| `redis.replication.replica.resources` | `object` | `{...}` | Redis replica resource requests and limits |
| `redis.securityContext` | `object` | `{...}` | Redis container security context |
| `redis.external.host` | `string` | `""` | External Redis hostname |
| `redis.external.port` | `int` | `6379` | External Redis port |
| `redis.external.password` | `string` | `""` | External Redis password |
| `redis.external.existingSecret` | `string` | `""` | Existing Secret containing external Redis password |
| `redis.external.existingSecretPasswordKey` | `string` | `"redis-password"` | Key containing external Redis password |
| `redisHttp.enabled` | `bool` | `true` | Enable Redis HTTP bridge required by OpenCut runtime |
| `redisHttp.image.repository` | `string` | `"docker.io/hiett/serverless-redis-http"` | Redis HTTP bridge image repository |
| `redisHttp.image.tag` | `string` | `"0.0.10"` | Redis HTTP bridge image tag |
| `redisHttp.image.pullPolicy` | `string` | `"IfNotPresent"` | Redis HTTP bridge pull policy |
| `redisHttp.token` | `string` | `""` | Static Redis REST token (empty auto-generates) |
| `redisHttp.external.url` | `string` | `""` | External Redis REST URL when bridge is disabled |
| `redisHttp.external.token` | `string` | `""` | External Redis REST token when bridge is disabled |
| `redisHttp.external.existingSecret` | `string` | `""` | Existing Secret containing external Redis REST token |
| `redisHttp.external.existingSecretTokenKey` | `string` | `"redis-rest-token"` | Secret key containing external Redis REST token |
| `redisHttp.service.port` | `int` | `80` | Redis HTTP bridge Service port |
| `redisHttp.probes.startup.enabled` | `bool` | `true` | Enable Redis HTTP startup probe |
| `redisHttp.probes.startup.path` | `string` | `"/"` | Redis HTTP startup probe path |
| `redisHttp.probes.readiness.enabled` | `bool` | `true` | Enable Redis HTTP readiness probe |
| `redisHttp.probes.readiness.path` | `string` | `"/"` | Redis HTTP readiness probe path |
| `redisHttp.probes.liveness.enabled` | `bool` | `true` | Enable Redis HTTP liveness probe |
| `redisHttp.probes.liveness.path` | `string` | `"/"` | Redis HTTP liveness probe path |
| `redisHttp.resources.requests.cpu` | `string` | `"500m"` | Redis HTTP bridge CPU request |
| `redisHttp.resources.requests.memory` | `string` | `"1Gi"` | Redis HTTP bridge memory request |
| `redisHttp.resources.limits.cpu` | `string` | `"4"` | Redis HTTP bridge CPU limit |
| `redisHttp.resources.limits.memory` | `string` | `"4Gi"` | Redis HTTP bridge memory limit |
| `redisHttp.securityContext` | `object` | `{...}` | Redis HTTP container security context |
| `serviceAccount.create` | `bool` | `true` | Create dedicated ServiceAccount with no API permissions |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name override |
| `serviceAccount.annotations` | `object` | `{}` | ServiceAccount annotations |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount Service Account Token |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `80` | Service HTTP port |
| `service.annotations` | `object` | `{}` | Service annotations |
| `service.ipFamilyPolicy` | `string` | `""` | Service IP family policy; empty uses cluster default |
| `service.ipFamilies` | `list` | `[]` | Requested address families for dual-stack clusters |
| `gateway.enabled` | `bool` | `false` | Enable Gateway API HTTPRoute |
| `gateway.annotations` | `object` | `{}` | Gateway API HTTPRoute annotations |
| `gateway.parentRefs` | `list` | `[]` | parentRefs pointing to existing Gateway resources |
| `gateway.hostnames` | `list` | `[]` | Hostnames matched by the HTTPRoute |
| `gateway.path` | `string` | `"/"` | HTTPRoute path value |
| `gateway.pathType` | `string` | `"PathPrefix"` | HTTPRoute path match type |
| `autoscaling.enabled` | `bool` | `false` | Enable HorizontalPodAutoscaler for OpenCut web pods |
| `autoscaling.minReplicas` | `int` | `1` | Minimum OpenCut web replicas |
| `autoscaling.maxReplicas` | `int` | `4` | Maximum OpenCut web replicas |
| `autoscaling.targetCPUUtilizationPercentage` | `int` | `70` | Target CPU utilization percentage |
| `autoscaling.targetMemoryUtilizationPercentage` | `int` | `80` | Target memory utilization percentage |
| `pdb.enabled` | `bool` | `true` | Enable PodDisruptionBudget for OpenCut web pods |
| `pdb.minAvailable` | `int` | `1` | Minimum available pods for PodDisruptionBudget |
| `probes.startup.enabled` | `bool` | `true` | Enable OpenCut startup probe |
| `probes.startup.path` | `string` | `"/api/health"` | Startup probe HTTP path |
| `probes.liveness.enabled` | `bool` | `true` | Enable OpenCut liveness probe |
| `probes.liveness.path` | `string` | `"/api/health"` | Liveness probe HTTP path |
| `probes.readiness.enabled` | `bool` | `true` | Enable OpenCut readiness probe |
| `probes.readiness.path` | `string` | `"/api/health"` | Readiness probe HTTP path |
| `resources.requests.cpu` | `string` | `"100m"` | OpenCut web container CPU request |
| `resources.requests.memory` | `string` | `"256Mi"` | OpenCut web container memory request |
| `resources.limits.cpu` | `string` | `"1"` | OpenCut web container CPU limit |
| `resources.limits.memory` | `string` | `"1Gi"` | OpenCut web container memory limit |
| `podSecurityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `podSecurityContext.runAsUser` | `int` | `1001` | Run as non-root user UID |
| `podSecurityContext.runAsGroup` | `int` | `1001` | Run as non-root group GID |
| `podSecurityContext.fsGroup` | `int` | `1001` | Filesystem group ID |
| `podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent container privilege escalation |
| `securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount root filesystem as read-only |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `podAnnotations` | `object` | `{}` | Annotations applied to pods |
| `podLabels` | `object` | `{}` | Extra labels applied to pods |
| `priorityClassName` | `string` | `""` | Scheduling priority class name |
| `terminationGracePeriodSeconds` | `int` | `30` | Grace period for pod shutdown in seconds |
| `nodeSelector` | `object` | `{}` | Node selection constraints |
| `tolerations` | `list` | `[]` | Pod scheduling tolerations |
| `affinity` | `object` | `{}` | Pod affinity or anti-affinity rules |
| `topologySpreadConstraints` | `list` | `[]` | Topology spread constraints |
| `extraVolumes` | `list` | `[]` | Extra volumes mounted into OpenCut pods |
| `extraVolumeMounts` | `list` | `[]` | Extra volume mounts mounted into OpenCut container |
| `test.image.repository` | `string` | `"docker.io/library/busybox"` | Test image repository |
| `test.image.tag` | `string` | `"1.37.0"` | Test image tag |
| `test.image.pullPolicy` | `string` | `"IfNotPresent"` | Test image pull policy |
| `extraObjects` | `list` | `[]` | Extra Kubernetes manifests rendered with the module |

---

### Recommended values

OpenCut workloads comply with the **Restricted** Kubernetes Pod Security Standard by running as the unprivileged non-root user (UID/GID 1001:1001), mounting an immutable read-only root filesystem (`readOnlyRootFilesystem: true`), dropping all Linux capabilities (`drop: ["ALL"]`), setting `allowPrivilegeEscalation: false`, and applying a default `RuntimeDefault` seccomp profile:

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    1001
		runAsGroup:   1001
		fsGroup:      1001
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

---

## Additional Resources

- [Official OpenCut Website](https://opencut.app)
- [Official OpenCut GitHub Repository](https://github.com/OpenCut-app/OpenCut)
- [OpenCut HelmForge Repository](https://github.com/helmforgedev/charts/tree/main/charts/opencut)
- [HelmForge Documentation](https://helmforge.dev)
- [Timoni Documentation](https://timoni.sh)

---

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the OpenCut module workloads:

| Workload | Kind | Kubesec Score | Status |
| :--- | :--- | :--- | :--- |
| OpenCut Web Workload (`opencut`) | Deployment | 14 points | ✅ |
| Redis HTTP Bridge (`opencut-redis-http`) | Deployment | 12 points | ✅ |
| PostgreSQL Workload (`opencut-postgresql`) | StatefulSet | 13 points | ✅ |
| Redis Workload (`opencut-redis`) | StatefulSet | 12 points | ✅ |
