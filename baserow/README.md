# Baserow

## Description
[Baserow](https://baserow.io/) is an open-source online database tool and no-code data collaboration platform for teams. It allows users to organize data, build powerful applications, and automate business processes without technical experience—lowering the barriers to app creation so that anyone who can work with a spreadsheet can create a database without sacrificing control, privacy, and security.

## Application Information
- **Version:** 2.3.3
- **Upstream Project:** [https://github.com/baserow/baserow](https://github.com/baserow/baserow)
- **Container Base:** [docker.io/baserow](https://hub.docker.com/u/baserow) (`docker.io/baserow/web-frontend:2.3.3`, `docker.io/baserow/backend:2.3.3`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Web Frontend (`baserow-frontend`):** Nuxt/Vue.js Single Page Application web interface running `docker.io/baserow/web-frontend:2.3.3` on container port 3000.
- **Backend WSGI (`baserow-wsgi`):** Django synchronous application server serving the core REST API endpoints and database operations on container port 8000.
- **Backend ASGI (`baserow-asgi`):** Django Channels ASGI server managing real-time WebSockets, streaming events, and collaboration updates on container port 8000.
- **Celery Worker (`baserow-celery-worker`):** Asynchronous background worker processing queued events, webhooks, and automation actions.
- **Celery Export Worker (`baserow-celery-export-worker`):** Dedicated background worker handling resource-intensive table exports (CSV, Excel, JSON).
- **PostgreSQL Subchart (`baserow-postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`docker.io/library/postgres:18.6`) providing persistent relational storage (`8Gi`).
- **Redis Subchart (`baserow-redis`):** Dedicated Redis StatefulSet (`docker.io/library/redis:8.8`) managing Celery task queues, caching, and WebSocket channel layers with persistent storage (`8Gi`).
- **MinIO Object Storage (`baserow-minio`):** S3-compatible object storage StatefulSet (`docker.io/minio/minio:RELEASE.2025-09-07T16-13-09Z-cpuv1`) managing uploaded files, images, and user attachments (`8Gi`).
- **Caddy Reverse Proxy (`baserow-caddy`):** In-cluster HTTP reverse proxy routing incoming traffic between the frontend, WSGI API, ASGI WebSockets, and MinIO storage.
- **Database Migration (`baserow-migration`):** Automated pre-install / pre-upgrade Job ensuring database schema migrations are applied before application traffic is served.
- **Gateway API HTTPRoute (`route`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resources for modern ingress routing.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway controller if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply baserow ./baserow
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	global: {
		baserow: {
			domain:        "baserow.example.com"
			backendDomain: "api.baserow.example.com"
			objectsDomain: "media.baserow.example.com"
		}
	}
	frontend: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "200m"
				memory: "512Mi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply baserow ./baserow \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete baserow
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the module name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `global.baserow.domain` | string | `"localhost:8080"` | Primary domain for the Baserow web frontend |
| `global.baserow.backendDomain` | string | `"api.localhost:8080"` | Domain name for the Baserow backend API |
| `global.baserow.objectsDomain` | string | `"objects.localhost:8080"` | Domain name for MinIO media and attachment storage |
| `global.baserow.assistantLLMModel` | string | `"groq/openai/gpt-oss-120b"` | Default LLM model identifier for AI assistant integrations |
| `frontend.image.repository` | string | `"baserow/web-frontend"` | Frontend container image repository |
| `frontend.image.tag` | string | `"2.3.3"` | Frontend container image tag |
| `frontend.replicaCount` | int | `1` | Number of frontend replicas |
| `frontend.resources.requests.cpu` | string | `"50m"` | CPU request for the frontend pod |
| `frontend.resources.requests.memory` | string | `"256Mi"` | Memory request for the frontend pod |
| `frontend.resources.limits.cpu` | string | `"100m"` | CPU limit for the frontend pod |
| `frontend.resources.limits.memory` | string | `"800Mi"` | Memory limit for the frontend pod |
| `frontend.service.port` | int | `3000` | Port exposed by the frontend Kubernetes Service |
| `backend.image.repository` | string | `"baserow/backend"` | Backend container image repository |
| `backend.image.tag` | string | `"2.3.3"` | Backend container image tag |
| `backend.wsgi.replicaCount` | int | `1` | Number of WSGI API replicas |
| `backend.wsgi.resources.requests.cpu` | string | `"100m"` | CPU request for WSGI API pods |
| `backend.wsgi.resources.requests.memory` | string | `"512Mi"` | Memory request for WSGI API pods |
| `backend.wsgi.resources.limits.cpu` | string | `"500m"` | CPU limit for WSGI API pods |
| `backend.wsgi.resources.limits.memory` | string | `"1024Mi"` | Memory limit for WSGI API pods |
| `backend.asgi.replicaCount` | int | `1` | Number of ASGI WebSocket replicas |
| `backend.asgi.resources.requests.cpu` | string | `"100m"` | CPU request for ASGI WebSocket pods |
| `backend.asgi.resources.requests.memory` | string | `"512Mi"` | Memory request for ASGI WebSocket pods |
| `backend.asgi.resources.limits.cpu` | string | `"500m"` | CPU limit for ASGI WebSocket pods |
| `backend.asgi.resources.limits.memory` | string | `"1024Mi"` | Memory limit for ASGI WebSocket pods |
| `backend.celeryWorker.replicaCount` | int | `1` | Number of Celery background worker replicas |
| `backend.celeryWorker.resources.requests.cpu` | string | `"100m"` | CPU request for Celery worker pods |
| `backend.celeryWorker.resources.requests.memory` | string | `"512Mi"` | Memory request for Celery worker pods |
| `backend.celeryWorker.resources.limits.cpu` | string | `"500m"` | CPU limit for Celery worker pods |
| `backend.celeryWorker.resources.limits.memory` | string | `"1024Mi"` | Memory limit for Celery worker pods |
| `backend.celeryExportWorker.replicaCount` | int | `1` | Number of Celery export worker replicas |
| `backend.celeryExportWorker.resources.requests.cpu` | string | `"100m"` | CPU request for export worker pods |
| `backend.celeryExportWorker.resources.requests.memory` | string | `"512Mi"` | Memory request for export worker pods |
| `backend.celeryExportWorker.resources.limits.cpu` | string | `"500m"` | CPU limit for export worker pods |
| `backend.celeryExportWorker.resources.limits.memory` | string | `"1024Mi"` | Memory limit for export worker pods |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL subchart |
| `postgresql.image.repository` | string | `"library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"18.6"` | PostgreSQL container image tag |
| `postgresql.auth.database` | string | `"baserow"` | Initial PostgreSQL database name |
| `postgresql.persistence.enabled` | bool | `true` | Enable persistent storage for PostgreSQL data |
| `postgresql.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for PostgreSQL |
| `postgresql.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL pod |
| `postgresql.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL pod |
| `postgresql.resources.limits.cpu` | string | `"500m"` | CPU limit for PostgreSQL pod |
| `postgresql.resources.limits.memory` | string | `"512Mi"` | Memory limit for PostgreSQL pod |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis subchart |
| `redis.image.repository` | string | `"library/redis"` | Redis container image repository |
| `redis.image.tag` | string | `"8.8"` | Redis container image tag |
| `redis.persistence.enabled` | bool | `true` | Enable persistent storage for Redis data |
| `redis.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for Redis |
| `redis.resources.requests.cpu` | string | `"100m"` | CPU request for Redis pod |
| `redis.resources.requests.memory` | string | `"128Mi"` | Memory request for Redis pod |
| `redis.resources.limits.cpu` | string | `"200m"` | CPU limit for Redis pod |
| `redis.resources.limits.memory` | string | `"128Mi"` | Memory limit for Redis pod |
| `minio.enabled` | bool | `true` | Deploy dedicated MinIO object storage subchart |
| `minio.image.repository` | string | `"minio/minio"` | MinIO container image repository |
| `minio.image.tag` | string | `"RELEASE.2025-09-07T16-13-09Z-cpuv1"` | MinIO container image tag |
| `minio.persistence.enabled` | bool | `true` | Enable persistent storage for MinIO data |
| `minio.persistence.resources.requests.storage` | string | `"8Gi"` | Storage size requested for MinIO volumes |
| `minio.resources.requests.cpu` | string | `"100m"` | CPU request for MinIO pod |
| `minio.resources.requests.memory` | string | `"256Mi"` | Memory request for MinIO pod |
| `minio.resources.limits.cpu` | string | `"200m"` | CPU limit for MinIO pod |
| `minio.resources.limits.memory` | string | `"256Mi"` | Memory limit for MinIO pod |
| `caddy.enabled` | bool | `true` | Deploy internal Caddy reverse proxy |
| `caddy.image.repository` | string | `"caddy"` | Caddy container image repository |
| `caddy.image.tag` | string | `"2.11.4"` | Caddy container image tag |
| `caddy.resources.requests.cpu` | string | `"100m"` | CPU request for Caddy reverse proxy |
| `caddy.resources.requests.memory` | string | `"128Mi"` | Memory request for Caddy reverse proxy |
| `caddy.resources.limits.cpu` | string | `"200m"` | CPU limit for Caddy reverse proxy |
| `caddy.resources.limits.memory` | string | `"128Mi"` | Memory limit for Caddy reverse proxy |

## Recommended values

Baserow workloads operate as dedicated unprivileged system users (`65510:65510`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		runAsUser:    65510
		runAsGroup:   65510
		runAsNonRoot: true
		fsGroup:      65510
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
		}
		runAsUser:    65510
		runAsGroup:   65510
		runAsNonRoot: true
	}
}
```

## Additional Resources
- [Official Baserow Website](https://baserow.io/)
- [Official Baserow Repository](https://github.com/baserow/baserow)
- [Baserow Documentation](https://baserow.io/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Baserow module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Baserow Web Frontend (`baserow-frontend`) | Deployment | 13 points | ✅  |
| Baserow WSGI API (`baserow-wsgi`) | Deployment | 13 points | ✅  |
| Baserow ASGI WebSockets (`baserow-asgi`) | Deployment | 13 points | ✅  |
| Baserow Celery Worker (`baserow-celery-worker`) | Deployment | 13 points | ✅  |
| Baserow Export Worker (`baserow-celery-export-worker`) | Deployment | 13 points | ✅  |
| PostgreSQL Subchart (`baserow-postgresql`) | StatefulSet | 15 points | ✅ |
| Redis Subchart (`baserow-redis`) | StatefulSet | 15 points | ✅ |
| MinIO Object Storage (`baserow-minio`) | StatefulSet | 15 points | ✅ |
| Caddy Reverse Proxy (`baserow-caddy`) | Deployment | 7 points | ✅ |
