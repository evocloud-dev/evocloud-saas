package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the NetBox Timoni module.
#Config: {
	// The kubeVersion is set at apply-time by querying the user's Kubernetes API.
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.25.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels & {
	}
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Calculated fields (Internal)
	_fullname: {
		if fullnameOverride != "" {
			fullnameOverride
		}
		if fullnameOverride == "" {
			metadata.name
		}
	}

	_configSecretName: {
		if existingSecret != "" {
			existingSecret
		}
		if existingSecret == "" {
			"\(_fullname)-config"
		}
	}

	_superuserSecretName: {
		if superuser.existingSecret != "" {
			superuser.existingSecret
		}
		if superuser.existingSecret == "" {
			"\(_fullname)-superuser"
		}
	}

	_extraVolumeMounts: [
		for ec in extraConfig {
			name: "extra-config-\(ec.name)"
			mountPath: ec.mountPath
			subPath: {
				if ec.subPath != _|_ { ec.subPath }
				if ec.subPath == _|_ { ec.name }
			}
			readOnly: {
				if ec.readOnly != _|_ { ec.readOnly }
				if ec.readOnly == _|_ { true }
			}
		}
	]

	_extraVolumes: [
		for ec in extraConfig {
			name: "extra-config-\(ec.name)"
			configMap: name: {
				if ec.configMap != _|_ { ec.configMap }
				if ec.configMap == _|_ { "\(_fullname)-extra-\(ec.name)" }
			}
		}
	]

	// Global parameters
	global: {
		imageRegistry:    *"" | string
		imagePullSecrets: *[] | [...string]
		storageClass:     *"" | string
	}

	// Common parameters
	nameOverride:      *"" | string
	fullnameOverride:  *"" | string
	commonLabels:      *{[string]: string} | {[string]: string}
	commonAnnotations: *{[string]: string} | {[string]: string}
	clusterDomain:     *"cluster.local" | string
	extraDeploy:       *[] | [...{...}]

	// NetBox Image parameters
	image: {
		registry:    *"ghcr.io" | string
		repository:  *"netbox-community/netbox" | string
		tag:         *"" | string // Defaults to moduleVersion if empty
		digest:      *"" | string
		pullPolicy:  *"IfNotPresent" | string
		pullSecrets: *[] | [...string]
	}

	// NetBox Configuration parameters
	superuser: {
		name:           *"admin" | string
		email:          *"admin@example.com" | string
		password:       *"changeit" | string
		apiToken:       *"" | string
		existingSecret: *"" | string
	}

	allowedHosts:              *["*"] | [...string]
	allowedHostsIncludesPodIP: *true | bool
	admins:                    *[] | [...[string, string]]
	allowTokenRetrieval:       *false | bool
	authPasswordValidators:    *[] | [...{...}]
	allowedUrlSchemes:         *["file", "ftp", "ftps", "http", "https", "irc", "mailto", "sftp", "ssh", "tel", "telnet", "tftp", "vnc", "xmpp"] | [...string]

	banner: {
		top:    *"" | string
		bottom: *"" | string
		login:  *"" | string
	}

	basePath:                 *"" | string
	changelogRetention:       *90 | int
	customValidators:         *{[string]: string} | {[string]: string}
	defaultUserPreferences:   *{[string]: {...}} | {[string]: {...}}

	cors: {
		originAllowAll:       *false | bool
		originWhitelist:      *[] | [...string]
		originRegexWhitelist: *[] | [...string]
	}

	csrf: {
		cookieName:     *"csrftoken" | string
		trustedOrigins: *[] | [...string]
	}

	defaultLanguage:          *"en-us" | string
	dataUploadMaxMemorySize: *2621440 | int
	debug:                    *false | bool
	dbWaitDebug:              *false | bool

	email: {
		server:             *"localhost" | string
		port:               *25 | int
		username:           *"" | string
		password:           *"" | string
		useSSL:             *false | bool
		useTLS:             *false | bool
		sslCertFile:        *"" | string
		sslKeyFile:         *"" | string
		timeout:            *10 | int
		from:               *"" | string
		existingSecretName: *"" | string
		existingSecretKey:  *"email-password" | string
	}

	enforceGlobalUnique:   *true | bool
	exemptViewPermissions: *[] | [...string]
	fieldChoices:           *{[string]: {...}} | {[string]: {...}}
	fileUploadMaxMemorySize: *2621440 | int
	graphQlEnabled:         *true | bool
	httpProxies:            *{[string]: string} | {[string]: string}
	internalIPs:            *["127.0.0.1", "::1"] | [...string]
	jobRetention:           *90 | int
	logging:                *{[string]: {...}} | {[string]: {...}}
	loginPersistence:       *false | bool
	loginRequired:          *false | bool
	loginTimeout:           *1209600 | int
	logoutRedirectUrl:      *"home" | string
	maintenanceMode:        *false | bool
	mapsUrl:                *"https://maps.google.com/?q=" | string
	maxPageSize:            *1000 | int
	storages:               *{[string]: {...}} | {[string]: {...}}
	paginateCount:          *50 | int
	plugins:                *[] | [...string]
	pluginsConfig:          *{[string]: {...}} | {[string]: {...}}
	powerFeedDefaultAmperage: *15 | int
	powerFeedMaxUtilisation:  *80 | int
	powerFeedDefaultVoltage:  *120 | int
	preferIPv4:             *false | bool
	rackElevationDefaultUnitHeight: *22 | int
	rackElevationDefaultUnitWidth:  *220 | int

	remoteAuth: {
		enabled:            *false | bool
		backends:           *["netbox.authentication.RemoteUserBackend"] | [...string]
		header:             *"HTTP_REMOTE_USER" | string
		userFirstName:      *"HTTP_REMOTE_USER_FIRST_NAME" | string
		userLastName:       *"HTTP_REMOTE_USER_LAST_NAME" | string
		userEmail:          *"HTTP_REMOTE_USER_EMAIL" | string
		autoCreateUser:     *false | bool
		autoCreateGroups:   *false | bool
		defaultGroups:      *[] | [...string]
		defaultPermissions: *{[string]: {...}} | {[string]: {...}}
		groupSyncEnabled:   *false | bool
		groupHeader:        *"HTTP_REMOTE_USER_GROUP" | string
		superuserGroups:    *[] | [...string]
		superusers:         *[] | [...string]
		staffGroups:        *[] | [...string]
		staffUsers:         *[] | [...string]
		groupSeparator:     *"|" | string
		ldap: {
			serverUri:        *"" | string
			startTls:         *true | bool
			ignoreCertErrors: *false | bool
			caCertDir:        *"" | string
			caCertData:       *"" | string
			bindDn:           *"" | string
			bindPassword:     *"" | string
			userDnTemplate:   *"" | string
			userSearchBaseDn: *"" | string
			userSearchAttr:   *"sAMAccountName" | string
			groupSearchBaseDn: *"" | string
			groupSearchClass:  *"group" | string
			groupType:         *"GroupOfNamesType" | string
			requireGroupDn:    *[] | [...string]
			isAdminDn:         *[] | [...string]
			isSuperUserDn:     *[] | [...string]
			findGroupPerms:    *true | bool
			mirrorGroups:      *true | bool
			mirrorGroupsExcept: *[] | [...string]
			cacheTimeout:       *3600 | int
			attrFirstName:      *"givenName" | string
			attrLastName:       *"sn" | string
			attrMail:           *"mail" | string
		}
	}

	releaseCheck: url: *"" | string
	rqDefaultTimeout:  *300 | int
	sessionCookieName: *"sessionid" | string
	enableLocalization: *false | bool
	timeZone:           *"UTC" | string
	dateFormat:         *"N j, Y" | string
	shortDateFormat:    *"Y-m-d" | string
	timeFormat:         *"g:i a" | string
	shortTimeFormat:    *"H:i:s" | string
	dateTimeFormat:     *"N j, Y g:i a" | string
	shortDateTimeFormat: *"Y-m-d H:i" | string
	extraConfig: *[] | [...{
		name:       string
		mountPath:  string
		subPath?:   string
		readOnly?:  bool
		configMap?: string
	}]
	secretKey:          *"" | string
	existingSecret:     *"" | string

	// Deployment parameters
	command:              *[] | [...string]
	args:                 *[] | [...string]
	replicaCount:         *1 | int
	persistence: {
		enabled:       *true | bool
		storageClass:  *"" | string
		subPath:       *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"1Gi" | string
		existingClaim: *"" | string
		annotations:   *{[string]: string} | {[string]: string}
	}
	reportsPersistence: {
		enabled:       *false | bool
		existingClaim: *"" | string
		subPath:       *"" | string
		storageClass:  *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"1Gi" | string
		annotations:   *{[string]: string} | {[string]: string}
	}
	scriptsPersistence: {
		enabled:       *false | bool
		existingClaim: *"" | string
		subPath:       *"" | string
		storageClass:  *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"1Gi" | string
		annotations:   *{[string]: string} | {[string]: string}
	}
	updateStrategy: {
		type: *"RollingUpdate" | string
		rollingUpdate?: {...}
	}
	serviceAccount: {
		create:                       *true | bool
		annotations:                  *{[string]: string} | {[string]: string}
		name:                         *"" | string
		automountServiceAccountToken: *false | bool
	}
	rbac: {
		create: *true | bool
		rules:  *[] | [...{...}]
	}
	hostAliases:       *[] | [...{...}]
	extraVolumes:      *[] | [...{...}]
	extraVolumeMounts: *[] | [...{...}]
	sidecars:          *[] | [...{...}]
	initContainers:    *[] | [...{...}]
	podLabels:         *{[string]: string} | {[string]: string}
	podAnnotations:    *{[string]: string} | {[string]: string}
	affinity?:           {...}
	nodeSelector?:       {[string]: string}
	tolerations:        *[] | [...{...}]
	priorityClassName:  *"" | string
	schedulerName:      *"" | string
	terminationGracePeriodSeconds: *null | int
	topologySpreadConstraints: *[] | [...{...}]

	pdb: {
		enabled:         *false | bool
		minAvailable?:   string | int
		maxUnavailable?: string | int
	}

	resourcesPreset: *"medium" | string
	resources:       *{...} | {...}

	podSecurityContext: {
		enabled:             *true | bool
		fsGroupChangePolicy: *"Always" | string
		sysctls:             *[] | [...{...}]
		supplementalGroups:  *[] | [...int]
		fsGroup:             *1000 | int
	}

	securityContext: {
		enabled:                  *true | bool
		seLinuxOptions:           *{...} | {...}
		runAsUser:                *1000 | int
		runAsGroup:               *1000 | int
		runAsNonRoot:             *true | bool
		privileged:               *false | bool
		readOnlyRootFilesystem:   *true | bool
		allowPrivilegeEscalation: *false | bool
		capabilities: drop:       *["ALL"] | [...string]
		seccompProfile: type:     *"RuntimeDefault" | string
	}

	automountServiceAccountToken: *false | bool

	livenessProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *0 | int
		periodSeconds:        *10 | int
		timeoutSeconds:       *1 | int
		failureThreshold:     *3 | int
		successThreshold:     *1 | int
	}
	readinessProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *0 | int
		periodSeconds:        *10 | int
		timeoutSeconds:       *1 | int
		failureThreshold:     *3 | int
		successThreshold:     *1 | int
	}
	startupProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *5 | int
		periodSeconds:        *10 | int
		timeoutSeconds:       *1 | int
		failureThreshold:     *100 | int
		successThreshold:     *1 | int
	}
	customLivenessProbe?:  {...}
	customReadinessProbe?: {...}
	customStartupProbe?:   {...}
	lifecycleHooks?:       {...}
	extraEnvs:            *[] | [...{...}]
	extraEnvVarsCM:       *"" | string
	extraEnvVarsSecret:   *"" | string
	revisionHistoryLimit: *10 | int

	service: {
		annotations:              *{[string]: string} | {[string]: string}
		type:                     *"ClusterIP" | string
		port:                     *80 | int
		nodePort:                 *"" | string
		clusterIP:                *"" | string
		externalTrafficPolicy:   *"Cluster" | string
		loadBalancerIP:           *"" | string
		loadBalancerSourceRanges: *[] | [...string]
		loadBalancerClass:        *"" | string
		externalIPs:              *[] | [...string]
		clusterIPs:               *[] | [...string]
		ipFamilyPolicy:           *"" | string
		sessionAffinity:          *"None" | string
		sessionAffinityConfig:    *{...} | {...}
	}

	ingress: {
		enabled:  *false | bool
		pathType: *"ImplementationSpecific" | string
		className: *"" | string
		annotations: *{[string]: string} | {[string]: string}
		hosts: *[] | [...{
			host: string
			paths: [...string | {...}]
		}]
		tls: *[] | [...{
			hosts: [...string]
			secretName: string
		}]
	}

	httpRoute: {
		enabled:     *true | bool
		annotations: *{[string]: string} | {[string]: string}
		parentRefs:  *[] | [...{
			name:        string
			namespace?:  string
			sectionName?: string
			kind?:       *"Gateway" | string
			group?:      *"gateway.networking.k8s.io" | string
		}]
		hostnames: *[] | [...string]
		filters:   *[] | [...{...}]
	}

	metrics: {
		granian: {
			enabled: *true | bool
			serviceMonitor: {
				enabled:           *false | bool
				honorLabels:       *false | bool
				interval:          *"" | string
				scrapeTimeout:     *"" | string
				metricRelabelings: *[] | [...{...}]
				relabelings:       *[] | [...{...}]
				selector:          *{...} | {...}
				additionalLabels:  *{[string]: string} | {[string]: string}
			}
		}
		enabled: *false | bool
		serviceMonitor: {
			enabled:           *false | bool
			honorLabels:       *false | bool
			interval:          *"" | string
			scrapeTimeout:     *"" | string
			metricRelabelings: *[] | [...{...}]
			relabelings:       *[] | [...{...}]
			selector:          *{...} | {...}
			additionalLabels:  *{[string]: string} | {[string]: string}
		}
	}

	postgresql: {
		enabled: *true | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"bitnamilegacy/postgresql" | string
			tag:        *"17.6.0-debian-12-r4" | string
			digest:     *"" | string
			pullPolicy:  *"IfNotPresent" | string
			pullSecrets: *[] | [...string]
			debug:       *false | bool
		}
		auth: {
			username: *"netbox" | string
			database: *"netbox" | string
		}
		persistence: {
			enabled:       *true | bool
			storageClass:  *"" | string
			accessMode:    *"ReadWriteOnce" | string
			size:          *"8Gi" | string
			existingClaim: *"" | string
			mountPath:     *"/bitnamilegacy/postgresql" | string
			subPath:       *"" | string
			volumeName:    *"" | string
		}
		resources: *{} | {...}
	}

	externalDatabase: {
		host:                     *"localhost" | string
		port:                     *5432 | int
		database:                 *"netbox" | string
		username:                 *"netbox" | string
		password:                 *"" | string
		existingSecretName:       *"" | string
		existingSecretKey:        *"postgresql-password" | string
		engine:                   *"django.db.backends.postgresql" | string
		connMaxAge:               *300 | int
		disableServerSideCursors: *false | bool
		options: {
			sslmode:               *"prefer" | string
			target_session_attrs: *"read-write" | string
		}
	}

	additionalDatabases: *{[string]: {...}} | {[string]: {...}}

	valkey: {
		enabled: *true | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"bitnamilegacy/valkey" | string
			tag:        *"8.1.3-debian-12-r3" | string
			digest:     *"" | string
			pullPolicy:  *"IfNotPresent" | string
			pullSecrets: *[] | [...string]
			debug:       *false | bool
		}
		sentinel: {
			enabled:    *false | bool
			primarySet: *"valkey-primary" | string
		}
		auth: sentinel: *false | bool
		replicaCount: *3 | int
		persistence: {
			enabled:       *true | bool
			storageClass:  *"" | string
			accessMode:    *"ReadWriteOnce" | string
			size:          *"1Gi" | string
			existingClaim: *"" | string
			mountPath:     *"/bitnami/valkey/data" | string
			subPath:       *"" | string
			volumeName:    *"" | string
		}
		resources: *{} | {...}
	}

	tasksDatabase: {
		database:              *0 | int
		ssl:                   *false | bool
		insecureSkipTlsVerify: *false | bool
		caCertPath:            *"" | string
		host:                  *"valkey-primary" | string
		port:                  *6379 | int
		sentinels:             *[] | [...string]
		sentinelService:       *"valkey-primary" | string
		sentinelTimeout:       *300 | int
		username:              *"" | string
		password:              *"" | string
		existingSecretName:    *"" | string
		existingSecretKey:     *"tasks-password" | string
	}

	cachingDatabase: {
		database:              *1 | int
		ssl:                   *false | bool
		insecureSkipTlsVerify: *false | bool
		caCertPath:            *"" | string
		host:                  *"valkey-primary" | string
		port:                  *6379 | int
		sentinels:             *[] | [...string]
		sentinelService:       *"valkey-primary" | string
		sentinelTimeout:       *300 | int
		username:              *"" | string
		password:              *"" | string
		existingSecretName:    *"" | string
		existingSecretKey:     *"cache-password" | string
	}

	autoscaling: {
		enabled:                           *false | bool
		minReplicas:                       *1 | int
		maxReplicas:                       *100 | int
		targetCPUUtilizationPercentage:    *80 | int
		targetMemoryUtilizationPercentage: *null | int
		behavior:                          *{...} | {...}
	}

	init: {
		image: {
			registry:    *"docker.io" | string
			repository:  *"busybox" | string
			tag:         *"1.37.0" | string
			digest:      *"" | string
			pullPolicy:  *"IfNotPresent" | string
			pullSecrets: *[] | [...string]
		}
		resourcesPreset: *"nano" | string
		resources:       *{...} | {...}
		securityContext: {
			enabled:        *true | bool
			seLinuxOptions: *{...} | {...}
			seccompProfile: type: *"RuntimeDefault" | string
			capabilities: drop: *["ALL"] | [...string]
			readOnlyRootFilesystem:   *true | bool
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *1000 | int
			runAsGroup:               *1000 | int
		}
	}

	test: {
		enabled: *false | bool
		image: {
			registry:    *"docker.io" | string
			repository:  *"busybox" | string
			tag:         *"1.37.0" | string
			digest:      *"" | string
			pullPolicy:  *"IfNotPresent" | string
			pullSecrets: *[] | [...string]
		}
		resourcesPreset: *"nano" | string
		resources:       *{...} | {...}
		securityContext: {
			enabled:        *false | bool
			seLinuxOptions: *{...} | {...}
			seccompProfile: type: *"RuntimeDefault" | string
			capabilities: drop: *["ALL"] | [...string]
			readOnlyRootFilesystem:   *true | bool
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *1000 | int
			runAsGroup:               *1000 | int
		}
	}

	housekeeping: {
		enabled:                    *true | bool
		schedule:                   *"0 0 * * *" | string
		timezone:                   *"" | string
		successfulJobsHistoryLimit: *5 | int
		failedJobsHistoryLimit:     *5 | int
		command:                    *["/opt/netbox/venv/bin/python", "/opt/netbox/netbox/manage.py", "housekeeping"] | [...string]
		args:                       *[] | [...string]
		podAnnotations:             *{[string]: string} | {[string]: string}
		podSecurityContext: {
			enabled:             *true | bool
			fsGroup:             *1000 | int
			fsGroupChangePolicy: *"Always" | string
			sysctls:             *[] | [...{...}]
			supplementalGroups:  *[] | [...int]
		}
		securityContext: {
			enabled:                  *true | bool
			seLinuxOptions:           *{...} | {...}
			seccompProfile: type:     *"RuntimeDefault" | string
			capabilities: drop:       *["ALL"] | [...string]
			privileged:               *false | bool
			readOnlyRootFilesystem:   *true | bool
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *1000 | int
			runAsGroup:               *1000 | int
		}
		resourcesPreset:     *"none" | string
		resources:           *{...} | {...}
		readOnlyPersistence: *false | bool
		extraEnvs:           *[] | [...{...}]
		extraEnvVarsCM:       *"" | string
		extraEnvVarsSecret:   *"" | string
		extraVolumes:        *[] | [...{...}]
		extraVolumeMounts:   *[] | [...{...}]
		sidecars:            *[] | [...{...}]
		initContainers:      *[] | [...{...}]
		affinity:             *{...} | {...}
		nodeSelector:         *{[string]: string} | {[string]: string}
		tolerations:          *[] | [...{...}]
		podLabels:            *{[string]: string} | {[string]: string}
		automountServiceAccountToken: *false | bool
		concurrencyPolicy:    *"Forbid" | string
		restartPolicy:        *"OnFailure" | string
		suspend:              *false | bool
	}

	worker: {
		enabled: *true | bool
		command: *["/opt/netbox/venv/bin/python", "/opt/netbox/netbox/manage.py", "rqworker"] | [...string]
		args:         *[] | [...string]
		replicaCount: *1 | int
		pdb: {
			enabled:        *false | bool
			minAvailable?:  string | int
			maxUnavailable?: string | int
		}
		podLabels:      *{[string]: string} | {[string]: string}
		podAnnotations: **{[string]: string} | {[string]: string}
		podSecurityContext: {
			enabled:             *true | bool
			fsGroup:             *1000 | int
			fsGroupChangePolicy: *"Always" | string
			sysctls:             *[] | [...{...}]
			supplementalGroups:  *[] | [...int]
		}
		securityContext: {
			enabled:                  *true | bool
			seLinuxOptions:           *{...} | {...}
			seccompProfile: type:     *"RuntimeDefault" | string
			capabilities: drop:       *["ALL"] | [...string]
			privileged:               *false | bool
			readOnlyRootFilesystem:   *true | bool
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *1000 | int
			runAsGroup:               *1000 | int
		}
		resourcesPreset:     *"none" | string
		resources:           *{...} | {...}
		readOnlyPersistence: *false | bool
		automountServiceAccountToken: *true | bool
		affinity:             *{...} | {...}
		nodeSelector:         *{[string]: string} | {[string]: string}
		tolerations:          *[] | [...{...}]
		priorityClassName:    *"" | string
		schedulerName:        *"" | string
		terminationGracePeriodSeconds: *null | int
		topologySpreadConstraints: *[] | [...{...}]
		hostAliases:                 *[] | [...{...}]
		updateStrategy: {
			type: *"RollingUpdate" | string
			rollingUpdate?: {...}
		}
		autoscaling: {
			enabled:                           *false | bool
			minReplicas:                       *1 | int
			maxReplicas:                       *100 | int
			targetCPUUtilizationPercentage:    *80 | int
			targetMemoryUtilizationPercentage: *null | int
			behavior:                          *{...} | {...}
		}
		extraEnvs:          *[] | [...{...}]
		extraEnvVarsCM:      *"" | string
		extraEnvVarsSecret:  *"" | string
		extraVolumes:       *[] | [...{...}]
		extraVolumeMounts:   *[] | [...{...}]
		sidecars:           *[] | [...{...}]
		initContainers:     *[] | [...{...}]
		waitForBackend: {
			enabled: *true | bool
			image: {
				registry:    *"docker.io" | string
				repository:  *"rancher/kubectl" | string
				tag:         *"v1.35.2" | string
				digest:      *"" | string
				pullPolicy:  *"IfNotPresent" | string
				pullSecrets: *[] | [...string]
			}
			command: *["/bin/kubectl"] | [...string]
			args:    *["rollout", "status", "deployment", "$(DEPLOYMENT_NAME)"] | [...string]
			containerSecurityContext: {
				enabled:                  *true | bool
				seLinuxOptions:           *{...} | {...}
				runAsUser:                *1001 | int
				runAsGroup:               *1001 | int
				runAsNonRoot:             *true | bool
				privileged:               *false | bool
				readOnlyRootFilesystem:   *true | bool
				allowPrivilegeEscalation: *false | bool
				capabilities: drop:       *["ALL"] | [...string]
				seccompProfile: type:     *"RuntimeDefault" | string
			}
			resourcesPreset: *"nano" | string
			resources:       *{...} | {...}
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		"web-deployment": #Deployment & {#config: config}
		"web-service": #Service & {#config: config}
		"configmap": #ConfigMap & {#config: config}
		if config.existingSecret == "" {
			"config-secret": #ConfigSecret & {#config: config}
		}
		if config.superuser.existingSecret == "" {
			"superuser-secret": #SuperuserSecret & {#config: config}
		}
		if config.externalDatabase.existingSecretName == "" {
			"postgresql-secret": #PostgresqlSecret & {#config: config}
		}
		if config.postgresql.enabled {
			"postgresql-service":  #PostgresQLService & {#config: config}
			"postgresql-headless": #PostgresQLHeadlessService & {#config: config}
			"postgresql-sts":      #PostgresQLStatefulSet & {#config: config}
		}
		if config.tasksDatabase.existingSecretName == "" || config.cachingDatabase.existingSecretName == "" {
			"valkey-secret": #ValkeySecret & {#config: config}
		}
		if config.valkey.enabled {
			"valkey-service":  #ValkeyService & {#config: config}
			"valkey-headless": #ValkeyHeadlessService & {#config: config}
			"valkey-sts":      #ValkeyStatefulSet & {#config: config}
			if config.valkey.replicaCount > 0 {
				"valkey-replicas-service": #ValkeyReplicasService & {#config: config}
				"valkey-replicas-sts":     #ValkeyReplicasStatefulSet & {#config: config}
			}
		}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			"media-pvc": #MediaPVC & {#config: config}
		}
		if config.reportsPersistence.enabled && config.reportsPersistence.existingClaim == "" {
			"reports-pvc": #ReportsPVC & {#config: config}
		}
		if config.scriptsPersistence.enabled && config.scriptsPersistence.existingClaim == "" {
			"scripts-pvc": #ScriptsPVC & {#config: config}
		}
		if config.ingress.enabled {
			"ingress": #Ingress & {#config: config}
		}
		if config.httpRoute.enabled {
			"httproute": #HTTPRoute & {#config: config}
		}
		if config.autoscaling.enabled {
			"web-hpa": #HPA & {#config: config}
		}
		if config.pdb.enabled {
			"web-pdb": #PDB & {#config: config}
		}
		if config.serviceAccount.create {
			"serviceaccount": #ServiceAccount & {#config: config}
		}
		if config.rbac.create {
			"role": #Role & {#config: config}
			"rolebinding": #RoleBinding & {#config: config}
		}
		if config.worker.enabled {
			"worker-deployment": #WorkerDeployment & {#config: config}
			if config.worker.autoscaling.enabled {
				"worker-hpa": #WorkerHPA & {#config: config}
			}
			if config.worker.pdb.enabled {
				"worker-pdb": #WorkerPDB & {#config: config}
			}
		}
		if config.housekeeping.enabled {
			"cronjob": #CronJob & {#config: config}
		}
		if config.metrics.serviceMonitor.enabled {
			"servicemonitor": #ServiceMonitor & {#config: config}
		}
		if config.metrics.granian.serviceMonitor.enabled {
			"granian-servicemonitor": #GranianServiceMonitor & {#config: config}
		}

		for i, obj in config.extraDeploy {
			"extra-\(i)": obj
		}
	}

	tests: {
		if config.test.enabled {
			"test-connection": #TestConnection & {#config: config}
		}
	}
}
