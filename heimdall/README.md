# Heimdall

## Description

[Heimdall Application Dashboard](https://heimdall.site/) is an elegant and customizable dashboard solution for organizing and accessing all your web applications, links, and services from a single interface.

## Application Information

- **Version:** 2.8.3
- **Official Website:** [https://heimdall.site/](https://heimdall.site/)
- **Upstream Project:** [https://github.com/linuxserver/Heimdall](https://github.com/linuxserver/Heimdall)
- **Container Base:** [docker.io/linuxserver/heimdall](https://hub.docker.com/r/linuxserver/heimdall) (`docker.io/linuxserver/heimdall:2.8.3`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Heimdall Web Application (`heimdall`):** Core dashboard engine serving web interface, background icon fetchers, and user configurations on port `80`.
- **Deployment (`heimdall`):** Single-replica workload configured with `Recreate` deployment strategy to protect SQLite database and configuration volume integrity.
- **Service (`heimdall`):** Kubernetes `ClusterIP` Service exposing the Heimdall HTTP listener on port `80`.
- **PersistentVolumeClaim (`heimdall`):** Dedicated persistent volume claim for `/config` storing application database, uploaded icons, user preferences, and app keys.
- **ServiceAccount (`heimdall`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **S3 Backup CronJob (`heimdall-backup`):** Optional automated S3-compatible snapshot archiver for `/config`.

## Prerequisites

- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Storage provisioner supporting `ReadWriteOnce` persistent volumes

## Install

To create an instance using default values:

```bash
timoni -n default apply heimdall ./heimdall
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		size:         "2Gi"
		storageClass: "local-path"
	}
	resources: {
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
	}
}
```

Apply the custom values to the instance:

```bash
timoni -n default apply heimdall ./heimdall \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```bash
timoni -n default delete heimdall
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the chart name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the complete resource name |
| `commonLabels` | `object` | `{}` | Extra resource labels |
| `image.repository` | `string` | `"docker.io/linuxserver/heimdall"` | Container image repository |
| `image.tag` | `string` | `"2.8.3"` | Container image tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `heimdall.puid` | `int` | `1000` | User ID for file permissions in `/config` |
| `heimdall.pgid` | `int` | `1000` | Group ID for file permissions in `/config` |
| `heimdall.timezone` | `string` | `"UTC"` | Timezone configuration |
| `heimdall.extraEnv` | `list` | `[]` | Extra environment variables |
| `persistence.enabled` | `bool` | `true` | Enable persistent storage for `/config` |
| `persistence.size` | `string` | `"1Gi"` | PVC storage capacity |
| `persistence.storageClass` | `string` | `""` | StorageClass name (empty for cluster default) |
| `resources.requests.cpu` | `string` | `"50m"` | CPU request limit |
| `resources.requests.memory` | `string` | `"128Mi"` | Memory request limit |
| `resources.limits.cpu` | `string` | `"500m"` | CPU limit |
| `resources.limits.memory` | `string` | `"256Mi"` | Memory limit |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `80` | Service HTTP port |
| `serviceAccount.create` | `bool` | `true` | Create dedicated ServiceAccount |
| `podSecurityContext` | `corev1.#PodSecurityContext` | `{}` | [Kubernetes pod security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context) |
| `securityContext` | `corev1.#SecurityContext` | `{}` | [Kubernetes container security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context) |

### Recommended values

Heimdall operates with dropped Linux capabilities, disallowed privilege escalation, and a default seccomp profile, while providing the minimal POSIX capabilities required by the internal initialization process:

```cue
values: {
	podSecurityContext: {
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: [
				"ALL",
			]
			add: [
				"CHOWN",
				"SETUID",
				"SETGID",
				"FOWNER",
				"DAC_OVERRIDE",
			]
		}
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
}
```

---

## Additional Resources

- [Official Heimdall Website](https://heimdall.site/)
- [Official Heimdall Repository](https://github.com/linuxserver/Heimdall)
- [LinuxServer.io Heimdall Image Documentation](https://docs.linuxserver.io/images/docker-heimdall/)
- [Timoni Documentation](https://timoni.sh)

---

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Heimdall module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|:---:|:---:|
| **Heimdall Workload (`heimdall-heimdall`)** | `Deployment` | **11 points** | ✅ |
