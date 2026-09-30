# Matomo

## Description
[Matomo](https://matomo.org/) (formerly Piwik) is the leading open-source web analytics platform, delivering privacy-centric metrics with 100% data ownership. Offering an ethical alternative to Google Analytics, Matomo provides real-time visitor reporting, heatmaps, session recordings, conversion funnels, custom dimensions, and campaign tracking while strictly complying with global privacy laws such as GDPR, HIPAA, and CCPA.

## Application Information
- **Version:** `5.13.0`
- **Upstream Project:** [https://github.com/matomo-org/matomo](https://github.com/matomo-org/matomo)
- **Container Base:** [docker.io/library/matomo](https://hub.docker.com/_/matomo) (`docker.io/library/matomo:5.13.0-apache`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Matomo Application Core (`matomo`):** Web server Deployment running Apache and PHP (`docker.io/library/matomo:5.13.0-apache`) on container port `8080` (exposed via Service port `80`). Serves the web dashboard, tracking endpoint (`matomo.php`), and REST reporting APIs.
- **MySQL Database (`matomo-mysql`):** Dedicated relational database StatefulSet running `library/mysql:9.7` with persistent volume storage (`8Gi`) storing visitor logs, aggregated reports, goals, and user profiles.
- **Matomo Archiver (`archiver`):** Background CronJob running every hour (`5 * * * *`) that executes `core:archive` to pre-calculate reports, ensuring instant dashboard rendering and fast querying.
- **Persistent Storage Volumes:**
  - **Matomo Application Files (`persistence`):** Persistent Volume Claim (`10Gi`, ReadWriteOnce) mounted to `/var/www/html` storing configuration (`config/config.ini.php`), custom plugins, and tracking assets.
  - **MySQL Data:** Dedicated Persistent Volume Claim (`8Gi`, ReadWriteOnce) for MySQL database persistence.
- **Kubernetes Services:**
  - `service`: Primary ClusterIP Service exposing port `80` to internal cluster traffic and reverse proxies.
  - `matomo-mysql`: ClusterIP Service exposing MySQL port `3306`.
  - `matomo-mysql-headless`: Headless Service supporting StatefulSet network identity.
- **Gateway API (`gatewayAPI`):** Optional Gateway API `HTTPRoute` resources for edge routing and TLS termination.
- **NetworkPolicy (`networkPolicy`):** Network isolation policies managing allowed ingress traffic and DNS egress.
- **PodDisruptionBudget (`podDisruptionBudget`):** Ensures continuous application availability during node maintenance.
- **ServiceAccount (`serviceAccount`):** Dedicated unprivileged Kubernetes ServiceAccount for Matomo pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support
- Gateway API router or reverse proxy for external HTTPS access

## Install

To create an instance using default values:

```shell
timoni -n default apply matomo ./matomo
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	matomo: {
		siteUrl:     "https://analytics.example.com"
		trustedHost: "analytics.example.com"
	}
	mysql: {
		auth: {
			password:     "StrongDatabasePassword123!"
			rootPassword: "StrongRootPassword123!"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply matomo ./matomo \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete matomo
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | `string` | `""` | Override the release name |
| `fullnameOverride` | `string` | `""` | Override the fully qualified release name |
| `replicaCount` | `int` | `1` | Number of Matomo application replicas |
| `image.repository` | `string` | `"docker.io/library/matomo"` | Matomo container image repository |
| `image.tag` | `string` | `"5.13.0-apache"` | Matomo container image tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `matomo.siteUrl` | `string` | `""` | External public URL of the Matomo instance |
| `matomo.trustedHost` | `string` | `""` | Trusted host domain for Matomo headers |
| `database.mode` | `string` | `"auto"` | Database connection mode (`auto`, `external`, `mysql`) |
| `mysql.enabled` | `bool` | `true` | Deploy internal MySQL database StatefulSet |
| `mysql.image.repository` | `string` | `"library/mysql"` | MySQL container image repository |
| `mysql.image.tag` | `string` | `"9.7"` | MySQL container image tag |
| `mysql.auth.database` | `string` | `"matomo"` | MySQL database name |
| `mysql.auth.username` | `string` | `"matomo"` | MySQL database username |
| `mysql.primary.persistence.size` | `string` | `"8Gi"` | Persistent Volume Claim size for MySQL |
| `mysql.primary.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "1Gi"}}` | MySQL resource requests and limits |
| `persistence.enabled` | `bool` | `true` | Enable persistent storage for Matomo application data |
| `persistence.size` | `string` | `"10Gi"` | Storage size for Matomo PVC |
| `archiver.enabled` | `bool` | `true` | Enable automated background report archiving CronJob |
| `archiver.schedule` | `string` | `"5 * * * *"` | Cron schedule for report archiving |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | `int` | `80` | External Service HTTP port |
| `apache.port` | `int` | `8080` | Internal Apache server listen port |
| `gatewayAPI.enabled` | `bool` | `false` | Enable Gateway API HTTPRoute resource |
| `networkPolicy.enabled` | `bool` | `true` | Enable NetworkPolicy ingress/egress isolation rules |
| `podDisruptionBudget.enabled` | `bool` | `true` | Enable PodDisruptionBudget for Matomo |
| `serviceAccount.create` | `bool` | `true` | Create a dedicated ServiceAccount |
| `serviceAccount.name` | `string` | `""` | Override ServiceAccount name |
| `resources.requests.cpu` | `string` | `"100m"` | Matomo container requested CPU |
| `resources.requests.memory` | `string` | `"256Mi"` | Matomo container requested memory |
| `resources.limits.cpu` | `string` | `"500m"` | Matomo container CPU limit |
| `resources.limits.memory` | `string` | `"1Gi"` | Matomo container memory limit |
| `podSecurityContext` | `corev1.#PodSecurityContext` | `{runAsUser: 33, runAsGroup: 33, fsGroup: 33, runAsNonRoot: true}` | Pod-level security context |
| `securityContext` | `corev1.#SecurityContext` | `{runAsNonRoot: true, allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}}` | Container security context |
| `nodeSelector` | `{[string]: string}` | `{}` | Node selector labels for pod scheduling |
| `tolerations` | `[...corev1.#Toleration]` | `[]` | Tolerations for pod scheduling |
| `affinity` | `corev1.#Affinity` | `{}` | Affinity and anti-affinity scheduling rules |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:    33
		runAsGroup:   33
		fsGroup:      33
		runAsNonRoot: true
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		runAsNonRoot:             true
		readOnlyRootFilesystem:   false
		capabilities: {
			drop: [
				"ALL",
			]
		}
	}
}
```

## Additional Resources
- [Official Matomo Website](https://matomo.org/)
- [Official Matomo Repository](https://github.com/matomo-org/matomo)
- [Matomo Documentation](https://matomo.org/docs/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Matomo module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Matomo Application Core (`matomo`) | Deployment | 11 points | ✅ |
| MySQL Database (`matomo-mysql`) | StatefulSet | 11 points | ✅ |
