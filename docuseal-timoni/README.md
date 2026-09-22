# DocuSeal

## Description
[DocuSeal](https://www.docuseal.com/) is an open-source platform for digital document signing and automated processing workflows. It provides an intuitive web interface and API for creating, sending, filling, and signing PDF documents online as an open-source alternative to DocuSign and PandaDoc.

## Application Information
- **Version:** 3.2.3
- **Upstream Project:** [https://github.com/docusealco/docuseal](https://github.com/docusealco/docuseal)
- **Container Base:** [docker.io/docuseal/docuseal](https://hub.docker.com/r/docuseal/docuseal) (`docker.io/docuseal/docuseal:3.2.3`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **DocuSeal Application (`docuseal`):** Core web server and document engine running `docker.io/docuseal/docuseal:3.2.3` on container port 3000 handling document generation, email delivery, and electronic signatures.
- **Kubernetes Service (`svc`):** ClusterIP service routing HTTP traffic to container port 3000.
- **Persistent Storage (`pvc`):** PersistentVolumeClaim mounted to `/data` preserving PDF documents, signing assets, cryptographic keys, and SQLite database files across pod restarts.
- **Ingress (`ingress`):** Optional Kubernetes Ingress resource for routing external traffic and configuring TLS termination.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally

## Install

To create an instance using default values:

```shell
timoni -n default apply docuseal ./docuseal-timoni
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	resources: {
		requests: {
			cpu:    "200m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
	}
	persistence: {
		data: {
			enabled:   true
			mountPath: "/data"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply docuseal ./docuseal-timoni \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all created Kubernetes resources:

```shell
timoni -n default delete docuseal
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docuseal/docuseal` | Container image repository for DocuSeal |
| `image.tag` | string | `3.2.3` | Pinned container image tag for DocuSeal |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `service.main.ports.http.port` | int | `3000` | Kubernetes Service HTTP port |
| `ingress.main.enabled` | bool | `false` | Enable Kubernetes Ingress resource |
| `persistence.data.enabled` | bool | `true` | Persist application data with a PersistentVolumeClaim |
| `persistence.data.mountPath` | string | `/data` | Container path for document and database persistence |
| `resources.requests` | object | `{cpu: "200m", memory: "256Mi"}` | Minimum compute resource requests |
| `resources.limits` | object | `{cpu: "500m", memory: "512Mi"}` | Maximum compute resource limits |

### Recommended values

Comply with the restricted Kubernetes pod security standard:

```cue
values: {
	securityContext: {
		runAsUser:              1000
		runAsGroup:             1000
		fsGroup:                1000
		runAsNonRoot:           true
		readOnlyRootFilesystem: true
		capabilities: {
			drop: ["ALL"]
		}
	}
}
```

## Additional Resources
- [Official DocuSeal Website](https://www.docuseal.com/)
- [Official DocuSeal Repository](https://github.com/docusealco/docuseal)
- [DocuSeal Documentation](https://www.docuseal.com/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the DocuSeal module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| DocuSeal Core Application (`docuseal`) | Deployment | 11 points | ✅  |
