# Ghost

## Description
[Ghost](https://ghost.org/) is a modern, open-source publishing platform built on Node.js designed for professional bloggers, online publications, independent journalists, and content creators. It features a rich editor, built-in member management, subscription payments, automated newsletter distribution, and SEO optimization.

## Application Information
- **Version:** 6.62.0
- **Upstream Project:** [https://github.com/TryGhost/Ghost](https://github.com/TryGhost/Ghost) / [https://ghost.org/](https://ghost.org/)
- **Container Base:** [docker.io/library/ghost](https://hub.docker.com/_/ghost) (`docker.io/library/ghost:6.62.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Ghost Core Application (`deployment`):** Node.js web and publishing application server running `docker.io/library/ghost:6.62.0` on container port 2368, mounting persistent volume storage for media uploads, themes, and configuration assets.
- **MySQL Database Subchart (`mysql`):** Dedicated relational database server (`docker.io/library/mysql:8.4.10`) on port 3306 with persistent volume storage (`8Gi`).
- **Persistent Storage Volumes (`pvc`):** Persistent volume storage (`10Gi`, ReadWriteOnce) mounted to `/var/lib/ghost/content` preserving uploaded images, active themes, and content data across pod restarts.
- **Kubernetes Service (`service`):** ClusterIP service exposing port 80 (named `http`, routing internally to container port 2368).
- **Gateway API HTTPRoute (`gateway`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource enabling modern ingress traffic routing through Envoy Gateway, Traefik, Cilium, or other Gateway API controllers.
- **Database Backup CronJob (`backup`):** Optional scheduled CronJob performing automated database backups uploaded to S3-compatible object storage via MinIO Client (`docker.io/helmforge/mc:1.0.0`).
- **External Secrets Operator (`externalSecrets`):** Optional ExternalSecret resource syncing database passwords from external secret stores (Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault).
- **ServiceAccount (`serviceAccount`):** Dedicated unprivileged Kubernetes ServiceAccount applied across Ghost module workloads.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Persistent storage provisioner (e.g. Ceph, OpenEBS, hostpath) supporting dynamic volume provisioning
- Ingress controller or Gateway API controller if external traffic routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply ghost ./ghost
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	ghost: {
		url: "https://blog.example.com"
	}
	database: external: {
		host: "mysql.example.com"
		name: "ghost"
		username: "ghost"
	}
	mysql: enabled: false
}
```

Apply the values to the instance:

```shell
timoni -n default apply ghost ./ghost \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete ghost
```

## Configuration

### Key Configuration Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"docker.io/library/ghost"` | Ghost container image repository |
| `image.tag` | string | `"6.62.0"` | Ghost container image tag |
| `ghost.url` | string | `"http://localhost:8080"` | Public canonical base URL for Ghost |
| `persistence.enabled` | bool | `true` | Enable persistent storage for content assets |
| `persistence.size` | string | `"10Gi"` | Storage size requested for Ghost content volume |
| `service.port` | int | `80` | Internal ClusterIP service port for Ghost |
| `mysql.enabled` | bool | `true` | Deploy internal dedicated MySQL StatefulSet |
| `mysql.image.tag` | string | `"8.4.10"` | MySQL container image tag |
| `mysql.standalone.persistence.size` | string | `"8Gi"` | Persistent storage size for MySQL database |
| `backup.enabled` | bool | `false` | Enable scheduled automated database backups |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress routing |
| `gateway.enabled` | bool | `true` | Enable Gateway API HTTPRoute routing |

## Recommended values

Ghost workloads enforce restricted security contexts by running as non-root users with dropped Linux capabilities and unprivileged service accounts:

```cue
values: {
	podSecurityContext: {
		seccompProfile: type: "RuntimeDefault"
		runAsUser:    10001
		runAsGroup:   10001
		fsGroup:      10001
	}
	securityContext: {
		readOnlyRootFilesystem:   true
		allowPrivilegeEscalation: false
		privileged:               false
		runAsNonRoot:             true
		runAsUser:                10001
		runAsGroup:               10001
		capabilities: drop: ["ALL"]
	}
	mysql: {
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: {
				drop: ["ALL"]
				add: ["SETGID", "SETUID", "CHOWN"]
			}
		}
		podSecurityContext: {
			runAsUser:      999
			runAsGroup:     999
			seccompProfile: type: "RuntimeDefault"
		}
	}
}
```

## Additional Resources
- [Official Ghost Website](https://ghost.org/)
- [Official Ghost Repository](https://github.com/TryGhost/Ghost)
- [Ghost Documentation](https://ghost.org/docs/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Ghost module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Ghost Core Application (`ghost`) | Deployment | 14 points | ✅ |
| MySQL Database (`ghost-mysql`) | StatefulSet | 12 points | ✅ |
