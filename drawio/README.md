# Drawio

## Description

[draw.io](https://www.drawio.com/) (formerly diagrams.net) is free, open-source online diagramming and whiteboarding software for creating flowcharts, process diagrams, org charts, UML, ER, and network diagrams.

## Application Information
- **Version:** `32.5.5`
- **Official Website:** [https://www.drawio.com/](https://www.drawio.com/)
- **Upstream Project:** [https://github.com/jgraph/drawio](https://github.com/jgraph/drawio)
- **Container Base:**
  - Drawio Application: [docker.io/jgraph/drawio](https://hub.docker.com/r/jgraph/drawio) (`docker.io/jgraph/drawio:32.5.5@sha256:30fefe1cf6e48c78f8816cdcd969d0a402a6bfd5077252cf5bb0428fd8ceaf69`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Drawio Web Server Workload (`drawio`):** Core web diagramming application running on container HTTP port `8080` and exposed on service port `10214`.
- **Deployment (`drawio`):** Single-replica deployment with `Recreate` upgrade strategy, `livenessProbe`, `readinessProbe`, and `startupProbe` health checks, and memory-backed runtime `emptyDir` mounts (`devshm`, `shared`, `tmp`, `varlogs`, `varrun`).
- **Service (`drawio`):** Kubernetes `ClusterIP` Service exposing the Drawio web application on port `10214` targeting container port `8080`.
- **Gateway API HTTPRoute (`drawio`):** Optional Gateway API `HTTPRoute` resource (`gateway.networking.k8s.io/v1`) for routing HTTP/HTTPS traffic via Kubernetes Gateway API controllers.

## Prerequisites

- Kubernetes cluster v1.33+ (or v1.20+ minimum supported by module schema)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply drawio ./drawio
```

To deploy with customized values (for example enabling `HTTPRoute`), create a `my-values.cue` file:

```cue
package main

values: {
	service: {
		main: {
			ports: {
				main: {
					port:       10214
					targetPort: 8080
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
					"drawio.example.com",
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
timoni -n default apply drawio ./drawio \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete drawio
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `metadata.labels` | `object` | `{}` | Additional labels applied to all module resources |
| `metadata.annotations` | `object` | `{}` | Annotations applied to all module resources |
| `image.repository` | `string` | `"docker.io/jgraph/drawio"` | Container image repository |
| `image.tag` | `string` | `"32.5.5@sha256:30fefe1cf6e48c78f8816cdcd969d0a402a6bfd5077252cf5bb0428fd8ceaf69"` | Container image release tag and digest |
| `image.digest` | `string` | `""` | Container image SHA256 digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `service.main.enabled` | `bool` | `true` | Enable the main Kubernetes Service |
| `service.main.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.main.publishNotReadyAddresses` | `bool` | `false` | Publish not-ready endpoint addresses |
| `service.main.annotations` | `object` | `{}` | Annotations applied to the Service |
| `service.main.ports.main.enabled` | `bool` | `true` | Enable the main Service port |
| `service.main.ports.main.port` | `int` | `10214` | Application Service port |
| `service.main.ports.main.protocol` | `string` | `"TCP"` | Service port protocol |
| `service.main.ports.main.targetPort` | `int` | `8080` | Container HTTP target port |
| `gatewayAPI.enabled` | `bool` | `false` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[]` | Route definitions with `parentRefs`, `hostnames`, `rules`, `labels`, and `annotations` |
| `workload.main.replicas` | `int` | `1` | Workload replica count |
| `workload.main.revisionHistoryLimit` | `int` | `3` | Number of old ReplicaSets to retain |
| `workload.main.strategy.type` | `string` | `"Recreate"` | Deployment strategy type |
| `workload.main.podSpec.serviceAccountName` | `string` | `"default"` | Kubernetes ServiceAccount name used by the pod |
| `workload.main.podSpec.containers.main.probes.liveness.type` | `string` | `"http"` | Liveness probe protocol type |
| `workload.main.podSpec.containers.main.probes.liveness.path` | `string` | `"/"` | Liveness probe HTTP path |
| `workload.main.podSpec.containers.main.probes.readiness.type` | `string` | `"http"` | Readiness probe protocol type |
| `workload.main.podSpec.containers.main.probes.readiness.path` | `string` | `"/"` | Readiness probe HTTP path |
| `workload.main.podSpec.containers.main.probes.startup.type` | `string` | `"http"` | Startup probe protocol type |
| `workload.main.podSpec.containers.main.probes.startup.path` | `string` | `"/"` | Startup probe HTTP path |
| `workload.main.podSpec.containers.main.env` | `object` | `{}` | Additional container environment variables |
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
| `podAnnotations` | `object` | `{}` | Annotations applied to pods |
| `nodeSelector` | `object` | `{"kubernetes.io/arch": "amd64"}` | Node selector labels for pod scheduling |
| `affinity` | `object` | `{}` | Pod and node affinity scheduling rules |
| `topologySpreadConstraints` | `list` | `[...]` | Pod topology spread constraints (`ScheduleAnyway`, `maxSkew: 1`) |
| `tolerations` | `list` | `[]` | Pod tolerations for node taints |

## Additional Resources
- [Official Drawio Website](https://www.drawio.com/)
- [Official Drawio Documentation](https://www.drawio.com/doc/)
- [Drawio GitHub Repository](https://github.com/jgraph/drawio)
- [Drawio Docker Hub](https://hub.docker.com/r/jgraph/drawio)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Drawio module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Drawio Server (`drawio`) | Deployment | 10 points | ✅ |

## Additional Resources
- [Official Drawio Website](https://www.drawio.com/)
- [Official Drawio Documentation](https://www.drawio.com/doc/)
- [Drawio GitHub Repository](https://github.com/jgraph/drawio)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Drawio module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Drawio Server (`drawio`) | Deployment | 10 points | ✅ |

