# BentoPDF

## Description

[BentoPDF](https://www.bentopdf.com/) is an open-source, privacy-first web application providing a comprehensive suite of PDF tools that run entirely client-side in the user's browser. With zero server-side document persistence or background processing, all PDF manipulation (merging, splitting, conversion, signing, redacting, and OCR) executes locally via WebAssembly and modern browser capabilities, ensuring absolute confidentiality and data isolation.

## Application Information

- **Version:** 2.8.8
- **Official Website:** [https://www.bentopdf.com/](https://www.bentopdf.com/)
- **Upstream Project:** [https://github.com/alam00000/bentopdf](https://github.com/alam00000/bentopdf)
- **Container Base:** [ghcr.io/alam00000/bentopdf](https://ghcr.io/alam00000/bentopdf) (`ghcr.io/alam00000/bentopdf:2.8.8`), [docker.io/nginx/nginx-prometheus-exporter](https://hub.docker.com/r/nginx/nginx-prometheus-exporter) (`docker.io/nginx/nginx-prometheus-exporter:1.5.3`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components

- **BentoPDF Web Application (`bentopdf`):** Frontend static web server and browser-local PDF processing suite executing an unprivileged NGINX server on port `8080`.
- **NGINX Prometheus Exporter (`nginx-exporter`):** Sidecar container (`nginx-prometheus-exporter:1.5.3`) scraping NGINX loopback statistics on port `8081` (`/stub_status`) and exposing Prometheus metrics on port `9113`.
- **ConfigMap (`bentopdf`):** Dedicated ConfigMap containing rendered `nginx.conf` and `config.json` mounted at `/etc/nginx/nginx.conf` and `/usr/share/nginx/html/config.json`.
- **Service (`bentopdf`):** Public Kubernetes Service exposing the BentoPDF web application on port `8080`.
- **Metrics Service (`bentopdf-metrics`):** Dedicated private Kubernetes Service exposing Prometheus metrics on port `9113`.
- **ServiceMonitor (`bentopdf`):** Optional Prometheus Operator CRD (`monitoring.coreos.com/v1`) for automated scrape configuration.
- **PrometheusRule (`bentopdf`):** Optional Prometheus alerting rules detecting exporter unavailability (`BentoPDFNginxUnavailable`).
- **ServiceAccount (`bentopdf`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.
- **NetworkPolicy (`bentopdf`):** Pod network isolation enforcing ingress restriction to HTTP and metrics ports, and default-deny outbound egress.
- **HorizontalPodAutoscaler (`bentopdf`):** Optional HorizontalPodAutoscaler scaling replicas based on static-serving container CPU utilization.
- **PodDisruptionBudget (`bentopdf`):** Optional PodDisruptionBudget protecting service availability during voluntary disruptions.
- **Gateway API HTTPRoute (`bentopdf`):** Optional Gateway API HTTPRoute definitions for Kubernetes Gateway API controllers.

## Prerequisites

- Kubernetes cluster v1.30+
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Optional: [Prometheus Operator](https://prometheus-operator.dev) if `metrics.serviceMonitor.enabled` or `metrics.prometheusRule.enabled` is active
- Optional: [Gateway API](https://gateway-api.sigs.k8s.io) CRDs if `gatewayAPI.enabled` is active
- Optional: Ingress controller (e.g., Ingress-NGINX, Traefik) if `ingress.enabled` is active

## Install

To create an instance using default values:

```bash
timoni -n default apply bentopdf ./bentopdf
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	replicaCount: 2
	server: port: 8080
	ingress: {
		enabled:          true
		ingressClassName: "nginx"
		hosts: [
			{
				host: "pdf.example.com"
				paths: [{
					path:     "/"
					pathType: "Prefix"
				}]
			},
		]
	}
	metrics: {
		enabled: true
		serviceMonitor: enabled: true
	}
}
```

Apply the custom values to the instance:

```bash
timoni -n default apply bentopdf ./bentopdf \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and delete all its Kubernetes resources:

```bash
timoni -n default delete bentopdf
```

## Configuration

### General values

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `nameOverride` | `string` | `""` | Override the short chart resource name |
| `fullnameOverride` | `string` | `""` | Override the full release resource name |
| `commonLabels` | `object` | `{}` | Extra resource labels; selector labels are reserved |
| `replicaCount` | `int` | `1` | Stateless replicas; PDF processing occurs in the browser |
| `image.repository` | `string` | `"ghcr.io/alam00000/bentopdf"` | BentoPDF container image repository |
| `image.tag` | `string` | `"2.8.8"` | Verified stable container image tag |
| `image.digest` | `string` | `""` | Container image digest |
| `image.pullPolicy` | `string` | `"IfNotPresent"` | Kubernetes image pull policy |
| `imagePullSecrets` | `list` | `[]` | Registry credentials for private image mirror |
| `server.port` | `int` | `8080` | Service HTTP port (8081 reserved for loopback stub_status) |
| `server.ipv6` | `bool` | `true` | Enable NGINX IPv6 listener |
| `config.disabledTools` | `list` | `[]` | Public runtime tool controls to hide in UI |
| `config.editorDisabledCategories` | `list` | `[]` | Native editor category IDs to disable |
| `serviceAccount.create` | `bool` | `true` | Create dedicated ServiceAccount with no API permissions |
| `serviceAccount.name` | `string` | `""` | Existing or overridden ServiceAccount name |
| `serviceAccount.annotations` | `object` | `{}` | ServiceAccount annotations |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Automount Service Account Token |
| `service.type` | `string` | `"ClusterIP"` | Kubernetes Service type |
| `service.port` | `int` | `8080` | Service HTTP port |
| `service.annotations` | `object` | `{}` | Service annotations |
| `service.ipFamilyPolicy` | `string` | `""` | Service IP family policy; empty uses cluster default |
| `service.ipFamilies` | `list` | `[]` | Requested address families; RequireDualStack needs dual-stack |
| `ingress.enabled` | `bool` | `false` | Create an Ingress for the application Service |
| `ingress.ingressClassName` | `string` | `""` | Ingress controller class; empty omits the field |
| `ingress.annotations` | `object` | `{}` | Ingress annotations |
| `ingress.hosts` | `list` | `[]` | Host and path routing rules |
| `ingress.tls` | `list` | `[]` | TLS host and Secret entries |
| `gatewayAPI.enabled` | `bool` | `false` | Render canonical Gateway API HTTPRoutes |
| `gatewayAPI.httpRoutes` | `list` | `[]` | Route definitions with parentRefs, hostnames, and rules |
| `networkPolicy.enabled` | `bool` | `true` | Create NetworkPolicies for ingress and pod egress |
| `networkPolicy.ingressFrom` | `list` | `[]` | Allowed ingress peers; empty allows pods in namespace |
| `networkPolicy.egressIsolation` | `bool` | `true` | Isolate outbound traffic; browser CDN requests unaffected |
| `networkPolicy.extraEgress` | `list` | `[]` | Explicit extra egress rules; default empty denies egress |
| `probes.startup.enabled` | `bool` | `true` | Enable startup probe |
| `probes.startup.path` | `string` | `"/"` | Startup probe HTTP path |
| `probes.liveness.enabled` | `bool` | `true` | Enable liveness probe |
| `probes.liveness.path` | `string` | `"/"` | Liveness probe HTTP path |
| `probes.readiness.enabled` | `bool` | `true` | Enable readiness probe |
| `probes.readiness.path` | `string` | `"/"` | Readiness probe HTTP path |
| `resources.requests.cpu` | `string` | `"50m"` | CPU request for static serving container |
| `resources.requests.memory` | `string` | `"64Mi"` | Memory request for static serving container |
| `resources.limits.cpu` | `string` | `"500m"` | CPU limit for static serving container |
| `resources.limits.memory` | `string` | `"256Mi"` | Memory limit for static serving container |
| `podDisruptionBudget.enabled` | `bool` | `false` | Protect voluntary disruptions (requires $\ge 2$ replicas) |
| `podDisruptionBudget.maxUnavailable` | `int` | `1` | Maximum unavailable pods during disruption |
| `podLabels` | `object` | `{}` | Pod labels; immutable selector labels cannot be overridden |
| `podAnnotations` | `object` | `{}` | Pod annotations, e.g. for external secret reloaders |
| `nodeSelector` | `object` | `{}` | Node selection constraints |
| `tolerations` | `list` | `[]` | Scheduling tolerations |
| `affinity` | `object` | `{}` | Pod affinity or anti-affinity rules |
| `topologySpreadConstraints` | `list` | `[]` | Topology spreading across nodes or zones |
| `priorityClassName` | `string` | `""` | Scheduling priority class |
| `terminationGracePeriodSeconds` | `int` | `30` | Grace period for HTTP shutdown |
| `autoscaling.enabled` | `bool` | `false` | Create HorizontalPodAutoscaler for static file serving |
| `autoscaling.minReplicas` | `int` | `2` | Minimum stateless replicas |
| `autoscaling.maxReplicas` | `int` | `5` | Maximum replicas allowed by the HPA |
| `autoscaling.targetCPUUtilizationPercentage` | `int` | `70` | Target CPU utilization of bentopdf container |
| `metrics.enabled` | `bool` | `false` | Run NGINX Prometheus exporter and expose metrics Service |
| `metrics.image.repository` | `string` | `"docker.io/nginx/nginx-prometheus-exporter"` | Exporter container image repository |
| `metrics.image.tag` | `string` | `"1.5.3"` | Exporter container image tag |
| `metrics.port` | `int` | `9113` | Metrics Service HTTP port |
| `metrics.resources.requests.cpu` | `string` | `"10m"` | CPU request for metrics exporter container |
| `metrics.resources.requests.memory` | `string` | `"32Mi"` | Memory request for metrics exporter container |
| `metrics.resources.limits.cpu` | `string` | `"100m"` | CPU limit for metrics exporter container |
| `metrics.resources.limits.memory` | `string` | `"64Mi"` | Memory limit for metrics exporter container |
| `metrics.serviceMonitor.enabled` | `bool` | `false` | Deploy Prometheus Operator ServiceMonitor |
| `metrics.serviceMonitor.interval` | `string` | `"30s"` | Prometheus scrape interval |
| `metrics.serviceMonitor.scrapeTimeout` | `string` | `"10s"` | Prometheus scrape timeout |
| `metrics.prometheusRule.enabled` | `bool` | `false` | Deploy Prometheus Operator alerting rules |
| `metrics.prometheusRule.additionalRules` | `list` | `[]` | Additional native Prometheus alerting or recording rules |
| `metrics.ingressFrom` | `list` | `[]` | Allowed ingress peers for metrics port 9113 |

---

### Recommended values

BentoPDF workloads comply with the **Restricted** Kubernetes Pod Security Standard by running as the unprivileged non-root user (UID/GID 101:101), mounting an immutable read-only root filesystem (`readOnlyRootFilesystem: true`), dropping all Linux capabilities (`drop: ["ALL"]`), setting `allowPrivilegeEscalation: false`, and applying a default `RuntimeDefault` seccomp profile:

```cue
values: {
	podSecurityContext: {
		runAsNonRoot: true
		runAsUser:    101
		runAsGroup:   101
		fsGroup:      101
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

- [Official BentoPDF GitHub Repository](https://github.com/alam00000/bentopdf)
- [BentoPDF HelmForge Documentation](https://helmforge.dev/docs/charts/bentopdf)
- [Timoni Documentation](https://timoni.sh)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the BentoPDF module workloads:

| Workload | Kind | Kubesec Score | Status |
| :--- | :--- | :--- | :--- |
| BentoPDF Workload (`bentopdf`) | Deployment | 12 points | ✅ |
