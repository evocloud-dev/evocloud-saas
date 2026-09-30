# Saleor

## Description
[Saleor](https://saleor.io/) is an open-source, headless, composable e-commerce platform built on Python (Django), GraphQL, and React. It delivers ultra-fast shopping experiences with a flexible API-first architecture, multi-channel and multi-currency capabilities, headless checkout, and an extensible modern dashboard.

## Application Information
- **Version:** 3.23.31 (Dashboard: 3.23.32)
- **Official Website:** [https://saleor.io/](https://saleor.io/)
- **Upstream Project:** [https://github.com/saleor/saleor](https://github.com/saleor/saleor)
- **Container Base:**
  - Core API: [ghcr.io/saleor/saleor](https://github.com/saleor/saleor/pkgs/container/saleor) (`ghcr.io/saleor/saleor:3.23.31`)
  - Dashboard: [ghcr.io/saleor/saleor-dashboard](https://github.com/saleor/saleor-dashboard/pkgs/container/saleor-dashboard) (`ghcr.io/saleor/saleor-dashboard:3.23.32`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`postgres:18-alpine`)
  - Valkey / Redis Cache: [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`valkey/valkey:9.0-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Saleor Core API (`sa-api`):** Primary Django/GraphQL backend application server (`ghcr.io/saleor/saleor:3.23.31`) handling catalog, checkout, orders, payments, webhooks, and GraphQL queries on container port 8000.
- **Saleor Dashboard (`sa-dashboard`):** Modern React/TypeScript administrative frontend (`ghcr.io/saleor/saleor-dashboard:3.23.32`) on container port 8080 (served via ClusterIP port 80).
- **Celery Worker (`sa-worker`):** Asynchronous background worker processing queue tasks, order emails, webhook deliveries, and analytics.
- **Celery Beat Scheduler (`sa-celery-beat`):** StatefulSet periodic task scheduler managing database-backed schedules, stock synchronization, and maintenance jobs.
- **PostgreSQL Database (`sa-postgresql`):** Dedicated relational database StatefulSet (`postgres:18-alpine`) managing products, transactions, users, and metadata with persistent storage (`8Gi`).
- **Valkey / Redis Cache (`sa-redis-master`):** In-memory key-value store and Celery broker StatefulSet (`valkey/valkey:9.0-alpine`) providing caching and fast asynchronous queue processing.
- **Database Migration Job (`migration-job`):** Automated bootstrapping job running Django database migrations on deploy/upgrade.
- **Persistent Storage Volumes:** Dedicated PersistentVolumeClaims for local media uploads (`media-pvc`), database persistence, and Redis dumps.
- **Kubernetes Services:** Dedicated ClusterIP services for API (`sa-api`), Dashboard (`sa-dashboard`), PostgreSQL (`sa-postgresql`), and Valkey/Redis (`sa-redis-master`).
- **ServiceAccount:** Dedicated unprivileged ServiceAccount for pod workloads.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Reverse proxy, Ingress controller, or Gateway for external access

## Install

To create an instance using default values:

```shell
timoni -n default apply saleor ./saleor-timoni/saleor
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	global: {
		secretKey: "your-super-secret-random-key"
	}
	api: {
		replicaCount: 2
		resources: requests: {
			cpu:    "500m"
			memory: "512Mi"
		}
	}
	dashboard: {
		enabled: true
	}
	postgresql: {
		enabled: true
		auth: {
			postgresPassword: "your-strong-db-password"
		}
	}
	redis: {
		enabled: true
		auth: {
			password: "your-strong-redis-password"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply saleor ./saleor-timoni/saleor \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete saleor
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `global.image.repository` | string | `ghcr.io/saleor/saleor` | Container image repository for Saleor API |
| `global.image.tag` | string | `3.23.31` | Container image tag for Saleor API |
| `global.secretKey` | string | `""` | Django cryptographic secret key |
| `global.storageClass` | string | `""` | StorageClass for persistent volume claims |
| `persistence.enabled` | bool | `true` | Enable persistent storage for local media files |
| `persistence.size` | string | `2Gi` | Storage size for media persistent volume |
| `api.enabled` | bool | `true` | Deploy Saleor Core GraphQL API server |
| `api.replicaCount` | int | `2` | Number of API server replicas |
| `api.service.port` | int | `8000` | Service port for API server |
| `api.resources.requests.cpu` | string | `512m` | CPU request for API server |
| `api.resources.requests.memory` | string | `512Mi` | Memory request for API server |
| `dashboard.enabled` | bool | `true` | Deploy Saleor Dashboard frontend |
| `dashboard.image.repository` | string | `ghcr.io/saleor/saleor-dashboard` | Dashboard container image repository |
| `dashboard.image.tag` | string | `3.23.32` | Dashboard container image tag |
| `dashboard.service.port` | int | `80` | Service port for Dashboard |
| `worker.enabled` | bool | `true` | Deploy Celery background worker |
| `worker.replicaCount` | int | `1` | Number of worker replicas |
| `worker.scheduler.resources` | object | `{requests: {cpu: "250m", memory: "256Mi"}}` | Resource requests for Celery Beat |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL StatefulSet |
| `postgresql.image.repository` | string | `postgres` | PostgreSQL container image |
| `postgresql.image.tag` | string | `18-alpine` | PostgreSQL version tag |
| `postgresql.primary.persistence.size` | string | `8Gi` | PostgreSQL data storage size |
| `redis.enabled` | bool | `true` | Deploy internal Valkey/Redis StatefulSet |
| `redis.image.repository` | string | `valkey/valkey` | Valkey container image |
| `redis.image.tag` | string | `9.0-alpine` | Valkey version tag |
| `redis.master.persistence.size` | string | `8Gi` | Valkey persistent volume size |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress resource |
| `podSecurityContext.runAsNonRoot` | bool | `true` | Enforce running pods as non-root user |
| `podSecurityContext.runAsUser` | int | `10001` | Pod non-root user ID |
| `podSecurityContext.fsGroup` | int | `10001` | Pod file system group ID |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent container privilege escalation |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Drop all Linux kernel capabilities |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    10001
		runAsGroup:   10001
		fsGroup:      10001
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: drop: [
			"ALL",
		]
	}
}
```

## Additional Resources
- [Official Saleor Website](https://saleor.io/)
- [Official Saleor Repository](https://github.com/saleor/saleor)
- [Saleor Documentation](https://docs.saleor.io/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Saleor module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Saleor Core API (`sa-api`) | Deployment | 12 points | ✅ |
| Saleor Dashboard (`sa-dashboard`) | Deployment | 13 points | ✅ |
| Saleor Worker (`sa-worker`) | Deployment | 13 points | ✅ |
| Celery Beat (`sa-celery-beat`) | StatefulSet | 15 points | ✅ |
| PostgreSQL Database (`sa-postgresql`) | StatefulSet | 13 points | ✅ |
| Valkey / Redis Cache (`sa-redis-master`) | StatefulSet | 13 points | ✅ |
