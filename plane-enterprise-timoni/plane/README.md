# Plane Enterprise

## Description
[Plane](https://plane.so/) provides project management and knowledge management for teams and agents. Plane brings projects, docs, and AI-powered workflows into one unified workspace so teams and agents can plan, execute, and stay aligned.

## Application Information
- **Version:** v2.6.3
- **Official Website:** [https://plane.so/](https://plane.so/)
- **Upstream Project:** [https://github.com/makeplane/plane](https://github.com/makeplane/plane)
- **Container Images:**
  - Admin Console: `artifacts.plane.so/makeplane/admin-commercial`
  - Core API Server: `artifacts.plane.so/makeplane/backend-commercial`
  - Web Application: `artifacts.plane.so/makeplane/web-commercial`
  - Space Community Portal: `artifacts.plane.so/makeplane/space-commercial`
  - Live Collaboration Server: `artifacts.plane.so/makeplane/live-commercial`
  - Monitor Telemetry: `artifacts.plane.so/makeplane/monitor-commercial`
  - Plane AI (Pi): `artifacts.plane.so/makeplane/plane-pi-commercial`
  - Iframely Media Embeds: `artifacts.plane.so/makeplane/iframely:v1.2.0`
  - Silo Integrations: `artifacts.plane.so/makeplane/silo-commercial`
  - Email Service: `artifacts.plane.so/makeplane/email-commercial`
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`postgres:18.6-alpine`)
  - Valkey / Redis Cache: [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`valkey/valkey:9.1.2-alpine`)
  - RabbitMQ Message Broker: [docker.io/library/rabbitmq](https://hub.docker.com/_/rabbitmq) (`rabbitmq:4.3.5-management-alpine`)
  - OpenSearch Vector & Search Engine: [docker.io/opensearchproject/opensearch](https://hub.docker.com/r/opensearchproject/opensearch) (`opensearchproject/opensearch:3.8.0`)
  - MinIO S3 Object Storage: [docker.io/minio/minio](https://hub.docker.com/r/minio/minio) (`minio/minio:latest`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Enterprise Workload

## Components
- **Admin Console (`plane-admin-wl`):** Nginx-based frontend administration interface (`artifacts.plane.so/makeplane/admin-commercial`) running as non-root UID `10001` with drop `ALL` capabilities and dedicated memory-backed cache directories.
- **Backend Core API (`plane-api-wl`):** Primary Django REST framework application server (`artifacts.plane.so/makeplane/backend-commercial`) managing issues, cycles, modules, roadmaps, and authorization.
- **Automation Consumer (`plane-automation-consumer-wl`):** Background worker consuming event streams from RabbitMQ (`plane.event_stream`) to process issue automations, auto-closures, and webhook dispatches.
- **Celery Beat Worker (`plane-beat-worker-wl`):** Periodic scheduler executing time-based recurring maintenance tasks, SLA reminders, and digest dispatches.
- **Iframely Embed Service (`plane-iframely-wl`):** Dedicated oEmbed parser and rich card preview generator (`artifacts.plane.so/makeplane/iframely:v1.2.0`).
- **Live Server (`plane-live-wl`):** High-concurrency WebSocket and real-time collaboration gateway (`artifacts.plane.so/makeplane/live-commercial`) maintaining presence and live updates.
- **MinIO Object Storage (`plane-minio`):** Dedicated S3-compatible local blob store StatefulSet managing user avatars, issue attachments, and document uploads.
- **Monitor Daemon (`plane-monitor-wl`):** Telemetry, health check, and system diagnostics StatefulSet (`artifacts.plane.so/makeplane/monitor-commercial`) with dedicated local storage (`100Mi`).
- **OpenSearch Cluster (`plane-opensearch-wl`):** Distributed search engine and high-dimensional vector store (`opensearchproject/opensearch:3.8.0`) indexing workspace items and storing AI embeddings (`1536` dimensions), running as unprivileged UID `1000`.
- **PostgreSQL Database (`plane-pgdb-wl`):** Primary relational database StatefulSet (`postgres:18.6-alpine`) storing application schema and Plane AI data (`plane_pi`), running securely as UID `70`.
- **RabbitMQ Message Broker (`plane-rabbitmq-wl`):** AMQP message broker StatefulSet (`rabbitmq:4.3.5-management-alpine`) managing task queues, background workers, and automation event streams, running as UID `999`.
- **Valkey / Redis Cache (`plane-redis-wl`):** High-throughput in-memory key-value cache StatefulSet (`valkey/valkey:9.1.2-alpine`) managing session caching, rate limiting, and pub/sub channels, running as UID `999`.
- **Transactional Outbox Poller (`plane-outbox-poller-wl`):** Poller service ensuring reliable at-least-once message dispatch from PostgreSQL to RabbitMQ.
- **Plane AI Core API (`plane-pi-api-wl`):** AI service gateway (`artifacts.plane.so/makeplane/plane-pi-commercial`) orchestrating LLM interactions across OpenAI, Claude, Groq, Cohere, custom self-hosted models, and embedding providers.
- **Plane AI Celery Beat Scheduler (`plane-pi-beat-wl`):** Dedicated Celery Beat scheduler executing periodic AI vector sync, doc synchronization, and workspace plan indexing.
- **Plane AI Background Worker (`plane-pi-worker-wl`):** Asynchronous task executor processing embedding generations, vector indexing pipelines, and document chunking.
- **Space Public Portal (`plane-space-wl`):** Customer-facing public issue tracker and roadmap portal (`artifacts.plane.so/makeplane/space-commercial`).
- **Web Frontend (`plane-web-wl`):** Primary React/Next.js web client (`artifacts.plane.so/makeplane/web-commercial`) serving the application user interface.
- **General Asynchronous Worker (`plane-worker-wl`):** Core Celery worker processing background jobs, export rendering, email dispatches, and heavy compute tasks.
- **Kubernetes Services & Ingress:** Dedicated ClusterIP services for all microservices, optional Traefik IngressRoute / standard Ingress, and cert-manager Certificate issuers.
- **ServiceAccount:** Unprivileged ServiceAccount (`plane-srv-account`) with `automountServiceAccountToken: false` applied across all pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Traefik or Ingress-NGINX controller (if external ingress is enabled)
- cert-manager (if automated Let's Encrypt TLS certificate issuance is enabled)

## Install

To create an instance using default values:

```shell
timoni -n default apply plane ./plane-enterprise-timoni/plane
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	planeVersion: "v2.6.3"

	license: {
		licenseServer: "https://prime.plane.so"
		licenseDomain: "plane.example.com"
	}

	ingress: {
		enabled:      true
		ingressClass: "traefik"
	}

	services: {
		postgres: {
			volumeSize: "20Gi"
		}
		opensearch: {
			volumeSize: "20Gi"
		}
		redis: {
			volumeSize: "2Gi"
		}
		minio: {
			volumeSize: "50Gi"
		}
	}

	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    10001
		runAsGroup:   10001
		fsGroup:      10001
	}

	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply plane ./plane-enterprise-timoni/plane \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete plane
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `planeVersion` | string | `v2.6.3` | Application version tag of Plane Enterprise |
| `dockerRegistry.enabled` | bool | `false` | Enable private Docker registry authentication |
| `dockerRegistry.registry` | string | `index.docker.io/v1/` | Container image registry endpoint |
| `dockerRegistry.existingSecret` | string | `""` | Existing Kubernetes Secret for registry credentials |
| `license.licenseServer` | string | `https://prime.plane.so` | Enterprise license authentication server |
| `license.licenseDomain` | string | `plane.example.com` | Licensed domain name for this Plane instance |
| `airgapped.enabled` | bool | `false` | Enable airgapped deployment mode |
| `airgapped.s3Secrets` | list | `[]` | List of Kubernetes Secrets containing custom S3 CA certificate bundles |
| `ingress.enabled` | bool | `true` | Enable external ingress routing |
| `ingress.ingressClass` | string | `traefik` | Ingress controller class name (`traefik` or `nginx`) |
| `ingress.traefik.maxRequestBodyBytes` | int | `20971520` | Max request body limit for Traefik middleware (20 MiB) |
| `ssl.tls_secret_name` | string | `""` | Existing TLS secret name for HTTPS termination |
| `ssl.createIssuer` | bool | `false` | Enable automated cert-manager TLS issuer |
| `ssl.issuer` | string | `http` | cert-manager issuer type (`http`, `cloudflare`, `digitalocean`) |
| `services.redis.local_setup` | bool | `true` | Deploy internal Valkey/Redis StatefulSet |
| `services.redis.image` | string | `valkey/valkey:9.1.2-alpine` | Container image for Valkey/Redis cache |
| `services.redis.volumeSize` | string | `500Mi` | Storage size for Redis/Valkey persistent volume |
| `services.postgres.local_setup` | bool | `true` | Deploy internal PostgreSQL StatefulSet |
| `services.postgres.image` | string | `postgres:18.6-alpine` | Container image for PostgreSQL database |
| `services.postgres.volumeSize` | string | `2Gi` | Storage size for PostgreSQL persistent volume |
| `services.rabbitmq.local_setup` | bool | `true` | Deploy internal RabbitMQ StatefulSet |
| `services.rabbitmq.image` | string | `rabbitmq:4.3.5-management-alpine` | Container image for RabbitMQ broker |
| `services.rabbitmq.volumeSize` | string | `100Mi` | Storage size for RabbitMQ persistent volume |
| `services.opensearch.local_setup` | bool | `true` | Deploy internal OpenSearch StatefulSet |
| `services.opensearch.image` | string | `opensearchproject/opensearch:3.8.0` | Container image for OpenSearch cluster |
| `services.opensearch.volumeSize` | string | `5Gi` | Storage size for OpenSearch persistent volume |
| `services.minio.local_setup` | bool | `true` | Deploy internal MinIO S3 object storage |
| `services.minio.image` | string | `minio/minio:latest` | Container image for MinIO server |
| `services.minio.volumeSize` | string | `3Gi` | Storage size for MinIO persistent volume |
| `services.web.replicas` | int | `1` | Replicas for Web frontend UI |
| `services.web.image` | string | `artifacts.plane.so/makeplane/web-commercial` | Container image for Web frontend |
| `services.api.replicas` | int | `1` | Replicas for core Django REST API server |
| `services.api.image` | string | `artifacts.plane.so/makeplane/backend-commercial` | Container image for core API |
| `services.worker.replicas` | int | `1` | Replicas for core background Celery worker |
| `services.beatworker.replicas` | int | `1` | Replicas for Celery Beat scheduler |
| `services.space.replicas` | int | `1` | Replicas for Space customer portal |
| `services.space.image` | string | `artifacts.plane.so/makeplane/space-commercial` | Container image for Space portal |
| `services.admin.replicas` | int | `1` | Replicas for Admin console |
| `services.admin.image` | string | `artifacts.plane.so/makeplane/admin-commercial` | Container image for Admin console |
| `services.live.replicas` | int | `1` | Replicas for Live collaboration WebSocket server |
| `services.live.image` | string | `artifacts.plane.so/makeplane/live-commercial` | Container image for Live server |
| `services.monitor.image` | string | `artifacts.plane.so/makeplane/monitor-commercial` | Container image for Monitor daemon |
| `services.outbox_poller.enabled` | bool | `true` | Enable transactional outbox poller |
| `services.automation_consumer.enabled` | bool | `true` | Enable RabbitMQ automation event consumer |
| `services.pi.enabled` | bool | `true` | Enable Plane AI (Pi) orchestration API |
| `services.pi.image` | string | `artifacts.plane.so/makeplane/plane-pi-commercial` | Container image for Plane AI |
| `services.pi_beat_worker.replicas` | int | `1` | Replicas for Plane AI Celery Beat scheduler |
| `services.pi_worker.replicas` | int | `1` | Replicas for Plane AI asynchronous worker |
| `services.iframely.enabled` | bool | `false` | Enable Iframely rich preview service |
| `services.silo.enabled` | bool | `false` | Enable Silo external connector integrations |
| `services.email_service.enabled` | bool | `false` | Enable dedicated SMTP email delivery service |
| `external_secrets.rabbitmq_existingSecret` | string | `""` | Existing Secret for RabbitMQ credentials |
| `external_secrets.pgdb_existingSecret` | string | `""` | Existing Secret for PostgreSQL credentials |
| `external_secrets.opensearch_existingSecret` | string | `""` | Existing Secret for OpenSearch credentials |
| `external_secrets.doc_store_existingSecret` | string | `""` | Existing Secret for S3 storage credentials |
| `env.use_storage_proxy` | bool | `true` | Proxy attachment uploads through API for internal MinIO |
| `env.doc_upload_size_limit` | string | `5242880` | Maximum file attachment size in bytes (5 MiB) |
| `podSecurityContext.runAsNonRoot` | bool | `true` | Run pod containers as non-root user |
| `podSecurityContext.runAsUser` | int | `10001` | Non-root user ID for application pods |
| `podSecurityContext.runAsGroup` | int | `10001` | Non-root group ID for application pods |
| `podSecurityContext.fsGroup` | int | `10001` | File system permissions group ID |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
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
- [Official Plane Website](https://plane.so/)
- [Official Plane Repository](https://github.com/makeplane/plane)
- [Plane Documentation](https://docs.plane.so/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Plane Enterprise module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Admin Console (`plane-admin-wl`) | Deployment | 13 points | ✅ |
| Backend Core API (`plane-api-wl`) | Deployment | 13 points | ✅ |
| Automation Consumer (`plane-automation-consumer-wl`) | Deployment | 13 points | ✅ |
| Celery Beat Worker (`plane-beat-worker-wl`) | Deployment | 13 points | ✅ |
| Iframely Embed Service (`plane-iframely-wl`) | Deployment | 13 points | ✅ |
| Live Collaboration Server (`plane-live-wl`) | Deployment | 13 points | ✅ |
| MinIO Object Storage (`plane-minio`) | StatefulSet | 11 points | ✅ |
| Monitor Daemon (`plane-monitor-wl`) | StatefulSet | 15 points | ✅ |
| OpenSearch Vector & Search Cluster (`plane-opensearch-wl`) | StatefulSet | 13 points | ✅ |
| PostgreSQL Relational Database (`plane-pgdb-wl`) | StatefulSet | 13 points | ✅ |
| RabbitMQ Message Broker (`plane-rabbitmq-wl`) | StatefulSet | 13 points | ✅ |
| Valkey / Redis Cache (`plane-redis-wl`) | StatefulSet | 13 points | ✅ |
| Transactional Outbox Poller (`plane-outbox-poller-wl`) | Deployment | 13 points | ✅ |
| Plane AI Core API (`plane-pi-api-wl`) | Deployment | 13 points | ✅ |
| Plane AI Celery Beat Scheduler (`plane-pi-beat-wl`) | Deployment | 13 points | ✅ |
| Plane AI Background Worker (`plane-pi-worker-wl`) | Deployment | 13 points | ✅ |
| Space Customer Portal (`plane-space-wl`) | Deployment | 13 points | ✅ |
| Web Frontend Client (`plane-web-wl`) | Deployment | 13 points | ✅ |
| General Asynchronous Worker (`plane-worker-wl`) | Deployment | 13 points | ✅ |
