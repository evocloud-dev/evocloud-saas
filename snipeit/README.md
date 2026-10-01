# Snipe-IT

## Description
[Snipe-IT](https://snipeitapp.com/) is an open-source, web-based IT asset management system designed for tracking computer hardware, software licenses, accessories, and consumables. Built on Laravel and PHP, Snipe-IT features QR and barcode label generation, employee check-in and check-out workflows, automated email alerts for expiring warranties and licenses, audit logging, and reporting tools.

## Application Information
- **Version:** `v8.7.2`
- **Official Website:** [https://snipeitapp.com/](https://snipeitapp.com/)
- **Upstream Project:** [https://github.com/snipe/snipe-it](https://github.com/snipe/snipe-it)
- **Container Base:**
  - Snipe-IT App: [docker.io/snipe/snipe-it](https://hub.docker.com/r/snipe/snipe-it) (`snipe/snipe-it:v8.7.2`)
  - MySQL Database: [docker.io/library/mysql](https://hub.docker.com/_/mysql) (`mysql:9.7.2`)
  - MySQL Backup (optional): `quay.io/yeebase/mysql-client:gcloud-sdk`
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **Snipe-IT Application (`snipeit`):** Core asset management web application (`Deployment/snipeit`) running `snipe/snipe-it:v8.7.2` on internal port 8080. Includes an unprivileged init container that configures Apache to listen on port 8080 and sets up environment shims.
- **MySQL Database (`snipeit-mysql`):** Dedicated relational database deployment (`Deployment/snipeit-mysql`) running `mysql:9.7.2` with persistent storage (`8Gi`), initialization hooks, and credentials management.
- **Snipe-IT Service (`snipeit`):** ClusterIP service exposing port 80 (routing to container port 8080) for internal access and ingress routing.
- **MySQL Service (`snipeit-mysql`):** ClusterIP service exposing port 3306 for internal database connections.
- **Persistent Storage (`pvc`, `mysql-pvc`):** PersistentVolumeClaims provisioning dedicated storage for uploaded assets (`/var/lib/snipeit`), web sessions (`/var/www/html/storage/framework/sessions`), and MySQL database records (`/var/lib/mysql`).
- **Ingress (`snipeit`):** Kubernetes Ingress controller routing external HTTP/HTTPS traffic to the Snipe-IT web service.
- **Pod Disruption Budget (`snipeit`):** High availability PDB ensuring minimal disruption during cluster upgrades and maintenance.
- **MySQL Backup Job / CronJob (Optional):** Optional automated backup and restore jobs supporting Google Cloud Storage (GCS) integration.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply snipeit ./snipeit
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	config: {
		snipeit: {
			url: "https://assets.example.com"
			key: "base64:YOUR_GENERATED_APP_KEY_HERE"
			timezone: "UTC"
		}
	}
	resources: {
		requests: {
			cpu:    "200m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1Gi"
		}
	}
	mysql: {
		enabled: true
		mysqlPassword: "StrongPassword123!"
		persistence: {
			size: "10Gi"
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply snipeit ./snipeit \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete snipeit
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `snipe/snipe-it` | Container image repository for Snipe-IT |
| `image.tag` | string | `v8.7.2` | Pinned container image tag for Snipe-IT |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `config.snipeit.env` | string | `production` | Application runtime environment (`production` or `development`) |
| `config.snipeit.url` | string | `http://localhost:8080` | External URL used for accessing the Snipe-IT application |
| `config.snipeit.key` | string | `base64:...` | Base64-encoded application cryptographic key |
| `config.snipeit.timezone` | string | `Europe/Berlin` | System timezone for timestamps and scheduling |
| `config.snipeit.locale` | string | `en` | Default UI language locale |
| `resources` | object | `{requests: {cpu: "100m", memory: "128Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Container resource requests and limits for Snipe-IT |
| `mysql.enabled` | bool | `true` | Deploy internal MySQL database deployment |
| `mysql.image` | string | `mysql` | Container image repository for MySQL |
| `mysql.imageTag` | string | `9.7.2` | Container image tag for MySQL |
| `mysql.mysqlDatabase` | string | `db-snipeit` | Name of the default database created on initialization |
| `mysql.mysqlUser` | string | `snipeit` | Database username for Snipe-IT connectivity |
| `mysql.persistence.size` | string | `8Gi` | Storage capacity allocated for MySQL data |
| `mysql.resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "1000m", memory: "1024Mi"}}` | Container resource requests and limits for MySQL |
| `persistence.enabled` | bool | `true` | Enable persistent storage for Snipe-IT app data and sessions |
| `persistence.size` | string | `2Gi` | Storage capacity allocated for Snipe-IT volume claims |
| `ingress.enabled` | bool | `true` | Enable Kubernetes Ingress for external traffic |
| `ingress.hosts` | list | `["example.local"]` | Ingress hostname routing list |
| `pdb.enabled` | bool | `true` | Enable PodDisruptionBudget for high availability |

### Recommended values

Comply with the restricted Kubernetes pod security standard:

```cue
values: {
	podSecurityContext: {
		runAsUser:  10000
		runAsGroup: 50
		fsGroup:    50
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
- [Official Snipe-IT Website](https://snipeitapp.com/)
- [Official Snipe-IT Repository](https://github.com/snipe/snipe-it)
- [Snipe-IT Documentation](https://snipe-it.readme.io/docs)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the Snipe-IT module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| Snipe-IT Application (`snipeit`) | Deployment | 11 points | ✅ |
| MySQL Database (`snipeit-mysql`) | Deployment | 11 points | ✅ |
