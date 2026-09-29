# Hoppscotch

## Description
[Hoppscotch](https://hoppscotch.io/) is a lightweight, open-source API development ecosystem. Built from the ground up as a fast, privacy-first alternative to tools like Postman and Insomnia, it enables developers and teams to create, test, and document REST, GraphQL, and WebSocket APIs directly from the browser or desktop application.

## Application Information
- **Version:** 2026.8.0
- **Upstream Project:** [https://github.com/hoppscotch/hoppscotch](https://github.com/hoppscotch/hoppscotch)
- **Container Base:**
  - Hoppscotch: [docker.io/hoppscotch/hoppscotch](https://hub.docker.com/r/hoppscotch/hoppscotch) (`docker.io/hoppscotch/hoppscotch:2026.8.0`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Hoppscotch Core (`hoppscotch`):** All-in-one deployment bundling the web client, admin dashboard, backend REST API, and WebSocket gateway running on container port 8081. Includes init containers for database readiness checking, Prisma database migrations, and runtime asset preparation.
- **PostgreSQL Database (`postgresql`):** Dedicated PostgreSQL 18 StatefulSet managing application data, collections, environments, and team workspaces with persistent volume storage (`10Gi`).
- **PostgreSQL Extensions Job (`postgresql-extensions-job`):** Automated pre-upgrade hook Job ensuring required PostgreSQL extensions (`pg_trgm`) are created.
- **Kubernetes Service (`hoppscotch`):** ClusterIP service exposing port 80 routing internally to container port 8081.
- **PostgreSQL Services (`postgresql`, `postgresql-primary-headless`):** ClusterIP and headless services routing database traffic on port 5432.
- **Gateway API HTTPRoute (`httproute`):** Native Kubernetes Gateway API HTTPRoute resource routing external traffic through Envoy Gateway.
- **Application Secrets (`secret`, `postgresql-auth`):** Securely stores encryption keys (`data-encryption-key`), session signing keys (`webapp-server-signing-key`), and database credentials.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount assigned to Hoppscotch workloads with disabled token automounting.
- **PodDisruptionBudget (`pdb`):** High-availability policy ensuring minimum replica availability during voluntary disruptions.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway) if HTTPRoute routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply hoppscotch ./hoppscotch
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	baseUrl:       "http://hoppscotch.example.com"
	adminUrl:      "http://admin.hoppscotch.example.com"
	backendApiUrl: "http://api.hoppscotch.example.com/v1"
	resources: {
		requests: {
			cpu:    "200m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "512Mi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply hoppscotch ./hoppscotch \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete hoppscotch
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the module name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `commonLabels` | map | `{}` | Labels added to every resource created by this module |
| `image.repository` | string | `"docker.io/hoppscotch/hoppscotch"` | Hoppscotch container image repository |
| `image.tag` | string | `"2026.8.0"` | Pinned container image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | list | `[]` | Secrets for authenticating against private container registries |
| `baseUrl` | string | `"http://localhost:3000"` | Public web client application URL |
| `adminUrl` | string | `"http://localhost:3100"` | Public admin dashboard application URL |
| `backendApiUrl` | string | `"http://localhost:3170/v1"` | Public backend REST API URL |
| `backendGqlUrl` | string | `"http://localhost:3170/graphql"` | Public backend GraphQL endpoint URL |
| `backendWsUrl` | string | `"ws://localhost:3170/graphql"` | Public backend WebSocket endpoint URL |
| `whitelistedOrigins` | string | `""` | Comma-separated list of allowed CORS origins |
| `encryption.key` | string | `"default-32-char-encryption-key-!"` | 32-character encryption key for stored secrets |
| `signingKey.key` | string | *(generated key)* | Secret key for signing webapp authentication tokens |
| `auth.providers` | string | `"EMAIL,GITHUB"` | Comma-separated list of enabled authentication providers |
| `auth.github.enabled` | bool | `true` | Enable GitHub OAuth provider |
| `auth.google.enabled` | bool | `false` | Enable Google OAuth provider |
| `auth.microsoft.enabled` | bool | `false` | Enable Microsoft OAuth provider |
| `service.port` | int | `80` | Kubernetes Service port for Hoppscotch |
| `service.containerPort` | int | `8081` | Container port for the all-in-one Hoppscotch binary |
| `gateway.enabled` | bool | `true` | Enable Gateway API HTTPRoute resource generation |
| `resources` | object | `{requests: {cpu: "200m", memory: "256Mi"}, limits: {cpu: "1000m", memory: "512Mi"}}` | Resource requests and limits for Hoppscotch |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL StatefulSet |
| `postgresql.image.repository` | string | `"docker.io/library/postgres"` | PostgreSQL container image repository |
| `postgresql.image.tag` | string | `"18.6-trixie"` | PostgreSQL container image tag |
| `postgresql.auth.database` | string | `"hoppscotch"` | Database name for Hoppscotch data |
| `postgresql.auth.username` | string | `"hoppscotch"` | PostgreSQL username |
| `postgresql.standalone.persistence.size` | string | `"10Gi"` | Persistent volume size for PostgreSQL storage |
| `postgresql.standalone.resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Resource requests and limits for PostgreSQL |

### Recommended values

Comply with the restricted Kubernetes pod security standards:

```cue
values: {
	podSecurityContext: {
		fsGroup:      1000
		runAsNonRoot: true
	}
	containerSecurityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		runAsUser:                1000
		capabilities: drop: ["ALL"]
	}
}
```

## Additional Resources
- [Official Hoppscotch Website](https://hoppscotch.io/)
- [Official Hoppscotch Repository](https://github.com/hoppscotch/hoppscotch)
- [Hoppscotch Documentation](https://docs.hoppscotch.io/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Hoppscotch module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Hoppscotch Core (`hoppscotch`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`postgresql`) | StatefulSet | 12 points | ✅ |
