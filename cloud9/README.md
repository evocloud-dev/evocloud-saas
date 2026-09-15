# Cloud9

## Description
[Cloud9](https://github.com/c9/core) is an open-source, web-based Integrated Development Environment (IDE) that provides a complete, modern development environment with syntax highlighting, code auto-completion, split-view editing, interactive terminal access, and revision history directly in your browser. Powered by LinuxServer.io's optimized container packaging, this Timoni module delivers a cloud-native, production-ready Cloud9 deployment with persistent workspace storage and Kubernetes Gateway API integration.

## Application Information
- **Version**: `1.29.2`
- **Upstream Project**: [https://github.com/c9/core](https://github.com/c9/core)
- **Container Base**: [https://github.com/linuxserver/docker-cloud9](https://github.com/linuxserver/docker-cloud9) (`ghcr.io/linuxserver/cloud9`)
- **Deployment Type**: Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Cloud9 IDE Core (`cloud9`)**: The web IDE application container running `ghcr.io/linuxserver/cloud9:version-1.29.2` on container port `8000`. Managed internally by `s6-overlay`, it drops root privileges to run the Node.js IDE runtime as unprivileged user `abc` (`568:568`).
- **Kubernetes Service (`cloud9`)**: `ClusterIP` service exposing port `10070` (mapped to container port `8000`) for cluster-internal access and ingress routing.
- **Persistent Workspace Storage (`cloud9-code`)**: `PersistentVolumeClaim` (default `100Gi`, `ReadWriteOnce`) mounted to `/code` to preserve repositories, projects, packages, and workspace configuration across pod restarts.
- **Gateway API HTTPRoute (`route`)**: Native `gateway.networking.k8s.io/v1` HTTPRoute resource enabling routing through Envoy Gateway, Traefik, Cilium, or other Gateway API controllers.

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway) if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply humhub oci://<container-registry-url>
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	route: {
		enabled: true
		parentRefs: [{
			name:      "shared-gtw"
			namespace: "kube-system"
		}]
		hostnames: [
			"c9.example.com",
		]
	}
	resources: {
		requests: {
			cpu:    "100m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "2000m"
			memory: "4096Mi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply humhub oci://<container-registry-url> \
--values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete cloud9
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | `string` | `ghcr.io/linuxserver/cloud9` | Container image repository |
| `image.tag` | `string` | `version-1.29.2@sha256:45c5fe102ff3390bcd4ea58db99023b7ea099a8462f5727973ec329bd4a8d6b4` | Pinned container image tag and digest |
| `image.pullPolicy` | `string` | `IfNotPresent` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `securityContext.container.runAsUser` | `int` | `0` | Container startup user ID (required by `s6-overlay`) |
| `securityContext.container.runAsGroup` | `int` | `0` | Container startup group ID |
| `securityContext.container.runAsNonRoot` | `bool` | `false` | Must be `false` for `s6-overlay` to initialize permissions |
| `securityContext.container.readOnlyRootFilesystem` | `bool` | `false` | Root filesystem read-write setting |
| `securityContext.container.allowPrivilegeEscalation` | `bool` | `false` | Disallows container privilege escalation |
| `securityContext.container.seccompProfile.type` | `string` | `RuntimeDefault` | Seccomp profile for container isolation |
| `service.main.ports.main.port` | `int` | `10070` | Service port exposed within the cluster |
| `service.main.ports.main.targetPort` | `int` | `8000` | Cloud9 backend container port |
| `service.main.ports.main.protocol` | `string` | `http` | Service port protocol |
| `workload.main.replicas` | `int` | `1` | Number of replica pods |
| `workload.main.revisionHistoryLimit` | `int` | `3` | Number of deployment revisions to retain |
| `workload.main.podSpec.containers.main.probes.liveness` | `object` | HTTP GET `/` on port `8000` | Liveness probe configuration |
| `workload.main.podSpec.containers.main.probes.readiness` | `object` | HTTP GET `/` on port `8000` | Readiness probe configuration |
| `workload.main.podSpec.containers.main.probes.startup` | `object` | HTTP GET `/` on port `8000` | Startup probe configuration |
| `persistence.code.enabled` | `bool` | `true` | Enable persistent storage for `/code` workspace |
| `persistence.code.mountPath` | `string` | `/code` | Filesystem path mounted inside the container |
| `persistence.code.size` | `string` | `100Gi` | PersistentVolumeClaim requested storage capacity |
| `persistence.code.accessMode` | `string` | `ReadWriteOnce` | Persistent volume access mode |
| `route.enabled` | `bool` | `false` | Create a Gateway API HTTPRoute resource |
| `route.parentRefs` | `list` | `[{name: "shared-gtw", namespace: "kube-system"}]` | Gateway reference(s) to attach the route to |
| `route.hostnames` | `list` | `[]` | Optional domain hostnames matching inbound requests |
| `route.path` | `string` | `/` | Inbound URL path match value |
| `route.pathType` | `string` | `PathPrefix` | URL path match type (`PathPrefix` or `Exact`) |
| `route.annotations` | `map` | `{}` | Annotations applied to the HTTPRoute resource |
| `resources.requests.cpu` | `string` | `75m` | Container requested CPU capacity |
| `resources.requests.memory` | `string` | `200Mi` | Container requested memory capacity |
| `resources.limits.cpu` | `string` | `1500m` | Container maximum CPU limit |
| `resources.limits.memory` | `string` | `2400Mi` | Container maximum memory limit |

#### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:  65532
		runAsGroup: 65532
		fsGroup:    65532
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}
}
```

## Additional Resources
- [Official Cloud9 Core Repository](https://github.com/c9/core)
- [LinuxServer.io Cloud9 Documentation](https://docs.linuxserver.io/images/docker-cloud9/)
- [Timoni Documentation](https://timoni.sh)

### Kubesec Scan Scores
Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Cloud9 module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|:---:|:---:|
| **Cloud9 IDE (`cloud9`)** | `Deployment` | **10 / 10** | **✅** |
