package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"uuid"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values, mirroring Helm values.yaml.
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
	appVersion: *"7.7.0.1" | string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels
	metadata: labels: "app.kubernetes.io/instance": metadata.name

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}
	selector: labels: "app.kubernetes.io/instance": metadata.name

	// -- (int) Numbers of replicas
	replicaCount: *1 | int32 & >=0
	replicas:     *replicaCount | int32 & >=0

	// The image allows setting the container image repository, tag, digest and pull policy.
	image: timoniv1.#Image & {
		repository: *"adamzammit/limesurvey" | string
		tag:        *"7.7.0.1" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}

	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	deployment: {
		updateStrategy?: appsv1.#DeploymentStrategy
		lifecycleHooks?: corev1.#Lifecycle
	}

	serviceAccount: {
		create:      *false | bool
		annotations: *{} | #StringMap
		name:        *"" | string
	}

	automountServiceAccountToken: *false | bool

	podAnnotations:               *{} | #StringMap
	podSecurityContext:           *{} | corev1.#PodSecurityContext
	initContainerSecurityContext: *{} | corev1.#SecurityContext
	securityContext:              *{} | corev1.#SecurityContext

	service: {
		type:         *"ClusterIP" | "ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
		port:         *80 | int32 & >0 & <=65535
		annotations?: timoniv1.#Annotations
	}

	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes: *[] | [...#HTTPRouteItem]
	}

	limesurvey: {
		admin: {
			name:           *"Lime Administrator" | string
			email:          *"lime@lime.lime" | string
			username:       *"admin" | string
			password:       *"" | string
			existingSecret: *"" | string
		}
		smtp: {
			host:           *"" | string
			user:           *"" | string
			password:       *"" | string
			existingSecret: *"" | string
			ssl:            *"" | string
			from_email:     *"your-email@example.net" | string
			debug:          *"" | string
		}
		tablePrefix:           *"lime_" | string
		debug:                 *"0" | string
		sqlDebug:              *"0" | string
		useInnodb:             *"true" | string
		dbSessions:            *"" | string
		phpSessionSaveHandler: *"" | string
		phpSessionSavePath:    *"" | string
		dontShowScriptName:    *"" | string
		dontUpdate:            *"" | string
		tz:                    *"Europe/Berlin" | string
		apiMode:               *"off" | string

		startupProbe:   #ProbeConfig
		livenessProbe:  #ProbeConfig
		readinessProbe: #ProbeConfig
	}

	persistence: {
		enabled:      *true | bool
		storageClass: *null | string
		accessModes:  *["ReadWriteOnce"] | [...string]
		size:         *"5Gi" | string
		annotations: *{
			"helm.sh/resource-policy": "keep"
		} | #StringMap
		finalizers: *[
			"kubernetes.io/pvc-protection",
		] | [...string]
		selectorLabels: *{} | #StringMap
		existingClaim:  *null | string
	}

	extraDeploy:         *[] | [...#AnyMap]
	extraVolumeMounts:   *[] | [...#ExtraVolumeMount]
	extraEmptyDirMounts: *[] | [...#ExtraEmptyDirMount]

	mariadb: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/bitnamilegacy/mariadb" | string
			tag:        *"12.0.2-debian-12-r0" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		auth: {
			database:       *"limesurvey" | string
			username:       *"limesurvey" | string
			password:       *"changeme" | string
			rootPassword:   *"" | string
			existingSecret: *"" | string
		}
		architecture: *"standalone" | string
		primary: {
			service: {
				port: *3306 | int32 & >0 & <=65535
				ports: {
					mysql: *3306 | int32 & >0 & <=65535
				}
			}
			persistence: {
				enabled:       *true | bool
				existingClaim: *"" | string
				storageClass:  *"" | string
				accessMode:    *"ReadWriteOnce" | string
				size:          *"8Gi" | string
			}
			resourcesPreset: *"none" | string
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
			podSecurityContext: {
				fsGroup?:             *1001 | int
				fsGroupChangePolicy?: *"Always" | string
				supplementalGroups?:  *[] | [...int]
				sysctls?:             *[] | [...corev1.#Sysctl]
			}
			containerSecurityContext: {
				allowPrivilegeEscalation?: *false | bool
				capabilities?: {
					drop?: *["ALL"] | [...string]
					add?:  *[] | [...string]
				}
				privileged?:             *false | bool
				readOnlyRootFilesystem?: *true | bool
				runAsGroup?:             *1001 | int
				runAsNonRoot?:           *true | bool
				runAsUser?:              *1001 | int
				seLinuxOptions?:         *{} | #AnyMap
				seccompProfile?: {
					type?: *"RuntimeDefault" | string
				}
			}
		}
	}

	externalDatabase: {
		type:           *"mysql" | string
		host:           *"mariadb.example.com" | string
		port:           *3306 | int32 & >0 & <=65535
		username:       *"limesurvey" | string
		password:       *"" | string
		database:       *"limesurvey" | string
		existingSecret: *"" | string
	}

	resources: *{
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
	} | corev1.#ResourceRequirements

	autoscaling: {
		enabled:                            *false | bool
		minReplicas:                        *1 | int32 & >=1
		maxReplicas:                        *100 | int32 & >=1
		targetCPUUtilizationPercentage:     *80 | int32 & >0
		targetMemoryUtilizationPercentage?: int32 & >0
	}

	nodeSelector:              *{} | #StringMap
	tolerations:               *[] | [...corev1.#Toleration]
	affinity:                  *{} | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]

	// =========================================================================
	// Central computed helper fields (mirroring _helpers.tpl and chart logic)
	// =========================================================================

	#appName:         string
	#serviceName:     string
	#mariadbFullname: "\(metadata.name)-mariadb"
	#imageReference:  string

	#serviceAccountName:  string
	#databaseSecretName:  string
	#secretName:          string
	#smtpSecretName:      string
	#pvcClaimName:        string
	#adminPassword:       string
	#smtpPassword:        string
	#mariadbRootPassword: string

	#dbType: string
	#dbHost: string
	#dbPort: string
	#dbUser: string
	#dbName: string

	if nameOverride == "" {
		#appName: "limesurvey"
	}
	if nameOverride != "" {
		#appName: nameOverride
	}

	if fullnameOverride != "" {
		#serviceName: fullnameOverride
	}
	if fullnameOverride == "" {
		if nameOverride != "" && !strings.Contains(metadata.name, nameOverride) {
			#serviceName: "\(metadata.name)-\(nameOverride)"
		}
		if nameOverride == "" || strings.Contains(metadata.name, nameOverride) {
			#serviceName: metadata.name
		}
	}

	if image.tag == "" && image.digest == "" {
		#imageReference: "\(image.repository):\(appVersion)"
	}
	if image.tag != "" || image.digest != "" {
		#imageReference: image.reference
	}

	if serviceAccount.create && serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: #serviceName
	}
	if !serviceAccount.create && serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if !serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: "default"
	}

	if mariadb.enabled && mariadb.auth.existingSecret != "" {
		#databaseSecretName: mariadb.auth.existingSecret
	}
	if mariadb.enabled && mariadb.auth.existingSecret == "" {
		#databaseSecretName: #mariadbFullname
	}
	if !mariadb.enabled && externalDatabase.existingSecret != "" {
		#databaseSecretName: externalDatabase.existingSecret
	}
	if !mariadb.enabled && externalDatabase.existingSecret == "" {
		#databaseSecretName: "\(#serviceName)-mariadb"
	}

	if limesurvey.admin.existingSecret != "" {
		#secretName: limesurvey.admin.existingSecret
	}
	if limesurvey.admin.existingSecret == "" {
		#secretName: #serviceName
	}

	if limesurvey.smtp.existingSecret != "" {
		#smtpSecretName: limesurvey.smtp.existingSecret
	}
	if limesurvey.smtp.existingSecret == "" {
		#smtpSecretName: "\(#serviceName)-smtp"
	}

	if persistence.existingClaim != null && persistence.existingClaim != "" {
		#pvcClaimName: persistence.existingClaim
	}
	if persistence.existingClaim == null || persistence.existingClaim == "" {
		#pvcClaimName: #serviceName
	}

	if limesurvey.admin.password != "" {
		#adminPassword: limesurvey.admin.password
	}
	if limesurvey.admin.password == "" {
		#adminPassword: strings.SliceRunes(strings.Replace(uuid.SHA1(uuid.ns.DNS, "\(metadata.namespace)/\(#secretName)/admin"), "-", "", -1), 0, 15)
	}

	if limesurvey.smtp.password != "" {
		#smtpPassword: limesurvey.smtp.password
	}
	if limesurvey.smtp.password == "" {
		#smtpPassword: strings.SliceRunes(strings.Replace(uuid.SHA1(uuid.ns.DNS, "\(metadata.namespace)/\(#smtpSecretName)/smtp"), "-", "", -1), 0, 15)
	}

	if mariadb.auth.rootPassword != "" {
		#mariadbRootPassword: mariadb.auth.rootPassword
	}
	if mariadb.auth.rootPassword == "" {
		#mariadbRootPassword: strings.SliceRunes(strings.Replace(uuid.SHA1(uuid.ns.DNS, "\(metadata.namespace)/\(#mariadbFullname)/root"), "-", "", -1), 0, 10)
	}

	if mariadb.enabled {
		#dbType: "mysql"
		#dbHost: #mariadbFullname
		#dbPort: "\(mariadb.primary.service.ports.mysql)"
		#dbUser: mariadb.auth.username
		#dbName: mariadb.auth.database
	}
	if !mariadb.enabled {
		#dbType: externalDatabase.type
		#dbHost: externalDatabase.host
		#dbPort: "\(externalDatabase.port)"
		#dbUser: externalDatabase.username
		#dbName: externalDatabase.database
	}

	#mariadbLabels: {
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/name":       "mariadb"
		"app.kubernetes.io/version":    "12.0.2"
		"app.kubernetes.io/part-of":    "mariadb"
	}

	#mariadbPrimaryLabels: {
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/name":       "mariadb"
		"app.kubernetes.io/version":    "12.0.2"
		"app.kubernetes.io/part-of":    "mariadb"
		"app.kubernetes.io/component":  "primary"
	}

	#mariadbMyCnf: """
		[mysqld]
		skip-name-resolve
		explicit_defaults_for_timestamp
		basedir=/opt/bitnami/mariadb
		datadir=/bitnami/mariadb/data
		plugin_dir=/opt/bitnami/mariadb/plugin
		port=3306
		socket=/opt/bitnami/mariadb/tmp/mysql.sock
		tmpdir=/opt/bitnami/mariadb/tmp
		max_allowed_packet=16M
		bind-address=*
		pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
		log-error=/opt/bitnami/mariadb/logs/mysqld.log
		character-set-server=UTF8
		collation-server=utf8_general_ci
		slow_query_log=0
		long_query_time=10.0
		binlog_expire_logs_seconds=2592000

		[client]
		port=3306
		socket=/opt/bitnami/mariadb/tmp/mysql.sock
		default-character-set=UTF8
		plugin_dir=/opt/bitnami/mariadb/plugin

		[manager]
		port=3306
		socket=/opt/bitnami/mariadb/tmp/mysql.sock
		pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
		"""

	#mariadbConfigChecksum: hex.Encode(sha256.Sum256(#mariadbMyCnf))
}

// Type aliases and sub-schemas.
#StringMap: {[string]: string}
#AnyMap:    {[string]: _}

#ProbeConfig: {
	enabled: *true | bool
	httpGet: {
		path: *"/" | string
		port: *"http" | string | int
		httpHeaders?: [...{
			name:  string
			value: string
		}]
	}
	initialDelaySeconds: *0 | int32
	periodSeconds:       *10 | int32
	timeoutSeconds:      *1 | int32
	successThreshold:    *1 | int32
	failureThreshold:    *3 | int32
}

#ExtraVolumeMount: {
	name:          string
	mountPath:     string
	subPath:       *"" | string
	readOnly?:     bool
	existingClaim: *"" | string
	hostPath:      *"" | string
	configMap:     *"" | string
	items?: [...corev1.#KeyToPath]
}

#ExtraEmptyDirMount: {
	name:      string
	mountPath: string
}

#HTTPRouteParentRef: {
	name!:       string
	group:       *"" | string
	kind:        *"" | string
	namespace:   *"" | string
	sectionName: *"" | string
	port:        *0 | int
}

#HTTPRouteRule: {
	matches?: [...]
	filters?: [...]
	backendRefs?: [...]
	omitDefaultBackend: *false | bool
}

#HTTPRouteItem: {
	name: *"" | string
	labels?: #StringMap
	annotations?: #StringMap
	parentRefs!: [...#HTTPRouteParentRef] & [_, ...]
	hostnames: *[] | [...string]
	rules: *[] | [...#HTTPRouteRule]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.mariadb.enabled {
			"mariadb-networkpolicy": #MariaDBNetworkPolicy & {#config: config}
			"mariadb-pdb":           #MariaDBPodDisruptionBudget & {#config: config}
			"mariadb-sa":            #MariaDBServiceAccount & {#config: config}
			if config.mariadb.auth.existingSecret == "" {
				"mariadb-secret": #MariaDBSecret & {#config: config}
			}
		}

		if config.limesurvey.admin.existingSecret == "" {
			"admin-secret": #AdminSecret & {#config: config}
		}

		if !config.mariadb.enabled && config.externalDatabase.existingSecret == "" {
			"external-db-secret": #ExternalDatabaseSecret & {#config: config}
		}

		if config.limesurvey.smtp.existingSecret == "" {
			"smtp-secret": #SmtpSecret & {#config: config}
		}

		if config.mariadb.enabled {
			"mariadb-configmap": #MariaDBConfigMap & {#config: config}
		}

		if config.persistence.enabled && (config.persistence.existingClaim == null || config.persistence.existingClaim == "") {
			pvc: #PersistentVolumeClaim & {#config: config}
		}

		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		if config.mariadb.enabled {
			"mariadb-headless-svc": #MariaDBHeadlessService & {#config: config}
			"mariadb-svc":          #MariaDBService & {#config: config}
		}

		svc:    #Service & {#config: config}
		deploy: #Deployment & {#config: config}

		if config.mariadb.enabled {
			"mariadb-statefulset": #MariaDBStatefulSet & {#config: config}
		}

		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {
					#config: config
					#route:  r
					#index:  i
				}
			}
		}

		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}

		for i, extra in config.extraDeploy {
			"extra-\(i)": extra
		}
	}

	tests: {}
}
