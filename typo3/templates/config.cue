package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// -- Provide a name in place of `typo3`
	nameOverride: *"" | string
	// -- String to fully override `"typo3.fullname"`
	fullnameOverride: *"" | string

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

	#appName:     *"typo3" | string
	#serviceName: metadata.name
	if fullnameOverride != "" {
		#serviceName: fullnameOverride
	}

	image: {
		registry:   *"docker.io" | string
		repository: *"martinhelmich/typo3" | string
		pullPolicy: *"Always" | string
		tag:        *"12.4" | string
		digest:     *"" | string
		reference:  *"\(registry)/\(repository):\(tag)" | string
		if digest != "" {
			reference: *"\(registry)/\(repository)@\(digest)" | string
		}
	}

	message?: string

	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	replicaCount: *1 | int & >0
	revisionHistoryLimit: *10 | int & >=0

	serviceAccount: {
		create:      *true | bool
		annotations: *{} | #StringMap
		name:        *"" | string
	}
	#serviceAccountName: "\(metadata.name)"
	if serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if !serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: "default"
	}

	podAnnotations:     *{} | #StringMap
	podSecurityContext: *{} | corev1.#PodSecurityContext
	securityContext:    *{} | corev1.#SecurityContext
	resources:          *{} | corev1.#ResourceRequirements
	automountServiceAccountToken: *false | bool

	service: {
		type: *"ClusterIP" | string
		port: *8080 | int & >0 & <=65535
	}

	ingress: {
		enabled:     *false | bool
		className:   *"" | string
		annotations: *{} | #StringMap
		hosts: *[{
			host: "chart-example.local"
			paths: [{
				path:     "/"
				pathType: "ImplementationSpecific"
			}]
		}] | [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"ImplementationSpecific" | string
			}]
		}]
		tls: *[] | [...{
			secretName: string
			hosts: [...string]
		}]
	}

	route: [string]: {
		enabled:       *false | bool
		apiVersion:    *"gateway.networking.k8s.io/v1" | string
		kind:          *"HTTPRoute" | string
		annotations:   *{} | #StringMap
		labels:        *{} | #StringMap
		hostnames:     *[] | [...string]
		parentRefs:    *[] | [...#AnyMap]
		matches:       *[{path: {type: "PathPrefix", value: "/"}}] | [...#AnyMap]
		filters:       *[] | [...#AnyMap]
		additionalRules: *[] | [...#AnyMap]
		httpsRedirect: *false | bool
		timeouts:      *{} | #AnyMap
	}
	route: main: {}

	autoscaling: {
		enabled: *false | bool
		minReplicas: *1 | int & >0
		maxReplicas: *100 | int & >0
		targetCPUUtilizationPercentage?: int & >0 & <=100
		targetMemoryUtilizationPercentage?: int & >0 & <=100
	}
	autoscaling: targetCPUUtilizationPercentage: *80 | int

	deploymentStrategy: *{} | #AnyMap
	nodeSelector:       *{} | #StringMap
	tolerations:        *[] | [...corev1.#Toleration]
	affinity:           *{} | corev1.#Affinity

	persistence: {
		fileadmin: #Persistence & { enabled: *false | bool }
		typo3conf: #Persistence & { enabled: *false | bool }
	}

	mysql: #DatabaseChart & {
		enabled: *true | bool
		image: {
			repository: *"bitnamilegacy/mysql" | string
			tag:        *"9.4.0-debian-12-r1" | string
		}
	}
	mariadb: #DatabaseChart & {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/mariadb" | string
			tag:        *"12.0.2-debian-12-r0" | string
		}
	}
	postgresql: #DatabaseChart & {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/postgresql" | string
			tag:        *"17.6.0-debian-12-r4" | string
		}
	}
	externalDatabase: {
		auth: {
			database:        *"typo3" | string
			existingSecret:  *"" | string
			password:        *"typo3" | string
			username:        *"typo3" | string
			userPasswordKey: *"password" | string
		}
		hostname: *"" | string
		port:     *3306 | int & >0 & <=65535
		type:     *"mysql" | string
	}

	#databaseSecretName: "\(metadata.name)-database"
	#databasePasswordKey: externalDatabase.auth.userPasswordKey

	test: {
		enabled: *false | bool
		image: {
			registry:   *"" | string
			repository: *"curlimages/curl" | string
			tag:        *"latest" | string
			digest:     *"" | string
			reference:  *"\(repository):\(tag)" | string
			if registry != "" {
				reference: *"\(registry)/\(repository):\(tag)" | string
			}
		}
	}
}

#StringMap: {[string]: string}
#AnyMap: {[string]: _}

#Persistence: {
	enabled:          bool
	accessModes:      *["ReadWriteOnce"] | [...string]
	annotations:      *{} | #StringMap
	existingClaim:     *"" | string
	storageClassName:  *"" | string
	resources:         corev1.#ResourceRequirements & {
		requests: {
			storage: *"8Gi" | string
		}
	}
}

#DatabaseChart: {
	enabled: bool
	auth: {
		database:       *"typo3" | string
		existingSecret: *"" | string
		password:       *"typo3" | string
		username:       *"typo3" | string
	}
	image: {
		repository: string
		tag:        string
	}
	persistence: #Persistence & {
		enabled: *true | bool
	}
	test: {
		enabled: *false | bool
	}
}

#Instance: {
	config: #Config

	objects: [
		if config.serviceAccount.create {#ServiceAccount & {#config: config}},
		#Service & {#config: config},
		#Deployment & {#config: config},
		if config.autoscaling.enabled {#HorizontalPodAutoscaler & {#config: config}},
		if config.ingress.enabled {#Ingress & {#config: config}},
		if config.persistence.fileadmin.enabled && config.persistence.fileadmin.existingClaim == "" {
			#PVCFileadmin & {#config: config}
		},
		if config.persistence.typo3conf.enabled && config.persistence.typo3conf.existingClaim == "" {
			#PVCTypo3conf & {#config: config}
		},
		if !config.mysql.enabled && !config.mariadb.enabled && !config.postgresql.enabled && config.externalDatabase.auth.existingSecret == "" {
			#DatabaseSecret & {#config: config}
		},
		for obj in (#MySQL & {#config: config}).objects if config.mysql.enabled {
			obj
		},
		for obj in (#MariaDB & {#config: config}).objects if config.mariadb.enabled {
			obj
		},
		for obj in (#PostgreSQL & {#config: config}).objects if config.postgresql.enabled {
			obj
		},
		for name, route in config.route if route.enabled {
			#HTTPRoute & {#config: config, #routeName: name, #route: route}
		},
	]

	tests: []
}