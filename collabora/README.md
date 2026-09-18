# Collabora

## Description
[Collabora Online](https://github.com/CollaboraOnline/online) (CODE - Collabora Online Development Edition) is a powerful, open-source, web-based office suite that provides real-time collaborative document editing directly in your web browser. Built on the upstream Collabora Online architecture, this Timoni module delivers a cloud-native, production-ready Collabora deployment with Kubernetes Secret credentials management, in-memory RAM disk sandboxing, secure non-root operation, and Kubernetes Gateway API integration.

## Application Information
- **Version:** 26.04.4.1.1
- **Upstream Project:** [https://github.com/CollaboraOnline/online](https://github.com/CollaboraOnline/online)
- **Container Base:** [docker.io/collabora/code](https://hub.docker.com/r/collabora/code) (`docker.io/collabora/code:26.04.4.1.1@sha256:1efda3043e8b9cb437d1b6c6efe20cc3753760e634de012b8dac391da488bf97`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Collabora Online Core (`collabora`):** The web-based document editing and rendering engine container running `docker.io/collabora/code:26.04.4.1.1` on container port 9980. Operates as dedicated unprivileged system user `cool` (`1001`), dropping all kernel capabilities (`ALL`), with `allowPrivilegeEscalation: false`, `seccompProfile: RuntimeDefault`, and `--o:mount_jail_tree=false` to achieve full non-root isolation and a 11/11 Kubesec score without requiring node-level DaemonSets.
- **Kubernetes Secret (`collabora`):** Securely stores the administrator username and password, mapped to container environment variables via `secretKeyRef` (mirroring upstream security architecture).
- **ConfigMap (`collabora`):** Stores Collabora server configuration parameters, spellcheck dictionaries, and WOPI client URL whitelist (`aliasgroups`).
- **Kubernetes Service (`collabora`):** ClusterIP service exposing port 9980 (named `http`) for cluster-internal access and ingress/gateway routing.
- **Gateway API HTTPRoute (`route`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource enabling modern ingress routing through Envoy Gateway, Traefik, Cilium, or other Gateway API controllers.
- **Kubernetes Ingress (`ingress`):** Standard `networking.k8s.io/v1` Ingress resource supporting NGINX, Traefik, HAProxy, and custom ingress controllers.
- **HorizontalPodAutoscaler (`autoscaling`):** Scales document worker replicas dynamically based on CPU/memory load.
- **PodDisruptionBudget (`podDisruptionBudget`):** Guarantees high availability and minimum document editing capacity during voluntary node disruptions and upgrades.
- **NetworkPolicy (`networkPolicy`):** Enforces network-level segmentation and isolates Collabora container traffic within the cluster.

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway) if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply collabora ./collabora
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	collabora: {
		username:    "myadmin"
		password:    "mysecretpassword"
		server_name: "office.example.com"
		aliasgroups: [
			{
				host: "https://cloud.example.com"
			},
		]
	}
	route: {
		enabled: true
		parentRefs: [{
			name:      "shared-gtw"
			namespace: "kube-system"
		}]
		hostnames: [
			"office.example.com",
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
timoni -n default apply collabora ./collabora \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete collabora
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/collabora/code` | Container image repository |
| `image.tag` | string | `26.04.4.1.1` | Pinned container image tag |
| `image.digest` | string | `sha256:1efda3043e8b9cb437d1b6c6efe20cc3753760e634de012b8dac391da488bf97` | Pinned container image digest |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `collabora.username` | string | `admin` | Collabora administrator username (stored in Secret) |
| `collabora.password` | string | `changeme` | Collabora administrator password (stored in Secret) |
| `collabora.server_name` | string | `example.com` | Public hostname or domain of the Collabora service |
| `collabora.aliasgroup1` | string | `https://cloud.example.com` | Primary WOPI host URL (TrueCharts addition) |
| `collabora.dictionaries` | list | `["de_DE", ...]` | Multilingual spellchecking dictionaries (TrueCharts addition) |
| `collabora.interface` | string | `default` | UI mode (`default`, `compact`, `tabbed`) |
| `collabora.extra_params` | string | `--o:ssl.enable=false ... --o:mount_jail_tree=false ...` | Tuned coolwsd daemon flags |
| `securityContext.privileged` | bool | `false` | Unprivileged container mode |
| `securityContext.runAsNonRoot` | bool | `true` | Enforces running as a non-root user |
| `securityContext.runAsUser` | int | `1001` | Runs as dedicated `cool` system user |
| `securityContext.readOnlyRootFilesystem` | bool | `false` | Document runtime conversion filesystem access |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Disables privilege escalation (achieves Kubesec score 11/11) |
| `securityContext.seccompProfile.type` | string | `RuntimeDefault` | Standard container runtime seccomp profile |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Drops all Linux capabilities |
| `podSecurityContext.fsGroup` | int | `1001` | Filesystem group matching `cool` user |
| `podSecurityContext.fsGroupChangePolicy` | string | `OnRootMismatch` | Optimizes volume permission checks on pod start |
| `podSecurityContext.seccompProfile.type` | string | `RuntimeDefault` | Pod-level runtime default seccomp profile |
| `installCOOLSeccompProfile` | bool | `false` | Host seccomp DaemonSet (not required with mount_jail_tree=false) |
| `service.port` | int | `9980` | Service port exposed within the cluster |
| `service.type` | string | `ClusterIP` | Kubernetes service type |
| `resources.requests.cpu` | string | `75m` | Container requested CPU capacity |
| `resources.requests.memory` | string | `200Mi` | Container requested memory capacity |
| `resources.limits.cpu` | string | `1500m` | Container maximum CPU limit |
| `resources.limits.memory` | string | `2400Mi` | Container maximum memory limit |
| `route.enabled` | bool | `true` | Create a Gateway API HTTPRoute resource |
| `route.parentRefs` | list | `[{name: "shared-gtw", namespace: "kube-system"}]` | Gateway reference(s) to attach the route to |
| `route.hostnames` | list | `[]` | Optional domain hostnames matching inbound requests |
| `route.path` | string | `/` | Inbound URL path match value |
| `route.pathType` | string | `PathPrefix` | URL path match type (`PathPrefix` or `Exact`) |
| `route.annotations` | map | `{}` | Annotations applied to the HTTPRoute resource |
| `ingress.enabled` | bool | `false` | Create a standard Kubernetes Ingress resource |
| `ingress.className` | string | `""` | Ingress class name (e.g. `nginx`, `traefik`) |
| `ingress.hosts` | list | `[]` | Ingress host match rules |
| `autoscaling.enabled` | bool | `true` | Create a HorizontalPodAutoscaler (HPA) resource |
| `autoscaling.minReplicas` | int | `2` | Minimum replica count for autoscaling |
| `autoscaling.maxReplicas` | int | `3` | Maximum replica count for autoscaling |
| `podDisruptionBudget.enabled` | bool | `true` | Create a PodDisruptionBudget (PDB) resource |
| `networkPolicy.enabled` | bool | `false` | Enforce Kubernetes NetworkPolicy ingress/egress isolation |
| `serviceAccount.create` | bool | `true` | Create a dedicated ServiceAccount for Collabora |
| `prometheus.servicemonitor.enabled` | bool | `false` | Create a Prometheus Operator ServiceMonitor for `/cool/getMetrics` |
| `deployment.customFonts.enabled` | bool | `false` | Mount PVC for custom typography & fonts |
| `nginxDeny.enabled` | bool | `false` | Deploy secondary Nginx pod blocking sensitive endpoints |
| `reverseProxy.enabled` | bool | `false` | Deploy WOPISrc hash sticky reverse proxy for multi-replica |

## Recommended values

Collabora Online operates as dedicated unprivileged system user `cool` (`1001`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`. When paired with `--o:mount_jail_tree=false` in `collabora.extra_params`, Collabora uses file copy/link isolation instead of Linux mount namespaces, eliminating the need for elevated permissions and passing all Kubesec checks with an unpenalized **11/11 score**:

```cue
values: {
	podSecurityContext: {
		fsGroup:             1001
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		readOnlyRootFilesystem:   false
		privileged:               false
		capabilities: {
			drop: [
				"ALL",
			]
		}
		runAsNonRoot:             true
		runAsUser:                1001
		allowPrivilegeEscalation: false
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
}
```

## Additional Resources
- [Official Collabora Online Repository](https://github.com/CollaboraOnline/online)
- [Official Collabora Online Documentation & Admin Console Guide](https://sdk.collaboraonline.com/docs/advanced_integration.html#admin-console)
- [Collabora Online WOPI Protocol Specification](https://sdk.collaboraonline.com/docs/installation/Configuration.html#wopi)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Collabora module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Collabora Online (`collabora`) | Deployment | 11 / 11 | ✅  |
