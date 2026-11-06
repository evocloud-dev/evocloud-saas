# Hexo Blog

## Description
[Hexo](https://hexo.io/) is a fast, simple, and powerful blog framework powered by Node.js. It allows users to write posts in Markdown, generate static web pages with blazing speed, and support rich themes and plugins for modern, lightweight, self-hosted blogging.

## Application Information
- **Version:** 4.3.2
- **Upstream Project:** [https://github.com/fletchto99/hexo-dev-docker](https://github.com/fletchto99/hexo-dev-docker)
- **Container Base:** [docker.io/fletchto99/hexo-dev-blog](https://hub.docker.com/r/fletchto99/hexo-dev-blog) (`docker.io/fletchto99/hexo-dev-blog:4.3.2@sha256:0d35f27fa6c9330660591c539a558c865ed808bbc39a8eecf39b5324680153f5`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Hexo Dev Blog (`hexo-blog`):** Fast, simple Node.js-powered blogging platform running `docker.io/fletchto99/hexo-dev-blog:4.3.2` on container port 8080, exposed via ClusterIP Service on port 10306.
- **Gateway API HTTPRoute (`httproute`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource for modern ingress routing into the Hexo service.
- **Persistent Storage (`hexo-blog-config`):** Dedicated PersistentVolumeClaim mounted at `/config` providing persistent storage (`100Gi`, ReadWriteOnce) for blog posts, themes, configurations, and runtime state.
- **Memory-backed Ephemeral Mounts:** High-performance emptyDir memory volumes mounted at `/dev/shm`, `/tmp`, `/var/logs`, `/var/run`, and `/shared` (`2400Mi` sizeLimit).

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply hexo-blog ./hexo-blog
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		config: {
			size: "50Gi"
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
timoni -n default apply hexo-blog ./hexo-blog \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete hexo-blog
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"docker.io/fletchto99/hexo-dev-blog"` | Container image repository |
| `image.tag` | string | `"4.3.2@sha256:0d35f27fa6c9330660591c539a558c865ed808bbc39a8eecf39b5324680153f5"` | Container image tag and digest |
| `image.pullPolicy` | string | `"IfNotPresent"` | Container image pull policy |
| `replicas` | int | `1` | Number of pod replicas |
| `revisionHistoryLimit` | int | `3` | Number of revision history limits to retain |
| `strategy.type` | string | `"Recreate"` | Deployment update strategy |
| `service.main.type` | string | `"ClusterIP"` | Kubernetes Service type |
| `service.main.publishNotReadyAddresses` | bool | `false` | Whether to publish not ready addresses on Service |
| `service.main.ports.main.port` | int | `10306` | Port exposed by the Kubernetes Service |
| `service.main.ports.main.targetPort` | int | `8080` | Container port for Hexo HTTP interface |
| `service.main.ports.main.protocol` | string | `"http"` | Network protocol |
| `persistence.config.enabled` | bool | `true` | Enable persistent volume storage for `/config` |
| `persistence.config.mountPath` | string | `"/config"` | Target directory inside container for persistent storage |
| `persistence.config.size` | string | `"100Gi"` | Persistent Volume size requested |
| `persistence.config.accessMode` | string | `"ReadWriteOnce"` | Storage volume access mode |
| `persistence.config.storageClass` | string | `undefined` | Optional StorageClass name for PVC dynamic provisioning |
| `securityContext.container.runAsUser` | int | `0` | UID to run container process |
| `securityContext.container.runAsGroup` | int | `0` | Primary GID to run container process |
| `securityContext.container.readOnlyRootFilesystem` | bool | `false` | Mount root filesystem as read-only |
| `securityContext.container.allowPrivilegeEscalation` | bool | `false` | Prevent container process from gaining extra privileges |
| `securityContext.container.runAsNonRoot` | bool | `false` | Validate that container does not run as root |
| `podSecurityContext.fsGroup` | int | `568` | Supplemental group for volume ownership |
| `podSecurityContext.fsGroupChangePolicy` | string | `"OnRootMismatch"` | Policy for changing volume ownership and permissions |
| `podSecurityContext.supplementalGroups` | list | `[568]` | Additional supplemental groups for the pod |
| `resources.requests.cpu` | string | `"75m"` | CPU request for the Hexo container |
| `resources.requests.memory` | string | `"200Mi"` | Memory request for the Hexo container |
| `resources.limits.cpu` | string | `"1500m"` | CPU limit for the Hexo container |
| `resources.limits.memory` | string | `"2400Mi"` | Memory limit for the Hexo container |
| `workload.main.podSpec.containers.main.env.HEXO_PLUGINS` | string | `""` | Optional space-separated Hexo plugins to install |
| `workload.main.podSpec.containers.main.env.TZ` | string | `"UTC"` | Timezone setting for the application |
| `workload.main.podSpec.containers.main.env.PUID` | string | `"568"` | User ID mapping for file permissions |
| `workload.main.podSpec.containers.main.env.PGID` | string | `"568"` | Group ID mapping for file permissions |
| `gatewayAPI.enabled` | bool | `false` | Enable Gateway API HTTPRoute resource generation |
| `gatewayAPI.gatewayClassName` | string | `""` | Optional GatewayClass name |
| `gatewayAPI.httpRoutes` | list | `[]` | List of HTTPRoute configurations with parentRefs, hostnames, and rules |
| `nodeSelector` | object | `{"kubernetes.io/arch": "amd64"}` | Node selector constraints |
| `terminationGracePeriodSeconds` | int | `60` | Grace period in seconds for graceful pod termination |

## Recommended values

Hexo Blog requires superuser privileges (`0:0`) initially to perform setup and manage files under `/config`, with a writable root filesystem, retaining specific Linux capabilities (`CHOWN`, `SETUID`, `SETGID`, `FOWNER`, `DAC_OVERRIDE`), and running under `seccompProfile: RuntimeDefault`:

```cue
values: {
	securityContext: {
		container: {
			allowPrivilegeEscalation: false
			privileged:               false
			readOnlyRootFilesystem:   false
			runAsNonRoot:             false
			runAsUser:                0
			runAsGroup:               0
			seccompProfile: {
				type: "RuntimeDefault"
			}
			capabilities: {
				add: [
					"CHOWN",
					"SETUID",
					"SETGID",
					"FOWNER",
					"DAC_OVERRIDE",
				]
				drop: [
					"ALL",
				]
			}
		}
	}
}
```

## Additional Resources
- [Official Hexo Website](https://hexo.io)
- [Hexo Dev Docker GitHub](https://github.com/fletchto99/hexo-dev-docker)
- [Hexo Documentation](https://hexo.io/docs/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Hexo Blog module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Hexo Dev Blog (`hexo-blog`) | Deployment | 10 points | ✅ |
