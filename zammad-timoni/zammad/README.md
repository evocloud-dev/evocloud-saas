# Zammad

## Description
[Zammad](https://zammad.org/) is a modern, open-source, web-based customer support and ticketing system designed for customer service teams, IT helpdesks, and enterprise service organizations. Built with Ruby on Rails and modern web standards, Zammad provides multi-channel customer communications (email, chat, telephone, social media, web forms), real-time ticket updates, full-text search across all interactions, customizable workflows, automated escalations, and strict data privacy compliance (GDPR-ready).

## Application Information
- **Version:** `7.1`
- **Official Website:** [https://zammad.org/](https://zammad.org/)
- **Upstream Project:** [https://github.com/zammad/zammad](https://github.com/zammad/zammad)
- **Container Base:**
  - Zammad Application (`nginx`, `railsserver`, `scheduler`, `websocket`): `ghcr.io/zammad/zammad` (`ghcr.io/zammad/zammad:7.1`)
  - Elasticsearch Search Engine: `docker.io/bitnamilegacy/elasticsearch` (`docker.io/bitnamilegacy/elasticsearch:8.18.0-debian-12-r2`)
  - PostgreSQL Database: `docker.io/bitnamilegacy/postgresql`
  - Redis / Valkey Cache & Message Broker: `docker.io/valkey/valkey` (`docker.io/valkey/valkey:9.1.0-alpine`)
  - Memcached Cache: `docker.io/bitnamilegacy/memcached`
  - MinIO Object Storage: `docker.io/bitnamilegacy/minio`
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Zammad Nginx Reverse Proxy (`za-nginx`):** Deployment (`Deployment/za-nginx`) acting as the HTTP/WebSocket reverse proxy serving web assets and routing API and WebSocket traffic on container port 8080.
- **Zammad Rails Application Server (`za-railsserver`):** Deployment (`Deployment/za-railsserver`) running the core Ruby on Rails backend, business logic, and REST APIs on container port 3000.
- **Zammad Background Scheduler (`za-scheduler`):** Deployment (`Deployment/za-scheduler`) executing cron jobs, email ingestion and delivery, and background tasks.
- **Zammad WebSocket Server (`za-websocket`):** Deployment (`Deployment/za-websocket`) managing real-time notifications, chat, and concurrent ticket editing sessions on container port 6042.
- **Elasticsearch Search Engine (`za-elasticsearch-master`):** StatefulSet (`StatefulSet/za-elasticsearch-master`) providing distributed full-text search indexing across tickets, users, articles, and attachments on container ports 9200 and 9300.
- **Memcached Cache (`za-memcached`):** Deployment (`Deployment/za-memcached`) delivering low-latency in-memory caching for Rails application objects on container port 11211.
- **MinIO Object Storage (`za-minio`):** Deployment (`Deployment/za-minio`) providing S3-compatible persistent storage for ticket attachments and media uploads on container port 9000.
- **PostgreSQL Database (`za-postgresql`):** StatefulSet (`StatefulSet/za-postgresql`) providing relational database storage for tickets, organization profiles, roles, and system metadata on container port 5432.
- **Redis Cache & Pub/Sub (`za-redis`):** StatefulSet (`StatefulSet/za-redis`) managing fast key-value caching and event pub/sub messaging on container port 6379.
- **Kubernetes Services:** ClusterIP and headless services routing internal network traffic across all nine components.
- **Secrets Management:** Managed secrets for PostgreSQL authentication, Redis passwords, Elasticsearch credentials, and S3 access tokens.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode
- Host node `vm.max_map_count >= 262144` configured (for Elasticsearch)

## Install

To create an instance using default values:

```shell
timoni -n default apply za ./zammad
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	image: {
		tag: "7.1"
	}
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
	elasticsearch: {
		master: {
			resources: {
				requests: {
					cpu:    "100m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1000m"
					memory: "2Gi"
				}
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply za ./zammad \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```shell
timoni -n default delete za
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `ghcr.io/zammad/zammad` | Zammad container image repository |
| `image.tag` | string | `7.1` | Pinned container image tag |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `service.port` | int | `8080` | Nginx frontend HTTP service port |
| `zammadConfig.nginx.replicas` | int | `1` | Number of Nginx frontend replicas |
| `zammadConfig.railsserver.replicas` | int | `1` | Number of Rails application server replicas |
| `zammadConfig.elasticsearch.enabled` | bool | `true` | Deploy internal Elasticsearch cluster |
| `zammadConfig.memcached.enabled` | bool | `true` | Deploy internal Memcached cache instance |
| `zammadConfig.minio.enabled` | bool | `true` | Deploy internal MinIO S3 object storage |
| `zammadConfig.postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database |
| `zammadConfig.redis.enabled` | bool | `true` | Deploy internal Redis cache & message broker |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress for external traffic |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	securityContext: {
		fsGroup:      1000
		runAsUser:    1000
		runAsGroup:   1000
		runAsNonRoot: true
		seccompProfile: type: "RuntimeDefault"
	}
	zammadConfig: {
		nginx: securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
			readOnlyRootFilesystem: true
			privileged:             false
		}
		railsserver: securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
			readOnlyRootFilesystem: true
			privileged:             false
		}
		scheduler: securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
			readOnlyRootFilesystem: true
			privileged:             false
		}
		websocket: securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
			readOnlyRootFilesystem: true
			privileged:             false
		}
	}
}
```

## Additional Resources
- [Official Zammad Website](https://zammad.org/)
- [Official Zammad Repository](https://github.com/zammad/zammad)
- [Zammad Documentation](https://docs.zammad.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Zammad module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Nginx Reverse Proxy (`za-nginx`) | Deployment | 12 points | ✅ |
| Rails Server (`za-railsserver`) | Deployment | 12 points | ✅ |
| Task Scheduler (`za-scheduler`) | Deployment | 12 points | ✅ |
| WebSocket Server (`za-websocket`) | Deployment | 12 points | ✅ |
| Memcached Cache (`za-memcached`) | Deployment | 14 points | ✅ |
| MinIO Storage (`za-minio`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`za-postgresql`) | StatefulSet | 14 points | ✅ |
| Redis Cache (`za-redis`) | StatefulSet | 14 points | ✅ |
| Elasticsearch Master (`za-elasticsearch-master`)* | StatefulSet | 15 points | ✅ |

