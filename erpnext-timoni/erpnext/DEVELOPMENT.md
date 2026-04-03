# Development & Publishing Guide

This guide explains how to work with the CUE files in this module, how to publish it to a registry, and how to deploy it.

## 1. Local Development (From CUE Files)

### Validate Configuration
To ensure your `values.cue` and templates are correct:
```bash
timoni mod vet .
```

### Build (Generate Kubernetes YAML)
If you want to see the "built" Kubernetes resources without applying them:
```bash
timoni build -n <namespace> <instance-name> .
```
*Note: This "builds" the YAML from your CUE files.*

### Test Apply
To apply directly from your local files:
```bash
timoni apply -n <namespace> <name> .  
```

---

## 2. Publishing (Building an OCI Artifact)

"Building an OCI artifact" means packaging your CUE files into a versioned image that lives in a container registry.

### Login to Registry

#### For GitHub Container Registry (GHCR)
1.  **Generate a Token**: Go to GitHub **Settings** -> **Developer settings** -> **Personal access tokens** (Tokens classic).
2.  **Permissions**: Select `write:packages` and `read:packages`.
3.  **Login via CLI**:
    ```bash
    echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u <username> --password-stdin
    ```

4. **Push the module to GHCR**:
    ```bash
    timoni mod push . oci://ghcr.io/<username>/modules/<app-name> --version <version>
    ```

#### For Docker Hub (Docker.io)
Docker Hub typically uses your standard password or a Personal Access Token:
1. **Login to docker registry**:
   ```bash
   docker login docker.io -u <username>
   ```
2. **Push the module to Docker Hub**:
This command **builds** the artifact from your files and **pushes** it in one step:
```bash
timoni mod push . oci://<registry-url>/<username>/erpnext-timoni --version <version>
```

---

## 3. Deployment (From OCI Registry)

Once published, anyone can deploy the module without needing the source files:

```bash
timoni apply -n <namespace>  <instance-name> oci://<registry-url>/<username>/modules/<app-name> --version <version> .
```

## 4. Pull (From OCI Registry)
From GHCR Registry
timoni mod pull oci://<registry-url>/<org-name>/modules/<app-name> --version 0.1.0 -o .

From Docker Registry
timoni mod  pull oci://<registry-url>/<org-name>/<app-name> --version 0.1.0 -o .



