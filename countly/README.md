# Countly

## Description
[Countly](https://countly.com/) brings first-party product analytics and user engagement together in one privacy-first platform, giving you control over your data, hosting, and customer experience.

## Application Information
- **Version:** 25.05.4
- **Upstream Project:** [https://github.com/Countly/countly-server](https://github.com/Countly/countly-server)
- **Container Base:**
  - Countly API: [docker.io/countly/api](https://hub.docker.com/r/countly/api) (`docker.io/countly/api:25.05.4`)
  - Countly Frontend: [docker.io/countly/frontend](https://hub.docker.com/r/countly/frontend) (`docker.io/countly/frontend:25.05.4`)
  - MongoDB Database: [docker.io/library/mongo](https://hub.docker.com/_/mongo) (`docker.io/library/mongo:7.0`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Countly API (`countly-api`):** Core API backend processing analytics beacons, managing worker queues, handling plugin integrations, and interfacing with MongoDB.
- **Countly Frontend (`countly-frontend`):** Web dashboard providing visualization, user journey tracking, report management, and system administration.
- **MongoDB Database (`countly-mongodb`):** Dedicated MongoDB 7.0 StatefulSet managing application data, analytics events, and user collections with persistent storage (`8Gi`).
- **Countly API Service (`countly-api`):** ClusterIP service routing internal API traffic to container port 3001 (exposed on port 3000).
- **Countly Frontend Service (`countly-frontend`):** ClusterIP service routing web interface requests to container port 6001 (exposed on port 3000).
- **MongoDB Service (`countly-mongodb`):** ClusterIP service routing database traffic on TCP port 27017.
- **Gateway API HTTPRoutes (`route_api`, `route_frontend`):** Native Kubernetes Gateway API HTTPRoutes routing external analytics beacons and web traffic through a shared gateway.
- **ServiceAccounts (`countly-api`, `countly-frontend`):** Dedicated unprivileged Kubernetes ServiceAccounts assigned to the API and Frontend workloads.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Gateway API CRDs (`gateway.networking.k8s.io/v1`) and a configured Gateway (e.g. Envoy Gateway) if HTTPRoutes are enabled

## Install

To create an instance using default values:

```shell
timoni -n default apply countly ./countly
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	hostname: "countly.example.com"
	api: {
		resources: {
			requests: {
				cpu:    "200m"
				memory: "400Mi"
			}
			limits: {
				cpu:    "1000m"
				memory: "2Gi"
			}
		}
	}
	frontend: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "100Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "500Mi"
			}
		}
	}
	mongodb: {
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "1Gi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply countly ./countly \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete countly
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `hostname` | string | `localhost` | Fully qualified domain name or hostname for Countly services |
| `api.image.registry` | string | `docker.io` | Container image registry for Countly API |
| `api.image.repository` | string | `countly/api` | Container image repository for Countly API |
| `api.image.tag` | string | `25.05.4` | Pinned container image tag for Countly API |
| `api.replicaCount` | int | `1` | Number of API replicas |
| `api.service.port` | int | `3000` | Kubernetes Service port for Countly API |
| `api.resources` | object | `{requests: {cpu: "200m", memory: "400Mi"}, limits: {cpu: "1000m", memory: "2Gi"}}` | Resource requests and limits for API pods |
| `frontend.image.registry` | string | `docker.io` | Container image registry for Countly Frontend |
| `frontend.image.repository` | string | `countly/frontend` | Container image repository for Countly Frontend |
| `frontend.image.tag` | string | `25.05.4` | Pinned container image tag for Countly Frontend |
| `frontend.replicaCount` | int | `1` | Number of Frontend replicas |
| `frontend.service.port` | int | `3000` | Kubernetes Service port for Countly Frontend |
| `frontend.resources` | object | `{requests: {cpu: "100m", memory: "100Mi"}, limits: {cpu: "500m", memory: "500Mi"}}` | Resource requests and limits for Frontend pods |
| `mongodb.enabled` | bool | `true` | Deploy internal MongoDB StatefulSet |
| `mongodb.image.repository` | string | `library/mongo` | Container image repository for MongoDB |
| `mongodb.image.tag` | string | `7.0` | Container image tag for MongoDB |
| `mongodb.useStatefulSet` | bool | `true` | Use StatefulSet deployment mode for MongoDB persistence |
| `mongodb.auth.database` | string | `countly` | Database name for Countly application data |
| `mongodb.resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "1Gi"}}` | Resource requests and limits for MongoDB |
| `config.plugins` | string | *(core plugins)* | Comma-separated list of enabled Countly plugins |
| `config.nodeOptions` | string | `--max-old-space-size=2048` | Node.js memory and runtime execution options |

### Recommended values

Comply with the restricted Kubernetes pod security standards:

```cue
values: {
	podSecurityContext: {
		runAsUser:  65510
		runAsGroup: 65510
		fsGroup:    65510
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		runAsNonRoot:             true
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}
}
```

## Additional Resources
- [Official Countly Website](https://countly.com/)
- [Official Countly Repository](https://github.com/Countly/countly-server)
- [Countly Documentation](https://resources.count.ly/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Countly module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Countly API (`countly-api`) | Deployment | 13 points | ✅  |
| Countly Frontend (`countly-frontend`) | Deployment | 12 points | ✅  |
| MongoDB Database (`countly-mongodb`) | StatefulSet | 11 points | ✅ |
