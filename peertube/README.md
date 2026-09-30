# PeerTube

## Description

[PeerTube](https://joinpeertube.org/) is a free, open-source, decentralized video and live streaming platform powered by ActivityPub and WebTorrent/HLS P2P. Developed by Framasoft, it enables individuals, organizations, and communities to run independent video hosting instances that federate seamlessly across the Fediverse without corporate walled gardens or tracking.

## Application Information

- **Version:** v8.2.2
- **Official Website:** [https://joinpeertube.org/](https://joinpeertube.org/)
- **Documentation:** [https://docs.joinpeertube.org/](https://docs.joinpeertube.org/)
- **Upstream Project:** [https://github.com/Chocobozzz/PeerTube](https://github.com/Chocobozzz/PeerTube)
- **Container Base:**
  - PeerTube Server: [docker.io/chocobozzz/peertube](https://hub.docker.com/r/chocobozzz/peertube) (`docker.io/chocobozzz/peertube:v8.2.2`)
  - PeerTube Runner: [docker.io/zendet/peertube-runner](https://hub.docker.com/r/zendet/peertube-runner) (`docker.io/zendet/peertube-runner:0.4.0-ctranslate2`)
  - PostgreSQL Database: [docker.io/postgres](https://hub.docker.com/_/postgres) (`docker.io/postgres:16-alpine`)
  - Redis Cache: [docker.io/redis](https://hub.docker.com/_/redis) (`docker.io/redis:7-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **PeerTube Server (`peertube-server`):** Primary workload Deployment running `docker.io/chocobozzz/peertube:v8.2.2` hosting the web application, REST API, ActivityPub federation, live streaming RTMP/RTMPS ingest, and metrics endpoints.
- **PeerTube VOD Runner (`peertube-runner-vod`):** Dedicated worker StatefulSet running `docker.io/zendet/peertube-runner:0.4.0-ctranslate2` executing remote video transcoding (Web Video, HLS) and automated transcription via Whisper AI (`whisper-ctranslate2`).
- **PostgreSQL Database (`peertube-postgresql`):** Bundled PostgreSQL 16 StatefulSet (`docker.io/postgres:16-alpine`) persisting video metadata, user channels, federation relationships, comments, and application state.
- **Redis Cache & Queue (`peertube-redis`):** Bundled Redis 7 StatefulSet (`docker.io/redis:7-alpine`) handling session caching and BullMQ background task execution.
- **PeerTube Services:**
  - `peertube-server`: ClusterIP service exposing web/API traffic on port 9000 (and optional RTMP 1935 / RTMPS 1936).
  - `peertube-server-metrics`: Optional Prometheus scraping service exposing metrics on port 9091.
  - `peertube-runner-headless`: Headless service for runner coordination.
  - `peertube-postgresql`: Internal database service on port 5432.
  - `peertube-redis`: Internal cache service on port 6379.
- **Persistent Storage Volumes:**
  - `peertube-server-storage`: Persistent volume (`ReadWriteOnce`, `20Gi`) for videos, thumbnails, torrent files, and configuration.
  - `peertube-runner-storage`: Persistent volume (`ReadWriteOnce`, `20Gi`) for runner video processing work directories.
  - `postgres-data`: Persistent volume (`ReadWriteOnce`, `10Gi`) for PostgreSQL database records.
  - `redis-data`: Persistent volume (`ReadWriteOnce`, `5Gi`) for Redis cache persistence.
- **Secrets Management:**
  - `peertube-server-admin`: Initial admin root password.
  - `peertube-server-postgres`: PostgreSQL database credentials.
  - `peertube-server-redis`: Redis authentication credentials.
  - `peertube-server-peertube-secret`: Internal application encryption secret.

## Prerequisites

- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply peertube ./peertube
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	server: {
		container: {
			resources: {
				requests: {
					cpu:    "200m"
					memory: "1Gi"
				}
				limits: {
					cpu:    "2"
					memory: "2Gi"
				}
			}
		}
		persistence: {
			size: "50Gi"
		}
	}
	postgresql: {
		enabled: true
	}
	redis: {
		enabled: true
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply peertube ./peertube \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete peertube
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `server.enabled` | bool | `true` | Enable PeerTube core server |
| `server.replicas` | int | `1` | Number of PeerTube server replicas |
| `server.container.image.repository` | string | `chocobozzz/peertube` | Container image repository |
| `server.container.image.tag` | string | `v8.2.2` | Container image tag |
| `server.container.image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `server.containerPort` | int | `9000` | PeerTube Web and API HTTP container port |
| `server.metricsPort` | int | `9091` | Prometheus metrics container port |
| `server.rtmpPort` | int | `1935` | RTMP live stream ingest container port |
| `server.rtmpsPort` | int | `1936` | RTMPS live stream ingest container port |
| `server.container.resources.requests.cpu` | string | `100m` | CPU requested for server |
| `server.container.resources.requests.memory` | string | `512Mi` | Memory requested for server |
| `server.container.resources.limits.cpu` | string | `1` | CPU limit for server |
| `server.container.resources.limits.memory` | string | `1Gi` | Memory limit for server |
| `server.container.securityContext.runAsNonRoot` | bool | `true` | Enforce running server container as non-root |
| `server.container.securityContext.readOnlyRootFilesystem` | bool | `true` | Mount server root filesystem as read-only |
| `server.container.securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent server container privilege escalation |
| `server.container.securityContext.capabilities.drop` | list | `["ALL"]` | Linux capabilities dropped for server |
| `server.podSecurityContext.runAsUser` | int | `65510` | User UID to run server pod processes |
| `server.podSecurityContext.runAsGroup` | int | `65510` | Group GID to run server pod processes |
| `server.podSecurityContext.fsGroup` | int | `65510` | Filesystem group ID for server volumes |
| `server.persistence.enabled` | bool | `true` | Enable persistent storage for video files |
| `server.persistence.size` | string | `20Gi` | Persistent storage size for video files |
| `runner.enabled` | bool | `false` | Enable remote PeerTube VOD transcoder runner |
| `runner.persistence.enabled` | bool | `true` | Enable persistent storage for runner scratch space |
| `runner.persistence.size` | string | `20Gi` | Storage size for runner temporary directory |
| `postgresql.enabled` | bool | `true` | Enable bundled PostgreSQL database |
| `postgresql.image.repository` | string | `postgres` | PostgreSQL image repository |
| `postgresql.image.tag` | string | `16-alpine` | PostgreSQL image tag |
| `postgresql.serviceAccountName` | string | `default` | ServiceAccount assigned to PostgreSQL pod |
| `postgresql.automountServiceAccountToken` | bool | `false` | Disable automounting service account token for PostgreSQL |
| `postgresql.resources.requests.cpu` | string | `100m` | CPU requested for PostgreSQL |
| `postgresql.resources.requests.memory` | string | `256Mi` | Memory requested for PostgreSQL |
| `postgresql.resources.limits.cpu` | string | `1000m` | CPU limit for PostgreSQL |
| `postgresql.resources.limits.memory` | string | `1Gi` | Memory limit for PostgreSQL |
| `postgresql.persistence.enabled` | bool | `true` | Enable persistent storage for database |
| `postgresql.persistence.size` | string | `10Gi` | Storage size for database |
| `redis.enabled` | bool | `true` | Enable bundled Redis cache |
| `redis.image.repository` | string | `redis` | Redis image repository |
| `redis.image.tag` | string | `7-alpine` | Redis image tag |
| `redis.serviceAccountName` | string | `default` | ServiceAccount assigned to Redis pod |
| `redis.automountServiceAccountToken` | bool | `false` | Disable automounting service account token for Redis |
| `redis.resources.requests.cpu` | string | `100m` | CPU requested for Redis |
| `redis.resources.requests.memory` | string | `128Mi` | Memory requested for Redis |
| `redis.resources.limits.cpu` | string | `500m` | CPU limit for Redis |
| `redis.resources.limits.memory` | string | `512Mi` | Memory limit for Redis |
| `redis.persistence.enabled` | bool | `true` | Enable persistent storage for Redis |
| `redis.persistence.size` | string | `5Gi` | Storage size for Redis |

### Recommended Pod Security Values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	server: {
		podSecurityContext: {
			runAsUser:  65510
			runAsGroup: 65510
			fsGroup:    65510
		}
		container: {
			securityContext: {
				runAsNonRoot:             true
				allowPrivilegeEscalation: false
				readOnlyRootFilesystem:   true
				capabilities: drop: ["ALL"]
				seccompProfile: type: "RuntimeDefault"
			}
		}
	}
}
```

## Additional Resources

- [Official PeerTube Website](https://joinpeertube.org/)
- [Official PeerTube Documentation](https://docs.joinpeertube.org/)
- [PeerTube GitHub Repository](https://github.com/Chocobozzz/PeerTube)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the PeerTube module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| PeerTube Server (`peertube-server`) | Deployment | 14 points | ✅ |
| PeerTube VOD Runner (`peertube-runner-vod`) | StatefulSet | 10 points | ✅ |
| PostgreSQL Database (`peertube-postgresql`) | StatefulSet | 10 points | ✅  |
| Redis Cache (`peertube-redis`) | StatefulSet | 10 points | ✅ |
