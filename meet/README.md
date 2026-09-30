# Meet

## Description
[Meet](https://github.com/suitenumerique/meet) is an open-source, sovereign video conferencing web application developed by La Suite Numérique (French inter-ministerial digital team). Designed for seamless and secure remote collaboration, Meet provides high-performance real-time audio and video conferencing powered by LiveKit WebRTC, comprehensive meeting intelligence features (including automated speech transcription and AI summarization via Celery workers), media storage with MinIO, and identity federation using Keycloak OIDC.

## Application Information
- **Version:** 1.0.1 (App: v1.23.0)
- **Upstream Project:** [https://github.com/suitenumerique/meet](https://github.com/suitenumerique/meet)
- **Container Base:** [lasuite/meet-backend](https://hub.docker.com/r/lasuite/meet-backend), [lasuite/meet-frontend](https://hub.docker.com/r/lasuite/meet-frontend), [lasuite/meet-summary](https://hub.docker.com/r/lasuite/meet-summary), [lasuite/meet-agents](https://hub.docker.com/r/lasuite/meet-agents)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Meet Frontend (`meet-frontend`):** Web user interface running `lasuite/meet-frontend:v1.23.0` serving the client-side SPA.
- **Meet Backend API (`meet-backend`):** Core Django application server running `lasuite/meet-backend:v1.23.0` handling rooms, meeting permissions, recordings, and REST API services.
- **Meet Summary (`meet-summary`):** Meeting intelligence and summarization web service running `lasuite/meet-summary:v1.23.0`.
- **Celery Backend Worker (`meet-celery-backend`):** Celery background worker processing asynchronous tasks and notifications for the core backend.
- **Celery Transcribe Worker (`meet-celery-transcribe-default`):** Celery worker processing audio transcription queues (`transcribe-queue`, `transcribe-queue-v2`).
- **Celery Summarize Worker (`meet-celery-summarize`):** Celery worker processing meeting summary and LLM pipelines (`summarize-queue`, `summarize-queue-v2`).
- **Celery Summary Backend Worker (`meet-celery-summary-backend`):** Celery worker handling webhook callbacks (`call-webhook-queue-v2`).
- **Meet Agent Subtitles (`meet-agent-subtitles`):** Real-time subtitles and transcription agent running `lasuite/meet-agents:v1.23.0`.
- **Meet Agent Metadata (`meet-agent-metadata`):** Live meeting participant and metadata tracking agent running `lasuite/meet-agents:v1.23.0`.
- **PostgreSQL Database (`postgresql`):** Dedicated PostgreSQL 17 StatefulSet (`postgres:17-alpine`) providing persistent relational storage for Meet.
- **Keycloak PostgreSQL Database (`kc-postgresql`):** Dedicated PostgreSQL 17 StatefulSet (`postgres:17-alpine`) managing authentication and identity data for Keycloak.
- **Redis Cache & Broker (`redis`):** In-memory cache and Celery task broker running `redis:8.8-alpine`.
- **Keycloak IAM (`keycloak`):** OpenID Connect (OIDC) identity provider StatefulSet running `quay.io/keycloak/keycloak:26.7.0` configured with the pre-provisioned Meet realm.
- **MinIO Object Storage (`meet-minio`):** S3-compatible object storage managing meeting recordings, transcripts, and media files.
- **LiveKit Server (`livekit`):** Scalable, high-performance real-time WebRTC media and signaling server running `livekit/livekit-server:v1.13.3`.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Ingress controller (e.g. NGINX Ingress Controller) with TLS certificate secrets configured

## Install

To create an instance using default values:

```shell
timoni -n default apply meet ./meet
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	ingress: {
		host: "meet.example.com"
	}
	keycloak: {
		host: "keycloak.example.com"
	}
	livekit: {
		host: "livekit.example.com"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply meet ./meet \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete meet
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"lasuite/meet-backend"` | Default backend container image repository |
| `image.tag` | string | `"v1.23.0"` | Default backend container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Container image pull policy |
| `nameOverride` | string | `""` | Override the module name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `ingress.enabled` | bool | `true` | Enable Ingress resource for frontend and backend API |
| `ingress.className` | string | `"nginx"` | IngressClass controller name |
| `ingress.host` | string | `"meet.127.0.0.1.nip.io"` | Ingress hostname for the Meet application |
| `ingress.tls.enabled` | bool | `true` | Enable TLS termination on Ingress |
| `ingress.tls.secretName` | string | `"mkcert"` | TLS certificate secret name |
| `backend.replicas` | int | `1` | Number of Meet backend API replicas |
| `backend.resources.requests.cpu` | string | `"10m"` | CPU request for backend API |
| `backend.resources.requests.memory` | string | `"256Mi"` | Memory request for backend API |
| `backend.resources.limits.cpu` | string | `"500m"` | CPU limit for backend API |
| `backend.resources.limits.memory` | string | `"768Mi"` | Memory limit for backend API |
| `frontend.replicas` | int | `1` | Number of Meet frontend replicas |
| `frontend.resources.requests.cpu` | string | `"10m"` | CPU request for frontend |
| `frontend.resources.requests.memory` | string | `"32Mi"` | Memory request for frontend |
| `frontend.resources.limits.cpu` | string | `"200m"` | CPU limit for frontend |
| `frontend.resources.limits.memory` | string | `"128Mi"` | Memory limit for frontend |
| `summary.replicas` | int | `1` | Number of Meet summary service replicas |
| `summary.resources.requests.cpu` | string | `"10m"` | CPU request for summary service |
| `summary.resources.requests.memory` | string | `"32Mi"` | Memory request for summary service |
| `summary.resources.limits.cpu` | string | `"200m"` | CPU limit for summary service |
| `summary.resources.limits.memory` | string | `"128Mi"` | Memory limit for summary service |
| `celeryBackend.replicas` | int | `1` | Number of Celery backend worker replicas |
| `celeryTranscribe.replicas` | int | `1` | Number of Celery transcribe worker replicas |
| `celerySummarize.replicas` | int | `1` | Number of Celery summarize worker replicas |
| `celerySummaryBackend.replicas` | int | `1` | Number of Celery summary backend worker replicas |
| `agentMetadata.replicas` | int | `1` | Number of agent metadata replicas |
| `agentSubtitles.replicas` | int | `1` | Number of agent subtitles replicas |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database for Meet |
| `postgresql.image.tag` | string | `"17-alpine"` | PostgreSQL image tag |
| `postgresql.database` | string | `"meet"` | PostgreSQL database name |
| `postgresql.username` | string | `"dinum"` | PostgreSQL user |
| `kc_postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database for Keycloak |
| `kc_postgresql.image.tag` | string | `"17-alpine"` | Keycloak PostgreSQL image tag |
| `kc_postgresql.database` | string | `"keycloak"` | Keycloak database name |
| `redis.enabled` | bool | `true` | Deploy internal Redis broker and cache |
| `redis.image.tag` | string | `"8.8-alpine"` | Redis image tag |
| `keycloak.enabled` | bool | `true` | Deploy Keycloak identity and access management |
| `keycloak.image.tag` | string | `"26.7.0"` | Keycloak container image tag |
| `keycloak.host` | string | `"keycloak.127.0.0.1.nip.io"` | Keycloak hostname |
| `minio.enabled` | bool | `true` | Deploy MinIO object storage for media and recordings |
| `livekit.enabled` | bool | `true` | Deploy LiveKit WebRTC server |
| `livekit.image.tag` | string | `"v1.13.3"` | LiveKit container image tag |
| `livekit.host` | string | `"livekit.127.0.0.1.nip.io"` | LiveKit server hostname |

## Recommended values

Meet workloads operate as dedicated unprivileged system users (`65510:65510`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    65510
		runAsGroup:   65510
		fsGroup:      65510
		seccompProfile: type: "RuntimeDefault"
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		runAsUser:                65510
		runAsGroup:               65510
		capabilities: drop: ["ALL"]
	}
}
```

## Additional Resources
- [Official Meet Repository](https://github.com/suitenumerique/meet)
- [La Suite Numérique](https://lasuite.numerique.gouv.fr/)
- [LiveKit Documentation](https://docs.livekit.io/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Meet module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Meet Frontend (`meet-frontend`) | Deployment | 14 points | ✅ |
| Meet Summary (`meet-summary`) | Deployment | 14 points | ✅ |
| Meet Backend (`meet-backend`) | Deployment | 14 points | ✅ |
| Meet Celery Backend (`meet-celery-backend`) | Deployment | 14 points | ✅ |
| Meet Celery Summarize (`meet-celery-summarize`) | Deployment | 14 points | ✅ |
| Meet Celery Summary Backend (`meet-celery-summary-backend`) | Deployment | 14 points | ✅ |
| Meet Agent Subtitles (`meet-agent-subtitles`) | Deployment | 14 points | ✅ |
| Meet Agent Metadata (`meet-agent-metadata`) | Deployment | 14 points | ✅ |
| PostgreSQL Database (`postgresql`) | StatefulSet | 14 points | ✅ |
| Keycloak PostgreSQL Database (`kc-postgresql`) | StatefulSet | 15 points | ✅ |
| Redis Cache (`redis`) | Deployment | 14 points | ✅ |
| Keycloak IAM (`keycloak`) | StatefulSet | 16 points | ✅ |
| MinIO Object Storage (`meet-minio`) | Deployment | 14 points | ✅ |
| LiveKit WebRTC Server (`livekit`) | Deployment | 14 points | ✅ |
| Meet Celery Transcribe Default (`meet-celery-transcribe-default`) | Deployment | 14 points | ✅ |
