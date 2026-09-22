# Automatisch

## Description
[Automatisch](https://automatisch.io/) is a business automation tool that lets you connect different services like Twitter, Slack, and [more](https://automatisch.io/docs/guide/available-apps) to automate your business processes. It is designed to help streamline your workflows by integrating the different services you use without requiring any programming knowledge.

> [!NOTE]
> On first boot, you can use `user@automatisch.io` with password `sample` to log in to Automatisch. Please change your email and password immediately from the Settings page after initial deployment.

## Application Information
- **Version:** 0.15.0
- **Upstream Project:** [https://github.com/automatisch/automatisch](https://github.com/automatisch/automatisch)
- **Container Base:** [docker.io/automatischio/automatisch](https://hub.docker.com/r/automatischio/automatisch) (`docker.io/automatischio/automatisch:0.15.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Automatisch Core (`deploy`):** Primary web and API server running `docker.io/automatischio/automatisch:0.15.0` on port 3000, with an init container that verifies database connectivity prior to startup.
- **Application Secret (`appSecret`):** Securely stores the cryptographic `ENCRYPTION_KEY`, `APP_SECRET_KEY`, and `WEBHOOK_SECRET_KEY` required by Automatisch to protect encrypted credentials and sign outgoing webhooks.
- **PostgreSQL Subchart (`pgDeploy`, `pgSVC`, `pgHeadlessSVC`, `pgSecret`):** Dedicated PostgreSQL 18 StatefulSet (`docker.io/library/postgres:18.6-trixie`) with persistent volume storage (`8Gi`), headless service, and automated secret generation.
- **Redis Subchart (`redisDeploy`, `redisSVC`, `redisHeadlessSVC`):** Dedicated Redis 8 StatefulSet (`docker.io/library/redis:8.8.2`) managing message broker queues and caching with persistent volume storage (`8Gi`).
- **Kubernetes Service (`svc`):** ClusterIP service exposing port 80 (named `http`) routing internally to container port 3000.
- **Ingress (`ingress`):** Optional Ingress resource routing traffic from your cluster ingress controller (e.g. Traefik, NGINX) to the Automatisch service.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount for Automatisch pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Ingress controller (e.g. Traefik, NGINX Ingress Controller) if Ingress routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply automatisch ./automatisch
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	automatisch: {
		webAppUrl: "https://automation.example.com"
	}
	ingress: {
		enabled:          true
		ingressClassName: "traefik"
		hosts: [{
			host: "automation.example.com"
		}]
	}
	encryptionKey:    "PwUzx9lRxIieaIQenGcpg3NjbL6l91tH46QaWBFS5hjikt3A"
	appSecretKey:     "changemeplease32characterslong!!"
	webhookSecretKey: "OdLnAp2KjCNd+VgpKqf5g72Kts2L1YFJwKzdebVtczL4yrGR"
}
```

Apply the values to the instance:

```shell
timoni -n default apply automatisch ./automatisch \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete automatisch
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the module name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `commonLabels` | map | `{}` | Labels added to every resource created by this module |
| `image.repository` | string | `"docker.io/automatischio/automatisch"` | Automatisch container image repository |
| `image.tag` | string | `"0.15.0"` | Automatisch container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | list | `[]` | Secrets for authenticating against private container registries |
| `encryptionKey` | string | required | Encryption key for securing connection credentials |
| `appSecretKey` | string | required | Application secret key for session encryption |
| `webhookSecretKey` | string | required | Webhook signing key for payload verification |
| `automatisch.webAppUrl` | string | `"http://localhost:3000"` | External public URL of the Automatisch web application |
| `automatisch.appEnv` | string | `"production"` | Application runtime environment (`production` or `development`) |
| `automatisch.extraEnv` | list | `[]` | Additional environment variables for the Automatisch container |
| `database.external.host` | string | `""` | Hostname of an external PostgreSQL database (when subchart is disabled) |
| `database.external.port` | string | `"5432"` | Port of the external PostgreSQL database |
| `database.external.name` | string | `"automatisch"` | External PostgreSQL database name |
| `database.external.username` | string | `"automatisch"` | External PostgreSQL username |
| `database.external.password` | string | `""` | External PostgreSQL password |
| `database.external.existingSecret` | string | `""` | Existing secret containing external database password |
| `database.external.existingSecretPasswordKey` | string | `"password"` | Key within existing secret for external database password |
| `redis_config.external.host` | string | `""` | Hostname of an external Redis server (when subchart is disabled) |
| `redis_config.external.port` | string | `"6379"` | Port of the external Redis server |
| `redis_config.external.existingSecret` | string | `""` | Existing secret for external Redis authentication |
| `serviceAccount.create` | bool | `true` | Create a dedicated ServiceAccount for Automatisch pods |
| `serviceAccount.name` | string | `""` | Override name for the created ServiceAccount |
| `serviceAccount.annotations` | map | `{}` | Annotations to add to the ServiceAccount |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | int | `80` | Port exposed by the Kubernetes Service (routes to 3000) |
| `service.annotations` | map | `{}` | Annotations to attach to the Kubernetes Service |
| `ingress.enabled` | bool | `false` | Enable Kubernetes Ingress resource creation |
| `ingress.ingressClassName` | string | `"traefik"` | IngressClass controller name |
| `ingress.annotations` | map | `{}` | Annotations to attach to the Ingress resource |
| `ingress.hosts` | list | `[]` | List of hostnames and routing rules |
| `ingress.tls` | list | `[]` | TLS certificates and secret configuration for Ingress |
| `probes.startup.enabled` | bool | `true` | Enable startup probe |
| `probes.startup.initialDelaySeconds` | int | `10` | Initial delay in seconds before checking startup probe |
| `probes.startup.periodSeconds` | int | `5` | Check interval in seconds for startup probe |
| `probes.startup.timeoutSeconds` | int | `3` | Timeout in seconds for startup probe response |
| `probes.startup.failureThreshold` | int | `30` | Number of failed attempts before container restart |
| `probes.liveness.enabled` | bool | `true` | Enable liveness probe |
| `probes.liveness.initialDelaySeconds` | int | `0` | Initial delay in seconds before checking liveness probe |
| `probes.liveness.periodSeconds` | int | `15` | Check interval in seconds for liveness probe |
| `probes.liveness.timeoutSeconds` | int | `5` | Timeout in seconds for liveness probe response |
| `probes.liveness.failureThreshold` | int | `3` | Failure count triggering container restart |
| `probes.readiness.enabled` | bool | `true` | Enable readiness probe |
| `probes.readiness.initialDelaySeconds` | int | `0` | Initial delay in seconds before checking readiness probe |
| `probes.readiness.periodSeconds` | int | `10` | Check interval in seconds for readiness probe |
| `probes.readiness.timeoutSeconds` | int | `5` | Timeout in seconds for readiness probe response |
| `probes.readiness.failureThreshold` | int | `3` | Failure count triggering traffic removal |
| `resources.requests.cpu` | string | `"100m"` | CPU request for the Automatisch container |
| `resources.requests.memory` | string | `"128Mi"` | Memory request for the Automatisch container |
| `resources.limits.cpu` | string | `"500m"` | CPU limit for the Automatisch container |
| `resources.limits.memory` | string | `"512Mi"` | Memory limit for the Automatisch container |
| `podSecurityContext.runAsUser` | int | `65510` | UID for unprivileged non-root pod execution |
| `podSecurityContext.runAsGroup` | int | `65510` | GID for unprivileged non-root pod execution |
| `podSecurityContext.runAsNonRoot` | bool | `true` | Enforce container execution as non-root user |
| `podSecurityContext.fsGroup` | int | `65510` | Filesystem group ID for volume ownership |
| `podSecurityContext.seccompProfile.type` | string | `"RuntimeDefault"` | Pod-level seccomp profile |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent gaining more privileges than parent process |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |
| `securityContext.runAsUser` | int | `65510` | Dedicated unprivileged container UID |
| `securityContext.runAsGroup` | int | `65510` | Dedicated unprivileged container GID |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce non-root execution inside container |
| `nodeSelector` | map | `{}` | Node labels required for pod scheduling |
| `tolerations` | list | `[]` | Tolerations for pod assignment to tainted nodes |
| `affinity` | map | `{}` | Affinity and anti-affinity scheduling rules |
| `topologySpreadConstraints` | list | `[]` | Pod distribution rules across failure domains |
| `priorityClassName` | string | `""` | PriorityClass assigned to the pod |
| `terminationGracePeriodSeconds` | int | `30` | Seconds to wait before forcibly terminating pod |
| `podLabels` | map | `{}` | Additional custom labels added to Automatisch pods |
| `podAnnotations` | map | `{}` | Additional custom annotations added to Automatisch pods |
| `extraVolumes` | list | `[{name: "logs", emptyDir: {}}]` | Additional volumes mounted into Automatisch pods |
| `extraVolumeMounts` | list | `[{name: "logs", mountPath: "/automatisch/packages/backend/logs"}]` | Additional volume mounts in the Automatisch container |
| `extraManifests` | list | `[]` | Additional raw Kubernetes manifests to apply with module |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.architecture` | string | `"standalone"` | PostgreSQL architecture mode |
| `postgresql.auth.database` | string | `"automatisch"` | Database name created on first run |
| `postgresql.auth.username` | string | `"automatisch"` | Database user created on first run |
| `postgresql.auth.password` | string | `"change-me-please-db-password!"` | Password for the PostgreSQL database user |
| `postgresql.image.repository` | string | `"docker.io/library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"18.6-trixie"` | PostgreSQL container image tag |
| `postgresql.persistence.enabled` | bool | `true` | Enable persistent storage for PostgreSQL data |
| `postgresql.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for PostgreSQL |
| `postgresql.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL subchart |
| `postgresql.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL subchart |
| `postgresql.resources.limits.cpu` | string | `"500m"` | CPU limit for PostgreSQL subchart |
| `postgresql.resources.limits.memory` | string | `"512Mi"` | Memory limit for PostgreSQL subchart |
| `redis.enabled` | bool | `true` | Deploy dedicated Redis subchart |
| `redis.architecture` | string | `"standalone"` | Redis architecture mode |
| `redis.image.repository` | string | `"docker.io/library/redis"` | Redis container image repository |
| `redis.image.tag` | string | `"8.8.2"` | Redis container image tag |
| `redis.persistence.enabled` | bool | `true` | Enable persistent storage for Redis data |
| `redis.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for Redis |
| `redis.resources.requests.cpu` | string | `"50m"` | CPU request for Redis subchart |
| `redis.resources.requests.memory` | string | `"64Mi"` | Memory request for Redis subchart |
| `redis.resources.limits.cpu` | string | `"200m"` | CPU limit for Redis subchart |
| `redis.resources.limits.memory` | string | `"128Mi"` | Memory limit for Redis subchart |

## Recommended values

Automatisch, PostgreSQL, and Redis operate as dedicated unprivileged system users (`65510:65510`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		runAsUser:    65510
		runAsGroup:   65510
		runAsNonRoot: true
		fsGroup:      65510
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
		}
		runAsUser:    65510
		runAsGroup:   65510
		runAsNonRoot: true
	}
}
```

## Additional Resources
- [Official Automatisch Website](https://automatisch.io/)
- [Official Automatisch Repository](https://github.com/automatisch/automatisch)
- [Automatisch Documentation](https://automatisch.io/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Automatisch module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Automatisch Core (`automatisch`) | Deployment | 12 points | ✅  |
| PostgreSQL Subchart (`postgresql`) | StatefulSet | 12 points | ✅ |
| Redis Subchart (`redis`) | StatefulSet | 12 points | ✅ |
