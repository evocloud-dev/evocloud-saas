package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	replicaCount: *1 | int
	nameOverride: *"" | string
	fullnameOverride: *"" | string
	commonLabels: {[string]: string}
	clusterDomain: *"cluster.local" | string

	image: timoniv1.#Image & {
		repository: *"docker.io/library/sonarqube" | string
		tag:        *"26.4.0.121862-community" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	containerPorts: {
		http: *9000 | int
	}

	service: {
		type:            *"ClusterIP" | "NodePort" | "LoadBalancer" | string
		annotations:     {[string]: string}
		port:            *9000 | int
		ipFamilyPolicy?: null | string
		ipFamilies?:     [...string]
	}

	serviceAccount: {
		create:                       *false | bool
		name:                         *"" | string
		annotations:                  {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	sonarqube: {
		databaseMode:                         *"auto" | "embedded" | "external" | "postgresql"
		context:                              *"" | string
		webJavaOpts:                          *"-Xms256m -Xmx512m" | string
		ceJavaOpts:                           *"-Xms256m -Xmx512m" | string
		searchJavaOpts:                       *"-Xms512m -Xmx512m" | string
		esBootstrapChecksDisable:             *true | bool
		monitoringPasscode:                   *"" | string
		existingMonitoringPasscodeSecret:     *"" | string
		existingMonitoringPasscodeSecretKey:  *"monitoring-passcode" | string
		extraEnv:                             *[] | [...corev1.#EnvVar]
		extraEnvFrom:                         *[] | [...corev1.#EnvFromSource]
		sonarProperties:                      {[string]: string}
	}

	database: {
		external: {
			jdbcUrl:                   *"" | string
			username:                  *"sonar" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"jdbc-password" | string
		}
	}

	postgresql: {
		enabled:          *false | bool
		architecture:     *"standalone" | string
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		auth: {
			database:                      *"sonarqube" | string
			username:                      *"sonar" | string
			password:                      *"" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"" | string
		}
		standalone: {
			persistence: {
				enabled:      *true | bool
				storageClass: *"" | string
				accessModes:  *["ReadWriteOnce"] | [...string]
				size:         *"20Gi" | string
			}
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.4-trixie" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		resources?:          corev1.#ResourceRequirements
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"1h" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | string
		}
		target: {
			creationPolicy: *"Owner" | string
		}
		database: {
			enabled: *false | bool
			targetName: *"" | string
			passwordRemoteRef: {
				key:                 *"" | string
				property?:           string
				version?:            string
				decodingStrategy?:   string
				conversionStrategy?: string
			}
		}
		monitoringPasscode: {
			enabled: *false | bool
			targetName: *"" | string
			remoteRef: {
				key:                 *"" | string
				property?:           string
				version?:            string
				decodingStrategy?:   string
				conversionStrategy?: string
			}
		}
	}

	plugins: {
		enabled: *false | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"10m" | string
				memory: *"32Mi" | string
			}
			limits: {
				cpu:    *"200m" | string
				memory: *"128Mi" | string
			}
		}
		install: *[] | [...{
			name: string
			url:  string
		}]
	}

	communityBranchPlugin: {
		enabled:   *false | bool
		version:   *"26.4.0" | string
		jarUrl:    *"" | string
		webappUrl: *"" | string
	}

	waitForDatabase: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		timeoutSeconds: *180 | int
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"10m" | string
				memory: *"16Mi" | string
			}
			limits: {
				cpu:    *"100m" | string
				memory: *"64Mi" | string
			}
		}
	}

	persistence: {
		data: {
			enabled:       *true | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
			size:          *"10Gi" | string
		}
		extensions: {
			enabled:       *true | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
			size:          *"5Gi" | string
		}
		logs: {
			enabled:       *false | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
			size:          *"5Gi" | string
		}
	}

	gatewayAPI: {
		enabled:    *false | bool
		apiVersion: *"gateway.networking.k8s.io/v1" | string
		annotations: {[string]: string}
		parentRefs: *[] | [...{
			group?:       string
			kind?:        string
			name:         string
			namespace?:   string
			sectionName?: string
			port?:        int
		}]
		hostnames: *[] | [...string]
		matches: *[{
			path: {
				type:  *"PathPrefix" | string
				value: *"/" | string
			}
		}] | [...{
			path?: {
				type:  string
				value: string
			}
			headers?: [...{
				name:  string
				value: string
				type?: string
			}]
			queryParams?: [...{
				name:  string
				value: string
				type?: string
			}]
			method?: string
		}]
		filters: *[] | [...{...}]
	}

	networkPolicy: {
		enabled: *false | bool
		ingress: {
			allowSameNamespace: *true | bool
			extraFrom:          *[] | [...{...}]
		}
		egress: {
			enabled:         *false | bool
			allowDNS:        *true | bool
			allowHTTP:       *true | bool
			allowHTTPS:      *true | bool
			allowPostgreSQL: *true | bool
			postgresqlPort:  *5432 | int
			extraTo:         *[] | [...{...}]
			extraEgress:     *[] | [...{...}]
		}
	}

	resources: corev1.#ResourceRequirements & {
		requests: {
			cpu:    *"500m" | string
			memory: *"2Gi" | string
		}
		limits: {
			cpu:    *"2" | string
			memory: *"3Gi" | string
		}
	}

	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext

	startupProbe: {
		enabled:             *true | bool
		path:                *"/api/system/status" | string
		initialDelaySeconds: *30 | int
		periodSeconds:       *15 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *80 | int
	}

	livenessProbe: {
		enabled:             *true | bool
		path:                *"/api/system/status" | string
		initialDelaySeconds: *180 | int
		periodSeconds:       *30 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *6 | int
	}

	readinessProbe: {
		enabled:             *true | bool
		path:                *"/api/system/status" | string
		initialDelaySeconds: *60 | int
		periodSeconds:       *15 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *20 | int
	}

	pdb: {
		enabled:      *false | bool
		minAvailable: *1 | int
	}

	podLabels:                 {[string]: string}
	podAnnotations:            {[string]: string}
	annotations:               {[string]: string}
	nodeSelector:              {[string]: string}
	tolerations?:              [...corev1.#Toleration]
	affinity?:                 corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *120 | int

	extraInitContainers: *[] | [...corev1.#Container]
	extraContainers:     *[] | [...corev1.#Container]
	extraVolumes:        *[] | [...corev1.#Volume]
	extraVolumeMounts:   *[] | [...corev1.#VolumeMount]
	extraManifests:      *[] | [...{...}]

	tests: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"10m" | string
				memory: *"16Mi" | string
			}
			limits: {
				cpu:    *"100m" | string
				memory: *"64Mi" | string
			}
		}
	}

	// Computed helper fields (mirroring Helm template helpers)
	fullname: [
		if fullnameOverride != "" {
			fullnameOverride
		},
		if fullnameOverride == "" {
			if nameOverride != "" {
				"\(metadata.name)-\(nameOverride)"
			}
			if nameOverride == "" {
				"\(metadata.name)-sonarqube"
			}
		},
	][0]

	databaseMode: [
		if sonarqube.databaseMode == "auto" {
			if database.external.jdbcUrl != "" || database.external.existingSecret != "" || (externalSecrets.enabled && externalSecrets.database.enabled) || database.external.password != "" {
				"external"
			}
			if !(database.external.jdbcUrl != "" || database.external.existingSecret != "" || (externalSecrets.enabled && externalSecrets.database.enabled) || database.external.password != "") {
				if postgresql.enabled {
					"postgresql"
				}
				if !postgresql.enabled {
					"embedded"
				}
			}
		},
		sonarqube.databaseMode,
	][0]

	postgresqlFullname: [
		if postgresql.fullnameOverride != "" {
			postgresql.fullnameOverride
		},
		if postgresql.fullnameOverride == "" {
			if postgresql.nameOverride != "" {
				"\(metadata.name)-\(postgresql.nameOverride)"
			}
			if postgresql.nameOverride == "" {
				"\(metadata.name)-postgresql"
			}
		},
	][0]

	postgresqlHost: "\(postgresqlFullname).\(metadata.namespace).svc.\(clusterDomain)"
	postgresqlPort: 5432

	postgresqlJdbcUrl: "jdbc:postgresql://\(postgresqlHost):\(postgresqlPort)/\(postgresql.auth.database)"

	databaseSecretName: [
		if databaseMode == "postgresql" {
			if postgresql.auth.existingSecret != "" {
				postgresql.auth.existingSecret
			}
			if postgresql.auth.existingSecret == "" {
				"\(postgresqlFullname)-auth"
			}
		},
		if databaseMode != "postgresql" {
			if externalSecrets.enabled && externalSecrets.database.enabled {
				if externalSecrets.database.targetName != "" {
					externalSecrets.database.targetName
				}
				if externalSecrets.database.targetName == "" {
					"\(fullname)-database"
				}
			}
			if !(externalSecrets.enabled && externalSecrets.database.enabled) {
				if database.external.existingSecret != "" {
					database.external.existingSecret
				}
				if database.external.existingSecret == "" {
					"\(fullname)-secrets"
				}
			}
		},
	][0]

	databaseSecretKey: [
		if databaseMode == "postgresql" {
			if postgresql.auth.existingSecretUserPasswordKey != "" {
				postgresql.auth.existingSecretUserPasswordKey
			}
			if postgresql.auth.existingSecretUserPasswordKey == "" {
				"user-password"
			}
		},
		if databaseMode != "postgresql" {
			database.external.existingSecretPasswordKey
		},
	][0]

	monitoringSecretName: [
		if externalSecrets.enabled && externalSecrets.monitoringPasscode.enabled {
			if externalSecrets.monitoringPasscode.targetName != "" {
				externalSecrets.monitoringPasscode.targetName
			}
			if externalSecrets.monitoringPasscode.targetName == "" {
				"\(fullname)-monitoring"
			}
		},
		if !(externalSecrets.enabled && externalSecrets.monitoringPasscode.enabled) {
			if sonarqube.existingMonitoringPasscodeSecret != "" {
				sonarqube.existingMonitoringPasscodeSecret
			}
			if sonarqube.existingMonitoringPasscodeSecret == "" {
				"\(fullname)-secrets"
			}
		},
	][0]

	monitoringSecretKey: sonarqube.existingMonitoringPasscodeSecretKey

	communityBranchJarName: "sonarqube-community-branch-plugin-\(communityBranchPlugin.version).jar"

	communityBranchJarUrl: [
		if communityBranchPlugin.jarUrl != "" {
			communityBranchPlugin.jarUrl
		},
		if communityBranchPlugin.jarUrl == "" {
			"https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/\(communityBranchPlugin.version)/sonarqube-community-branch-plugin-\(communityBranchPlugin.version).jar"
		},
	][0]

	communityBranchWebappUrl: [
		if communityBranchPlugin.webappUrl != "" {
			communityBranchPlugin.webappUrl
		},
		if communityBranchPlugin.webappUrl == "" {
			"https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/\(communityBranchPlugin.version)/sonarqube-webapp.zip"
		},
	][0]

	_contextPath: [
		if sonarqube.context != "" {
			sonarqube.context
		},
		if sonarqube.context == "" {
			""
		},
	][0]

	startupProbePath:   "\(_contextPath)\(startupProbe.path)"
	livenessProbePath:  "\(_contextPath)\(livenessProbe.path)"
	readinessProbePath: "\(_contextPath)\(readinessProbe.path)"

	// Validations matching sonarqube.validate in Helm helper
	replicaCount: <=1

	if sonarqube.databaseMode == "postgresql" {
		postgresql: enabled: true
	}

	if databaseMode == "external" {
		postgresql: enabled: false
		database: external: {
			jdbcUrl:  != ""
			username: != ""
		}
		let esEnabled = externalSecrets.enabled
		let esDbEnabled = externalSecrets.database.enabled
		if !esEnabled || !esDbEnabled {
			{ database: external: password: != "" } | { database: external: existingSecret: != "" }
		}
	}

	if databaseMode == "postgresql" {
		postgresql: auth: {
			database: != ""
			username: != ""
		}
	}

	if gatewayAPI.enabled {
		gatewayAPI: parentRefs: [...{}] & [_, ...]
	}

	if externalSecrets.database.enabled || externalSecrets.monitoringPasscode.enabled {
		externalSecrets: enabled: true
	}

	if externalSecrets.enabled {
		externalSecrets: secretStoreRef: name: != ""
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		cm: #ConfigMap & {#config: config}

		svc: #Service & {#config: config}

		deploy: #Deployment & {#config: config}

		let databaseMode = config.databaseMode
		let needsDbSecret = databaseMode == "external" && config.database.external.existingSecret == "" && !(config.externalSecrets.enabled && config.externalSecrets.database.enabled) && config.database.external.password != ""
		let needsMonitoringSecret = config.sonarqube.monitoringPasscode != "" && config.sonarqube.existingMonitoringPasscodeSecret == "" && !(config.externalSecrets.enabled && config.externalSecrets.monitoringPasscode.enabled)
		if needsDbSecret || needsMonitoringSecret {
			secret: #Secret & {#config: config}
		}

		if config.persistence.data.enabled && config.persistence.data.existingClaim == "" {
			pvcData: #PVC & {#config: config, #pvcName: "data", #pvcSpec: config.persistence.data}
		}
		if config.persistence.extensions.enabled && config.persistence.extensions.existingClaim == "" {
			pvcExtensions: #PVC & {#config: config, #pvcName: "extensions", #pvcSpec: config.persistence.extensions}
		}
		if config.persistence.logs.enabled && config.persistence.logs.existingClaim == "" {
			pvcLogs: #PVC & {#config: config, #pvcName: "logs", #pvcSpec: config.persistence.logs}
		}

		if config.gatewayAPI.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		if config.networkPolicy.enabled {
			netpol: #NetworkPolicy & {#config: config}
		}

		if config.pdb.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}

		if config.externalSecrets.enabled {
			if config.externalSecrets.database.enabled {
				esDb: #ExternalSecretDB & {#config: config}
			}
			if config.externalSecrets.monitoringPasscode.enabled {
				esMonitoring: #ExternalSecretMonitoring & {#config: config}
			}
		}

		if config.postgresql.enabled {
			pgSecret:      #PGSecret & {#config: config}
			pgSVC:         #PGSVC & {#config: config}
			pgHeadlessSVC: #PGHeadlessSVC & {#config: config}
			pgDeploy:      #PGStatefulSet & {#config: config}
		}
	}

	tests: {
		if config.tests.enabled {
			"test-svc": #TestJob & {#config: config}
		}
	}
}
