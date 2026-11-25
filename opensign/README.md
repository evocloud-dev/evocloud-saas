# OpenSign

## Description
[OpenSign](https://www.opensignlabs.com/) is a free and open-source electronic signature solution designed as an alternative to proprietary e-sign tools such as DocuSign and Adobe Sign. It allows organizations to sign, send, track, and manage legally binding digital contracts, PDF documents, and certificates with full control over data privacy and document integrity.

## Application Information
- **Version:** `3.1.0`
- **Official Website:** [https://www.opensignlabs.com/](https://www.opensignlabs.com/)
- **Upstream Project:** [https://github.com/OpenSignLabs/OpenSign](https://github.com/OpenSignLabs/OpenSign)
- **Container Base:**
  - OpenSign Server (Backend API): `docker.io/opensign/opensignserver:main` (`docker.io/opensign/opensignserver:main@sha256:49819bc883aa5b0053106f2d60d49334231c723cc37c01a304a9322e46bfc06f`)
  - OpenSign Client (Frontend Web): `docker.io/opensign/opensign:main` (`docker.io/opensign/opensign:main@sha256:093910c698c135e272a794ec1df81324c584b0c1011bb95da0c04ff22adb45ac`)
  - MongoDB Database: `docker.io/library/mongo:9.0.8` (`docker.io/library/mongo:9.0.8@sha256:b035239e35453a1103de0e37ea4ddd8cce024abf295cfac5e51ed34cb98f7ef7`)
  - S3 Uploader (Backup): `docker.io/helmforge/mc:1.0.0`
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **OpenSign Server (`deployServer`):** Deployment (`Deployment/<name>-server`) running the Parse-based backend API on port 8080 with health probes, migration safety, and persistent document storage (`5Gi`).
- **OpenSign Client (`deployClient`):** Deployment (`Deployment/<name>-client`) running the React frontend UI on port 3000 with startup, liveness, and readiness probes.
- **Client Autoscaling & Disruption Budget (`hpaClient`, `pdbClient`):** Optional `HorizontalPodAutoscaler` and `PodDisruptionBudget` for high availability and automatic scaling of the stateless frontend under traffic spikes.
- **MongoDB Database (`deployMongo`, `svcMongo`, `pvcMongo`):** Dedicated MongoDB deployment (`Deployment/<name>-mongo`) with persistent volume storage (`10Gi`), health probes, and optional external database integration.
- **HTTPRoute Gateway Routing (`httpRoute`):** Optional Kubernetes Gateway API `HTTPRoute` for routing external traffic directly to the frontend (port 3000) and Parse backend API (port 8080).
- **Database Backup Automation (`backupCronJob`, `backupConfigMap`):** Optional scheduled CronJob performing `mongodump` archiving and uploading to S3-compatible object storage via MinIO Client (`mc`).
- **Secrets Management (`envSecret`):** Pre-configured out-of-the-box application secret with support for user-supplied `existingSecret` for production and GitOps security.
- **External Secrets Operator (`externalSecret`):** Optional Kubernetes `ExternalSecret` custom resource integration to securely synchronize sensitive environment variables from external secret backends (HashiCorp Vault, AWS Secrets Manager, etc.) via ESO.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

### Document Signing Certificate
OpenSign digitally signs PDF documents upon completion using a PKCS#12 (`.pfx` or `.p12`) cryptographic certificate bundle. For document signing to succeed, `PFX_BASE64` and `PASS_PHRASE` must be provided in `envSecret`, via an `existingSecret`, or through External Secrets Operator.

To generate a self-signed dev certificate:
```bash
# 1. Generate private key and certificate (365 days)
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout /tmp/opensign.key -out /tmp/opensign.crt \
  -subj "/CN=OpenSign/O=Dev/C=US"

# 2. Export to PKCS#12 bundle (.pfx) with passphrase 'opensign'
openssl pkcs12 -export -out /tmp/opensign.pfx \
  -inkey /tmp/opensign.key -in /tmp/opensign.crt -passout pass:opensign

# 3. Base64 encode the pfx into a single line
base64 -w 0 /tmp/opensign.pfx > /tmp/pfx_base64.txt
```
Copy the Base64 output into `values.cue` under `envSecret.PFX_BASE64` with `envSecret.PASS_PHRASE: "opensign"`, or map it via `existingSecret` in production.

## Install

To create an instance using default values:

```shell
timoni -n default apply opensign ./opensign
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	config: {
		publicUrl: "https://opensign.example.com"
		apiUrl:    "https://opensign.example.com/app"
	}
	gateway: {
		enabled: true
		hostnames: ["opensign.example.com"]
	}
	client: {
		autoscaling: {
			enabled:     true
			minReplicas: 2
			maxReplicas: 5
		}
	}
	backup: {
		enabled:  true
		schedule: "0 3 * * *"
		s3: {
			endpoint: "https://s3.example.com"
			bucket:   "opensign-backups"
			existingSecret: "s3-credentials"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply opensign ./opensign \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all its created Kubernetes resources:

```shell
timoni -n default delete opensign
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the release name used in resource naming |
| `fullnameOverride` | string | `""` | Override the full release name used in resource naming |
| `existingSecret` | string | `""` | Existing Kubernetes secret to use instead of creating in-tree envSecret |
| `config.publicUrl` | string | `http://localhost:3000` | Browser-visible frontend URL |
| `config.apiUrl` | string | `http://localhost:8080/app` | Parse backend API endpoint (must end with `/app`) |
| `server.enabled` | bool | `true` | Deploy OpenSign backend server |
| `server.image.repository` | string | `docker.io/opensign/opensignserver` | Server container image repository |
| `server.image.tag` | string | `main` | Upstream container image tag |
| `server.image.digest` | string | `sha256:49819bc883aa5b0053106f2d60d49334231c723cc37c01a304a9322e46bfc06f` | Immutable image manifest digest |
| `server.replicas` | int | `1` | Number of backend server replicas (singleton recommended for migrations) |
| `server.port` | int | `8080` | Internal server container HTTP port |
| `server.resources` | object | `{requests: {cpu: "200m", memory: "256Mi"}, limits: {cpu: "1000m", memory: "1Gi"}}` | Server container CPU/memory limits |
| `server.persistence.enabled` | bool | `true` | Enable persistent storage for uploaded documents |
| `server.persistence.size` | string | `5Gi` | Storage capacity for documents volume |
| `client.enabled` | bool | `true` | Deploy OpenSign frontend client |
| `client.image.repository` | string | `docker.io/opensign/opensign` | Client container image repository |
| `client.image.tag` | string | `main` | Upstream container image tag |
| `client.image.digest` | string | `sha256:093910c698c135e272a794ec1df81324c584b0c1011bb95da0c04ff22adb45ac` | Immutable image manifest digest |
| `client.replicas` | int | `1` | Number of frontend client replicas |
| `client.port` | int | `3000` | Internal client container HTTP port |
| `client.autoscaling.enabled` | bool | `false` | Enable Horizontal Pod Autoscaler for frontend |
| `client.autoscaling.minReplicas` | int | `1` | Minimum number of frontend replicas |
| `client.autoscaling.maxReplicas` | int | `5` | Maximum number of frontend replicas |
| `client.podDisruptionBudget.enabled` | bool | `false` | Enable PodDisruptionBudget for frontend |
| `mongodb.enabled` | bool | `true` | Deploy internal MongoDB instance |
| `mongodb.image.repository` | string | `docker.io/library/mongo` | MongoDB container image repository |
| `mongodb.image.tag` | string | `9.0.8` | MongoDB container image tag |
| `mongodb.persistence.size` | string | `10Gi` | MongoDB persistent storage size |
| `externalMongodb.enabled` | bool | `false` | Connect to an external MongoDB database |
| `externalMongodb.uri` | string | `""` | Connection URI for external MongoDB |
| `externalMongodb.existingSecret` | string | `""` | Secret containing external MongoDB URI |
| `externalMongodb.existingSecretKey` | string | `"uri"` | Key within existingSecret containing MongoDB URI |
| `externalMongodb.existingSecretUriKey` | string | `""` | Alternate key name for existingSecret URI (HelmForge compatibility) |
| `gateway.enabled` | bool | `false` | Enable Kubernetes Gateway API HTTPRoute |
| `gateway.hostnames` | list | `["opensign.example.com"]` | Hostnames handled by the HTTPRoute |
| `backup.enabled` | bool | `false` | Enable scheduled automated database backups to S3 |
| `backup.schedule` | string | `0 2 * * *` | Cron schedule for database backups |
| `externalSecrets.enabled` | bool | `false` | Enable External Secrets Operator integration |
| `externalSecrets.apiVersion` | string | `external-secrets.io/v1` | ExternalSecret API version |
| `externalSecrets.secretStoreRef.name` | string | `""` | Name of the SecretStore / ClusterSecretStore |
| `externalSecrets.secretStoreRef.kind` | string | `SecretStore` | Kind of secret store (`SecretStore` or `ClusterSecretStore`) |
| `externalSecrets.refreshInterval` | string | `1h` | Interval at which secret data is refreshed from external vault |
| `externalSecrets.target.creationPolicy` | string | `Owner` | Secret creation policy (`Owner` or `Merge`) |
| `envSecret.PFX_BASE64` | string | `""` | Base64-encoded PKCS#12 (.pfx/.p12) digital certificate for signing PDFs |
| `envSecret.PASS_PHRASE` | string | `""` | Passphrase to decrypt the PFX digital certificate |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsUser:    1000
		runAsGroup:   1000
		runAsNonRoot: true
		fsGroup:      1000
		seccompProfile: type: "RuntimeDefault"
	}
	server: {
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
	}
	client: {
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
	}
	mongodb: {
		podSecurityContext: {
			runAsNonRoot: true
			runAsUser:    999
			runAsGroup:   999
			fsGroup:      999
			seccompProfile: type: "RuntimeDefault"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official OpenSign Website](https://www.opensignlabs.com/)
- [Official OpenSign Repository](https://github.com/OpenSignLabs/OpenSign)
- [OpenSign Documentation](https://docs.opensignlabs.com/)
- [Timoni Documentation](https://timoni.sh)

## Changelog

### 0.1.1 - 2026-11-09
- **Changed:** Upgraded OpenSign to release `3.1.0` using official upstream `main` tag locked to immutable SHA256 digests.
- **Removed:** Removed embedded Caddy reverse proxy in favor of native Kubernetes Services and Gateway API HTTPRoute.
- **Added:** Support for Gateway API `HTTPRoute` for direct ingress routing to frontend (port 3000) and Parse backend API (port 8080).
- **Added:** Support for external MongoDB connections (`externalMongodb`).
- **Added:** Scheduled automated database backup CronJob exporting to S3 via MinIO Client (`mc`).
- **Added:** Proper secrets management with `existingSecret` integration for GitOps and external secret managers.
- **Added:** Startup, liveness, and readiness probes across server, client, and mongodb workloads.
- **Added:** Horizontal Pod Autoscaler (HPA) and PodDisruptionBudget (PDB) support for stateless frontend client.
- **Added:** External Secrets Operator (`#ExternalSecret`) integration via `externalSecrets` with flexible target mapping.
- **Fixed:** Scoped all Services, PVCs, ConfigMaps, and volume mounts with instance name prefix (`\(#config.metadata.name)`) to fix multi-tenancy collisions.
- **Changed:** Standardized documentation with complete configuration options and security profiles.

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the OpenSign module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| OpenSign Server (`server`) | Deployment | 10 points | ✅ |
| OpenSign Client (`client`) | Deployment | 10 points | ✅ |
| MongoDB Database (`mongo`) | Deployment | 11 points | ✅ |
| Automated Backup (`backup`) | CronJob | 15 points | ✅ |
