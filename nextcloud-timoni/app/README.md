# Nextcloud

## Description
[Nextcloud](https://nextcloud.com/) is an open-source, on-premises content collaboration platform that provides file storage, synchronization, real-time document editing, communication, and groupware capabilities while maintaining complete data sovereignty and enterprise security.

## Application Information
- **Version:** 0.1.2 (App: 34.0.3-apache)
- **Upstream Project:** [https://github.com/nextcloud/server](https://github.com/nextcloud/server)
- **Container Base:** [docker.io/library/nextcloud](https://hub.docker.com/_/nextcloud) (`docker.io/library/nextcloud:34.0.3-apache`), [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18`), [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`docker.io/valkey/valkey:9.1.2-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Nextcloud Core (`nextcloud`):** Primary web server, API, and collaboration suite running Nextcloud Apache PHP on port 80.
- **PostgreSQL Database Subchart (`nextcloud-postgresql`):** Dedicated PostgreSQL 18 Deployment providing persistent relational database storage (`8Gi`) running under an unprivileged security context (`999:999`).
- **Redis / Valkey Cache Subchart (`nextcloud-redis`):** In-memory cache and transactional lock broker running Valkey 9 (`docker.io/valkey/valkey:9.1.2-alpine`) on port 6379 with persistent volume backing (`1Gi`) and hardened security context (`999:999`).
- **Persistent Volume Claims:** Dedicated persistent volume claims including `nextcloud-pvc` (`8Gi`), optional `nextcloud-data-pvc`, `database-pvc`, and `redis-pvc`.
- **ServiceAccount & RBAC (`nextcloud-serviceaccount`):** Dedicated unprivileged Kubernetes ServiceAccount and least-privilege RBAC role bindings.
- **Observability & Metrics:** Optional Nextcloud Prometheus exporter (`metrics`) and Prometheus ServiceMonitor integrations.
- **Optional Add-ons:** Imaginary image processing service (`imaginary`), Nginx reverse proxy sidecar (`nginx`), scheduled CronJob (`cronjob`), and Horizontal Pod Autoscaler (`hpa`).

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting ReadWriteOnce persistent volumes

## Install

To create an instance using default values:

```shell
timoni -n default apply nextcloud ./app
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	nextcloud: {
		host: "nextcloud.example.com"
		trustedDomains: ["nextcloud.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply nextcloud ./app \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete nextcloud
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the chart name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `image.repository` | string | `"docker.io/library/nextcloud"` | Nextcloud container image repository |
| `image.tag` | string | `"34.0.3-apache"` | Nextcloud container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `nextcloud.host` | string | `"nextcloud.kube.home"` | Primary hostname for Nextcloud instance |
| `nextcloud.containerPort` | int | `80` | Container port for Nextcloud web server |
| `nextcloud.trustedDomains` | list | `["nextcloud.kube.home", "localhost"]` | List of trusted domains for web access |
| `nextcloud.trustedProxies` | list | `["127.0.0.1", "10.0.0.0/8"]` | List of reverse proxy IP ranges |
| `nextcloud.datadir` | string | `"/var/www/html/data"` | Directory path for user data files |
| `nextcloud.username` | string | `"admin"` | Initial administrator username |
| `nextcloud.password` | string | `"EvoCloudNextcloud2026!"` | Initial administrator password |
| `resources.requests.cpu` | string | `"10m"` | CPU request for Nextcloud web container |
| `resources.requests.memory` | string | `"128Mi"` | Memory request for Nextcloud web container |
| `resources.limits.cpu` | string | `"1000m"` | CPU limit for Nextcloud web container |
| `resources.limits.memory` | string | `"1Gi"` | Memory limit for Nextcloud web container |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | int | `8080` | Port exposed by Kubernetes Service (routes to 80) |
| `persistence.enabled` | bool | `true` | Enable persistent storage for Nextcloud HTML directory |
| `persistence.size` | string | `"8Gi"` | Persistent Volume size requested for Nextcloud storage |
| `rbac.enabled` | bool | `true` | Enable RBAC resources |
| `rbac.serviceAccount.name` | string | `"nextcloud-serviceaccount"` | Name of the ServiceAccount |
| `database.postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `database.postgresql.image` | string | `"docker.io/library/postgres:18"` | PostgreSQL container image |
| `database.postgresql.auth.database` | string | `"nextcloud"` | PostgreSQL database name |
| `database.postgresql.auth.username` | string | `"nextcloud"` | PostgreSQL database username |
| `database.postgresql.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for PostgreSQL |
| `database.postgresql.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL |
| `database.postgresql.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL |
| `database.postgresql.resources.limits.cpu` | string | `"1000m"` | CPU limit for PostgreSQL |
| `database.postgresql.resources.limits.memory` | string | `"512Mi"` | Memory limit for PostgreSQL |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis / Valkey in-memory cache subchart |
| `redis.image.repository` | string | `"valkey/valkey"` | Valkey container image repository |
| `redis.image.tag` | string | `"9.1.2-alpine"` | Valkey container image tag |
| `redis.port` | int | `6379` | Port exposed by Redis service |
| `redis.master.persistence.size` | string | `"1Gi"` | Persistent Volume size requested for Redis |
| `redis.resources.requests.cpu` | string | `"100m"` | CPU request for Redis |
| `redis.resources.requests.memory` | string | `"128Mi"` | Memory request for Redis |
| `redis.resources.limits.cpu` | string | `"500m"` | CPU limit for Redis |
| `redis.resources.limits.memory` | string | `"256Mi"` | Memory limit for Redis |
| `redis.securityContext.runAsUser` | int | `999` | Unprivileged non-root container UID |
| `redis.securityContext.runAsGroup` | int | `999` | Unprivileged non-root container GID |
| `redis.securityContext.readOnlyRootFilesystem` | bool | `false` | Mount container root filesystem in read-only mode |
| `redis.securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `redis.securityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |

## Recommended values

Nextcloud subcharts operate with dedicated unprivileged system users (`999:999` for PostgreSQL and Redis), dropping all Linux kernel capabilities (`drop: ["ALL"]`), `allowPrivilegeEscalation: false`, and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	redis: {
		podSecurityContext: {
			runAsUser:           999
			runAsGroup:          999
			fsGroup:             999
			runAsNonRoot:        true
			seccompProfile: type: "RuntimeDefault"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			privileged:               false
			runAsNonRoot:             true
			runAsUser:                999
			runAsGroup:               999
			readOnlyRootFilesystem:   false
			capabilities: drop: ["ALL"]
			seccompProfile: type: "RuntimeDefault"
		}
	}
}
```

## Additional Resources
- [Official Nextcloud Website](https://nextcloud.com/)
- [Official Nextcloud Server Repository](https://github.com/nextcloud/server)
- [Nextcloud Documentation](https://docs.nextcloud.com/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Nextcloud module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Nextcloud Core (`nextcloud`) | Deployment | 12 points | ✅ |
| PostgreSQL Subchart (`nextcloud-postgresql`) | Deployment | 12 points | ✅ |
| Redis Subchart (`nextcloud-redis`) | Deployment | 11 points | ✅ |
