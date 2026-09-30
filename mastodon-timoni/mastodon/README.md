# Mastodon

## Description
[Mastodon](https://joinmastodon.org/) is a free, decentralized, open-source social networking platform built on the W3C ActivityPub open protocol. Operating as a core pillar of the Fediverse, Mastodon enables independent servers ("instances") to interconnect seamlessly, allowing users to follow profiles, publish posts, share media, and interact across independent communities without central corporate control or algorithmic manipulation.

## Application Information
- **Version:** `v4.7.1`
- **Upstream Project:** [https://github.com/mastodon/mastodon](https://github.com/mastodon/mastodon)
- **Container Base:** [ghcr.io/mastodon/mastodon](https://github.com/mastodon/mastodon/pkgs/container/mastodon) (`ghcr.io/mastodon/mastodon:v4.7.1`, `ghcr.io/mastodon/mastodon-streaming:v4.7.1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Mastodon Web (`mastodon-web`):** Primary Ruby on Rails application Deployment running `ghcr.io/mastodon/mastodon:v4.7.1` on port `3000` (exposed via Service port `80`). Serves the web UI, REST API endpoints, ActivityPub federation routes, and OAuth identity services.
- **Mastodon Streaming API (`mastodon-streaming`):** High-concurrency Node.js WebSocket and Server-Sent Events (SSE) Deployment running `ghcr.io/mastodon/mastodon-streaming:v4.7.1` on port `4000`, dispatching real-time notifications and timeline events to connected clients.
- **Mastodon Sidekiq Worker (`mastodon-sidekiq`):** Asynchronous background job worker Deployment running `ghcr.io/mastodon/mastodon:v4.7.1` handling media processing, push/pull federation delivery, email notifications, and scheduled tasks.
- **PostgreSQL Database (`mastodon-postgresql`):** Relational database StatefulSet running `bitnamilegacy/postgresql:17.6.0-debian-12-r4` on port `5432` storing accounts, posts, relationships, and metadata.
- **Redis In-Memory Cache (`mastodon-redis-master`):** Key-value in-memory data store StatefulSet running `valkey/valkey:9.0.6-alpine` on port `6379` powering timeline caches, Sidekiq job queues, and WebSocket pub/sub messaging.
- **OpenSearch / Elasticsearch Engine (`mastodon-elasticsearch-master`):** Full-text search engine StatefulSet running `opensearchproject/opensearch:3.8.0` on port `9200` providing full-text search across posts, hashtags, and directory accounts.
- **Persistent Storage Volumes:**
  - **Media & System Storage (`system`):** Persistent Volume Claim (`100Gi`, ReadWriteOnce) storing uploaded media, avatars, and cached remote attachments.
  - **Assets Storage (`assets`):** Persistent Volume Claim (`10Gi`, ReadWriteOnce) for compiled assets.
  - **PostgreSQL Data:** Dedicated Persistent Volume for database persistence.
  - **OpenSearch Data:** Dedicated Persistent Volume for search indexes.
- **Kubernetes Services:** ClusterIP services exposing web traffic (port `80`), streaming (port `4000`), database (port `5432`), Redis (port `6379`), and OpenSearch (port `9200`).
- **Gateway API & Ingress:** Optional Gateway API `HTTPRoute` and Kubernetes `Ingress` resources for edge routing and TLS termination.
- **ServiceAccount (`serviceaccount`):** Dedicated unprivileged Kubernetes ServiceAccount for Mastodon workloads.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support (or S3/MinIO object storage for media files)
- Reverse proxy, Ingress Controller, or Gateway API router for external HTTPS access

## Install

To create an instance using default values:

```shell
timoni -n default apply mastodon ./mastodon-timoni/mastodon
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	mastodon: {
		local_domain: "social.example.com"
		web_domain:   "social.example.com"
		local_https:  true
		createAdmin: {
			username: "admin"
			email:    "admin@example.com"
		}
	}
	smtp: {
		server:       "smtp.mailgun.org"
		port:         587
		from_address: "notifications@social.example.com"
		login:        "postmaster@social.example.com"
		password:     "your-smtp-password"
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply mastodon ./mastodon-timoni/mastodon \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete mastodon
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | `string` | `"ghcr.io/mastodon/mastodon"` | Container image repository for Mastodon core |
| `image.tag` | `string` | `"v4.7.1"` | Container image tag for Mastodon core |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `mastodon.local_domain` | `string` | `"localhost"` | The domain used in user handles (e.g. `@user@example.com`) |
| `mastodon.web_domain` | `string` | `"localhost:8080"` | The public web domain where the instance is accessible |
| `mastodon.local_https` | `bool` | `false` | Whether the instance runs on HTTPS externally |
| `mastodon.singleUserMode` | `bool` | `false` | Enable single-user mode |
| `mastodon.authorizedFetch` | `bool` | `false` | Require authorized signatures for fetching ActivityPub objects |
| `mastodon.createAdmin.enabled` | `bool` | `true` | Create an initial administrator account on startup |
| `mastodon.createAdmin.username` | `string` | `"not_gargron"` | Initial administrator username |
| `mastodon.createAdmin.email` | `string` | `"admin@gmail.com"` | Initial administrator email |
| `mastodon.persistence.system.resources.requests.storage` | `string` | `"100Gi"` | Storage size for user-uploaded media and system files |
| `mastodon.persistence.assets.resources.requests.storage` | `string` | `"10Gi"` | Storage size for compiled web assets |
| `mastodon.web.replicas` | `int` | `2` | Number of web pod replicas |
| `mastodon.web.port` | `int` | `3000` | Mastodon Rails web server container port |
| `mastodon.web.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "512Mi"}, limits: {cpu: "1", memory: "1536Mi"}}` | Web pod resource requests and limits |
| `mastodon.streaming.image.repository` | `string` | `"ghcr.io/mastodon/mastodon-streaming"` | Container image repository for Streaming API |
| `mastodon.streaming.image.tag` | `string` | `"v4.7.1"` | Container image tag for Streaming API |
| `mastodon.streaming.replicas` | `int` | `2` | Number of streaming pod replicas |
| `mastodon.streaming.port` | `int` | `4000` | Streaming API container port |
| `mastodon.streaming.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Streaming pod resource requests and limits |
| `mastodon.sidekiq.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1", memory: "1024Mi"}}` | Sidekiq worker resource requests and limits |
| `mastodon.s3.enabled` | `bool` | `false` | Enable external S3-compatible object storage for media |
| `postgresql.enabled` | `bool` | `true` | Deploy internal PostgreSQL database StatefulSet |
| `postgresql.image.repository` | `string` | `"bitnamilegacy/postgresql"` | PostgreSQL container image repository |
| `postgresql.image.tag` | `string` | `"17.6.0-debian-12-r4"` | PostgreSQL container image tag |
| `postgresql.auth.database` | `string` | `"mastodon_production"` | Database name |
| `postgresql.auth.username` | `string` | `"mastodon"` | Database username |
| `redis.enabled` | `bool` | `true` | Deploy internal Redis/Valkey cache StatefulSet |
| `redis.image.repository` | `string` | `"valkey/valkey"` | Redis/Valkey container image repository |
| `redis.image.tag` | `string` | `"9.0.6-alpine"` | Redis/Valkey container image tag |
| `elasticsearch.enabled` | `bool` | `true` | Deploy OpenSearch/Elasticsearch full-text search StatefulSet |
| `elasticsearch.image.repository` | `string` | `"opensearchproject/opensearch"` | OpenSearch container image repository |
| `elasticsearch.image.tag` | `string` | `"3.8.0"` | OpenSearch container image tag |
| `elasticsearch.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "512Mi"}, limits: {cpu: "1", memory: "2048Mi"}}` | OpenSearch resource requests and limits |
| `serviceAccount.create` | `bool` | `true` | Create dedicated ServiceAccount |
| `serviceAccount.name` | `string` | `""` | Override ServiceAccount name |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | `int` | `80` | Kubernetes Service HTTP port |
| `podSecurityContext` | `corev1.#PodSecurityContext` | `{runAsUser: 991, runAsGroup: 991, fsGroup: 991}` | Pod-level security context |
| `securityContext` | `corev1.#SecurityContext` | `{runAsUser: 991, runAsNonRoot: true, allowPrivilegeEscalation: false, capabilities: drop: ["ALL"]}` | Container security context |
| `nodeSelector` | `{[string]: string}` | `{}` | Node selector labels for pod scheduling |
| `tolerations` | `[...corev1.#Toleration]` | `[]` | Tolerations for pod scheduling |
| `affinity` | `corev1.#Affinity` | `{}` | Affinity and anti-affinity scheduling rules |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:  991
		runAsGroup: 991
		fsGroup:    991
	}
	securityContext: {
		allowPrivilegeEscalation: false
		privileged:               false
		runAsNonRoot:             true
		readOnlyRootFilesystem:   false
		capabilities: drop: [
			"ALL",
		]
		runAsUser: 991
	}
}
```

## Additional Resources
- [Official Mastodon Website](https://joinmastodon.org/)
- [Official Mastodon Repository](https://github.com/mastodon/mastodon)
- [Mastodon Documentation](https://docs.joinmastodon.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Mastodon module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Mastodon Web (`mastodon-web`) | Deployment | 11 points | ✅ |
| Mastodon Streaming (`mastodon-streaming`) | Deployment | 11 points | ✅ |
| Mastodon Sidekiq Worker (`mastodon-sidekiq`) | Deployment | 11 points | ✅ |
| PostgreSQL Database (`mastodon-postgresql`) | StatefulSet | 14 points | ✅ |
| Redis In-Memory Cache (`mastodon-redis-master`) | StatefulSet | 14 points | ✅ |
| OpenSearch / Elasticsearch Engine (`mastodon-elasticsearch-master`) | StatefulSet | 14 points | ✅ |
