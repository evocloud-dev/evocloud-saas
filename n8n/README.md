# n8n

## Description
[n8n](https://n8n.io/) is an extensible, open-source workflow automation platform that enables users to connect disparate services, automate complex multi-step processes, and build custom API integrations with both low-code and code-native flexibility. Featuring native queue mode scaling with Redis and support for isolated task runner sidecars, n8n provides an enterprise-ready automation engine that maintains strict data sovereignty and security within Kubernetes clusters.

## Application Information
- **Version:** 0.1.0 (App: 2.37.11)
- **Upstream Project:** [https://github.com/n8n-io/n8n](https://github.com/n8n-io/n8n)
- **Container Base:** [docker.io/n8nio/n8n](https://hub.docker.com/r/n8nio/n8n) (`docker.io/n8nio/n8n:2.37.11`), [docker.io/n8nio/runners](https://hub.docker.com/r/n8nio/runners) (`docker.io/n8nio/runners:2.37.11`), [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-alpine`), [docker.io/library/redis](https://hub.docker.com/_/redis) (`docker.io/library/redis:8.10.1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **n8n Core (`deploy` / `n8n-n8n`):** Primary workflow execution server, web UI editor, and webhook listener running `docker.io/n8nio/n8n:2.37.11` on port 5678 (exposed as Service port 80), accompanied by an optional external task runner sidecar (`docker.io/n8nio/runners:2.37.11`) for secure isolated script execution.
- **n8n Worker (`deployWorker` / `n8n-n8n-worker`):** Scalable background worker Deployment running `docker.io/n8nio/n8n:2.37.11` in queue mode, consuming and executing asynchronous workflow tasks from Redis queues.
- **PostgreSQL Database Subchart (`pgDeploy` / `n8n-n8n-postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`docker.io/library/postgres:18.6-alpine`) providing persistent relational storage (`8Gi`) with automated `uuid-ossp` extension provisioning.
- **Redis Subchart (`redisDeploy` / `n8n-n8n-redis`):** Dedicated Redis 8 StatefulSet (`docker.io/library/redis:8.10.1`) managing message broker queues and inter-process event distribution for horizontal worker scaling.
- **Persistent Volume Claim (`pvc`):** Persistent storage (`5Gi`) mounted at `/home/node/.n8n` storing user configurations, custom community nodes, and credentials cache.
- **Kubernetes Service (`svc`):** ClusterIP service exposing port 80 routing internally to container port 5678.
- **Gateway API HTTPRoute (`httpRoute`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource for modern cluster ingress routing.
- **Database Backup CronJob (`backupCronJob`):** Optional automated scheduled backup Job streaming database dumps to S3-compatible object storage.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount for n8n pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting ReadWriteOnce persistent volumes
- Gateway controller (e.g. Envoy Gateway, Cilium) if Gateway API routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply n8n ./n8n
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	n8n: {
		webhookUrl:    "https://n8n.example.com"
		editorBaseUrl: "https://n8n.example.com"
	}
	gateway: {
		enabled:   true
		hostnames: ["n8n.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply n8n ./n8n \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete n8n
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the chart name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `commonLabels` | map | `{}` | Labels added to every resource created by this module |
| `image.repository` | string | `"docker.io/n8nio/n8n"` | n8n container image repository |
| `image.tag` | string | `"2.37.11"` | n8n container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `n8n.encryptionKey` | string | `"..."` | Encryption key for securing workflow credentials and sensitive data |
| `n8n.webhookUrl` | string | `""` | Public webhook URL for external access |
| `n8n.editorBaseUrl` | string | `""` | Base URL used by the web editor interface |
| `n8n.logLevel` | string | `"warn"` | Logging level (`info`, `warn`, `error`, `debug`) |
| `n8n.diagnosticsEnabled` | bool | `false` | Enable or disable sharing anonymous diagnostics with n8n |
| `n8n.gracefulShutdownTimeout` | int | `60` | Graceful shutdown timeout in seconds for main and worker processes |
| `taskRunners.mode` | string | `"external"` | Task runner mode (`internal` or `external` dedicated sidecar) |
| `taskRunners.image.repository` | string | `"docker.io/n8nio/runners"` | External task runner sidecar container image repository |
| `taskRunners.image.tag` | string | `"2.37.11"` | External task runner sidecar container image tag |
| `queue.enabled` | bool | `true` | Enable queue mode using Redis for horizontal worker scaling |
| `queue.workers` | int | `1` | Number of background worker replicas |
| `queue.concurrency` | int | `10` | Number of concurrent workflow executions per worker |
| `queue.resources.requests.cpu` | string | `"250m"` | CPU request for n8n worker pods |
| `queue.resources.requests.memory` | string | `"512Mi"` | Memory request for n8n worker pods |
| `queue.resources.limits.cpu` | string | `"1"` | CPU limit for n8n worker pods |
| `queue.resources.limits.memory` | string | `"1Gi"` | Memory limit for n8n worker pods |
| `persistence.enabled` | bool | `true` | Enable persistent storage for `/home/node/.n8n` |
| `persistence.size` | string | `"5Gi"` | Persistent Volume size requested for n8n storage |
| `resources.requests.cpu` | string | `"250m"` | CPU request for main n8n container |
| `resources.requests.memory` | string | `"512Mi"` | Memory request for main n8n container |
| `resources.limits.cpu` | string | `"1"` | CPU limit for main n8n container |
| `resources.limits.memory` | string | `"1Gi"` | Memory limit for main n8n container |
| `podSecurityContext.fsGroup` | int | `1000` | Group ID used for volume filesystem permissions |
| `podSecurityContext.fsGroupChangePolicy` | string | `"OnRootMismatch"` | Policy for volume filesystem ownership changes |
| `podSecurityContext.seccompProfile.type` | string | `"RuntimeDefault"` | Pod-level seccomp profile |
| `securityContext.runAsUser` | int | `1000` | Unprivileged non-root container UID |
| `securityContext.runAsGroup` | int | `1000` | Unprivileged non-root container GID |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce container execution as non-root user |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | int | `80` | Port exposed by Kubernetes Service (routes to 5678) |
| `gateway.enabled` | bool | `false` | Enable Kubernetes Gateway API HTTPRoute creation |
| `backup.enabled` | bool | `false` | Enable scheduled automated database backups to S3 |
| `backup.schedule` | string | `"0 3 * * *"` | Cron schedule for backup Job |
| `database.mode` | string | `"auto"` | Database mode (`auto`, `sqlite`, `external`, `postgresql`, `mysql`) |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.image.repository` | string | `"docker.io/library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"18.6-alpine"` | PostgreSQL container image tag |
| `postgresql.auth.database` | string | `"n8n"` | PostgreSQL database name |
| `postgresql.auth.username` | string | `"n8n"` | PostgreSQL username |
| `postgresql.standalone.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for PostgreSQL |
| `postgresql.standalone.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL subchart |
| `postgresql.standalone.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL subchart |
| `postgresql.standalone.resources.limits.cpu` | string | `"1"` | CPU limit for PostgreSQL subchart |
| `postgresql.standalone.resources.limits.memory` | string | `"1Gi"` | Memory limit for PostgreSQL subchart |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis message broker subchart |
| `redis.image.repository` | string | `"docker.io/library/redis"` | Redis container image repository |
| `redis.image.tag` | string | `"8.10.1"` | Redis container image tag |
| `redis.standalone.persistence.size` | string | `"1Gi"` | Persistent Volume size requested for Redis |
| `redis.standalone.resources.requests.cpu` | string | `"50m"` | CPU request for Redis subchart |
| `redis.standalone.resources.requests.memory` | string | `"64Mi"` | Memory request for Redis subchart |
| `redis.standalone.resources.limits.cpu` | string | `"500m"` | CPU limit for Redis subchart |
| `redis.standalone.resources.limits.memory` | string | `"256Mi"` | Memory limit for Redis subchart |

## Recommended values

n8n core and worker pods operate as dedicated unprivileged system users (`1000:1000`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		fsGroup:             1000
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official n8n Website](https://n8n.io/)
- [Official n8n Repository](https://github.com/n8n-io/n8n)
- [n8n Documentation](https://docs.n8n.io/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the n8n module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| n8n Core (`n8n-n8n`) | Deployment | 11 points | ✅ |
| n8n Worker (`n8n-n8n-worker`) | Deployment | 11 points | ✅ |
| PostgreSQL Subchart (`n8n-n8n-postgresql`) | StatefulSet | 13 points | ✅ |
| Redis Subchart (`n8n-n8n-redis`) | StatefulSet | 13 points | ✅ |
