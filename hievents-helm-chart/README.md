# Hi.Events Helm Chart

## Description

[Hi.Events](https://hi.events/) is an open-source event management and ticket-selling platform designed as a modern, self-hosted alternative to platforms like Eventbrite. It provides complete control over event creation, attendee registration, ticket types, check-in processing, automated confirmation emails, and payment integrations.

## Application Information

- **Version:** 1.11.1-beta
- **Official Website:** [https://hi.events/](https://hi.events/)
- **Upstream Project:** [https://github.com/HiEventsDev/hi.events](https://github.com/HiEventsDev/hi.events)
- **Container Base:**
  - Backend / Worker: `docker.io/daveearley/hi.events-backend:v1.11.1-beta`
  - Frontend: `docker.io/daveearley/hi.events-frontend:v1.11.1-beta`
  - Web Proxy: `docker.io/nginx:1.30-alpine`
  - PostgreSQL: `docker.io/postgres:18-alpine`
  - Valkey / Redis: `docker.io/valkey/valkey:9.1.2-alpine`
- **Deployment Type:** Helm Chart / Kubernetes Cloud-Native Workload

## Components

- **Hi.Events Backend (`hievents-backend`):** Core Laravel API service processing business logic, authentication, event schemas, ticket operations, and webhooks on container port `8080`.
- **Hi.Events Frontend (`hievents-frontend`):** Web client dashboard providing attendee registration and organizer management on container port `5678`.
- **NGINX Reverse Proxy (`hievents-deployment-nginx`):** Reverse proxy unifying frontend and backend routing into a single public interface on port `80` (container port `8080`).
- **Queue Worker (`hievents-worker`):** Asynchronous background queue worker processing asynchronous jobs (emails, webhooks, order transactions, ticket generation).
- **PostgreSQL Database (`hievents-postgresql`):** Dedicated relational database StatefulSet storing application data, attendee records, and transactional history.
- **Valkey / Redis In-Memory Store (`hievents-redis`):** High-performance caching layer and queue broker StatefulSet managing sessions and background tasks.
- **Database Migration Job (`hievents-migration`):** Automated database schema migration job executed during chart deployment.
- **Task Scheduler CronJob (`hievents-scheduler`):** Periodic Laravel scheduler CronJob running automated event maintenance and scheduled tasks.
- **Gateway API HTTPRoute (`hievents`):** Native `gateway.networking.k8s.io/v1` HTTPRoute resource for modern cluster ingress routing.
- **Persistent Volume Claims (`pvc`):** Dedicated storage claims for persistent uploads (`/var/www/html/storage/app`) and database persistence.
- **ServiceAccount (`hievents`):** Dedicated unprivileged Kubernetes ServiceAccount applied across Hi.Events workloads with `automountServiceAccountToken: false`.

## Prerequisites

- Kubernetes cluster v1.26+
- Helm v3.10+ installed locally
- Storage provisioner supporting dynamic `ReadWriteOnce` persistent volumes
- Optional: Kubernetes Gateway API controller (Envoy Gateway, Traefik, Cilium, etc.)

## Install

To install the chart using default values:

```bash
helm install hievents ./charts/hievents -n default --create-namespace
```

To deploy with customized values, create a `my-values.yaml` file:

```yaml
hieventsConfig:
  app:
    url: "https://events.example.com"
    frontendUrl: "https://events.example.com"

backend:
  replicaCount: 2
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"

postgresql:
  persistence:
    size: "20Gi"
```

Apply the custom values during installation:

```bash
helm install hievents ./charts/hievents -n default \
  -f ./my-values.yaml
```

## Upgrade

To apply changes or upgrade the release:

```bash
helm upgrade hievents ./charts/hievents -n default \
  -f ./my-values.yaml
```

## Uninstall

To uninstall the release and remove all its workloads:

```bash
helm uninstall hievents -n default
```

## Configuration

### Key Configuration Parameters

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `hieventsConfig.app.name` | `string` | `"Hi.Events"` | Application display name |
| `hieventsConfig.app.url` | `string` | `"http://localhost:8080"` | Base URL for API endpoints |
| `hieventsConfig.app.frontendUrl` | `string` | `"http://localhost:8080"` | Base URL for frontend interface |
| `backend.image.repository` | `string` | `"daveearley/hi.events-backend"` | Backend container image repository |
| `backend.image.tag` | `string` | `"v1.11.1-beta"` | Backend container image tag |
| `backend.replicaCount` | `int` | `2` | Number of backend API replicas |
| `frontend.image.repository` | `string` | `"daveearley/hi.events-frontend"` | Frontend container image repository |
| `frontend.image.tag` | `string` | `"v1.11.1-beta"` | Frontend container image tag |
| `frontend.replicaCount` | `int` | `2` | Number of frontend replicas |
| `webProxy.image.repository` | `string` | `"nginx"` | Reverse proxy image repository |
| `webProxy.image.tag` | `string` | `"1.30-alpine"` | Reverse proxy image tag |
| `postgresql.enabled` | `bool` | `true` | Deploy internal PostgreSQL StatefulSet |
| `postgresql.image.tag` | `string` | `"18-alpine"` | PostgreSQL image tag |
| `postgresql.persistence.size` | `string` | `"10Gi"` | Persistent storage size for database |
| `redis.enabled` | `bool` | `true` | Deploy internal Valkey/Redis StatefulSet |
| `redis.image.tag` | `string` | `"9.1.2-alpine"` | Valkey/Redis image tag |
| `serviceAccount.create` | `bool` | `true` | Create dedicated ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Disable API token automounting |

### Recommended values

Comply with the restricted [Kubernetes pod security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/):

```yaml
podSecurityContext:
  runAsUser: 10001
  runAsGroup: 10001
  fsGroup: 10001
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

---

## Additional Resources

- [Official Hi.Events Website](https://hi.events/)
- [Official Hi.Events Repository](https://github.com/HiEventsDev/hi.events)
- [Hi.Events Documentation](https://hi.events/docs)
- [Helm Documentation](https://helm.sh/docs/)

---

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Hi.Events Helm chart workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|:---:|:---:|
| **Hi.Events Backend (`hievents-backend`)** | `Deployment` | **13 points** | ✅ |
| **Hi.Events Frontend (`hievents-frontend`)** | `Deployment` | **13 points** | ✅ |
| **NGINX Reverse Proxy (`hievents-deployment-nginx`)** | `Deployment` | **13 points** | ✅ |
| **Hi.Events Worker (`hievents-worker`)** | `Deployment` | **13 points** | ✅ |
| **PostgreSQL Database (`hievents-postgresql`)** | `StatefulSet` | **15 points** | ✅ |
| **Valkey / Redis Broker (`hievents-redis`)** | `StatefulSet` | **15 points** | ✅ |
