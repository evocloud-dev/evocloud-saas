# Middleware

## Description
[Middleware](https://www.middlewarehq.com/) is an open-source engineering management and DORA metrics platform designed to help engineering teams track, understand, and improve their delivery performance. It measures key DORA metrics including Deployment Frequency, Lead Time for Changes, Mean Time to Recovery (MTTR), and Change Failure Rate across CI/CD and Git provider integrations.

## Application Information
- **Version:** `0.3.1`
- **Official Website:** [https://www.middlewarehq.com/](https://www.middlewarehq.com/)
- **Upstream Project:** [https://github.com/middlewarehq/middleware](https://github.com/middlewarehq/middleware)
- **Container Base:**
  - Middleware Core Application: [docker.io/middlewareeng/middleware](https://hub.docker.com/r/middlewareeng/middleware) (`docker.io/middlewareeng/middleware:0.3.1`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
  - Redis In-Memory Datastore: [docker.io/library/redis](https://hub.docker.com/_/redis) (`docker.io/library/redis:8.10.1`)
  - Wait Init Helper: [docker.io/library/busybox](https://hub.docker.com/_/busybox) (`docker.io/library/busybox:1.37`)
  - Test Suite Runner: [docker.io/curlimages/curl](https://hub.docker.com/r/curlimages/curl) (`docker.io/curlimages/curl:8.21.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Middleware Server (`middleware`):** Primary application workload (`Deployment/middleware`) running `docker.io/middlewareeng/middleware:0.3.1` exposing the Next.js frontend (port 3333), analytics API (port 9696), and sync server (port 9697). Includes a `wait-for-postgresql` init container for database readiness verification.
- **PostgreSQL Database (`middleware-postgresql`):** Bundled relational database (`StatefulSet/middleware-postgresql`) running PostgreSQL 18.6-trixie with persistent volume storage (`8Gi`), automated schema creation, health probes, and database user initialization.
- **Redis Datastore (`middleware-redis`):** Bundled standalone caching and background-job queue datastore (`StatefulSet/middleware-redis`) running Redis 8.10.1 with persistent volume storage (`8Gi`), password authentication, and custom configuration.
- **Middleware Services (`middleware`, `middleware-postgresql`, `middleware-postgresql-primary-headless`, `middleware-redis`, `middleware-redis-headless`):** Internal ClusterIP and Headless services exposing the frontend web UI (port 80), database endpoints (port 5432), and Redis endpoints (port 6379).
- **Persistent Storage:** PersistentVolumeClaims providing dedicated storage for application encryption keys (`/app/keys`, default `1Gi`), PostgreSQL database files (`8Gi`), and Redis data (`8Gi`).
- **Ingress (`ingress`):** Optional Ingress resource (`networking.k8s.io/v1`) providing external HTTP/HTTPS routing and TLS termination for the frontend web application.
- **Gateway API HTTPRoute (`gatewayAPI`):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) routing external traffic to the Middleware service.
- **Secrets & ConfigMaps:** Automated credential and configuration generation for PostgreSQL (`middleware-postgresql-auth`, `middleware-postgresql-config`, `middleware-postgresql-initdb`) and Redis (`middleware-redis-auth`, `middleware-redis-config`).
- **Test Job (`test-svc`):** Optional post-install test suite (`Job/test-svc`) verifying frontend HTTP connectivity.

## Prerequisites
- Kubernetes cluster v1.20+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply middleware ./middleware
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	serviceAccount: {
		create:                       true
		automountServiceAccountToken: false
	}
	ingress: {
		enabled:          true
		ingressClassName: "traefik"
		hosts: [{
			host: "dora.example.com"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}]
		tls: [{
			hosts: ["dora.example.com"]
			secretName: "middleware-tls"
		}]
	}
	resources: {
		requests: {
			cpu:    "500m"
			memory: "1Gi"
		}
		limits: {
			cpu:    "2"
			memory: "2Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply middleware ./middleware \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete middleware
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/middlewareeng/middleware` | Container image repository for Middleware |
| `image.tag` | string | `0.3.1` | Pinned container image tag |
| `image.digest` | string | `""` | Container image digest |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `imagePullSecrets` | list | `[]` | Pod image pull secrets |
| `middleware.frontendPort` | int | `3333` | Frontend web UI port (Next.js) |
| `middleware.analyticsPort` | int | `9696` | Analytics calculation API port |
| `middleware.syncPort` | int | `9697` | Git provider ingestion sync server port |
| `middleware.environment` | string | `prod` | Application runtime environment |
| `middleware.timezone` | string | `UTC` | Application timezone |
| `middleware.extraEnv` | list | `[]` | Extra environment variables for the application container |
| `externalDatabase.enabled` | bool | `false` | Enable external PostgreSQL database instead of bundled StatefulSet |
| `externalDatabase.host` | string | `""` | External database hostname |
| `externalDatabase.port` | int | `5432` | External database TCP port |
| `externalDatabase.name` | string | `mhq-oss` | External database name |
| `externalDatabase.user` | string | `middleware` | External database username |
| `externalDatabase.password` | string | `""` | External database password |
| `externalDatabase.existingSecret` | string | `""` | Existing Kubernetes secret containing database credentials |
| `externalDatabase.existingSecretPasswordKey` | string | `user-password` | Secret key containing external database password |
| `externalRedis.enabled` | bool | `false` | Enable external Redis datastore instead of bundled StatefulSet |
| `externalRedis.host` | string | `""` | External Redis hostname |
| `externalRedis.port` | int | `6379` | External Redis TCP port |
| `postgresql.enabled` | bool | `true` | Deploy bundled standalone PostgreSQL database StatefulSet |
| `postgresql.auth.database` | string | `mhq-oss` | PostgreSQL database name |
| `postgresql.auth.username` | string | `middleware` | PostgreSQL database username |
| `postgresql.auth.password` | string | `""` | PostgreSQL database password (auto-generated if empty) |
| `postgresql.resources` | object | `{requests: {cpu: "250m", memory: "512Mi"}, limits: {cpu: "500m", memory: "1Gi"}}` | Resource requests and limits for PostgreSQL |
| `postgresql.persistence.size` | string | `8Gi` | Storage capacity allocated for PostgreSQL database files |
| `redis.enabled` | bool | `true` | Deploy bundled standalone Redis StatefulSet |
| `redis.architecture` | string | `standalone` | Redis operational architecture mode |
| `redis.resources` | object | `{requests: {cpu: "100m", memory: "128Mi"}, limits: {cpu: "250m", memory: "256Mi"}}` | Resource requests and limits for Redis |
| `redis.persistence.size` | string | `8Gi` | Storage capacity allocated for Redis data files |
| `persistence.enabled` | bool | `true` | Enable persistent storage for encryption keys (`/app/keys`) |
| `persistence.size` | string | `1Gi` | Storage capacity allocated for application encryption keys |
| `persistence.storageClass` | string | `""` | StorageClass name for application PVC |
| `persistence.accessModes` | list | `["ReadWriteOnce"]` | Persistent volume access modes |
| `serviceAccount.create` | bool | `true` | Create dedicated ServiceAccount for Middleware |
| `serviceAccount.name` | string | `""` | ServiceAccount name override |
| `serviceAccount.automountServiceAccountToken` | bool | `false` | Automount service account API credentials |
| `service.type` | string | `ClusterIP` | Kubernetes Service type |
| `service.port` | int | `80` | Kubernetes Service HTTP port |
| `ingress.enabled` | bool | `false` | Enable Ingress routing |
| `ingress.ingressClassName` | string | `traefik` | Ingress controller class name |
| `ingress.hosts` | list | `[]` | Ingress hostname and path routing definitions |
| `ingress.tls` | list | `[]` | Ingress TLS secret configurations |
| `gatewayAPI.enabled` | bool | `false` | Enable Gateway API HTTPRoute for Middleware |
| `gatewayAPI.httpRoutes` | list | `[]` | HTTPRoute definitions with parentRefs, hostnames, and routing rules |
| `resources` | object | `{requests: {cpu: "250m", memory: "512Mi"}, limits: {cpu: "1", memory: "1Gi"}}` | Container resource requests and limits for Middleware |
| `podSecurityContext` | object | `{seccompProfile: {type: "RuntimeDefault"}}` | Pod-level security context |
| `securityContext` | object | `{allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}}` | Container-level security context |
| `test.enabled` | bool | `false` | Run automated HTTP connectivity tests post-apply |

### Recommended values

Comply with hardened security standards:

```cue
values: {
	resources: {
		requests: {
			cpu:    "250m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1"
			memory: "1Gi"
		}
	}
	podSecurityContext: {
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
		}
	}
	serviceAccount: {
		create:                       true
		automountServiceAccountToken: false
	}
}
```

## Additional Resources
- [Official Middleware Website](https://www.middlewarehq.com/)
- [Official Middleware Repository](https://github.com/middlewarehq/middleware)
- [Middleware Documentation](https://docs.middlewarehq.com/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Middleware module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Middleware Server (`middleware`) | Deployment | 10 points | ✅ |
| PostgreSQL Database (`middleware-postgresql`) | StatefulSet | 13 points | ✅ |
| Redis Datastore (`middleware-redis`) | StatefulSet | 13 points | ✅ |
