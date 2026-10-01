# Wallabag

## Description
[Wallabag](https://wallabag.org/) is an open-source, self-hosted read-it-later web application that allows users to save articles, blog posts, and web pages for offline reading. It extracts clean article content (removing advertisements and distracting layout elements), supports tagging, full-text search, annotations, RSS feeds, and multi-format exports (PDF, EPUB, MOBI), and integrates seamlessly with official browser extensions and mobile applications for iOS and Android.

## Application Information
- **Version:** `2.6.14`
- **Official Website:** [https://wallabag.org/](https://wallabag.org/)
- **Upstream Project:** [https://github.com/wallabag/wallabag](https://github.com/wallabag/wallabag)
- **Container Base:**
  - Wallabag Application: `docker.io/wallabag/wallabag` (`docker.io/wallabag/wallabag:2.6.14`)
  - PostgreSQL Database: `docker.io/library/postgres` (`docker.io/library/postgres:18.6-trixie`)
  - Redis Cache & Queue: `docker.io/library/redis` (`docker.io/library/redis:8.10.1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Wallabag Core Application (`walla-wallabag`):** Deployment (`Deployment/walla-wallabag`) running the Symfony-based Wallabag PHP application serving the web UI and REST API on container port 80.
- **PostgreSQL Database (`walla-postgresql`):** StatefulSet (`StatefulSet/walla-postgresql`) providing relational data persistence for articles, user accounts, tags, and annotations with persistent volume storage (`8Gi`).
- **Redis Cache & Queue (`walla-redis`):** StatefulSet (`StatefulSet/walla-redis`) providing high-performance in-memory caching and background worker queue handling with persistent volume storage (`8Gi`).
- **Wallabag Service (`walla-wallabag`):** ClusterIP service routing HTTP traffic to the Wallabag application pod on port 80.
- **PostgreSQL Services (`walla-postgresql`, `walla-postgresql-primary-headless`):** ClusterIP and headless services routing database connections on port 5432.
- **Redis Services (`walla-redis-client`, `walla-redis-headless`):** ClusterIP and headless services routing Redis cache/queue traffic on port 6379.
- **Persistent Volume Claims (`walla-wallabag-data`):** Storage (`2Gi`) preserving downloaded article images, user media, and assets.
- **Secrets Management (`walla-wallabag-app`, `walla-admin-secret`, `walla-postgresql-auth`):** Managed Kubernetes Secrets storing Symfony application secrets, administrator account credentials, and database passwords.
- **Backup Automation (Optional):** ConfigMap and CronJob for scheduled PostgreSQL database dumps exported to S3-compatible object storage.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply walla ./wallabag
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	wallabag: {
		domainName: "https://wallabag.example.com"
		adminUser: {
			username: "wallabag"
			email:    "admin@example.com"
			password: "MySecurePassword123!"
		}
	}
	resources: {
		requests: {
			cpu:    "200m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1Gi"
		}
	}
	persistence: {
		size: "5Gi"
	}
	postgresql: {
		enabled: true
		auth: {
			database: "wallabag"
			username: "wallabag"
			password: "MySecureDatabasePassword123!"
		}
		persistence: {
			size: "10Gi"
		}
	}
	redis: {
		enabled: true
		persistence: {
			size: "5Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply walla ./wallabag \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```shell
timoni -n default delete walla
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/wallabag/wallabag` | Container image repository |
| `image.tag` | string | `2.6.14` | Pinned container image tag |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `replicaCount` | int | `1` | Number of Wallabag application replicas |
| `wallabag.port` | int | `80` | Wallabag HTTP service port |
| `wallabag.domainName` | string | `http://localhost:8080` | Public domain URL for Wallabag instance |
| `wallabag.registration` | bool | `false` | Enable or disable public user registration |
| `service.type` | string | `ClusterIP` | Kubernetes service type |
| `service.port` | int | `80` | Kubernetes service port |
| `resources` | object | `{requests: {cpu: "100m", memory: "128Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Container resource requests and limits |
| `persistence.enabled` | bool | `true` | Enable persistent storage for assets |
| `persistence.size` | string | `2Gi` | Wallabag data volume size |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database |
| `postgresql.image.repository` | string | `docker.io/library/postgres` | PostgreSQL container image |
| `postgresql.image.tag` | string | `18.6-trixie` | PostgreSQL container image tag |
| `postgresql.persistence.size` | string | `8Gi` | PostgreSQL volume storage capacity |
| `redis.enabled` | bool | `true` | Deploy internal Redis cache and queue |
| `redis.image.repository` | string | `docker.io/library/redis` | Redis container image |
| `redis.image.tag` | string | `8.10.1` | Redis container image tag |
| `redis.persistence.size` | string | `8Gi` | Redis volume storage capacity |
| `backup.enabled` | bool | `false` | Enable scheduled automated database backups |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:    65510
		runAsGroup:   65510
		runAsNonRoot: true
		fsGroup:      65510
		seccompProfile: type: "RuntimeDefault"
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
			add: ["NET_BIND_SERVICE"]
		}
	}
	postgresql: {
		podSecurityContext: {
			runAsUser:    65510
			runAsGroup:   65510
			runAsNonRoot: true
			fsGroup:      65510
			seccompProfile: type: "RuntimeDefault"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
			runAsUser:    65510
			runAsGroup:   65510
			runAsNonRoot: true
		}
	}
	redis: {
		podSecurityContext: {
			runAsUser:    65510
			runAsGroup:   65510
			runAsNonRoot: true
			fsGroup:      65510
			seccompProfile: type: "RuntimeDefault"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
			runAsUser:    65510
			runAsGroup:   65510
			runAsNonRoot: true
		}
	}
}
```

## Additional Resources
- [Official Wallabag Website](https://wallabag.org/)
- [Official Wallabag Repository](https://github.com/wallabag/wallabag)
- [Wallabag Documentation](https://doc.wallabag.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Wallabag module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Wallabag Application (`walla-wallabag`) | Deployment | 13 points | ✅ |
| PostgreSQL Database (`walla-postgresql`) | StatefulSet | 15 points | ✅ |
| Redis Cache & Queue (`walla-redis`) | StatefulSet | 15 points | ✅ |
