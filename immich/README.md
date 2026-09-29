# Immich

## Description
[Immich](https://immich.app/) is a self-hosted photo and video management solution. Easily back up, organize, and manage your photos on your own server. Immich helps you browse, search and organize your photos and videos with ease, without sacrificing your privacy.

## Application Information
- **Version:** `v3.1.0`
- **Upstream Project:** [https://github.com/immich-app/immich](https://github.com/immich-app/immich)
- **Container Base:** [ghcr.io/immich-app/immich-server](https://github.com/immich-app/immich/pkgs/container/immich-server) (`ghcr.io/immich-app/immich-server:v3.1.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Immich Server (`immich`):** Primary application Deployment running `ghcr.io/immich-app/immich-server:v3.1.0`. Provides the REST API, web UI, background microservices, and job orchestration. Exposes container port `2283` mapped to service port `80`.
- **Immich Machine Learning (`immich-machine-learning`):** Microservice Deployment running `ghcr.io/immich-app/immich-machine-learning:v3.1.0` on port `3003`. Handles heavy AI workloads including facial detection, CLIP image classification, and vector embeddings.
- **PostgreSQL Database (`immich-postgresql`):** Dedicated PostgreSQL 14 StatefulSet running `ghcr.io/immich-app/postgres:14-vectorchord1.1.1-pgvector0.8.5` with VectorChord and pgvector extensions for fast vector indexing.
- **Valkey In-Memory Cache (`immich-valkey`):** High-performance in-memory datastore StatefulSet running `docker.io/valkey/valkey:8.1.9` on port `6379`. Powers Immich background queues and caching.
- **Persistent Storage:**
  - **Upload Library (`library`):** Persistent volume claim (`50Gi`) mounted to `/usr/src/app/upload` storing original photos, videos, and generated thumbnails.
  - **Model Cache (`model-cache`):** Persistent volume claim (`10Gi`) mounted to `/cache` caching downloaded machine learning models.
  - **PostgreSQL Data (`pgdata`):** Dedicated Persistent Volume (`20Gi`) for the PostgreSQL database.
  - **Valkey Data (`valkey-data`):** Dedicated Persistent Volume (`5Gi`) for Valkey cache persistence.
- **Kubernetes Service (`immich`):** ClusterIP service exposing port 80 routing internally to the Immich server container port 2283.
- **Gateway API (`httproute`):** Optional Gateway API `HTTPRoute` resource for exposing Immich externally with TLS termination.
- **ServiceAccount (`immich`):** Dedicated unprivileged Kubernetes ServiceAccount for Immich pods.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support (or `ReadWriteMany` when scaling server replicas)
- Gateway API CRDs and Gateway controller (e.g. Envoy Gateway) if HTTPRoute routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply immich ./immich
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	server: {
		persistence: {
			size: "100Gi"
		}
	}
	gateway: {
		enabled: true
		hostnames: ["photos.example.com"]
		parentRefs: [{
			name:      "eg"
			namespace: "envoy-gateway-system"
		}]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply immich ./immich \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete immich
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | `string` | `""` | Override the chart name |
| `fullnameOverride` | `string` | `""` | Override the fully qualified release name |
| `commonLabels` | `{[string]: string}` | `{}` | Additional labels applied to all chart resources |
| `image.repository` | `string` | `"ghcr.io/immich-app/immich-server"` | Immich server image repository |
| `image.tag` | `string` | `"v3.1.0"` | Immich server image tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `imagePullSecrets` | `[...timoniv1.ObjectReference]` | `[]` | [Kubernetes image pull secrets](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod) |
| `machineLearning.enabled` | `bool` | `true` | Enable the Immich machine-learning service |
| `machineLearning.replicaCount` | `int` | `1` | Number of machine-learning replicas |
| `machineLearning.image.repository` | `string` | `"ghcr.io/immich-app/immich-machine-learning"` | Machine-learning image repository |
| `machineLearning.image.tag` | `string` | `"v3.1.0"` | Machine-learning image tag |
| `machineLearning.image.pullPolicy` | `string` | `"IfNotPresent"` | Machine-learning image pull policy |
| `machineLearning.service.port` | `int` | `3003` | Machine-learning service port |
| `machineLearning.persistence.enabled` | `bool` | `true` | Enable persistent model cache |
| `machineLearning.persistence.size` | `string` | `"10Gi"` | Model cache PVC size |
| `machineLearning.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "512Mi"}, limits: {cpu: "1", memory: "2Gi"}}` | Machine-learning resource requests and limits |
| `machineLearning.securityContext` | `corev1.#SecurityContext` | `{allowPrivilegeEscalation: false, readOnlyRootFilesystem: false, capabilities: {drop: ["ALL"]}}` | Security context for machine-learning container |
| `server.replicaCount` | `int` | `1` | Number of Immich server replicas |
| `server.revisionHistoryLimit` | `int` | `3` | Number of old ReplicaSets retained |
| `server.logLevel` | `string` | `"log"` | Immich log level (`log`, `debug`, `warn`, `error`) |
| `server.logFormat` | `string` | `"json"` | Immich log format |
| `server.timezone` | `string` | `"Etc/UTC"` | Container timezone |
| `server.persistence.enabled` | `bool` | `true` | Enable upload library persistence |
| `server.persistence.size` | `string` | `"50Gi"` | Upload library PVC size |
| `database.external.host` | `string` | `""` | External PostgreSQL hostname (used when `postgresql.enabled=false`) |
| `database.external.port` | `int` | `5432` | External PostgreSQL port |
| `database.external.database` | `string` | `"immich"` | External PostgreSQL database name |
| `database.external.username` | `string` | `"postgres"` | External PostgreSQL username |
| `database.external.password` | `string` | `""` | External PostgreSQL password |
| `database.external.existingSecret` | `string` | `""` | Existing Secret containing external PostgreSQL password |
| `postgresql.enabled` | `bool` | `true` | Enable the HelmForge PostgreSQL subchart with VectorChord image |
| `postgresql.image.repository` | `string` | `"ghcr.io/immich-app/postgres"` | PostgreSQL image repository recommended by Immich |
| `postgresql.image.tag` | `string` | `"14-vectorchord1.1.1-pgvector0.8.5"` | PostgreSQL image tag with VectorChord and pgvectors |
| `postgresql.auth.database` | `string` | `"immich"` | PostgreSQL database name |
| `postgresql.auth.username` | `string` | `"postgres"` | PostgreSQL username |
| `postgresql.auth.postgresPassword` | `string` | `"postgres-password"` | PostgreSQL superuser password |
| `postgresql.auth.password` | `string` | `"user-password"` | PostgreSQL user password |
| `postgresql.standalone.persistence.size` | `string` | `"20Gi"` | PostgreSQL PVC size |
| `postgresql.standalone.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1", memory: "1Gi"}}` | PostgreSQL resource requests and limits |
| `valkey.internal.enabled` | `bool` | `true` | Enable bundled Valkey/Redis cache |
| `valkey.architecture` | `string` | `"standalone"` | Redis chart architecture (`standalone` or `replication`) |
| `valkey.image.repository` | `string` | `"docker.io/valkey/valkey"` | Valkey image repository |
| `valkey.image.tag` | `string` | `"8.1.9"` | Valkey image tag |
| `valkey.auth.enabled` | `bool` | `true` | Enable cache password authentication |
| `valkey.auth.password` | `string` | `"valkey-password"` | Cache authentication password |
| `valkey.standalone.persistence.size` | `string` | `"5Gi"` | Valkey cache PVC size |
| `valkey.standalone.resources` | `timoniv1.#ResourceRequirements` | `{requests: {cpu: "50m", memory: "128Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Valkey resource requests and limits |
| `valkey.securityContext` | `corev1.#SecurityContext` | `{allowPrivilegeEscalation: false, readOnlyRootFilesystem: false, runAsNonRoot: true, runAsUser: 65510, runAsGroup: 65510, capabilities: {drop: ["ALL"]}}` | Security context for Valkey container |
| `externalSecrets.enabled` | `bool` | `false` | Render ExternalSecret resources for database and cache credentials |
| `serviceAccount.create` | `bool` | `true` | Create a dedicated ServiceAccount |
| `serviceAccount.name` | `string` | `""` | ServiceAccount name override |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount ServiceAccount token into Immich pods |
| `service.type` | `string` | `"ClusterIP"` | Service type for Immich server traffic |
| `service.port` | `int` | `80` | Kubernetes Service HTTP port |
| `service.targetPort` | `int` | `2283` | Immich server target container port |
| `gateway.enabled` | `bool` | `false` | Enable Gateway API HTTPRoute |
| `gateway.parentRefs` | `[...]` | `[]` | parentRefs pointing to existing Gateway resources |
| `gateway.hostnames` | `[...string]` | `[]` | Hostnames matched by the HTTPRoute |
| `networkPolicy.enabled` | `bool` | `false` | Enable NetworkPolicy for Immich pods |
| `autoscaling.enabled` | `bool` | `false` | Enable HorizontalPodAutoscaler for Immich server |
| `pdb.enabled` | `bool` | `true` | Enable PodDisruptionBudget for Immich server |
| `pdb.minAvailable` | `int` | `1` | Minimum available pods for PodDisruptionBudget |
| `resources.requests.cpu` | `string` | `"100m"` | Immich server CPU request |
| `resources.requests.memory` | `string` | `"512Mi"` | Immich server memory request |
| `resources.limits.cpu` | `string` | `"1"` | Immich server CPU limit |
| `resources.limits.memory` | `string` | `"2Gi"` | Immich server memory limit |
| `podSecurityContext` | `corev1.#PodSecurityContext` | `{seccompProfile: {type: "RuntimeDefault"}}` | Pod security context for Immich pods |
| `securityContext` | `corev1.#SecurityContext` | `{allowPrivilegeEscalation: false, capabilities: {drop: ["ALL"]}}` | Container security context for Immich server |
| `nodeSelector` | `{[string]: string}` | `{}` | Node selector for pod scheduling |
| `tolerations` | `[...corev1.#Toleration]` | `[]` | Tolerations for pod scheduling |
| `affinity` | `timoniv1.#AffinityValues` | `{}` | Affinity rules for pod scheduling |
| `topologySpreadConstraints` | `[...corev1.#TopologySpreadConstraint]` | `[]` | Topology spread constraints for pod scheduling |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: [
				"ALL",
			]
		}
	}
}
```

## Additional Resources
- [Official Immich Website](https://immich.app/)
- [Official Immich Repository](https://github.com/immich-app/immich)
- [Immich Documentation](https://immich.app/docs/overview/introduction)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Immich module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Immich Server (`immich`) | Deployment | 14 points | ✅ |
| PostgreSQL Database (`immich-postgresql`) | StatefulSet | 10 points | ✅ |
| Valkey In-Memory Cache (`immich-valkey`) | StatefulSet | 15 points | ✅ |
