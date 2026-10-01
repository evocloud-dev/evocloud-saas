# Shlink

## Description
[Shlink](https://shlink.io/) is an open-source, self-hosted URL shortener that lets you shorten URLs, track comprehensive visit analytics, generate customizable QR codes, and manage multi-domain redirects via a rich REST API and web interface.

Built for cloud-native environments, this Timoni module provides a production-ready deployment of both the Shlink backend and the Shlink Web Client, complete with multi-database support (PostgreSQL, MariaDB, MySQL, SQLite), Valkey/Redis caching, Kubernetes Gateway API HTTPRoute routing, and compliance with the restricted Pod Security Standard.

## Application Information
- **Version:** 5.1.6 (Web Client: 4.8.1)
- **Official Website:** [https://shlink.io/](https://shlink.io/)
- **Upstream Project:** [https://github.com/shlinkio/shlink](https://github.com/shlinkio/shlink)
- **Container Base:**
  - Shlink Backend: [docker.io/shlinkio/shlink](https://hub.docker.com/r/shlinkio/shlink) (`shlinkio/shlink:5.1.6`)
  - Shlink Web Client: [docker.io/shlinkio/shlink-web-client](https://hub.docker.com/r/shlinkio/shlink-web-client) (`shlinkio/shlink-web-client:4.8.1`)
  - PostgreSQL Database: [docker.io/bitnamilegacy/postgresql](https://hub.docker.com/r/bitnamilegacy/postgresql) (`bitnamilegacy/postgresql:17.6.0-debian-12-r4`)
  - Redis / Valkey Cache: [docker.io/bitnamilegacy/redis](https://hub.docker.com/r/bitnamilegacy/redis) (`bitnamilegacy/redis:8.2.1-debian-12-r0`)
  - MySQL Database: [docker.io/bitnamilegacy/mysql](https://hub.docker.com/r/bitnamilegacy/mysql) (`bitnamilegacy/mysql:9.4.0-debian-12-r1`)
  - MariaDB Database: [docker.io/bitnamilegacy/mariadb](https://hub.docker.com/r/bitnamilegacy/mariadb) (`bitnamilegacy/mariadb:12.0.2-debian-12-r0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Shlink Core Backend (`shlink`):** High-performance PHP/Swoole application server running `shlinkio/shlink:5.1.6` on port 8080, handling URL shortening, redirect resolution, QR code rendering, and REST API endpoints.
- **Shlink Web Client (`shlink-web`):** Modern React single-page frontend application running `shlinkio/shlink-web-client:4.8.1` on port 80 for managing links, domains, and analytics.
- **PostgreSQL Database (`shlink-postgresql`):** Dedicated relational database StatefulSet (`bitnamilegacy/postgresql:17.6.0-debian-12-r4`) managing links, tags, and visit logs with persistent storage.
- **Redis Cache (`shlink-redis`):** In-memory key-value cache StatefulSet (`bitnamilegacy/redis:8.2.1-debian-12-r0`) accelerating redirect caching and visit rate limiting.
- **MySQL Database (`shlink-mysql`):** Optional relational database StatefulSet (`bitnamilegacy/mysql:9.4.0-debian-12-r1`).
- **MariaDB Database (`shlink-mariadb`):** Optional relational database StatefulSet (`bitnamilegacy/mariadb:12.0.2-debian-12-r0`).
- **RabbitMQ Message Broker (`shlink-rabbitmq`):** Optional message broker StatefulSet (`bitnamilegacy/rabbitmq:4.1.3-debian-12-r1`).
- **Gateway API HTTPRoute (`route`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resources routing incoming traffic to backend and frontend services.
- **HorizontalPodAutoscaler (`hpa`, `web-hpa`):** Automatically scales backend and web replicas based on CPU load.
- **Kubernetes Services:** Dedicated ClusterIP services exposing the backend (port 8080), web frontend (port 80), and database/cache ports.
- **ServiceAccounts:** Dedicated unprivileged ServiceAccounts for both backend and web client.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a Gateway controller (e.g. Envoy Gateway) if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply shlink ./shlink-backend
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	config: {
		general: {
			defaultDomain: "short.example.com"
			initialApiKey: "your-strong-api-key-here"
			isHttpsEnabled: true
		}
	}
	postgresql: {
		enabled: true
		auth: {
			database: "shlink"
			username: "shlink"
			password: "your-strong-db-password"
		}
	}
	redis: {
		enabled: true
	}
	web: {
		enabled: true
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply shlink ./shlink-backend \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete shlink
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.registry` | string | `docker.io` | Container image registry for Shlink backend |
| `image.repository` | string | `shlinkio/shlink` | Container image repository for Shlink backend |
| `image.tag` | string | `5.1.6` | Container image tag for Shlink backend |
| `image.pullPolicy` | string | `Always` | Image pull policy |
| `replicaCount` | int | `1` | Backend pod replica count |
| `service.port` | int | `8080` | ClusterIP service port for Shlink backend |
| `route.main.enabled` | bool | `true` | Enable Gateway API HTTPRoute for backend |
| `resources.requests.cpu` | string | `100m` | CPU request for backend |
| `resources.requests.memory` | string | `128Mi` | Memory request for backend |
| `resources.limits.cpu` | string | `2` | CPU limit for backend |
| `resources.limits.memory` | string | `2Gi` | Memory limit for backend |
| `autoscaling.enabled` | bool | `true` | Enable backend horizontal pod autoscaling |
| `config.general.defaultDomain` | string | `localhost:8080` | Default domain used for short URL generation |
| `config.general.initialApiKey` | string | `my-super-secret-api-key` | Initial API key for administrative authentication |
| `config.general.isHttpsEnabled` | bool | `false` | Enable HTTPS links generation in redirects |
| `config.redirects.cacheLifetime` | int | `30` | Redirect cache lifetime in seconds |
| `config.redirects.statusCode` | int | `302` | HTTP redirect status code (`301`, `302`, `307`, `308`) |
| `config.trackingVisits.anonymizeRemoteAddr` | bool | `true` | Anonymize visitor IP addresses for GDPR compliance |
| `config.urlShortening.defaultShortCodesLength` | int | `5` | Generated short code character length |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL StatefulSet |
| `postgresql.image.repository` | string | `bitnamilegacy/postgresql` | PostgreSQL image repository |
| `postgresql.image.tag` | string | `17.6.0-debian-12-r4` | PostgreSQL image tag |
| `redis.enabled` | bool | `true` | Deploy internal Valkey/Redis StatefulSet |
| `redis.image.repository` | string | `bitnamilegacy/redis` | Redis image repository |
| `redis.image.tag` | string | `8.2.1-debian-12-r0` | Redis image tag |
| `mysql.enabled` | bool | `false` | Deploy internal MySQL StatefulSet |
| `mariadb.enabled` | bool | `false` | Deploy internal MariaDB StatefulSet |
| `web.enabled` | bool | `true` | Deploy Shlink Web Client frontend |
| `web.image.repository` | string | `shlinkio/shlink-web-client` | Web Client image repository |
| `web.image.tag` | string | `4.8.1` | Web Client image tag |
| `web.service.port` | int | `80` | ClusterIP service port for Web Client |
| `web.resources.requests.cpu` | string | `50m` | CPU request for Web Client |
| `web.resources.requests.memory` | string | `64Mi` | Memory request for Web Client |
| `podSecurityContext.runAsNonRoot` | bool | `true` | Enforce running pods as non-root user |
| `podSecurityContext.runAsUser` | int | `10001` | Non-root user ID |
| `podSecurityContext.runAsGroup` | int | `10001` | Non-root group ID |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent container privilege escalation |
| `securityContext.readOnlyRootFilesystem` | bool | `true` | Mount container root filesystem as read-only |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Drop all Linux kernel capabilities |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    10001
		runAsGroup:   10001
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		runAsNonRoot:           true
		runAsUser:              10001
		runAsGroup:             10001
		readOnlyRootFilesystem: true
		capabilities: drop: [
			"ALL",
		]
	}
}
```

## Additional Resources
- [Official Shlink Website](https://shlink.io/)
- [Official Shlink Repository](https://github.com/shlinkio/shlink)
- [Shlink Documentation](https://shlink.io/documentation/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Shlink module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Shlink Core Backend (`shlink`) | Deployment | 13 points | ✅ |
| Shlink Web Client (`shlink-web`) | Deployment | 13 points | ✅ |
| PostgreSQL Database (`shlink-postgresql`) | StatefulSet | 10 points | ✅ |
| Redis Cache (`shlink-redis`) | StatefulSet | 10 points | ✅ |
| MySQL Database (`shlink-mysql`) | StatefulSet | 10 points | ✅ |
| MariaDB Database (`shlink-mariadb`) | StatefulSet | 10 points | ✅ |
| RabbitMQ Message Broker (`shlink-rabbitmq`) | StatefulSet | 10 points | ✅ |

