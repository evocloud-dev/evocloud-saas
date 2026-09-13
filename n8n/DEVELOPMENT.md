# Development & Publishing Guide

This guide explains how to work with the CUE files in this module, how to publish it to a registry, and how to deploy it.

## 1. Local Development (From CUE Files)

### Validate Configuration
To ensure your `values.cue` and templates are correct:
```bash
timoni mod vet .
```

### Build (Generate Kubernetes YAML)
To see the rendered Kubernetes resources:
```bash
timoni build -n <namespace> <instance-name> .
```

### Test Apply
To apply directly from your local files:
```bash
timoni apply -n <namespace> <name> .
```

---

## 2. Publishing (Building an OCI Artifact)

### Login to Registry

#### For GitHub Container Registry (GHCR)
1. **Login via CLI**:
   ```bash
   echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u <username> --password-stdin
   ```

2. **Push the module to GHCR**:
   ```bash
   timoni mod push . oci://ghcr.io/<username>/modules/n8n --version <version>
   ```

### Offline / CI Workflow (Pre-built OCI Archive)
1. **Build the self-contained tarball:**
   ```bash
   timoni mod build . --version <version> --output ./builds/n8n-<version>.tar
   ```

2. **Push the pre-built tarball:**
   ```bash
   timoni mod push ./builds/n8n-<version>.tar oci://<registry-url>/<username>/n8n -v <version>
   ```

---

## 3. Deployment (From OCI Registry)

```bash
timoni apply -n <namespace> <instance-name> oci://<registry-url>/<username>/modules/n8n --version <version>
```

