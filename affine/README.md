# AFFiNE

## Description

[AFFiNE](https://affine.pro) is an open-source, all-in-one collaborative workspace that integrates notes, docs, and whiteboards. It features end-to-end synchronization, local-first storage, full-text vector search capabilities via pgvector, authenticated Redis caching, and persistent native identity signing keys.

## Application Information
- **Version:** `0.27.4`
- **Official Website:** [https://affine.pro/](https://affine.pro/)
- **Upstream Project:** [https://github.com/toeverything/AFFiNE](https://github.com/toeverything/AFFiNE)
- **Container Base:**
  - AFFiNE Application: [ghcr.io/toeverything/affine](https://github.com/toeverything/AFFiNE/pkgs/container/affine) (`ghcr.io/toeverything/affine:0.27.4`)
  - Database Backend (PostgreSQL): [docker.io/pgvector/pgvector](https://hub.docker.com/r/pgvector/pgvector) (`pgvector/pgvector:0.8.7-pg18-bookworm@sha256:2358fcba361ed2233a5ed81b5fe4ca779ccb304120ce531a3bf51c0ed7e2bc11`)
  - Cache Backend (Redis/Valkey): [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`docker.io/valkey/valkey:9.2`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **AFFiNE Server Workload (`affine`):** Core application server handling collaborative editing, GraphQL API, document sync, blob storage, and background workers running on port `3010`.
- **Deployment (`affine`):** Single-replica deployment with `Recreate` upgrade strategy, private loopback bootstrap initContainer, readiness/liveness/startup probes, and non-root execution (`1000:1000`).
- **Bootstrap ConfigMap (`affine-bootstrap`):** Embedded Node.js ECMAScript scripts (`bootstrap.mjs`, `start.mjs`, `tls-admission.mjs`, `readiness.mjs`) orchestrating private loopback initialization, certificate checks, and health probes.
- **Service (`affine`):** Kubernetes Service exposing the web dashboard and collaboration endpoints on port `3010`.
- **PersistentVolumeClaim (`affine`):** Persistent volume claim mounted at `/home/node/.affine` for local workspace state, SEC1 signing keys, blobs, and avatars (`20Gi` default).
- **Bootstrap Secret (`affine-bootstrap`):** Retained Kubernetes Secret storing the initial administrator password (`admin-password` key) with `helm.sh/resource-policy: keep`.
- **ServiceAccount (`affine`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **Bundled PostgreSQL (`affine-postgresql`):** Bundled standalone PostgreSQL with pgvector extension (`pgvector/pgvector:0.8.6-pg16-bookworm`), custom initialization scripts, and network isolation.
- **Bundled Redis (`affine-redis`):** Bundled standalone Redis instance with authentication, dedicated service account, persistent data storage (`5Gi`), and dedicated network policy.
- **Gateway API HTTPRoute (`affine`):** Optional Gateway API HTTPRoute resource for routing traffic via Kubernetes Gateway API controllers.
- **ExternalSecret (`affine`):** Optional External Secrets Operator v1 resource for syncing database, Redis, and bootstrap secrets from external secret stores.
- **Metrics Service & ServiceMonitor (`affine-metrics`):** Optional private metrics Service on port `9464`, Prometheus `ServiceMonitor`, and alert `PrometheusRule`.

## Prerequisites

- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active
- Optional: [Prometheus Operator](https://prometheus-operator.dev) if `metrics.serviceMonitor.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply affine ./affine
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	server: {
		publicUrl: "https://affine.example.com"
	}
	bootstrap: {
		email: "admin@example.com"
		existingSecret: "affine-admin-secret"
		passwordKey: "password"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply affine ./affine \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete affine
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the module name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the complete resource name |
| `commonLabels` | `object` | `{}` | Additional labels applied to all module resources |
| `replicaCount` | `int` | `1` | Workload replica count (AFFiNE requires exactly 1 replica) |
| `image.repository` | `string` | `"ghcr.io/toeverything/affine"` | Container image repository |
| `image.tag` | `string` | `"0.27.4"` | Container image release tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `extraEnv` | `list` | `[]` | Extra environment variables (managed variables reserved) |
| `server.port` | `int` | `3010` | Application container HTTP port |
| `server.publicUrl` | `string` | `""` | Exact browser-visible origin (defaults to in-cluster Service URL) |
| `bootstrap.name` | `string` | `"Administrator"` | Display name for the first native administrator |
| `bootstrap.email` | `string` | `"admin@example.test"` | First administrator email |
| `bootstrap.password` | `string` | `""` | Optional initial password (16-32 chars; empty generates random secret) |
| `bootstrap.existingSecret` | `string` | `""` | Existing Secret containing initial administrator password |
| `bootstrap.passwordKey` | `string` | `"admin-password"` | Key in Secret containing initial password |
| `persistence.enabled` | `bool` | `true` | Enable persistent storage for `/home/node/.affine` |
| `persistence.size` | `string` | `"20Gi"` | Storage capacity of the persistent volume claim |
| `persistence.storageClass` | `string` | `""` | StorageClass name for data claim |
| `persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.existingClaim` | `string` | `""` | Existing PVC name override |
| `persistence.retain` | `bool` | `true` | Retain PVC during uninstall |
| `runtime.temporarySize` | `string` | `"1Gi"` | Bounded emptyDir volume size for `/tmp` and cache |
| `serviceAccount.create` | `bool` | `true` | Create dedicated Kubernetes ServiceAccount |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name override |
| `serviceAccount.annotations` | `object` | `{}` | Annotations applied to ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount ServiceAccount API credentials |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `3010` | Application Service port |
| `service.annotations` | `object` | `{}` | Annotations applied to Service |
| `service.ipFamilyPolicy` | `string` | `""` | Service IP family policy |
| `service.ipFamilies` | `list` | `[]` | Service requested address families |
| `probes.startup.enabled` | `bool` | `true` | Enable container startup probe |
| `probes.startup.failureThreshold` | `int` | `60` | Startup probe failure threshold |
| `probes.startup.periodSeconds` | `int` | `5` | Startup probe period in seconds |
| `probes.startup.timeoutSeconds` | `int` | `5` | Startup probe timeout in seconds |
| `probes.readiness.enabled` | `bool` | `true` | Enable container readiness probe |
| `probes.readiness.failureThreshold` | `int` | `3` | Readiness probe failure threshold |
| `probes.readiness.periodSeconds` | `int` | `10` | Readiness probe period in seconds |
| `probes.readiness.timeoutSeconds` | `int` | `5` | Readiness probe timeout in seconds |
| `probes.liveness.enabled` | `bool` | `true` | Enable container liveness probe |
| `probes.liveness.failureThreshold` | `int` | `3` | Liveness probe failure threshold |
| `probes.liveness.periodSeconds` | `int` | `20` | Liveness probe period in seconds |
| `probes.liveness.timeoutSeconds` | `int` | `5` | Liveness probe timeout in seconds |
| `resources.requests.cpu` | `string` | `"500m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"1Gi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"2"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"3Gi"` | Container memory limit |
| `podSecurityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `podSecurityContext.runAsUser` | `int` | `1000` | Pod user UID |
| `podSecurityContext.runAsGroup` | `int` | `1000` | Pod group GID |
| `podSecurityContext.fsGroup` | `int` | `1000` | Pod filesystem group GID |
| `podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount container image root as read-only |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `gatewayAPI.enabled` | `bool` | `true` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | Route definitions with parentRefs, hostnames, rules, labels and annotations |
| `externalSecrets.enabled` | `bool` | `false` | Enable External Secrets Operator resources |
| `externalSecrets.refreshInterval` | `string` | `"1h"` | Refresh interval for external secrets |
| `externalSecrets.items` | `list` | `[]` | ExternalSecret definitions |
| `database.host` | `string` | `""` | External PostgreSQL host (used when `postgresql.enabled: false`) |
| `database.port` | `int` | `5432` | External PostgreSQL port |
| `database.name` | `string` | `"affine"` | External PostgreSQL database name |
| `database.username` | `string` | `"affine"` | External PostgreSQL username |
| `database.passwordSecret` | `string` | `""` | Secret containing external PostgreSQL password |
| `database.passwordKey` | `string` | `"password"` | Key within Secret containing password |
| `database.tls.enabled` | `bool` | `true` | Enable TLS verification for external PostgreSQL |
| `database.tls.caSecret` | `string` | `""` | Optional CA Secret for PostgreSQL TLS |
| `database.tls.caKey` | `string` | `"ca.crt"` | Key within CA Secret containing certificate |
| `cache.host` | `string` | `""` | External Redis host (used when `redis.enabled: false`) |
| `cache.port` | `int` | `6379` | External Redis port |
| `cache.username` | `string` | `""` | External Redis username |
| `cache.passwordSecret` | `string` | `""` | Secret containing external Redis password |
| `cache.passwordKey` | `string` | `"redis-password"` | Key within Secret containing password |
| `cache.database` | `int` | `0` | Base logical database index |
| `cache.tls.enabled` | `bool` | `true` | Enable TLS verification for external Redis |
| `cache.tls.caSecret` | `string` | `""` | Optional CA Secret for Redis TLS |
| `cache.tls.caKey` | `string` | `"ca.crt"` | Key within CA Secret containing certificate |
| `postgresql.enabled` | `bool` | `true` | Enable bundled pgvector PostgreSQL |
| `redis.enabled` | `bool` | `true` | Enable bundled standalone Redis |
| `metrics.enabled` | `bool` | `false` | Enable private Prometheus metrics endpoint |
| `metrics.port` | `int` | `9464` | Private Prometheus metrics port |
| `metrics.serviceMonitor.enabled` | `bool` | `false` | Enable Prometheus Operator ServiceMonitor |
| `metrics.prometheusRule.enabled` | `bool` | `false` | Enable Prometheus Operator PrometheusRule |

## Additional Resources
- [Official AFFiNE Website](https://affine.pro/)
- [Official AFFiNE Documentation](https://docs.affine.pro)
- [AFFiNE GitHub Repository](https://github.com/toeverything/AFFiNE)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the AFFiNE module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| AFFiNE Server (`affine-affine`) | Deployment | 12 points | ✅ |
| Database Backend (`affine-postgresql`) | StatefulSet | 14 points | ✅ |
| Cache Backend (`affine-redis`) | StatefulSet | 13 points | ✅ |
