# Moodle

## Description
[Moodle](https://moodle.org/) is a free, open-source learning management system (LMS) designed to provide educators, administrators, and learners with a single robust, secure, and integrated system to create personalized learning environments. It features course management, interactive assignments, quizzes, gradebooks, collaborative activities, multilingual support, and a rich plugin ecosystem.

## Application Information
- **Version:** `v5.3.0`
- **Official Website:** [https://moodle.org/](https://moodle.org/)
- **Upstream Project:** [https://github.com/moodle/moodle](https://github.com/moodle/moodle)
- **Container Base:**
  - Moodle PHP/Apache Application: [docker.io/moodlehq/moodle-php-apache](https://hub.docker.com/r/moodlehq/moodle-php-apache) (`docker.io/moodlehq/moodle-php-apache:8.4-bookworm@sha256:922af51668352004b4255cdc1f726a63f0cee7c1354eaf66dd8d5f2c7cc379b5`)
  - MariaDB Database: [docker.io/library/mariadb](https://hub.docker.com/_/mariadb) (`docker.io/library/mariadb:11.8`)
  - MySQL Database: [docker.io/library/mysql](https://hub.docker.com/_/mysql) (`docker.io/library/mysql:8.4`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
  - Redis: [docker.io/library/redis](https://hub.docker.com/_/redis) (`docker.io/library/redis:8.10.1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Moodle Application Server (`moodle`):** Primary application workload (`Deployment/moodle`) running `docker.io/moodlehq/moodle-php-apache:8.4-bookworm` with Apache prefork, PHP 8.4 runtime, read-only immutable root filesystem, and background cron / adhoc workers. Includes automated `prepare-code` and `install-database` init containers for code integrity and database bootstrapping.
- **MariaDB Database (`moodle-mariadb`):** Bundled relational database (`StatefulSet/moodle-mariadb`) powered by MariaDB 11.8 with persistent volume storage (`8Gi`), automated database initialization, and credential management.
- **MySQL Database (`moodle-mysql`):** Bundled relational database (`StatefulSet/moodle-mysql`) powered by MySQL 8.4 LTS with persistent volume storage (`8Gi`), automated database initialization, and credential management.
- **PostgreSQL Database (`moodle-postgresql`):** Bundled relational database (`StatefulSet/moodle-postgresql`) powered by PostgreSQL 18.6 with persistent volume storage (`8Gi`), automated schema creation, and database user initialization.
- **Redis Session Cache (`moodle-redis`):** Bundled standalone Redis cache (`StatefulSet/moodle-redis`) powered by Redis 8.10.1 with persistent volume storage (`8Gi`) for centralized session handling and caching across replicas.
- **Maintenance Worker (`moodle-maint-...`):** Optional operator-controlled Job (`Job/moodle-maint-<runId>`) to run database upgrades, environment checks, and cache purging during maintenance windows.
- **Moodle Services (`moodle`, `moodle-mariadb`, `moodle-mariadb-headless`, `moodle-mysql`, `moodle-mysql-headless`, `moodle-postgresql`, `moodle-postgresql-headless`, `moodle-redis-client`, `moodle-redis-headless`):** Internal ClusterIP and Headless services exposing the web application (port 80), database services (ports 3306 / 5432), and Redis session store (port 6379).
- **Persistent Storage:** PersistentVolumeClaims providing dedicated storage for `moodledata` files (`10Gi`), database files (`8Gi`), and Redis cache persistence (`8Gi`).
- **Gateway API HTTPRoute (`gatewayAPI`):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) routing external traffic to the Moodle web service.
- **Secrets:** Automated secret generation for Moodle initial administrator credentials (`moodle-admin`), MariaDB credentials (`moodle-mariadb-auth`), MySQL credentials (`moodle-mysql-auth`), PostgreSQL credentials (`moodle-postgresql-auth`), and Redis passwords (`moodle-redis-auth`).

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` (or `ReadWriteMany` for multi-replica deployments)

## Install

To create an instance using default values:

```shell
timoni -n default apply moodle ./moodle
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	replicaCount: 2
	moodle: {
		wwwroot: "https://moodle.example.com"
	}
	gatewayAPI: {
		enabled: true
		httpRoutes: [{
			hostnames: ["moodle.example.com"]
			parentRefs: [{
				name: "my-gateway"
			}]
		}]
	}
	sessions: {
		enabled: true
	}
	redis: {
		enabled: true
	}
	persistence: {
		accessModes: ["ReadWriteMany"]
	}
	resources: {
		requests: {
			cpu:    "500m"
			memory: "1Gi"
		}
		limits: {
			cpu:    "2000m"
			memory: "2Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply moodle ./moodle \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete moodle
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/moodlehq/moodle-php-apache` | Container image repository for Moodle PHP/Apache runtime |
| `image.tag` | string | `8.4-bookworm` | Pinned container image tag |
| `image.digest` | string | `sha256:922af5166835...` | Container image digest |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `source.mode` | string | `archive` | Code source mode (`archive` or `image`) |
| `source.url` | string | `https://download.moodle.org/download.php/direct/stable502/moodle-5.2.2.tgz` | Moodle release tarball download URL |
| `source.sha256` | string | `72be209e7c...` | SHA-256 digest of source archive |
| `replicaCount` | int | `1` | Number of web replicas (multiple replicas require RWX storage and Redis sessions) |
| `moodle.wwwroot` | string | `http://localhost:8080` | Public URL without trailing slash |
| `moodle.siteName` | string | `Moodle Learning Platform` | Moodle platform site name |
| `moodle.adminUser` | string | `admin` | Initial administrator username |
| `moodle.adminEmail` | string | `admin@example.com` | Administrator contact email |
| `moodle.adminPassword` | string | `""` | Initial administrator bootstrap password (auto-generated if empty) |
| `moodle.existingSecret` | string | `""` | Existing secret containing admin password |
| `database.type` | string | `mariadb` | Database type (`mariadb`, `mysql`, or `postgresql`) |
| `mariadb.enabled` | bool | `true` | Deploy bundled standalone MariaDB database |
| `mariadb.auth.database` | string | `moodle` | MariaDB database name |
| `mariadb.auth.username` | string | `moodle` | MariaDB database username |
| `mysql.enabled` | bool | `false` | Deploy bundled standalone MySQL database |
| `mysql.auth.database` | string | `moodle` | MySQL database name |
| `mysql.auth.username` | string | `moodle` | MySQL database username |
| `postgresql.enabled` | bool | `false` | Deploy bundled standalone PostgreSQL database |
| `postgresql.auth.database` | string | `moodle` | PostgreSQL database name |
| `postgresql.auth.username` | string | `moodle` | PostgreSQL database username |
| `sessions.enabled` | bool | `true` | Enable Redis session management |
| `redis.enabled` | bool | `true` | Deploy bundled standalone Redis cache |
| `persistence.enabled` | bool | `true` | Enable persistent storage for moodledata |
| `persistence.size` | string | `10Gi` | Storage capacity allocated for moodledata |
| `persistence.accessModes` | list | `["ReadWriteOnce"]` | PVC access modes (`ReadWriteMany` for multi-pod scaling) |
| `cron.enabled` | bool | `true` | Run scheduled Moodle background tasks container |
| `adhoc.enabled` | bool | `false` | Enable dedicated ad-hoc task worker |
| `maintenance.enabled` | bool | `false` | Scale web pods to zero and run maintenance job |
| `metrics.enabled` | bool | `false` | Expose private authenticated Prometheus metrics endpoint |
| `gatewayAPI.enabled` | bool | `false` | Enable Gateway API HTTPRoute for external traffic |
| `externalSecrets.enabled` | bool | `false` | Materialize credentials via External Secrets Operator |
| `autoscaling.enabled` | bool | `false` | Enable Horizontal Pod Autoscaling (HPA) |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:           33
		runAsGroup:          33
		runAsNonRoot:        true
		fsGroup:             33
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		runAsUser:                33
		runAsGroup:               33
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official Moodle Website](https://moodle.org/)
- [Official Moodle Repository](https://github.com/moodle/moodle)
- [Moodle Documentation](https://docs.moodle.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Moodle module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Moodle Web Server (`moodle`) | Deployment | 12 points | ✅ |
| MariaDB Database (`moodle-mariadb`) | StatefulSet | 13 points | ✅ |
| MySQL Database (`moodle-mysql`) | StatefulSet | 13 points | ✅ |
| PostgreSQL Database (`moodle-postgresql`) | StatefulSet | 13 points | ✅ |
| Redis Session Cache (`moodle-redis`) | StatefulSet | 13 points | ✅ |
