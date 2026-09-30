# openHAB

## Description
[openHAB](https://www.openhab.org/) is a vendor-neutral, open-source smart home automation platform designed to integrate diverse home automation devices, protocols, and technologies into a single unified system with local data sovereignty and flexible automation rule engines.

## Application Information
- **Version:** 0.1.0 (App: 5.2.1)
- **Upstream Project:** [https://github.com/openhab/openhab-distro](https://github.com/openhab/openhab-distro)
- **Container Base:** [docker.io/openhab/openhab](https://hub.docker.com/r/openhab/openhab) (`docker.io/openhab/openhab:5.2.1`), [docker.io/library/busybox](https://hub.docker.com/_/busybox) (`docker.io/library/busybox:1.37`), [docker.io/library/alpine](https://hub.docker.com/_/alpine) (`docker.io/library/alpine:3.22`), [docker.io/helmforge/mc](https://hub.docker.com/r/helmforge/mc) (`docker.io/helmforge/mc:1.0.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **openHAB Core (`openhab`):** Primary home automation controller StatefulSet running the OSGi Java runtime on port 8080 (HTTP) and optional 8443 (HTTPS).
- **Apache Karaf SSH Console (`openhab-karaf`):** Built-in administrative shell service on port 8101 for OSGi bundle management, diagnostics, and debugging.
- **Persistent Storage:** Dedicated PersistentVolumeClaims for runtime state (`openhab-userdata`, 5Gi), configuration files (`openhab-conf`, 1Gi), and drop-in addons (`openhab-addons`, 2Gi).
- **ConfigMap Provisioning:** Automated init container syncing items, things, and sitemaps configuration into the conf volume before main container startup.
- **Gateway API HTTPRoute (`httproute`):** Optional `gateway.networking.k8s.io/v1` HTTPRoute resource for modern cluster ingress routing.
- **ServiceAccount & RBAC (`serviceAccount`):** Dedicated Kubernetes ServiceAccount configured with `automountServiceAccountToken: false`.
- **Observability & Metrics:** Optional Prometheus metrics scraping annotations and Prometheus Operator ServiceMonitor.
- **Automated Backup CronJob (`backup`):** Optional scheduled CronJob creating compressed tar archives of userdata and conf directories for upload to S3-compatible object storage.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting ReadWriteOnce persistent volumes
- Gateway controller (e.g. Envoy Gateway, Cilium) if Gateway API routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply openhab ./openhab
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	env: {
		TZ: "Europe/Berlin"
	}
	gateway: {
		enabled:   true
		hostnames: ["openhab.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply openhab ./openhab \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete openhab
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the chart name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `image.repository` | string | `"docker.io/openhab/openhab"` | openHAB container image repository |
| `image.tag` | string | `"5.2.1"` | openHAB container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `replicaCount` | int | `1` | Number of replicas (**MUST** remain 1; openHAB does not support horizontal scaling) |
| `serviceAccount.create` | bool | `true` | Create dedicated ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | bool | `false` | Mount API credentials into the pod |
| `podSecurityContext.fsGroup` | int | `9001` | Group ID used for mounted storage volumes |
| `podSecurityContext.seccompProfile.type` | string | `"RuntimeDefault"` | Pod-level seccomp profile |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `securityContext.readOnlyRootFilesystem` | bool | `false` | Read-only root filesystem setting (openHAB requires write access to internal runtime paths) |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | int | `8080` | HTTP port exposed by openHAB Service |
| `karaf.enabled` | bool | `true` | Enable Apache Karaf SSH console Service |
| `karaf.service.port` | int | `8101` | SSH port for Karaf administration |
| `persistence.userdata.enabled` | bool | `true` | Enable persistent storage for runtime state, JSONDB, and persistence files |
| `persistence.userdata.size` | string | `"5Gi"` | Persistent Volume size requested for userdata |
| `persistence.conf.enabled` | bool | `true` | Enable persistent storage for configuration files |
| `persistence.conf.size` | string | `"1Gi"` | Persistent Volume size requested for conf |
| `persistence.addons.enabled` | bool | `true` | Enable persistent storage for custom drop-in addons |
| `persistence.addons.size` | string | `"2Gi"` | Persistent Volume size requested for addons |
| `resources.requests.cpu` | string | `"500m"` | CPU request for openHAB container |
| `resources.requests.memory` | string | `"512Mi"` | Memory request for openHAB container |
| `resources.limits.cpu` | string | `"2000m"` | CPU limit for openHAB container |
| `resources.limits.memory` | string | `"2Gi"` | Memory limit for openHAB container |
| `env.TZ` | string | `"UTC"` | Container timezone |
| `env.EXTRA_JAVA_OPTS` | string | `""` | Extra JVM options (e.g. `-Xms512m -Xmx1g`) |
| `gateway.enabled` | bool | `false` | Enable Kubernetes Gateway API HTTPRoute creation |
| `gateway.hostnames` | list | `["openhab.local"]` | Hostnames associated with the HTTPRoute |
| `metrics.enabled` | bool | `false` | Enable Prometheus metrics support |
| `backup.enabled` | bool | `false` | Enable automated backup CronJob to S3-compatible storage |
| `backup.schedule` | string | `"0 3 * * *"` | Backup CronJob schedule |

## Recommended values

The openHAB container image entrypoint starts under root privileges to configure group/user ownership (`9001:9001`) and ensure permissions on mounted volumes, before dropping privileges to the unprivileged `openhab` user (`gosu openhab`). The pod configures `fsGroup: 9001` and a `RuntimeDefault` seccomp profile:

```cue
values: {
	podSecurityContext: {
		fsGroup: 9001
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
	}
}
```

## Additional Resources
- [Official openHAB Website](https://www.openhab.org/)
- [Official openHAB Community](https://community.openhab.org/)
- [openHAB Documentation](https://www.openhab.org/docs/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the openHAB module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| openHAB Core (`openhab`) | StatefulSet | 10 points | ✅ |
