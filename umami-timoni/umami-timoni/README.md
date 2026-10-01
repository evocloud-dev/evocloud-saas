# Umami

## Description
[Umami](https://umami.is/) is an open-source, privacy-preserving web analytics solution designed as an independent alternative to Google Analytics. It tracks page views, unique visitors, bounce rates, traffic sources, client devices, and custom event goals without collecting personal data, using cookies, or tracking users across websites, ensuring default compliance with GDPR, CCPA, and PECR.

## Application Information
- **Version:** `3.3.1`
- **Official Website:** [https://umami.is/](https://umami.is/)
- **Upstream Project:** [https://github.com/umami-software/umami](https://github.com/umami-software/umami)
- **Container Base:**
  - Umami Application: [ghcr.io/umami-software/umami](https://github.com/umami-software/umami/pkgs/container/umami) (`ghcr.io/umami-software/umami:3.3.1`)
  - PostgreSQL Database: `bitnamilegacy/postgresql` (`bitnamilegacy/postgresql:14`)
  - MySQL Database (Optional): `bitnamilegacy/mysql` (`bitnamilegacy/mysql:8.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Umami Core Application (`umami`):** Deployment (`Deployment/umami`) running the web analytics tracking endpoint and administrative analytics dashboard on container port 3000.
- **PostgreSQL Database (`umami-postgresql`):** StatefulSet (`StatefulSet/umami-postgresql`) providing relational persistence for tracking events, websites, user accounts, and session data with persistent volume storage (`8Gi`).
- **Umami Service (`umami`):** ClusterIP service routing traffic to the Umami application pod on port 3000.
- **PostgreSQL Services (`umami-postgresql`, `umami-postgresql-hl`):** ClusterIP and headless services routing database connections on port 5432.
- **HorizontalPodAutoscaler (`umami`):** Autoscaling policy dynamically scaling application pods based on CPU and memory utilization.
- **Secrets Management (`umami-db`, `umami-app-secret`):** Managed secrets storing the database connection string and application hashing salt.
- **Gateway API HTTPRoute / Ingress (`route`, `ingress`):** Optional Gateway API HTTPRoute or Kubernetes Ingress routing external traffic to the service.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply um ./umami-timoni
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	resources: {
		requests: {
			cpu:    "200m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1Gi"
		}
	}
	umami: {
		appSecret: {
			secret: "replace-with-a-very-secure-random-app-secret-string"
		}
	}
	postgresql: {
		enabled: true
		auth: {
			database: "umami"
			username: "umami"
			password: "MySecureDatabasePassword123!"
		}
		persistence: {
			size: "20Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply um ./umami-timoni \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete um
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.registry` | string | `ghcr.io` | Container image registry |
| `image.repository` | string | `umami-software/umami` | Container image repository |
| `image.tag` | string | `3.3.1` | Pinned container image tag |
| `image.pullPolicy` | string | `Always` | Kubernetes image pull policy |
| `replicaCount` | int | `1` | Number of Umami application replicas |
| `service.port` | int | `3000` | Kubernetes service listening port |
| `resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1000m", memory: "512Mi"}}` | Container resource requests and limits |
| `autoscaling.enabled` | bool | `true` | Enable Horizontal Pod Autoscaler |
| `umami.disableTelemetry` | string | `"1"` | Disable anonymous telemetry collection |
| `umami.disableBotCheck` | string | `"1"` | Disable bot validation checks |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database |
| `postgresql.image.repository` | string | `bitnamilegacy/postgresql` | PostgreSQL container image |
| `postgresql.image.tag` | string | `14` | PostgreSQL container image tag |
| `postgresql.persistence.size` | string | `8Gi` | PostgreSQL volume storage capacity |
| `mysql.enabled` | bool | `false` | Deploy optional internal MySQL database |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress for external traffic |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		fsGroup: 65533
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		runAsUser:                1001
		runAsGroup:               65533
		capabilities: drop: ["ALL"]
	}
	postgresql: {
		podSecurityContext: {
			fsGroup: 1001
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
			runAsNonRoot:             true
			runAsUser:                1001
			runAsGroup:               1001
			capabilities: drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official Umami Website](https://umami.is/)
- [Official Umami Repository](https://github.com/umami-software/umami)
- [Umami Documentation](https://umami.is/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Umami module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Umami Application (`um`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`um-postgresql`) | StatefulSet | 13 points | ✅ |
