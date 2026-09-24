# Docmost

## Description
[Docmost](https://docmost.com/) is an open-source collaborative wiki and document sharing platform designed for technical teams and organizations. It provides real-time collaborative rich-text editing, organized knowledge spaces, permissions management, and diagrams integration as an open alternative to Notion, Confluence, and Slite.

## Application Information
- **Version:** 0.95
- **Upstream Project:** [https://github.com/docmost/docmost](https://github.com/docmost/docmost)
- **Container Base:**
  - Docmost App: [docker.io/docmost/docmost](https://hub.docker.com/r/docmost/docmost) (`docker.io/docmost/docmost:0.95`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
  - Redis / Valkey Cache: [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`docker.io/valkey/valkey:9.1.2-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Docmost Application (`docmost`):** Core collaborative documentation and wiki server running `docker.io/docmost/docmost:0.95` on container port 3000, managing real-time collaboration, document spaces, and rich-text editing.
- **PostgreSQL Database (`docmost-postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`docker.io/library/postgres:18.6-trixie`) with persistent volume storage (`8Gi`), headless service, and automated database initialization with `pg_trgm` and `unaccent` extensions.
- **Valkey / Redis Cache & Pub/Sub (`docmost-redis`):** Dedicated Valkey/Redis StatefulSet (`docker.io/valkey/valkey:9.1.2-alpine`) with persistent storage (`1Gi`) handling caching, session storage, and real-time collaboration channels.
- **Docmost Service (`docmost`):** ClusterIP service exposing port 80 (routing to container port 3000) for internal access and gateway/ingress routing.
- **PostgreSQL Services (`docmost-postgresql`, `docmost-postgresql-primary-headless`):** ClusterIP and headless services routing database traffic on port 5432.
- **Redis Services (`docmost-redis-client`, `docmost-redis-headless`):** ClusterIP and headless services routing Redis/Valkey traffic on port 6379.
- **Persistent Data Storage (`pvc`):** PersistentVolumeClaim (`10Gi`, ReadWriteOnce) persisting file attachments and user uploads when local storage mode is enabled.
- **Database Backup CronJob (`backup`):** Scheduled CronJob performing automated PostgreSQL database backups and uploading them to S3-compatible object storage via MinIO Client (`mc`).
- **Gateway API HTTPRoute / Ingress (`httproute`, `ingress`):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) or standard Kubernetes Ingress for external traffic management.
- **External Secrets Operator (`externalsecret`):** Optional ExternalSecret resources syncing application secrets, database credentials, and S3 keys from external vaults.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount for Docmost pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway) if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply docmost ./docmost
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	docmost: {
		appUrl:    "https://wiki.example.com"
		appSecret: "a-very-secret-random-key-at-least-32-chars"
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
	postgresql: {
		enabled: true
		auth: {
			database: "docmost"
			username: "docmost"
			password: "DocmostDbPassword123!"
		}
	}
	redis: {
		enabled: true
	}
	storage: {
		mode: "local"
		local: {
			size: "10Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply docmost ./docmost \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete docmost
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/docmost/docmost` | Container image repository for Docmost |
| `image.tag` | string | `0.95` | Pinned container image tag for Docmost |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `docmost.appUrl` | string | `""` | Full external base URL of the Docmost application |
| `docmost.appSecret` | string | `""` | Secret key used for cryptographic signing and sessions |
| `docmost.jwtTokenExpiresIn` | string | `30d` | JWT token lifespan for user sessions |
| `resources` | object | `{requests: {cpu: "500m", memory: "512Mi"}, limits: {cpu: "1000m", memory: "1Gi"}}` | Resource requests and limits for Docmost pods |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL 18 StatefulSet |
| `postgresql.image.repository` | string | `docker.io/library/postgres` | PostgreSQL image repository |
| `postgresql.image.tag` | string | `18.6-trixie` | Pinned PostgreSQL image tag |
| `postgresql.standalone.persistence.size` | string | `8Gi` | Storage size for PostgreSQL persistent volume |
| `redis.enabled` | bool | `true` | Deploy internal Valkey/Redis StatefulSet |
| `redis.image.repository` | string | `docker.io/valkey/valkey` | Valkey/Redis image repository |
| `redis.image.tag` | string | `9.1.2-alpine` | Pinned Valkey image tag |
| `redis.standalone.persistence.size` | string | `1Gi` | Storage size for Redis/Valkey persistent volume |
| `storage.mode` | string | `local` | Attachment storage backend (`local` or `s3`) |
| `storage.local.size` | string | `10Gi` | Storage size for local attachment volume |
| `backup.enabled` | bool | `true` | Enable scheduled automated database backups to S3 |
| `backup.schedule` | string | `0 3 * * *` | Cron schedule for automated backups |

### Recommended values

Comply with the restricted Kubernetes pod security standard:

```cue
values: {
	podSecurityContext: {
		fsGroup: 10001
	}
	securityContext: {
		runAsUser:                10001
		runAsGroup:               10001
		runAsNonRoot:             true
		readOnlyRootFilesystem:   true
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
	}
}
```

## Additional Resources
- [Official Docmost Website](https://docmost.com/)
- [Official Docmost Repository](https://github.com/docmost/docmost)
- [Docmost Documentation](https://docmost.com/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Docmost module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Docmost Core Application (`docmost`) | Deployment | 13 points | ✅  |
| PostgreSQL Database (`docmost-postgresql`) | StatefulSet | 13 points | ✅ |
| Valkey / Redis Subchart (`docmost-redis`) | StatefulSet | 15 points | ✅ |
