# Nexus OSS

## Description
[Sonatype Nexus OSS](https://www.sonatype.com/products/sonatype-nexus-repository) is an open-source artifact repository manager that organizes, stores, and distributes software components and build dependencies across major package ecosystems (Docker, Maven, npm, PyPI, Helm, NuGet, and more). It helps DevOps and software engineering teams centralize binary management, accelerate builds, proxy public repositories, and maintain control over software supply chain artifacts.

## Application Information
- **Version:** 3.97.3
- **Upstream Project:** [https://github.com/sonatype/nexus-public](https://github.com/sonatype/nexus-public)
- **Container Base:** [docker.io/sonatype/nexus3](https://hub.docker.com/r/sonatype/nexus3) (`docker.io/sonatype/nexus3:3.97.3@sha256:4b9a0efb605808c15927c751107b3f3308ae306c4b22715c96bf9bbabbb0e736`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Nexus Repository Manager (`nexus-oss`):** Core Java application running `docker.io/sonatype/nexus3:3.97.3` on container port 8081, exposed via ClusterIP Service on port 10288.
- **Gateway API HTTPRoute (`httproute`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource for modern ingress routing into the Nexus service.
- **Persistent Storage (`nexus-oss-data`):** Dedicated PersistentVolumeClaim mounted at `/nexus-data` providing persistent storage (`100Gi`, ReadWriteOnce) for blob stores, components, repository configurations, and runtime state.
- **Memory-backed Ephemeral Mounts:** High-performance emptyDir memory volumes mounted at `/dev/shm`, `/tmp`, `/var/logs`, `/var/run`, and `/shared` (`2400Mi` sizeLimit), enabling fully secure execution with `readOnlyRootFilesystem: true`.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply nexus-oss ./nexus-oss
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
timoni -n default apply nexus-oss ./nexus-oss \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete nexus-oss
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"docker.io/sonatype/nexus3"` | Container image repository |
| `image.tag` | string | `"3.97.3@sha256:4b9a0efb605808c15927c751107b3f3308ae306c4b22715c96bf9bbabbb0e736"` | Container image tag and digest |
| `image.pullPolicy` | string | `"IfNotPresent"` | Container image pull policy |
| `replicas` | int | `1` | Number of pod replicas |
| `revisionHistoryLimit` | int | `3` | Number of revision history limits to retain |
| `strategy.type` | string | `"Recreate"` | Deployment update strategy |
| `service.main.type` | string | `"ClusterIP"` | Kubernetes Service type |
| `service.main.ports.main.port` | int | `10288` | Port exposed by the Kubernetes Service |
| `service.main.ports.main.targetPort` | int | `8081` | Container port for Nexus HTTP interface |
| `service.main.ports.main.protocol` | string | `"TCP"` | Network protocol |
| `persistence.data.enabled` | bool | `true` | Enable persistent volume storage for `/nexus-data` |
| `persistence.data.mountPath` | string | `"/nexus-data"` | Target directory inside container for persistent storage |
| `persistence.data.size` | string | `"100Gi"` | Persistent Volume size requested |
| `persistence.data.accessMode` | string | `"ReadWriteOnce"` | Storage volume access mode |
| `persistence.data.storageClass` | string | `undefined` | Optional StorageClass name for PVC dynamic provisioning |
| `securityContext.container.runAsUser` | int | `200` | Unprivileged UID to run container process |
| `securityContext.container.runAsGroup` | int | `200` | Unprivileged primary GID to run container process |
| `securityContext.container.readOnlyRootFilesystem` | bool | `true` | Mount root filesystem as read-only |
| `securityContext.container.allowPrivilegeEscalation` | bool | `false` | Prevent container process from gaining extra privileges |
| `securityContext.container.runAsNonRoot` | bool | `true` | Validate that container does not run as root |
| `securityContext.pod.fsGroup` | int | `200` | Supplemental group for volume ownership |
| `securityContext.pod.fsGroupChangePolicy` | string | `"OnRootMismatch"` | Policy for changing volume ownership and permissions |
| `securityContext.pod.supplementalGroups` | list | `[568]` | Additional supplemental groups for the pod |
| `resources.requests.cpu` | string | `"75m"` | CPU request for the Nexus container |
| `resources.requests.memory` | string | `"200Mi"` | Memory request for the Nexus container |
| `resources.limits.cpu` | string | `"1500m"` | CPU limit for the Nexus container |
| `resources.limits.memory` | string | `"2400Mi"` | Memory limit for the Nexus container |
| `workload.main.podSpec.containers.main.env.INSTALL4J_ADD_VM_PARAMS` | string | `"-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"` | Nexus JVM memory and path arguments |
| `gatewayAPI.enabled` | bool | `true` | Enable Gateway API HTTPRoute resource generation |
| `gatewayAPI.gatewayClassName` | string | `""` | Optional GatewayClass name |
| `gatewayAPI.httpRoutes` | list | `[...]` | List of HTTPRoute configurations with parentRefs, hostnames, and rules |
| `nodeSelector` | object | `{"kubernetes.io/arch": "amd64"}` | Node selector constraints |
| `terminationGracePeriodSeconds` | int | `60` | Grace period in seconds for graceful pod termination |

## Recommended values

Nexus OSS workloads operate as dedicated unprivileged system users (`200:200`), with read-only root filesystems, dropping all Linux kernel capabilities (`drop: ["ALL"]`), and with `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	securityContext: {
		pod: {
			runAsNonRoot: true
			fsGroup:      200
			fsGroupChangePolicy: "OnRootMismatch"
			supplementalGroups: [568]
		}
		container: {
			allowPrivilegeEscalation: false
			privileged:               false
			readOnlyRootFilesystem:   true
			runAsNonRoot:             true
			runAsUser:                200
			runAsGroup:               200
			seccompProfile: {
				type: "RuntimeDefault"
			}
			capabilities: {
				drop: ["ALL"]
			}
		}
	}
}
```

## Additional Resources
- [Official Sonatype Nexus Website](https://www.sonatype.com/products/sonatype-nexus-repository)
- [Official Nexus Public Repository](https://github.com/sonatype/nexus-public)
- [Sonatype Nexus Documentation](https://help.sonatype.com/repomanager3)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Nexus OSS module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Nexus Repository Manager (`nexus-oss`) | Deployment | 12 points | ✅ |
