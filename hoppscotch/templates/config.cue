package templates

import (
	"strconv"
	"regexp"
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
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Chart mode: dev | production
	mode: *"dev" | "production"

	nameOverride: *"" | string
	fullnameOverride: *"" | string
	namespaceOverride: *"" | string
	commonLabels: *{} | {[string]: string}
	clusterDomain: *"cluster.local" | string

	image: {
		repository: *"docker.io/hoppscotch/hoppscotch" | string
		tag:        *"2026.5.0" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}

	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	baseUrl: *"" | string
	adminUrl: *"" | string
	backendGqlUrl: *"" | string
	backendWsUrl: *"" | string
	backendApiUrl: *"" | string
	shortcodeBaseUrl: *"" | string
	whitelistedOrigins: *"" | string
	enableSubpathBasedAccess: *true | bool
	tosLink: *"" | string
	privacyPolicyLink: *"" | string

	proxy: {
		appUrl: *"" | string
	}

	encryption: {
		key: string
		existingSecret: *"" | string
		existingSecretKey: *"data-encryption-key" | string
	}

	signingKey: {
		key: string
		existingSecret: *"" | string
		existingSecretKey: *"webapp-server-signing-key" | string
	}

	postgresql: {
		enabled: *true | bool
		fullnameOverride: *"" | string
		nameOverride: *"" | string
		image: {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.4-trixie" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		auth: {
			database: *"hoppscotch" | string
			username: *"hoppscotch" | string
			password: *"" | string
			existingSecret: *"" | string
			existingSecretUserPasswordKey: *"" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size: *"10Gi" | string
			}
			resources: *{
				requests: {
					cpu:    "100m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "512Mi"
				}
			} | corev1.#ResourceRequirements
		}
		initdb: {
			scripts: *{} | {[string]: string}
		}
	}

	postgresqlExtensionsJob: {
		enabled: *true | bool
		requireExistingResources: *true | bool
		image: {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.3-trixie" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		backoffLimit: *6 | int
		activeDeadlineSeconds: *300 | int
		podAnnotations: *{} | {[string]: string}
		podSecurityContext: *{
			runAsNonRoot: true
			runAsUser: 999
			fsGroup: 999
			seccompProfile: {
				type: "RuntimeDefault"
			}
		} | corev1.#PodSecurityContext
		securityContext: *{
			allowPrivilegeEscalation: false
			capabilities: {
				drop: ["ALL"]
			}
			readOnlyRootFilesystem: true
			runAsNonRoot: true
			runAsUser: 999
		} | corev1.#SecurityContext
		resources: *{
			requests: {
				cpu: "10m"
				memory: "32Mi"
			}
			limits: {
				cpu: "100m"
				memory: "128Mi"
			}
		} | corev1.#ResourceRequirements
	}

	database: {
		external: {
			enabled: *false | bool
			host: *"" | string
			port: *5432 | int
			name: *"hoppscotch" | string
			username: *"hoppscotch" | string
			password: *"" | string
			existingSecret: *"" | string
			existingSecretPasswordKey: *"postgres-password" | string
			url: *"" | string
			existingSecretUrlKey: *"" | string
		}
	}

	auth: {
		providers: *"EMAIL" | string
		github: {
			enabled: *false | bool
			clientId: *"" | string
			clientSecret: *"" | string
			existingSecret: *"" | string
			existingSecretClientIdKey: *"github-client-id" | string
			existingSecretClientSecretKey: *"github-client-secret" | string
			scope: *"user:email" | string
			callbackUrl: *"" | string
		}
		google: {
			enabled: *false | bool
			clientId: *"" | string
			clientSecret: *"" | string
			existingSecret: *"" | string
			existingSecretClientIdKey: *"google-client-id" | string
			existingSecretClientSecretKey: *"google-client-secret" | string
			scope: *"email,profile" | string
			callbackUrl: *"" | string
		}
		microsoft: {
			enabled: *false | bool
			clientId: *"" | string
			clientSecret: *"" | string
			existingSecret: *"" | string
			existingSecretClientIdKey: *"microsoft-client-id" | string
			existingSecretClientSecretKey: *"microsoft-client-secret" | string
			scope: *"user.read" | string
			callbackUrl: *"" | string
		}
	}

	mailer: {
		enabled: *false | bool
		from: *"" | string
		useCustomConfigs: *false | bool
		smtpUrl: *"" | string
		host: *"" | string
		port: *587 | int
		secure: *true | bool
		user: *"" | string
		password: *"" | string
		tlsRejectUnauthorized: *true | bool
		existingSecret: *"" | string
		existingSecretSmtpUrlKey: *"smtp-url" | string
		existingSecretPasswordKey: *"smtp-password" | string
	}

	replicaCount: *1 | int

	deployment: {
		strategy: {
			type: *"RollingUpdate" | "Recreate"
			rollingUpdate?: {
				maxUnavailable: *(0 | string) | (int | string)
				maxSurge: *(1 | string) | (int | string)
			}
		}
	}

	serviceAccount: {
		create: *true | bool
		name: *"" | string
		automountServiceAccountToken: *false | bool
		annotations: *{} | {[string]: string}
	}

	podSecurityContext: *{
		fsGroup: 1000
		runAsNonRoot: true
	} | corev1.#PodSecurityContext

	containerSecurityContext: *{
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
		}
		readOnlyRootFilesystem: false
		runAsNonRoot: true
		runAsUser: 1000
	} | corev1.#SecurityContext

	resources: *{
		requests: {
			cpu: "200m"
			memory: "256Mi"
		}
		limits: {
			cpu: "1000m"
			memory: "512Mi"
		}
	} | corev1.#ResourceRequirements

	service: {
		type: *"ClusterIP" | "NodePort" | "LoadBalancer" | string
		port: *80 | int
		containerPort: *8081 | int
		ipFamilyPolicy: *"" | string
		ipFamilies: *[] | [...string]
	}

	ingress: {
		enabled: *false | bool
		ingressClassName: *"" | string
		host: *"" | string
		annotations: *{} | {[string]: string}
		tls: *[] | [...]
	}

	gateway: {
		enabled: *false | bool
		parentRefs: *[] | [...]
		hostnames: *[] | [...string]
		path: *"/" | string
		pathType: *"PathPrefix" | string
		annotations: *{} | {[string]: string}
	}

	gatewayAPI: {
		enabled: *false | bool
		parentRefs: *[] | [...]
		hostnames: *[] | [...string]
		path: *"/" | string
		pathType: *"PathPrefix" | string
		paths: *[] | [...]
		annotations: *{} | {[string]: string}
		gatewayName?: string
		gatewayNamespace?: string
	}

	externalSecrets: {
		enabled: *false | bool
		apiVersion: *"external-secrets.io/v1" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | string
		}
		refreshInterval: *"1h" | string
		data: *[] | [...]
		dataFrom: *[] | [...]
		annotations: *{} | {[string]: string}
	}

	metrics: {
		enabled: *false | bool
		serviceMonitor: {
			enabled: *false | bool
			interval: *"30s" | string
			labels: *{} | {[string]: string}
		}
	}

	networkPolicy: {
		enabled: *false | bool
		ingress: *[] | [...]
		egress: *[] | [...]
	}

	podDisruptionBudget: {
		enabled: *false | bool
		minAvailable: *(1 | string) | (int | string)
	}

	podAnnotations: *{} | {[string]: string}
	podLabels: *{} | {[string]: string}
	nodeSelector: *{} | {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity: *{} | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]

	initContainers: *[] | [...]
	extraEnv: *[] | [...]
	extraEnvFrom: *[] | [...]



	// Computed properties
	fullname: string
	if fullnameOverride != "" { fullname: fullnameOverride }
	if fullnameOverride == "" {
		let name = [if nameOverride != "" { nameOverride }, "hoppscotch"][0]
		fullname: "\(metadata.name)-\(name)"
	}

	namespace: string
	if namespaceOverride != "" { namespace: namespaceOverride }
	if namespaceOverride == "" { namespace: metadata.namespace }

	protocol: string
	if len(ingress.tls) > 0 { protocol: "https" }
	if len(ingress.tls) == 0 { protocol: "http" }

	#baseUrl: string
	if baseUrl != "" { #baseUrl: baseUrl }
	if baseUrl == "" {
		if ingress.host != "" { #baseUrl: "\(protocol)://\(ingress.host)" }
		if ingress.host == "" { #baseUrl: "http://localhost:3000" }
	}

	#adminUrl: string
	if adminUrl != "" { #adminUrl: adminUrl }
	if adminUrl == "" {
		if ingress.host != "" { #adminUrl: "\(protocol)://\(ingress.host)/admin" }
		if ingress.host == "" { #adminUrl: "http://localhost:3100" }
	}

	#backendGqlUrl: string
	if backendGqlUrl != "" { #backendGqlUrl: backendGqlUrl }
	if backendGqlUrl == "" {
		if ingress.host != "" { #backendGqlUrl: "\(protocol)://\(ingress.host)/backend/graphql" }
		if ingress.host == "" { #backendGqlUrl: "http://localhost:3170/graphql" }
	}

	#backendWsUrl: string
	if backendWsUrl != "" { #backendWsUrl: backendWsUrl }
	if backendWsUrl == "" {
		if ingress.host != "" {
			if len(ingress.tls) > 0 { #backendWsUrl: "wss://\(ingress.host)/backend/graphql" }
			if len(ingress.tls) == 0 { #backendWsUrl: "ws://\(ingress.host)/backend/graphql" }
		}
		if ingress.host == "" { #backendWsUrl: "ws://localhost:3170/graphql" }
	}

	#backendApiUrl: string
	if backendApiUrl != "" { #backendApiUrl: backendApiUrl }
	if backendApiUrl == "" {
		if ingress.host != "" { #backendApiUrl: "\(protocol)://\(ingress.host)/backend/v1" }
		if ingress.host == "" { #backendApiUrl: "http://localhost:3170/v1" }
	}

	#shortcodeBaseUrl: string
	if shortcodeBaseUrl != "" { #shortcodeBaseUrl: shortcodeBaseUrl }
	if shortcodeBaseUrl == "" { #shortcodeBaseUrl: #baseUrl }

	#whitelistedOrigins: string
	if whitelistedOrigins != "" { #whitelistedOrigins: whitelistedOrigins }
	if whitelistedOrigins == "" { #whitelistedOrigins: "\(#baseUrl),\(#adminUrl),\(#backendApiUrl),app://localhost_3200,app://hoppscotch" }

	#authProviders: string
	if auth.providers != "" { #authProviders: auth.providers }
	if auth.providers == "" { #authProviders: "EMAIL" }

	#githubCallbackUrl: string
	if auth.github.callbackUrl != "" { #githubCallbackUrl: auth.github.callbackUrl }
	if auth.github.callbackUrl == "" { #githubCallbackUrl: "\(#backendApiUrl)/auth/github/callback" }

	#googleCallbackUrl: string
	if auth.google.callbackUrl != "" { #googleCallbackUrl: auth.google.callbackUrl }
	if auth.google.callbackUrl == "" { #googleCallbackUrl: "\(#backendApiUrl)/auth/google/callback" }

	#microsoftCallbackUrl: string
	if auth.microsoft.callbackUrl != "" { #microsoftCallbackUrl: auth.microsoft.callbackUrl }
	if auth.microsoft.callbackUrl == "" { #microsoftCallbackUrl: "\(#backendApiUrl)/auth/microsoft/callback" }

	serviceAccountName: string
	if serviceAccount.create {
		if serviceAccount.name != "" { serviceAccountName: serviceAccount.name }
		if serviceAccount.name == "" { serviceAccountName: fullname }
	}
	if !serviceAccount.create {
		if serviceAccount.name != "" { serviceAccountName: serviceAccount.name }
		if serviceAccount.name == "" { serviceAccountName: "default" }
	}

	databaseHost: string
	if !postgresql.enabled {
		if database.external.host != "" { databaseHost: database.external.host }
		if database.external.host == "" {
			if database.external.url != "" {
				let hostPort = regexp.FindSubmatch(#"^postgresql://(?:[^@]+@)?([^/]+)"#, database.external.url)
				if len(hostPort) > 1 {
					let mHost = regexp.FindSubmatch(#"^([^:]+)"#, hostPort[1])
					if len(mHost) > 1 { databaseHost: mHost[1] }
					if len(mHost) == 0 { databaseHost: hostPort[1] }
				}
				if len(hostPort) == 0 { databaseHost: "" }
			}
			if database.external.url == "" { databaseHost: "" }
		}
	}
	if postgresql.enabled {
		databaseHost: "\(metadata.name)-postgresql"
	}

	databasePort: int
	if !postgresql.enabled {
		if database.external.host != "" { databasePort: database.external.port }
		if database.external.host == "" {
			if database.external.url != "" {
				let hostPort = regexp.FindSubmatch(#"^postgresql://(?:[^@]+@)?([^/]+)"#, database.external.url)
				if len(hostPort) > 1 {
					let mPort = regexp.FindSubmatch(#":(\d+)$"#, hostPort[1])
					if len(mPort) > 1 { databasePort: strconv.Atoi(mPort[1]) }
					if len(mPort) == 0 { databasePort: 5432 }
				}
				if len(hostPort) == 0 { databasePort: 5432 }
			}
			if database.external.url == "" { databasePort: 5432 }
		}
	}
	if postgresql.enabled {
		databasePort: 5432
	}

	databaseName: string
	if !postgresql.enabled {
		if database.external.name != "" { databaseName: database.external.name }
		if database.external.name == "" { databaseName: "hoppscotch" }
	}
	if postgresql.enabled {
		if postgresql.auth.database != "" { databaseName: postgresql.auth.database }
		if postgresql.auth.database == "" { databaseName: "hoppscotch" }
	}

	databaseSecretName: string
	if database.external.existingSecret != "" { databaseSecretName: database.external.existingSecret }
	if database.external.existingSecret == "" { databaseSecretName: fullname }

	databaseSecretUrlKey: string
	if database.external.existingSecret != "" && database.external.existingSecretUrlKey != "" { databaseSecretUrlKey: database.external.existingSecretUrlKey }
	if database.external.existingSecret == "" || database.external.existingSecretUrlKey == "" { databaseSecretUrlKey: "database-url" }

	postgresqlSecretName: string
	if postgresql.auth.existingSecret != _|_ && postgresql.auth.existingSecret != "" { postgresqlSecretName: postgresql.auth.existingSecret }
	if postgresql.auth.existingSecret == _|_ || postgresql.auth.existingSecret == "" {
		if postgresql.fullnameOverride != _|_ && postgresql.fullnameOverride != "" { postgresqlSecretName: "\(postgresql.fullnameOverride)-auth" }
		if postgresql.fullnameOverride == _|_ || postgresql.fullnameOverride == "" {
			let name = [if postgresql.nameOverride != _|_ && postgresql.nameOverride != "" { postgresql.nameOverride }, "postgresql"][0]
			postgresqlSecretName: "\(metadata.name)-\(name)-auth"
		}
	}

	encryptionSecretName: string
	if encryption.existingSecret != "" { encryptionSecretName: encryption.existingSecret }
	if encryption.existingSecret == "" { encryptionSecretName: fullname }

	encryptionSecretKey: string
	if encryption.existingSecret != "" { encryptionSecretKey: encryption.existingSecretKey }
	if encryption.existingSecret == "" { encryptionSecretKey: "data-encryption-key" }

	signingSecretName: string
	if signingKey.existingSecret != "" { signingSecretName: signingKey.existingSecret }
	if signingKey.existingSecret == "" { signingSecretName: fullname }

	signingSecretKey: string
	signingSecretKey: signingKey.existingSecretKey

	shouldRunPostgresqlExtensionsJob: bool
	shouldRunPostgresqlExtensionsJob: postgresql.enabled && postgresqlExtensionsJob.enabled

	databaseEnv: [...corev1.#EnvVar]
	if !postgresql.enabled && database.external.existingSecret != "" && database.external.existingSecretUrlKey == "" {
		databaseEnv: [
			{
				name: "DB_PASSWORD"
				valueFrom: secretKeyRef: {
					name: database.external.existingSecret
					key: database.external.existingSecretPasswordKey
				}
			},
			{
				name: "DATABASE_URL"
				value: "postgresql://\(database.external.username):$(DB_PASSWORD)@\(databaseHost):\(databasePort)/\(databaseName)"
			}
		]
	}
	if postgresql.enabled {
		databaseEnv: [
			{
				name: "DB_PASSWORD"
				valueFrom: secretKeyRef: {
					name: postgresqlSecretName
					key: [if postgresql.auth.existingSecretUserPasswordKey != _|_ && postgresql.auth.existingSecretUserPasswordKey != "" { postgresql.auth.existingSecretUserPasswordKey }, "user-password"][0]
				}
			},
			{
				name: "DATABASE_URL"
				value: "postgresql://\(postgresql.auth.username):$(DB_PASSWORD)@\(databaseHost):\(databasePort)/\(databaseName)"
			}
		]
	}
	if (!postgresql.enabled && (database.external.existingSecret == "" || database.external.existingSecretUrlKey != "")) {
		databaseEnv: [
			{
				name: "DATABASE_URL"
				valueFrom: secretKeyRef: {
					name: databaseSecretName
					key: databaseSecretUrlKey
				}
			}
		]
	}

	labels: timoniv1.#Labels
	labels: {
		"helm.sh/chart": "hoppscotch-\(moduleVersion)"
		"app.kubernetes.io/name": [if nameOverride != "" { nameOverride }, "hoppscotch"][0]
		"app.kubernetes.io/instance": metadata.name
		"app.kubernetes.io/version": image.tag
		"app.kubernetes.io/managed-by": "Helm"
		"app.kubernetes.io/part-of": "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}

	selectorLabels: timoniv1.#Labels
	selectorLabels: {
		"app.kubernetes.io/name": [if nameOverride != "" { nameOverride }, "hoppscotch"][0]
		"app.kubernetes.io/instance": metadata.name
	}
	test: {
		enabled: *false | bool
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		svc: #Service & {#config: config}
		cm: #ConfigMap & {#config: config}

		// Only create secret if any of these conditions are true:
		if config.encryption.existingSecret == "" || config.signingKey.existingSecret == "" || (config.database.external.enabled && config.database.external.existingSecret == "") || (config.auth.github.enabled && config.auth.github.existingSecret == "") || (config.auth.google.enabled && config.auth.google.existingSecret == "") || (config.auth.microsoft.enabled && config.auth.microsoft.existingSecret == "") || (config.mailer.enabled && config.mailer.existingSecret == "") {
			sec: #Secret & {#config: config}
		}

		deploy: #Deployment & {
			#config: config
			#cmData: cm.data
			if objects.sec != _|_ {
				#secData: objects.sec.data
			}
		}

		if config.externalSecrets.enabled {
			externalsecret: #ExternalSecret & {#config: config}
		}

		if config.gateway.enabled || config.gatewayAPI.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		if config.networkPolicy.enabled {
			networkpolicy: #NetworkPolicy & {#config: config}
		}

		if config.podDisruptionBudget.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}

		if config.shouldRunPostgresqlExtensionsJob {
			"postgresql-extensions-job": #PostgreSQLExtensionsJob & {#config: config}
		}

		if config.metrics.enabled && config.metrics.serviceMonitor.enabled {
			servicemonitor: #ServiceMonitor & {#config: config}
		}

		if config.postgresql.enabled {
			if config.postgresql.auth.existingSecret == "" {
				"postgresql-secret": #PostgreSQLSecret & {#config: config}
			}
			"postgresql-initdb-cm": #PostgreSQLInitDBCM & {#config: config}
			"postgresql-svc":       #PostgreSQLService & {#config: config}
			"postgresql-hl-svc":    #PostgreSQLHeadlessService & {#config: config}
			"postgresql-sts":       #PostgreSQLStatefulSet & {#config: config}
		}
	}
}
