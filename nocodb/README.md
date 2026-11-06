# NocoDB

## Description
[NocoDB](https://nocodb.com/) is an open-source No-Code database platform that transforms any relational database (PostgreSQL, MySQL, SQL Server, SQLite) into an interactive, smart spreadsheet. It serves as a self-hosted alternative to Airtable, allowing teams to collaborate on relational data, create grid, gallery, kanban, and form views, generate REST and GraphQL APIs automatically, and integrate workflows without writing code.

## Application Information
- **Version:** 0.301.5
- **Upstream Project:** [https://github.com/nocodb/nocodb](https://github.com/nocodb/nocodb)
- **Container Base:** [docker.io/nocodb/nocodb](https://hub.docker.com/r/nocodb/nocodb) (`docker.io/nocodb/nocodb:0.301.5@sha256:d9516f0bf546fd6c78a382ab0657626c683fca7aaafdbbe53c66baf15df7fc0d`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **NocoDB Server (`nocodb`):** Primary web and API server running `docker.io/nocodb/nocodb:0.301.5` on container port 10226, exposed via ClusterIP Service on port 10226. Includes database-readiness init containers (`nocodb-system-cnpg-wait` and `nocodb-system-redis-wait`).
- **Redis / Valkey Cache (`nocodb-redis`):** High-performance cache StatefulSet running `docker.io/bitnamisecure/valkey:latest` on port 6379 with automated health scripts (`ping_liveness_local.sh`, `ping_readiness_local.sh`), exposed via ClusterIP Service on port 6379.
- **CloudNativePG PostgreSQL Cluster (`nocodb-cnpg-main`):** High-availability PostgreSQL 16 cluster (`postgresql.cnpg.io/v1`) running `ghcr.io/cloudnative-pg/postgresql:16.15` with 2 instances, automated switchover/failover, and dedicated PVC storage.
- **Persistent Storage (`nocodb-data`):** Dedicated PersistentVolumeClaim mounted at `/usr/app/data` (`100Gi`, ReadWriteOnce) for local file attachments, uploads, and runtime storage.
- **Memory-backed Ephemeral Mounts:** High-performance emptyDir memory volumes mounted at `/dev/shm`, `/tmp`, `/var/logs`, `/var/run`, and `/shared` (`2400Mi` sizeLimit).
- **ConfigMaps & Secrets:** Managed configuration and authentication secrets (`nocodb-configmap`, `nocodb-secrets`, `nocodb-rediscreds`, `nocodb-cnpg-main-urls`, `nocodb-cnpg-main-user`, `nocodb-redis-health`).

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- [CloudNativePG Operator](https://cloudnative-pg.io/) (`postgresql.cnpg.io/v1` CRDs) installed in the cluster

## Install

To create an instance using default values:

```shell
timoni -n default apply nocodb ./nocodb
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		data: {
			storage: "200Gi"
		}
	}
	cnpg: {
		main: {
			instances: 3
			storage:   "200Gi"
		}
	}
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						resources: {
							limits: {
								cpu:    "2000m"
								memory: "4096Mi"
							}
						}
					}
				}
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply nocodb ./nocodb \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete nocodb
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"docker.io/nocodb/nocodb"` | Container image repository |
| `image.tag` | string | `"0.301.5"` | Container image tag |
| `image.digest` | string | `"sha256:d9516f0bf546fd6c78a382ab0657626c683fca7aaafdbbe53c66baf15df7fc0d"` | Container image SHA256 digest |
| `image.pullPolicy` | string | `"IfNotPresent"` | Container image pull policy |
| `replicas` | int | `1` | Number of pod replicas |
| `revisionHistoryLimit` | int | `3` | Number of revision history limits to retain |
| `strategy.type` | string | `"Recreate"` | Deployment update strategy |
| `service.main.ports.main.port` | int | `10226` | Port exposed by the Kubernetes Service |
| `persistence.data.enabled` | bool | `true` | Enable persistent volume storage for `/usr/app/data` |
| `persistence.data.mountPath` | string | `"/usr/app/data"` | Target directory inside container for persistent storage |
| `persistence.data.storage` | string | `"100Gi"` | Persistent Volume size requested |
| `persistence.data.accessModes` | list | `["ReadWriteOnce"]` | Storage volume access modes |
| `securityContext.container.runAsUser` | int | `0` | User ID to run main container process |
| `securityContext.container.runAsGroup` | int | `0` | Group ID to run main container process |
| `securityContext.container.readOnlyRootFilesystem` | bool | `false` | Mount root filesystem as read-only |
| `securityContext.container.runAsNonRoot` | bool | `false` | Validate container does not run as root |
| `securityContext.pod.fsGroup` | int | `568` | Supplemental group for volume ownership |
| `securityContext.pod.fsGroupChangePolicy` | string | `"OnRootMismatch"` | Policy for changing volume ownership and permissions |
| `securityContext.pod.supplementalGroups` | list | `[568]` | Additional supplemental groups for the pod |
| `workload.main.podSpec.containers.main.resources.requests.cpu` | string | `"75m"` | CPU request for the NocoDB container |
| `workload.main.podSpec.containers.main.resources.requests.memory` | string | `"200Mi"` | Memory request for the NocoDB container |
| `workload.main.podSpec.containers.main.resources.limits.cpu` | string | `"1500m"` | CPU limit for the NocoDB container |
| `workload.main.podSpec.containers.main.resources.limits.memory` | string | `"2400Mi"` | Memory limit for the NocoDB container |
| `workload.main.podSpec.containers.main.env.PORT` | int | `10226` | HTTP listening port for NocoDB |
| `workload.main.podSpec.containers.main.env.NC_PUBLIC_URL` | string | `"http://localhost:10226"` | Public accessible URL for NocoDB |
| `workload.main.podSpec.containers.main.env.NC_DISABLE_TELE` | bool | `true` | Disable telemetry reporting |
| `workload.main.podSpec.containers.main.env.NC_JWT_EXPIRES_IN` | string | `"10h"` | JWT token expiration duration |
| `cnpg.main.enabled` | bool | `true` | Enable CloudNativePG PostgreSQL database cluster |
| `cnpg.main.instances` | int | `2` | Number of PostgreSQL cluster instances |
| `cnpg.main.user` | string | `"nocodb"` | PostgreSQL database user |
| `cnpg.main.database` | string | `"nocodb"` | PostgreSQL database name |
| `cnpg.main.storage` | string | `"100Gi"` | Storage size for PostgreSQL PVC and WAL storage |
| `cnpg.main.image.repository` | string | `"ghcr.io/cloudnative-pg/postgresql"` | CloudNativePG container image repository |
| `cnpg.main.image.tag` | string | `"16.15"` | CloudNativePG PostgreSQL version tag |
| `cnpg.main.securityContext.container.runAsUser` | int | `26` | Postgres container UID (`postgresUID`) |
| `cnpg.main.securityContext.container.runAsGroup` | int | `26` | Postgres container GID (`postgresGID`) |
| `redis.enabled` | bool | `true` | Enable Redis (Valkey) cache StatefulSet |
| `redis.redisUsername` | string | `"default"` | Username for Redis connection |
| `redis.port` | int | `6379` | Service and container port for Redis |
| `redis.image.repository` | string | `"docker.io/bitnamisecure/valkey"` | Redis container image repository |
| `redis.image.tag` | string | `"latest"` | Redis container image tag |
| `redis.securityContext.container.runAsUser` | int | `568` | Redis container user ID |
| `redis.securityContext.container.runAsGroup` | int | `0` | Redis container group ID |
| `redis.securityContext.container.readOnlyRootFilesystem` | bool | `false` | Mount Redis root filesystem as read-only |
| `nodeSelector` | object | `{"kubernetes.io/arch": "amd64"}` | Node selector constraints |
| `terminationGracePeriodSeconds` | int | `60` | Grace period in seconds for graceful pod termination |

## Recommended values

NocoDB workloads operate with dedicated unprivileged system users, memory-backed ephemeral volumes, and `seccompProfile: RuntimeDefault`:

```cue
values: {
	securityContext: {
		pod: {
			fsGroup:             568
			fsGroupChangePolicy: "OnRootMismatch"
			supplementalGroups: [568]
		}
		container: {
			readOnlyRootFilesystem:   false
			runAsNonRoot:             false
			runAsUser:                0
			runAsGroup:               0
		}
	}
	redis: {
		securityContext: {
			container: {
				runAsNonRoot:           false
				runAsUser:              568
				runAsGroup:             0
				readOnlyRootFilesystem: false
			}
		}
	}
	cnpg: {
		main: {
			securityContext: {
				container: {
					runAsUser:  26
					runAsGroup: 26
				}
			}
		}
	}
}
```

## Additional Resources
- [Official NocoDB Website](https://nocodb.com/)
- [Official NocoDB Repository](https://github.com/nocodb/nocodb)
- [NocoDB Documentation](https://docs.nocodb.com/)
- [CloudNativePG Documentation](https://cloudnative-pg.io/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the NocoDB module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| NocoDB (`nocodb`) | Deployment | 12 points | ✅ |
| Redis / Valkey (`nocodb-redis`) | StatefulSet | 12 points | ✅ |
