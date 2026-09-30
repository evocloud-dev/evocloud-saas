# OpenProject

## Description
[OpenProject](https://www.openproject.org/) is the leading open-source project management software, providing classical, agile, and hybrid project management tools, team collaboration, task tracking, Gantt charts, roadmapping, and document sharing with total data sovereignty.

## Application Information
- **Version:** 0.1.2 (App: 17.8.0-slim)
- **Upstream Project:** [https://github.com/opf/openproject](https://github.com/opf/openproject)
- **Container Base:** [docker.io/openproject/openproject](https://hub.docker.com/r/openproject/openproject) (`docker.io/openproject/openproject:17.8.0-slim`), [docker.io/openproject/hocuspocus](https://hub.docker.com/r/openproject/hocuspocus) (`docker.io/openproject/hocuspocus:release-17.7-e4163f1c`), [docker.io/bitnamilegacy/postgresql](https://hub.docker.com/r/bitnamilegacy/postgresql) (`docker.io/bitnamilegacy/postgresql:15.4.0-debian-11-r45`), [docker.io/bitnamilegacy/memcached](https://hub.docker.com/r/bitnamilegacy/memcached) (`docker.io/bitnamilegacy/memcached:1.6.24-debian-12-r0`), [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **OpenProject Web (`openp-web`):** Primary web server, API, and user interface running OpenProject Puma on container port 8080 (exposed via Service port 80).
- **Background Worker (`openp-worker-default`):** GoodJob background worker consuming and executing asynchronous jobs, emails, and background processing.
- **Scheduled Cron (`openp-cron`):** Periodic background task runner executing cron jobs, mail polling, and scheduled maintenance.
- **Hocuspocus Collaboration Server (`openp-hocuspocus`):** Real-time collaborative document editing backend powered by Yjs/Hocuspocus running on port 1234.
- **PostgreSQL Database Subchart (`openp-postgresql`):** Dedicated PostgreSQL 15 StatefulSet providing persistent relational database storage with unprivileged bitnami security context (`1001:1001`).
- **Memcached Cache Subchart (`openp-memcached`):** Dedicated Memcached StatefulSet providing fast in-memory key-value caching.
- **Database Seeder (`seeder`):** One-off initial Job responsible for database migrations and initial administrative data seeding.
- **Network Policies:** Granular egress and ingress NetworkPolicy objects for web, worker, cron, seeder, and hocuspocus workloads.
- **Ingress (`ingress`):** Optional Ingress resource multiplexing HTTP web traffic (`/`) to OpenProject and WebSocket traffic (`/hocuspocus`) to the Hocuspocus collaboration server under a single hostname.
- **ServiceAccount & RBAC (`sa`, `role`, `roleBinding`):** Dedicated Kubernetes ServiceAccount with `automountServiceAccountToken: false` and optional OpenShift SecurityContextConstraints.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting ReadWriteOnce persistent volumes (and ReadWriteMany if multi-replica web scaling is enabled)

## Install

To create an instance using default values:

```shell
timoni -n default apply openproject ./openproject
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	openproject: {
		host:          "openproject.example.com"
		secretKeyBase: "a-very-long-secret-key-base-minimum-64-characters"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply openproject ./openproject \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete openproject
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the chart name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `image.registry` | string | `"docker.io"` | OpenProject container image registry |
| `image.repository` | string | `"openproject/openproject"` | OpenProject container image repository |
| `image.tag` | string | `"17.8.0-slim"` | OpenProject container image tag |
| `image.imagePullPolicy` | string | `"Always"` | Kubernetes image pull policy |
| `replicaCount` | int | `1` | Number of web replicas |
| `serviceAccount.create` | bool | `true` | Create dedicated ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | bool | `false` | Mount Kubernetes API token into the pod |
| `podSecurityContext.fsGroup` | int | `1000` | Group ID for volume filesystem ownership |
| `containerSecurityContext.runAsUser` | int | `1000` | Unprivileged non-root container UID |
| `containerSecurityContext.runAsGroup` | int | `1000` | Unprivileged non-root container GID |
| `containerSecurityContext.runAsNonRoot` | bool | `true` | Enforce container execution as non-root user |
| `containerSecurityContext.readOnlyRootFilesystem` | bool | `true` | Mount container root filesystem in read-only mode |
| `containerSecurityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `containerSecurityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |
| `containerSecurityContext.seccompProfile.type` | string | `"RuntimeDefault"` | Seccomp profile type |
| `service.ports.http.port` | int | `80` | Port exposed by Kubernetes Service (routes to 8080) |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `persistence.enabled` | bool | `true` | Enable persistent storage for uploaded attachments |
| `persistence.size` | string | `"1Gi"` | Storage capacity requested for persistent storage |
| `persistence.accessModes` | list | `["ReadWriteMany"]` | Access modes for storage claim |
| `resources.requests.cpu` | string | `"200m"` | CPU request for web container |
| `resources.requests.memory` | string | `"1536Mi"` | Memory request for web container |
| `resources.limits.cpu` | string | `"1000m"` | CPU limit for web container |
| `resources.limits.memory` | string | `"2Gi"` | Memory limit for web container |
| `openproject.host` | string | `""` | Primary public hostname for OpenProject |
| `openproject.https` | bool | `true` | Enforce HTTPS protocol |
| `openproject.secretKeyBase` | string | `"OVERWRITE_ME"` | Secret key used for signing cookies and tokens |
| `hocuspocus.enabled` | bool | `true` | Enable Hocuspocus real-time collaboration server |
| `hocuspocus.image.repository` | string | `"docker.io/openproject/hocuspocus"` | Hocuspocus container image repository |
| `hocuspocus.image.tag` | string | `"release-17.7-e4163f1c"` | Hocuspocus container image tag |
| `hocuspocus.service.port` | int | `1234` | Port exposed by Hocuspocus Service |
| `ingress.enabled` | bool | `false` | Enable Ingress routing for web and Hocuspocus WebSocket |
| `ingress.host` | string | `"openproject.local"` | Hostname for Ingress routing |
| `ingress.ingressClassName` | string | `"nginx"` | Ingress controller class name |
| `cron.enabled` | bool | `true` | Enable background cron runner Deployment |
| `postgresql.bundled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.image.repository` | string | `"bitnamilegacy/postgresql"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"15.4.0-debian-11-r45"` | PostgreSQL container image tag |
| `memcached.bundled` | bool | `true` | Deploy dedicated Memcached cache subchart |
| `memcached.image.repository` | string | `"bitnamilegacy/memcached"` | Memcached container image repository |
| `memcached.image.tag` | string | `"1.6.24-debian-12-r0"` | Memcached container image tag |

## Recommended values

OpenProject pods operate with dedicated unprivileged system users (`1000:1000`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with read-only root filesystems, `allowPrivilegeEscalation: false`, and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		enabled: true
		fsGroup: 1000
	}
	containerSecurityContext: {
		enabled:                  true
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		readOnlyRootFilesystem:   true
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}
}
```

## Additional Resources
- [Official OpenProject Website](https://www.openproject.org/)
- [Official OpenProject Repository](https://github.com/opf/openproject)
- [OpenProject Documentation](https://www.openproject.org/docs/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the OpenProject module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| OpenProject Web (`openp-web`) | Deployment | 11 points | ✅ |
| OpenProject Cron (`openp-cron`) | Deployment | 12 points | ✅ |
| Hocuspocus (`openp-hocuspocus`) | Deployment | 11 points | ✅ |
| OpenProject Worker (`openp-worker-default`) | Deployment | 11 points | ✅ |
| PostgreSQL Subchart (`openp-postgresql`) | StatefulSet | 13 points | ✅ |
| Memcached Subchart (`openp-memcached`) | StatefulSet | 13 points | ✅ |
