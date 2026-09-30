# Metabase

## Description
[Metabase](https://www.metabase.com/) is an open-source business intelligence and data analytics platform that allows teams to explore data, build interactive dashboards, and generate automated reports without requiring technical SQL knowledge. By lowering technical barriers while preserving enterprise governance and data security, Metabase empowers organizations to make data-driven decisions seamlessly.

## Application Information
- **Version:** 0.1.0 (App: v0.63.5)
- **Upstream Project:** [https://github.com/metabase/metabase](https://github.com/metabase/metabase)
- **Container Base:** [docker.io/metabase/metabase](https://hub.docker.com/r/metabase/metabase) (`docker.io/metabase/metabase:v0.63.5`), [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.4-trixie`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Metabase Core (`metabase-metabase`):** Primary web interface, query execution, and analytics engine running `docker.io/metabase/metabase:v0.63.5` on container port 3000, with an init container (`docker.io/library/busybox:1.37`) ensuring database readiness before startup.
- **PostgreSQL Database Subchart (`metabase-postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`docker.io/library/postgres:18.4-trixie`) providing persistent relational storage (`8Gi`) for Metabase application metadata, dashboards, collections, queries, and user accounts.
- **Application Secret (`appSecret`):** Securely stores the cryptographic `encryptionSecretKey` used to encrypt connected database credentials and integrations.
- **Kubernetes Service (`svc`):** ClusterIP service exposing port 80 routing internally to container port 3000.
- **Gateway API HTTPRoute (`httproute`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource providing modern Kubernetes Gateway API ingress routing.
- **Database Backup CronJob (`backupCronJob`):** Optional automated scheduled backup Job (`pg_dump` + MinIO client `mc`) streaming database dumps to S3-compatible object storage.
- **External Secrets Operator (`externalSecret`):** Optional ExternalSecret integration syncing credentials from external secret management vaults.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount for Metabase pods.

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway controller if HTTPRoute is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply metabase ./metabase
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	metabase: {
		siteUrl: "https://analytics.example.com"
	}
	gateway: {
		hostnames: ["analytics.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply metabase ./metabase \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete metabase
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the module name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `commonLabels` | map | `{}` | Additional common labels applied to all resources |
| `image.repository` | string | `"docker.io/metabase/metabase"` | Metabase container image repository |
| `image.tag` | string | `"v0.63.5"` | Metabase container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Container image pull policy |
| `metabase.port` | int | `3000` | Port where Metabase listens inside container |
| `metabase.siteUrl` | string | `""` | Full external public URL of the Metabase instance |
| `metabase.encryptionSecretKey` | string | `""` | Base64-encoded key used to encrypt connected database credentials |
| `metabase.existingSecret` | string | `""` | Existing Kubernetes secret containing encryption key |
| `metabase.existingSecretKey` | string | `"encryption-secret-key"` | Key within existing secret for encryption key |
| `metabase.aiFeaturesEnabled` | bool | `false` | Enable AI-assisted query and dashboard features |
| `metabase.javaTimezone` | string | `"UTC"` | Timezone configuration for the Java runtime |
| `metabase.javaOpts` | string | `""` | Extra JVM options passed to Java runtime |
| `serviceAccount.create` | bool | `true` | Create dedicated ServiceAccount for Metabase pods |
| `service.type` | string | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | int | `80` | Port exposed by Kubernetes Service (routes to 3000) |
| `gateway.enabled` | bool | `true` | Enable Kubernetes Gateway API HTTPRoute creation |
| `gateway.hostnames` | list | `[]` | List of hostnames matched by HTTPRoute |
| `gateway.path` | string | `"/"` | Path prefix for HTTPRoute routing |
| `resources.requests.cpu` | string | `"250m"` | CPU request for Metabase container |
| `resources.requests.memory` | string | `"512Mi"` | Memory request for Metabase container |
| `resources.limits.cpu` | string | `"1000m"` | CPU limit for Metabase container |
| `resources.limits.memory` | string | `"2Gi"` | Memory limit for Metabase container |
| `podSecurityContext.runAsUser` | int | `65510` | Non-root UID for pod execution |
| `podSecurityContext.runAsGroup` | int | `65510` | Non-root GID for pod execution |
| `podSecurityContext.fsGroup` | int | `65510` | Filesystem group ID for volume ownership |
| `podSecurityContext.seccompProfile.type` | string | `"RuntimeDefault"` | Pod-level seccomp profile |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Prevent gaining more privileges than parent process |
| `securityContext.readOnlyRootFilesystem` | bool | `true` | Enforce read-only root filesystem |
| `securityContext.runAsNonRoot` | bool | `true` | Enforce non-root execution inside container |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Linux kernel capabilities dropped from container |
| `backup.enabled` | bool | `false` | Enable automated S3 database backups |
| `backup.schedule` | string | `"0 3 * * *"` | Cron schedule for database backup CronJob |
| `backup.s3.endpoint` | string | `""` | S3-compatible endpoint URL for backups |
| `backup.s3.bucket` | string | `""` | S3 bucket name for backups |
| `backup.s3.prefix` | string | `"metabase"` | Key prefix within the S3 bucket |
| `database.external.host` | string | `""` | Hostname of external PostgreSQL database (when internal subchart is disabled) |
| `database.external.port` | string | `"5432"` | Port of external PostgreSQL database |
| `database.external.name` | string | `"metabase"` | External PostgreSQL database name |
| `database.external.username` | string | `"metabase"` | External PostgreSQL username |
| `database.external.password` | string | `""` | External PostgreSQL password |
| `postgresql.enabled` | bool | `true` | Deploy dedicated PostgreSQL database subchart |
| `postgresql.image.repository` | string | `"docker.io/library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"18.4-trixie"` | PostgreSQL container image tag |
| `postgresql.auth.database` | string | `"metabase"` | Database name created on first run |
| `postgresql.auth.username` | string | `"metabase"` | Database user created on first run |
| `postgresql.auth.password` | string | `"change-me-please-db-password!"` | Password for PostgreSQL database user |
| `postgresql.standalone.persistence.enabled` | bool | `true` | Enable persistent storage for PostgreSQL data |
| `postgresql.standalone.persistence.size` | string | `"8Gi"` | Persistent Volume size requested for PostgreSQL |
| `postgresql.standalone.resources.requests.cpu` | string | `"100m"` | CPU request for PostgreSQL subchart |
| `postgresql.standalone.resources.requests.memory` | string | `"256Mi"` | Memory request for PostgreSQL subchart |
| `postgresql.standalone.resources.limits.cpu` | string | `"500m"` | CPU limit for PostgreSQL subchart |
| `postgresql.standalone.resources.limits.memory` | string | `"768Mi"` | Memory limit for PostgreSQL subchart |

## Recommended values

Metabase and PostgreSQL operate as dedicated unprivileged system users (`65510:65510`), dropping all Linux kernel capabilities (`drop: ["ALL"]`), with `allowPrivilegeEscalation: false` and `seccompProfile: RuntimeDefault`, conforming to Kubernetes Pod Security Standards (Restricted):

```cue
values: {
	podSecurityContext: {
		runAsUser:  65510
		runAsGroup: 65510
		fsGroup:    65510
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official Metabase Website](https://www.metabase.com/)
- [Official Metabase Repository](https://github.com/metabase/metabase)
- [Metabase Documentation](https://www.metabase.com/docs/latest/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Metabase module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Metabase Core (`metabase-metabase`) | Deployment | 14 points | ✅ |
| PostgreSQL Subchart (`metabase-postgresql`) | StatefulSet | 16 points | ✅ |
