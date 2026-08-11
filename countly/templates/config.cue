package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	hostname:         *"localhost" | string

	api: {
		image: {
			registry:   string
			repository: string
			tag:        string
			pullPolicy: *"Always" | "IfNotPresent" | "Never"
		}
		imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
		podAnnotations: {[string]: string} | *{}
		podSecurityContext?: corev1.#PodSecurityContext
		priorityClassName:    *"" | string
		replicaCount:         *1 | int & >=0
		revisionHistoryLimit: *10 | int & >=0
		resources?:            timoniv1.#ResourceRequirements
		securityContext?:      corev1.#SecurityContext
		serviceAccount: {
			create:      *true | bool
			annotations: {[string]: string} | *{}
			name:        *"" | string
		}
		service: {
			type: *"ClusterIP" | string
			port: *3000 | int & >0
		}
		route: {
			main: {
				enabled:      *false | bool
				apiVersion:   *"gateway.networking.k8s.io/v1" | string
				kind:         *"HTTPRoute" | string
				annotations?: {[string]: string}
				labels?:      {[string]: string}
				hostnames?: [...string]
				parentRefs?: [...{name: string, namespace?: string}] | *[]
				matches: [...{
					path?: {
						type?:  string
						value?: string
					}
				}] | *[]
				filters?:         [...]
				additionalRules?: [...]
				httpsRedirect:   *false | bool
				timeouts?:        {...}
			}
		}
		autoscaling: {
			enabled:                           *false | bool
			minReplicas:                       *1 | int & >=1
			maxReplicas:                       *100 | int & >=1
			targetCPUUtilizationPercentage?:    int & >=1
			targetMemoryUtilizationPercentage?: int & >=1
		}
		livenessProbe: {
			failureThreshold:    *6 | int & >=1
			initialDelaySeconds: *60 | int & >=0
			periodSeconds:       *30 | int & >=1
			successThreshold:    *1 | int & >=1
			timeoutSeconds:      *2 | int & >=1
		}
		readinessProbe: {
			failureThreshold:    *6 | int & >=1
			initialDelaySeconds: *60 | int & >=0
			periodSeconds:       *30 | int & >=1
			successThreshold:    *1 | int & >=1
			timeoutSeconds:      *2 | int & >=1
		}
		nodeSelector: {[string]: string} | *{}
		tolerations: [...corev1.#Toleration] | *[]
		affinity?: corev1.#Affinity
		selectorLabels: {[string]: string} | *{}
		extraEnv: [...corev1.#EnvVar] | *[]
	}

	frontend: {
		image: {
			registry:   string
			repository: string
			tag:        string
			pullPolicy: *"Always" | "IfNotPresent" | "Never"
		}
		imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
		podAnnotations: {[string]: string} | *{}
		podSecurityContext?: corev1.#PodSecurityContext
		priorityClassName:    *"" | string
		replicaCount:         *1 | int & >=0
		revisionHistoryLimit: *10 | int & >=0
		resources?:            timoniv1.#ResourceRequirements
		securityContext?:      corev1.#SecurityContext
		serviceAccount: {
			create:      *true | bool
			annotations: {[string]: string} | *{}
			name:        *"" | string
		}
		service: {
			type: *"ClusterIP" | string
			port: *3000 | int & >0
		}
		route: {
			main: {
				enabled:      *false | bool
				apiVersion:   *"gateway.networking.k8s.io/v1" | string
				kind:         *"HTTPRoute" | string
				annotations?: {[string]: string}
				labels?:      {[string]: string}
				hostnames?: [...string]
				parentRefs?: [...{name: string, namespace?: string}] | *[]
				matches: [...{
					path?: {
						type?:  string
						value?: string
					}
				}] | *[]
				filters?:         [...]
				additionalRules?: [...]
				httpsRedirect:   *false | bool
				timeouts?:        {...}
			}
		}
		autoscaling: {
			enabled:                           *false | bool
			minReplicas:                       *1 | int & >=1
			maxReplicas:                       *100 | int & >=1
			targetCPUUtilizationPercentage?:    int & >=1
			targetMemoryUtilizationPercentage?: int & >=1
		}
		livenessProbe: {
			failureThreshold:    *6 | int & >=1
			initialDelaySeconds: *60 | int & >=0
			periodSeconds:       *30 | int & >=1
			successThreshold:    *1 | int & >=1
			timeoutSeconds:      *2 | int & >=1
		}
		readinessProbe: {
			failureThreshold:    *6 | int & >=1
			initialDelaySeconds: *60 | int & >=0
			periodSeconds:       *30 | int & >=1
			successThreshold:    *1 | int & >=1
			timeoutSeconds:      *2 | int & >=1
		}
		nodeSelector: {[string]: string} | *{}
		tolerations: [...corev1.#Toleration] | *[]
		affinity?: corev1.#Affinity
		selectorLabels: {[string]: string} | *{}
		extraEnv: [...corev1.#EnvVar] | *[]
	}

	extraEnv: [...corev1.#EnvVar] | *[]

	config: {
		api: {
			filestorage: *"gridfs" | string
			mail: {
				enabled: *false | bool
				auth: {
					existingSecret: *"" | string
					password:       *"" | string
					username:       *"" | string
				}
				from: *"" | string
				host: *"" | string
				port: *0 | int & >=0
			}
			workerCount: *"1" | string
		}
		nodeOptions: *"--max-old-space-size=2048" | string
		plugins:     string
	}

	mongodb: {
		enabled:      *true | bool
		architecture: *"standalone" | "replicaset"
		image: {
			registry:   *"docker.io" | string
			repository: *"library/mongo" | string
			tag:        *"7.0" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			enabled:  *false | bool
			database: *"countly" | string
			password: *"countly" | string
			username: *"countly" | string
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		resources?:          timoniv1.#ResourceRequirements
		useStatefulSet: *true | bool
	}

	externalMongodb: {
		auth: {
			database: *"countly" | string
		}
		hostname: *"" | string
		port:     *27017 | int & >0
	}
}

#Instance: {
	config: #Config

	objects: {
		if config.api.serviceAccount.create {
			saApi: #ServiceAccountApi & {#config: config}
		}
		svcApi: #ServiceApi & {#config: config}
		deployApi: #DeploymentApi & {#config: config}
		if config.api.route.main.enabled {
			routeApi: #RouteApi & {#config: config}
		}

		if config.frontend.serviceAccount.create {
			saFrontend: #ServiceAccountFrontend & {#config: config}
		}
		svcFrontend: #ServiceFrontend & {#config: config}
		deployFrontend: #DeploymentFrontend & {#config: config}
		if config.frontend.route.main.enabled {
			routeFrontend: #RouteFrontend & {#config: config}
		}

		if config.api.autoscaling.enabled {
			hpaApi: #HpaApi & {#config: config}
		}
		if config.frontend.autoscaling.enabled {
			hpaFrontend: #HpaFrontend & {#config: config}
		}

		if config.mongodb.enabled {
			mongodbSvc: #MongodbService & {#config: config}
			if config.mongodb.useStatefulSet {
				mongodbSts: #MongodbStatefulSet & {#config: config}
			}
			if !config.mongodb.useStatefulSet {
				mongodbDeploy: #MongodbDeployment & {#config: config}
			}
		}

		if config.config.api.mail.enabled && config.config.api.mail.auth.password != "" && config.config.api.mail.auth.existingSecret == "" {
			secretApi: #SecretApi & {#config: config}
		}
	}
}
