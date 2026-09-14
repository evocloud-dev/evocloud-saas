# HumHub

## Description
HumHub is an open-source, flexible, and feature-rich social network and collaboration platform built with PHP and the Yii framework. It is designed to facilitate communication, information sharing, project coordination, and teamwork within organizations, communities, and enterprises. Featuring customizable "Spaces", activity streams, rich directory search, granular access control, and an extensive module marketplace, HumHub enables teams to build tailored social intranets and interactive portals. It is a strong open-source alternative to Facebook. 

## Application Information
- **Version**: `1.17.2`
- **Upstream Project**: [https://github.com/humhub/humhub](https://github.com/humhub/humhub)
- **Container Base**: [https://github.com/mriedmann/humhub-docker](https://github.com/mriedmann/humhub-docker)
- **Deployment Type**: Timoni Module / Kubernetes Cloud-Native Application

## Components
- **HumHub PHP-FPM Application Core (`main`)**: FastCGI application server running `ghcr.io/mriedmann/humhub-phponly:1.17.2` on port `9000`. Executes the HumHub backend, processes business logic, handles database migrations, executes background cron jobs, and serves dynamic requests.
- **HumHub NGINX Web Server (`nginx`)**: Reverse proxy and static file server running `ghcr.io/mriedmann/humhub-nginx:1.17.2` on service port `8080` (container port `80`). Proxies dynamic requests to PHP-FPM via FastCGI and directly serves static assets (CSS, JavaScript, media files).
- **MariaDB Database**: Relational storage tier running `docker.io/bitnamisecure/mariadb:latest`. Supports automated provisioning via an embedded internal instance or connection to an external MariaDB/MySQL cluster.
- **Redis / Valkey**: High-performance in-memory datastore running `docker.io/bitnamisecure/valkey:latest`. Powers HumHub's async task queue (`humhub\modules\queue\driver\Redis`) and application cache (`yii\redis\Cache`).
- **Persistent Storage**:
  - **`config`**: Mounts to `/var/www/localhost/htdocs/protected/config` to store dynamic runtime configuration and install tokens.
  - **`assets`**: Mounts to `/var/www/localhost/htdocs/assets` (shared between PHP-FPM and NGINX) for compiled frontend assets.
  - **`uploads`**: Mounts to `/var/www/localhost/htdocs/uploads` (shared between PHP-FPM and NGINX) for persistent storage of user uploads, avatars, attachments, and media files.
  - **`modules`** *(optional)*: Mounts to `/var/www/localhost/htdocs/protected/modules` for persistent marketplace and third-party modules.
  - **`themes`** *(optional, default disabled)*: Mounts to `/var/www/localhost/htdocs/themes`. Should only be enabled when pre-populating custom themes; keep disabled to preserve the built-in HumHub default theme.

## Prerequisites
- Kubernetes cluster v1.20+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support (or `ReadWriteMany` if scaling workloads across nodes)
- Ingress Controller (e.g. Traefik, NGINX Ingress, or Envoy Gateway) for external HTTPS access

## Install

To create an instance using the default values:

```shell
timoni -n default apply humhub oci://<container-registry-url>
```

To change the [default configuration](#configuration),
create one or more `values.cue` files and apply them to the instance.

For example, create a file `my-values.cue` with the following content:

```cue
values: {
	resources: requests: {
		cpu:    "100m"
		memory: "128Mi"
	}
}
```

And apply the values with:

```shell
timoni -n default apply humhub oci://<container-registry-url> \
--values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete humhub
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | `string` | `ghcr.io/mriedmann/humhub-phponly` | Container image repository for HumHub PHP-FPM core |
| `image.tag` | `string` | `<latest version>` | Container image tag for HumHub PHP-FPM core |
| `image.pullPolicy` | `string` | `IfNotPresent` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `nginxImage.repository` | `string` | `ghcr.io/mriedmann/humhub-nginx` | Container image repository for HumHub NGINX web server |
| `nginxImage.tag` | `string` | `<latest version>` | Container image tag for HumHub NGINX web server |
| `nginxImage.pullPolicy` | `string` | `IfNotPresent` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `humhub.host` | `string` | `localhost:8080` | Fully-qualified domain name or host exposed to end users |
| `humhub.proto` | `string` | `http` | External access protocol (`http` or `https`) |
| `humhub.admin.login` | `string` | `admin` | Initial administrator username |
| `humhub.admin.password` | `string` | `test` | Initial administrator password |
| `humhub.admin.email` | `string` | `humhub@example.com` | Administrator email address |
| `humhub.mailer.hostname` | `string` | `""` | SMTP mail server hostname |
| `humhub.mailer.port` | `int` | `1025` | SMTP mail server port |
| `humhub.nginx.max_client_body_size` | `string` | `10m` | Maximum client body size for file uploads |
| `service.main.ports.main.port` | `int` | `8080` | External HTTP service port for NGINX |
| `service.backend.ports.backend.port` | `int` | `9000` | Internal FastCGI backend service port |
| `mariadb.enabled` | `bool` | `true` | Deploy internal embedded MariaDB instance |
| `mariadb.host` | `string` | `""` | External MariaDB host (when `mariadb.enabled` is `false`) |
| `mariadb.mariadbUsername` | `string` | `humhub` | Database username |
| `mariadb.mariadbDatabase` | `string` | `humhub` | Database name |
| `mariadb.password` | `string` | `humhub` | Database user password |
| `redis.enabled` | `bool` | `true` | Deploy internal embedded Valkey/Redis instance |
| `redis.host` | `string` | `""` | External Redis host (when `redis.enabled` is `false`) |
| `redis.password` | `string` | `humhubredis` | Redis authentication password |
| `resources.requests.cpu` | `string` | `75m` | Main container requested CPU |
| `resources.requests.memory` | `string` | `200Mi` | Main container requested memory |
| `resources.limits.cpu` | `string` | `1500m` | Main container CPU limit |
| `resources.limits.memory` | `string` | `2400Mi` | Main container memory limit |
| `persistence.config.enabled` | `bool` | `true` | Enable persistent volume for HumHub configuration |
| `persistence.config.size` | `string` | `100Gi` | Size of config persistent volume claim |
| `persistence.assets.enabled` | `bool` | `true` | Enable persistent volume for compiled static assets |
| `persistence.assets.size` | `string` | `100Gi` | Size of assets persistent volume claim |
| `persistence.uploads.enabled` | `bool` | `true` | Enable persistent volume for user-uploaded media |
| `persistence.uploads.size` | `string` | `100Gi` | Size of uploads persistent volume claim |
| `persistence.modules.enabled` | `bool` | `true` | Enable persistent volume for custom/marketplace modules |
| `persistence.themes.enabled` | `bool` | `false` | Enable persistent volume for custom themes (keep `false` for default theme) |
| `nodeSelector` | `{[string]: string}` | `kubernetes.io/arch: amd64` | Node selector labels for pod scheduling |
| `podAnnotations` | `{[string]: string}` | `{}` | Annotations applied to pods |
| `test.enabled` | `bool` | `false` | Run end-to-end tests at install and upgrades |

#### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:  65532
		runAsGroup: 65532
		fsGroup:    65532
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}
}
```

> [!NOTE]
> In environments with strict Pod Security Standards enforcing unprivileged non-root IDs (`65532`), ensure persistent volume permissions are pre-aligned with cluster policies. By default, the upstream HumHub container image initiates filesystem permissions under `UID 0` before running unprivileged application workers.

## Changelog
This changelog tracks version updates, image refreshes, security patches, and structural enhancements to the HumHub Timoni module:

### [1.17.2] - 2026-09-14
- **Engine Update**: Upgraded HumHub core to upstream version `1.17.2` (`ghcr.io/mriedmann/humhub-phponly:1.17.2` and `ghcr.io/mriedmann/humhub-nginx:1.17.2`).
- **Database & Cache Refresh**: Updated MariaDB (`docker.io/bitnamisecure/mariadb`) and Redis/Valkey (`docker.io/bitnamisecure/valkey`) to secured, digest-pinned images.
- **Theme Persistence Fix**: Set `persistence.themes.enabled` to `false` by default to prevent masking HumHub's pre-installed default theme with an empty volume.
- **Health Probes**: Configured standard FastCGI healthchecks (`/usr/local/bin/php-fpm-healthcheck`) and NGINX `/ping` liveness/readiness probes.
- **Security Validation**: Validated all manifests through Kubesec, achieving passing scores across all Deployments and StatefulSets.

## Additional Resources
- [DEVELOPMENT.MD](./DEVELOPMENT.MD) - Development guidelines, local testing, and packaging procedures
- [Official HumHub Documentation](https://docs.humhub.org/)
- [Timoni Documentation](https://timoni.sh)

### Kubesec Scan Scores
Security validation performed via [Kubesec](https://kubesec.io) static analysis across the HumHub module's Deployments and StatefulSets:

| Workload | Kind | Kubesec Score | Status |
|---|---|:---:|:---:|
| **HumHub PHP-FPM (`main`)** | `Deployment` | **12 / 12** | ✅ |
| **HumHub NGINX (`nginx`)** | `Deployment` | **12 / 12** | ✅ |
| **MariaDB (`mariadb`)** | `Deployment` | **10 / 10** | ✅ |
| **Redis / Valkey (`redis`)** | `StatefulSet` | **12 / 12** | ✅ |

