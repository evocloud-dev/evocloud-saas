# Uptime Kuma

## Description

[Uptime Kuma](https://uptime.kuma.pet) is an open-source, self-hosted monitoring tool featuring HTTP(s), TCP, DNS, and Ping checks, status pages, certificate expiration alerts, extensive notification channels, and support for SQLite or MariaDB/MySQL backends.

## Application Information

- **Version:** 2.5.5
- **Official Website:** [https://uptime.kuma.pet](https://uptime.kuma.pet)
- **Upstream Project:** [https://github.com/louislam/uptime-kuma](https://github.com/louislam/uptime-kuma)
- **Container Base:** [docker.io/louislam/uptime-kuma](https://hub.docker.com/r/louislam/uptime-kuma) (`docker.io/louislam/uptime-kuma:2.5.5`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Uptime Kuma Web Application (`uptime-kuma`):** Core monitoring service, web dashboard, and API endpoints running on port `3001`.
- **Deployment (`uptime-kuma`):** Single-replica deployment with `Recreate` rollout strategy, preStop lifecycle hook (`sleep 5`), health probes, and optional `wait-for-db` init container.
- **Service (`uptime-kuma`):** Kubernetes Service exposing the web dashboard and status pages on port `80` (target port `3001`).
- **PersistentVolumeClaim (`uptime-kuma-data`):** Persistent volume claim mounted at `/app/data` for SQLite database, upload assets, and TLS certificates (`2Gi` default).
- **Bundled MySQL (`uptime-kuma-mysql`):** Bundled MariaDB-compatible MySQL StatefulSet (`docker.io/library/mysql:9.7.2`) with `8Gi` storage, authentication secrets, initialization ConfigMap, and custom configuration.
- **MySQL Headless Service (`uptime-kuma-mysql-headless`):** Headless Service (`clusterIP: None`) for StatefulSet network identity and pod discovery.
- **MySQL Client Service (`uptime-kuma-mysql`):** ClusterIP Service routing internal database queries to the MySQL server on port `3306`.
- **Automated Backup CronJob (`uptime-kuma-backup`):** Scheduled CronJob performing SQLite tar archiving or MySQL database dumps and uploading backups to S3-compatible object storage via MinIO Client (`docker.io/helmforge/mc:1.0.0`).
- **Backup ConfigMap (`uptime-kuma-backup-script`):** Script ConfigMap orchestrating backup generation and `mc` S3 uploads.
- **ServiceAccount (`uptime-kuma`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **Gateway API HTTPRoute (`uptime-kuma`):** Optional Gateway API HTTPRoute definition for routing external traffic via Kubernetes Gateway API controllers.
- **ExternalSecret (`uptime-kuma`):** Optional External Secrets Operator v1 resource for syncing database and S3 backup credentials from external secret managers.

## Prerequisites

- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active

## Install

To create an instance using default values:

```bash
timoni -n default apply uptime-kuma ./uptime-kuma
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		size: "5Gi"
		storageClass: "fast-nvme"
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
	gatewayAPI: {
		enabled: true
	}
}
```

Apply the custom values to the instance:

```bash
timoni -n default apply uptime-kuma ./uptime-kuma \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```bash
timoni -n default delete uptime-kuma
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the module name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the complete resource name |
| `commonLabels` | `object` | `{}` | Additional labels applied to all module resources |
| `image.repository` | `string` | `"docker.io/louislam/uptime-kuma"` | Uptime Kuma container image repository |
| `image.tag` | `string` | `"2.5.5"` | Uptime Kuma container image release tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private container mirrors |
| `uptimeKuma.port` | `int` | `3001` | Application container HTTP port |
| `uptimeKuma.disableFrameSameOrigin` | `bool` | `false` | Allow iframe embedding from different origins |
| `uptimeKuma.extraEnv` | `list` | `[]` | Extra environment variables appended to the container |
| `database.type` | `string` | `"sqlite"` | Database backend (`sqlite` or `mariadb`) |
| `database.external.host` | `string` | `""` | External MariaDB hostname |
| `database.external.port` | `string` | `"3306"` | External MariaDB port |
| `database.external.name` | `string` | `"uptime_kuma"` | External MariaDB database name |
| `database.external.username` | `string` | `"uptime_kuma"` | External MariaDB username |
| `database.external.password` | `string` | `""` | External MariaDB password |
| `database.external.existingSecret` | `string` | `""` | Existing Secret containing the external database password |
| `database.external.existingSecretPasswordKey` | `string` | `"password"` | Key within existing Secret containing the password |
| `persistence.enabled` | `bool` | `true` | Enable persistent storage for `/app/data` |
| `persistence.size` | `string` | `"2Gi"` | Capacity of the data volume claim |
| `persistence.storageClass` | `string` | `""` | StorageClass name for data volume claim |
| `persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.existingClaim` | `string` | `""` | Use existing PVC instead of provisioning new claim |
| `serviceAccount.create` | `bool` | `true` | Create dedicated Kubernetes ServiceAccount |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name override |
| `serviceAccount.annotations` | `object` | `{}` | Annotations applied to the ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount Service Account Token |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `80` | Service HTTP port |
| `service.annotations` | `object` | `{}` | Annotations applied to the Service |
| `probes.startup.enabled` | `bool` | `true` | Enable container startup probe |
| `probes.startup.path` | `string` | `"/"` | Startup probe HTTP GET path |
| `probes.liveness.enabled` | `bool` | `true` | Enable container liveness probe |
| `probes.liveness.path` | `string` | `"/"` | Liveness probe HTTP GET path |
| `probes.readiness.enabled` | `bool` | `true` | Enable container readiness probe |
| `probes.readiness.path` | `string` | `"/"` | Readiness probe HTTP GET path |
| `resources.requests.cpu` | `string` | `"100m"` | Container CPU request |
| `resources.requests.memory` | `string` | `"128Mi"` | Container memory request |
| `resources.limits.cpu` | `string` | `"500m"` | Container CPU limit |
| `resources.limits.memory` | `string` | `"512Mi"` | Container memory limit |
| `podSecurityContext.fsGroup` | `int` | `10001` | Pod filesystem group ID |
| `podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent container privilege escalation |
| `securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount root filesystem as read-only |
| `securityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `securityContext.runAsUser` | `int` | `65510` | Non-root user UID |
| `securityContext.runAsGroup` | `int` | `65510` | Non-root group GID |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `lifecycle.preStop.exec.command` | `list` | `["sh", "-c", "sleep 5"]` | Container lifecycle preStop hook |
| `nodeSelector` | `object` | `{}` | Node selection constraints |
| `tolerations` | `list` | `[]` | Pod scheduling tolerations |
| `affinity` | `object` | `{}` | Pod affinity or anti-affinity rules |
| `topologySpreadConstraints` | `list` | `[]` | Topology spread constraints |
| `priorityClassName` | `string` | `""` | Scheduling priority class name |
| `terminationGracePeriodSeconds` | `int` | `30` | Grace period for pod shutdown in seconds |
| `podLabels` | `object` | `{}` | Additional labels applied to pods |
| `podAnnotations` | `object` | `{}` | Additional annotations applied to pods |
| `backup.enabled` | `bool` | `false` | Enable automated backup CronJob |
| `backup.schedule` | `string` | `"0 2 * * *"` | Backup execution schedule in Cron format |
| `backup.suspend` | `bool` | `false` | Suspend backup CronJob execution |
| `backup.concurrencyPolicy` | `string` | `"Forbid"` | CronJob concurrency policy |
| `backup.archivePrefix` | `string` | `"uptime-kuma"` | Archive file prefix for backups |
| `backup.images.uploader.repository` | `string` | `"docker.io/helmforge/mc"` | MinIO Client image repository |
| `backup.images.uploader.tag` | `string` | `"1.0.0"` | MinIO Client image tag |
| `backup.images.mysql.repository` | `string` | `"docker.io/library/mysql"` | MySQL dump container image repository |
| `backup.images.mysql.tag` | `string` | `"8.4"` | MySQL dump container image tag |
| `backup.s3.endpoint` | `string` | `""` | S3-compatible object store endpoint URL |
| `backup.s3.bucket` | `string` | `""` | S3 bucket name |
| `backup.s3.prefix` | `string` | `"uptime-kuma"` | Path prefix inside the S3 bucket |
| `backup.s3.createBucketIfNotExists` | `bool` | `true` | Create S3 bucket automatically if missing |
| `backup.s3.existingSecret` | `string` | `""` | Existing Secret containing S3 access credentials |
| `backup.s3.accessKey` | `string` | `""` | S3 access key (when existingSecret is unset) |
| `backup.s3.secretKey` | `string` | `""` | S3 secret key (when existingSecret is unset) |
| `extraVolumes` | `list` | `[]` | Extra volumes mounted into pods |
| `extraVolumeMounts` | `list` | `[]` | Extra volume mounts attached to the container |
| `extraManifests` | `list` | `[]` | Extra Kubernetes manifests rendered alongside module |
| `gatewayAPI.enabled` | `bool` | `false` | Render Gateway API HTTPRoute resources |
| `gatewayAPI.gatewayClassName` | `string` | `""` | GatewayClass name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | HTTPRoute specifications with parentRefs and rules |
| `externalSecrets.enabled` | `bool` | `false` | Render ExternalSecret resources |
| `externalSecrets.apiVersion` | `string` | `"external-secrets.io/v1"` | ExternalSecret API version |
| `externalSecrets.refreshInterval` | `string` | `"1h"` | Provider sync interval |
| `externalSecrets.items` | `list` | `[]` | ExternalSecret definitions |
| `mysql.enabled` | `bool` | `true` | Enable bundled MySQL / MariaDB subchart |
| `mysql.architecture` | `string` | `"standalone"` | MySQL architecture mode (`standalone`) |
| `mysql.image.repository` | `string` | `"docker.io/library/mysql"` | MySQL container image repository |
| `mysql.image.tag` | `string` | `"9.7.2"` | MySQL container image tag |
| `mysql.image.pullPolicy` | `string` | `"IfNotPresent"` | MySQL image pull policy |
| `mysql.auth.database` | `string` | `"uptime_kuma"` | MySQL database name |
| `mysql.auth.username` | `string` | `"uptime_kuma"` | MySQL user name |
| `mysql.auth.password` | `string` | `"mysql_password"` | MySQL user password |
| `mysql.resources.requests.cpu` | `string` | `"250m"` | MySQL CPU request |
| `mysql.resources.requests.memory` | `string` | `"512Mi"` | MySQL memory request |
| `mysql.resources.limits.cpu` | `string` | `"500m"` | MySQL CPU limit |
| `mysql.resources.limits.memory` | `string` | `"1Gi"` | MySQL memory limit |

---

### Recommended values

Uptime Kuma workloads comply with the **Restricted** Kubernetes Pod Security Standard by running as the unprivileged non-root user (UID/GID 65510:65510), dropping all Linux capabilities (`drop: ["ALL"]`), setting `allowPrivilegeEscalation: false`, and applying a default `RuntimeDefault` seccomp profile:

```cue
values: {
	podSecurityContext: {
		fsGroup:             10001
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		runAsUser:                65510
		runAsGroup:               65510
		capabilities: {
			drop: [
				"ALL",
			]
		}
	}
}
```

---

## Additional Resources

- [Official Uptime Kuma Website](https://uptime.kuma.pet)
- [Official Uptime Kuma GitHub Repository](https://github.com/louislam/uptime-kuma)
- [Uptime Kuma HelmForge Repository](https://github.com/helmforgedev/charts/tree/main/charts/uptime-kuma)
- [Timoni Documentation](https://timoni.sh)

---

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Uptime Kuma module workloads:

| Workload | Kind | Kubesec Score | Status |
| :--- | :--- | :--- | :--- |
| Uptime Kuma Web Workload (`uptime-kuma`) | Deployment | 13 points | ✅ |
| MySQL Database Workload (`uptime-kuma-mysql`) | StatefulSet | 13 points | ✅ |
