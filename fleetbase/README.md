# Fleetbase

## Description
[Fleetbase](https://fleetbase.io/) is an open-source, modular logistics and supply chain operating system. It provides dispatch, fleet management, live tracking, commerce, warehousing, and finance in a unified cloud-native platform with a REST API, webhooks, and an extension ecosystem. It supports self-hosting on Kubernetes infrastructure or managing operations via Fleetbase Cloud.

## Application Information
- **Version:** `0.7.68`
- **Official Website:** [https://fleetbase.io/](https://fleetbase.io/)
- **Upstream Project:** [https://github.com/fleetbase/fleetbase](https://github.com/fleetbase/fleetbase)
- **Container Base:**
  - Fleetbase API Application: [docker.io/fleetbase/fleetbase-api](https://hub.docker.com/r/fleetbase/fleetbase-api) (`docker.io/fleetbase/fleetbase-api:v0.7.68`)
  - HTTPD Reverse Proxy: [docker.io/nginx](https://hub.docker.com/_/nginx) (`docker.io/nginx:stable-alpine`)
  - Fleetbase Console Web UI: [docker.io/fleetbase/fleetbase-console](https://hub.docker.com/r/fleetbase/fleetbase-console) (`docker.io/fleetbase/fleetbase-console:v0.7.68`)
  - SocketCluster Broker: [docker.io/socketcluster/socketcluster](https://hub.docker.com/r/socketcluster/socketcluster) (`docker.io/socketcluster/socketcluster:v20.0.2`)
  - Database Backend (MySQL): [docker.io/mysql](https://hub.docker.com/_/mysql) (`docker.io/mysql:8.0-oracle`)
  - Cache & Message Bus (Redis/Valkey): [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`docker.io/valkey/valkey:9.2`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Fleetbase API Workload (`application`):** Core Fleetbase backend running Laravel Octane with FrankenPHP (`Deployment/fleetbase-application`) exposing port 8000.
- **Fleetbase HTTPD Reverse Proxy (`httpd`):** Nginx reverse proxy fronting the API application (`Deployment/fleetbase-httpd` & `Service/fleetbase-httpd`) on port 80 with request buffering and timeout tuning.
- **Fleetbase Console Web UI (`console`):** Ember.js frontend single-page application (`Deployment/fleetbase-console` & `Service/fleetbase-console`) on port 4200 with dynamic `fleetbase.config.json` ConfigMap injection.
- **Queue Worker (`queue`):** Asynchronous background queue worker (`Deployment/fleetbase-queue`) executing `php artisan queue:work` with queue health probes.
- **Scheduler Daemon (`scheduler`):** Scheduled tasks cron daemon (`Deployment/fleetbase-scheduler`) executing `go-crond` for Laravel scheduled jobs.
- **SocketCluster Broker (`socket`):** Real-time pub/sub event broker (`Deployment/fleetbase-socket` & `Service/fleetbase-socket`) on port 8000.
- **Database StatefulSet (`database`):** In-cluster MySQL StatefulSet (`StatefulSet/fleetbase-mysql` & `Service/fleetbase-mysql`) on port 3306 with configurable PVC (or toggleable for external RDS/Cloud SQL).
- **Cache StatefulSet (`cache`):** In-cluster Redis/Valkey StatefulSet (`StatefulSet/fleetbase-redis` & `Service/fleetbase-redis`) on port 6379 with configurable PVC (or toggleable for external ElastiCache/Memorystore).
- **Database Migration Job (`migration`):** Lifecycle batch Job (`Job/fleetbase-migration`) running `./deploy.sh` to initialize databases, execute migrations, and seed permissions.
- **Gateway API HTTPRoute (`gatewayAPI`):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) routing external traffic to `httpd` (API routes), `console` (SPA), and `socket` (WebSockets).
- **ServiceAccount (`sa`):** Dedicated ServiceAccount with `automountServiceAccountToken: false` for least-privilege security.

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce`

## Install

To create an instance using default values:

```shell
timoni -n fleet apply fleet ./fleetbase
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	environment: "production"
	app: {
		replicas: 2
		persistence: {
			enabled: true
			size:    "20Gi"
		}
	}
	database: {
		persistence: {
			enabled: true
			size:    "50Gi"
		}
	}
	cache: {
		persistence: {
			enabled: true
			size:    "20Gi"
		}
	}
	gatewayAPI: {
		enabled: true
	}
}
```

Apply the values to the instance:

```shell
timoni -n fleet apply fleet ./fleetbase \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n fleet delete fleet
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `environment` | string | `"development"` | Target environment (`development`, `staging`, `production`) |
| `serviceAccount.create` | bool | `true` | Specifies whether a service account should be created |
| `serviceAccount.annotations` | map | `{}` | Annotations to add to the service account |
| `serviceAccount.name` | string | `""` | The name of the service account to use (generated using instance name if empty) |
| `automountServiceAccountToken` | bool | `false` | Disable automounting API credentials into pods |
| `app.autoscaling.enabled` | bool | `false` | Enable HorizontalPodAutoscaler for application |
| `app.autoscaling.minReplicas` | int | `1` | Minimum replica count for application autoscaling |
| `app.autoscaling.maxReplicas` | int | `5` | Maximum replica count for application autoscaling |
| `app.autoscaling.targetCPUUtilizationPercentage` | int | `80` | Target CPU utilization percentage |
| `app.image.repository` | string | `docker.io/fleetbase/fleetbase-api` | API container image repository |
| `app.image.tag` | string | `v0.7.68` | API container image tag |
| `app.replicas` | int | `1` | Replica count for application deployment |
| `app.port` | int | `8000` | Port for application container |
| `app.service.port` | int | `8000` | Service port for Fleetbase API |
| `app.service.type` | string | `ClusterIP` | Kubernetes Service type for API |
| `app.key` | string | `base64:hyts2W3knDncDxQ0gRgf8cCGHRTgGyZh0RoAEhCr1kQ=` | Laravel APP_KEY application encryption key |
| `app.consoleHost` | string | `"http://localhost:4200"` | Console origin URL for CORS |
| `app.frontendHosts` | string | `"http://localhost,http://127.0.0.1,..."` | Allowed frontend hosts for CORS |
| `app.persistence.enabled` | bool | `true` | Enable PVC for `/fleetbase/api/storage/app` |
| `app.persistence.size` | string | `10Gi` | PVC capacity for application storage |
| `app.resources.requests.cpu` | string | `100m` | CPU request for application container |
| `app.resources.requests.memory` | string | `256Mi` | Memory request for application container |
| `app.resources.limits.cpu` | string | `1000m` | CPU limit for application container |
| `app.resources.limits.memory` | string | `1Gi` | Memory limit for application container |
| `httpd.image.repository` | string | `docker.io/nginx` | Nginx HTTPD image repository |
| `httpd.image.tag` | string | `stable-alpine` | Nginx HTTPD image tag |
| `httpd.replicas` | int | `1` | Replica count for HTTPD deployment |
| `httpd.port` | int | `80` | Port exposed by HTTPD container |
| `httpd.service.port` | int | `80` | Service port for HTTPD reverse proxy |
| `httpd.service.type` | string | `ClusterIP` | Kubernetes Service type for HTTPD |
| `httpd.resources.requests.cpu` | string | `20m` | CPU request for HTTPD container |
| `httpd.resources.requests.memory` | string | `64Mi` | Memory request for HTTPD container |
| `httpd.resources.limits.cpu` | string | `200m` | CPU limit for HTTPD container |
| `httpd.resources.limits.memory` | string | `256Mi` | Memory limit for HTTPD container |
| `console.image.repository` | string | `docker.io/fleetbase/fleetbase-console` | Console frontend image repository |
| `console.image.tag` | string | `v0.7.68` | Console frontend image tag |
| `console.enabled` | bool | `true` | Enable Fleetbase Console web UI |
| `console.replicas` | int | `1` | Replica count for Console deployment |
| `console.port` | int | `4200` | Port exposed by Console container |
| `console.service.port` | int | `4200` | Service port for Fleetbase Console |
| `console.service.type` | string | `ClusterIP` | Kubernetes Service type for Console |
| `console.apiHost` | string | `"http://localhost:8000"` | Fleetbase API host for Console UI client |
| `console.resources.requests.cpu` | string | `20m` | CPU request for Console container |
| `console.resources.requests.memory` | string | `64Mi` | Memory request for Console container |
| `console.resources.limits.cpu` | string | `200m` | CPU limit for Console container |
| `console.resources.limits.memory` | string | `128Mi` | Memory limit for Console container |
| `queue.enabled` | bool | `true` | Enable background queue worker deployment |
| `queue.replicas` | int | `1` | Replica count for queue worker deployment |
| `queue.resources.requests.cpu` | string | `100m` | CPU request for queue container |
| `queue.resources.requests.memory` | string | `256Mi` | Memory request for queue container |
| `queue.resources.limits.cpu` | string | `500m` | CPU limit for queue container |
| `queue.resources.limits.memory` | string | `512Mi` | Memory limit for queue container |
| `scheduler.enabled` | bool | `true` | Enable scheduled task cron daemon deployment |
| `scheduler.replicas` | int | `1` | Replica count for scheduler deployment |
| `scheduler.resources.requests.cpu` | string | `50m` | CPU request for scheduler container |
| `scheduler.resources.requests.memory` | string | `128Mi` | Memory request for scheduler container |
| `scheduler.resources.limits.cpu` | string | `200m` | CPU limit for scheduler container |
| `scheduler.resources.limits.memory` | string | `256Mi` | Memory limit for scheduler container |
| `socket.image.repository` | string | `docker.io/socketcluster/socketcluster` | SocketCluster image repository |
| `socket.image.tag` | string | `v20.0.2` | SocketCluster image tag |
| `socket.enabled` | bool | `true` | Enable SocketCluster real-time event broker |
| `socket.port` | int | `8000` | Port for SocketCluster container |
| `socket.service.port` | int | `8000` | Service port for SocketCluster broker |
| `socket.service.type` | string | `ClusterIP` | Kubernetes Service type for SocketCluster |
| `socket.resources.requests.cpu` | string | `50m` | CPU request for socket container |
| `socket.resources.requests.memory` | string | `128Mi` | Memory request for socket container |
| `socket.resources.limits.cpu` | string | `500m` | CPU limit for socket container |
| `socket.resources.limits.memory` | string | `512Mi` | Memory limit for socket container |
| `database.image.repository` | string | `docker.io/mysql` | MySQL container image repository |
| `database.image.tag` | string | `8.0-oracle` | MySQL container image tag |
| `database.enabled` | bool | `true` | Run in-cluster MySQL (`false` for external DB) |
| `database.name` | string | `"fleetbase"` | MySQL database name |
| `database.user` | string | `"root"` | MySQL database username |
| `database.password` | string | `"fleetbase"` | MySQL database root password |
| `database.allowEmptyPassword` | bool | `true` | Allow empty password for MySQL |
| `database.service.port` | int | `3306` | Service port for MySQL database |
| `database.service.type` | string | `ClusterIP` | Kubernetes Service type for MySQL |
| `database.persistence.enabled` | bool | `true` | Enable persistent storage for MySQL |
| `database.persistence.size` | string | `10Gi` | Storage capacity allocated for MySQL PVC |
| `database.podSecurityContext.runAsUser` | int | `999` | User ID for MySQL pod |
| `database.podSecurityContext.runAsGroup` | int | `999` | Group ID for MySQL pod |
| `database.podSecurityContext.runAsNonRoot` | bool | `true` | Run MySQL as non-root user |
| `database.resources.requests.cpu` | string | `100m` | CPU request for database container |
| `database.resources.requests.memory` | string | `512Mi` | Memory request for database container |
| `database.resources.limits.cpu` | string | `1000m` | CPU limit for database container |
| `database.resources.limits.memory` | string | `1Gi` | Memory limit for database container |
| `cache.image.repository` | string | `docker.io/valkey/valkey` | Redis / Valkey container image repository |
| `cache.image.tag` | string | `9.2` | Redis / Valkey container image tag |
| `cache.enabled` | bool | `true` | Run in-cluster Redis/Valkey (`false` for external cache) |
| `cache.port` | int | `6379` | Port for Redis/Valkey cache container |
| `cache.service.port` | int | `6379` | Service port for Redis/Valkey cache |
| `cache.service.type` | string | `ClusterIP` | Kubernetes Service type for Redis/Valkey |
| `cache.persistence.enabled` | bool | `true` | Enable persistent storage for Redis/Valkey |
| `cache.persistence.size` | string | `10Gi` | Storage capacity allocated for Redis PVC |
| `cache.podSecurityContext.runAsUser` | int | `999` | User ID for Redis pod |
| `cache.podSecurityContext.runAsGroup` | int | `999` | Group ID for Redis pod |
| `cache.podSecurityContext.runAsNonRoot` | bool | `true` | Run Redis as non-root user |
| `cache.resources.requests.cpu` | string | `20m` | CPU request for cache container |
| `cache.resources.requests.memory` | string | `64Mi` | Memory request for cache container |
| `cache.resources.limits.cpu` | string | `200m` | CPU limit for cache container |
| `cache.resources.limits.memory` | string | `256Mi` | Memory limit for cache container |
| `migration.enabled` | bool | `true` | Run database migration batch Job on deployment |
| `migration.resources.requests.cpu` | string | `100m` | CPU request for migration container |
| `migration.resources.requests.memory` | string | `256Mi` | Memory request for migration container |
| `migration.resources.limits.cpu` | string | `1000m` | CPU limit for migration container |
| `migration.resources.limits.memory` | string | `1Gi` | Memory limit for migration container |
| `gatewayAPI.enabled` | bool | `true` | Enable Gateway API HTTPRoute resource generation |
| `gatewayAPI.gatewayClassName` | string | `""` | Optional GatewayClass name |
| `gatewayAPI.httpRoutes` | list | `[...]` | List of HTTPRoute specifications with hostnames and rules |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/) and Kubesec hardening:

```cue
values: {
	automountServiceAccountToken: false
	app: {
		securityContext: {
			capabilities: {
				drop: ["ALL"]
				add: ["CHOWN", "DAC_OVERRIDE", "SETUID", "SETGID", "NET_BIND_SERVICE"]
			}
		}
	}
	httpd: {
		securityContext: {
			capabilities: {
				drop: ["ALL"]
				add: ["CHOWN", "SETUID", "SETGID", "NET_BIND_SERVICE"]
			}
		}
	}
	console: {
		securityContext: {
			capabilities: {
				drop: ["ALL"]
				add: ["CHOWN", "SETUID", "SETGID", "NET_BIND_SERVICE"]
			}
		}
	}
	database: {
		podSecurityContext: {
			fsGroup:      999
			runAsUser:    999
			runAsGroup:   999
			runAsNonRoot: true
		}
		securityContext: {
			runAsUser:    999
			runAsGroup:   999
			runAsNonRoot: true
			capabilities: {
				drop: ["ALL"]
			}
		}
	}
	cache: {
		podSecurityContext: {
			fsGroup:      999
			runAsUser:    999
			runAsGroup:   999
			runAsNonRoot: true
		}
		securityContext: {
			runAsUser:    999
			runAsGroup:   999
			runAsNonRoot: true
			capabilities: {
				drop: ["ALL"]
			}
		}
	}
}
```

## Additional Resources
- [Official Fleetbase Website](https://fleetbase.io/)
- [Official Fleetbase Documentation](https://www.fleetbase.io/docs)
- [API Reference](https://www.fleetbase.io/docs/api)
- [Fleetbase GitHub Repository](https://github.com/fleetbase/fleetbase)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Fleetbase module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Fleetbase API (`fleet-application`) | Deployment | 10 points | ✅ |
| Fleetbase HTTPD (`fleet-httpd`) | Deployment | 10 points | ✅ |
| Fleetbase Console (`fleet-console`) | Deployment | 10 points | ✅ |
| Background Queue (`fleet-queue`) | Deployment | 10 points | ✅ |
| Scheduled Tasks (`fleet-scheduler`) | Deployment | 10 points | ✅ |
| SocketCluster Broker (`fleet-socket`) | Deployment | 10 points | ✅ |
| Database Backend (`fleet-mysql`) | StatefulSet | 13 points | ✅ |
| Cache & Message Bus (`fleet-redis`) | StatefulSet | 13 points | ✅ |
