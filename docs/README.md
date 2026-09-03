# docs — Timoni Module

A [timoni.sh](http://timoni.sh) module for deploying [Docs](https://github.com/suitenumerique/docs)
(also known as **Impress**) to Kubernetes.

---

## Prerequisites

### Cluster requirements

| Requirement | Notes |
|---|---|
| Kubernetes ≥ 1.20 | |
| `ingress-nginx` installed | Module uses `ingressClassName: nginx` by default |
| `mkcert` (local dev only) | For self-signed TLS on `*.127.0.0.1.nip.io` |

### Required namespace resources

Before running `timoni apply`, the following resources **must exist** in the target namespace:

| Kind | Name | Purpose |
|---|---|---|
| `ConfigMap` | `certifi` | Bundled CA certificates (Python `certifi` + your local CA). Mounted into the backend pod so Django can verify HTTPS calls to Keycloak. |
| `Secret` | `mkcert` | Your `mkcert` root CA. Used by the ingress controller as the default TLS certificate. |

---

## Option A — Full local setup (recommended for new environments)

If you are starting from scratch, use the official bootstrap script from the Docs project.
It creates a Kind cluster, configures CoreDNS, installs `ingress-nginx`, and provisions
all required secrets and configmaps automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/numerique-gouv/tools/main/kind/create_cluster.sh | sh -s -- docs
```

> The script accepts two arguments: `APPLICATION` (namespace name, default `app`) and
> `CLUSTERNAME` (kind cluster name, default `suite`).
> Pass `docs` as the application name to match this module's defaults.

Once the script completes, skip to [Deploy](#deploy).

---

## Option B — Existing cluster

If you already have a Kubernetes cluster and ingress controller, you only need to provision
the certificate resources. These are the relevant steps extracted from the bootstrap script:

### 1. Install mkcert and generate a wildcard certificate

```bash
mkcert -install
cd /tmp
mkcert "127.0.0.1.nip.io" "*.127.0.0.1.nip.io"
```

### 2. Install ingress-nginx controller (if not already installed)

```bash
# Add Helm repo and install ingress-nginx (disabling admission webhooks for fast local setup)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.admissionWebhooks.enabled=false
```

### 3. Configure ingress-nginx to use the mkcert certificate as default TLS

```bash
# Create or update the TLS secret in the ingress-nginx namespace
kubectl -n ingress-nginx create secret tls mkcert \
  --key /tmp/127.0.0.1.nip.io+1-key.pem \
  --cert /tmp/127.0.0.1.nip.io+1.pem \
  --dry-run=client -o yaml | kubectl apply -f -

# Patch the controller deployment to use the cert as default SSL
kubectl -n ingress-nginx patch deployments.apps ingress-nginx-controller \
  --type json -p '[
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--default-ssl-certificate=ingress-nginx/mkcert"}
  ]'
```

### 3. Create the target namespace

```bash
kubectl create ns docs
kubectl config set-context --current --namespace=docs
```

### 4. Create the `mkcert` secret in the namespace

```bash
kubectl -n docs create secret generic mkcert \
  --from-file=rootCA.pem="$(mkcert -CAROOT)/rootCA.pem"
```

### 5. Create the `certifi` ConfigMap and Secret

The `certifi` ConfigMap bundles the standard Python CA bundle with your local `mkcert` root CA.
This allows the Django backend to verify TLS connections to Keycloak (which uses a self-signed cert).

```bash
# Download the standard certifi CA bundle
curl https://raw.githubusercontent.com/certifi/python-certifi/refs/heads/master/certifi/cacert.pem \
  -o /tmp/cacert.pem

# Append your local mkcert root CA to it
cat "$(mkcert -CAROOT)/rootCA.pem" >> /tmp/cacert.pem

# Create the ConfigMap (mounted into the backend pod at /cert/cacert.pem)
kubectl -n docs create configmap certifi \
  --from-file=cacert.pem=/tmp/cacert.pem

# Create the Secret (used by other tools that expect a secret)
kubectl -n docs create secret generic certifi \
  --from-file=/tmp/cacert.pem
```

---

## Deploy

Apply the module from the local directory (development):

```bash
timoni apply -n docs docs . 
```

---

## Uninstall

```bash
timoni -n docs delete docs
```