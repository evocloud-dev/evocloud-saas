package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Type aliases for map fields.
#StringMap: {[string]: string}
#AnyMap: {[string]: _}

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

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     *{} | #StringMap

	#appName:            string
	#serviceName:        string
	#contentClaimName:   string
	#dbHost:             string
	#dbPort:             string
	#dbName:             string
	#dbUsername:          string
	#dbSecretName:       string
	#dbSecretPasswordKey: string
	#serviceAccountName: string

	if nameOverride == "" {
		#appName: "ghost"
	}
	if nameOverride != "" {
		#appName: nameOverride
	}
	if fullnameOverride == "" {
		#serviceName: metadata.name
	}
	if fullnameOverride != "" {
		#serviceName: fullnameOverride
	}
	if persistence.existingClaim == "" {
		#contentClaimName: "\(#serviceName)-content"
	}
	if persistence.existingClaim != "" {
		#contentClaimName: persistence.existingClaim
	}

	// The selector labels for Deployments and Services.
	// Uses the Helm convention: app.kubernetes.io/name = chart name (#appName).
	selector: labels: timoniv1.#Labels & {
		"app.kubernetes.io/name":     #appName
		"app.kubernetes.io/instance": metadata.name
	}

	// Full resource labels: selector labels + informational labels.
	labels: selector.labels & commonLabels & {
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/part-of":    "helmforge"
		"app.kubernetes.io/managed-by": "timoni"
	}

	image: {
		repository: *"docker.io/library/ghost" | string
		tag:        *"6.51.0" | string
		pullPolicy: *"IfNotPresent" | string
		reference:  "\(repository):\(tag)"
	}
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	ghost: {
		url:      *"" | string
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	database: external: {
		host:                      *"" | string
		port:                      *"3306" | string
		name:                      *"ghost" | string
		username:                  *"ghost" | string
		password:                  *"" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"password" | string
	}

	mysql: {
		enabled: *true | bool
		image: {
			repository: *"docker.io/library/mysql" | string
			tag:        *"8.4.7" | string
			pullPolicy: *"IfNotPresent" | string
		}
		architecture: *"standalone" | string
		auth: {
			database: *"ghost" | string
			username: *"ghost" | string
			password: *"" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
			resources: *{
				requests: {cpu: "100m", memory: "256Mi"}
				limits: {cpu: "500m", memory: "768Mi"}
			} | corev1.#ResourceRequirements
		}
	}

	if !mysql.enabled {
		#dbHost: database.external.host
	}
	if mysql.enabled {
		#dbHost: "\(metadata.name)-mysql"
	}
	if !mysql.enabled {
		#dbPort: database.external.port
	}
	if mysql.enabled {
		#dbPort: "3306"
	}
	if !mysql.enabled {
		#dbName: database.external.name
	}
	if mysql.enabled {
		#dbName: mysql.auth.database
	}
	if !mysql.enabled {
		#dbUsername: database.external.username
	}
	if mysql.enabled {
		#dbUsername: mysql.auth.username
	}
	if mysql.enabled {
		#dbSecretName: "\(metadata.name)-mysql-auth"
	}
	if !mysql.enabled && database.external.existingSecret == "" {
		#dbSecretName: "\(#serviceName)-db"
	}
	if !mysql.enabled && database.external.existingSecret != "" {
		#dbSecretName: database.external.existingSecret
	}
	if mysql.enabled {
		#dbSecretPasswordKey: "mysql-user-password"
	}
	if !mysql.enabled && database.external.existingSecret == "" {
		#dbSecretPasswordKey: "password"
	}
	if !mysql.enabled && database.external.existingSecret != "" {
		#dbSecretPasswordKey: database.external.existingSecretPasswordKey
	}

	persistence: {
		enabled:       *true | bool
		size:          *"10Gi" | string
		storageClass:  *"" | string
		accessModes:   *["ReadWriteOnce"] | [...string]
		existingClaim: *"" | string
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Forbid" | "Replace" | "Allow"
		successfulJobsHistoryLimit: *3 | int & >=0
		failedJobsHistoryLimit:     *3 | int & >=0
		backoffLimit:               *1 | int & >=0
		archivePrefix:              *"ghost" | string
		images: {
			backup:   *"docker.io/library/busybox:1.37" | string
			uploader: *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: *{} | corev1.#ResourceRequirements
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"ghost" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
		#secretName: string
		if s3.existingSecret == "" {
			#secretName: "\(#serviceName)-backup"
		}
		if s3.existingSecret != "" {
			#secretName: s3.existingSecret
		}
	}

	serviceAccount: {
		create:                       *false | bool
		name:                         *"" | string
		annotations:                  *{} | #StringMap
		automountServiceAccountToken: *false | bool
	}
	if !serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: "default"
	}
	if serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: #serviceName
	}

	service: {
		type:           *"ClusterIP" | string
		port:           *80 | int & >0 & <=65535
		annotations:    *{} | #StringMap
		ipFamilyPolicy: *"" | string
		ipFamilies:     *[] | [...string]
	}

	ingress: {
		enabled:          *false | bool
		ingressClassName: *"traefik" | string
		annotations:      *{} | #StringMap
		hosts: *[] | [...{
			host: string
			paths: *[{path: "/", pathType: "Prefix"}] | [...{
				path:     string
				pathType: *"Prefix" | string
			}]
		}]
		tls: *[] | [...{
			hosts: [...string]
			secretName: string
		}]
	}

	gateway: {
		enabled:     *false | bool
		annotations: *{} | #StringMap
		parentRefs:  *[] | [...#AnyMap]
		hostnames:   *[] | [...string]
		path:        *"/" | string
		pathType:    *"PathPrefix" | string
	}

	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"0" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | string
		}
		target: creationPolicy: *"Owner" | string
		data: *[] | [...#AnyMap]
	}

	probes: {
		startup:   #Probe & {enabled: *true | bool, path: *"/ghost/api/admin/site/" | string, initialDelaySeconds: *15 | int}
		liveness:  #Probe & {enabled: *true | bool, path: *"/ghost/api/admin/site/" | string, periodSeconds: *15 | int}
		readiness: #Probe & {enabled: *true | bool, path: *"/ghost/api/admin/site/" | string, periodSeconds: *10 | int}
	}

	resources: *{
		requests: {cpu: "100m", memory: "256Mi"}
		limits: {cpu: "500m", memory: "768Mi"}
	} | corev1.#ResourceRequirements
	waitForDatabase: resources: *{
		requests: {cpu: "10m", memory: "16Mi"}
		limits: {cpu: "100m", memory: "64Mi"}
	} | corev1.#ResourceRequirements

	podSecurityContext: *{seccompProfile: type: "RuntimeDefault"} | corev1.#PodSecurityContext
	securityContext: *{
		allowPrivilegeEscalation: false
		privileged:               false
	} | corev1.#SecurityContext

	nodeSelector:                  *{} | #StringMap
	tolerations:                   *[] | [...corev1.#Toleration]
	affinity:                      *{} | corev1.#Affinity
	topologySpreadConstraints:     *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int & >=0
	podLabels:                     *{} | #StringMap
	podAnnotations:                *{} | #StringMap
	extraVolumes:                  *[] | [...corev1.#Volume]
	extraVolumeMounts:             *[] | [...corev1.#VolumeMount]
	extraManifests:                *[] | [...#AnyMap]

	test: enabled: *false | bool
}

#Probe: {
	enabled:             bool
	path:                string
	initialDelaySeconds: *0 | int & >=0
	periodSeconds:       *5 | int & >0
	timeoutSeconds:      *3 | int & >0
	failureThreshold:    *3 | int & >0
}

// #ProbeSpec converts a #Probe into a Kubernetes httpGet probe.
#ProbeSpec: {
	#probe: #Probe
	httpGet: {
		path: #probe.path
		port: "http"
	}
	initialDelaySeconds: #probe.initialDelaySeconds
	periodSeconds:       #probe.periodSeconds
	timeoutSeconds:      #probe.timeoutSeconds
	failureThreshold:    #probe.failureThreshold
}

#Instance: {
	config: #Config

	objects: {
		service: #Service & {#config: config}
		deployment: #Deployment & {#config: config}

		if config.serviceAccount.create {
			serviceAccount: #ServiceAccount & {#config: config}
		}
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if !config.mysql.enabled && config.database.external.existingSecret == "" && config.database.external.password != "" {
			databaseSecret: #DatabaseSecret & {#config: config}
		}
		if config.mysql.enabled {
			mysqlSecret:          #MySQLSecret & {#config: config}
			mysqlService:         #MySQLService & {#config: config}
			mysqlHeadlessService: #MySQLHeadlessService & {#config: config}
			mysqlStatefulSet:     #MySQLStatefulSet & {#config: config}
		}
		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.gateway.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}
		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecret & {#config: config}
		}
		if config.backup.enabled {
			backupConfigMap: #BackupConfigMap & {#config: config}
			backupCronJob:   #BackupCronJob & {#config: config}
			if config.backup.s3.existingSecret == "" {
				backupSecret: #BackupSecret & {#config: config}
			}
		}
		for i, manifest in config.extraManifests {
			"extra-\(i)": manifest
		}
	}

	tests: {}
}
