# tududi

## Description

[tududi](https://tududi.com/) is a self-hosted web-based task, project, and personal productivity management application. It allows users to organize their life and projects with a clear, hierarchical structure (areas, projects, tasks, notes, and tags) and smart recurring tasks while keeping data private.

## Application Information
- **Version:** `1.9.5`
- **Official Website:** [https://tududi.com/](https://tududi.com/)
- **Upstream Project:** [https://github.com/chrisvel/tududi](https://github.com/chrisvel/tududi)
- **Container Base:**
  - tududi Application: [docker.io/chrisvel/tududi](https://hub.docker.com/r/chrisvel/tududi) (`docker.io/chrisvel/tududi:1.9.5`)
  - PostgreSQL Database: [docker.io/postgres](https://hub.docker.com/_/postgres) (`docker.io/postgres:16-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **tududi Web Server Workload (`tududi`):** Core web-based task and project management application running on container HTTP port `3002` and exposed on service port `3002`.
- **Deployment (`tududi`):** Single-replica deployment with `Recreate` upgrade strategy, `livenessProbe` and `readinessProbe` HTTP health checks (`/api/health`), immutable `ConfigMap` environment configuration, and persistent storage mounts for `/app/uploads`, `/app/backups`, and `/app/db` (when SQLite is used).
- **Service (`tududi`):** Kubernetes `ClusterIP` Service exposing the tududi web application on port `3002` targeting container port `http` (`3002`).
- **ConfigMap (`tududi-<hash>`):** Immutable Kubernetes `ConfigMap` providing application environment variables from `values.env` (and automatically wiring `DATABASE_URL` when `postgres.enabled` is active).
- **PersistentVolumeClaims (`tududi-uploads`, `tududi-backups`, `tududi-db`):** Persistent storage volumes (`ReadWriteOnce`) mounted at `/app/uploads` (`5Gi` default), `/app/backups` (`5Gi` default), and `/app/db` (`1Gi` default, created when `postgres.enabled` is `false`).
- **PostgreSQL Database (`tududi-postgres`):** Dedicated PostgreSQL 16 database `StatefulSet` (with `volumeClaimTemplates` for `5Gi` persistent storage and `pg_isready` health checks) and `Service` (port `5432`).
- **Gateway API HTTPRoute (`tududi`):** Optional Gateway API `HTTPRoute` resource (`gateway.networking.k8s.io/v1`) for routing HTTP/HTTPS traffic via Kubernetes Gateway API controllers.

## Prerequisites

- Kubernetes cluster v1.33+ (or v1.20+ minimum supported by module schema)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting `ReadWriteOnce` PVCs for `persistence` and `postgres.persistence`
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply tududi ./tududi
```

To deploy with customized values (for example customizing PostgreSQL credentials, environment variables, and `HTTPRoute`), create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		uploads: {
			enabled: true
			size:    "10Gi"
		}
		backups: {
			enabled: true
			size:    "10Gi"
		}
	}
	postgres: {
		enabled:  true
		database: "tududi"
		user:     "tududi"
		password: "tududi-secret-password"
		persistence: {
			size: "10Gi"
		}
	}
	service: {
		type: "ClusterIP"
		port: 3002
	}
	gatewayAPI: {
		enabled: true
		httpRoutes: [
			{
				parentRefs: [
					{
						name:      "shared-gtw"
						namespace: "kube-system"
						group:     "gateway.networking.k8s.io"
						kind:      "Gateway"
						port:      80
					},
				]
				hostnames: [
					"tududi.example.com",
				]
			},
		]
	}
	resources: {
		requests: {
			cpu:    "100m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "512Mi"
		}
	}
	env: {
		TUDUDI_USER_EMAIL:      "admin@example.com"
		TUDUDI_USER_PASSWORD:   "change-me-to-a-secure-password"
		TUDUDI_SESSION_SECRET:  "change-me-please-use-openssl-rand-hex-64"
		TUDUDI_ALLOWED_ORIGINS: "https://tududi.example.com"
		TUDUDI_TRUST_PROXY:     "true"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply tududi ./tududi \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete tududi
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `metadata.labels` | `object` | `{}` | Additional labels applied to all module resources |
| `metadata.annotations` | `object` | `{}` | Annotations applied to all module resources |
| `image.repository` | `string` | `"docker.io/chrisvel/tududi"` | Container image repository |
| `image.tag` | `string` | `"1.9.5"` | Container image release tag |
| `image.digest` | `string` | `""` | Container image SHA256 digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `replicas` | `int` | `1` | Workload replica count |
| `strategy.type` | `string` | `"Recreate"` | Deployment rollout strategy (`Recreate` or `RollingUpdate`) |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `3002` | Application Service HTTP port |
| `service.annotations` | `object` | `{}` | Annotations applied to the Service |
| `persistence.db.enabled` | `bool` | `true` | Enable the `db` PersistentVolumeClaim (when `postgres.enabled` is `false`) |
| `persistence.db.size` | `string` | `"1Gi"` | Storage capacity requested for the `db` PVC |
| `persistence.db.accessModes` | `list` | `["ReadWriteOnce"]` | `db` PVC access modes |
| `persistence.db.storageClass` | `string` | `""` | Optional StorageClass name for the `db` PVC |
| `persistence.uploads.enabled` | `bool` | `true` | Enable the `uploads` PersistentVolumeClaim |
| `persistence.uploads.size` | `string` | `"5Gi"` | Storage capacity requested for the `uploads` PVC |
| `persistence.uploads.accessModes` | `list` | `["ReadWriteOnce"]` | `uploads` PVC access modes |
| `persistence.uploads.storageClass` | `string` | `""` | Optional StorageClass name for the `uploads` PVC |
| `persistence.backups.enabled` | `bool` | `true` | Enable the `backups` PersistentVolumeClaim |
| `persistence.backups.size` | `string` | `"5Gi"` | Storage capacity requested for the `backups` PVC |
| `persistence.backups.accessModes` | `list` | `["ReadWriteOnce"]` | `backups` PVC access modes |
| `persistence.backups.storageClass` | `string` | `""` | Optional StorageClass name for the `backups` PVC |
| `postgres.enabled` | `bool` | `true` | Enable the PostgreSQL database StatefulSet component |
| `postgres.image.repository` | `string` | `"docker.io/postgres"` | PostgreSQL container image repository |
| `postgres.image.tag` | `string` | `"16-alpine"` | PostgreSQL container image tag |
| `postgres.image.pullPolicy` | `string` | `"IfNotPresent"` | PostgreSQL image pull policy |
| `postgres.port` | `int` | `5432` | PostgreSQL Service and container port |
| `postgres.database` | `string` | `"tududi"` | PostgreSQL database name |
| `postgres.user` | `string` | `"tududi"` | PostgreSQL database username |
| `postgres.password` | `string` | `"change-me-postgres-password"` | PostgreSQL database password |
| `postgres.podSecurityContext.runAsUser` | `int` | `999` | PostgreSQL Pod user UID |
| `postgres.podSecurityContext.runAsGroup` | `int` | `999` | PostgreSQL Pod group GID |
| `postgres.podSecurityContext.fsGroup` | `int` | `999` | PostgreSQL Pod filesystem group GID |
| `postgres.securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation on PostgreSQL container |
| `postgres.securityContext.privileged` | `bool` | `false` | Run PostgreSQL container in privileged mode |
| `postgres.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from PostgreSQL container |
| `postgres.securityContext.capabilities.add` | `list` | `["CHOWN", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]` | Linux capabilities added to PostgreSQL container |
| `postgres.persistence.size` | `string` | `"5Gi"` | Storage capacity requested for the PostgreSQL PVC |
| `postgres.persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PostgreSQL PVC access modes |
| `postgres.persistence.storageClass` | `string` | `""` | Optional StorageClass name for the PostgreSQL PVC |
| `postgres.resources.requests.cpu` | `string` | `"100m"` | PostgreSQL container CPU request |
| `postgres.resources.requests.memory` | `string` | `"256Mi"` | PostgreSQL container memory request |
| `postgres.resources.limits.cpu` | `string` | `"1000m"` | PostgreSQL container CPU limit |
| `postgres.resources.limits.memory` | `string` | `"512Mi"` | PostgreSQL container memory limit |
| `gatewayAPI.enabled` | `bool` | `false` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | Route definitions with `parentRefs`, `hostnames`, `rules`, `labels`, and `annotations` |
| `resources.requests.cpu` | `string` | `"100m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"256Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"1000m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"512Mi"` | Container memory limit |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `securityContext.privileged` | `bool` | `false` | Run container in privileged mode |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `securityContext.capabilities.add` | `list` | `["CHOWN", "DAC_OVERRIDE", "FOWNER", "NET_BIND_SERVICE", "SETGID", "SETUID"]` | Linux capabilities added to container |
| `env.TUDUDI_USER_EMAIL` | `string` | `"admin@example.com"` | Initial admin account email |
| `env.TUDUDI_USER_PASSWORD` | `string` | `"change-me-to-a-secure-password"` | Initial admin account password |
| `env.TUDUDI_SESSION_SECRET` | `string` | `"change-me-please-use-openssl-rand-hex-64"` | Secret key used to sign session cookies |
| `env.TUDUDI_ALLOWED_ORIGINS` | `string` | `"http://localhost:3002"` | Comma-separated list of allowed CORS origins |
| `env.TUDUDI_TRUST_PROXY` | `string` | `"false"` | Trust reverse proxy `X-Forwarded-For` headers |
| `env.TUDUDI_UPLOAD_PATH` | `string` | `"/app/uploads"` | Container upload directory path |
| `env.TUDUDI_BACKUP_PATH` | `string` | `"/app/backups"` | Container backup directory path |
| `env.PUID` | `string` | `"1001"` | Runtime user UID |
| `env.PGID` | `string` | `"1001"` | Runtime group GID |
| `env.DB_SSL` | `string` | `"false"` | Enable SSL for PostgreSQL connections |
| `env.DB_POOL_MAX` | `string` | `"10"` | Maximum PostgreSQL connection pool size |
| `automountServiceAccountToken` | `bool` | `false` | Automatically mount the Kubernetes ServiceAccount token |
| `podAnnotations` | `object` | `{}` | Annotations applied to pods |
| `podSecurityContext` | `object` | `{}` | Pod-level security context settings |
| `nodeSelector` | `object` | `{"kubernetes.io/os": "linux"}` | Node selector labels for pod scheduling |
| `affinity` | `object` | `{podAntiAffinity: "soft"}` | Pod and node affinity scheduling rules |
| `topologySpreadConstraints` | `list` | `[]` | Pod topology spread constraints |
| `tolerations` | `list` | `[]` | Pod tolerations for node taints |
| `test.enabled` | `bool` | `false` | Run healthcheck test Job on install/upgrade |

## Additional Resources
- [Official tududi Website](https://tududi.com/)
- [tududi GitHub Repository](https://github.com/chrisvel/tududi)
- [tududi Environment Configuration Reference](https://github.com/chrisvel/tududi/blob/main/.env.example)
- [tududi Docker Hub](https://hub.docker.com/r/chrisvel/tududi)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the tududi module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| tududi Server (`tududi`) | Deployment | 10 points | ✅ |
| PostgreSQL Database (`tududi-postgres`) | StatefulSet | 12 points | ✅ |
