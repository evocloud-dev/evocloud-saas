# Chatwoot

## Description
[Chatwoot](https://www.chatwoot.com/) is an open-source, omni-channel customer engagement and support platform. It enables teams to manage customer conversations across live chat, email, WhatsApp, Instagram, Facebook, and Twitter from a single, unified dashboard.

## Application Information
- **Version:** v4.17.1
- **Upstream Project:** [https://github.com/chatwoot/chatwoot](https://github.com/chatwoot/chatwoot)
- **Container Base:** [docker.io/chatwoot/chatwoot](https://hub.docker.com/r/chatwoot/chatwoot) (`chatwoot/chatwoot:v4.17.1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Chatwoot Web Application (`chatwoot-web`):** Ruby on Rails application server handling real-time agent dashboard and REST APIs on container port 3000.
- **Chatwoot Background Worker (`chatwoot-worker`):** Sidekiq worker processing asynchronous jobs, scheduled tasks, webhooks, and email notifications.
- **PostgreSQL Database (`chatwoot-postgresql`):** Dedicated PostgreSQL StatefulSet (`ghcr.io/chatwoot/pgvector:14.4.0-debian-11-r0`) with vector extensions and persistent storage (`8Gi`).
- **Redis & Sentinel Cluster (`chatwoot-redis`):** Dedicated Redis StatefulSet (`bitnamilegacy/redis:6.2.9-debian-11-r0`) with Sentinel managing Sidekiq queues, caching, and ActionCable WebSockets with persistent storage (`8Gi`).
- **Database Migration Job (`chatwoot-migration`):** Automated pre-install / pre-upgrade Job executing schema preparation and migrations.
- **Kubernetes Service (`chatwoot-web` / `web-svc`):** ClusterIP service exposing port 80 (routing internally to container port 3000).
- **HorizontalPodAutoscaler (`web-hpa`, `worker-hpa`):** Automatically scales Web and Worker replicas based on CPU and memory thresholds.
- **Application Secret (`chatwoot-env`):** Manages cryptographic session tokens (`SECRET_KEY_BASE`) and runtime environment variables.
- **ServiceAccount (`serviceAccount`):** Dedicated unprivileged Kubernetes ServiceAccount for Chatwoot pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Ingress controller (e.g. Traefik, NGINX Ingress Controller) if Ingress routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply chatwoot ./chatwoot-timoni/chatwoot
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	env: {
		FRONTEND_URL:    "https://support.example.com"
		SECRET_KEY_BASE: "generate-a-secure-64-character-secret-key-base-here"
	}
	web: {
		replicaCount: 2
		resources: {
			requests: {
				cpu:    "250m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
	}
	worker: {
		replicaCount: 2
		resources: {
			requests: {
				cpu:    "250m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply chatwoot ./chatwoot-timoni/chatwoot \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete chatwoot
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"chatwoot/chatwoot"` | Chatwoot container image repository |
| `image.tag` | string | `"v4.17.1"` | Chatwoot container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | list | `[]` | Secrets for authenticating against private container registries |
| `web.replicaCount` | int | `2` | Initial replica count for the web application |
| `web.hpa.enabled` | bool | `true` | Enable HorizontalPodAutoscaler for web deployment |
| `web.hpa.minpods` | int | `2` | Minimum pod replicas for web deployment |
| `web.hpa.maxpods` | int | `10` | Maximum pod replicas for web deployment |
| `web.hpa.cputhreshold` | int | `80` | CPU utilization percentage threshold for scaling |
| `web.hpa.memorythreshold` | int | `80` | Memory utilization percentage threshold for scaling |
| `web.resources.requests.cpu` | string | `"250m"` | CPU request for web application container |
| `web.resources.requests.memory` | string | `"256Mi"` | Memory request for web application container |
| `web.resources.limits.cpu` | string | `"500m"` | CPU limit for web application container |
| `web.resources.limits.memory` | string | `"512Mi"` | Memory limit for web application container |
| `worker.replicaCount` | int | `2` | Initial replica count for background workers |
| `worker.hpa.enabled` | bool | `true` | Enable HorizontalPodAutoscaler for workers |
| `worker.hpa.minpods` | int | `2` | Minimum pod replicas for workers |
| `worker.hpa.maxpods` | int | `10` | Maximum pod replicas for workers |
| `worker.resources.requests.cpu` | string | `"250m"` | CPU request for worker container |
| `worker.resources.requests.memory` | string | `"256Mi"` | Memory request for worker container |
| `worker.resources.limits.cpu` | string | `"500m"` | CPU limit for worker container |
| `worker.resources.limits.memory` | string | `"512Mi"` | Memory limit for worker container |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | int | `80` | Port exposed by the Kubernetes Service |
| `services.internalPort` | int | `3000` | Port Chatwoot application listens on inside container |
| `serviceAccount.create` | bool | `true` | Create a dedicated ServiceAccount for Chatwoot workloads |
| `serviceAccount.name` | string | `""` | Custom name for the created ServiceAccount |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress resource creation |
| `ingress.hosts` | list | `[]` | List of hostnames and routing rules for Ingress |
| `ingress.tls` | list | `[]` | TLS certificate configurations for Ingress |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.nameOverride` | string | `"chatwoot-postgresql"` | Name override for PostgreSQL StatefulSet |
| `postgresql.image.repository` | string | `"chatwoot/pgvector"` | PostgreSQL container image repository |
| `postgresql.auth.database` | string | `"chatwoot_production"` | PostgreSQL database name created on first run |
| `postgresql.auth.username` | string | `"postgres"` | PostgreSQL database user |
| `postgresql.auth.postgresPassword` | string | `"postgres"` | PostgreSQL password |
| `postgresql.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL pod |
| `postgresql.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL pod |
| `postgresql.resources.limits.cpu` | string | `"500m"` | CPU limit for PostgreSQL pod |
| `postgresql.resources.limits.memory` | string | `"512Mi"` | Memory limit for PostgreSQL pod |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis cluster subchart |
| `redis.nameOverride` | string | `"chatwoot-redis"` | Name override for Redis StatefulSet |
| `redis.image.repository` | string | `"bitnamilegacy/redis"` | Redis container image repository |
| `redis.image.tag` | string | `"6.2.9-debian-11-r0"` | Redis container image tag |
| `redis.auth.password` | string | `"redis"` | Redis server authentication password |
| `redis.sentinel.enabled` | bool | `true` | Enable Redis Sentinel for high-availability monitoring |
| `redis.resources.requests.cpu` | string | `"100m"` | CPU request for Redis pod |
| `redis.resources.requests.memory` | string | `"128Mi"` | Memory request for Redis pod |
| `redis.resources.limits.cpu` | string | `"200m"` | CPU limit for Redis pod |
| `redis.resources.limits.memory` | string | `"256Mi"` | Memory limit for Redis pod |
| `env.FRONTEND_URL` | string | `"http://localhost:9090"` | External public URL of the Chatwoot web interface |
| `env.SECRET_KEY_BASE` | string | required | Cryptographic key base for session integrity |
| `env.RAILS_ENV` | string | `"production"` | Application runtime environment mode |

## Recommended values

Chatwoot core application workloads (Web and Worker) operate under unprivileged system user `10001:10001`, dropping all Linux kernel capabilities (`drop: ["ALL"]`), mounting root filesystems as read-only, and enforcing `seccompProfile: RuntimeDefault`:

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    10001
		runAsGroup:   10001
		fsGroup:      10001
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		capabilities: {
			drop: ["ALL"]
		}
		readOnlyRootFilesystem: true
		runAsNonRoot:           true
		runAsUser:              10001
		runAsGroup:             10001
	}
}
```

## Additional Resources
- [Official Chatwoot Website](https://www.chatwoot.com/)
- [Official Chatwoot Repository](https://github.com/chatwoot/chatwoot)
- [Chatwoot Documentation](https://www.chatwoot.com/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Chatwoot module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Chatwoot Web (`chatwoot-web`) | Deployment | 14 points | ✅  |
| Chatwoot Worker (`chatwoot-worker`) | Deployment | 14 points | ✅  |
| Redis Subchart (`chatwoot-redis`) | StatefulSet | 12 points | ✅ |
| PostgreSQL Subchart (`chatwoot-postgresql`) | StatefulSet | 10 points | ✅ |
