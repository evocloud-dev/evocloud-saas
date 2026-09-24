# Docs (Impress)

## Description
[Docs](https://docs.la-suite.eu/) is an open-source text editor: web-native, made for real-time collaboration, cleanly structured documents and sub-docs with full ownership of your data.

## Application Information
- **Version:** v5.5.0
- **Upstream Project:** [https://github.com/suitenumerique/docs](https://github.com/suitenumerique/docs)
- **Container Base:**
  - Docs Backend & Celery: [docker.io/lasuite/impress-backend](https://hub.docker.com/r/lasuite/impress-backend) (`lasuite/impress-backend:v5.5.0`)
  - Docs Frontend: [docker.io/lasuite/impress-frontend](https://hub.docker.com/r/lasuite/impress-frontend) (`lasuite/impress-frontend:v5.5.0`)
  - Docs Y-Provider: [docker.io/lasuite/impress-y-provider](https://hub.docker.com/r/lasuite/impress-y-provider) (`lasuite/impress-y-provider:v5.5.0`)
  - Docs PostgreSQL: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`postgres:18.6-alpine`)
  - Keycloak PostgreSQL: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`postgres:16.15-alpine`)
  - Redis Cache & Queue: [docker.io/library/redis](https://hub.docker.com/_/redis) (`redis:8.8.2-alpine`)
  - Keycloak SSO: [quay.io/keycloak/keycloak](https://quay.io/repository/keycloak/keycloak) (`keycloak:26.7.3`)
  - MinIO Object Storage: [docker.io/minio/minio](https://hub.docker.com/r/minio/minio) (`minio/minio:RELEASE.2025-09-07T16-13-09Z-cpuv1`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Docs Frontend (`docs-frontend`):** Web user interface running `lasuite/impress-frontend:v5.5.0` on container port 8080 (exposed on port 80) providing rich-text document editing, dashboard navigation, and workspace management.
- **Docs Backend (`docs-backend`):** Core Django API server running `lasuite/impress-backend:v5.5.0` on container port 8000 (exposed on port 80) managing document metadata, OIDC authentication, permissions, and REST endpoints.
- **Celery Background Worker (`docs-celery-worker`):** Asynchronous task worker running `lasuite/impress-backend:v5.5.0` processing PDF exports, file operations, and scheduled maintenance tasks.
- **Yjs Collaboration Server (`docs-y-provider`):** Real-time WebSocket and CRDT synchronization engine running `lasuite/impress-y-provider:v5.5.0` on port 4444 enabling concurrent multi-user live editing.
- **Docs PostgreSQL Database (`postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`postgres:18.6-alpine`) storing Docs application models, document hierarchies, and workspace permissions.
- **Keycloak PostgreSQL Database (`kc-postgresql`):** Dedicated PostgreSQL 16 StatefulSet (`postgres:16.15-alpine`) storing Keycloak realms, user accounts, and credentials.
- **Redis Cache & Broker (`redis`):** Redis 8 deployment (`redis:8.8.2-alpine`) serving as Celery task message broker and application caching tier.
- **Keycloak Identity Provider (`keycloak`):** Dedicated Keycloak 26 StatefulSet (`quay.io/keycloak/keycloak:26.7.3`) providing centralized OpenID Connect (OIDC) single sign-on authentication.
- **MinIO Object Storage (`docs-minio`):** S3-compatible object storage deployment (`minio/minio`) persisting user uploads, embedded media, and document attachments.
- **Kubernetes Ingress Controllers:** Ingress rules routing web UI traffic, live WebSocket collaboration (`/collaboration/ws/`), collaboration APIs (`/collaboration/api/`), admin panel (`/admin`), and authenticated media streaming (`/media/`).

## Prerequisites

### Cluster Requirements

| Requirement | Notes |
|---|---|
| Kubernetes ≥ 1.20 | Recommended v1.26+ |
| `ingress-nginx` installed | Module uses `ingressClassName: nginx` by default |
| `mkcert` (local dev only) | For self-signed TLS on `*.127.0.0.1.nip.io` |
| [Timoni CLI](https://timoni.sh) | v0.17+ installed locally |

### Required Namespace Resources
Before running `timoni apply`, the following resources **must exist** in the target namespace to facilitate secure OIDC communication with Keycloak:

| Kind | Name | Purpose |
|---|---|---|
| `ConfigMap` | `certifi` | Bundled CA certificates (Python `certifi` + your local CA). Mounted into the backend pod so Django can verify HTTPS calls to Keycloak. |
| `Secret` | `mkcert` | Root CA certificate used by the ingress controller for TLS termination. |

### Environment Setup

#### Option A — Full local setup (recommended for new environments)

If you are starting from scratch, use the official bootstrap script from the Docs project. It creates a Kind cluster, configures CoreDNS, installs `ingress-nginx`, and provisions all required secrets and configmaps automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/numerique-gouv/tools/main/kind/create_cluster.sh | sh -s -- docs
```

> The script accepts two arguments: `APPLICATION` (namespace name, default `app`) and `CLUSTERNAME` (kind cluster name, default `suite`). Pass `docs` as the application name to match this module's defaults.
> Once the script completes, skip directly to [Install](#install).

#### Option B — Existing cluster

If you already have a Kubernetes cluster and ingress controller, you only need to provision the certificate resources. These are the relevant steps extracted from the bootstrap script:

##### 1. Install mkcert and generate a wildcard certificate
```bash
mkcert -install
cd /tmp
mkcert "127.0.0.1.nip.io" "*.127.0.0.1.nip.io"
```

##### 2. Install ingress-nginx controller (if not already installed)
```bash
# Add Helm repo and install ingress-nginx (disabling admission webhooks for fast local setup)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.admissionWebhooks.enabled=false
```

##### 3. Configure ingress-nginx to use the mkcert certificate as default TLS
```bash
# Create or update the TLS secret in the ingress-nginx namespace
kubectl -n ingress-nginx create secret tls mkcert \
  --key /tmp/127.0.0.1.nip.io+1-key.pem \
  --cert /tmp/127.0.0.1.nip.io+1.pem \
  --dry-run=client -o yaml | kubectl apply -f -

# Patch the controller deployment to use the cert as default SSL
kubectl -n ingress-nginx patch deployments.apps ingress-nginx-controller \
  --type json -p '[
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--default-ssl-certificate=ingress-nginx/mkcert"}
  ]'
```

##### 4. Create the target namespace
```bash
kubectl create ns docs
kubectl config set-context --current --namespace=docs
```

##### 5. Create the mkcert secret in the namespace
```bash
kubectl -n docs create secret generic mkcert \
  --from-file=rootCA.pem="$(mkcert -CAROOT)/rootCA.pem"
```

##### 6. Create the certifi ConfigMap and Secret
The `certifi` ConfigMap bundles the standard Python CA bundle with your local `mkcert` root CA. This allows the Django backend to verify TLS connections to Keycloak (which uses a self-signed cert).

```bash
# Download the standard certifi CA bundle
curl https://raw.githubusercontent.com/certifi/python-certifi/refs/heads/master/certifi/cacert.pem \
  -o /tmp/cacert.pem

# Append your local mkcert root CA to it
cat "$(mkcert -CAROOT)/rootCA.pem" >> /tmp/cacert.pem

# Create the ConfigMap (mounted into the backend pod at /cert/cacert.pem)
kubectl -n docs create configmap certifi \
  --from-file=cacert.pem=/tmp/cacert.pem

# Create the Secret (used by other tools that expect a secret)
kubectl -n docs create secret generic certifi \
  --from-file=/tmp/cacert.pem
```

## Install

To create an instance using default values:

```shell
timoni -n docs apply docs ./docs
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	image: {
		tag: "v5.5.0"
	}
	djangoSecretKey: "your-very-secure-random-secret-key"
	backend: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "1000m"
				memory: "1024Mi"
			}
		}
	}
	frontend: {
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
}
```

Apply the values to the instance:

```shell
timoni -n docs apply docs ./docs \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n docs delete docs
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `lasuite/impress-backend` | Container image repository for Docs backend |
| `image.tag` | string | `v5.5.0` | Pinned container image tag for Docs backend |
| `frontend.image.repository` | string | `lasuite/impress-frontend` | Container image repository for Docs frontend |
| `frontend.image.tag` | string | `v5.5.0` | Pinned container image tag for Docs frontend |
| `yProvider.image.repository` | string | `lasuite/impress-y-provider` | Container image repository for Yjs collaboration provider |
| `yProvider.image.tag` | string | `v5.5.0` | Pinned container image tag for Yjs provider |
| `djangoSecretKey` | string | `""` | Secret key used by Django for sessions and signing |
| `djangoSuperUserEmail` | string | `admin@example.com` | Administrator email address for initial bootstrap |
| `djangoSuperUserPass` | string | `admin` | Administrator password for initial bootstrap |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database for Docs |
| `postgresql.image.tag` | string | `18.6-alpine` | Pinned PostgreSQL image tag for Docs |
| `kc_postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database for Keycloak |
| `kc_postgresql.image.tag` | string | `16.15-alpine` | Pinned PostgreSQL image tag for Keycloak |
| `redis.enabled` | bool | `true` | Deploy internal Redis queue and cache |
| `redis.image.tag` | string | `8.8.2-alpine` | Pinned Redis image tag |
| `keycloak.enabled` | bool | `true` | Deploy internal Keycloak OIDC provider |
| `keycloak.image.tag` | string | `26.7.3` | Pinned Keycloak image tag |
| `minio.enabled` | bool | `true` | Deploy internal MinIO S3 object storage |

### Recommended values

Comply with the restricted Kubernetes pod security standard:

```cue
values: {
	backend: {
		podSecurityContext: {
			runAsNonRoot: true
			runAsUser:    65510
			runAsGroup:   65510
			fsGroup:      65510
			seccompProfile: type: "RuntimeDefault"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   true
			runAsNonRoot:             true
			runAsUser:                65510
			runAsGroup:               65510
			capabilities: drop: ["ALL"]
			seccompProfile: type: "RuntimeDefault"
		}
	}
}
```

## Additional Resources
- [Official Docs Website](https://docs.la-suite.eu/)
- [Official Docs Repository](https://github.com/suitenumerique/docs)
- [La Suite Numérique Website](https://lasuite.numerique.gouv.fr/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Docs module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Docs Frontend (`docs-frontend`) | Deployment | 14 points | ✅  |
| Docs Backend (`docs-backend`) | Deployment | 11 points | ✅  |
| Celery Background Worker (`docs-celery-worker`) | Deployment | 14 points | ✅  |
| Yjs Collaboration Server (`docs-y-provider`) | Deployment | 14 points | ✅  |
| Docs PostgreSQL (`postgresql`) | StatefulSet | 15 points | ✅  |
| Keycloak PostgreSQL (`kc-postgresql`) | StatefulSet | 15 points | ✅  |
| Redis Queue & Broker (`redis`) | Deployment | 14 points | ✅  |
| Keycloak Identity Provider (`keycloak`) | StatefulSet | 15 points | ✅  |
| MinIO Object Storage (`docs-minio`) | Deployment | 14 points | ✅  |