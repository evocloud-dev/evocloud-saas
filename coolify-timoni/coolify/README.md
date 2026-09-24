# Coolify

## Description
[Coolify](https://coolify.io/) is an open-source & self-hostable alternative to Vercel, Heroku, Netlify and Railway for easily deploying websites, databases, web applications and 280+ one-click services to your own server.

## Application Information
- **Version:** 4.3.14
- **Upstream Project:** [https://github.com/coollabsio/coolify](https://github.com/coollabsio/coolify)
- **Container Base:** [ghcr.io/coollabsio/coolify](https://github.com/coollabsio/coolify/pkgs/container/coolify) (`ghcr.io/coollabsio/coolify:4.3.14`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Coolify Application Server (`coolify-app`):** Core Laravel, PHP-FPM, and NGINX web dashboard and deployment engine serving traffic on container port 8080 (exposed on port 8000).
- **Soketi Realtime Server (`coolify-soketi`):** High-performance WebSockets server (`ghcr.io/coollabsio/coolify-realtime:1.0.18`) handling live terminal streaming, build progress, and event subscriptions on container ports 6001 and 6002.
- **PostgreSQL Database (`coolify-postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`postgres:18-alpine`) with persistent storage (`8Gi`) managing team projects, server registrations, and deployment metadata.
- **Redis Cache & Queue (`coolify-redis-master`):** Dedicated Redis/Valkey StatefulSet (`valkey/valkey:9.0-alpine`) managing job queuing, background tasks, and real-time Pub/Sub broadcasts with persistent storage (`2Gi`).
- **Coolify App Service (`coolify-app-svc`):** ClusterIP service routing inbound HTTP traffic to container port 8080.
- **Soketi Service (`coolify-soketi`):** ClusterIP service routing WebSocket connections (port 6001) and Prometheus/health metrics (port 6002).
- **Shared Data Storage (`shared-data-pvc`):** PersistentVolumeClaim (`1Gi`, ReadWriteOnce) persisting SSH keys, project repositories, build logs, and temporary build assets.
- **Application Secrets (`coolify-app-secrets`):** Securely stores encryption keys (`APP_KEY`), database credentials, Redis auth, and admin account passwords.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount applied across all Coolify workloads.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Ingress controller (e.g. Traefik, NGINX Ingress Controller) if Ingress routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply coolify ./coolify-timoni/coolify
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	config: {
		APP_URL: "https://coolify.example.com"
	}
	secrets: {
		APP_KEY:            "base64:xZW/NBFucHhBaBybNsgXJzy83TcC6atI8PuzAUbh638="
		ROOT_USERNAME:      "admin"
		ROOT_USER_EMAIL:    "admin@example.com"
		ROOT_USER_PASSWORD: "MySecurePassword123!"
	}
	coolifyApp: {
		resources: {
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
		}
	}
	ingress: {
		enabled:   true
		className: "traefik"
		hosts: [{
			host: "coolify.example.com"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply coolify ./coolify-timoni/coolify \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete coolify
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `coolifyApp.image.repository` | string | `"ghcr.io/coollabsio/coolify"` | Coolify application container image repository |
| `coolifyApp.image.tag` | string | `"4.3.14"` | Coolify application container image tag |
| `coolifyApp.image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `coolifyApp.replicaCount` | int | `1` | Number of Coolify core application replicas |
| `coolifyApp.resources.requests.cpu` | string | `"250m"` | CPU request for Coolify core container |
| `coolifyApp.resources.requests.memory` | string | `"512Mi"` | Memory request for Coolify core container |
| `coolifyApp.resources.limits.cpu` | string | `"1000m"` | CPU limit for Coolify core container |
| `coolifyApp.resources.limits.memory` | string | `"1Gi"` | Memory limit for Coolify core container |
| `coolifyApp.service.port` | int | `8000` | Port exposed on the Coolify Service |
| `coolifyApp.service.targetPort` | int | `8080` | Internal container port for Coolify NGINX proxy |
| `soketi.enabled` | bool | `true` | Deploy Soketi WebSocket subchart |
| `soketi.image.repository` | string | `"ghcr.io/coollabsio/coolify-realtime"` | Soketi container image repository |
| `soketi.image.tag` | string | `"1.0.18"` | Soketi container image tag |
| `soketi.replicaCount` | int | `1` | Number of Soketi WebSocket pod replicas |
| `soketi.resources.requests.cpu` | string | `"100m"` | CPU request for Soketi container |
| `soketi.resources.requests.memory` | string | `"256Mi"` | Memory request for Soketi container |
| `soketi.resources.limits.cpu` | string | `"500m"` | CPU limit for Soketi container |
| `soketi.resources.limits.memory` | string | `"512Mi"` | Memory limit for Soketi container |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.primary.image.repository` | string | `"postgres"` | PostgreSQL container image repository |
| `postgresql.primary.image.tag` | string | `"18-alpine"` | PostgreSQL container image tag |
| `postgresql.auth.database` | string | `"coolify"` | Initial PostgreSQL database name |
| `postgresql.auth.username` | string | `"coolify"` | Initial PostgreSQL database user |
| `postgresql.primary.persistence.size` | string | `"8Gi"` | Persistent volume storage requested for PostgreSQL |
| `postgresql.primary.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL container |
| `postgresql.primary.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL container |
| `postgresql.primary.resources.limits.cpu` | string | `"1000m"` | CPU limit for PostgreSQL container |
| `postgresql.primary.resources.limits.memory` | string | `"1Gi"` | Memory limit for PostgreSQL container |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis/Valkey cache subchart |
| `redis.image.repository` | string | `"valkey/valkey"` | Valkey container image repository |
| `redis.image.tag` | string | `"9.0-alpine"` | Valkey container image tag |
| `redis.persistence.size` | string | `"2Gi"` | Persistent volume storage requested for Redis/Valkey |
| `redis.master.resources.requests.cpu` | string | `"100m"` | CPU request for Redis master container |
| `redis.master.resources.requests.memory` | string | `"128Mi"` | Memory request for Redis master container |
| `redis.master.resources.limits.cpu` | string | `"500m"` | CPU limit for Redis master container |
| `redis.master.resources.limits.memory` | string | `"256Mi"` | Memory limit for Redis master container |
| `sharedDataPvc.size` | string | `"1Gi"` | Persistent volume storage requested for shared app PVC |
| `sharedDataPvc.accessModes` | list | `["ReadWriteOnce"]` | PVC access modes for shared data storage |
| `config.APP_NAME` | string | `"Coolify"` | Name displayed across the Coolify application |
| `config.APP_URL` | string | `"http://localhost:8000"` | Public web address of the Coolify instance |
| `config.APP_ENV` | string | `"production"` | Application runtime environment mode |
| `secrets.APP_KEY` | string | required | Base64-encoded application encryption key |
| `secrets.ROOT_USERNAME` | string | `"admin"` | Initial administrator username |
| `secrets.ROOT_USER_EMAIL` | string | `"admin@gmail.com"` | Initial administrator email address |
| `secrets.ROOT_USER_PASSWORD` | string | required | Initial administrator password |

## Recommended values

Coolify application workloads run under dedicated unprivileged system users (`10001:10001`), dropping all Linux capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`:

```cue
values: {
	securityContext: {
		enabled:                  true
		fsGroup:                  10001
		runAsUser:                10001
		runAsGroup:               10001
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		capabilities: {
			drop: ["ALL"]
			add: []
		}
	}
}
```

## Additional Resources
- [Official Coolify Website](https://coolify.io/)
- [Official Coolify Repository](https://github.com/coollabsio/coolify)
- [Coolify Documentation](https://coolify.io/docs)
- [Timoni Documentation](https://timoni.sh)

## Changelog

### [0.1.2] - 2026-09-22
- **Security:** Added dedicated `ServiceAccount` and configured `serviceAccountName: #config.metadata.name` across all module workloads (`coolify-app`, `coolify-soketi`, `coolify-postgresql`, and `coolify-redis-master`).

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Coolify module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Coolify Core Application (`coolify-app`) | Deployment | 13 points | ✅  |
| Soketi WebSocket Server (`coolify-soketi`) | Deployment | 13 points | ✅  |
| PostgreSQL Database (`coolify-postgresql`) | StatefulSet | 14 points | ✅ |
| Redis Cache & Queue (`coolify-redis-master`) | StatefulSet | 16 points | ✅ |
