# Invoice Ninja

## Description
[Invoice Ninja](https://invoiceninja.com/) is a leading open-source invoicing, billing, payment processing, and time-tracking platform built for freelancers, agencies, and small-to-medium enterprises. Powered by Laravel and Flutter, it empowers businesses to generate professional invoices and quotes, accept payments across 30+ gateway integrations (including Stripe and PayPal), track billable tasks and expenses, manage client projects, and automate recurring subscriptions.

## Application Information
- **Version:** `5.13.33`
- **Upstream Project:** [https://github.com/invoiceninja/invoiceninja](https://github.com/invoiceninja/invoiceninja)
- **Container Base:** [invoiceninja/invoiceninja-debian](https://hub.docker.com/r/invoiceninja/invoiceninja-debian) (`invoiceninja/invoiceninja-debian:5.13.33`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Invoice Ninja Application Core (`invoice-app`):** Primary backend Deployment running `invoiceninja/invoiceninja-debian:5.13.33` on FastCGI port `9000`. Handles business logic, PDF invoice generation (via snappdf), database migrations, and background queue workers. Includes an init container (`busybox:1.37`) ensuring database and cache availability before application startup.
- **Invoice Ninja NGINX Web Server (`invoice-nginx`):** Reverse proxy Deployment running unprivileged `nginxinc/nginx-unprivileged:alpine` on container port `8080`, exposed via ClusterIP Service port `80`. Routes incoming HTTP/HTTPS traffic to the application FastCGI server and serves public assets.
- **MariaDB Database (`invoice-mysql`):** Relational database Deployment running `mariadb:lts` on port `3306` with persistent storage for company data, client details, invoices, and payment histories.
- **Redis In-Memory Cache (`invoice-redis`):** High-speed in-memory datastore Deployment running `redis:alpine` on port `6379` managing application caching, session states, and asynchronous queue execution.
- **Persistent Storage:**
  - **Public Assets (`appPublic`):** Persistent Volume Claim (`1Gi`) mounted to `/var/www/app/public` storing public uploads and client-accessible assets.
  - **Application Documents (`appStorage`):** Persistent Volume Claim (`5Gi`) mounted to `/var/www/app/storage` storing generated invoice PDFs, system cache, and private attachments.
  - **MariaDB Data (`mysqlData`):** Persistent Volume Claim (`10Gi`) mounted to `/var/lib/mysql` for database persistence.
  - **Redis Data (`redisData`):** Persistent Volume Claim (`1Gi`) mounted to `/data` for Redis state persistence.
- **Kubernetes Services:**
  - `invoice-nginx`: Primary entrypoint Service exposing HTTP on port `80` (target port `8080`).
  - `invoice-app`: Backend Service exposing FastCGI port `9000`.
  - `invoice-mysql`: Database Service exposing port `3306`.
  - `invoice-redis`: Cache Service exposing port `6379`.
- **ConfigMaps & Secrets:**
  - `invoice-config`: Application runtime environment configurations and parameters.
  - `invoice-nginx`: NGINX configuration templates routing traffic to FastCGI.
  - `invoice-secret`: Cryptographic application key (`APP_KEY`), database passwords, Redis authentication, and default admin credentials.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support (or `ReadWriteMany` when scaling application or web server replicas)
- Reverse proxy or LoadBalancer for external HTTPS access

## Install

To create an instance using default values:

```shell
timoni -n default apply invoiceninja ./invoiceninja
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	env: {
		appUrl: "https://invoicing.example.com"
	}
	secret: {
		appKey:         "base64:YOUR_GENERATED_32_BYTE_KEY_HERE"
		dbPassword:     "secure-database-password"
		dbRootPassword: "secure-root-password"
		redisPassword:  "secure-redis-password"
		inUserEmail:    "admin@example.com"
		inPassword:     "StrongAdminPassword123!"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply invoiceninja ./invoiceninja \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete invoiceninja
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | `string` | `""` | Override the release name |
| `fullnameOverride` | `string` | `""` | Override the fully qualified release name |
| `app.image.repository` | `string` | `"invoiceninja/invoiceninja-debian"` | Invoice Ninja application image repository |
| `app.image.tag` | `string` | `"5.13.33"` | Invoice Ninja application image tag |
| `app.image.pullPolicy` | `string` | `"IfNotPresent"` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `app.busyboxTag` | `string` | `"1.37"` | Busybox image tag for the init wait container |
| `app.replicaCount` | `int` | `1` | Number of application replicas (requires RWX storage if > 1) |
| `app.resources` | `corev1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1000m", memory: "1Gi"}}` | Application container resource requests and limits |
| `app.podSecurityContext` | `corev1.#PodSecurityContext` | `{seccompProfile: {type: "RuntimeDefault"}}` | Pod security context for Invoice Ninja application |
| `app.securityContext` | `corev1.#SecurityContext` | *(drops ALL, adds SETUID/SETGID/CHOWN for supervisord)* | Container security context for application |
| `app.initSecurityContext` | `corev1.#SecurityContext` | `{runAsNonRoot: true, runAsUser: 65510, capabilities: {drop: ["ALL"]}}` | Security context for init wait container |
| `nginx.image.repository` | `string` | `"nginxinc/nginx-unprivileged"` | NGINX web server image repository |
| `nginx.image.tag` | `string` | `"alpine"` | NGINX web server image tag |
| `nginx.replicaCount` | `int` | `1` | Number of NGINX web server replicas |
| `nginx.containerPort` | `int` | `8080` | Internal listen port for unprivileged NGINX |
| `nginx.service.type` | `string` | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `nginx.service.port` | `int` | `80` | External Service HTTP port |
| `nginx.resources` | `corev1.#ResourceRequirements` | `{requests: {cpu: "50m", memory: "64Mi"}, limits: {cpu: "500m", memory: "128Mi"}}` | NGINX container resource requests and limits |
| `nginx.podSecurityContext` | `corev1.#PodSecurityContext` | `{seccompProfile: {type: "RuntimeDefault"}}` | Pod security context for NGINX |
| `nginx.securityContext` | `corev1.#SecurityContext` | `{runAsNonRoot: true, runAsUser: 101, capabilities: {drop: ["ALL"]}}` | Container security context for unprivileged NGINX |
| `mysql.image.repository` | `string` | `"mariadb"` | MariaDB container image repository |
| `mysql.image.tag` | `string` | `"lts"` | MariaDB container image tag |
| `mysql.service.port` | `int` | `3306` | MariaDB Service port |
| `mysql.resources` | `corev1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1000m", memory: "512Mi"}}` | MariaDB container resource requests and limits |
| `mysql.podSecurityContext` | `corev1.#PodSecurityContext` | `{seccompProfile: {type: "RuntimeDefault"}}` | Pod security context for database |
| `mysql.securityContext` | `corev1.#SecurityContext` | `{runAsNonRoot: true, runAsUser: 999, runAsGroup: 999, capabilities: {drop: ["ALL"]}}` | Container security context for MariaDB |
| `redis.image.repository` | `string` | `"redis"` | Redis container image repository |
| `redis.image.tag` | `string` | `"alpine"` | Redis container image tag |
| `redis.service.port` | `int` | `6379` | Redis Service port |
| `redis.resources` | `corev1.#ResourceRequirements` | `{requests: {cpu: "50m", memory: "64Mi"}, limits: {cpu: "500m", memory: "128Mi"}}` | Redis container resource requests and limits |
| `redis.podSecurityContext` | `corev1.#PodSecurityContext` | `{seccompProfile: {type: "RuntimeDefault"}}` | Pod security context for Redis |
| `redis.securityContext` | `corev1.#SecurityContext` | `{runAsNonRoot: true, runAsUser: 999, runAsGroup: 999, capabilities: {drop: ["ALL"]}}` | Container security context for Redis |
| `persistence.appPublic.enabled` | `bool` | `true` | Enable persistent storage for public media assets |
| `persistence.appPublic.size` | `string` | `"1Gi"` | PVC size for public media storage |
| `persistence.appStorage.enabled` | `bool` | `true` | Enable persistent storage for documents and invoices |
| `persistence.appStorage.size` | `string` | `"5Gi"` | PVC size for application storage |
| `persistence.mysqlData.enabled` | `bool` | `true` | Enable persistent storage for MariaDB |
| `persistence.mysqlData.size` | `string` | `"10Gi"` | PVC size for database storage |
| `persistence.redisData.enabled` | `bool` | `true` | Enable persistent storage for Redis data |
| `persistence.redisData.size` | `string` | `"1Gi"` | PVC size for Redis storage |
| `serviceAccount.create` | `bool` | `false` | Create a dedicated ServiceAccount |
| `secret.appKey` | `string` | `base64:...` | Base64-encoded application encryption key |
| `secret.dbPassword` | `string` | `"ninja"` | Database password for application user |
| `secret.dbRootPassword` | `string` | `"ninjaAdm1nPassword"` | Database root administrator password |
| `secret.redisPassword` | `string` | `"Redis_password"` | Redis authentication password |
| `secret.inUserEmail` | `string` | `"admin@example.com"` | Initial administrator email address |
| `secret.inPassword` | `string` | `"changeme!"` | Initial administrator login password |
| `env.appUrl` | `string` | `"http://localhost"` | Fully qualified public application URL |
| `env.appEnv` | `string` | `"production"` | Application runtime environment |
| `env.trustedProxies` | `string` | `"*"` | CIDR range for trusted reverse proxies |
| `env.mailMailer` | `string` | `"log"` | Mail driver (`smtp`, `log`, etc.) |

### Recommended values

Security contexts configured in `values.cue` per workload:

```cue
values: {
	app: {
		podSecurityContext: {
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
			runAsNonRoot:             false
			capabilities: {
				add: [
					"SETGID",
					"SETUID",
					"DAC_OVERRIDE",
					"FOWNER",
					"CHOWN",
				]
				drop: [
					"ALL",
				]
			}
		}
	}
	nginx: {
		podSecurityContext: {
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			runAsNonRoot:             true
			runAsUser:                101
			capabilities: {
				drop: [
					"ALL",
				]
			}
		}
	}
}
```

## Additional Resources
- [Official Invoice Ninja Website](https://invoiceninja.com/)
- [Official Invoice Ninja Repository](https://github.com/invoiceninja/invoiceninja)
- [Invoice Ninja Documentation](https://invoiceninja.github.io/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Invoice Ninja module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Invoice Ninja Application Core (`invoice-app`) | Deployment | 12 points | ✅ |
| Invoice Ninja NGINX Web Server (`invoice-nginx`) | Deployment | 11 points | ✅ |
| MariaDB Database (`invoice-mysql`) | Deployment | 11 points | ✅ |
| Redis In-Memory Cache (`invoice-redis`) | Deployment | 11 points | ✅ |
