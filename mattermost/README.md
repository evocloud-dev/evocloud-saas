# Mattermost

## Description
[Mattermost](https://mattermost.com) is an open-source, self-hosted collaboration platform that provides secure messaging, voice/audio channels, project management, and developer workflow automation across the entire software development lifecycle. Designed for enterprise security and data control, Mattermost runs securely on Kubernetes with high availability, full persistence, and native PostgreSQL database integration via CloudNativePG.

## Application Information
- **Version:** `12.0.0`
- **Official Website:** [https://mattermost.com](https://mattermost.com)
- **Upstream Project:** [https://github.com/mattermost/mattermost-server](https://github.com/mattermost/mattermost-server)
- **Container Base:**
  - Mattermost Enterprise Edition: [docker.io/mattermost/mattermost-enterprise-edition](https://hub.docker.com/r/mattermost/mattermost-enterprise-edition) (`docker.io/mattermost/mattermost-enterprise-edition:release-12.0@sha256:6e591e3aa84788b98727a63c6196f4d470f10efdfe053a200dd49cf56e7247aa`)
  - CloudNativePG PostgreSQL: [ghcr.io/cloudnative-pg/postgresql](https://github.com/cloudnative-pg/postgresql-containers) (`ghcr.io/cloudnative-pg/postgresql:18.6@sha256:899d3ed526b659d77935dde0e6bf2d69dbbf17d3d8c6486ca8cfd04bd3c18533`)
  - Database Wait Helper: `oci.trueforge.org/containerforge/postgresql-client:9.6.24@sha256:8ca87491df3145248ee8040ab01ff816a2af13a401c6db950aac371c1b3ebf81`
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Mattermost Server (`mattermost`):** Primary collaboration workload (`Deployment/mattermost`) running Mattermost Enterprise Edition, configured with secure non-root permissions, startup, liveness, and readiness health probes.
- **Database Wait Helper (`mattermost-system-cnpg-wait`):** Dedicated init container testing PostgreSQL database connectivity and readiness via `pg_isready` before starting the Mattermost application.
- **CloudNativePG PostgreSQL Cluster (`mattermost-cnpg-main`):** High-availability 2-instance PostgreSQL database cluster (`Cluster/mattermost-cnpg-main`) provisioned via CloudNativePG with dedicated data and WAL storage.
- **Database Secrets (`mattermost-cnpg-main-user`, `mattermost-cnpg-main-urls`):** Automated basic-auth credential and connection URL Secret resources providing database credentials and standardized connection strings.
- **Mattermost Service (`mattermost`):** Internal ClusterIP service exposing the Mattermost application on port `10239` (forwarding to container targetPort `8065`).
- **Persistent Storage:** Dedicated PersistentVolumeClaims providing resilient storage for configuration (`/mattermost/config`), user data and uploads (`/mattermost/data`), system logs (`/mattermost/logs`), server plugins (`/mattermost/plugins`), client plugins (`/mattermost/client/plugins`), and Bleve search indexes (`/mattermost/bleve-indexes`).
- **Ephemeral & Memory Mounts:** Dedicated `emptyDir` memory tmpfs mounts for `/dev/shm`, `/tmp`, `/var/run`, `/var/logs`, and `/shared`.

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- [CloudNativePG Operator](https://cloudnative-pg.io) installed in the cluster (e.g. `cnpg-system`)
- Default StorageClass supporting `ReadWriteOnce`

## Install

To create an instance using default values:

```shell
timoni -n default apply mattermost ./mattermost
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	workload: main: podSpec: containers: main: env: {
		MM_SERVICESETTINGS_SITEURL: "https://chat.example.com"
	}
	resources: {
		requests: {
			cpu:    "200m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "2"
			memory: "4Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply mattermost ./mattermost \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete mattermost
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/mattermost/mattermost-enterprise-edition` | Container image repository |
| `image.tag` | string | `release-12.0` | Pinned container image tag |
| `image.digest` | string | `sha256:6e591e3aa84788b98727a63c6196f4d470f10efdfe053a200dd49cf56e7247aa` | Container image digest |
| `image.pullPolicy` | string | `IfNotPresent` | Container image pull policy |
| `workload.main.podSpec.containers.main.env` | object | `{TIMEZONE: "UTC", TZ: "UTC", UMASK: "0022", S6_READ_ONLY_ROOT: "1", ...}` | Environment variables passed to Mattermost |
| `service.main.ports.main.port` | int | `10239` | Kubernetes Service port |
| `service.main.ports.main.targetPort` | int | `8065` | Container target port |
| `service.main.ports.main.protocol` | string | `TCP` | Service port protocol |
| `service.main.type` | string | `ClusterIP` | Kubernetes Service type |
| `service.main.publishNotReadyAddresses` | bool | `false` | Publish DNS before pod readiness |
| `resources.requests.cpu` | string | `75m` | Guaranteed CPU request |
| `resources.requests.memory` | string | `200Mi` | Guaranteed memory request |
| `resources.limits.cpu` | string | `1500m` | Maximum CPU limit |
| `resources.limits.memory` | string | `2400Mi` | Maximum memory limit |
| `persistence.config.size` | string | `100Gi` | Storage capacity for config volume |
| `persistence.data.size` | string | `100Gi` | Storage capacity for data volume |
| `persistence.logs.size` | string | `100Gi` | Storage capacity for logs volume |
| `persistence.plugins.size` | string | `100Gi` | Storage capacity for plugins volume |
| `persistence.clientplugins.size` | string | `100Gi` | Storage capacity for client plugins volume |
| `persistence.bleveindexes.size` | string | `100Gi` | Storage capacity for Bleve search indexes |
| `cnpg.main.enabled` | bool | `true` | Enable CloudNativePG PostgreSQL database cluster & secrets |
| `cnpg.main.instances` | int | `2` | Number of PostgreSQL instances for high availability |
| `cnpg.main.user` | string | `mattermost` | PostgreSQL database user |
| `cnpg.main.database` | string | `mattermost` | PostgreSQL database name |
| `cnpg.main.storage.size` | string | `100Gi` | PostgreSQL database PVC storage size |
| `cnpg.main.walStorage.size` | string | `100Gi` | PostgreSQL WAL PVC storage size |
| `replicas` | int | `1` | Number of Mattermost pod replicas |
| `revisionHistoryLimit` | int | `3` | Deployment revision history limit |
| `automountServiceAccountToken` | bool | `false` | Automount ServiceAccount token in pods |
| `enableServiceLinks` | bool | `false` | Inject environment variables for active services |
| `terminationGracePeriodSeconds` | int | `60` | Pod termination grace period in seconds |
| `podSecurityContext` | object | `{fsGroup: 568, fsGroupChangePolicy: "OnRootMismatch", supplementalGroups: [568]}` | Pod-level security context |
| `securityContext` | object | `{runAsNonRoot: true, runAsUser: 568, runAsGroup: 568, readOnlyRootFilesystem: true, allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}}` | Container-level security context |
| `nodeSelector` | object | `{"kubernetes.io/os": "linux"}` | Node selector constraints |
| `affinity` | object | `podAntiAffinity: soft` | Pod scheduling affinity rules |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		fsGroup:             568
		fsGroupChangePolicy: "OnRootMismatch"
		supplementalGroups: [568]
	}
	securityContext: {
		runAsUser:                568
		runAsGroup:               568
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		seccompProfile: {
			type: "RuntimeDefault"
		}
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official Mattermost Website](https://mattermost.com)
- [Official Mattermost Repository](https://github.com/mattermost/mattermost-server)
- [Mattermost Documentation](https://docs.mattermost.com/)
- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Mattermost module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Mattermost Server (`mattermost`) | Deployment | 12 points | ✅ |

