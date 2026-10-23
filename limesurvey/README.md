# limesurvey

## Description

[LimeSurvey](https://www.limesurvey.org/) is the leading open-source online statistical survey web application. It enables users to develop, publish, and collect responses from online surveys without requiring software development experience. It supports rich question types, advanced survey branching logic, multi-language support, token-based respondent access management, and comprehensive data analytics and export.

## Application Information
- **Version:** `7.7.0.1`
- **Official Website:** [https://www.limesurvey.org/](https://www.limesurvey.org/)
- **Upstream Project:** [https://github.com/LimeSurvey/LimeSurvey](https://github.com/LimeSurvey/LimeSurvey)
- **Container Base:**
  - LimeSurvey Application: [docker.io/adamzammit/limesurvey](https://hub.docker.com/r/adamzammit/limesurvey) (`adamzammit/limesurvey:7.7.0.1`)
  - MariaDB Database: [docker.io/bitnamilegacy/mariadb](https://hub.docker.com/r/bitnamilegacy/mariadb) (`docker.io/bitnamilegacy/mariadb:12.0.2-debian-12-r0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **LimeSurvey Web Server Workload (`limesurvey`):** Core web-based survey management application running on container HTTP port `80` and exposed on service port `80`.
- **Deployment (`limesurvey`):** Deployment with `startupProbe`, `livenessProbe`, and `readinessProbe` HTTP health checks, `db-isalive` initContainer waiting for database readiness, persistent storage mounts for `/var/www/html/plugins`, `/var/www/html/upload`, `/var/lime/sessions`, and `/var/www/html/application/config`.
- **Service (`limesurvey`):** Kubernetes `ClusterIP` Service exposing the LimeSurvey web application on port `80` targeting container port `http` (`80`).
- **Secrets (`<name>`, `<name>-smtp`):** Kubernetes Secrets storing LimeSurvey administrator password and SMTP credentials.
- **PersistentVolumeClaim (`<name>`):** Persistent storage volume (`ReadWriteOnce`, `5Gi` default) preserving LimeSurvey plugins, survey uploads, session data, and dynamic configuration.
- **MariaDB Database (`<name>-mariadb`):** Dedicated MariaDB 12 database `StatefulSet` with `volumeClaimTemplates` (`8Gi` persistent storage), `ConfigMap` (`my.cnf`), credential secret, headless service, and ClusterIP service (port `3306`).
- **Gateway API HTTPRoute (`<name>`):** Optional Gateway API `HTTPRoute` resource (`gateway.networking.k8s.io/v1`) for routing HTTP/HTTPS traffic via Kubernetes Gateway API controllers.
- **HorizontalPodAutoscaler (`<name>`):** Optional HorizontalPodAutoscaler (`autoscaling/v2`) scaling LimeSurvey replicas based on CPU and memory utilization.

## Prerequisites

- Kubernetes cluster v1.33+ (or v1.20+ minimum supported by module schema)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- StorageClass supporting `ReadWriteOnce` PVCs for `persistence` and `mariadb.primary.persistence`
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply limesurvey ./limesurvey
```

To deploy with customized values (for example customizing database credentials, resource limits, and `HTTPRoute`), create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		size: "10Gi"
	}
	mariadb: {
		enabled: true
		auth: {
			database: "limesurvey"
			username: "limesurvey"
			password: "my-secure-db-password"
		}
		primary: {
			persistence: {
				size: "15Gi"
			}
			resources: {
				requests: {
					cpu:    "200m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1000m"
					memory: "1Gi"
				}
			}
		}
	}
	service: {
		type: "ClusterIP"
		port: 80
	}
	gatewayAPI: {
		enabled: true
		httpRoutes: [
			{
				parentRefs: [
					{
						name:      "shared-gtw"
						namespace: "kube-system"
						group:     "gateway.networking.k8s.io"
						kind:      "Gateway"
						port:      80
					},
				]
				hostnames: [
					"survey.example.com",
				]
			},
		]
	}
	resources: {
		requests: {
			cpu:    "200m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1Gi"
		}
	}
	limesurvey: {
		admin: {
			name:     "Survey Administrator"
			email:    "admin@example.com"
			username: "admin"
			password: "my-secure-admin-password"
		}
		tz: "UTC"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply limesurvey ./limesurvey \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete limesurvey
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `replicaCount` | `int` | `1` | Workload replica count |
| `image.repository` | `string` | `"adamzammit/limesurvey"` | Container image repository |
| `image.tag` | `string` | `"7.7.0.1"` | Container image release tag |
| `image.digest` | `string` | `""` | Container image SHA256 digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `nameOverride` | `string` | `""` | Override the default app name |
| `fullnameOverride` | `string` | `""` | Override the generated resource name prefix |
| `serviceAccount.create` | `bool` | `false` | Specifies whether a ServiceAccount should be created |
| `serviceAccount.name` | `string` | `""` | Name of existing ServiceAccount to use |
| `serviceAccount.annotations` | `object` | `{}` | Annotations to add to the ServiceAccount |
| `automountServiceAccountToken` | `bool` | `false` | Automatically mount ServiceAccount token in pod |
| `podAnnotations` | `object` | `{}` | Annotations applied to LimeSurvey pods |
| `podSecurityContext` | `object` | `{}` | Pod-level security context settings |
| `initContainerSecurityContext` | `object` | `{}` | Security context for initContainer (`db-isalive`) |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation on LimeSurvey container |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `securityContext.capabilities.add` | `list` | `["CHOWN", "FOWNER", "DAC_OVERRIDE", "SETUID", "SETGID", "NET_BIND_SERVICE"]` | Linux capabilities added to container |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `80` | Application Service HTTP port |
| `gatewayAPI.enabled` | `bool` | `false` | Enable Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | Route definitions with `parentRefs`, `hostnames`, `rules`, `labels`, and `annotations` |
| `resources.requests.cpu` | `string` | `"100m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"128Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"500m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"512Mi"` | Container memory limit |
| `limesurvey.admin.name` | `string` | `"Lime Administrator"` | Full name of the LimeSurvey administrator |
| `limesurvey.admin.email` | `string` | `"lime@lime.lime"` | Email address of the LimeSurvey administrator |
| `limesurvey.admin.username` | `string` | `"admin"` | Username of the LimeSurvey administrator |
| `limesurvey.admin.password` | `string` | `""` | Password of administrator (auto-generated if empty) |
| `limesurvey.admin.existingSecret` | `string` | `""` | Existing secret containing administrator password |
| `limesurvey.smtp.host` | `string` | `""` | SMTP host for email delivery |
| `limesurvey.smtp.user` | `string` | `""` | SMTP authorization username |
| `limesurvey.smtp.password` | `string` | `""` | SMTP authorization password |
| `limesurvey.smtp.existingSecret` | `string` | `""` | Existing secret for SMTP credentials |
| `limesurvey.smtp.ssl` | `string` | `""` | Set to `"ssl"` or `"tls"` for secure SMTP |
| `limesurvey.smtp.from_email` | `string` | `"your-email@example.net"` | Default sender email address |
| `limesurvey.smtp.debug` | `string` | `""` | Enable SMTP debugging |
| `limesurvey.tablePrefix` | `string` | `"lime_"` | Database table name prefix |
| `limesurvey.debug` | `string` | `"0"` | Debug level (0 is off, 1 for errors, 2 for strict PHP) |
| `limesurvey.sqlDebug` | `string` | `"0"` | SQL debug level (0 is off, 1 is on) |
| `limesurvey.useInnodb` | `string` | `"true"` | Use InnoDB storage engine |
| `limesurvey.dbSessions` | `string` | `""` | Use database-backed sessions |
| `limesurvey.phpSessionSaveHandler` | `string` | `""` | PHP session save handler |
| `limesurvey.phpSessionSavePath` | `string` | `""` | PHP session save path |
| `limesurvey.dontShowScriptName` | `string` | `""` | Hide index.php from URLs |
| `limesurvey.dontUpdate` | `string` | `""` | Skip database update routine |
| `limesurvey.tz` | `string` | `"Europe/Berlin"` | Time zone name |
| `limesurvey.apiMode` | `string` | `"off"` | RPC-API mode (`"off"`, `"json"`, or `"xml"`) |
| `persistence.enabled` | `bool` | `true` | Enable persistence using Persistent Volume Claim |
| `persistence.size` | `string` | `"5Gi"` | Storage capacity requested for the LimeSurvey PVC |
| `persistence.accessModes` | `list` | `["ReadWriteOnce"]` | LimeSurvey PVC access modes |
| `persistence.storageClass` | `string` | `null` | Optional StorageClass name for the LimeSurvey PVC |
| `persistence.existingClaim` | `string` | `null` | Existing PersistentVolumeClaim to bind |
| `mariadb.enabled` | `bool` | `true` | Enable the bundled MariaDB database StatefulSet |
| `mariadb.image.repository` | `string` | `"docker.io/bitnamilegacy/mariadb"` | MariaDB container image repository |
| `mariadb.image.tag` | `string` | `"12.0.2-debian-12-r0"` | MariaDB container image tag |
| `mariadb.image.pullPolicy` | `string` | `"IfNotPresent"` | MariaDB image pull policy |
| `mariadb.auth.database` | `string` | `"limesurvey"` | MariaDB database name |
| `mariadb.auth.username` | `string` | `"limesurvey"` | MariaDB database username |
| `mariadb.auth.password` | `string` | `"changeme"` | MariaDB database user password |
| `mariadb.auth.existingSecret` | `string` | `""` | Existing secret for MariaDB credentials |
| `mariadb.architecture` | `string` | `"standalone"` | MariaDB deployment architecture |
| `mariadb.primary.persistence.enabled` | `bool` | `true` | Enable MariaDB data persistence |
| `mariadb.primary.persistence.size` | `string` | `"8Gi"` | Storage capacity requested for MariaDB PVC |
| `mariadb.primary.persistence.accessMode` | `string` | `"ReadWriteOnce"` | MariaDB PVC access mode |
| `mariadb.primary.resourcesPreset` | `string` | `"none"` | Bitnami common resource preset |
| `mariadb.primary.resources.requests.cpu` | `string` | `"100m"` | MariaDB container CPU request |
| `mariadb.primary.resources.requests.memory` | `string` | `"256Mi"` | MariaDB container memory request |
| `mariadb.primary.resources.limits.cpu` | `string` | `"500m"` | MariaDB container CPU limit |
| `mariadb.primary.resources.limits.memory` | `string` | `"512Mi"` | MariaDB container memory limit |
| `mariadb.primary.podSecurityContext.fsGroup` | `int` | `1001` | MariaDB Pod filesystem group GID |
| `mariadb.primary.containerSecurityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation on MariaDB container |
| `mariadb.primary.containerSecurityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount root filesystem as read-only |
| `mariadb.primary.containerSecurityContext.runAsNonRoot` | `bool` | `true` | Run MariaDB container as non-root |
| `mariadb.primary.containerSecurityContext.runAsUser` | `int` | `1001` | MariaDB container user UID |
| `mariadb.primary.containerSecurityContext.runAsGroup` | `int` | `1001` | MariaDB container group GID |
| `mariadb.primary.containerSecurityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from MariaDB container |
| `externalDatabase.type` | `string` | `"mysql"` | External database type (`"mysql"` or `"pgsql"`) |
| `externalDatabase.host` | `string` | `"mariadb.example.com"` | External database host |
| `externalDatabase.port` | `int` | `3306` | External database port |
| `externalDatabase.username` | `string` | `"limesurvey"` | External database username |
| `externalDatabase.password` | `string` | `""` | External database password |
| `externalDatabase.database` | `string` | `"limesurvey"` | External database database name |
| `externalDatabase.existingSecret` | `string` | `""` | Existing secret containing external database password |
| `autoscaling.enabled` | `bool` | `false` | Enable HorizontalPodAutoscaler |
| `autoscaling.minReplicas` | `int` | `1` | Minimum number of replicas for autoscaling |
| `autoscaling.maxReplicas` | `int` | `100` | Maximum number of replicas for autoscaling |
| `autoscaling.targetCPUUtilizationPercentage` | `int` | `80` | Target CPU utilization percentage |
| `nodeSelector` | `object` | `{}` | Node selector labels for pod scheduling |
| `tolerations` | `list` | `[]` | Pod tolerations for node taints |
| `affinity` | `object` | `{}` | Pod and node affinity scheduling rules |
| `topologySpreadConstraints` | `list` | `[]` | Pod topology spread constraints |

## Additional Resources
- [Official LimeSurvey Website](https://www.limesurvey.org/)
- [LimeSurvey GitHub Repository](https://github.com/LimeSurvey/LimeSurvey)
- [LimeSurvey Docker Hub](https://hub.docker.com/r/adamzammit/limesurvey)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the LimeSurvey module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| MariaDB Database (`limesurvey-mariadb`) | StatefulSet | 14 points | ✅ |
| LimeSurvey Server (`limesurvey`) | Deployment | 10 points | ✅ |
