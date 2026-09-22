# Drupal WxT

## Description
[Drupal WxT](https://drupalwxt.github.io/) is an open-source web content management distribution built on Drupal and the Web Experience Toolkit (WxT) to assist in building and maintaining multilingual, accessible, usable, and interoperable enterprise web platforms.

## Application Information
- **Version:** WxT 6.1.4 
- **Official Website:** [https://drupalwxt.github.io/](https://drupalwxt.github.io/)
- **Upstream Project:** [https://github.com/drupalwxt/wxt](https://github.com/drupalwxt/wxt)
- **Container Base:** [drupalwxt/site-wxt](https://hub.docker.com/r/drupalwxt/site-wxt) (`drupalwxt/site-wxt:6.1.4`, `drupalwxt/site-wxt:6.1.4-nginx`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Drupal Core Application (`drupal`):** PHP-FPM application container (`drupalwxt/site-wxt:6.1.4`) executing the Drupal application runtime on port 9000.
- **NGINX Web Server (`drupal-nginx`):** Frontend reverse proxy and static asset server (`drupalwxt/site-wxt:6.1.4-nginx`) serving incoming HTTP/HTTPS traffic on ports 8080 and 8443.
- **Varnish HTTP Cache (`drupal-varnish`):** High-performance reverse HTTP proxy accelerator (`varnish:9.0.3`) handling edge caching and header normalization on port 8080.
- **PostgreSQL Database (`drupal-postgresql`):** Dedicated relational database workload (`bitnamilegacy/postgresql:16`) for site data and module content.
- **MySQL Database (`drupal-mysql`):** Dedicated relational database workload (`bitnamilegacy/mysql:8.0`) serving as an alternative database engine on port 3306.
- **Redis In-Memory Cache (`drupal-redis`):** In-memory key-value data store (`bitnamilegacy/redis:7.0`) on port 6379 for backend caching and session management.
- **Apache Solr Search (`drupal-solr`):** Enterprise search engine server (`bitnamilegacy/solr:9.2.1-debian-11-r73`) on port 8983 providing full-text and faceted search capabilities.
- **ServiceAccount (`drupal`):** Dedicated unprivileged Kubernetes ServiceAccount applied across Drupal module workloads.
- **Persistent Storage Volumes:** Dedicated persistent volume claims for Drupal file uploads (`sites/default/files`), database persistence, Solr indexes, and cache directories.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Ingress controller (e.g., Ingress-NGINX, Traefik) if external routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply drupal ./drupal-timoni/drupal-app
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	drupal: {
		siteName:  "My Custom Drupal Site"
		siteEmail: "admin@example.com"
		username:  "admin"
		password:  "AdminPassword123!"
		resources: {
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1500m"
				memory: "1536Mi"
			}
		}
	}
	ingress: {
		enabled:   true
		className: "nginx"
		hosts: [
			"drupal.example.com",
		]
	}
}
```

Apply the custom values to the instance:

```shell
timoni -n default apply drupal ./drupal-timoni/drupal-app \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```shell
timoni -n default delete drupal
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `drupal.image` | string | `"drupalwxt/site-wxt"` | Drupal core PHP-FPM container image repository |
| `drupal.tag` | string | `"6.1.4"` | Drupal core container image tag |
| `drupal.replicas` | int | `1` | Number of Drupal application replicas |
| `drupal.siteName` | string | `"Drupal Install Profile (WxT)"` | Site title configured during installation |
| `drupal.username` | string | `"admin"` | Initial administrator username |
| `drupal.password` | string | `"admin"` | Initial administrator password |
| `drupal.resources.requests.cpu` | string | `"200m"` | CPU request for Drupal core container |
| `drupal.resources.requests.memory` | string | `"512Mi"` | Memory request for Drupal core container |
| `drupal.resources.limits.cpu` | string | `"1500m"` | CPU limit for Drupal core container |
| `drupal.resources.limits.memory` | string | `"1536Mi"` | Memory limit for Drupal core container |
| `drupal.persistence.enabled` | bool | `true` | Enable persistent storage for Drupal files |
| `drupal.persistence.size` | string | `"8Gi"` | Persistent storage capacity for Drupal uploads |
| `nginx.image` | string | `"drupalwxt/site-wxt"` | NGINX container image repository |
| `nginx.tag` | string | `"6.1.4-nginx"` | NGINX container image tag |
| `nginx.replicas` | int | `1` | Number of NGINX reverse proxy replicas |
| `varnish.enabled` | bool | `true` | Deploy Varnish reverse proxy cache |
| `varnish.varnishd.image` | string | `"varnish"` | Varnish container image repository |
| `varnish.varnishd.tag` | string | `"9.0.3"` | Varnish container image tag |
| `varnish.memorySize` | string | `"100M"` | In-memory cache allocated for Varnish |
| `mysql.enabled` | bool | `true` | Deploy dedicated MySQL database instance |
| `mysql.image.repository` | string | `"bitnamilegacy/mysql"` | MySQL container image repository |
| `mysql.image.tag` | string | `"8.0"` | MySQL container image tag |
| `mysql.auth.database` | string | `"wxt"` | Initial MySQL database name |
| `mysql.auth.username` | string | `"wxt"` | Initial MySQL database username |
| `mysql.primary.persistence.size` | string | `"128Gi"` | Persistent volume storage requested for MySQL |
| `postgresql.enabled` | bool | `false` | Deploy dedicated PostgreSQL database instance |
| `postgresql.image.repository` | string | `"bitnamilegacy/postgresql"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"16"` | PostgreSQL container image tag |
| `postgresql.auth.database` | string | `"wxt"` | Initial PostgreSQL database name |
| `postgresql.auth.username` | string | `"wxt"` | Initial PostgreSQL database user |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis cache instance |
| `redis.image.repository` | string | `"bitnamilegacy/redis"` | Redis container image repository |
| `redis.image.tag` | string | `"7.0"` | Redis container image tag |
| `solr.enabled` | bool | `true` | Deploy dedicated Apache Solr search server |
| `solr.image.repository` | string | `"bitnamilegacy/solr"` | Apache Solr container image repository |
| `solr.image.tag` | string | `"9.2.1-debian-11-r73"` | Apache Solr container image tag |
| `solr.persistence.size` | string | `"8Gi"` | Persistent volume storage requested for Solr |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress routing |
| `ingress.className` | string | `""` | Ingress controller class name |

## Recommended values

Drupal WxT and NGINX workloads comply with the restricted Kubernetes Pod Security Standard by running as the unprivileged `www-data` user (`33:33`), mounting a read-only root filesystem (`readOnlyRootFilesystem: true`), dropping all Linux capabilities (`drop: ["ALL"]`), setting `allowPrivilegeEscalation: false`, and applying a default seccomp profile:

```cue
values: {
	drupal: {
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   true
			runAsNonRoot:             true
			runAsUser:                33
			capabilities: drop: ["ALL"]
		}
		podSecurityContext: {
			fsGroup:        33
			runAsUser:      33
			runAsGroup:     33
			runAsNonRoot:   true
			seccompProfile: type: "RuntimeDefault"
		}
	}
}
```

## Additional Resources
- [Official Drupal WxT Website](https://drupalwxt.github.io/)
- [Drupal WxT Documentation](https://drupalwxt.github.io/docs/)
- [Drupal WxT GitHub Repository](https://github.com/drupalwxt/wxt)
- [Official Drupal Website](https://www.drupal.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Drupal module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Drupal Core Application (`drupal`) | Deployment | 12 points | ✅ |
| NGINX Web Server (`drupal-nginx`) | Deployment | 12 points | ✅ |
| Varnish HTTP Cache (`drupal-varnish`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`drupal-postgresql`) | Deployment | 12 points | ✅ |
| Redis Cache & Queue (`drupal-redis`) | Deployment | 12 points | ✅ |
| Apache Solr Search (`drupal-solr`) | Deployment | 12 points | ✅  |
| MySQL Database (`drupal-mysql`) | Deployment | 10 points | ✅ | 
