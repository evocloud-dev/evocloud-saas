# SiYuan

## Description

[SiYuan](https://b3log.org/siyuan/) is a privacy-first, local-first personal knowledge management system with fine-grained block-level refactoring and Markdown WYSIWYG editing.

## Application Information

- **Version:** 3.8.3
- **Official Website:** [https://b3log.org/siyuan/](https://b3log.org/siyuan/)
- **Upstream Project:** [https://github.com/siyuan-note/siyuan](https://github.com/siyuan-note/siyuan)
- **Container Base:** [docker.io/b3log/siyuan](https://hub.docker.com/r/b3log/siyuan) (`docker.io/b3log/siyuan:v3.8.3`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **SiYuan Kernel & Web Application (`siyuan`):** Core knowledge management engine and frontend running unprivileged `/opt/siyuan/kernel serve` under UID/GID 1000 on port `6806`.
- **Deployment (`siyuan`):** Exactly 1 replica workload enforcing a `Recreate` deployment strategy to protect SQLite database and workspace volume integrity.
- **Service (`siyuan`):** Kubernetes Service exposing the SiYuan HTTP listener on port `6806`.
- **PersistentVolumeClaim (`siyuan`):** Dedicated persistent volume claim for `/siyuan/workspace` preserving configuration, database, assets, and version history.
- **Secret (`siyuan-auth`):** Managed Kubernetes Secret storing the administrative access code (or referencing an existing Secret).
- **OIDC Secret (`siyuan-oidc`):** Optional managed Kubernetes Secret holding client credentials when native OIDC authentication is enabled.
- **ServiceAccount (`siyuan`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **Gateway API HTTPRoute (`siyuan`):** Optional Gateway API HTTPRoute definitions for Kubernetes Gateway API controllers.
- **ExternalSecret (`siyuan`):** Optional External Secrets Operator v1 resource for syncing external secrets.

## Prerequisites

- Kubernetes cluster v1.26+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active
- Optional: [External Secrets Operator](https://external-secrets.io) if `externalSecrets.enabled` is active

## Install

To create an instance using default values:

```bash
timoni -n default apply siyuan ./siyuan
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	persistence: {
		size:         "20Gi"
		storageClass: "fast-rbd"
	}
	server: port: 6806
	resources: {
		requests: {
			cpu:    "100m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1Gi"
		}
	}
}
```

Apply the custom values to the instance:

```bash
timoni -n default apply siyuan ./siyuan \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```bash
timoni -n default delete siyuan
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the chart name used in resource names |
| `fullnameOverride` | `string` | `""` | Override the complete resource name |
| `commonLabels` | `object` | `{}` | Extra resource labels; selector labels are reserved |
| `replicaCount` | `int` | `1` | Exactly one writer per workspace, including RWX volumes |
| `image.repository` | `string` | `"docker.io/b3log/siyuan"` | Container image repository |
| `image.tag` | `string` | `"v3.8.3"` | Verified stable image tag |
| `image.digest` | `string` | `""` | Container image digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for a private mirror |
| `auth.accessCode` | `string` | `""` | Native administrative access code (empty generates 32 random alphanumeric characters) |
| `auth.existingSecret` | `string` | `""` | Existing access-code Secret; do not combine with an inline code |
| `auth.accessCodeKey` | `string` | `"access-code"` | Key containing the native access code, distinct from an API token |
| `server.port` | `int` | `6806` | Container listen port; Service and probes follow this value |
| `extraEnv` | `list` | `[]` | Additional environment entries; chart-managed security variables cannot be overridden |
| `envFrom` | `list` | `[]` | Additional envFrom Secret/ConfigMap references |
| `serviceAccount.create` | `bool` | `true` | Create a dedicated ServiceAccount with no API permissions |
| `serviceAccount.name` | `string` | `""` | Existing or overridden ServiceAccount name |
| `serviceAccount.annotations` | `object` | `{}` | ServiceAccount annotations |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount Service Account Token |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `6806` | Service HTTP port |
| `service.annotations` | `object` | `{}` | Service annotations |
| `service.ipFamilyPolicy` | `string` | `""` | Service IP family policy; empty uses cluster default |
| `service.ipFamilies` | `list` | `[]` | Requested address families; RequireDualStack needs a dual-stack cluster |
| `gatewayAPI.enabled` | `bool` | `false` | Render canonical Gateway API HTTPRoutes |
| `gatewayAPI.gatewayClassName` | `string` | `""` | Optional GatewayClass controller name |
| `gatewayAPI.httpRoutes` | `list` | `[...]` | Route definitions with parentRefs, hostnames, rules, labels and annotations |
| `externalSecrets.enabled` | `bool` | `false` | Enable External Secrets Operator resources |
| `externalSecrets.refreshInterval` | `string` | `"1h"` | Default operator refresh interval |
| `externalSecrets.items` | `list` | `[]` | ExternalSecret resource definitions |
| `probes.startup.enabled` | `bool` | `true` | Wait for native kernel boot completion before liveness starts |
| `probes.startup.path` | `string` | `"/api/system/bootProgress"` | Startup probe HTTP path |
| `probes.startup.requireBootComplete` | `bool` | `true` | Require native boot progress 100 before startup/readiness succeeds |
| `probes.startup.periodSeconds` | `int` | `5` | Startup probe check interval |
| `probes.startup.timeoutSeconds` | `int` | `2` | Startup probe timeout |
| `probes.startup.failureThreshold` | `int` | `60` | Startup probe failure threshold |
| `probes.liveness.enabled` | `bool` | `true` | Check local HTTP availability without requiring external services |
| `probes.liveness.path` | `string` | `"/api/system/version"` | Liveness probe HTTP path |
| `probes.liveness.requireBootComplete` | `bool` | `false` | Require native boot progress 100 before startup/readiness succeeds |
| `probes.liveness.periodSeconds` | `int` | `20` | Liveness probe check interval |
| `probes.liveness.timeoutSeconds` | `int` | `3` | Liveness probe timeout |
| `probes.liveness.failureThreshold` | `int` | `3` | Liveness probe failure threshold |
| `probes.readiness.enabled` | `bool` | `true` | Require complete kernel initialization before admitting traffic |
| `probes.readiness.path` | `string` | `"/api/system/bootProgress"` | Readiness probe HTTP path |
| `probes.readiness.requireBootComplete` | `bool` | `true` | Require native boot progress 100 before startup/readiness succeeds |
| `probes.readiness.periodSeconds` | `int` | `10` | Readiness probe check interval |
| `probes.readiness.timeoutSeconds` | `int` | `3` | Readiness probe timeout |
| `probes.readiness.failureThreshold` | `int` | `3` | Readiness probe failure threshold |
| `resources.requests.cpu` | `string` | `"100m"` | CPU request for indexing and workspace operations |
| `resources.requests.memory` | `string` | `"256Mi"` | Memory request for indexing and workspace operations |
| `resources.limits.cpu` | `string` | `"1000m"` | CPU limit for indexing and workspace operations |
| `resources.limits.memory` | `string` | `"1Gi"` | Memory limit for indexing and workspace operations |
| `podSecurityContext.runAsNonRoot` | `bool` | `true` | Enforce non-root execution |
| `podSecurityContext.runAsUser` | `int` | `1000` | Run as non-root user UID |
| `podSecurityContext.runAsGroup` | `int` | `1000` | Run as non-root group GID |
| `podSecurityContext.fsGroup` | `int` | `1000` | Filesystem group ID for the workspace volume |
| `podSecurityContext.fsGroupChangePolicy` | `string` | `"OnRootMismatch"` | Filesystem group permission change policy |
| `podSecurityContext.seccompProfile.type` | `string` | `"RuntimeDefault"` | Pod seccomp profile type |
| `securityContext.allowPrivilegeEscalation` | `bool` | `false` | Prevent container privilege escalation |
| `securityContext.readOnlyRootFilesystem` | `bool` | `true` | Mount root filesystem as read-only |
| `securityContext.capabilities.drop` | `list` | `["ALL"]` | Linux capabilities dropped from container |
| `podLabels` | `object` | `{}` | Pod labels; immutable selector labels cannot be overridden |
| `podAnnotations` | `object` | `{}` | Pod annotations, e.g. for an external Secret reloader |
| `nodeSelector` | `object` | `{}` | Node selection constraints |
| `tolerations` | `list` | `[]` | Scheduling tolerations |
| `affinity` | `object` | `{}` | Pod affinity or anti-affinity rules |
| `topologySpreadConstraints` | `list` | `[]` | Topology spreading across nodes or zones |
| `priorityClassName` | `string` | `""` | Scheduling priority class |
| `terminationGracePeriodSeconds` | `int` | `30` | Grace period for HTTP shutdown |
| `persistence.enabled` | `bool` | `true` | Persist the complete workspace volume |
| `persistence.existingClaim` | `string` | `""` | Pre-existing workspace PVC; disables PVC creation |
| `persistence.storageClass` | `string` | `""` | StorageClass name; empty uses cluster default |
| `persistence.size` | `string` | `"10Gi"` | Workspace claim capacity |
| `persistence.accessModes` | `list` | `["ReadWriteOnce"]` | PVC access modes |
| `persistence.retain` | `bool` | `true` | Keep the generated PVC on uninstall |
| `persistence.annotations` | `object` | `{}` | Annotations for the PersistentVolumeClaim |
| `oidc.enabled` | `bool` | `false` | Enable native OIDC alongside local access-code login |
| `oidc.provider` | `string` | `"custom"` | Standard custom OIDC provider contract |
| `oidc.issuerURL` | `string` | `""` | Issuer URL used for discovery, JWKS and token exchange |
| `oidc.clientID` | `string` | `""` | Registered OIDC client identifier |
| `oidc.clientSecret` | `string` | `""` | Inline client credential stored only in Secret |
| `oidc.existingSecret` | `string` | `""` | Existing Secret containing client credential |
| `oidc.clientSecretKey` | `string` | `"client-secret"` | Key containing the OIDC client credential |
| `oidc.scopes` | `list` | `["openid", "profile", "email"]` | Scopes requested during authorization |
| `oidc.redirectURL` | `string` | `""` | Exact HTTPS callback ending in `/api/system/oidc/callback` |
| `oidc.allowAll` | `bool` | `false` | Grant workspace administration to every authenticated identity |
| `oidc.claimRules` | `list` | `[]` | AND across rules, OR across values for claim admission |
| `extraContainers` | `list` | `[]` | Optional companion containers |

---

### Recommended values

SiYuan workloads comply with the **Restricted** Kubernetes Pod Security Standard by running as the unprivileged non-root user (UID/GID 1000:1000), mounting an immutable read-only root filesystem (`readOnlyRootFilesystem: true`), dropping all Linux capabilities (`drop: ["ALL"]`), setting `allowPrivilegeEscalation: false`, and applying a default `RuntimeDefault` seccomp profile:

```cue
values: {
	podSecurityContext: {
		runAsNonRoot:        true
		runAsUser:           1000
		runAsGroup:          1000
		fsGroup:             1000
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

---

## Additional Resources

- [Official SiYuan Website](https://b3log.org/siyuan/)
- [Official SiYuan GitHub Repository](https://github.com/siyuan-note/siyuan)
- [SiYuan HelmForge Documentation](https://helmforge.dev/docs/charts/siyuan)
- [Timoni Documentation](https://timoni.sh)

---

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the SiYuan module workloads:

| Workload | Kind | Kubesec Score | Status |
| :--- | :--- | :--- | :--- |
| SiYuan Workload (`siyuan`) | Deployment | 12 points | ✅ |
