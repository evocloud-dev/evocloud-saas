# Langflow

## Description
[Langflow](https://www.langflow.org/) is a dynamic, visual framework and low-code web platform for building, prototyping, and deploying multi-agent applications, Retrieval-Augmented Generation (RAG) pipelines, and Large Language Model (LLM) workflows. With an intuitive drag-and-drop canvas, customizable Python components, and native support for major AI frameworks (including LangChain, LlamaIndex, OpenAI, Anthropic, and Hugging Face), Langflow empowers developers to experiment, iterate, and deploy production-ready generative AI solutions seamlessly.

## Application Information
- **Version:** `1.11.5`
- **Upstream Project:** [https://github.com/langflow-ai/langflow](https://github.com/langflow-ai/langflow)
- **Container Base:** [docker.io/langflowai/langflow](https://hub.docker.com/r/langflowai/langflow) (`docker.io/langflowai/langflow:1.11.5`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Langflow Core (`deploy`):** Primary application Deployment running `docker.io/langflowai/langflow:1.11.5` on port `7860`. Serves the visual canvas interface, REST API, WebSocket streams, component registry, and flow execution runtime.
- **Database Engine:** Embedded SQLite database persisted on local storage (`/app/langflow`), with optional out-of-the-box support for external PostgreSQL/MySQL databases via SQLAlchemy connection strings.
- **Persistent Volume (`pvc`):** Persistent Volume Claim (`5Gi`, default `ReadWriteOnce`) mounted to `/app/langflow` storing flows, local configurations, API credentials, and SQLite database files.
- **Kubernetes Service (`svc`):** ClusterIP Service exposing port `7860` for internal cluster routing and Gateway API ingress integration.
- **Gateway API HTTPRoute (`httproute`):** Optional Gateway API `HTTPRoute` resource for cluster edge routing, custom hostname binding, and TLS termination.
- **PodDisruptionBudget (`pdb`):** Guarantees high availability and application continuity during voluntary node disruptions and upgrades.
- **NetworkPolicy (`networkpolicy`):** Optional granular network policy controlling ingress from specific namespaces and egress to DNS/external LLM APIs.
- **Secrets (`secret`, `dbSecret`):** Cryptographically protects `LANGFLOW_SECRET_KEY`, superuser credentials, and external database credentials.
- **ServiceAccount (`sa`):** Dedicated unprivileged Kubernetes ServiceAccount for Langflow pods.

## Prerequisites
- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass with `ReadWriteOnce` volume support (or `ReadWriteMany` when scaling replicas across nodes)
- Gateway API CRDs and Gateway controller (e.g. Envoy Gateway) if HTTPRoute routing is enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply langflow ./langflow
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	auth: {
		superuser:         "admin"
		superuserPassword: "StrongSecretPassword123!"
	}
	persistence: {
		size: "10Gi"
	}
	gateway: {
		enabled:   true
		hostnames: ["langflow.example.com"]
		parentRefs: [{
			name:      "eg"
			namespace: "envoy-gateway-system"
		}]
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply langflow ./langflow \
  --values ./my-values.cue
```

## Uninstall

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n default delete langflow
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | `string` | `""` | Override the chart name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the full release name used in resource names |
| `commonLabels` | `{[string]: string}` | `{}` | Labels added to every rendered resource |
| `image.repository` | `string` | `"docker.io/langflowai/langflow"` | Official Langflow image repository |
| `image.tag` | `string` | `"1.11.5"` | Official Langflow image tag |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | [Kubernetes image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| `imagePullSecrets` | `[...corev1.#LocalObjectReference]` | `[]` | [Kubernetes image pull secrets](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod) |
| `replicaCount` | `int` | `1` | Number of Langflow replicas (scaling > 1 requires external DB and RWX storage) |
| `app.port` | `int` | `7860` | Langflow application HTTP port |
| `app.command` | `[...string]` | `[]` | Optional container command override |
| `app.args` | `[...string]` | `[]` | Optional container arguments override |
| `app.env` | `[...corev1.#EnvVar]` | `[]` | Additional Langflow environment variables |
| `app.envFrom` | `[...corev1.#EnvFromSource]` | `[]` | Environment variables from ConfigMaps or Secrets |
| `app.extraEnv` | `[...corev1.#EnvVar]` | `[]` | Extra environment variables appended after managed variables |
| `auth.secretKey` | `string` | `""` | Secret key used for sensitive data encryption and JWT signing (auto-generated when empty) |
| `auth.superuser` | `string` | `"admin"` | Initial administrator username |
| `auth.superuserPassword` | `string` | `"Changeit@123"` | Initial administrator password |
| `auth.existingSecret` | `string` | `""` | Existing Secret containing auth credentials |
| `database.mode` | `string` | `"sqlite"` | Database mode (`sqlite` or `external`) |
| `database.url` | `string` | `""` | External SQLAlchemy database connection URL (e.g. PostgreSQL) |
| `database.existingSecret` | `string` | `""` | Existing Secret containing external database URL |
| `persistence.enabled` | `bool` | `true` | Persist Langflow local config and SQLite database |
| `persistence.size` | `string` | `"5Gi"` | Size of the persistent volume claim |
| `persistence.storageClass` | `string` | `""` | StorageClass for PVC (empty uses cluster default) |
| `persistence.accessModes` | `[...string]` | `["ReadWriteOnce"]` | Persistent volume access modes |
| `persistence.existingClaim` | `string` | `""` | Name of an existing PVC to use |
| `persistence.mountPath` | `string` | `"/app/langflow"` | Mounted Langflow configuration and data directory |
| `serviceAccount.create` | `bool` | `true` | Create a dedicated ServiceAccount |
| `serviceAccount.name` | `string` | `""` | Override ServiceAccount name |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount Kubernetes API token into the Langflow pod |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.port` | `int` | `7860` | Kubernetes Service HTTP port |
| `gateway.enabled` | `bool` | `false` | Create a Gateway API HTTPRoute for Langflow |
| `gateway.parentRefs` | `[...]` | `[]` | Gateway API parent references |
| `gateway.hostnames` | `[...string]` | `[]` | Hostnames matched by the HTTPRoute |
| `gateway.path` | `string` | `"/"` | HTTPRoute path match value |
| `pdb.enabled` | `bool` | `true` | Create a PodDisruptionBudget |
| `pdb.minAvailable` | `int` | `1` | Minimum available pods during voluntary disruptions |
| `networkPolicy.enabled` | `bool` | `false` | Create a NetworkPolicy limiting inbound Langflow traffic |
| `resources.requests.cpu` | `string` | `"100m"` | Langflow container requested CPU |
| `resources.requests.memory` | `string` | `"512Mi"` | Langflow container requested memory |
| `resources.limits.cpu` | `string` | `"2"` | Langflow container CPU limit |
| `resources.limits.memory` | `string` | `"2Gi"` | Langflow container memory limit |
| `podSecurityContext` | `corev1.#PodSecurityContext` | *(runAsUser: 1000, runAsNonRoot: true, RuntimeDefault seccomp)* | Pod security context |
| `securityContext` | `corev1.#SecurityContext` | *(runAsUser: 1000, runAsNonRoot: true, capabilities drop: ALL)* | Container security context |
| `nodeSelector` | `{[string]: string}` | `{}` | Node selector labels for pod scheduling |
| `tolerations` | `[...corev1.#Toleration]` | `[]` | Tolerations for pod scheduling |
| `affinity` | `corev1.#Affinity` | `{}` | Affinity and anti-affinity scheduling rules |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:     1000
		runAsGroup:    1000
		fsGroup:       1000
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		runAsUser:                1000
		runAsGroup:               1000
		capabilities: {
			drop: [
				"ALL",
			]
		}
	}
}
```

## Additional Resources
- [Official Langflow Website](https://www.langflow.org/)
- [Official Langflow Repository](https://github.com/langflow-ai/langflow)
- [Langflow Documentation](https://docs.langflow.org/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Langflow module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Langflow Core (`langflow`) | Deployment | 11 points | ✅ |
