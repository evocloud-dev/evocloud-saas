# Traccar

## Description
[Traccar](https://www.traccar.org/) is an open-source modern GPS tracking platform that supports more than 2,000 GPS tracking device protocols and models. It provides real-time device location tracking, historical trajectory playback, geofencing, multi-channel alerts (SMS, email, push notifications), comprehensive trip reports, and a responsive web and mobile management interface. It enables fleet managers, logistics operators, and individuals to monitor vehicles and personal tracking assets securely and efficiently.

## Application Information
- **Version:** 6.17
- **Upstream Project:** [https://www.traccar.org](https://www.traccar.org) ([GitHub](https://github.com/traccar/traccar))
- **Container Base:** [docker.io/traccar/traccar](https://hub.docker.com/r/traccar/traccar) (`docker.io/traccar/traccar:6.17@sha256:b32d9346adf46df7c33c58577e17ad60f6feadd1f3cd87c876041f6c79317ef1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Traccar GPS Tracking Server (`traccar`):** Core GPS tracking service running `docker.io/traccar/traccar:6.17` on container port 8082, exposed via ClusterIP Service on port 8082.
- **PostgreSQL Database Cluster (`traccar-cnpg-main`):** High-availability CloudNativePG PostgreSQL database cluster (`2` instances) running `ghcr.io/cloudnative-pg/postgresql:16.15` providing resilient relational data storage for telemetry, device registries, and user configurations.
- **Database Wait Init Container (`traccar-system-cnpg-wait`):** Synchronization init container running `oci.trueforge.org/containerforge/postgresql-client:9.6.24` that verifies PostgreSQL connection readiness via `pg_isready` before starting Traccar.
- **Persistent Storage (`traccar-data`):** Dedicated PersistentVolumeClaim mounted at `/opt/traccar/data` providing persistent storage (`100Gi`, ReadWriteOnce) for configuration, tracker logs, and runtime application data.
- **Memory-backed Ephemeral Mounts:** High-performance emptyDir memory volumes mounted at `/dev/shm`, `/tmp`, `/var/logs`, `/var/run`, and `/shared` (`2400Mi` sizeLimit), supporting secure temporary directory isolation.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- [CloudNativePG (CNPG) Operator](https://cloudnative-pg.io) installed in the cluster

## Install

To create an instance using default values:

```shell
timoni -n default apply traccar ./traccar
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		data: {
			size: "200Gi"
		}
	}
	resources: {
		limits: {
			cpu:    "2000m"
			memory: "4Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply traccar ./traccar \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete traccar
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"docker.io/traccar/traccar"` | Container image repository |
| `image.tag` | string | `"6.17@sha256:b32d9346adf46df7c33c58577e17ad60f6feadd1f3cd87c876041f6c79317ef1"` | Container image tag and digest |
| `image.pullPolicy` | string | `"IfNotPresent"` | Container image pull policy |
| `replicas` | int | `1` | Number of pod replicas |
| `revisionHistoryLimit` | int | `3` | Number of revision history limits to retain |
| `strategy.type` | string | `"Recreate"` | Deployment update strategy |
| `resources.requests.cpu` | string | `"75m"` | CPU request for the Traccar container |
| `resources.requests.memory` | string | `"200Mi"` | Memory request for the Traccar container |
| `resources.limits.cpu` | string | `"1500m"` | CPU limit for the Traccar container |
| `resources.limits.memory` | string | `"2400Mi"` | Memory limit for the Traccar container |
| `initContainers."system-cnpg-wait".image.repository` | string | `"oci.trueforge.org/containerforge/postgresql-client"` | Init container image repository |
| `initContainers."system-cnpg-wait".image.tag` | string | `"9.6.24"` | Init container image tag |
| `initContainers."system-cnpg-wait".image.digest` | string | `"sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93"` | Init container image digest |
| `initContainers."system-cnpg-wait".resources.requests.cpu` | string | `"10m"` | CPU request for DB wait init container |
| `initContainers."system-cnpg-wait".resources.requests.memory` | string | `"50Mi"` | Memory request for DB wait init container |
| `initContainers."system-cnpg-wait".resources.limits.cpu` | string | `"500m"` | CPU limit for DB wait init container |
| `initContainers."system-cnpg-wait".resources.limits.memory` | string | `"512Mi"` | Memory limit for DB wait init container |
| `service.main.ports.main.port` | int | `8082` | Port exposed by the Kubernetes Service |
| `service.main.ports.main.targetPort` | int | `8082` | Container port for Traccar HTTP interface |
| `service.main.ports.main.protocol` | string | `"TCP"` | Network protocol |
| `persistence.data.enabled` | bool | `true` | Enable persistent storage for Traccar data |
| `persistence.data.mountPath` | string | `"/opt/traccar/data"` | Target directory inside container for persistent storage |
| `persistence.data.size` | string | `"100Gi"` | Persistent Volume size requested |
| `persistence.data.accessMode` | string | `"ReadWriteOnce"` | Storage volume access mode |
| `persistence.data.storageClass` | string | `undefined` | Optional StorageClass name for PVC dynamic provisioning |
| `cnpg.main.enabled` | bool | `true` | Enable CloudNativePG PostgreSQL cluster |
| `cnpg.main.user` | string | `"traccar"` | Database username |
| `cnpg.main.database` | string | `"traccar"` | Database name |
| `cnpg.image.repository` | string | `"ghcr.io/cloudnative-pg/postgresql"` | CNPG PostgreSQL image repository |
| `cnpg.image.tag` | string | `"16.15"` | CNPG PostgreSQL image tag |
| `cnpg.image.digest` | string | `"sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a"` | CNPG PostgreSQL image digest |
| `cnpg.instances` | int | `2` | PostgreSQL cluster replica count |
| `cnpg.storage` | string | `"100Gi"` | Storage size for CNPG database volume |
| `cnpg.walStorage` | string | `"100Gi"` | Storage size for CNPG WAL volume |
| `cnpg.resources.requests.cpu` | string | `"75m"` | CPU request for PostgreSQL instances |
| `cnpg.resources.requests.memory` | string | `"200Mi"` | Memory request for PostgreSQL instances |
| `cnpg.resources.limits.cpu` | string | `"1500m"` | CPU limit for PostgreSQL instances |
| `cnpg.resources.limits.memory` | string | `"2400Mi"` | Memory limit for PostgreSQL instances |
| `securityContext.container.runAsUser` | int | `0` | UID to run Traccar container process |
| `securityContext.container.runAsGroup` | int | `0` | Primary GID to run Traccar container process |
| `securityContext.container.readOnlyRootFilesystem` | bool | `false` | Mount root filesystem as read-only |
| `securityContext.container.allowPrivilegeEscalation` | bool | `false` | Prevent container process from gaining extra privileges |
| `securityContext.container.runAsNonRoot` | bool | `false` | Validate whether container runs as non-root |
| `podSecurityContext.fsGroup` | int | `568` | Supplemental group for volume ownership |
| `podSecurityContext.fsGroupChangePolicy` | string | `"OnRootMismatch"` | Policy for changing volume ownership and permissions |
| `podSecurityContext.supplementalGroups` | list | `[568]` | Additional supplemental groups for the pod |
| `env.TZ` | string | `"UTC"` | Timezone environment variable |
| `env.PUID` | int | `568` | Process user ID environment setting |
| `env.PGID` | int | `568` | Process group ID environment setting |
| `nodeSelector` | object | `{"kubernetes.io/arch": "amd64"}` | Node selector constraints |
| `terminationGracePeriodSeconds` | int | `60` | Grace period in seconds for graceful pod termination |

## Recommended values

For production environments, ensure appropriate persistent volume sizes and resource allocations for both the application and the CloudNativePG cluster:

```cue
values: {
	resources: {
		requests: {
			cpu:    "100m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "2000m"
			memory: "2048Mi"
		}
	}
	persistence: {
		data: {
			size: "200Gi"
		}
	}
	cnpg: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "2000m"
				memory: "2048Mi"
			}
		}
		storage: "200Gi"
	}
}
```

## Additional Resources
- [Official Traccar Website](https://www.traccar.org)
- [Official Traccar GitHub Repository](https://github.com/traccar/traccar)
- [Traccar Documentation](https://www.traccar.org/documentation/)
- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Traccar module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Traccar GPS Tracking System (`traccar`) | Deployment | 12 points | ✅ |
