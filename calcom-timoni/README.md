# Cal.com

## Description
[Cal.com](https://cal.com/) is an open-source scheduling infrastructure and privacy-first Calendly alternative. It allows individuals, teams, and organizations to manage their availability, book appointments, connect calendars, and automate booking workflows while maintaining complete ownership of their data.

## Application Information
- **Version:** v6.2.0
- **Upstream Project:** [https://github.com/calcom/cal.com](https://github.com/calcom/cal.com)
- **Container Base:** [docker.io/calcom/cal.com](https://hub.docker.com/r/calcom/cal.com) (`docker.io/calcom/cal.com:v6.2.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Cal.com Core (`deploy`):** Next.js web application and scheduling engine running `docker.io/calcom/cal.com:v6.2.0` on container port 3000.
- **PostgreSQL Subchart (`postgresql_statefulset`, `postgresql_svc`, `postgresql_secret`, `postgresql_pvc`):** Dedicated PostgreSQL database StatefulSet (`docker.io/library/postgres:18-alpine`) with persistent storage (`10Gi`) and automated credential management.
- **Kubernetes Service (`svc`):** ClusterIP service exposing port 3000 for in-cluster communication and ingress traffic routing.
- **HorizontalPodAutoscaler (`hpa`):** Automatically scales Cal.com replicas between 1 and 10 based on CPU and memory thresholds (default 80%).
- **Application Secret (`secret`):** Securely stores database connection strings (`DATABASE_URL`), public application URL (`NEXT_PUBLIC_WEBAPP_URL`), session secrets (`NEXTAUTH_SECRET`), and encryption keys (`CALENDSO_ENCRYPTION_KEY`).
- **Ingress (`ingress`):** Optional Ingress resource for external domain routing and TLS certificate management.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Ingress controller (e.g. Traefik, NGINX Ingress Controller) if Ingress routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply calcom ./calcom-timoni
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	secret: {
		data: {
			NEXT_PUBLIC_WEBAPP_URL:  "https://cal.example.com"
			NEXTAUTH_SECRET:         "generate-a-secure-secret-here"
			CALENDSO_ENCRYPTION_KEY: "generate-a-secure-key-here"
		}
	}
	ingress: main: {
		enabled:   true
		className: "traefik"
		hosts: [{
			host: "cal.example.com"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply calcom ./calcom-timoni \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete calcom
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `replicaCount` | int | `1` | Number of Cal.com pod replicas |
| `image.repository` | string | `"calcom/cal.com"` | Cal.com container image repository |
| `image.tag` | string | `"v6.2.0"` | Cal.com container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | list | `[]` | Secrets for pulling images from private registries |
| `nameOverride` | string | `""` | Override the release name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `podAnnotations` | map | `{}` | Annotations to attach to Cal.com pods |
| `podSecurityContext` | map | `{}` | Pod-level security context configuration |
| `securityContext.runAsUser` | int | `10001` | Dedicated unprivileged container UID |
| `securityContext.runAsGroup` | int | `10001` | Dedicated unprivileged container GID |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce container execution as non-root user |
| `securityContext.readOnlyRootFilesystem` | bool | `true` | Mount the container root filesystem in read-only mode |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |
| `secret.enabled` | bool | `true` | Generate Kubernetes Secret containing runtime credentials |
| `secret.data.DATABASE_URL` | string | `"postgresql://user:password@postgresql:5432/calcom"` | Full PostgreSQL connection URI |
| `secret.data.NEXT_PUBLIC_WEBAPP_URL` | string | `"http://localhost:3000"` | Public web application URL for booking links |
| `secret.data.NEXTAUTH_SECRET` | string | `"changeme"` | Cryptographic secret for signing NextAuth sessions |
| `secret.data.CALENDSO_ENCRYPTION_KEY` | string | `"changeme"` | Symmetric encryption key for stored integration tokens |
| `secret.data.AB_TEST_BUCKET_PROBABILITY` | string | `"0"` | A/B testing probability setting |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.image.repository` | string | `"postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"18-alpine"` | PostgreSQL container image tag |
| `postgresql.auth.username` | string | `"user"` | PostgreSQL database user |
| `postgresql.auth.password` | string | `"password"` | PostgreSQL database password |
| `postgresql.auth.database` | string | `"calcom"` | PostgreSQL database name |
| `postgresql.storage.size` | string | `"10Gi"` | Persistent Volume Claim size for PostgreSQL data |
| `postgresql.storage.storageClass` | string | `"standard"` | StorageClass for PostgreSQL persistent storage |
| `postgresql.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL pod |
| `postgresql.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL pod |
| `postgresql.resources.limits.cpu` | string | `"500m"` | CPU limit for PostgreSQL pod |
| `postgresql.resources.limits.memory` | string | `"512Mi"` | Memory limit for PostgreSQL pod |
| `service.main.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.main.ports.http.port` | int | `3000` | Port exposed by the Cal.com Service |
| `ingress.main.enabled` | bool | `false` | Enable Kubernetes Ingress resource creation |
| `ingress.main.className` | string | `""` | IngressClass controller name |
| `ingress.main.hosts` | list | `[{host: "example.org", ...}]` | Ingress routing hostnames and paths |
| `ingress.main.tls` | list | `[]` | Ingress TLS secrets and certificate configuration |
| `resources.requests.cpu` | string | `"100m"` | CPU request for Cal.com web container |
| `resources.requests.memory` | string | `"256Mi"` | Memory request for Cal.com web container |
| `resources.limits.cpu` | string | `"1000m"` | CPU limit for Cal.com web container |
| `resources.limits.memory` | string | `"1Gi"` | Memory limit for Cal.com web container |
| `autoscaling.enabled` | bool | `true` | Enable HorizontalPodAutoscaler |
| `autoscaling.minReplicas` | int | `1` | Minimum number of Cal.com replicas |
| `autoscaling.maxReplicas` | int | `10` | Maximum number of Cal.com replicas |
| `autoscaling.targetCPUUtilizationPercentage` | int | `80` | Target CPU utilization percentage for scaling |
| `autoscaling.targetMemoryUtilizationPercentage` | int | `80` | Target memory utilization percentage for scaling |
| `nodeSelector` | map | `{}` | Node labels required for pod scheduling |
| `tolerations` | list | `[]` | Tolerations for tainted nodes |
| `affinity` | map | `{}` | Affinity and anti-affinity scheduling rules |

## Recommended values

Cal.com and its database subchart operate under hardened unprivileged security contexts with dropped capabilities and read-only root filesystems conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	securityContext: {
		runAsUser:              10001
		runAsGroup:             10001
		runAsNonRoot:           true
		readOnlyRootFilesystem: true
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official Cal.com Website](https://cal.com/)
- [Official Cal.com Repository](https://github.com/calcom/cal.com)
- [Cal.com Documentation](https://cal.com/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Cal.com module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Cal.com Web Application (`calcom`) | Deployment | 12 points | ✅  |
| PostgreSQL Subchart (`postgresql`) | StatefulSet | 12 points | ✅ |
