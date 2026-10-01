# Strapi

## Description
[Strapi](https://strapi.io/) is an open-source headless CMS (Content Management System) built on Node.js. It provides developers and content teams with customizable REST and GraphQL APIs, an intuitive administrative panel, role-based access control (RBAC), and flexible content-type modeling for multi-channel content delivery.

## Application Information
- **Version:** `5.52.1`
- **Official Website:** [https://strapi.io/](https://strapi.io/)
- **Upstream Project:** [https://github.com/strapi/strapi](https://github.com/strapi/strapi)
- **Container Base:**
  - Strapi Application: [ghcr.io/evocloud-dev/oci/strapi-base](https://github.com/evocloud-dev) (`ghcr.io/evocloud-dev/oci/strapi-base:5.52.1`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
  - MySQL Database (optional subchart): [docker.io/library/mysql](https://hub.docker.com/_/mysql) (`docker.io/library/mysql:9.7.2`)
  - Init Container: [docker.io/library/busybox](https://hub.docker.com/_/busybox) (`docker.io/library/busybox:1.37`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Strapi Application (`strapi`):** Core headless CMS application server (`Deployment/strapi`) running `ghcr.io/evocloud-dev/oci/strapi-base:5.52.1` on port 1337, managing content schemas, admin UI, REST/GraphQL endpoints, and upload handlers.
- **PostgreSQL Database (`strapi-postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`StatefulSet/strapi-postgresql`) running `postgres:18.6-trixie` with persistent volume storage (`8Gi`), headless service, and automated secret provisioning.
- **Strapi Service (`strapi`):** ClusterIP service exposing port 80 (routing to container port 1337) for internal cluster communications, ingress routing, and frontend applications.
- **PostgreSQL Services (`strapi-postgresql`, `strapi-postgresql-primary-headless`):** ClusterIP and headless services routing database traffic on port 5432.
- **Persistent Storage (`persistence`, `postgresql.primary.persistence`):** Dedicated PersistentVolumeClaims for local media uploads (`5Gi`), SQLite database files (if used), and PostgreSQL database records (`8Gi`).
- **Init Container (`wait-for-db`):** Network socket probe verifying that the relational database is reachable before booting Strapi.
- **Ingress (`ingress`) & Gateway API (`gatewayAPI`):** Optional Ingress controller or Gateway API HTTPRoute routing HTTP/HTTPS traffic to the Strapi API and admin panel.
- **Automated Backup (Optional CronJob):** Scheduled CronJob performing automated database backups and uploading them to S3/MinIO object storage.
- **ServiceAccount (`serviceAccount`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply strapi ./strapi
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	strapi: {
		url: "https://cms.example.com"
		upload: {
			provider: "local"
		}
	}
	resources: {
		requests: {
			cpu:    "500m"
			memory: "1Gi"
		}
		limits: {
			cpu:    "2"
			memory: "2Gi"
		}
	}
	postgresql: {
		enabled: true
		primary: {
			persistence: {
				size: "16Gi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply strapi ./strapi \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete strapi
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `ghcr.io/evocloud-dev/oci/strapi-base` | Container image repository for Strapi |
| `image.tag` | string | `5.52.1` | Pinned container image tag for Strapi |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `strapi.port` | int | `1337` | Container listening port for Strapi |
| `strapi.nodeEnv` | string | `production` | Node.js runtime environment |
| `strapi.telemetryDisabled` | bool | `true` | Disable anonymous telemetry reporting |
| `strapi.upload.provider` | string | `local` | Upload asset provider (`local`, `aws-s3`, `cloudinary`) |
| `resources` | object | `{requests: {cpu: "250m", memory: "512Mi"}, limits: {cpu: "1", memory: "1Gi"}}` | Container resource requests and limits for Strapi |
| `database.mode` | string | `auto` | Database mode (`auto`, `sqlite`, `external`, `postgresql`, `mysql`) |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database subchart |
| `postgresql.image.repository` | string | `docker.io/library/postgres` | Container image repository for PostgreSQL |
| `postgresql.image.tag` | string | `18.6-trixie` | Container image tag for PostgreSQL |
| `postgresql.auth.database` | string | `strapi` | Database name created on initialization |
| `postgresql.auth.username` | string | `strapi` | Database username for Strapi connectivity |
| `postgresql.primary.persistence.size` | string | `8Gi` | Storage capacity allocated for PostgreSQL data |
| `postgresql.primary.resources` | object | `{requests: {cpu: "250m", memory: "256Mi"}, limits: {cpu: "1", memory: "512Mi"}}` | Container resource requests and limits for PostgreSQL |
| `persistence.enabled` | bool | `true` | Enable persistent storage for uploads and local data |
| `persistence.size` | string | `5Gi` | Storage capacity allocated for Strapi uploads |
| `service.port` | int | `80` | Kubernetes Service port |
| `service.type` | string | `ClusterIP` | Kubernetes Service type |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress for external traffic |

### Recommended values

Comply with the restricted Kubernetes pod security standard:

```cue
values: {
	podSecurityContext: {
		fsGroup: 65510
		seccompProfile: type: "RuntimeDefault"
	}
	securityContext: {
		runAsNonRoot:             true
		runAsUser:                65510
		runAsGroup:               65510
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}
}
```

## Additional Resources
- [Official Strapi Website](https://strapi.io/)
- [Official Strapi Repository](https://github.com/strapi/strapi)
- [Strapi Documentation](https://docs.strapi.io/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Strapi module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Strapi Application (`strapi`) | Deployment | 13 points | ✅ |
| PostgreSQL Database (`strapi-postgresql`) | StatefulSet | 15 points | ✅ |
