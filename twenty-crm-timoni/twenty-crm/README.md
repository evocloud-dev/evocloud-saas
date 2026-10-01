# Twenty CRM

## Description
[Twenty](https://twenty.com/) is an open-source CRM (Customer Relationship Management) designed as a modern, customizable alternative to Salesforce. It features visual pipeline tracking, contact and company relationship management, custom objects and fields, notes and task logging, role-based permissions, and bi-directional API integrations.

## Application Information
- **Version:** `v2.17.0`
- **Official Website:** [https://twenty.com/](https://twenty.com/)
- **Upstream Project:** [https://github.com/twentyhq/twenty](https://github.com/twentyhq/twenty)
- **Container Base:**
  - Twenty Core Application: [twentycrm/twenty](https://hub.docker.com/r/twentycrm/twenty) (`twentycrm/twenty:v2.17.0`)
  - PostgreSQL Database: [ghcr.io/zalando/spilo-16](https://github.com/zalando/spilo) (`ghcr.io/zalando/spilo-16:3.3-p2`)
  - Redis Server: [redis/redis-stack-server](https://hub.docker.com/r/redis/redis-stack-server) (`redis/redis-stack-server:7.2.0-v20`)
  - Utility Image: `postgres:18-alpine`
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Twenty Server (`tw-server`):** Core application server (`Deployment/tw-server`) running `twentycrm/twenty:v2.17.0` on internal port 3000. Includes automated database readiness probes and migration init containers.
- **Twenty Worker (`tw-worker`):** Asynchronous background worker (`Deployment/tw-worker`) executing scheduled tasks, webhook dispatching, email processing, and workflow triggers.
- **PostgreSQL Database (`tw-db`):** Dedicated relational database deployment (`Deployment/tw-db`) powered by Zalando Spilo 16 with persistent volume storage (`10Gi`), automated schema creation, and database user initialization.
- **Redis Cache & Broker (`tw-redis`):** Dedicated Redis Stack Server deployment (`Deployment/tw-redis`) managing queue distribution, event broadcasting, and high-speed in-memory caching on port 6379.
- **Twenty Services (`tw-server`, `tw-db`, `tw-redis`):** Internal ClusterIP services exposing the API/UI (port 3000), PostgreSQL database (port 5432), and Redis broker (port 6379).
- **Persistent Storage:** PersistentVolumeClaims providing dedicated storage for server uploads (`10Gi`), container data (`100Mi`), database records (`10Gi`), and Redis snapshots (`1Gi`).
- **Ingress (`server.ingress`):** Optional Kubernetes Ingress controller routing external HTTP/HTTPS traffic to the Twenty server.
- **Secrets:** Automated secret generation for application authentication tokens (`tw-tokens`), database connection strings (`tw-db-url`), and database administrative credentials (`tw-db-superuser`).

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply tw ./twenty-crm
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	server: {
		env: {
			SERVER_URL:   "https://crm.example.com"
			FRONTEND_URL: "https://crm.example.com"
		}
		resources: {
			requests: {
				cpu:    "1000m"
				memory: "1Gi"
			}
			limits: {
				cpu:    "2000m"
				memory: "2Gi"
			}
		}
	}
	db: {
		internal: {
			persistence: {
				size: "20Gi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply tw ./twenty-crm \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete tw
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `twentycrm/twenty` | Container image repository for Twenty CRM |
| `image.tag` | string | `v2.17.0` | Pinned container image tag for Twenty CRM |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `server.replicaCount` | int | `2` | Number of replicas for the Twenty server |
| `server.service.port` | int | `3000` | HTTP container listening port |
| `server.resources` | object | `{requests: {cpu: "500m", memory: "512Mi"}, limits: {cpu: "2000m", memory: "2Gi"}}` | Container resource requests and limits for Server |
| `worker.replicaCount` | int | `1` | Number of replicas for the Twenty background worker |
| `worker.resources` | object | `{requests: {cpu: "500m", memory: "1Gi"}, limits: {cpu: "2000m", memory: "4Gi"}}` | Container resource requests and limits for Worker |
| `storage.type` | string | `local` | Upload and asset storage backend (`local` or `s3`) |
| `db.internal.enabled` | bool | `true` | Deploy internal Spilo 16 PostgreSQL database |
| `db.internal.image.repository` | string | `ghcr.io/zalando/spilo-16` | PostgreSQL container image repository |
| `db.internal.image.tag` | string | `3.3-p2` | PostgreSQL container image tag |
| `db.internal.database` | string | `twenty` | Default database name |
| `db.internal.persistence.size` | string | `10Gi` | Storage capacity allocated for PostgreSQL data |
| `redis.internal.enabled` | bool | `true` | Deploy internal Redis Stack Server |
| `redis.internal.image.repository` | string | `redis/redis-stack-server` | Redis container image repository |
| `redis.internal.image.tag` | string | `7.2.0-v20` | Redis container image tag |
| `server.ingress.enabled` | bool | `false` | Enable Kubernetes Ingress for external traffic |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	server: {
		podSecurityContext: {
			runAsUser:           1000
			runAsGroup:          1000
			runAsNonRoot:        true
			fsGroup:             1000
			fsGroupChangePolicy: "Always"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: {
				drop: ["ALL"]
			}
			readOnlyRootFilesystem: false
			runAsNonRoot:            true
			runAsUser:               1000
			runAsGroup:              1000
		}
	}
	worker: {
		podSecurityContext: {
			runAsUser:           10001
			runAsGroup:          10001
			runAsNonRoot:        true
			fsGroup:             10001
			fsGroupChangePolicy: "Always"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: {
				drop: ["ALL"]
			}
			readOnlyRootFilesystem: true
			runAsNonRoot:            true
			runAsUser:               10001
			runAsGroup:              10001
		}
	}
	db: {
		internal: {
			podSecurityContext: {
				fsGroup:             103
				fsGroupChangePolicy: "Always"
			}
			securityContext: {
				allowPrivilegeEscalation: false
				capabilities: {
					drop: ["ALL"]
					add: ["CHOWN", "SETUID", "SETGID", "DAC_OVERRIDE", "FOWNER"]
				}
				readOnlyRootFilesystem: false
			}
		}
	}
	redis: {
		internal: {
			podSecurityContext: {
				runAsUser:           10001
				runAsGroup:          10001
				runAsNonRoot:        true
				fsGroup:             10001
				fsGroupChangePolicy: "Always"
			}
			securityContext: {
				allowPrivilegeEscalation: false
				capabilities: {
					drop: ["ALL"]
				}
				readOnlyRootFilesystem: true
				runAsNonRoot:            true
				runAsUser:               10001
				runAsGroup:              10001
			}
		}
	}
}
```

## Additional Resources
- [Official Twenty CRM Website](https://twenty.com/)
- [Official Twenty CRM Repository](https://github.com/twentyhq/twenty)
- [Twenty CRM Documentation](https://docs.twenty.com/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Twenty CRM module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Twenty CRM Server (`tw-server`) | Deployment | 11 points | ✅ |
| Twenty CRM Worker (`tw-worker`) | Deployment | 14 points | ✅ |
| PostgreSQL Database (`tw-db`) | Deployment | 10 points | ✅ |
| Redis Server (`tw-redis`) | Deployment | 14 points | ✅ |
