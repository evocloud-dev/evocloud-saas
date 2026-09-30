# Readeck

## Description
[Readeck](https://readeck.org/) is a self-hosted read-it-later and bookmarking tool designed for reading without distractions. It strips web pages of ads and clutter to extract and archive articles, bookmarks, and images for easy reading and reference.

## Application Information
- **Version:** 0.23.2
- **Official Website:** [https://readeck.org/](https://readeck.org/)
- **Upstream Project:** [https://codeberg.org/readeck/readeck](https://codeberg.org/readeck/readeck)
- **Container Base:** [codeberg.org/readeck/readeck](https://codeberg.org/readeck/readeck) (`codeberg.org/readeck/readeck:0.23.2`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Readeck Core Application (`read`):** Lightweight web application server running `codeberg.org/readeck/readeck:0.23.2` on container port 8000. Configured with a read-only root filesystem, dropped kernel capabilities (`ALL`), and running as non-root user UID `1000`.
- **Kubernetes Service (`svc`):** ClusterIP Service routing incoming traffic on port 8000 for internal access and reverse proxy integration.
- **Persistent Data Storage (`pvc`):** PersistentVolumeClaim (`100Mi`, ReadWriteOnce) mounted to `/readeck` for storing SQLite database files, bookmarks, article extracts, and cached media.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply readeck ./readeck-timoni
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		data: {
			size: "5Gi"
		}
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

Apply the values to the instance:

```shell
timoni -n default apply readeck ./readeck-timoni \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete readeck
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `codeberg.org/readeck/readeck` | Container image repository |
| `image.tag` | string | `0.23.2` | Container image tag |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `resources.requests.cpu` | string | `200m` | Minimum CPU requested |
| `resources.requests.memory` | string | `256Mi` | Minimum memory requested |
| `resources.limits.cpu` | string | `500m` | Maximum CPU limit |
| `resources.limits.memory` | string | `512Mi` | Maximum memory limit |
| `service.main.ports.http.port` | int | `8000` | Service HTTP port |
| `ingress.main.enabled` | bool | `false` | Enable ingress routing |
| `persistence.data.enabled` | bool | `true` | Enable persistent storage for data |
| `persistence.data.mountPath` | string | `/readeck` | Mount path for data directory |
| `persistence.data.accessMode` | string | `ReadWriteOnce` | Persistent volume access mode |
| `persistence.data.size` | string | `100Mi` | Persistent volume storage size |
| `securityContext.runAsUser` | int | `1000` | Container user ID |
| `securityContext.runAsGroup` | int | `1000` | Container group ID |
| `securityContext.fsGroup` | int | `1000` | Pod filesystem group ID |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce running as a non-root user |
| `securityContext.readOnlyRootFilesystem` | bool | `true` | Mount container root filesystem as read-only |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Drop all Linux kernel capabilities |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	securityContext: {
		runAsUser:              1000
		runAsGroup:             1000
		fsGroup:                1000
		runAsNonRoot:           true
		readOnlyRootFilesystem: true
		capabilities: drop: [
			"ALL",
		]
	}
}
```

## Additional Resources
- [Official Readeck Website](https://readeck.org/)
- [Official Readeck Repository](https://codeberg.org/readeck/readeck)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Readeck module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Readeck Core (`read`) | Deployment | 11 points | ✅ |
