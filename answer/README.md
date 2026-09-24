# Apache Answer

## Description
[Apache Answer](https://answer.apache.org/) is a free, open-source question-and-answer (Q&A) platform designed for software teams, developer communities, and organizations of all sizes. Built with Go and React, Answer provides community voting, reputation systems, rich markdown editing, content moderation, multilingual localization, and an extensible plugin architecture.

## Application Information
- **Version:** 2.0.2
- **Upstream Project:** [https://github.com/apache/answer](https://github.com/apache/answer)
- **Container Base:** [docker.io/apache/answer](https://hub.docker.com/r/apache/answer) (`docker.io/apache/answer:2.0.2`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Apache Answer Core (`deployment`):** The primary web and API server container running `docker.io/apache/answer:2.0.2` on container port 80, mounting persistent storage for file uploads, avatars, plugins, and SQLite databases.
- **Kubernetes Secret (`secret` / `admin`):** Securely stores the administrator username and password, mapped to container environment variables via `secretKeyRef` (mirroring upstream security architecture).
- **PersistentVolumeClaim (`pvc`):** Persistent storage mounted to `/data` (default `5Gi`, ReadWriteOnce) preserving uploaded files, cache, and SQLite database across pod restarts.
- **Kubernetes Service (`service`):** ClusterIP service exposing port 80 (named `http`) for cluster-internal access and ingress/gateway routing.
- **Gateway API HTTPRoute (`httproute`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource enabling modern ingress routing through Envoy Gateway, Traefik, Cilium, or other Gateway API controllers.
- **PostgreSQL Subchart (`pgDeploy`, `pgSVC`, `pgHeadlessSVC`, `pgSecret`):** Optional dedicated PostgreSQL 18 StatefulSet (`docker.io/library/postgres:18.6-trixie`) with persistent volume storage (`8Gi`), headless service, and automated secret generation.
- **MySQL Subchart (`mysqlDeploy`, `mysqlSVC`, `mysqlHeadlessSVC`, `mysqlSecret`):** Optional dedicated MySQL 9 StatefulSet (`docker.io/library/mysql:9.7.2`) with persistent volume storage (`8Gi`), headless service, and automated secret generation.
- **Database Backup CronJob (`backupCronJob`, `backupCM`):** Optional scheduled CronJob performing database-aware automated backups (full directory tar for SQLite, `pg_dump` for PostgreSQL, or `mysqldump` for MySQL) uploaded to S3-compatible object storage via MinIO Client (`docker.io/helmforge/mc:1.0.0`).
- **External Secrets Operator (`esAdmin`, `esDatabase`, `esBackup`):** Optional ExternalSecret resources syncing administrator passwords, database credentials, and S3 keys from external secret stores (Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault).
- **ServiceAccount (`serviceAccount`):** Dedicated unprivileged Kubernetes ServiceAccount for Answer pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway) if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply answer ./answer
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	answer: {
		siteUrl:      "https://qa.example.com"
		siteName:     "Community Q&A"
		contactEmail: "admin@example.com"
	}
	admin: {
		name:     "admin"
		password: "MySecurePassword123!"
		email:    "admin@example.com"
	}
	postgresql: {
		enabled: true
		auth: {
			database: "answer"
			username: "answer"
			password: "PostgresPassword123!"
		}
	}
	gateway: {
		enabled: true
		parentRefs: [{
			name:      "shared-gtw"
			namespace: "kube-system"
		}]
		hostnames: [
			"qa.example.com",
		]
	}
	resources: {
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply answer ./answer \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete answer
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/apache/answer` | Container image repository |
| `image.tag` | string | `2.0.2` | Pinned container image tag |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `image.digest` | string | `""` | Pinned container image digest |
| `imagePullSecrets` | list | `[]` | Image pull secrets for private registries |
| `answer.siteUrl` | string | `""` | Full external URL of the site (auto-detected from Ingress/Gateway if empty) |
| `answer.siteName` | string | `Apache Answer` | Site name displayed in the browser tab and header |
| `answer.language` | string | `en-US` | Default language for the UI |
| `answer.contactEmail` | string | `admin@example.com` | Contact email shown in the site footer and admin |
| `answer.externalContentDisplay` | string | `ask_before_display` | External content display policy (`always_display` or `ask_before_display`) |
| `answer.autoInstall` | bool | `true` | Enable automated unattended installation on first boot |
| `answer.logLevel` | string | `WARN` | Application logging level (`DEBUG`, `INFO`, `WARN`, `ERROR`) |
| `answer.notifications.newQuestionEmail.queueSize` | int | `1024` | Maximum new-question email tasks buffered by the worker |
| `answer.notifications.newQuestionEmail.sendIntervalSeconds` | int | `0` | Delay between new-question email attempts in seconds |
| `answer.extraEnv` | list | `[]` | Additional environment variables for the Answer container |
| `admin.name` | string | `admin` | Admin username for initial setup |
| `admin.password` | string | `Changeit@123.` | Admin password for initial setup (stored in Secret) |
| `admin.email` | string | `admin@example.com` | Admin email address |
| `admin.existingSecret` | string | `""` | Use an existing Kubernetes secret for admin credentials |
| `admin.existingSecretPasswordKey` | string | `admin-password` | Key in existing secret for admin password |
| `database.mode` | string | `auto` | Database mode (`auto`, `sqlite`, `external`, `postgresql`, `mysql`) |
| `database.sqlite.file` | string | `/data/answer.db` | SQLite database file path inside the data volume |
| `database.external.vendor` | string | `postgres` | External database vendor (`postgres` or `mysql`) |
| `database.external.host` | string | `""` | External database hostname |
| `database.external.port` | string | `""` | External database port (auto-detected from vendor if empty) |
| `database.external.name` | string | `answer` | External database name |
| `database.external.username` | string | `answer` | External database username |
| `database.external.password` | string | `""` | External database password |
| `database.external.existingSecret` | string | `""` | Existing secret for external database password |
| `database.external.existingSecretPasswordKey` | string | `database-password` | Key in existing secret for external database password |
| `postgresql.enabled` | bool | `true` | Deploy PostgreSQL subchart as a dedicated database |
| `postgresql.architecture` | string | `standalone` | PostgreSQL architecture (`standalone` or `replication`) |
| `postgresql.image.repository` | string | `docker.io/library/postgres` | PostgreSQL image repository |
| `postgresql.image.tag` | string | `18.6-trixie` | PostgreSQL image tag |
| `postgresql.auth.database` | string | `answer` | PostgreSQL database name created on first run |
| `postgresql.auth.username` | string | `answer` | PostgreSQL database username created on first run |
| `postgresql.auth.password` | string | `postgres_password` | PostgreSQL database password |
| `postgresql.resources.requests.cpu` | string | `250m` | PostgreSQL requested CPU capacity |
| `postgresql.resources.requests.memory` | string | `256Mi` | PostgreSQL requested memory capacity |
| `postgresql.resources.limits.cpu` | string | `500m` | PostgreSQL maximum CPU limit |
| `postgresql.resources.limits.memory` | string | `512Mi` | PostgreSQL maximum memory limit |
| `postgresql.standalone.persistence.enabled` | bool | `true` | Enable persistence for PostgreSQL data |
| `postgresql.standalone.persistence.size` | string | `8Gi` | PVC storage size for PostgreSQL data |
| `mysql.enabled` | bool | `false` | Deploy MySQL subchart as a dedicated database |
| `mysql.architecture` | string | `standalone` | MySQL architecture (`standalone` or `replication`) |
| `mysql.image.repository` | string | `docker.io/library/mysql` | MySQL image repository |
| `mysql.image.tag` | string | `9.7.2` | MySQL image tag |
| `mysql.auth.database` | string | `answer` | MySQL database name created on first run |
| `mysql.auth.username` | string | `answer` | MySQL database username created on first run |
| `mysql.auth.password` | string | `""` | MySQL database password |
| `mysql.auth.rootPassword` | string | `""` | MySQL root password |
| `mysql.standalone.persistence.enabled` | bool | `true` | Enable persistence for MySQL data |
| `mysql.standalone.persistence.size` | string | `8Gi` | PVC storage size for MySQL data |
| `persistence.enabled` | bool | `true` | Enable persistent storage for Answer data |
| `persistence.size` | string | `5Gi` | Storage capacity allocated for `/data` |
| `persistence.storageClass` | string | `""` | Storage class name (empty uses cluster default) |
| `persistence.accessMode` | string | `ReadWriteOnce` | Storage access mode for the PVC |
| `persistence.existingClaim` | string | `""` | Use an existing PVC instead of creating one |
| `resources.requests.cpu` | string | `100m` | Container requested CPU capacity |
| `resources.requests.memory` | string | `128Mi` | Container requested memory capacity |
| `resources.limits.cpu` | string | `500m` | Container maximum CPU limit |
| `resources.limits.memory` | string | `512Mi` | Container maximum memory limit |
| `securityContext.runAsNonRoot` | bool | `true` | Enforces running as a non-root user |
| `securityContext.runAsUser` | int | `65510` | Runs as dedicated non-root user |
| `securityContext.runAsGroup` | int | `65510` | Runs as dedicated non-root group |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Disables privilege escalation |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Drops all Linux capabilities |
| `securityContext.capabilities.add` | list | `["NET_BIND_SERVICE"]` | Linux capability allowing unprivileged binding to port 80 |
| `podSecurityContext.runAsNonRoot` | bool | `true` | Enforces non-root at pod level |
| `podSecurityContext.runAsUser` | int | `65510` | Dedicated pod user ID |
| `podSecurityContext.runAsGroup` | int | `65510` | Dedicated pod group ID |
| `podSecurityContext.fsGroup` | int | `65510` | Filesystem group matching Answer user |
| `podSecurityContext.seccompProfile.type` | string | `RuntimeDefault` | Pod-level runtime default seccomp profile |
| `startupProbe.enabled` | bool | `true` | Enable startup probe |
| `startupProbe.path` | string | `/healthz` | HTTP GET endpoint for startup probe |
| `livenessProbe.enabled` | bool | `true` | Enable liveness probe |
| `livenessProbe.path` | string | `/healthz` | HTTP GET endpoint for liveness probe |
| `readinessProbe.enabled` | bool | `true` | Enable readiness probe |
| `readinessProbe.path` | string | `/healthz` | HTTP GET endpoint for readiness probe |
| `service.type` | string | `ClusterIP` | Kubernetes service type |
| `service.port` | int | `80` | Service port exposed within the cluster |
| `service.annotations` | map | `{}` | Annotations applied to the Kubernetes Service |
| `gateway.enabled` | bool | `true` | Create a Gateway API HTTPRoute resource |
| `gateway.parentRefs` | list | `[]` | Gateway reference(s) to attach the HTTPRoute to |
| `gateway.hostnames` | list | `[]` | Optional domain hostnames matching inbound requests |
| `gateway.path` | string | `/` | Inbound URL path match value |
| `gateway.pathType` | string | `PathPrefix` | URL path match type (`PathPrefix` or `Exact`) |
| `gateway.annotations` | map | `{}` | Annotations applied to the HTTPRoute resource |
| `serviceAccount.create` | bool | `true` | Create a dedicated ServiceAccount for Answer |
| `serviceAccount.name` | string | `""` | Custom name for the ServiceAccount |
| `backup.enabled` | bool | `false` | Enable scheduled database-aware backups to S3 storage |
| `backup.schedule` | string | `0 3 * * *` | Cron schedule for backups (daily at 03:00 UTC) |
| `backup.images.sqlite` | string | `docker.io/library/alpine:3.22` | Image used for SQLite backup (with tar) |
| `backup.images.postgresql` | string | `docker.io/library/postgres:18.4-alpine` | Image used for PostgreSQL backup (with pg_dump) |
| `backup.images.mysql` | string | `docker.io/library/mysql:8.4` | Image used for MySQL backup (with mysqldump) |
| `backup.images.uploader` | string | `docker.io/helmforge/mc:1.0.0` | S3 uploader image (MinIO client) |
| `backup.s3.endpoint` | string | `""` | S3-compatible endpoint URL |
| `backup.s3.bucket` | string | `""` | Target S3 bucket name |
| `backup.s3.prefix` | string | `answer` | Key prefix within the bucket |
| `backup.s3.createBucketIfNotExists` | bool | `true` | Auto-create bucket if it does not exist |
| `backup.s3.existingSecret` | string | `""` | Use an existing secret for S3 credentials |
| `externalSecrets.enabled` | bool | `false` | Render ExternalSecret resources for External Secrets Operator |
| `externalSecrets.apiVersion` | string | `external-secrets.io/v1` | ExternalSecret API version |
| `externalSecrets.secretStoreRef.name` | string | `""` | Existing SecretStore or ClusterSecretStore name |
| `externalSecrets.admin.enabled` | bool | `false` | Render ExternalSecret for admin credentials |
| `externalSecrets.database.enabled` | bool | `false` | Render ExternalSecret for database credentials |
| `externalSecrets.backup.enabled` | bool | `false` | Render ExternalSecret for S3 backup credentials |

## Recommended values

Apache Answer operates as dedicated unprivileged system user `65510:65510`, dropping all Linux kernel capabilities (`drop: ["ALL"]`), granting only `NET_BIND_SERVICE` to bind port 80, with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`. This configuration complies with the restricted Kubernetes Pod Security Standard and achieves an unpenalized **13 points Kubesec score**:

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
		runAsUser:                65510
		runAsGroup:               65510
		runAsNonRoot:             true
		capabilities: {
			drop: [
				"ALL",
			]
			add: [
				"NET_BIND_SERVICE",
			]
		}
	}
}
```

## Additional Resources
- [Official Apache Answer Website](https://answer.apache.org/)
- [Official Apache Answer Repository](https://github.com/apache/answer)
- [Apache Answer Documentation](https://answer.apache.org/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Apache Answer module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Apache Answer Core (`answer`) | Deployment | 13 points | ✅  |
| PostgreSQL Subchart (`postgresql`) | StatefulSet | 15 points | ✅ |
| MySQL Subchart (`mysql`) | StatefulSet | 15 points | ✅ |
