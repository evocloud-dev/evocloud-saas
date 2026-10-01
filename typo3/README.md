# TYPO3

## Description
[TYPO3](https://typo3.org/) is an enterprise-class, open-source Content Management System (CMS) written in PHP. Built for scalability, flexibility, and extensibility, it powers multi-language, multi-site digital experiences with advanced granular access permissions, decoupled architecture options, and an active global open-source community.

## Application Information
- **Version:** `13.4`
- **Official Website:** [https://typo3.org/](https://typo3.org/)
- **Upstream Project:** [https://github.com/TYPO3/typo3](https://github.com/TYPO3/typo3)
- **Container Base:**
  - TYPO3 Application: [docker.io/martinhelmich/typo3](https://hub.docker.com/r/martinhelmich/typo3) (`docker.io/martinhelmich/typo3:13.4`)
  - PostgreSQL Database (Default): [bitnamilegacy/postgresql](https://hub.docker.com/r/bitnamilegacy/postgresql) (`bitnamilegacy/postgresql:17.6.0-debian-12-r4`)
  - MySQL Database (Optional): [bitnamilegacy/mysql](https://hub.docker.com/r/bitnamilegacy/mysql) (`bitnamilegacy/mysql:9.4.0-debian-12-r1`)
  - MariaDB Database (Optional): [bitnamilegacy/mariadb](https://hub.docker.com/r/bitnamilegacy/mariadb) (`bitnamilegacy/mariadb:12.0.2-debian-12-r0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **TYPO3 Core Application (`typo`):** Deployment (`Deployment/typo`) running `martinhelmich/typo3:13.4` with an initial HTML asset population init container (`populate-html`) and volume mounts for configuration and uploads.
- **PostgreSQL Database (`typo-postgresql`):** StatefulSet (`StatefulSet/typo-postgresql`) providing primary relational data persistence with persistent volume storage (`8Gi`) and automated database initialization.
- **MySQL / MariaDB Subcharts:** Optional Bitnami legacy database StatefulSets (`typo-mysql`, `typo-mariadb`) configurable as alternatives to PostgreSQL.
- **TYPO3 Service (`typo`):** ClusterIP service exposing the web application on port 8080 (routing to container port 80).
- **PostgreSQL Services (`typo-postgresql`, `typo-postgresql-headless`):** ClusterIP and headless services routing database connections on port 5432.
- **Persistent Storage:** PersistentVolumeClaims (`typo-fileadmin`, `typo-typo3conf`) maintaining uploads and system configuration files across pod restarts.
- **HorizontalPodAutoscaler (`typo`):** Autoscaling policy managing pod replicas based on CPU utilization targets.
- **Gateway API HTTPRoute (`typo`):** HTTPRoute resource routing external gateway traffic to the TYPO3 service.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply typo ./typo3
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
	postgresql: {
		enabled: true
		auth: {
			database: "typo3"
			username: "typo3"
			password: "MySecurePassword123!"
		}
		persistence: {
			resources: requests: storage: "10Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply typo ./typo3 \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete typo
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.registry` | string | `docker.io` | Container image registry |
| `image.repository` | string | `martinhelmich/typo3` | Container image repository |
| `image.tag` | string | `13.4` | Pinned container image tag |
| `image.pullPolicy` | string | `Always` | Kubernetes image pull policy |
| `replicaCount` | int | `1` | Number of TYPO3 application replicas |
| `service.port` | int | `8080` | Kubernetes service listening port |
| `resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Container resource requests and limits |
| `autoscaling.enabled` | bool | `true` | Enable Horizontal Pod Autoscaler |
| `persistence.fileadmin.enabled` | bool | `true` | Persistent storage for user file uploads |
| `persistence.typo3conf.enabled` | bool | `true` | Persistent storage for TYPO3 configuration |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database |
| `postgresql.image.repository` | string | `bitnamilegacy/postgresql` | PostgreSQL container image |
| `postgresql.image.tag` | string | `17.6.0-debian-12-r4` | PostgreSQL container image tag |
| `postgresql.persistence.resources.requests.storage` | string | `8Gi` | PostgreSQL volume storage size |
| `mysql.enabled` | bool | `false` | Deploy internal MySQL database |
| `mariadb.enabled` | bool | `false` | Deploy internal MariaDB database |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		fsGroup: 33
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
			add: ["NET_BIND_SERVICE", "CHOWN", "SETUID", "SETGID"]
		}
		readOnlyRootFilesystem: true
	}
	postgresql: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
	}
}
```

## Additional Resources
- [Official TYPO3 Website](https://typo3.org/)
- [Official TYPO3 Repository](https://github.com/TYPO3/typo3)
- [TYPO3 Documentation](https://docs.typo3.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the TYPO3 module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| TYPO3 Application (`typo`) | Deployment | 11 points | ✅ |
| PostgreSQL Database (`typo-postgresql`) | StatefulSet | 10 points | ✅ |
| MySQL Database (`typo-mysql`) | StatefulSet | 10 points | ✅ |
| MariaDB Database (`typo-mariadb`) | StatefulSet | 10 points | ✅ |
