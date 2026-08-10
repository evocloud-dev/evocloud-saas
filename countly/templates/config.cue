package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	kubeVersion!: string
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

    fullname: string | *metadata.name
    image: timoniv1.#Image & {
		repository: *"docker.io/library/countly" | string
        tag:        *"3.12.0" | string
        digest:     *"" | string
        pullPolicy: *"IfNotPresent" | string
	}

	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"10m" | timoniv1.#CPUQuantity
			memory: *"32Mi" | timoniv1.#MemoryQuantity
		}
	}

	replicas: *1 | int & >0

	securityContext?: corev1.#SecurityContext

	serviceAccount: {
		create: *false | bool
		name: string
		annotations?: timoniv1.#Annotations
	}

	service: {
		annotations?: timoniv1.#Annotations
		type: *"ClusterIP" | string
		port: *80 | int & >0 & <=65535
		apiPort: *3001 | int & >0 & <=65535
		ipFamilyPolicy?: string
		ipFamilies?: [...string]
	}

	podAnnotations?: {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]
	nodeSelector?: {[string]: string}
	priorityClassName?: string
	terminationGracePeriodSeconds?: int
	podLabels?: {[string]: string}

	test: {
		enabled: *false | bool
	}

	countly: {
		apiPort: *3001 | int & >0 & <=65535
		dashboardPort: *6001 | int & >0 & <=65535
		apiWorkers: *4 | int & >0
		timezone: string
		plugins: string
		extraEnv?: [...corev1.#EnvVar]
	}

	externalMongodb: {
		enabled: *false | bool
		uri: string
		existingSecret: string
		existingSecretUriKey: string
	}

	ingress: {
		enabled: *false | bool
		ingressClassName: string
		annotations?: timoniv1.#Annotations
		hosts?: [...{ host?: string
			paths?: [...{ path?: string
				pathType?: string
			}]
		}]
		tls?: [...{ hosts: [...string]
			secretName: string
		}]
	}

	gateway: {
		enabled: *false | bool
		hostnames?: [...string]
		parentRefs?: [...{ name: string
			namespace?: string
		}]
	}

	externalSecrets: {
		enabled: *false | bool
		apiVersion: string
		refreshInterval: string
		secretStoreRef: {
			name: string
			kind: string
		}
		target: {
			creationPolicy: string
		}
		data?: [...]
	}

	backup: {
		enabled: *false | bool
		schedule: string
		suspend: bool
		concurrencyPolicy: string
		successfulJobsHistoryLimit: int
		failedJobsHistoryLimit: int
		backoffLimit: int
		archivePrefix: string
		images: {
			mongodb: string
			uploader: string
		}
		resources: timoniv1.#ResourceRequirements
		s3: {
			endpoint: string
			bucket: string
			prefix: string
			createBucketIfNotExists: bool
			existingSecret: string
			existingSecretAccessKeyKey: string
			existingSecretSecretKeyKey: string
			accessKey: string
			secretKey: string
		}
		database: {
			uri: string
			mongodumpArgs: string
		}
	}

	serviceAccountName: string
	if serviceAccount.name != "" {
		serviceAccountName: serviceAccount.name
	}
	if serviceAccount.name == "" {
		if serviceAccount.create {
			serviceAccountName: fullname
		}
		if !serviceAccount.create {
			serviceAccountName: "default"
		}
	}

	mongodb: {
		enabled: *false | bool
		image?: timoniv1.#Image & {
			repository: *"docker.io/library/mongo" | string
			tag:        *"7.0" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		extraEnvVars: [...corev1.#EnvVar] | *[]
		podSecurityContext: {} | {...}
		securityContext: {} | {...}
		podAnnotations: {[string]: string} | *{}
		resources: timoniv1.#ResourceRequirements | *{}
		...
	}

	mongodbHost: string | *""
	if mongodb.enabled {
		mongodbHost: "\(metadata.name)-mongodb"
	}

	mongodbSecretName: string | *""
	if externalMongodb.enabled && externalMongodb.existingSecret != "" {
		mongodbSecretName: externalMongodb.existingSecret
	}
	if !externalMongodb.enabled {
		mongodbSecretName: "\(metadata.name)-mongodb"
	}

	mongodbURI: string | *""
	if externalMongodb.enabled {
		mongodbURI: externalMongodb.uri
	}
	if !externalMongodb.enabled {
		mongodbURI: "mongodb://root:$(MONGODB_ROOT_PASSWORD)@\(metadata.name)-mongodb:27017/countly?authSource=admin"
	}

	backupSecretName: string | *""
	if backup.s3.existingSecret != "" {
		backupSecretName: backup.s3.existingSecret
	}
	if backup.s3.existingSecret == "" {
		backupSecretName: "\(fullname)-backup"
	}

	backupMongodbURI: string | *""
	if backup.database.uri != "" {
		backupMongodbURI: backup.database.uri
	}
	if backup.database.uri == "" && externalMongodb.enabled {
		backupMongodbURI: externalMongodb.uri
	}
	if backup.database.uri == "" && !externalMongodb.enabled {
		backupMongodbURI: "mongodb://root:$(MONGODB_ROOT_PASSWORD)@\(metadata.name)-mongodb:27017/countly?authSource=admin"
	}

	nameOverride?: string
	fullnameOverride?: string
	commonLabels?: {[string]: string}
	...
}

#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		svc: #Service & {#config: config}
		deploy: #Deployment & {#config: config}
		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.gateway.enabled {
			httproute: #HTTPRoute & {#config: config}
		}
		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecret & {#config: config}
		}
		if config.mongodb.enabled && !config.externalMongodb.enabled {
			mongodbSts: #MongodbStatefulSet & {#config: config}
			mongodbSvc: #MongodbService & {#config: config}
			if config.mongodb.auth.enabled {
				mongodbSecret: #MongodbSecret & {#config: config}
			}
		}
		if config.backup.enabled {
			backupScripts: #BackupScriptsConfigMap & {#config: config}
			backupCronJob: #BackupCronJob & {#config: config}
			if config.backup.s3.existingSecret == "" {
				backupSecret: #BackupSecret & {#config: config}
			}
		}
	}
}
