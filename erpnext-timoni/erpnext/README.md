# ERPNext

## Description
[ERPNext](https://erpnext.com/) is a full-featured, open-source enterprise resource planning (ERP) system built on the Frappe framework. It provides end-to-end business management capabilities including accounting, human resources (HRMS), inventory and warehouse management, CRM, sales, purchasing, manufacturing, project management, and customer support for organizations of all sizes.

## Application Information
- **Version:** v16.34.1
- **Upstream Project:** [https://github.com/frappe/erpnext](https://github.com/frappe/erpnext) / [https://erpnext.com](https://erpnext.com)
- **Container Base:** [frappe/erpnext](https://hub.docker.com/r/frappe/erpnext) (`frappe/erpnext:v16.34.1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **ERPNext NGINX (`erpnext-nginx`):** Reverse proxy and static asset web server routing incoming HTTP traffic on port 8080 to Gunicorn and Socket.IO backends.
- **ERPNext Gunicorn Application Server (`erpnext-gunicorn`):** Python WSGI application server running the core Frappe and ERPNext business logic on container port 8000.
- **ERPNext Socket.IO Server (`erpnext-socketio`):** Real-time WebSockets event server running on port 9000 handling live notifications, dashboard updates, and background event broadcasting.
- **ERPNext Default Worker (`erpnext-worker-d`):** Dedicated background worker processing default asynchronous task queues.
- **ERPNext Short Worker (`erpnext-worker-s`):** Dedicated background worker processing high-priority, short-duration asynchronous jobs.
- **ERPNext Long Worker (`erpnext-worker-l`):** Dedicated background worker handling resource-intensive, long-running batch operations, data imports, and report generation.
- **ERPNext Scheduler (`erpnext-scheduler`):** Periodic task scheduler triggering automated cron jobs, maintenance routines, and recurring business transactions.
- **MariaDB StatefulSet (`erpnext-mariadb-sts`):** Dedicated MariaDB relational database server (`mariadb:12.3.3`) on port 3306 with persistent volume storage (`8Gi`).
- **PostgreSQL StatefulSet (`erpnext-postgresql-sts`):** Optional dedicated PostgreSQL 18 relational database server (`postgres:18`) on port 5432 with persistent volume storage (`8Gi`).
- **Valkey In-Memory Cache (`erpnext-valkey-cache`):** High-performance Valkey in-memory caching engine (`valkey/valkey:9.0.6`) on port 6379 for fast session and metadata lookup.
- **Valkey Queue Broker (`erpnext-valkey-queue`):** Dedicated Valkey message queue and job broker (`valkey/valkey:9.0.6`) on port 6379 coordinating asynchronous worker execution.
- **Persistent Storage Volumes:** Dedicated shared persistent volume storage for worker site assets and system logs.
- **Kubernetes ServiceAccount:** Dedicated unprivileged ServiceAccount applied across ERPNext pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Shared ReadWriteMany (RWX) storage provisioner (e.g. CephFS, NFS) for multi-pod file access
- Ingress controller or Gateway API controller if external traffic routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply erpnext ./erpnext
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	image: {
		repository: "frappe/erpnext"
		tag:        "v16.34.1"
	}
	nginx: {
		environment: {
			frappeSiteNameHeader: "erp.example.com"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply erpnext ./erpnext \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete erpnext
```

## Configuration

### Key Configuration Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `"frappe/erpnext"` | ERPNext container image repository |
| `image.tag` | string | `"v16.34.1"` | ERPNext container image tag |
| `nginx.service.port` | int | `8080` | Internal ClusterIP service port for NGINX |
| `nginx.autoscaling.enabled` | bool | `true` | Enable Horizontal Pod Autoscaling for NGINX |
| `worker.gunicorn.service.port` | int | `8000` | Internal ClusterIP service port for Gunicorn |
| `socketio.service.port` | int | `9000` | Internal ClusterIP service port for Socket.IO |
| `mariadb-sts.enabled` | bool | `true` | Deploy internal dedicated MariaDB StatefulSet |
| `mariadb-sts.image.tag` | string | `"12.3.3"` | MariaDB container image tag |
| `mariadb-sts.persistence.size` | string | `"8Gi"` | Persistent storage size for MariaDB database |
| `postgresql-sts.enabled` | bool | `false` | Deploy internal dedicated PostgreSQL StatefulSet |
| `postgresql-sts.image.tag` | string | `"18"` | PostgreSQL container image tag |
| `postgresql-sts.persistence.size` | string | `"8Gi"` | Persistent storage size for PostgreSQL database |
| `valkey-cache.enabled` | bool | `true` | Deploy dedicated Valkey cache instance |
| `valkey-cache.image.tag` | string | `"9.0.6"` | Valkey cache container image tag |
| `valkey-queue.enabled` | bool | `true` | Deploy dedicated Valkey queue broker |
| `valkey-queue.image.tag` | string | `"9.0.6"` | Valkey queue container image tag |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress routing |
| `httproute.enabled` | bool | `false` | Enable Gateway API HTTPRoute routing |

## Recommended values

ERPNext application workloads comply with Kubernetes security standards by running as unprivileged non-root users with dropped Linux capabilities and restricted privileges:

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    1000
		runAsGroup:   1000
		supplementalGroups: [1000]
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
			add: ["CHOWN", "NET_BIND_SERVICE", "SETGID", "SETUID"]
		}
	}
}
```

## Additional Resources
- [Official ERPNext Website](https://erpnext.com/)
- [Official ERPNext Repository](https://github.com/frappe/erpnext)
- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the ERPNext module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| NGINX Reverse Proxy (`erpnext-nginx`) | Deployment | 11 points | ✅ |
| Gunicorn Application Server (`erpnext-gunicorn`) | Deployment | 11 points | ✅ |
| Socket.IO Server (`erpnext-socketio`) | Deployment | 11 points | ✅ |
| Default Queue Worker (`erpnext-worker-d`) | Deployment | 11 points | ✅ |
| Short Queue Worker (`erpnext-worker-s`) | Deployment | 11 points | ✅ |
| Long Queue Worker (`erpnext-worker-l`) | Deployment | 11 points | ✅ |
| Task Scheduler (`erpnext-scheduler`) | Deployment | 11 points | ✅ |
| MariaDB Database (`erpnext-mariadb-sts`) | StatefulSet | 13 points | ✅ |
| PostgreSQL Database (`erpnext-postgresql-sts`) | StatefulSet | 13 points | ✅ |
| Valkey In-Memory Cache (`erpnext-valkey-cache`) | Deployment | 14 points | ✅ |
| Valkey Queue Broker (`erpnext-valkey-queue`) | Deployment | 14 points | ✅ |
