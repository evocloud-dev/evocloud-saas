# Semaphore

## Description

[Semaphore](https://semaphoreui.com/) is a modern, open source alternative to Ansible Tower. It is a self-hosted web-based solution that allows you to create and manage Ansible projects, playbooks, and roles, while also providing a web interface for running and monitoring Ansible tasks.

## Application Information
- **Version:** `2.19.17` (Chart `8.0.2`)
- **Official Website:** [https://semaphoreui.com/](https://semaphoreui.com/)
- **Upstream Project:** [https://github.com/semaphoreui/semaphore](https://github.com/semaphoreui/semaphore)
- **Container Base:**
  - Semaphore Application: [docker.io/semaphoreui/semaphore](https://hub.docker.com/r/semaphoreui/semaphore) (`docker.io/semaphoreui/semaphore:v2.19.17@sha256:008dacd9f1adbd92e8a048f1786ae1dd9bed2a352aca2eb30b9837de5706e7f7`)
  - CloudNativePG PostgreSQL: [ghcr.io/cloudnative-pg/postgresql](https://github.com/cloudnative-pg/postgres-containers) (`ghcr.io/cloudnative-pg/postgresql:16.15@sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a`)
  - PostgreSQL Readiness Wait InitContainer: `oci.trueforge.org/containerforge/postgresql-client:9.6.24@sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93`
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Semaphore Web Server Workload (`semaphore`):** Core web-based Ansible UI and task runner running on container HTTP port `3000` and exposed on service port `3000`.
- **Deployment (`semaphore`):** Single-replica deployment with `Recreate` upgrade strategy, `livenessProbe`, `readinessProbe`, and `startupProbe` HTTP health checks, persistent `/etc/semaphore` (`config`) and `/data` (`data`) storage mounts, memory-backed runtime `emptyDir` mounts (`devshm`, `shared`, `tmp`, `varlogs`, `varrun`), and a `semaphore-system-cnpg-wait` init container that waits for PostgreSQL readiness.
- **Service (`semaphore`):** Kubernetes `ClusterIP` Service exposing the Semaphore web interface on port `3000` targeting container port `3000`.
- **PersistentVolumeClaims (`semaphore-config`, `semaphore-data`):** Persistent storage volumes (`ReadWriteOnce`, `100Gi` default) mounted at `/etc/semaphore` for Semaphore configuration and `/data` for Ansible playbooks and repositories.
- **Secrets (`semaphore-semaphore-secrets`, `semaphore-cnpg-main-user`, `semaphore-cnpg-main-urls`):** Kubernetes Secrets storing the Semaphore access key encryption secret (`SEMAPHORE_ACCESS_KEY_ENCRYPTION`), PostgreSQL basic-auth credentials, and database connection URLs (`host`, `jdbc`, `nossl`, `porthost`, `std`).
- **CloudNativePG Cluster (`semaphore-cnpg-main`):** High-availability PostgreSQL 16 `Cluster` (`postgresql.cnpg.io/v1`) with 2 instances, `100Gi` data storage, and `100Gi` WAL storage.
- **Gateway API HTTPRoute (`semaphore`):** Optional Gateway API `HTTPRoute` resource (`gateway.networking.k8s.io/v1`) for routing HTTP/HTTPS traffic via Kubernetes Gateway API controllers.

## Prerequisites

- Kubernetes cluster v1.33+ (or v1.20+ minimum supported by module schema)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- [CloudNativePG Operator](https://cloudnative-pg.io/) (`postgresql.cnpg.io/v1` CRDs) installed if `cnpg.main.enabled` is active
- StorageClass supporting `ReadWriteOnce` PVCs if `persistence.config.enabled`, `persistence.data.enabled`, or `cnpg.main.enabled` is active
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply semaphore ./semaphore
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		config: {
			enabled:   true
			mountPath: "/etc/semaphore"
			storage:   "100Gi"
		}
		data: {
			enabled:   true
			mountPath: "/data"
			storage:   "100Gi"
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port:       3000
					protocol:   "http"
					targetPort: 3000
				}
			}
		}
	}
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						env: {
							SEMAPHORE_ADMIN:          "admin"
							SEMAPHORE_ADMIN_NAME:     "admin"
							SEMAPHORE_ADMIN_PASSWORD: "changeme"
							SEMAPHORE_ADMIN_EMAIL:    "admin@localhost"
						}
					}
				}
			}
		}
	}
	cnpg: {
		main: {
			enabled:   true
			user:      "semaphore"
			password:  "PLACEHOLDERPASSWORD"
			database:  "semaphore"
			instances: 2
		}
	}
	resources: {
		requests: {
			cpu:    "75m"
			memory: "200Mi"
		}
		limits: {
			cpu:    "1500m"
			memory: "2400Mi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply semaphore ./semaphore \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete semaphore
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `metadata.labels` | `object` | `{}` | Additional labels applied to all module resources |
| `metadata.annotations` | `object` | `{}` | Annotations applied to all module resources |
| `image.repository` | `string` | `"docker.io/semaphoreui/semaphore"` | Container image repository |
| `image.tag` | `string` | `"v2.19.17"` | Container image release tag |
| `image.digest` | `string` | `"sha256:008dacd9f1adbd92e8a048f1786ae1dd9bed2a352aca2eb30b9837de5706e7f7"` | Container image SHA256 digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `replicas` | `int` | `1` | Workload replica count |
| `semaphore.accessKeyEncryption` | `string` | `"mhRwnWnp57QztexJJkHtYf618h4dapMu"` | Encryption key stored in `semaphore-secrets` (`SEMAPHORE_ACCESS_KEY_ENCRYPTION`) |
| `semaphore.tz` | `string` | `"UTC"` | Container timezone (`TZ` environment variable) |
| `semaphore.umask` | `string` | `"0022"` | Container file creation mask (`UMASK` and `UMASK_SET`) |
| `semaphore.puid` | `string` | `"568"` | Application user ID (`PUID`, `USER_ID`, `UID`) |
| `semaphore.pgid` | `string` | `"568"` | Application group ID (`PGID`, `GROUP_ID`, `GID`) |
| `workload.main.podSpec.containers.main.env` | `object` | `{...}` | Environment variables (`SEMAPHORE_DB_*`, `SEMAPHORE_ADMIN*`, `SEMAPHORE_LDAP_*`, `SEMAPHORE_PLAYBOOK_PATH`) |
| `persistence.config.enabled` | `bool` | `true` | Enable the `config` PersistentVolumeClaim |
| `persistence.config.mountPath` | `string` | `"/etc/semaphore"` | Container mount path for the `config` volume |
| `persistence.config.storage` | `string` | `"100Gi"` | Storage capacity requested for the `config` PVC |
| `persistence.config.accessModes` | `list` | `["ReadWriteOnce"]` | `config` PVC access modes |
| `persistence.config.storageClass` | `string` | `""` | Optional StorageClass name for the `config` PVC |
| `persistence.data.enabled` | `bool` | `true` | Enable the `data` PersistentVolumeClaim |
| `persistence.data.mountPath` | `string` | `"/data"` | Container mount path for the `data` volume |
| `persistence.data.storage` | `string` | `"100Gi"` | Storage capacity requested for the `data` PVC |
| `persistence.data.accessModes` | `list` | `["ReadWriteOnce"]` | `data` PVC access modes |
| `persistence.data.storageClass` | `string` | `""` | Optional StorageClass name for the `data` PVC |
| `cnpg.main.enabled` | `bool` | `true` | Enable the CloudNativePG PostgreSQL cluster and secrets |
| `cnpg.main.user` | `string` | `"semaphore"` | PostgreSQL database owner username |
| `cnpg.main.password` | `string` | `"PLACEHOLDERPASSWORD"` | PostgreSQL database user password |
| `cnpg.main.database` | `string` | `"semaphore"` | PostgreSQL database name |
| `cnpg.main.port` | `int` | `5432` | PostgreSQL service port |
| `cnpg.main.instances` | `int` | `2` | Number of PostgreSQL instances in the CNPG cluster |
| `cnpg.main.storage.size` | `string` | `"100Gi"` | Storage size for the CNPG database PVC template |
| `cnpg.main.walStorage.size` | `string` | `"100Gi"` | Storage size for the CNPG WAL PVC template |
| `service.main.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.main.annotations` | `object` | `{}` | Annotations applied to the Service |
| `service.main.ports.main.port` | `int` | `3000` | Application Service port |
| `service.main.ports.main.protocol` | `string` | `"http"` | Service port protocol |
| `service.main.ports.main.targetPort` | `int` | `3000` | Container HTTP target port |
| `gatewayAPI.enabled` | `bool` | `false` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | Route definitions with `parentRefs`, `hostnames`, `rules`, `labels`, and `annotations` |
| `resources.requests.cpu` | `string` | `"75m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"200Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"1500m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"2400Mi"` | Container memory limit |
| `securityContext.pod.fsGroup` | `int` | `568` | Pod filesystem group GID |
| `securityContext.pod.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `securityContext.pod.supplementalGroups` | `list` | `[568]` | Pod supplemental group IDs |
| `securityContext.pod.sysctls` | `list` | `[]` | Pod namespace sysctls |
| `securityContext.container.runAsNonRoot` | `bool` | `false` | Enforce non-root execution |
| `securityContext.container.runAsUser` | `int` | `0` | Container user UID |
| `securityContext.container.runAsGroup` | `int` | `0` | Container group GID |
| `securityContext.container.readOnlyRootFilesystem` | `bool` | `false` | Mount container root filesystem as read-only |
| `securityContext.container.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `securityContext.container.privileged` | `bool` | `false` | Run container in privileged mode |
| `securityContext.container.seccompProfile.type` | `string` | `"RuntimeDefault"` | Container seccomp profile type |
| `securityContext.container.capabilities.add` | `list` | `["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"]` | Linux capabilities added to container |
| `securityContext.container.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `securityContext.initContainer.runAsNonRoot` | `bool` | `true` | Enforce non-root execution for the init container |
| `securityContext.initContainer.runAsUser` | `int` | `568` | Init container user UID |
| `securityContext.initContainer.runAsGroup` | `int` | `568` | Init container group GID |
| `securityContext.initContainer.readOnlyRootFilesystem` | `bool` | `true` | Mount init container root filesystem as read-only |
| `podAnnotations` | `object` | `{}` | Annotations applied to pods |
| `nodeSelector` | `object` | `{"kubernetes.io/arch": "amd64"}` | Node selector labels for pod scheduling |
| `affinity` | `object` | `{podAffinity: ...}` | Pod and node affinity scheduling rules |
| `topologySpreadConstraints` | `list` | `[...]` | Pod topology spread constraints (`ScheduleAnyway`, `maxSkew: 1`) |
| `tolerations` | `list` | `[]` | Pod tolerations for node taints |

## Additional Resources
- [Official Semaphore Website](https://semaphoreui.com/)
- [Official Semaphore Documentation](https://docs.semaphoreui.com/)
- [Semaphore GitHub Repository](https://github.com/semaphoreui/semaphore)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Semaphore module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Semaphore Server (`semaphore`) | Deployment | 12 points | ✅ |
