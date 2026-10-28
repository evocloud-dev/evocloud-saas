# Grav

## Description

[Grav](https://getgrav.org) is a fast, simple, and flexible open-source flat-file CMS (Content Management System). Unlike traditional CMS platforms, Grav requires no database installation and stores content in Markdown files with YAML configuration, Twig templating, and smart caching.

## Application Information
- **Version:** `2.2.13`
- **Official Website:** [https://getgrav.org/](https://getgrav.org/)
- **Upstream Project:** [https://github.com/getgrav/grav](https://github.com/getgrav/grav)
- **Container Base:**
  - Grav Application: [ghcr.io/linuxserver/grav](https://github.com/linuxserver/docker-grav) (`ghcr.io/linuxserver/grav:2.2.13`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Grav Web Server Workload (`grav`):** Core flat-file CMS web application running on container HTTP port `80` and exposed on service port `10012`.
- **Deployment (`grav`):** Single-replica deployment with `Recreate` upgrade strategy, `livenessProbe`, `readinessProbe`, and `startupProbe` health checks, memory-backed runtime `emptyDir` mounts, and pod affinity co-locating with the `config` PVC.
- **Service (`grav`):** Kubernetes `ClusterIP` Service exposing the Grav web platform on port `10012` targeting container port `80`.
- **PersistentVolumeClaim (`grav-config`):** Persistent volume claim mounted at `/config` for Grav site content, plugins, themes, and configuration (`100Gi` default).
- **Gateway API HTTPRoute (`grav`):** Optional Gateway API `HTTPRoute` resource (`gateway.networking.k8s.io/v1`) for routing HTTP/HTTPS traffic via Kubernetes Gateway API controllers.

## Prerequisites

- Kubernetes cluster v1.33+ (or v1.20+ minimum supported by module schema)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply grav ./grav
```

To deploy with customized values (for example enabling `HTTPRoute`), create a `my-values.cue` file:

```cue
package main

values: {
	service: {
		main: {
			ports: {
				main: {
					port:       10012
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
					"grav.example.com",
				]
			},
		]
	}
	persistence: {
		config: {
			enabled:   true
			mountPath: "/config"
			size:      "100Gi"
		}
		varrun: {
			enabled: true
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply grav ./grav \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete grav
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `metadata.labels` | `object` | `{}` | Additional labels applied to all module resources |
| `metadata.annotations` | `object` | `{}` | Annotations applied to all module resources |
| `replicas` | `int` | `1` | Workload replica count |
| `serviceAccountName` | `string` | `"default"` | Kubernetes ServiceAccount name used by the pod |
| `TZ` | `string` | `"UTC"` | Timezone environment variable (`TZ`) passed to the container |
| `image.repository` | `string` | `"ghcr.io/linuxserver/grav"` | Container image repository |
| `image.tag` | `string` | `"2.2.13"` | Container image release tag |
| `image.digest` | `string` | `""` | Container image SHA256 digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `env` | `list` | `[...]` | Container environment variables (`TZ`, `UMASK`, `PUID`, `PGID`, etc.) |
| `service.main.enabled` | `bool` | `true` | Enable the main Kubernetes Service |
| `service.main.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.main.publishNotReadyAddresses` | `bool` | `false` | Publish not-ready endpoint addresses |
| `service.main.annotations` | `object` | `{}` | Annotations applied to the Service |
| `service.main.ports.main.enabled` | `bool` | `true` | Enable the main Service port |
| `service.main.ports.main.port` | `int` | `10012` | Application Service port |
| `service.main.ports.main.protocol` | `string` | `"TCP"` | Service port protocol |
| `service.main.ports.main.targetPort` | `int` | `80` | Container HTTP target port |
| `gatewayAPI.enabled` | `bool` | `false` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[]` | Route definitions with `parentRefs`, `hostnames`, `rules`, `labels`, and `annotations` |
| `persistence.config.enabled` | `bool` | `true` | Enable persistent storage for `/config` (`<name>-config` PVC) |
| `persistence.config.mountPath` | `string` | `"/config"` | Mount path for the `config` persistent volume |
| `persistence.config.readOnly` | `bool` | `false` | Mount the `config` volume as read-only |
| `persistence.config.size` | `string` | `"100Gi"` | Storage capacity of the persistent volume claim |
| `persistence.config.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.config.storageClass` | `string` | `""` | Optional StorageClass name for the `config` PVC |
| `persistence.devshm.enabled` | `bool` | `true` | Enable memory-backed `/dev/shm` `emptyDir` volume |
| `persistence.devshm.mountPath` | `string` | `"/dev/shm"` | Mount path for `devshm` |
| `persistence.devshm.sizeLimit` | `string` | `"2400Mi"` | Size limit for `devshm` `emptyDir` |
| `persistence.shared.enabled` | `bool` | `true` | Enable `/shared` `emptyDir` volume |
| `persistence.shared.mountPath` | `string` | `"/shared"` | Mount path for `shared` |
| `persistence.tmp.enabled` | `bool` | `true` | Enable memory-backed `/tmp` `emptyDir` volume |
| `persistence.tmp.mountPath` | `string` | `"/tmp"` | Mount path for `tmp` |
| `persistence.tmp.sizeLimit` | `string` | `"2400Mi"` | Size limit for `tmp` `emptyDir` |
| `persistence.varlogs.enabled` | `bool` | `true` | Enable memory-backed `/var/logs` `emptyDir` volume |
| `persistence.varlogs.mountPath` | `string` | `"/var/logs"` | Mount path for `varlogs` |
| `persistence.varlogs.sizeLimit` | `string` | `"2400Mi"` | Size limit for `varlogs` `emptyDir` |
| `persistence.varrun.enabled` | `bool` | `true` | Enable memory-backed `/var/run` `emptyDir` volume |
| `persistence.varrun.mountPath` | `string` | `"/var/run"` | Mount path for `varrun` |
| `persistence.varrun.sizeLimit` | `string` | `"2400Mi"` | Size limit for `varrun` `emptyDir` |
| `resources.requests.cpu` | `string` | `"75m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"200Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"1500m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"2400Mi"` | Container memory limit |
| `securityContext.pod.fsGroup` | `int` | `568` | Pod filesystem group GID |
| `securityContext.pod.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `securityContext.pod.supplementalGroups` | `list` | `[568]` | Pod supplemental group IDs |
| `securityContext.pod.sysctls` | `list` | `[{name: "net.ipv4.ip_unprivileged_port_start", value: "80"}]` | Pod namespace sysctls |
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
| `affinity` | `object` | `podAffinity` on `truecharts.org/pvc: config` | Pod and node affinity scheduling rules |
| `topologySpreadConstraints` | `list` | `[...]` | Pod topology spread constraints (`ScheduleAnyway`, `maxSkew: 1`) |
| `tolerations` | `list` | `[]` | Pod tolerations for node taints |

## Additional Resources
- [Official Grav Website](https://getgrav.org/)
- [Official Grav Documentation](https://learn.getgrav.org/)
- [Grav GitHub Repository](https://github.com/getgrav/grav)
- [LinuxServer.io Grav Container](https://github.com/linuxserver/docker-grav)
- [Timoni Documentation](https://timoni.sh)

## Changelog

### 0.1.1 - 2026-10-26
- **Changed:** Upgraded Grav application container image from `2.2.9` to `2.2.13` (`ghcr.io/linuxserver/grav:2.2.13`).

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Grav module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Grav Server (`grav`) | Deployment | 10 points | ✅ |
