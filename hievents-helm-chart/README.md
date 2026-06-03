# Hi.Events Helm Chart

This repository contains a Helm chart for running Hi.Events on Kubernetes.

The chart deploys:

- Laravel backend `Deployment` and `Service`
- Frontend `Deployment` and `Service`
- Web proxy `Deployment` and `Service` for one-origin browser access
- Queue worker `Deployment`
- Laravel scheduler `CronJob`
- Migration `Job`, optionally as a Helm hook
- Optional bundled PostgreSQL `StatefulSet`
- Optional bundled Redis `StatefulSet`
- S3/object storage environment wiring
- Optional local upload storage PVC for Laravel media files
- Optional Gateway API `HTTPRoute`
- Optional HPA, PDB, ServiceAccount, and NetworkPolicy resources
- Default resources, pod security context, and container security context for app workloads

## Prerequisites

- Kubernetes cluster
- Helm 3
- Backend and frontend images already built and pushed
- `APP_KEY`, database, Redis, and S3 credentials
- Gateway API installed if `httpRoute.enabled=true`
- StorageClass if bundled PostgreSQL/Redis persistence is enabled
- StorageClass if local upload storage is enabled

## Install

To install the chart:

1. Create the namespace:

```sh
kubectl create namespace hievents
```

2. Run `helm install`. Note that a plain install with the default `values.yaml` will fail because `APP_KEY`, database, Redis, and S3 credentials are required. Set them during installation:

```sh
helm install hievents ./charts/hievents -n hievents
```

## Upgrade

To apply changes or upgrade the release, run `helm upgrade`:

```sh
helm upgrade hievents ./charts/hievents -n hievents
```


## Validation

```sh
helm lint ./charts/hievents
helm template hievents ./charts/hievents
kubectl get pods,jobs,cronjobs,httproute -n hievents
```

## Resources And Security

Backend and frontend resources are enabled by default in `values.yaml`. Worker, scheduler, and migration resources are also set because they run the backend image.

Migration hooks are disabled by default. This matters for the bundled PostgreSQL/Redis mode because a `pre-install` hook runs before Helm creates the database service, leaving only the migration job running while it waits for dependencies. If you use external database and Redis services that already exist before the release, you can set `migration.useHelmHooks=true`.

The chart sets a conservative default `seccompProfile: RuntimeDefault` pod security context and `allowPrivilegeEscalation: false` container security context for backend/frontend. It does not force `runAsNonRoot` by default because the upstream backend Dockerfile starts as `USER root`, and the CSR frontend image uses the standard `nginx:alpine` image that binds port 80. If you build custom non-root images, override `podSecurityContext` and `securityContext` in your values file.

The default frontend `service.targetPort` is `5678`, matching the upstream SSR frontend image.

Backend and frontend probes use the named container port `http` by default. The backend default probe path is `/` because the pinned upstream Hi.Events release does not expose `/api/health`.

## Local Port-Forwarding

For browser testing, use the chart's web proxy service:

```sh
kubectl port-forward svc/hievents-service-nginx 8080:80 -n hievents
```

Then open:

```text
http://localhost:8080/auth/register
```

This mirrors the official all-in-one Docker routing. The browser uses one origin, `/api/*` is rewritten to the backend without the `/api` prefix, `/storage/*` is sent to the backend, and all other paths are sent to the frontend.
For local `APP_ENV=local` testing, nginx also rewrites the auth token cookie so it works over `http://localhost`.

Port-forwarding only the frontend service is not enough for registration unless you also provide an external API route that rewrites `/api/*` before it reaches Laravel.

## Local Upload Storage

Hi.Events can use S3-compatible object storage or Laravel local storage. For local storage, enable the backend PVC:

```yaml
hieventsConfig:
  storage:
    driver: local

backend:
  replicaCount: 1
  persistence:
    enabled: true
    size: 10Gi
    mountPath: /var/www/html/storage/app
```

The PVC template is `charts/hievents/templates/pvc.yaml`. It is rendered only when `hieventsConfig.storage.driver=local` and `backend.persistence.enabled=true`.

The PVC is mounted into backend, worker, and scheduler pods at `/var/www/html/storage/app`. That path covers Hi.Events' local private disk (`storage/app`) and public upload disk (`storage/app/public`). If you run multiple backend or worker replicas, use a `ReadWriteMany` capable storage class; otherwise keep the backend and worker on one writable volume topology or use S3.

