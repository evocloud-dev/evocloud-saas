# NetBox

## Description
[NetBox](https://netboxlabs.com/) is an open-source Network Infrastructure Automation (NIA) and Network Source of Truth (NSoT) application designed to manage and document computer networks, IP address management (IPAM), and datacenter infrastructure management (DCIM).

## Application Information
- **Version:** 0.1.0 (App: v4.6.9)
- **Upstream Project:** [https://github.com/netbox-community/netbox](https://github.com/netbox-community/netbox)
- **Container Base:** [ghcr.io/chielochi/netbox-plugins](https://github.com/chielochi/netbox-plugins) (`ghcr.io/chielochi/netbox-plugins:v4.6.9` based on `docker.io/netboxcommunity/netbox`), [docker.io/bitnamilegacy/postgresql](https://hub.docker.com/r/bitnamilegacy/postgresql) (`docker.io/bitnamilegacy/postgresql:17.6.0-debian-12-r4`), [docker.io/bitnamilegacy/valkey](https://hub.docker.com/r/bitnamilegacy/valkey) (`docker.io/bitnamilegacy/valkey:8.1.3-debian-12-r3`), [docker.io/busybox](https://hub.docker.com/_/busybox) (`docker.io/busybox:1.37.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **NetBox Core (`netbox`):** Primary web application, API server, and admin interface running Granian WSGI/ASGI with Python/Django on port 8080 (exposed via Service port 80).
- **NetBox Worker (`netbox-worker`):** Scalable RQ background worker (`rqworker`) executing asynchronous jobs, webhooks, and queued tasks, equipped with an init container verifying backend deployment rollout status.
- **PostgreSQL Database Subchart (`netbox-postgresql`):** Dedicated PostgreSQL 17 StatefulSet providing persistent relational storage (`8Gi`) running under unprivileged Bitnami security context (`65510:65510`).
- **Valkey Primary (`netbox-valkey-primary`):** Dedicated Valkey 8 StatefulSet serving as primary in-memory cache and Redis-compatible broker for RQ task queues (`1Gi`).
- **Valkey Replicas (`netbox-valkey-replicas`):** Replicated Valkey instances ensuring high-availability cache read replicas.
- **Housekeeping CronJob (`cronjob`):** Scheduled CronJob running NetBox management housekeeping tasks (`manage.py housekeeping`) on a configurable cron schedule (`0 0 * * *`).
- **Persistent Volume Claims:** Dedicated persistent volume claims including Media PVC (`media-pvc`), optional Reports PVC (`reports-pvc`), and Scripts PVC (`scripts-pvc`).
- **Gateway API HTTPRoute (`httproute`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource for modern cluster ingress routing.
- **Observability & Metrics:** Built-in Granian metrics exporter and Prometheus ServiceMonitors for web and background worker telemetry.
- **ServiceAccount & RBAC (`serviceaccount`, `role`, `rolebinding`):** Dedicated Kubernetes ServiceAccount and least-privilege RBAC role bindings.

## Prerequisites
- Kubernetes cluster v1.25+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting ReadWriteOnce persistent volumes
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway, Cilium) if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply netbox ./netbox
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	superuser: {
		name:  "admin"
		email: "admin@example.com"
	}
	httpRoute: {
		enabled:   true
		hostnames: ["netbox.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply netbox ./netbox \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete netbox
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the chart name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `commonLabels` | map | `{}` | Common labels added to all resources |
| `commonAnnotations` | map | `{}` | Common annotations added to all resources |
| `clusterDomain` | string | `"cluster.local"` | Kubernetes cluster domain |
| `image.registry` | string | `"ghcr.io"` | NetBox container image registry |
| `image.repository` | string | `"chielochi/netbox-plugins"` | NetBox container image repository |
| `image.tag` | string | `"v4.6.9"` | NetBox container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `superuser.name` | string | `"admin"` | Default superuser username |
| `superuser.email` | string | `"admin@example.com"` | Default superuser email address |
| `superuser.password` | string | `"changeit"` | Default superuser password |
| `superuser.existingSecret` | string | `""` | Existing secret name containing superuser credentials |
| `allowedHosts` | list | `["*"]` | List of allowed HTTP Host headers |
| `allowedHostsIncludesPodIP` | bool | `true` | Automatically append pod IP to allowed hosts |
| `loginRequired` | bool | `true` | Enforce authentication to view any NetBox content |
| `timeZone` | string | `"UTC"` | Server time zone |
| `plugins` | list | `["netbox_routing", "netbox_topology_views"]` | Enabled NetBox plugins |
| `persistence.enabled` | bool | `true` | Enable persistent storage for uploaded media files |
| `persistence.size` | string | `"1Gi"` | Storage capacity requested for NetBox media PVC |
| `persistence.accessMode` | string | `"ReadWriteOnce"` | Access mode for media PVC |
| `resources.requests.cpu` | string | `"200m"` | CPU request for NetBox web container |
| `resources.requests.memory` | string | `"1Gi"` | Memory request for NetBox web container |
| `resources.limits.cpu` | string | `"500m"` | CPU limit for NetBox web container |
| `resources.limits.memory` | string | `"2Gi"` | Memory limit for NetBox web container |
| `podSecurityContext.fsGroup` | int | `1000` | Group ID for volume filesystem permissions |
| `podSecurityContext.fsGroupChangePolicy` | string | `"Always"` | Policy for volume filesystem ownership changes |
| `securityContext.runAsUser` | int | `1000` | Unprivileged non-root container UID |
| `securityContext.runAsGroup` | int | `1000` | Unprivileged non-root container GID |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce container execution as non-root user |
| `securityContext.readOnlyRootFilesystem` | bool | `true` | Mount container root filesystem in read-only mode |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |
| `securityContext.seccompProfile.type` | string | `"RuntimeDefault"` | Seccomp profile type |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | int | `80` | Port exposed by Kubernetes Service (routes to 8080) |
| `httpRoute.enabled` | bool | `false` | Enable Kubernetes Gateway API HTTPRoute creation |
| `httpRoute.hostnames` | list | `["evocloud.dev"]` | Hostnames associated with the HTTPRoute |
| `housekeeping.enabled` | bool | `true` | Enable scheduled housekeeping CronJob |
| `housekeeping.schedule` | string | `"0 0 * * *"` | Housekeeping CronJob schedule |
| `worker.enabled` | bool | `true` | Enable NetBox background RQ worker deployment |
| `worker.replicaCount` | int | `1` | Number of worker replicas |
| `worker.resources.requests.cpu` | string | `"200m"` | CPU request for worker pods |
| `worker.resources.requests.memory` | string | `"512Mi"` | Memory request for worker pods |
| `worker.resources.limits.cpu` | string | `"500m"` | CPU limit for worker pods |
| `worker.resources.limits.memory` | string | `"1Gi"` | Memory limit for worker pods |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.image.repository` | string | `"bitnamilegacy/postgresql"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"17.6.0-debian-12-r4"` | PostgreSQL container image tag |
| `postgresql.auth.username` | string | `"netbox"` | PostgreSQL database user |
| `postgresql.auth.database` | string | `"netbox"` | PostgreSQL database name |
| `postgresql.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for PostgreSQL |
| `postgresql.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL |
| `postgresql.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL |
| `postgresql.resources.limits.cpu` | string | `"500m"` | CPU limit for PostgreSQL |
| `postgresql.resources.limits.memory` | string | `"1Gi"` | Memory limit for PostgreSQL |
| `valkey.enabled` | bool | `true` | Deploy dedicated Valkey in-memory cache subchart |
| `valkey.image.repository` | string | `"bitnamilegacy/valkey"` | Valkey container image repository |
| `valkey.image.tag` | string | `"8.1.3-debian-12-r3"` | Valkey container image tag |
| `valkey.replicaCount` | int | `3` | Number of Valkey replica instances |
| `valkey.persistence.size` | string | `"1Gi"` | Persistent Volume size requested for Valkey |
| `valkey.resources.requests.cpu` | string | `"100m"` | CPU request for Valkey |
| `valkey.resources.requests.memory` | string | `"128Mi"` | Memory request for Valkey |
| `valkey.resources.limits.cpu` | string | `"500m"` | CPU limit for Valkey |
| `valkey.resources.limits.memory` | string | `"512Mi"` | Memory limit for Valkey |

## Recommended values

NetBox pods operate with dedicated unprivileged system users (`1000:1000` for NetBox core/worker, `65510:65510` for PostgreSQL/Valkey), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with read-only root filesystems, `allowPrivilegeEscalation: false`, and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		fsGroup:             1000
		fsGroupChangePolicy: "Always"
	}
	securityContext: {
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
- [Official NetBox Website (NetBox Labs)](https://netboxlabs.com/)
- [Official NetBox Repository](https://github.com/netbox-community/netbox)
- [NetBox Documentation](https://docs.netbox.dev/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the NetBox module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| NetBox Core (`netbox`) | Deployment | 12 points | ✅ |
| NetBox Worker (`netbox-worker`) | Deployment | 11 points | ✅ |
| PostgreSQL Subchart (`netbox-postgresql`) | StatefulSet | 15 points | ✅ |
| Valkey Primary (`netbox-valkey-primary`) | StatefulSet | 15 points | ✅ |
| Valkey Replicas (`netbox-valkey-replicas`) | StatefulSet | 15 points | ✅ |
