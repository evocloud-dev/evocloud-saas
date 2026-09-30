# Pimcore

## Description

[Pimcore](https://pimcore.com/) is an open-source digital experience platform (DXP), product information management (PIM), master data management (MDM), digital asset management (DAM), customer data platform (CDP), and digital commerce framework. Built on the Symfony PHP framework, Pimcore centralizes enterprise master data, digital assets, and customer experiences into a composable, cloud-native architecture.

## Application Information

- **Version:** 1.0.1
- **Upstream Project:** [https://github.com/pimcore/pimcore](https://github.com/pimcore/pimcore)
- **Container Base:**
  - Pimcore PHP: [docker.io/pimcore/pimcore](https://hub.docker.com/r/pimcore/pimcore) (`pimcore/pimcore:php8.5-latest`)
  - Pimcore Nginx: [docker.io/library/nginx](https://hub.docker.com/_/nginx) (`nginx:stable-alpine`)
  - Maintenance Worker: [docker.io/pimcore/pimcore](https://hub.docker.com/r/pimcore/pimcore) (`pimcore/pimcore:php8.5-latest`)
  - Supervisord: [docker.io/pimcore/pimcore](https://hub.docker.com/r/pimcore/pimcore) (`pimcore/pimcore:php8.5-supervisord-5.x`)
  - Mercure Hub: [docker.io/dunglas/mercure](https://hub.docker.com/r/dunglas/mercure) (`dunglas/mercure:latest`)
  - MariaDB Database: [docker.io/library/mariadb](https://hub.docker.com/_/mariadb) (`mariadb:11.4`)
  - Redis Cache & Sessions: [docker.io/library/redis](https://hub.docker.com/_/redis) (`redis:8.8-alpine`)
  - OpenSearch Search Engine: [docker.io/opensearchproject/opensearch](https://hub.docker.com/r/opensearchproject/opensearch) (`opensearchproject/opensearch:2.19.6`)
  - RabbitMQ Message Broker: [docker.io/library/rabbitmq](https://hub.docker.com/_/rabbitmq) (`rabbitmq:4-management`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Pimcore PHP-FPM (`pimcore-php`):** Core application runtime executing Pimcore PHP 8.5 backend, API services, and admin interface on container port 9000.
- **Nginx Web Server (`pimcore-nginx`):** Reverse proxy and web server routing requests to PHP-FPM, terminating HTTP traffic on port 80 with gzip compression and static caching.
- **Maintenance Worker (`pimcore-maintenance-worker`):** Dedicated worker running Symfony Messenger consumer to handle asynchronous queues and maintenance jobs.
- **Supervisord Worker (`pimcore-supervisord`):** Continuous queue runner and background process supervisor (`pimcore/pimcore:php8.5-supervisord-5.x`).
- **Mercure Hub (`pimcore-mercure`):** Real-time hub providing Server-Sent Events (SSE) updates to connected clients on port 80.
- **MariaDB Database (`mysql-mariadb`):** Dedicated MariaDB StatefulSet persisting database tables and Pimcore relational metadata on port 3306.
- **Redis Cache (`redis-master`):** Dedicated in-memory cache and session management StatefulSet on port 6379.
- **OpenSearch Search Engine (`pimcore-opensearch`):** Full-text search and analytical indexing StatefulSet on port 9200.
- **RabbitMQ Message Broker (`pimcore-rabbitmq`):** AMQP message broker StatefulSet handling distributed queues and messages on ports 5672 and 15672.
- **Persistent Data Storage (`pvc`):** PersistentVolumeClaims managing application assets (`pimcore-data`), database storage (`mysql-data`), Redis state, OpenSearch indices, and RabbitMQ queues.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount for Pimcore workloads.

## Prerequisites

- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply pimcore ./pimcore
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	pimcore: {
		appEnv:    "prod"
		appSecret: "ChangeMe123!"
		username:  "admin"
		password:  "AdminPassword123!"
	}
	mysql: {
		auth: {
			database: "pimcore"
			username: "pimcore"
		}
	}
	php: {
		resources: {
			requests: {
				cpu:    "500m"
				memory: "1Gi"
			}
			limits: {
				cpu:    "1000m"
				memory: "2Gi"
			}
		}
	}
	nginx: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "64Mi"
			}
			limits: {
				cpu:    "200m"
				memory: "128Mi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply pimcore ./pimcore \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```shell
timoni -n default delete pimcore
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `pimcore.appEnv` | string | `prod` | Application environment (`prod` or `dev`) |
| `pimcore.appSecret` | string | `ChangeMe123!` | Secret key for encryption and session signing |
| `pimcore.username` | string | `admin` | Initial admin username |
| `pimcore.password` | string | `ChangeMe123!` | Initial admin password |
| `php.image.registry` | string | `pimcore/pimcore` | Container image repository for Pimcore PHP-FPM |
| `php.image.tag` | string | `php8.5-latest` | Container image tag for Pimcore PHP-FPM |
| `php.replicas` | int | `1` | Number of PHP-FPM replicas |
| `php.service.port` | int | `9000` | Port exposed by the PHP-FPM service |
| `nginx.image.registry` | string | `nginx` | Container image repository for Nginx |
| `nginx.image.tag` | string | `stable-alpine` | Container image tag for Nginx |
| `nginx.service.port` | int | `80` | Port exposed by the Nginx service |
| `maintenance.worker.replicas` | int | `1` | Replicas for Symfony Messenger maintenance worker |
| `supervisord.enabled` | bool | `true` | Enable Supervisord worker deployment |
| `supervisord.image.tag` | string | `php8.5-supervisord-5.x` | Image tag for Supervisord |
| `mercure.enabled` | bool | `true` | Enable Mercure real-time hub deployment |
| `mysql.replicas` | int | `1` | Replicas for MariaDB database StatefulSet |
| `mysql.image.tag` | string | `11.4` | Container image tag for MariaDB |
| `redis.replicas` | int | `1` | Replicas for Redis StatefulSet |
| `redis.image.tag` | string | `8.8-alpine` | Container image tag for Redis |
| `opensearch.image` | string | `opensearchproject/opensearch:2.19.6` | Image for OpenSearch StatefulSet |
| `rabbitmq.image` | string | `rabbitmq:4-management` | Image for RabbitMQ StatefulSet |
| `pvc.data.storage` | string | `10Gi` | Storage size for Pimcore persistent data volume |
| `pvc.mysql.storage` | string | `8Gi` | Storage size for MariaDB persistent data volume |
| `pvc.redis.storage` | string | `8Gi` | Storage size for Redis persistent data volume |
| `pvc.opensearch.storage` | string | `5Gi` | Storage size for OpenSearch persistent data volume |
| `pvc.rabbitmq.storage` | string | `5Gi` | Storage size for RabbitMQ persistent data volume |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		fsGroup: 33
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: [
				"ALL",
			]
			add: [
				"NET_BIND_SERVICE",
				"SETGID",
				"SETUID",
			]
		}
	}
}
```

## Additional Resources

- [Official Pimcore Website](https://pimcore.com/)
- [Official Pimcore Repository](https://github.com/pimcore/pimcore)
- [Pimcore Documentation](https://docs.pimcore.com/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Pimcore module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Pimcore PHP-FPM (`pimcore-php`) | Deployment | 11 points | ✅  |
| Pimcore Nginx (`pimcore-nginx`) | Deployment | 9 points | ✅  |
| Maintenance Worker (`pimcore-maintenance-worker`) | Deployment | 11 points | ✅  |
| Supervisord (`pimcore-supervisord`) | Deployment | 11 points | ✅  |
| Mercure Hub (`pimcore-mercure`) | Deployment | 8 points | ✅ |
| MariaDB (`mysql-mariadb`) | StatefulSet | 10 points | ✅  |
| Redis Cache (`redis-master`) | StatefulSet | 10 points | ✅  |
| OpenSearch (`pimcore-opensearch`) | StatefulSet | 11 points | ✅  |
| RabbitMQ (`pimcore-rabbitmq`) | StatefulSet | 11 points | ✅  |
