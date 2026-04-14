package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	corev1 "k8s.io/api/core/v1"
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
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// OpenProject specific values
	develop: *true | bool

	image: {
		registry:        *"docker.io" | string
		repository:      *"openproject/openproject" | string
		tag:             *"17.2.3-slim" | string
		digest:          *null | string
		imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
		reference:       "\(repository):\(tag)"
	}

	dbInit: {
		image: {
			registry:        *"docker.io" | string
			repository:      *"postgres" | string
			tag:             *"16" | string
			digest:          *null | string
			imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
			reference:       "\(repository):\(tag)"
		}
		resourcesPreset: *null | string
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"1536Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"500m" | timoniv1.#CPUQuantity
				memory: *"2Gi" | timoniv1.#MemoryQuantity
			}
		}
	}

	appInit: {
		resourcesPreset: *null | string
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				memory: *"1536Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				memory: *"2Gi" | timoniv1.#MemoryQuantity
			}
		}
	}

	global: {
		imagePullSecrets: [...string] | *[]
	}
	namespaceOverride:       *"" | string
	commonLabels:            timoniv1.#Labels
	commonAnnotations:       timoniv1.#Annotations
	nameOverride:            *"" | string
	fullnameOverride:        *"" | string
	imagePullSecrets:        [...corev1.#LocalObjectReference] | *[]

	affinity:    *{} | _
	tolerations: *[] | [_]
	nodeSelector: *{} | { [string]: string }
	topologySpreadConstraints: *[] | [_]
	runtimeClassName: *"" | string

	cleanup: {
		deletePodsOnSuccess:        *true | bool
		deletePodsOnSuccessTimeout: *86400 | int
	}

	environment: { [string]: string }
	extraEnvVars: *[] | [_]
	extraVolumes: *[] | [_]
	extraVolumeMounts: *[] | [_]

	clusterDomain: *"cluster.local" | string

	ingress: {
		enabled:          *false | bool
		ingressClassName: *null | string
		annotations: timoniv1.#Annotations & {
			"nginx.ingress.kubernetes.io/proxy-read-timeout": *"3600" | string
			"nginx.ingress.kubernetes.io/proxy-send-timeout": *"3600" | string
			"nginx.ingress.kubernetes.io/proxy-http-version": *"1.1" | string
			"nginx.ingress.kubernetes.io/websocket-services": *"\(metadata.name)-hocuspocus" | string
		}
		labels:   timoniv1.#Labels
		host:     *"openproject.example.com" | string
		path:     *"/" | string
		pathType: *"Prefix" | string
		tls: {
			enabled:    *true | bool
			secretName: *"" | string
			extraTls:   *[] | [_]
		}
	}

	egress: tls: rootCA: {
		configMap: *"" | string
		fileName:  *"" | string
	}

	networkPolicy: {
		enabled:                 *false | bool
		allowExternal:           *true | bool
		allowExternalEgress:     *true | bool
		addExternalClientAccess: *true | bool
		extraIngress:           *[] | [_]
		extraEgress:            *[] | [_]
		ingressPodMatchLabels:   timoniv1.#Labels
		ingressNSMatchLabels:    timoniv1.#Labels
		ingressNSPodMatchLabels: timoniv1.#Labels
	}

	persistence: {
		enabled:          *true | bool
		existingClaim:    *"" | string
		storageClassName: *"ceph-filesystem" | string
		accessModes:      *["ReadWriteMany"] | [...string]
		size:             *"1Gi" | string
		annotations:      timoniv1.#Annotations
	}

	service: {
		enabled:     *true | bool
		type:        *"ClusterIP" | string
		annotations: timoniv1.#Annotations
		labels:      timoniv1.#Labels
		ports: {
			http: {
				port:          *80 | int
				containerPort: *8080 | int
				protocol:      *"TCP" | string
				nodePort:      *0 | int
			}
		}
		sessionAffinity: {
			enabled:        *false | bool
			timeoutSeconds: *10800 | int
		}
		loadBalancerIP: *"" | string
	}

	serviceAccount: {
		create:      *true | bool
		annotations: timoniv1.#Annotations
		openshift: securityContextConstraints: roleBinding: {
			enable:       *false | bool
			resourceName: *"nonroot-v2" | string
		}
	}

	seeder: {
		resourcesPreset: *null | string
		nodeSelector: *{} | { [string]: string }
		annotations:  timoniv1.#Annotations
		resources:    timoniv1.#ResourceRequirements
	}

	seederJob: {
		resourcesPreset: *null | string
		annotations: timoniv1.#Annotations
		resources:   timoniv1.#ResourceRequirements
	}

	strategy: {
		type: *"Recreate" | "RollingUpdate"
	}

	cron: {
		enabled:         *true | bool
		resourcesPreset: *null | string
		annotations:     timoniv1.#Annotations
		resources:       timoniv1.#ResourceRequirements
		environment: { [string]: string | int }
		existingSecret: *"" | string
		secretKeys: {
			imapUsername: *"imapUsername" | string
			imapPassword: *"imapPassword" | string
		}
		nodeSelector: *{} | { [string]: string }
	}

	worker: {
		nodeSelector: *{} | { [string]: string }
		labels:       timoniv1.#Labels
		annotations:  timoniv1.#Annotations
		topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
	}

	workers: {
		[string]: #Worker
	}

	#Worker: {
		queues:       *"" | string
		maxThreads?:  int
		replicaCount: *1 | int
		resources:    timoniv1.#ResourceRequirements
		strategy: {
			type: *"Recreate" | "RollingUpdate"
		}
		nodeSelector: *{} | { [string]: string }
		annotations:  timoniv1.#Annotations
		labels:       timoniv1.#Labels
		topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
	}

	web: {
		nodeSelector: *{} | { [string]: string }
		annotations:  timoniv1.#Annotations
		labels:       timoniv1.#Labels
		topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
	}

		hocuspocus: {
			enabled:         *true | bool
			resourcesPreset: *null | string
			openproject_url: *"" | string
			https:           openproject.https
			ingress: {
			path:     *"/hocuspocus" | string
			pathType: *"Prefix" | string
		}
		auth: {
			existingSecret: *"" | string
			secret:         *"secret" | string
			secretKey:      *"secret" | string
		}
		networkPolicy: {
			enabled:                 *true | bool
			allowExternal:           *true | bool
			allowExternalEgress:     *true | bool
			addExternalClientAccess: *true | bool
			extraIngress:           *[] | [_]
			extraEgress:            *[] | [_]
			ingressPodMatchLabels:   timoniv1.#Labels
			ingressNSMatchLabels:    timoniv1.#Labels
			ingressNSPodMatchLabels: timoniv1.#Labels
		}
		image: {
			repository:      *"docker.io/openproject/hocuspocus" | string
			tag:             *"release-338001b2" | string
			imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
			reference:       "\(repository):\(tag)"
		}
		strategy: type: *"Recreate" | "RollingUpdate"
		podAnnotations: timoniv1.#Annotations
		service: {
			port:           *1234 | int
			type:           *"ClusterIP" | string
			loadBalancerIP: *"" | string
		}
		resources:     timoniv1.#ResourceRequirements
	}

	openproject: {
		seed_locale:          *"en" | string
		https:                *true | bool
		host:                 *"" | string
		hsts:                 *true | bool
		cache: store:         *"memcache" | string
		extraEnvVarsSecret:   *"" | string
		extraEnvVars:         { [string]: string | int } | *{}
		extraVolumes:         [...corev1.#Volume] | *[]
		extraVolumeMounts:    [...corev1.#VolumeMount] | *[]
		railsRelativeUrlRoot: *"" | string
		admin_user: {
			password:       *"admin" | string
			password_reset: *"true" | string
			name:           *"OpenProject Admin" | string
			mail:           *"admin@example.net" | string
			secret:         hocuspocus.auth.secretKey
			secretKeys: password: *"" | string
			locked:         *false | bool
		}
		oidc: {
			enabled:               *false | bool
			provider:              *"Keycloak" | string
			displayName:           *"Keycloak" | string
			host:                  *"" | string
			identifier:            *"" | string
			secret:                *"" | string
			authorizationEndpoint: *"" | string
			tokenEndpoint:         *"" | string
			userinfoEndpoint:      *"" | string
			endSessionEndpoint:    *"" | string
			scope:                 *"[openid]" | string
			attribute_map:         *{} | _
			existingSecret:        *"" | string
			secretKeys: {
				identifier: *"clientId" | string
				secret:     *"clientSecret" | string
			}
			extraOidcSealedSecret: *"" | string
		}
		realtime_collaboration: {
			enabled: *true | bool
			hocuspocus: {
				protocol: *"wss" | string
				host:     *"" | string
				path:     *"/hocuspocus" | string
				auth: {
					existingSecret: *"" | string
					secret:         *"secret" | string
					secretKey:      *"secret" | string
				}
			}
		}
		postgresStatementTimeout: *"120s" | string
		annotations:              timoniv1.#Annotations
		useTmpVolumes:            *true | bool
		tmpVolumesStorage:        *"5Gi" | string
		tmpVolumesStorageClassName: *"" | string
		tmpVolumesAnnotations:    timoniv1.#Annotations
		tmpVolumesLabels:         timoniv1.#Labels
	}

	s3: {
		enabled: *false | bool
		auth: {
			accessKeyId:     *"" | string
			secretAccessKey: *"" | string
			existingSecret:  *"" | string
		}
		region:           *"" | string
		bucketName:       *"" | string
		endpoint:         *"" | string
		host:             *"" | string
		port:             *"" | string
		pathStyle:        *false | bool
		signatureVersion: *4 | int
		useIamProfile:    *false | bool
		enableSignatureV4Streaming: *true | bool
		directUploads:    *true | bool
	}

	podAnnotations: timoniv1.#Annotations

	podSecurityContext: {
		enabled: *true | bool
		fsGroup: *1000 | int
	}

	containerSecurityContext: {
		enabled:                  *true | bool
		runAsUser:                *1000 | int
		runAsGroup:               *1000 | int
		allowPrivilegeEscalation: *false | bool
		capabilities: drop:       *["ALL"] | [...string]
		seccompProfile: type:     *"RuntimeDefault" | string
		readOnlyRootFilesystem:   *true | bool
		runAsNonRoot:             *true | bool
	}

	postgresql: {
		bundled: *true | bool
		image: {
			repository:      *"bitnamilegacy/postgresql" | string
			tag:             *"15.4.0-debian-11-r45" | string
			imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
			reference:       "\(repository):\(tag)"
		}
		volumePermissions: {
			enabled: *false | bool
			image: {
				repository:      *"bitnamilegacy/os-shell" | string
				tag:             *"" | string
				imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
				reference:       "\(repository):\(tag)"
			}
		}
		metrics: {
			enabled: *false | bool
			image: {
				repository:      *"bitnamilegacy/postgres-exporter" | string
				tag:             *"" | string
				imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
				reference:       "\(repository):\(tag)"
			}
		}
		global: containerSecurityContext: {
			enabled:                  *true | bool
			allowPrivilegeEscalation: *false | bool
			capabilities: drop:       *["ALL"] | [...string]
			seccompProfile: type:     *"RuntimeDefault" | string
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
		}
		commonLabels: timoniv1.#Labels
		connection: {
			host: *null | string
			port: *null | int
		}
		auth: {
			existingSecret:   *"" | string
			username:         *"openproject" | string
			database:         *"openproject" | string
			password:         *"" | string
			postgresPassword: *"" | string
		}
		options: {
			pool:                  *null | string
			requireAuth:           *null | string
			channelBinding:        *null | string
			connectTimeout:        *null | string
			clientEncoding:        *null | string
			keepalives:            *null | string
			keepalivesIdle:        *null | string
			keepalivesInterval:    *null | string
			keepalivesCount:       *null | string
			replication:           *null | string
			gssencmode:            *null | string
			sslmode:               *null | string
			sslcompression:        *null | string
			sslcert:               *null | string
			sslkey:                *null | string
			sslpassword:           *null | string
			sslrootcert:           *null | string
			sslcrl:                *null | string
			sslMinProtocolVersion: *null | string
		}
	}

	memcached: {
		bundled: *true | bool
		image: {
			repository:      *"bitnamilegacy/memcached" | string
			tag:             *"1.6.24-debian-12-r0" | string
			imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
			reference:       "\(repository):\(tag)"
		}
		global: containerSecurityContext: {
			enabled:                  *true | bool
			allowPrivilegeEscalation: *false | bool
			capabilities: drop:       *["ALL"] | [...string]
			seccompProfile: type:     *"RuntimeDefault" | string
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
		}
		commonLabels: timoniv1.#Labels
		connection: {
			host: *null | string
			port: *null | int
		}

		auth: {
			existingSecret: *"" | string
		}
	}

	probes: {
		liveness: #Probe & { initialDelaySeconds: *60 | int, timeoutSeconds: *30 | int, periodSeconds: *15 | int, failureThreshold: *3 | int, successThreshold: *1 | int }
		readiness: #Probe & { initialDelaySeconds: *0 | int, timeoutSeconds: *5 | int, periodSeconds: *10 | int, failureThreshold: *3 | int, successThreshold: *1 | int }
		startup: #Probe & { initialDelaySeconds: *60 | int, timeoutSeconds: *5 | int, periodSeconds: *15 | int, failureThreshold: *10 | int, successThreshold: *1 | int }
	}

	#Probe: {
		enabled:             *true | bool
		initialDelaySeconds: int 
		timeoutSeconds:      int
		periodSeconds:       int
		failureThreshold:    int
		successThreshold:    int
	}

	replicaCount:           *1 | int
	backgroundReplicaCount: *1 | int

	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"200m" | timoniv1.#CPUQuantity
			memory: *"1536Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"1000m" | timoniv1.#CPUQuantity
			memory: *"2Gi" | timoniv1.#MemoryQuantity
		}
	}

	autoscaling: {
		enabled:                          *false | bool
		minReplicas:                      *1 | int
		maxReplicas:                      *2 | int
		targetCPUUtilizationPercentage:    *null | int
		targetMemoryUtilizationPercentage: *null | int
		customMetrics:                   *[] | [_]
		behavior:                        *{} | _
	}
    
	test: {
		...
		enabled: *false | bool
	}


	metrics: {
		enabled: *false | bool
		path:    *"/metrics" | string
		port:    *9394 | int
		serviceMonitor: {
			enabled:       *false | bool
			namespace:     *"" | string
			labels:        timoniv1.#Labels
			annotations:   timoniv1.#Annotations
			interval:      *"5s" | string
			scrapeTimeout: *"5s" | string
			honorLabels:   *false | bool
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVC & {#config: config}
		}
		sa: #ServiceAccount & {#config: config}
		for k, v in (#Service & {#config: config}) {
			if k != "#config" {
				"svc-\(k)": v
			}
		}
		secret: #CoreSecret & {#config: config}
		web: #WebDeployment & {#config: config}
		for name, w in config.workers {
			"worker-\(name)": #WorkerDeployment & {
				#config:     config
				#workerName: name
				#worker:     w
			}
		}
		if config.cron.enabled {
			cron: #CronDeployment & {#config: config}
		}
		seeder: #SeederJob & {#config: config}

		// Infrastructure
		for k, v in (#PostgreSQL & {#config: config}).objects {
			"db-\(k)": v
		}
		for k, v in (#Memcached & {#config: config}).objects {
			"memcached-\(k)": v
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.hocuspocus.enabled {
			"hocuspocus-deploy": #HocuspocusDeployment & {#config: config}
			if config.hocuspocus.networkPolicy.enabled {
				"hocuspocus-np": #HocuspocusNetworkPolicy & {#config: config}
			}
			if config.hocuspocus.auth.existingSecret == "" {
				"hocuspocus-secret": #HocuspocusSecret & {#config: config}
			}
		}

		if config.networkPolicy.enabled {
			"web-np":    #WebNetworkPolicy & {#config: config}
			"worker-np": #WorkerNetworkPolicy & {#config: config}
			"cron-np":   #CronNetworkPolicy & {#config: config}
			"seeder-np": #SeederNetworkPolicy & {#config: config}
		}

		if len(config.environment) > 0 {
			"env-secret": #EnvironmentSecret & {#config: config}
		}
		if config.cron.enabled && len(config.cron.environment) > 0 {
			"cron-env-secret": #CronEnvironmentSecret & {#config: config}
		}
		if config.memcached.bundled {
			"memcached-secret": #MemcachedSecret & {#config: config}
		}
		if config.openproject.oidc.enabled && config.openproject.oidc.existingSecret == "" {
			"oidc-secret": #OIDCSecret & {#config: config}
		}
		if config.s3.enabled && config.s3.auth.existingSecret == "" {
			"s3-secret": #S3Secret & {#config: config}
		}

		if config.autoscaling.enabled {
			hpa: #HPA & {#config: config}
		}

		if config.serviceAccount.openshift.securityContextConstraints.roleBinding.enable {
			role:        #Role & {#config: config}
			roleBinding: #RoleBinding & {#config: config}
		}

		if config.metrics.serviceMonitor.enabled {
			"service-monitor": #ServiceMonitor & {#config: config}
		}
	}
}
