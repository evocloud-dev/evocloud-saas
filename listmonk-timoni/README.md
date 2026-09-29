# Listmonk

## Description
[Listmonk](https://listmonk.app/) is a standalone, high-performance, self-hosted newsletter and mailing list manager. Written in Go and powered by PostgreSQL, it provides multi-list subscriber management, transactional messaging, rich analytics, custom email templating, dynamic subscriber attributes, and high-throughput email delivery via multi-threaded worker pools.

## Application Information
- **Version:** `v6.2.0`
- **Upstream Project:** [https://github.com/knadh/listmonk](https://github.com/knadh/listmonk)
- **Container Base:** [docker.io/listmonk/listmonk](https://hub.docker.com/r/listmonk/listmonk) (`docker.io/listmonk/listmonk:v6.2.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Listmonk Core (`deployment`):** Primary application Deployment running `docker.io/listmonk/listmonk:v6.2.0` on port `9000`. Provides the web administration UI, public subscription APIs, email campaign dispatcher, and analytics pipeline.
- **PostgreSQL Database (`postgres-statefulset`):** Relational database StatefulSet running `postgres:18` on port `5432` with persistent storage for subscribers, campaigns, logs, and templating data.
- **Database Initialization & Migration (`job-init`, `pmj-job`):** Automated database migration and setup jobs managing schema bootstrapping, migrations, and extension installations.
- **Persistent Storage Volumes:**
  - **Media Uploads Storage (`pvc`):** Persistent Volume Claim (`5Gi`, ReadWriteOnce) mounted to `/listmonk/uploads` storing campaign images, logos, and attachments.
  - **PostgreSQL Data:** Dedicated Persistent Volume Claim (`4Gi`, ReadWriteOnce) attached to the PostgreSQL StatefulSet.
- **Kubernetes Services:**
  - `service`: Primary ClusterIP Service exposing port `9000` to internal cluster routing and reverse proxies.
  - `postgres-service`: Headless cluster service managing PostgreSQL network connectivity on port `5432`.
- **PodDisruptionBudget (`pdb-listmonk`, `pdb-postgres`):** Safeguards application and database availability during voluntary disruptions and node maintenance.
- **ServiceAccount (`serviceaccount`):** Dedicated unprivileged Kubernetes ServiceAccount for Listmonk workloads.
- **Secrets & ConfigMaps:** Manages database credentials, SMTP relay authentication, and Listmonk configuration settings.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support
- Reverse proxy or LoadBalancer for external HTTPS traffic access

## Install

To create an instance using default values:

```shell
timoni -n default apply listmonk ./listmonk-timoni
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	admin: {
		username: "admin"
		password: "StrongAdminPassword123!"
	}
	smtp: {
		enabled:  true
		host:     "smtp.sendgrid.net"
		port:     587
		username: "apikey"
		password: "SG.your-actual-api-key"
		from:     "newsletter@example.com"
	}
	storage: {
		size: "10Gi"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply listmonk ./listmonk-timoni \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete listmonk
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | `string` | `""` | Override the release name |
| `fullnameOverride` | `string` | `""` | Override the fully qualified release name |
| `replicaCount` | `int` | `1` | Number of Listmonk application replicas |
| `image.repository` | `string` | `"listmonk/listmonk"` | Container image repository |
| `image.tag` | `string` | `"v6.2.0"` | Container image tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `imagePullSecrets` | `[...corev1.#LocalObjectReference]` | `[]` | [Kubernetes image pull secrets](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod) |
| `serviceAccount.create` | `bool` | `true` | Create a dedicated ServiceAccount |
| `serviceAccount.name` | `string` | `""` | Override ServiceAccount name |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | `int` | `9000` | Kubernetes Service HTTP port |
| `resources.requests.cpu` | `string` | `"250m"` | Listmonk container requested CPU |
| `resources.requests.memory` | `string` | `"256Mi"` | Listmonk container requested memory |
| `resources.limits.cpu` | `string` | `"500m"` | Listmonk container CPU limit |
| `resources.limits.memory` | `string` | `"512Mi"` | Listmonk container memory limit |
| `autoscaling.enabled` | `bool` | `true` | Enable HorizontalPodAutoscaler for Listmonk |
| `autoscaling.minReplicas` | `int` | `1` | Minimum replicas for autoscaling |
| `autoscaling.maxReplicas` | `int` | `3` | Maximum replicas for autoscaling |
| `autoscaling.targetCPUUtilizationPercentage` | `int` | `80` | Target CPU utilization for autoscaling |
| `podDisruptionBudget.enabled` | `bool` | `true` | Enable PodDisruptionBudget for Listmonk |
| `podDisruptionBudget.minAvailable` | `int` | `1` | Minimum available pods during disruptions |
| `admin.username` | `string` | `"admin"` | Initial administrator username |
| `admin.password` | `string` | `"change-me"` | Initial administrator password |
| `app.address` | `string` | `"0.0.0.0:9000"` | Listmonk listen address and port |
| `app.lang` | `string` | `"en"` | Default interface language |
| `database.host` | `string` | `"listmonk-postgres"` | PostgreSQL database host |
| `database.port` | `int` | `5432` | PostgreSQL database port |
| `database.name` | `string` | `"listmonk"` | PostgreSQL database name |
| `database.user` | `string` | `"listmonk"` | PostgreSQL database username |
| `database.password` | `string` | `"change-me-postgres"` | PostgreSQL database password |
| `database.sslMode` | `string` | `"disable"` | PostgreSQL SSL mode (`disable`, `require`, `verify-full`) |
| `database.existingSecret` | `string` | `""` | Existing Secret containing database password |
| `postgres.enabled` | `bool` | `true` | Deploy internal PostgreSQL database StatefulSet |
| `postgres.image.repository` | `string` | `"postgres"` | PostgreSQL image repository |
| `postgres.image.tag` | `string` | `"18"` | PostgreSQL image tag |
| `postgres.storage.size` | `string` | `"4Gi"` | PostgreSQL Persistent Volume Claim size |
| `postgres.resources.requests.cpu` | `string` | `"100m"` | Requested CPU for PostgreSQL |
| `postgres.resources.requests.memory` | `string` | `"256Mi"` | Requested memory for PostgreSQL |
| `postgres.resources.limits.cpu` | `string` | `"500m"` | CPU limit for PostgreSQL |
| `postgres.resources.limits.memory` | `string` | `"1Gi"` | Memory limit for PostgreSQL |
| `smtp.enabled` | `bool` | `false` | Enable SMTP mail delivery server configuration |
| `smtp.host` | `string` | `"smtp.example.com"` | SMTP server hostname |
| `smtp.port` | `int` | `587` | SMTP server port |
| `smtp.username` | `string` | `"user@example.com"` | SMTP server username |
| `smtp.password` | `string` | `"change-me"` | SMTP server password |
| `smtp.from` | `string` | `"noreply@example.com"` | Default sender email address |
| `smtp.tlsEnabled` | `bool` | `true` | Enable TLS encryption for SMTP connections |
| `storage.enabled` | `bool` | `true` | Enable persistent storage for media and image uploads |
| `storage.size` | `string` | `"5Gi"` | Storage size for media uploads PVC |
| `podSecurityContext` | `corev1.#PodSecurityContext` | `{runAsUser: 10001, runAsGroup: 10001, fsGroup: 10001}` | Pod security context |
| `securityContext` | `corev1.#SecurityContext` | `{runAsUser: 10001, runAsGroup: 10001, runAsNonRoot: true, allowPrivilegeEscalation: false, readOnlyRootFilesystem: true, capabilities: {drop: ["ALL"]}}` | Container security context |
| `nodeSelector` | `{[string]: string}` | `{}` | Node selector labels for pod scheduling |
| `tolerations` | `[...corev1.#Toleration]` | `[]` | Tolerations for pod scheduling |
| `affinity` | `corev1.#Affinity` | `{}` | Affinity and anti-affinity scheduling rules |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:  10001
		runAsGroup: 10001
		fsGroup:    10001
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		runAsUser:                10001
		runAsGroup:               10001
		capabilities: {
			drop: [
				"ALL",
			]
		}
	}
}
```

## Additional Resources
- [Official Listmonk Website](https://listmonk.app/)
- [Official Listmonk Repository](https://github.com/knadh/listmonk)
- [Listmonk Documentation](https://listmonk.app/docs/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Listmonk module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Listmonk Core (`my-listmonk-listmonk`) | Deployment | 14 points | ✅ |
| PostgreSQL Database (`listmonk-postgres`) | StatefulSet | 16 points | ✅ |
