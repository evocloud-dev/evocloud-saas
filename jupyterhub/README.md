# JupyterHub

## Description
[JupyterHub](https://jupyter.org/hub) is a multi-user server for Jupyter notebooks that manages and scales interactive computing environments for teams, classrooms, and research platforms. It enables users to authenticate and dynamically spawn dedicated, isolated single-user JupyterLab/notebook server environments on Kubernetes via KubeSpawner.

## Application Information
- **Version:** `5.4.6`
- **Official Website:** [https://jupyter.org/hub](https://jupyter.org/hub)
- **Upstream Project:** [https://github.com/jupyterhub/jupyterhub](https://github.com/jupyterhub/jupyterhub)
- **Container Base:**
  - JupyterHub Hub Application: [quay.io/jupyterhub/k8s-hub](https://quay.io/repository/jupyterhub/k8s-hub) (`quay.io/jupyterhub/k8s-hub:4.4.2`)
  - Configurable HTTP Proxy: [docker.io/jupyterhub/configurable-http-proxy](https://hub.docker.com/r/jupyterhub/configurable-http-proxy) (`docker.io/jupyterhub/configurable-http-proxy:5.3.0`)
  - Single-User Notebook: [quay.io/jupyter/base-notebook](https://quay.io/repository/jupyter/base-notebook) (`quay.io/jupyter/base-notebook:2026-10-05`)
  - Wait Init Helper: [docker.io/curlimages/curl](https://hub.docker.com/r/curlimages/curl) (`docker.io/curlimages/curl:8.21.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **JupyterHub Hub (`jupyterhub-hub`):** Primary control plane workload (`Deployment/jupyterhub-hub`) running `quay.io/jupyterhub/k8s-hub:4.4.2` managing user authentication, single-user notebook lifecycles via `KubeSpawner`, and proxy routing tables. Includes a `wait-for-proxy-api` init container for proxy readiness verification.
- **Configurable HTTP Proxy (`jupyterhub-proxy`):** Dynamic reverse proxy workload (`Deployment/jupyterhub-proxy`) running `docker.io/jupyterhub/configurable-http-proxy:5.3.0` routing incoming web traffic to the Hub or active single-user notebook servers.
- **Single-User Notebooks (`jupyter-<username>`):** Dynamically spawned user pods running `quay.io/jupyter/base-notebook:2026-10-05` provisioned on-demand via `KubeSpawner` with optional per-user persistent storage and resource constraints.
- **JupyterHub Services (`jupyterhub`, `jupyterhub-hub`, `jupyterhub-proxy-api`):** Internal and public ClusterIP services exposing the configurable HTTP proxy (port 80), internal proxy REST API (port 8001), and Hub control plane (port 8081).
- **Persistent Storage:** PersistentVolumeClaims providing dedicated storage for Hub SQLite state (`/srv/jupyterhub`, default `10Gi`), and optional per-user home directories (`/home/jovyan`).
- **Gateway API HTTPRoute (`gateway`):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) routing external traffic to the JupyterHub proxy service.
- **ServiceMonitor (`metrics.serviceMonitor`):** Optional Prometheus Operator ServiceMonitor (`monitoring.coreos.com/v1`) scraping Hub metrics.
- **External Secrets (`externalSecrets`):** Optional ExternalSecret resource (`external-secrets.io/v1`) for fetching proxy authentication tokens and cookie secrets from external secret stores.
- **Secrets & ConfigMaps:** Automated credential and configuration generation for proxy authentication (`jupyterhub-proxy`) and Hub Python runtime settings (`jupyterhub-hub-config`).

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` (or `ReadWriteMany` / external DB for multi-replica Hub deployments)

## Install

To create an instance using default values:

```shell
timoni -n default apply jupyterhub ./jupyterhub
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	hub: {
		replicaCount: 1
		resources: {
			requests: {
				cpu:    "200m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1"
				memory: "1Gi"
			}
		}
	}
	proxy: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
	}
	auth: {
		type:          "dummy"
		dummyPassword: "ChangeMeImmediately123!"
	}
	singleuser: {
		image: {
			name: "quay.io/jupyter/base-notebook"
			tag:  "2026-10-05"
		}
		storage: {
			enabled:  true
			capacity: "10Gi"
		}
	}
	gateway: {
		enabled: true
		parentRefs: [{
			name: "my-gateway"
		}]
		hostnames: ["jupyter.example.com"]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply jupyterhub ./jupyterhub \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete jupyterhub
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the release name |
| `fullnameOverride` | string | `""` | Override the fully qualified release name |
| `commonLabels` | object | `{}` | Additional labels applied to all chart resources |
| `hub.replicaCount` | int | `1` | Number of Hub replicas (keep at 1 when using SQLite) |
| `hub.image.repository` | string | `quay.io/jupyterhub/k8s-hub` | Hub container image repository |
| `hub.image.tag` | string | `4.4.2` | Pinned Hub container image tag |
| `hub.image.digest` | string | `""` | Hub container image digest |
| `hub.image.pullPolicy` | string | `IfNotPresent` | Hub image pull policy |
| `hub.baseUrl` | string | `/` | Base URL prefix for JupyterHub |
| `hub.dbPath` | string | `/srv/jupyterhub/jupyterhub.sqlite` | SQLite database file path |
| `hub.cookieSecret.existingSecret` | string | `""` | Existing Secret containing shared cookie secret |
| `hub.cookieSecret.existingSecretKey` | string | `cookie-secret` | Key within existing cookie secret |
| `hub.cookieSecret.fileName` | string | `jupyterhub_cookie_secret` | Secret file name mounted in `/srv/jupyterhub` |
| `hub.logLevel` | string | `INFO` | Hub logging verbosity (`DEBUG`, `INFO`, `WARN`, `ERROR`) |
| `hub.cleanupServers` | bool | `false` | Stop single-user servers when Hub stops |
| `hub.extraConfig` | string | `""` | Custom Python configuration appended to `jupyterhub_config.py` |
| `hub.persistence.enabled` | bool | `true` | Enable persistent storage for Hub state and SQLite database |
| `hub.persistence.existingClaim` | string | `""` | Name of existing PVC to bind |
| `hub.persistence.storageClass` | string | `""` | StorageClass for Hub PVC |
| `hub.persistence.accessModes` | list | `["ReadWriteOnce"]` | PVC access modes |
| `hub.persistence.size` | string | `10Gi` | Storage capacity allocated for Hub data |
| `hub.resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1", memory: "1Gi"}}` | Container resource requests and limits for Hub |
| `proxy.image.repository` | string | `docker.io/jupyterhub/configurable-http-proxy` | Proxy container image repository |
| `proxy.image.tag` | string | `5.3.0` | Pinned proxy container image tag |
| `proxy.image.digest` | string | `""` | Proxy container image digest |
| `proxy.image.pullPolicy` | string | `IfNotPresent` | Proxy image pull policy |
| `proxy.secretToken` | string | `""` | Proxy authentication token (auto-generated if empty) |
| `proxy.existingSecret` | string | `""` | Existing Secret containing proxy token |
| `proxy.existingSecretTokenKey` | string | `proxy-token` | Secret key containing proxy authentication token |
| `proxy.logLevel` | string | `warn` | Proxy logging verbosity (`debug`, `info`, `warn`, `error`) |
| `proxy.bind.ip` | string | `""` | Public-facing proxy bind IP (`0.0.0.0` or `::`) |
| `proxy.bind.apiIp` | string | `""` | Proxy REST API bind IP |
| `proxy.resources` | object | `{requests: {cpu: "50m", memory: "128Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Container resource requests and limits for Proxy |
| `auth.type` | string | `dummy` | Authenticator type (`dummy` or `custom`) |
| `auth.dummyPassword` | string | `Changeme123` | Default bootstrap password for DummyAuthenticator |
| `auth.allowInsecureDummy` | bool | `false` | Explicitly allow exposing Hub with unauthenticated dummy login |
| `singleuser.image.name` | string | `quay.io/jupyter/base-notebook` | Default single-user notebook image repository |
| `singleuser.image.tag` | string | `2026-10-05` | Pinned single-user notebook image tag |
| `singleuser.image.pullPolicy` | string | `IfNotPresent` | Notebook image pull policy |
| `singleuser.cpu.guarantee` | number | `0.1` | Guaranteed CPU request for single-user pods |
| `singleuser.cpu.limit` | number | `1` | CPU limit for single-user pods |
| `singleuser.memory.guarantee` | string | `512M` | Guaranteed memory request for single-user pods |
| `singleuser.memory.limit` | string | `2G` | Memory limit for single-user pods |
| `singleuser.storage.enabled` | bool | `false` | Enable dedicated per-user persistent home storage |
| `singleuser.storage.capacity` | string | `10Gi` | Storage capacity allocated for per-user PVCs |
| `singleuser.storage.storageClass` | string | `""` | StorageClass for per-user PVCs |
| `singleuser.storage.accessModes` | list | `["ReadWriteOnce"]` | PVC access modes for per-user volumes |
| `singleuser.startTimeout` | int | `300` | Notebook spawn timeout in seconds |
| `singleuser.defaultUrl` | string | `/lab` | Default landing path for spawned notebooks |
| `singleuser.profiles` | list | `[]` | Profile list allowing users to select image/resource flavors |
| `imagePullSecrets` | list | `[]` | Image pull secrets for private registries |
| `service.type` | string | `ClusterIP` | Kubernetes Service type for public proxy |
| `service.port` | int | `80` | Service HTTP port for public traffic |
| `service.proxyApiPort` | int | `8001` | Service TCP port for internal proxy API |
| `service.ipFamilyPolicy` | string | `""` | Service IP family policy (`SingleStack`, `PreferDualStack`, `RequireDualStack`) |
| `service.ipFamilies` | list | `[]` | Service IP families (`IPv4`, `IPv6`) |
| `gateway.enabled` | bool | `false` | Enable Gateway API HTTPRoute |
| `gateway.apiVersion` | string | `gateway.networking.k8s.io/v1` | Gateway API version |
| `gateway.parentRefs` | list | `[]` | Gateway parentRefs routing to the HTTPRoute |
| `gateway.hostnames` | list | `[]` | Hostnames matched by HTTPRoute |
| `gateway.rules` | list | `[{matches: [{path: {type: "PathPrefix", value: "/"}}]}]` | HTTPRoute routing rules |
| `serviceAccount.create` | bool | `true` | Create dedicated ServiceAccount |
| `serviceAccount.name` | string | `""` | ServiceAccount name override |
| `rbac.create` | bool | `true` | Create namespaced Role and RoleBinding for KubeSpawner |
| `metrics.authenticatePrometheus` | bool | `true` | Require authentication for Prometheus `/hub/metrics` endpoint |
| `metrics.allowPublicUnauthenticatedPrometheus` | bool | `false` | Allow unauthenticated metrics on public endpoints |
| `metrics.serviceMonitor.enabled` | bool | `false` | Deploy Prometheus Operator ServiceMonitor |
| `metrics.serviceMonitor.interval` | string | `30s` | Scrape interval for ServiceMonitor |
| `podSecurityContext` | object | `{fsGroup: 1000, fsGroupChangePolicy: "OnRootMismatch", seccompProfile: {type: "RuntimeDefault"}}` | Pod-level security context |
| `securityContext` | object | `{allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}, readOnlyRootFilesystem: true, runAsGroup: 1000, runAsNonRoot: true, runAsUser: 1000}` | Container-level security context |
| `pdb.enabled` | bool | `true` | Enable PodDisruptionBudget for Hub |
| `pdb.minAvailable` | int / string | `1` | Minimum available pods during voluntary disruptions |
| `externalSecrets.enabled` | bool | `false` | Materialize proxy token via External Secrets Operator |
| `externalSecrets.secretStoreRef.name` | string | `""` | SecretStore or ClusterSecretStore name |
| `externalSecrets.secretStoreRef.kind` | string | `SecretStore` | SecretStore kind (`SecretStore` or `ClusterSecretStore`) |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		fsGroup:             1000
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: {
			drop: ["ALL"]
		}
	}
	serviceAccount: {
		create: true
	}
}
```

## Additional Resources
- [Official JupyterHub Website](https://jupyter.org/hub)
- [Official JupyterHub Repository](https://github.com/jupyterhub/jupyterhub)
- [JupyterHub Documentation](https://jupyterhub.readthedocs.io/)
- [Zero to JupyterHub on Kubernetes](https://z2jh.jupyter.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the JupyterHub module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| JupyterHub Hub (`jup-hub`) | Deployment | 11 points | ✅ |
| Configurable HTTP Proxy (`jup-proxy`) | Deployment | 12 points | ✅ |
