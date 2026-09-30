# Paperless-ngx

## Description

[Paperless-ngx](https://docs.paperless-ngx.com/) is an open-source document management system that transforms physical documents into searchable online archives. Using optical character recognition (OCR), machine learning tagging, and automated document indexing, Paperless-ngx organizes scanned receipts, invoices, statements, and PDFs into an accessible, searchable repository.

## Application Information

- **Version:** 3.1.3
- **Official Website:** [https://docs.paperless-ngx.com/](https://docs.paperless-ngx.com/)
- **Upstream Project:** [https://github.com/paperless-ngx/paperless-ngx](https://github.com/paperless-ngx/paperless-ngx)
- **Container Base:**
  - Paperless-ngx Core: [ghcr.io/paperless-ngx/paperless-ngx](https://github.com/paperless-ngx/paperless-ngx/pkgs/container/paperless-ngx) (`ghcr.io/paperless-ngx/paperless-ngx:3.1.3`)
  - Valkey / Redis Broker: [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`docker.io/valkey/valkey:9.1.2-alpine`)
  - PostgreSQL Database: [docker.io/postgres](https://hub.docker.com/_/postgres) (`docker.io/postgres:18-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Paperless-ngx Core (`paper`):** Primary workload Deployment running `ghcr.io/paperless-ngx/paperless-ngx:3.1.3` on container port 8000, hosting the web interface, REST API, OCR pipelines, and Celery consumer workers.
- **Valkey / Redis Broker (`paper-redis-master`):** Dedicated Valkey/Redis Deployment (`docker.io/valkey/valkey:9.1.2-alpine`) serving as the asynchronous message broker and cache for document indexing queues.
- **PostgreSQL Database (`paper-postgresql`):** Dedicated PostgreSQL Deployment (`docker.io/postgres:18-alpine`) storing document metadata, full-text indexes, tags, user accounts, and system configuration.
- **Core Service (`paper`):** ClusterIP service routing HTTP traffic on port 8000 to the Paperless-ngx web application.
- **Redis Services (`paper-redis-master`, `paper-redis-headless`):** ClusterIP and headless services routing Redis cache/broker traffic on port 6379.
- **PostgreSQL Services (`paper-postgresql`, `paper-postgresql-headless`):** ClusterIP and headless services routing database traffic on port 5432.
- **Persistent Storage Volumes:**
  - `paper-data`: Persistent volume for SQLite/internal index data (`/usr/src/paperless/data`).
  - `paper-media`: Persistent volume for uploaded and archived document files (`/usr/src/paperless/media`).
  - `paper-consume`: Persistent volume for incoming document consumption directory (`/usr/src/paperless/consume`).
  - `paper-export`: Persistent volume for document exports and backups (`/usr/src/paperless/export`).
  - `paper-redis-master`: Persistent volume for Redis persistence (`/data`).
  - `paper-postgresql`: Persistent volume for PostgreSQL database storage (`/var/lib/postgresql/data`).
- **Secrets Management:**
  - `paper-redis`: Secret storing Redis authentication credentials (`redis-password`).
  - `paper-postgresql`: Secret storing PostgreSQL database authentication credentials (`postgres-password`).

## Prerequisites

- Kubernetes cluster v1.22+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply paperless-timoni ./paperless-timoni
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	resources: {
		requests: {
			cpu:    "200m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "2Gi"
		}
	}
	postgresql: {
		enabled: true
		auth: {
			database:         "paperless"
			username:         "paperless"
			postgresPassword: "StrongPassword123!"
		}
	}
	redis: {
		enabled: true
	}
	persistence: {
		media: {
			size: "20Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply paperless-timoni ./paperless-timoni \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete paperless-timoni
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `ghcr.io/paperless-ngx/paperless-ngx` | Container image repository |
| `image.tag` | string | `3.1.3` | Container image tag |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `service.main.ports.http.port` | int | `8000` | Kubernetes Service HTTP port |
| `env` | map | `{}` | Additional environment variables for Paperless |
| `securityContext.runAsUser` | int | `1000` | User UID to run container process |
| `securityContext.runAsGroup` | int | `1000` | User GID to run container process |
| `securityContext.fsGroup` | int | `1000` | Filesystem group ID for pod volumes |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce running as non-root user |
| `securityContext.readOnlyRootFilesystem` | bool | `true` | Mount root filesystem as read-only |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Linux capabilities dropped |
| `resources.requests.cpu` | string | `100m` | CPU requested for Paperless core |
| `resources.requests.memory` | string | `256Mi` | Memory requested for Paperless core |
| `resources.limits.cpu` | string | `1000m` | CPU limit for Paperless core |
| `resources.limits.memory` | string | `1Gi` | Memory limit for Paperless core |
| `persistence.data.enabled` | bool | `true` | Enable persistent storage for data directory |
| `persistence.data.size` | string | `1Gi` | Storage size for data directory |
| `persistence.media.enabled` | bool | `true` | Enable persistent storage for media archive |
| `persistence.media.size` | string | `8Gi` | Storage size for media archive |
| `persistence.consume.enabled` | bool | `true` | Enable persistent storage for consume directory |
| `persistence.consume.size` | string | `4Gi` | Storage size for consume directory |
| `persistence.export.enabled` | bool | `true` | Enable persistent storage for export directory |
| `persistence.export.size` | string | `1Gi` | Storage size for export directory |
| `postgresql.enabled` | bool | `true` | Enable bundled PostgreSQL database |
| `postgresql.image.repository` | string | `docker.io/postgres` | PostgreSQL image repository |
| `postgresql.image.tag` | string | `18-alpine` | PostgreSQL image tag |
| `postgresql.auth.database` | string | `paperless` | PostgreSQL database name |
| `postgresql.auth.username` | string | `postgres` | PostgreSQL username |
| `postgresql.auth.postgresPassword` | string | `changeme` | PostgreSQL password |
| `postgresql.serviceAccount.automountServiceAccountToken` | bool | `false` | Disable automounting service account token |
| `postgresql.securityContext.runAsUser` | int | `70` | PostgreSQL Pod runAsUser UID |
| `postgresql.securityContext.runAsGroup` | int | `70` | PostgreSQL Pod runAsGroup GID |
| `postgresql.securityContext.fsGroup` | int | `70` | PostgreSQL Pod fsGroup GID |
| `postgresql.securityContext.runAsNonRoot` | bool | `true` | Enforce running PostgreSQL as non-root |
| `postgresql.containerSecurityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `postgresql.containerSecurityContext.capabilities.drop` | list | `["ALL"]` | Linux capabilities dropped for PostgreSQL |
| `postgresql.primary.persistence.enabled` | bool | `true` | Enable persistent storage for PostgreSQL |
| `postgresql.primary.persistence.size` | string | `8Gi` | Storage size for PostgreSQL database |
| `redis.enabled` | bool | `true` | Enable bundled Valkey/Redis cache & broker |
| `redis.image.repository` | string | `docker.io/valkey/valkey` | Redis / Valkey image repository |
| `redis.image.tag` | string | `9.1.2-alpine` | Redis / Valkey image tag |
| `redis.serviceAccount.automountServiceAccountToken` | bool | `false` | Disable automounting service account token |
| `redis.securityContext.runAsUser` | int | `999` | Redis Pod runAsUser UID |
| `redis.securityContext.runAsGroup` | int | `999` | Redis Pod runAsGroup GID |
| `redis.securityContext.fsGroup` | int | `999` | Redis Pod fsGroup GID |
| `redis.securityContext.runAsNonRoot` | bool | `true` | Enforce running Redis as non-root |
| `redis.containerSecurityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `redis.containerSecurityContext.capabilities.drop` | list | `["ALL"]` | Linux capabilities dropped for Redis |
| `redis.master.persistence.enabled` | bool | `true` | Enable persistent storage for Redis |
| `redis.master.persistence.size` | string | `8Gi` | Storage size for Redis persistence |

### Recommended Pod Security Values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	securityContext: {
		runAsUser:                1000
		runAsGroup:               1000
		fsGroup:                  1000
		runAsNonRoot:             true
		readOnlyRootFilesystem:   false
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}
}
```

## Additional Resources

- [Official Paperless-ngx Documentation](https://docs.paperless-ngx.com/)
- [Paperless-ngx GitHub Repository](https://github.com/paperless-ngx/paperless-ngx)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Paperless module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Paperless-ngx Core (`paper`) | Deployment | 12 points | ✅  |
| Valkey / Redis Broker (`paper-redis-master`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`paper-postgresql`) | Deployment | 11 points | ✅ |
