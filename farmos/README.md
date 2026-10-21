# farmOS

## Description

[farmOS](https://farmos.org/) is a web-based application for farm management, planning, and record keeping. It is developed by a community of volunteers and aims to provide a standard platform for farmers, developers, and researchers to build upon.

## Application Information
- **Version:** `latest` (Chart `10.0.1`)
- **Official Website:** [https://farmos.org/](https://farmos.org/)
- **Upstream Project:** [https://github.com/farmOS/farmOS](https://github.com/farmOS/farmOS)
- **Container Base:**
  - farmOS Application: [docker.io/farmos/farmos](https://hub.docker.com/r/farmos/farmos) (`docker.io/farmos/farmos:latest@sha256:0ead55792d93aaf9dc69d0e53e171a70163e4443d62df3bb7fb695c9487e3bc3`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:16-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **farmOS Web Server Workload (`farmos`):** Core web-based farm management application running on container HTTP port `80` and exposed on service port `80`.
- **Deployment (`farmos`):** Single-replica deployment with `Recreate` upgrade strategy, `livenessProbe`, `readinessProbe`, and `startupProbe` TCP health checks, persistent `/var/www/html/sites` storage mount (`sitesdirectory`), and memory-backed runtime `emptyDir` mounts (`devshm`, `shared`, `tmp`, `varlogs`, `varrun`).
- **Service (`farmos`):** Kubernetes `ClusterIP` Service exposing the farmOS web application on port `80` targeting container port `80`.
- **PersistentVolumeClaim (`farmos-sitesdirectory`):** Persistent storage volume (`ReadWriteOnce`, `100Gi` default) mounted at `/var/www/html/sites` for farmOS site data and configuration.
- **PostgreSQL Database (`farmos-postgresql`):** Dedicated PostgreSQL 16 database `StatefulSet` (with `volumeClaimTemplates` for `10Gi` persistent storage), `Service` (port `5432`), and `Secret` (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`).
- **Gateway API HTTPRoute (`farmos`):** Optional Gateway API `HTTPRoute` resource (`gateway.networking.k8s.io/v1`) for routing HTTP/HTTPS traffic via Kubernetes Gateway API controllers.

## Prerequisites

- Kubernetes cluster v1.33+ (or v1.20+ minimum supported by module schema)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting `ReadWriteOnce` PVCs if `persistence.sitesdirectory.enabled` or `postgresql.persistence.enabled` is active
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply farmos ./farmos
```

To deploy with customized values (for example customizing PostgreSQL credentials and `HTTPRoute`), create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		sitesdirectory: {
			enabled:   true
			mountPath: "/var/www/html/sites"
			size:      "100Gi"
		}
	}
	postgresql: {
		enabled: true
		auth: {
			database: "farmos"
			username: "farmos"
			password: "farmos-secret-password"
		}
		persistence: {
			enabled: true
			size:    "10Gi"
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port:       80
					protocol:   "tcp"
					targetPort: 80
				}
			}
		}
	}
	gatewayAPI: {
		enabled: true
		httpRoutes: [
			{
				parentRefs: [
					{
						name:      "main-gateway"
						namespace: "gateway-system"
					},
				]
				hostnames: [
					"farmos.example.com",
				]
			},
		]
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
timoni -n default apply farmos ./farmos \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete farmos
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `metadata.labels` | `object` | `{}` | Additional labels applied to all module resources |
| `metadata.annotations` | `object` | `{}` | Annotations applied to all module resources |
| `image.repository` | `string` | `"docker.io/farmos/farmos"` | Container image repository |
| `image.tag` | `string` | `"latest@sha256:0ead55792d93aaf9dc69d0e53e171a70163e4443d62df3bb7fb695c9487e3bc3"` | Container image release tag and digest |
| `image.digest` | `string` | `""` | Container image SHA256 digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `tz` | `string` | `"UTC"` | Container timezone (`TZ` environment variable) |
| `replicas` | `int` | `1` | Workload replica count |
| `persistence.sitesdirectory.enabled` | `bool` | `true` | Enable the `sitesdirectory` PersistentVolumeClaim |
| `persistence.sitesdirectory.mountPath` | `string` | `"/var/www/html/sites"` | Container mount path for the `sitesdirectory` volume |
| `persistence.sitesdirectory.size` | `string` | `"100Gi"` | Storage capacity requested for the PVC |
| `persistence.sitesdirectory.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.sitesdirectory.storageClass` | `string` | `""` | Optional StorageClass name for the PVC |
| `postgresql.enabled` | `bool` | `true` | Enable the PostgreSQL database component |
| `postgresql.image.repository` | `string` | `"docker.io/library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | `string` | `"16-alpine"` | PostgreSQL container image tag |
| `postgresql.image.pullPolicy` | `string` | `"IfNotPresent"` | PostgreSQL image pull policy |
| `postgresql.auth.database` | `string` | `"farmos"` | PostgreSQL database name |
| `postgresql.auth.username` | `string` | `"farmos"` | PostgreSQL database username |
| `postgresql.auth.password` | `string` | `"farmos-secret-password"` | PostgreSQL database password |
| `postgresql.service.port` | `int` | `5432` | PostgreSQL Service port |
| `postgresql.persistence.enabled` | `bool` | `true` | Enable PersistentVolumeClaim for PostgreSQL data |
| `postgresql.persistence.size` | `string` | `"10Gi"` | Storage capacity requested for the PostgreSQL PVC |
| `postgresql.persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PostgreSQL PVC access modes |
| `postgresql.persistence.storageClass` | `string` | `""` | Optional StorageClass name for the PostgreSQL PVC |
| `postgresql.resources.requests.cpu` | `string` | `"50m"` | PostgreSQL container CPU request |
| `postgresql.resources.requests.memory` | `string` | `"128Mi"` | PostgreSQL container memory request |
| `postgresql.resources.limits.cpu` | `string` | `"1000m"` | PostgreSQL container CPU limit |
| `postgresql.resources.limits.memory` | `string` | `"1024Mi"` | PostgreSQL container memory limit |
| `service.main.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.main.annotations` | `object` | `{}` | Annotations applied to the Service |
| `service.main.ports.main.port` | `int` | `80` | Application Service port |
| `service.main.ports.main.protocol` | `string` | `"tcp"` | Service port protocol |
| `service.main.ports.main.targetPort` | `int` | `80` | Container HTTP target port |
| `gatewayAPI.enabled` | `bool` | `true` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | Route definitions with `parentRefs`, `hostnames`, `rules`, `labels`, and `annotations` |
| `resources.requests.cpu` | `string` | `"75m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"200Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"1500m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"2400Mi"` | Container memory limit |
| `securityContext.pod.fsGroup` | `int` | `568` | Pod filesystem group GID |
| `securityContext.pod.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `securityContext.pod.supplementalGroups` | `list` | `[568]` | Pod supplemental group IDs |
| `securityContext.pod.sysctls` | `list` | `[{"name": "net.ipv4.ip_unprivileged_port_start", "value": "80"}]` | Pod namespace sysctls |
| `securityContext.container.runAsNonRoot` | `bool` | `false` | Enforce non-root execution |
| `securityContext.container.runAsUser` | `int` | `0` | Container user UID |
| `securityContext.container.runAsGroup` | `int` | `0` | Container group GID |
| `securityContext.container.readOnlyRootFilesystem` | `bool` | `false` | Mount container root filesystem as read-only |
| `securityContext.container.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `securityContext.container.privileged` | `bool` | `false` | Run container in privileged mode |
| `securityContext.container.seccompProfile.type` | `string` | `"RuntimeDefault"` | Container seccomp profile type |
| `securityContext.container.capabilities.add` | `list` | `["NET_BIND_SERVICE", "CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"]` | Linux capabilities added to container |
| `securityContext.container.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `podAnnotations` | `object` | `{}` | Annotations applied to pods |
| `nodeSelector` | `object` | `{"kubernetes.io/arch": "amd64"}` | Node selector labels for pod scheduling |
| `affinity` | `object` | `{podAffinity: ...}` | Pod and node affinity scheduling rules |
| `topologySpreadConstraints` | `list` | `[...]` | Pod topology spread constraints (`ScheduleAnyway`, `maxSkew: 1`) |
| `tolerations` | `list` | `[]` | Pod tolerations for node taints |

## Additional Resources
- [Official farmOS Website](https://farmos.org/)
- [Official farmOS Documentation](https://farmos.org/guide/)
- [farmOS GitHub Repository](https://github.com/farmOS/farmOS)
- [farmOS Docker Hub](https://hub.docker.com/r/farmos/farmos)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the farmOS module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| farmOS Server (`farmos`) | Deployment | 10 points | ✅ |
| PostgreSQL Database (`farmos-postgresql`) | StatefulSet | 14 points | ✅ |
