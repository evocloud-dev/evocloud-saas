# Reactive Resume

## Description
[Reactive Resume](https://rxresu.me/) is a free, open-source resume builder designed to simplify the creation, customization, and management of resumes. It features real-time editing, multiple customizable templates, multi-page support, custom typography and colors, structured section management, private PDF export, and multi-language support.

## Application Information
- **Version:** `v5.3.0`
- **Official Website:** [https://rxresu.me/](https://rxresu.me/)
- **Upstream Project:** [https://github.com/AmruthPillai/Reactive-Resume](https://github.com/AmruthPillai/Reactive-Resume)
- **Container Base:**
  - Reactive Resume Core Application: [ghcr.io/amruthpillai/reactive-resume](https://github.com/AmruthPillai/Reactive-Resume/pkgs/container/reactive-resume) (`ghcr.io/amruthpillai/reactive-resume:v5.3.0@sha256:c487ec5edcfe054bcb312fcd498f868e56f274756d0046b01c83f210855017ab`)
  - Reverse Proxy: [docker.io/nginxinc/nginx-unprivileged](https://hub.docker.com/r/nginxinc/nginx-unprivileged) (`docker.io/nginxinc/nginx-unprivileged:1.30.4-alpine`)
  - Admission Helper: [docker.io/library/node](https://hub.docker.com/_/node) (`docker.io/library/node:24.21.0-alpine`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:16-alpine`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Reactive Resume Server (`reactive-resume`):** Primary application workload (`Deployment/reactive-resume`) running `ghcr.io/amruthpillai/reactive-resume:v5.3.0` behind an unprivileged NGINX reverse proxy (`docker.io/nginxinc/nginx-unprivileged:1.30.4-alpine`) on port 3000. Includes an automated `bootstrap` init container for secure first-user admin enrollment and database schema migrations.
- **Admission Helper (`reactive-resume-admission`):** Dedicated security verification service (`Deployment/reactive-resume-admission`) running Node.js 24 on port 8088. Probes the application pod for network isolation before initial administrative credentials are accepted.
- **PostgreSQL Database (`reactive-resume-postgresql`):** Bundled relational database (`StatefulSet/reactive-resume-postgresql`) powered by PostgreSQL 16 Alpine with persistent volume storage (`8Gi`), automated schema creation, and database user initialization.
- **Reactive Resume Services (`reactive-resume`, `reactive-resume-admission`, `reactive-resume-postgresql`, `reactive-resume-postgresql-primary-headless`):** Internal ClusterIP and Headless services exposing the web application (port 3000), admission verification endpoint (port 8088), and database service (port 5432).
- **Persistent Storage:** PersistentVolumeClaims providing dedicated storage for resume uploads and identity markers (`10Gi`), and PostgreSQL database files (`8Gi`).
- **Network Policies:** Granular ingress and egress isolation policies restricting pod-to-pod communications, admission verification, and database access.
- **Gateway API HTTPRoute (`gatewayAPI`):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) routing external traffic to the Reactive Resume proxy.
- **Secrets:** Automated secret generation for admission challenge tokens (`reactive-resume-admission`), initial owner credentials (`reactive-resume-bootstrap`), retained identity encryption keys (`reactive-resume-identity`), and PostgreSQL database passwords (`reactive-resume-postgresql-auth`).

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode
- NetworkPolicy-enforcing CNI (e.g. Cilium, Calico, Canal) for enrollment admission verification

## Install

To create an instance using default values:

```shell
timoni -n default apply rr ./reactive-resume
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	server: {
		publicUrl: "https://resume.example.com"
	}
	gatewayAPI: {
		enabled: true
		httpRoutes: [{
			hostnames: ["resume.example.com"]
			parentRefs: [{
				name: "my-gateway"
			}]
		}]
	}
	storage: {
		driver: "s3"
		s3: {
			bucket:         "my-resumes-bucket"
			region:         "us-east-1"
			existingSecret: "s3-credentials"
		}
	}
	resources: {
		requests: {
			cpu:    "500m"
			memory: "1Gi"
		}
		limits: {
			cpu:    "2000m"
			memory: "2Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply rr ./reactive-resume \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete rr
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `ghcr.io/amruthpillai/reactive-resume` | Container image repository for Reactive Resume |
| `image.tag` | string | `v5.3.0` | Pinned container image tag for Reactive Resume |
| `image.digest` | string | `sha256:c487ec5edcfe...` | Container image digest |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `proxy.image.repository` | string | `docker.io/nginxinc/nginx-unprivileged` | Container image repository for the unprivileged proxy |
| `proxy.image.tag` | string | `1.30.4-alpine` | Proxy container image tag |
| `proxy.bodySize` | string | `20m` | Maximum public client request body size |
| `proxy.resources` | object | `{requests: {cpu: "50m", memory: "32Mi"}, limits: {cpu: "500m", memory: "128Mi"}}` | Container resource requests and limits for the proxy |
| `admission.image.repository` | string | `docker.io/library/node` | Container image repository for the admission probe |
| `admission.image.tag` | string | `24.21.0-alpine` | Admission probe container image tag |
| `admission.key` | string | `""` | 64-character hex HMAC admission secret key (auto-generated by default) |
| `admission.existingSecret` | string | `""` | Existing secret containing HMAC admission key |
| `replicaCount` | int | `1` | Number of application replicas (fixed to 1 for serial migrations) |
| `server.port` | int | `3000` | HTTP proxy container listening port |
| `server.publicUrl` | string | `""` | External canonical HTTP(S) URL |
| `resources` | object | `{requests: {cpu: "250m", memory: "512Mi"}, limits: {cpu: "2", memory: "2Gi"}}` | Container resource requests and limits for the application |
| `bootstrap.name` | string | `Initial Owner` | Display name of the initial administrator account |
| `bootstrap.email` | string | `owner@example.test` | Initial administrator email address |
| `bootstrap.username` | string | `owner` | Initial administrator username |
| `bootstrap.password` | string | `""` | Initial admin password (min 16 chars; empty uses default secret) |
| `bootstrap.existingSecret` | string | `""` | Existing secret containing initial admin password |
| `storage.driver` | string | `local` | Upload and asset storage backend (`local` or `s3`) |
| `storage.s3.bucket` | string | `""` | Dedicated S3 bucket name |
| `storage.s3.region` | string | `us-east-1` | S3 bucket region |
| `storage.s3.existingSecret` | string | `""` | Secret with `access-key-id` and `secret-access-key` |
| `postgresql.enabled` | bool | `true` | Deploy bundled standalone PostgreSQL database |
| `postgresql.auth.database` | string | `reactive_resume` | Relational database name |
| `postgresql.auth.username` | string | `reactive_resume` | Relational database username |
| `database.host` | string | `""` | External PostgreSQL hostname (when bundled is disabled) |
| `database.port` | int | `5432` | External PostgreSQL TCP port |
| `database.passwordSecret` | string | `""` | Secret containing external PostgreSQL password |
| `persistence.enabled` | bool | `true` | Enable persistent storage for uploads and identity marker |
| `persistence.size` | string | `10Gi` | Storage capacity allocated for application data |
| `networkPolicy.enabled` | bool | `true` | Enforce CNI-backed network isolation policies |
| `networkPolicy.allowPublicHttps` | bool | `true` | Allow egress to public HTTPS for PDF fallback fonts |
| `oauth.enabled` | bool | `false` | Enable native OAuth2 single sign-on |
| `smtp.enabled` | bool | `false` | Enable authenticated SMTP email delivery |
| `gatewayAPI.enabled` | bool | `false` | Enable Gateway API HTTPRoute for external traffic |
| `externalSecrets.enabled` | bool | `false` | Materialize credentials via External Secrets Operator |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:           1000
		runAsGroup:          1000
		runAsNonRoot:        true
		fsGroup:             1000
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		runAsUser:                1000
		runAsGroup:               1000
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official Reactive Resume Website](https://rxresu.me/)
- [Official Reactive Resume Repository](https://github.com/AmruthPillai/Reactive-Resume)
- [Reactive Resume Documentation](https://docs.rxresu.me/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Reactive Resume module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Reactive Resume Server (`reactive-resume`) | Deployment | 12 points | ✅ |
| Admission Helper (`reactive-resume-admission`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`reactive-resume-postgresql`) | StatefulSet | 14 points | ✅ |

