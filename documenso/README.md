# Documenso

## Description

[Documenso](https://documenso.com/) is an open-source, modern document signing platform designed as an alternative to proprietary e-signature tools. Built with Next.js, Prisma, and TypeScript, Documenso provides complete control over document lifecycle workflows, cryptographic signing, tamper-evident audit trails, and customizable signing fields. It supports asynchronous background processing through BullMQ and Redis, scalable document storage via S3 or PostgreSQL, and seamless integration with PKCS#12 signing certificates.

## Application Information
- **Version:** `2.22.0`
- **Official Website:** [https://documenso.com/](https://documenso.com/)
- **Upstream Project:** [https://github.com/documenso/documenso](https://github.com/documenso/documenso)
- **Container Base:**
  - Documenso Application: [ghcr.io/documenso/documenso](https://github.com/documenso/documenso/pkgs/container/documenso) (`ghcr.io/documenso/documenso:v2.22.0@sha256:f9976d2142d34ee89506e161b0a5ec859a0c327f3fe0a398b46d3941fc8dd35e`)
  - Database Backend (PostgreSQL): [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`postgres:18.6-trixie`)
  - Cache / Queue Backend (Redis/Valkey): [docker.io/valkey/valkey](https://hub.docker.com/r/valkey/valkey) (`valkey:9.2`)
  - Dependency Wait Container (BusyBox): [docker.io/library/busybox](https://hub.docker.com/_/busybox) (`busybox:1.37.0@sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **Documenso Server Workload (`documenso`):** Core full-stack application server executing Next.js web application, REST API endpoints, Prisma database schema migrations, and PDF signing workflows running on HTTP port `3000`.
- **Deployment (`documenso`):** Cloud-native deployment enforcing unprivileged execution (`runAsUser: 1001`), read-only root filesystem, Linux capability drops (`ALL`), dedicated ephemeral writable runtime directories, and dependency initialization checks.
- **Dependency Wait InitContainer (`wait-for-services`):** Unprivileged BusyBox container verifying network socket reachability for PostgreSQL and Redis prior to application boot.
- **Mailcatcher / Inbucket (`documenso-inbucket`):** Built-in development email capture server (`inbucket/inbucket`) providing complete parity with upstream Docker Compose (SMTP port `2500`, Web UI port `9000`, POP3 port `1100`). Automatically intercepts outgoing verification, signup, and signature request emails during testing.
- **Service (`documenso`):** Kubernetes Service exposing the web application and API on port `3000`.
- **Application Secret (`documenso`):** Retained Kubernetes Secret storing auto-generated `NEXTAUTH_SECRET`, `NEXT_PRIVATE_ENCRYPTION_KEY`, and `NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY`.
- **ServiceAccount (`documenso`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **PodDisruptionBudget (`documenso`):** Availability protection ensuring at least `1` replica remains online during voluntary disruptions.
- **HorizontalPodAutoscaler (`documenso`):** Optional autoscaling mechanism scaling replicas based on target CPU utilization (requires BullMQ and S3 object storage).
- **Bundled PostgreSQL (`documenso-postgresql`):** Bundled standalone PostgreSQL StatefulSet (`postgres:18.6-trixie`), headless and ClusterIP services, initialization scripts, dedicated service account, and persistent data storage (`8Gi`).
- **Bundled Redis / Valkey (`documenso-redis`):** Bundled standalone Valkey StatefulSet (`valkey:9.2`) powering BullMQ job queues, password authentication, headless and ClusterIP services, dedicated service account, and persistent data storage (`1Gi`).
- **Gateway API HTTPRoute (`documenso`):** Optional Gateway API HTTPRoute resource for modern routing via Kubernetes Gateway API controllers.
- **ExternalSecret (`documenso`):** Optional External Secrets Operator v1 resource for synchronizing application, database, SMTP, S3, and Redis credentials from external secret stores.

## Prerequisites

- Kubernetes cluster v1.30+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- **SMTP Server / Mail Provider (Required for Signups & Auth):** Documenso requires a functional SMTP service to send user registration, email verification, password reset, and signature invitation emails.
  - **Development / Testing:** Enable the built-in Inbucket mailcatcher (`inbucket.enabled: true`, active by default). It intercepts all emails sent by Documenso without requiring external mail credentials. The captured emails can be viewed via the Inbucket Web UI on port `9000`.
  - **Production:** Configure an external transactional email provider (e.g. SendGrid, Mailgun, Postmark, AWS SES, or standard SMTP) by setting `smtp.enabled: true` with host, port, credentials Secret, or disabling Inbucket (`inbucket.enabled: false`).
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active

## Install

To create an instance using default values:

```shell
timoni -n default apply documenso ./documenso
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	documenso: {
		publicUrl: "https://documenso.example.com"
		jobsProvider: "bullmq"
	}
	gatewayAPI: {
		enabled: true
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply documenso ./documenso \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete documenso
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `global` | `object` | `{}` | Values shared with HelmForge dependency charts |
| `nameOverride` | `string` | `""` | Override the chart name used in Kubernetes object names |
| `fullnameOverride` | `string` | `""` | Override the full release name used in Kubernetes object names |
| `commonLabels` | `object` | `{}` | Extra labels applied to every module resource |
| `commonAnnotations` | `object` | `{}` | Annotations applied to every module resource |
| `replicaCount` | `int` | `1` | Workload replica count (more than 1 requires BullMQ and S3 storage) |
| `autoscaling.enabled` | `bool` | `false` | Enable HorizontalPodAutoscaler (requires BullMQ and shared S3 storage) |
| `autoscaling.minReplicas` | `int` | `2` | Minimum replica count when autoscaling is enabled |
| `autoscaling.maxReplicas` | `int` | `5` | Maximum replica count when autoscaling is enabled |
| `autoscaling.targetCPUUtilizationPercentage` | `int` | `70` | Target average CPU utilization |
| `podDisruptionBudget.enabled` | `bool` | `true` | Create a PodDisruptionBudget for voluntary disruptions |
| `podDisruptionBudget.minAvailable` | `int` | `1` | Minimum available Documenso pods |
| `image.repository` | `string` | `"ghcr.io/documenso/documenso"` | Official Documenso image repository |
| `image.tag` | `string` | `"v2.22.0"` | Pinned official Documenso release tag |
| `image.digest` | `string` | `"sha256:f9976d2142d34ee89506e161b0a5ec859a0c327f3fe0a398b46d3941fc8dd35e"` | Immutable multi-architecture OCI manifest digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private mirrors |
| `documenso.publicUrl` | `string` | `""` | Canonical public URL (empty derives from first HTTPRoute hostname) |
| `documenso.mailFromAddress` | `string` | `"noreply@example.com"` | Sender email address used by transactional mail |
| `documenso.mailFromName` | `string` | `"Documenso"` | Sender display name used by transactional mail |
| `documenso.jobsProvider` | `string` | `"bullmq"` | Background-job provider: `local`, `bullmq`, or `inngest` |
| `documenso.existingSecret` | `string` | `""` | Existing Secret containing authentication and encryption keys |
| `documenso.nextAuthSecretKey` | `string` | `"nextauth-secret"` | Key containing `NEXTAUTH_SECRET` |
| `documenso.encryptionKeyKey` | `string` | `"encryption-key"` | Key containing `NEXT_PRIVATE_ENCRYPTION_KEY` |
| `documenso.encryptionSecondaryKeyKey` | `string` | `"encryption-secondary-key"` | Key containing `NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY` |
| `documenso.extraEnv` | `list` | `[]` | Additional environment entries for supported advanced upstream settings |
| `documenso.extraEnvFrom` | `list` | `[]` | Additional envFrom sources such as Secret or ConfigMap references |
| `database.external.enabled` | `bool` | `false` | Use an externally managed PostgreSQL database instead of the bundled subchart |
| `database.external.existingSecret` | `string` | `""` | Existing Secret containing complete, URL-encoded PostgreSQL URLs |
| `database.external.urlKey` | `string` | `"database-url"` | Key containing `NEXT_PRIVATE_DATABASE_URL` |
| `database.external.directUrlKey` | `string` | `"direct-database-url"` | Key containing `NEXT_PRIVATE_DIRECT_DATABASE_URL` |
| `database.external.directUrlEnabled` | `bool` | `false` | Whether the direct URL key exists in the Secret |
| `database.external.host` | `string` | `""` | TCP host used by dependency waiting |
| `database.external.port` | `int` | `5432` | PostgreSQL TCP port |
| `database.external.networkPolicyPeers` | `list` | `[]` | NetworkPolicy peers allowed to the external database |
| `postgresql.enabled` | `bool` | `true` | Deploy bundled standalone PostgreSQL subchart |
| `postgresql.architecture` | `string` | `"standalone"` | PostgreSQL architecture pattern |
| `postgresql.image.repository` | `string` | `"docker.io/library/postgres"` | Container image repository for PostgreSQL |
| `postgresql.image.tag` | `string` | `"18.6-trixie"` | Container image tag for PostgreSQL |
| `postgresql.image.digest` | `string` | `""` | Optional immutable manifest digest for PostgreSQL |
| `postgresql.image.pullPolicy` | `string` | `"IfNotPresent"` | PostgreSQL image pull policy |
| `postgresql.auth.database` | `string` | `"documenso"` | Application database created on first initialization |
| `postgresql.auth.username` | `string` | `"documenso"` | Application database user |
| `postgresql.auth.password` | `string` | `""` | Application password (auto-generated if empty) |
| `postgresql.auth.postgresPassword` | `string` | `""` | Administrative password (auto-generated if empty) |
| `postgresql.resources.requests.cpu` | `string` | `"100m"` | Compute CPU request for PostgreSQL |
| `postgresql.resources.requests.memory` | `string` | `"256Mi"` | Compute memory request for PostgreSQL |
| `postgresql.resources.limits.cpu` | `string` | `"1"` | Compute CPU limit for PostgreSQL |
| `postgresql.resources.limits.memory` | `string` | `"1Gi"` | Compute memory limit for PostgreSQL |
| `postgresql.podSecurityContext.fsGroup` | `int` | `999` | PostgreSQL pod filesystem group GID |
| `postgresql.podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `postgresql.podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `postgresql.securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `postgresql.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `postgresql.securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount container image root as read-only |
| `postgresql.securityContext.runAsGroup` | `int` | `999` | Container group GID |
| `postgresql.securityContext.runAsNonRoot` | `bool` | `true` | Run container processes as non-root |
| `postgresql.securityContext.runAsUser` | `int` | `999` | Container user UID |
| `postgresql.standalone.persistence.enabled` | `bool` | `true` | Persist PostgreSQL data |
| `postgresql.standalone.persistence.size` | `string` | `"8Gi"` | Requested PostgreSQL PVC capacity |
| `postgresql.standalone.resources.requests.cpu` | `string` | `"100m"` | Standalone PostgreSQL compute CPU request |
| `postgresql.standalone.resources.requests.memory` | `string` | `"256Mi"` | Standalone PostgreSQL compute memory request |
| `postgresql.standalone.resources.limits.cpu` | `string` | `"1"` | Standalone PostgreSQL compute CPU limit |
| `postgresql.standalone.resources.limits.memory` | `string` | `"1Gi"` | Standalone PostgreSQL compute memory limit |
| `redis.enabled` | `bool` | `true` | Deploy bundled Redis (required when jobsProvider is bullmq) |
| `redis.architecture` | `string` | `"standalone"` | Redis architecture pattern |
| `redis.image.repository` | `string` | `"docker.io/valkey/valkey"` | Container image repository for Redis / Valkey |
| `redis.image.tag` | `string` | `"9.2"` | Container image tag for Redis / Valkey |
| `redis.image.digest` | `string` | `""` | Optional immutable manifest digest for Redis |
| `redis.image.pullPolicy` | `string` | `"IfNotPresent"` | Redis image pull policy |
| `redis.auth.enabled` | `bool` | `true` | Require password authentication for Redis |
| `redis.auth.password` | `string` | `""` | Redis password (auto-generated if empty) |
| `redis.resources.requests.cpu` | `string` | `"50m"` | Compute CPU request for Redis |
| `redis.resources.requests.memory` | `string` | `"128Mi"` | Compute memory request for Redis |
| `redis.resources.limits.cpu` | `string` | `"500m"` | Compute CPU limit for Redis |
| `redis.resources.limits.memory` | `string` | `"512Mi"` | Compute memory limit for Redis |
| `redis.podSecurityContext.fsGroup` | `int` | `999` | Redis pod filesystem group GID |
| `redis.podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `redis.podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `redis.securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent privilege escalation |
| `redis.securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `redis.securityContext.readOnlyRootFilesystem` | `bool` | `false` | Mount container image root as read-only |
| `redis.securityContext.runAsGroup` | `int` | `999` | Container group GID |
| `redis.securityContext.runAsNonRoot` | `bool` | `true` | Run container processes as non-root |
| `redis.securityContext.runAsUser` | `int` | `999` | Container user UID |
| `redis.standalone.persistence.enabled` | `bool` | `true` | Persist queued jobs |
| `redis.standalone.persistence.size` | `string` | `"1Gi"` | Requested Redis PVC capacity |
| `redis.standalone.resources.requests.cpu` | `string` | `"50m"` | Standalone Redis compute CPU request |
| `redis.standalone.resources.requests.memory` | `string` | `"128Mi"` | Standalone Redis compute memory request |
| `redis.standalone.resources.limits.cpu` | `string` | `"500m"` | Standalone Redis compute CPU limit |
| `redis.standalone.resources.limits.memory` | `string` | `"512Mi"` | Standalone Redis compute memory limit |
| `redis.external.enabled` | `bool` | `false` | Use an external Redis service |
| `redis.external.host` | `string` | `""` | External Redis hostname |
| `redis.external.port` | `int` | `6379` | External Redis port |
| `redis.external.database` | `int` | `0` | Redis logical database |
| `redis.external.existingSecret` | `string` | `""` | Existing Secret containing the Redis password |
| `redis.external.passwordKey` | `string` | `"redis-password"` | Key containing the Redis password |
| `redis.external.networkPolicyPeers` | `list` | `[]` | NetworkPolicy peers allowed to external Redis |
| `smtp.enabled` | `bool` | `false` | Enable authenticated SMTP configuration |
| `smtp.host` | `string` | `""` | SMTP hostname |
| `smtp.port` | `int` | `587` | SMTP port |
| `smtp.secure` | `bool` | `false` | Use implicit TLS |
| `smtp.existingSecret` | `string` | `""` | Existing Secret containing SMTP credentials |
| `smtp.usernameKey` | `string` | `"username"` | Key containing the SMTP username |
| `smtp.passwordKey` | `string` | `"password"` | Key containing the SMTP password |
| `inbucket.enabled` | `bool` | `true` | Deploy bundled Inbucket mailcatcher for local testing and email verification (active only when `smtp.enabled: false`) |
| `inbucket.image.repository` | `string` | `"docker.io/inbucket/inbucket"` | Inbucket container image repository |
| `inbucket.image.tag` | `string` | `"main"` | Inbucket container image tag |
| `inbucket.image.digest` | `string` | `"sha256:bcbdd450835688f45bcc1fbe0cdd2876422e0c92548b91dd5aa5ecda926b8ee9"` | Inbucket container image digest |
| `inbucket.image.pullPolicy` | `string` | `"IfNotPresent"` | Pull policy for Inbucket |
| `inbucket.smtpPort` | `int` | `2500` | Inbucket SMTP port (Documenso routes mail here when smtp is disabled) |
| `inbucket.webPort` | `int` | `9000` | Inbucket Web UI port for reviewing captured emails |
| `inbucket.pop3Port` | `int` | `1100` | Inbucket POP3 port |
| `inbucket.resources.requests.cpu` | `string` | `"50m"` | Compute CPU request for Inbucket |
| `inbucket.resources.requests.memory` | `string` | `"64Mi"` | Compute memory request for Inbucket |
| `inbucket.resources.limits.cpu` | `string` | `"500m"` | Compute CPU limit for Inbucket |
| `inbucket.resources.limits.memory` | `string` | `"256Mi"` | Compute memory limit for Inbucket |
| `objectStorage.provider` | `string` | `"database"` | Storage provider: `database` or `s3` |
| `objectStorage.s3.bucket` | `string` | `""` | S3 bucket |
| `objectStorage.s3.region` | `string` | `"us-east-1"` | AWS region |
| `objectStorage.s3.endpoint` | `string` | `""` | Optional S3-compatible endpoint |
| `objectStorage.s3.forcePathStyle` | `bool` | `false` | Force path-style access for S3-compatible providers |
| `objectStorage.s3.existingSecret` | `string` | `""` | Existing Secret containing S3 credentials |
| `objectStorage.s3.accessKeyKey` | `string` | `"access-key"` | Key containing the access key |
| `objectStorage.s3.secretKeyKey` | `string` | `"secret-key"` | Key containing the secret key |
| `certificate.enabled` | `bool` | `false` | Enable a PKCS#12 signing certificate mounted from a Secret |
| `certificate.existingSecret` | `string` | `""` | Existing Secret containing the certificate and passphrase |
| `certificate.fileKey` | `string` | `"signing-certificate.p12"` | Key containing the binary PKCS#12 certificate |
| `certificate.passphraseKey` | `string` | `"passphrase"` | Key containing its passphrase |
| `certificate.mountPath` | `string` | `"/var/run/documenso/certificate/signing-certificate.p12"` | Mount path exposed through NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH |
| `gotenberg.enabled` | `bool` | `false` | Enable an external Gotenberg document-conversion service |
| `gotenberg.url` | `string` | `""` | Gotenberg base URL |
| `gotenberg.existingSecret` | `string` | `""` | Optional existing Secret containing Basic Auth credentials |
| `gotenberg.usernameKey` | `string` | `"username"` | Username key in the Secret |
| `gotenberg.passwordKey` | `string` | `"password"` | Password key in the Secret |
| `externalSecrets.enabled` | `bool` | `false` | Render ExternalSecret resources |
| `externalSecrets.refreshInterval` | `string` | `"1h"` | Default refresh interval for external secrets |
| `externalSecrets.items` | `list` | `[]` | Native ExternalSecret definitions using name/fullnameOverride and spec |
| `serviceAccount.create` | `bool` | `true` | Create a dedicated ServiceAccount |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name (empty uses release fullname) |
| `serviceAccount.annotations` | `object` | `{}` | Additional ServiceAccount annotations |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Keep the Kubernetes API token unmounted |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `3000` | Service port |
| `service.annotations` | `object` | `{}` | Additional Service annotations |
| `service.ipFamilyPolicy` | `string` | `""` | Service IP family policy (empty inherits cluster default) |
| `service.ipFamilies` | `list` | `[]` | Ordered Service address families (empty inherits cluster default) |
| `gatewayAPI.enabled` | `bool` | `false` | Render Gateway API HTTPRoutes |
| `gatewayAPI.publicUrlScheme` | `string` | `"https"` | Scheme used when deriving `documenso.publicUrl` |
| `gatewayAPI.httpRoutes` | `list` | `[]` | Route definitions with parentRefs, hostnames, rules, labels, annotations |
| `probes.startup.enabled` | `bool` | `true` | Enable startup probe through `/api/health` |
| `probes.startup.initialDelaySeconds` | `int` | `5` | Seconds before the first startup probe |
| `probes.startup.periodSeconds` | `int` | `5` | Seconds between startup probes |
| `probes.startup.timeoutSeconds` | `int` | `5` | Timeout for one startup probe |
| `probes.startup.failureThreshold` | `int` | `60` | Failures allowed while Prisma migrations complete |
| `probes.liveness.enabled` | `bool` | `true` | Enable dependency-independent TCP liveness |
| `probes.liveness.initialDelaySeconds` | `int` | `0` | Seconds before the first liveness probe |
| `probes.liveness.periodSeconds` | `int` | `20` | Seconds between liveness probes |
| `probes.liveness.timeoutSeconds` | `int` | `5` | Timeout for one liveness probe |
| `probes.liveness.failureThreshold` | `int` | `3` | Consecutive failures before restart |
| `probes.readiness.enabled` | `bool` | `true` | Enable readiness through `/api/health` |
| `probes.readiness.initialDelaySeconds` | `int` | `0` | Seconds before the first readiness probe |
| `probes.readiness.periodSeconds` | `int` | `10` | Seconds between readiness probes |
| `probes.readiness.timeoutSeconds` | `int` | `5` | Timeout for one readiness probe |
| `probes.readiness.failureThreshold` | `int` | `3` | Consecutive failures before traffic is withdrawn |
| `waitForServices.image.repository` | `string` | `"docker.io/library/busybox"` | Official BusyBox image used to wait for state services |
| `waitForServices.image.tag` | `string` | `"1.37.0"` | Pinned multi-platform BusyBox tag |
| `waitForServices.image.digest` | `string` | `"sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e"` | Pinned multi-platform BusyBox digest |
| `waitForServices.image.pullPolicy` | `string` | `"IfNotPresent"` | Pull policy for the dependency wait image |
| `waitForServices.timeoutSeconds` | `int` | `180` | Maximum seconds each dependency wait loop may run |
| `waitForServices.resources.requests.cpu` | `string` | `"10m"` | Compute CPU request for dependency wait container |
| `waitForServices.resources.requests.memory` | `string` | `"16Mi"` | Compute memory request for dependency wait container |
| `waitForServices.resources.limits.cpu` | `string` | `"100m"` | Compute CPU limit for dependency wait container |
| `waitForServices.resources.limits.memory` | `string` | `"64Mi"` | Compute memory limit for dependency wait container |
| `resources.requests.cpu` | `string` | `"250m"` | Compute CPU request for Documenso |
| `resources.requests.memory` | `string` | `"512Mi"` | Compute memory request for Documenso |
| `resources.limits.cpu` | `string` | `"1"` | Compute CPU limit for Documenso |
| `resources.limits.memory` | `string` | `"1Gi"` | Compute memory limit for Documenso |
| `podSecurityContext.runAsNonRoot` | `bool` | `true` | Run container processes as non-root |
| `podSecurityContext.runAsUser` | `int` | `1001` | UID of the non-root user |
| `podSecurityContext.runAsGroup` | `int` | `1001` | GID of the non-root group |
| `podSecurityContext.fsGroup` | `int` | `1001` | GID for volumes mounted to the pod |
| `podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Policy for volume ownership modifications |
| `podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent escalation of privileges |
| `securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount the root filesystem as read-only |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped for security hardening |
| `runtimeStorage.sizeLimit` | `string` | `"512Mi"` | Capacity limit for the runtime ephemeral storage |
| `terminationGracePeriodSeconds` | `int` | `60` | Grace period for in-flight requests and background jobs |
| `podLabels` | `object` | `{}` | Additional pod labels |
| `podAnnotations` | `object` | `{}` | Additional pod annotations |
| `nodeSelector` | `object` | `{}` | Node labels required for scheduling |
| `tolerations` | `list` | `[]` | Node taints tolerated by the pod |
| `affinity` | `object` | `{}` | Pod scheduling affinity |
| `topologySpreadConstraints` | `list` | `[]` | Topology spread constraints |
| `priorityClassName` | `string` | `""` | Optional PriorityClass name |
| `extraVolumes` | `list` | `[]` | Additional volumes |
| `extraVolumeMounts` | `list` | `[]` | Additional volume mounts |

## Additional Resources

- **Official Website:** [https://documenso.com/](https://documenso.com/)
- **Documentation:** [https://docs.documenso.com/](https://docs.documenso.com/)
- **Upstream Source Code:** [https://github.com/documenso/documenso](https://github.com/documenso/documenso)
- **Timoni Documentation:** [https://timoni.sh/](https://timoni.sh/)

## Kubesec Scan Scores

| Resource | Score | Critical Findings | Advice |
| :--- | :--- | :--- | :--- |
| `Deployment/documenso.default` | 14 | None | Passed restricted pod security profile |
| `StatefulSet/documenso-postgresql.default` | 13 | None | Passed baseline / restricted profile |
| `StatefulSet/documenso-redis.default` | 13 | None | Passed baseline / restricted profile |

