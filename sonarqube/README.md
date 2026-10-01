# SonarQube

## Description
[SonarQube](https://www.sonarsource.com/products/sonarqube/) is an open-source static code analysis platform developed by SonarSource. It provides continuous inspection of code quality and security across multiple programming languages to detect bugs, code smells, and security vulnerabilities, enforcing Quality Gates across continuous integration and deployment pipelines.

## Application Information
- **Version:** `26.9.0.129388-community`
- **Official Website:** [https://www.sonarsource.com/products/sonarqube/](https://www.sonarsource.com/products/sonarqube/)
- **Upstream Project:** [https://github.com/SonarSource/sonarqube](https://github.com/SonarSource/sonarqube)
- **Container Base:**
  - SonarQube Server: [docker.io/library/sonarqube](https://hub.docker.com/_/sonarqube) (`docker.io/library/sonarqube:26.9.0.129388-community`)
  - PostgreSQL Database: [docker.io/library/postgres](https://hub.docker.com/_/postgres) (`docker.io/library/postgres:18.6-trixie`)
  - Init Containers / Utilities: [docker.io/library/busybox](https://hub.docker.com/_/busybox) (`docker.io/library/busybox:1.38`)
- **Deployment Type:** Timoni Module / Kubernetes Cloud-Native Workload

## Components
- **SonarQube Server (`sonarqube`):** Core application server (`Deployment/sona-sonarqube`) running `sonarqube:26.9.0.129388-community` on port 9000, managing static code analysis, the embedded search index, and the administration console.
- **PostgreSQL Database (`postgresql`):** Dedicated PostgreSQL 18 StatefulSet (`StatefulSet/sona-postgresql`) running `postgres:18.6-trixie` with persistent volume storage (`20Gi`), headless service, and automated secret credentials management.
- **SonarQube Service (`sonarqube`):** ClusterIP service exposing port 9000 for internal cluster communications, CI/CD runners, and reverse proxies.
- **PostgreSQL Services (`postgresql`, `postgresql-primary-headless`):** ClusterIP and headless services routing database traffic on port 5432.
- **Persistent Storage (`data`, `extensions`, `logs`, `standalone.persistence`):** Dedicated PersistentVolumeClaims for SonarQube data (`10Gi`), extensions & plugins (`5Gi`), server logs (`5Gi`), and PostgreSQL data directory (`20Gi`).
- **Init Containers:**
  - `wait-for-database`: Polls PostgreSQL TCP connectivity to ensure the database is fully reachable before launching SonarQube.
  - `plugins`: Automatically downloads custom and community plugins into `/opt/sonarqube/extensions/plugins`.
  - `communityBranchPlugin`: Installs and configures the SonarQube Community Branch Plugin to support branching and pull request analysis.
- **Gateway API HTTPRoute (Optional):** Optional Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) for modern Kubernetes Gateway routing.
- **NetworkPolicy (Optional):** Fine-grained Kubernetes network policies controlling ingress and egress network access.
- **Pod Disruption Budget (`pdb`):** Ensures high availability during node drain and cluster upgrades.
- **ServiceAccount (`serviceAccount`):** Dedicated unprivileged Kubernetes ServiceAccount with `automountServiceAccountToken: false`.

## Prerequisites
- Kubernetes cluster v1.20+ (recommended v1.26+)
- [Timoni CLI](https://timoni.sh) v0.17+ installed locally
- Default StorageClass supporting `ReadWriteOnce` access mode

## Install

To create an instance using default values:

```shell
timoni -n default apply sona ./sonarqube
```

To deploy with customized values, create a `my-values.cue` file:

```cue
package main

values: {
	resources: {
		requests: {
			cpu:    "1"
			memory: "3Gi"
		}
		limits: {
			cpu:    "2"
			memory: "4Gi"
		}
	}
	sonarqube: {
		webJavaOpts:    "-Xms512m -Xmx1024m"
		ceJavaOpts:     "-Xms512m -Xmx1024m"
		searchJavaOpts: "-Xms1024m -Xmx1024m"
	}
	postgresql: {
		enabled: true
		standalone: {
			persistence: {
				size: "30Gi"
			}
		}
	}
}
```

Apply the values to the instance:

```shell
timoni -n default apply sona ./sonarqube \
  --values ./my-values.cue
```

## Uninstall

To uninstall the instance and remove all associated Kubernetes resources:

```shell
timoni -n default delete sona
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image.repository` | string | `docker.io/library/sonarqube` | Container image repository for SonarQube |
| `image.tag` | string | `26.9.0.129388-community` | Pinned container image tag for SonarQube |
| `image.pullPolicy` | string | `IfNotPresent` | Kubernetes image pull policy |
| `containerPorts.http` | int | `9000` | HTTP container listening port |
| `service.port` | int | `9000` | Kubernetes Service port |
| `sonarqube.databaseMode` | string | `auto` | Database mode (`auto`, `embedded`, `external`, `postgresql`) |
| `sonarqube.webJavaOpts` | string | `-Xms256m -Xmx512m` | JVM options for the web process |
| `sonarqube.ceJavaOpts` | string | `-Xms256m -Xmx512m` | JVM options for the compute engine process |
| `sonarqube.searchJavaOpts` | string | `-Xms512m -Xmx512m` | JVM options for the search engine |
| `resources` | object | `{requests: {cpu: "500m", memory: "2Gi"}, limits: {cpu: "2", memory: "3Gi"}}` | Container resource requests and limits for SonarQube |
| `postgresql.enabled` | bool | `true` | Deploy internal PostgreSQL database subchart |
| `postgresql.image.repository` | string | `docker.io/library/postgres` | Container image repository for PostgreSQL |
| `postgresql.image.tag` | string | `18.6-trixie` | Container image tag for PostgreSQL |
| `postgresql.auth.database` | string | `sonarqube` | Database name created on initialization |
| `postgresql.auth.username` | string | `sonar` | Database username for SonarQube connectivity |
| `postgresql.standalone.persistence.size` | string | `20Gi` | Storage capacity allocated for PostgreSQL data |
| `postgresql.resources` | object | `{requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "512Mi"}}` | Container resource requests and limits for PostgreSQL |
| `communityBranchPlugin.enabled` | bool | `true` | Enable SonarQube Community Branch Plugin |
| `communityBranchPlugin.version` | string | `26.5.0` | Community Branch Plugin release version |
| `plugins.enabled` | bool | `true` | Enable automated plugin downloads |
| `persistence.data.size` | string | `10Gi` | Persistent storage capacity for `/opt/sonarqube/data` |
| `persistence.extensions.size` | string | `5Gi` | Persistent storage capacity for `/opt/sonarqube/extensions` |
| `persistence.logs.size` | string | `5Gi` | Persistent storage capacity for `/opt/sonarqube/logs` |
| `pdb.enabled` | bool | `true` | Enable PodDisruptionBudget for high availability |

### Recommended values

Comply with the restricted Kubernetes pod security standard:

```cue
values: {
	podSecurityContext: {
		fsGroup: 1000
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: drop: ["ALL"]
	}
}
```

## Additional Resources
- [Official SonarQube Website](https://www.sonarsource.com/products/sonarqube/)
- [Official SonarQube Repository](https://github.com/SonarSource/sonarqube)
- [SonarQube Documentation](https://docs.sonarsource.com/sonarqube-community-build/)
- [Timoni Documentation](https://timoni.sh)

## Kubesec Scan Scores

Security validation performed via [Kubesec](https://kubesec.io) static analysis across the SonarQube module workloads:

| Workload | Kind | Kubesec Score | Status |
|---|---|---|---|
| SonarQube Server (`sona-sonarqube`) | Deployment | 12 points | ✅ |
| PostgreSQL Database (`sona-postgresql`) | StatefulSet | 15 points | ✅ |
