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
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	initMode: *true | bool

	configs: {
		image?: string
		seafileFrontendReplicas: *2 | int
		seafileDataVolume?: {
			disablePVC: *false | bool
			storage: *"10Gi" | string
			storageClassName?: string
		}
	}

	image: *"seafileltd/seafile-pro-mc:13.0-latest" | string
	initContainerImage: *"busybox@sha256:fd8d9aa63ba2f0982b5304e1ee8d3b90a210bc1ffb5314d980eb6962f1a9715d" | string
	imagePullSecrets: *[{name: "regcred"}] | [...timoniv1.#ObjectReference]

	env: {
		TIME_ZONE: *"" | string
		SEAFILE_LOG_TO_STDOUT: *"" | string
		SITE_ROOT: *"" | string
		SEAFILE_SERVER_HOSTNAME: *"" | string
		SEAFILE_SERVER_PROTOCOL: *"http" | string
		SEAFILE_MYSQL_DB_HOST: *"" | string
		SEAFILE_MYSQL_DB_PORT: *"" | string
		SEAFILE_MYSQL_DB_USER: *"" | string
		SEAFILE_MYSQL_DB_CCNET_DB_NAME: *"" | string
		SEAFILE_MYSQL_DB_SEAFILE_DB_NAME: *"" | string
		SEAFILE_MYSQL_DB_SEAHUB_DB_NAME: *"" | string
		CACHE_PROVIDER: *"" | string
		REDIS_HOST: *"" | string
		REDIS_PORT: *"" | string
		MEMCACHED_HOST: *"" | string
		MEMCACHED_PORT: *"" | string
		SEAF_SERVER_STORAGE_TYPE: *"" | string
		S3_COMMIT_BUCKET: *"" | string
		S3_FS_BUCKET: *"" | string
		S3_BLOCK_BUCKET: *"" | string
		S3_KEY_ID: *"" | string
		S3_USE_V4_SIGNATURE: *"" | string
		S3_AWS_REGION: *"" | string
		S3_HOST: *"" | string
		S3_USE_HTTPS: *"" | string
		S3_PATH_STYLE_REQUEST: *"" | string
		ENABLE_NOTIFICATION_SERVER: *"" | string
		NOTIFICATION_SERVER_URL: *"" | string
		ENABLE_SEAFILE_AI: *"" | string
		ENABLE_FACE_RECOGNITION: *"" | string
		SEAFILE_AI_SERVER_URL: *"" | string
		MD_FILE_COUNT_LIMIT: *"" | string
		ENABLE_SEADOC: *"" | string
		SEADOC_SERVER_URL: *"" | string
		INIT_SEAFILE_ADMIN_EMAIL: *"" | string
		CLUSTER_INIT_ES_HOST: *"" | string
		CLUSTER_INIT_ES_PORT: *"" | string
		[string]: string
	}
	secretsMap: *{} | {[string]: string}

	extraEnv: {
		frontend: [...corev1.#EnvVar]
		backend: [...corev1.#EnvVar]
	}
	extraVolumes: {
		frontend: [...#ExtraVolume]
		backend: [...#ExtraVolume]
	}
	extraResources: {
		frontend: *{} | corev1.#ResourceRequirements
		backend: *{} | corev1.#ResourceRequirements
	}

	service: {
		type: *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port: *80 | int & >0 & <=65535
		targetPort: *80 | int & >0 & <=65535
		annotations?: timoniv1.#Annotations
	}

	podAnnotations?: timoniv1.#Annotations
	podLabels?: {[string]: string}
	nodeSelector?: {[string]: string}
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity

	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?: corev1.#SecurityContext
	serviceAccountName?: string
	automountServiceAccountToken?: bool

	test: {
		enabled: *false | bool
	}

	#dataVolumeEnabled: !((configs.seafileDataVolume.disablePVC | false) == true)
	#dataVolumeStorage: configs.seafileDataVolume.storage | "10Gi"

	#envData: {
		if env.TIME_ZONE != "" && env.TIME_ZONE != "<required>" {TIME_ZONE: env.TIME_ZONE}
		if env.TIME_ZONE == "" || env.TIME_ZONE == "<required>" {TIME_ZONE: "UTC"}
		if env.SEAFILE_LOG_TO_STDOUT != "" && env.SEAFILE_LOG_TO_STDOUT != "<required>" {SEAFILE_LOG_TO_STDOUT: env.SEAFILE_LOG_TO_STDOUT}
		if env.SEAFILE_LOG_TO_STDOUT == "" || env.SEAFILE_LOG_TO_STDOUT == "<required>" {SEAFILE_LOG_TO_STDOUT: "true"}
		if env.SITE_ROOT != "" && env.SITE_ROOT != "<required>" {SITE_ROOT: env.SITE_ROOT}
		if env.SITE_ROOT == "" || env.SITE_ROOT == "<required>" {SITE_ROOT: "/"}
		if env.SEAFILE_SERVER_HOSTNAME != "" && env.SEAFILE_SERVER_HOSTNAME != "<required>" {SEAFILE_SERVER_HOSTNAME: env.SEAFILE_SERVER_HOSTNAME}
		if env.SEAFILE_SERVER_PROTOCOL != "" && env.SEAFILE_SERVER_PROTOCOL != "<required>" {SEAFILE_SERVER_PROTOCOL: env.SEAFILE_SERVER_PROTOCOL}
		if env.SEAFILE_SERVER_PROTOCOL == "" || env.SEAFILE_SERVER_PROTOCOL == "<required>" {SEAFILE_SERVER_PROTOCOL: "https"}
		if env.SEAFILE_MYSQL_DB_HOST != "" && env.SEAFILE_MYSQL_DB_HOST != "<required>" {SEAFILE_MYSQL_DB_HOST: env.SEAFILE_MYSQL_DB_HOST}
		if env.SEAFILE_MYSQL_DB_PORT != "" && env.SEAFILE_MYSQL_DB_PORT != "<required>" {SEAFILE_MYSQL_DB_PORT: env.SEAFILE_MYSQL_DB_PORT}
		if env.SEAFILE_MYSQL_DB_PORT == "" || env.SEAFILE_MYSQL_DB_PORT == "<required>" {SEAFILE_MYSQL_DB_PORT: "3306"}
		if env.SEAFILE_MYSQL_DB_USER != "" && env.SEAFILE_MYSQL_DB_USER != "<required>" {SEAFILE_MYSQL_DB_USER: env.SEAFILE_MYSQL_DB_USER}
		if env.SEAFILE_MYSQL_DB_USER == "" || env.SEAFILE_MYSQL_DB_USER == "<required>" {SEAFILE_MYSQL_DB_USER: "seafile"}
		if env.SEAFILE_MYSQL_DB_CCNET_DB_NAME != "" && env.SEAFILE_MYSQL_DB_CCNET_DB_NAME != "<required>" {SEAFILE_MYSQL_DB_CCNET_DB_NAME: env.SEAFILE_MYSQL_DB_CCNET_DB_NAME}
		if env.SEAFILE_MYSQL_DB_CCNET_DB_NAME == "" || env.SEAFILE_MYSQL_DB_CCNET_DB_NAME == "<required>" {SEAFILE_MYSQL_DB_CCNET_DB_NAME: "ccnet_db"}
		if env.SEAFILE_MYSQL_DB_SEAFILE_DB_NAME != "" && env.SEAFILE_MYSQL_DB_SEAFILE_DB_NAME != "<required>" {SEAFILE_MYSQL_DB_SEAFILE_DB_NAME: env.SEAFILE_MYSQL_DB_SEAFILE_DB_NAME}
		if env.SEAFILE_MYSQL_DB_SEAFILE_DB_NAME == "" || env.SEAFILE_MYSQL_DB_SEAFILE_DB_NAME == "<required>" {SEAFILE_MYSQL_DB_SEAFILE_DB_NAME: "seafile_db"}
		if env.SEAFILE_MYSQL_DB_SEAHUB_DB_NAME != "" && env.SEAFILE_MYSQL_DB_SEAHUB_DB_NAME != "<required>" {SEAFILE_MYSQL_DB_SEAHUB_DB_NAME: env.SEAFILE_MYSQL_DB_SEAHUB_DB_NAME}
		if env.SEAFILE_MYSQL_DB_SEAHUB_DB_NAME == "" || env.SEAFILE_MYSQL_DB_SEAHUB_DB_NAME == "<required>" {SEAFILE_MYSQL_DB_SEAHUB_DB_NAME: "seahub_db"}
		if env.CACHE_PROVIDER != "" && env.CACHE_PROVIDER != "<required>" {CACHE_PROVIDER: env.CACHE_PROVIDER}
		if env.CACHE_PROVIDER == "" || env.CACHE_PROVIDER == "<required>" {CACHE_PROVIDER: "redis"}
		REDIS_HOST: env.REDIS_HOST
		if env.REDIS_PORT != "" && env.REDIS_PORT != "<required>" {REDIS_PORT: env.REDIS_PORT}
		if env.REDIS_PORT == "" || env.REDIS_PORT == "<required>" {REDIS_PORT: "6379"}
		MEMCACHED_HOST: env.MEMCACHED_HOST
		if env.MEMCACHED_PORT != "" && env.MEMCACHED_PORT != "<required>" {MEMCACHED_PORT: env.MEMCACHED_PORT}
		if env.MEMCACHED_PORT == "" || env.MEMCACHED_PORT == "<required>" {MEMCACHED_PORT: "11211"}
		SEAF_SERVER_STORAGE_TYPE: env.SEAF_SERVER_STORAGE_TYPE
		S3_COMMIT_BUCKET: env.S3_COMMIT_BUCKET
		S3_FS_BUCKET: env.S3_FS_BUCKET
		S3_BLOCK_BUCKET: env.S3_BLOCK_BUCKET
		S3_KEY_ID: env.S3_KEY_ID
		if env.S3_USE_V4_SIGNATURE != "" && env.S3_USE_V4_SIGNATURE != "<required>" {S3_USE_V4_SIGNATURE: env.S3_USE_V4_SIGNATURE}
		if env.S3_USE_V4_SIGNATURE == "" || env.S3_USE_V4_SIGNATURE == "<required>" {S3_USE_V4_SIGNATURE: "true"}
		if env.S3_AWS_REGION != "" && env.S3_AWS_REGION != "<required>" {S3_AWS_REGION: env.S3_AWS_REGION}
		if env.S3_AWS_REGION == "" || env.S3_AWS_REGION == "<required>" {S3_AWS_REGION: "us-east-1"}
		S3_HOST: env.S3_HOST
		if env.S3_USE_HTTPS != "" && env.S3_USE_HTTPS != "<required>" {S3_USE_HTTPS: env.S3_USE_HTTPS}
		if env.S3_USE_HTTPS == "" || env.S3_USE_HTTPS == "<required>" {S3_USE_HTTPS: "true"}
		if env.S3_PATH_STYLE_REQUEST != "" && env.S3_PATH_STYLE_REQUEST != "<required>" {S3_PATH_STYLE_REQUEST: env.S3_PATH_STYLE_REQUEST}
		if env.S3_PATH_STYLE_REQUEST == "" || env.S3_PATH_STYLE_REQUEST == "<required>" {S3_PATH_STYLE_REQUEST: "false"}
		if env.ENABLE_NOTIFICATION_SERVER != "" && env.ENABLE_NOTIFICATION_SERVER != "<required>" {ENABLE_NOTIFICATION_SERVER: env.ENABLE_NOTIFICATION_SERVER}
		if env.ENABLE_NOTIFICATION_SERVER == "" || env.ENABLE_NOTIFICATION_SERVER == "<required>" {ENABLE_NOTIFICATION_SERVER: "false"}
		NOTIFICATION_SERVER_URL: env.NOTIFICATION_SERVER_URL
		if env.ENABLE_SEAFILE_AI != "" && env.ENABLE_SEAFILE_AI != "<required>" {ENABLE_SEAFILE_AI: env.ENABLE_SEAFILE_AI}
		if env.ENABLE_SEAFILE_AI == "" || env.ENABLE_SEAFILE_AI == "<required>" {ENABLE_SEAFILE_AI: "false"}
		if env.ENABLE_FACE_RECOGNITION != "" && env.ENABLE_FACE_RECOGNITION != "<required>" {ENABLE_FACE_RECOGNITION: env.ENABLE_FACE_RECOGNITION}
		if env.ENABLE_FACE_RECOGNITION == "" || env.ENABLE_FACE_RECOGNITION == "<required>" {ENABLE_FACE_RECOGNITION: "false"}
		SEAFILE_AI_SERVER_URL: env.SEAFILE_AI_SERVER_URL
		if env.MD_FILE_COUNT_LIMIT != "" && env.MD_FILE_COUNT_LIMIT != "<required>" {MD_FILE_COUNT_LIMIT: env.MD_FILE_COUNT_LIMIT}
		if env.MD_FILE_COUNT_LIMIT == "" || env.MD_FILE_COUNT_LIMIT == "<required>" {MD_FILE_COUNT_LIMIT: "100000"}
		if env.ENABLE_SEADOC != "" && env.ENABLE_SEADOC != "<required>" {ENABLE_SEADOC: env.ENABLE_SEADOC}
		if env.ENABLE_SEADOC == "" || env.ENABLE_SEADOC == "<required>" {ENABLE_SEADOC: "false"}
		SEADOC_SERVER_URL: env.SEADOC_SERVER_URL
		if env.INIT_SEAFILE_ADMIN_EMAIL != "" && env.INIT_SEAFILE_ADMIN_EMAIL != "<required>" {INIT_SEAFILE_ADMIN_EMAIL: env.INIT_SEAFILE_ADMIN_EMAIL}
		if (env.INIT_SEAFILE_ADMIN_EMAIL == "" || env.INIT_SEAFILE_ADMIN_EMAIL == "<required>") && initMode == false {INIT_SEAFILE_ADMIN_EMAIL: ""}
		if env.CLUSTER_INIT_ES_HOST != "" && env.CLUSTER_INIT_ES_HOST != "<required>" {CLUSTER_INIT_ES_HOST: env.CLUSTER_INIT_ES_HOST}
		if (env.CLUSTER_INIT_ES_HOST == "" || env.CLUSTER_INIT_ES_HOST == "<required>") && initMode == false {CLUSTER_INIT_ES_HOST: ""}
		if env.CLUSTER_INIT_ES_PORT != "" && env.CLUSTER_INIT_ES_PORT != "<required>" {CLUSTER_INIT_ES_PORT: env.CLUSTER_INIT_ES_PORT}
		if env.CLUSTER_INIT_ES_PORT == "" || env.CLUSTER_INIT_ES_PORT == "<required>" {CLUSTER_INIT_ES_PORT: "9200"}
	}

	#notificationEnabled: (#envData.ENABLE_NOTIFICATION_SERVER | "false") == "true"
	#cacheProvider:       #envData.CACHE_PROVIDER
	#storageType:         #envData.SEAF_SERVER_STORAGE_TYPE | "disk"
	#seadocEnabled:       (#envData.ENABLE_SEADOC | "false") == "true"
	#seafileAIEnabled:    (#envData.ENABLE_SEAFILE_AI | "false") == "true"

	if #notificationEnabled {
		#envData: INNER_NOTIFICATION_SERVER_URL: #envData.NOTIFICATION_SERVER_URL & =~"^.+$"
	}
	if #cacheProvider == "redis" {
		#envData: REDIS_HOST: =~"^.+$"
	}
	if #cacheProvider == "memcached" {
		#envData: MEMCACHED_HOST: =~"^.+$"
	}
	if #storageType == "s3" {
		#envData: {
			S3_COMMIT_BUCKET: =~"^.+$"
			S3_FS_BUCKET:     =~"^.+$"
			S3_BLOCK_BUCKET:  =~"^.+$"
			S3_KEY_ID:        =~"^.+$"
		}
	}
	if #seadocEnabled {
		#envData: SEADOC_SERVER_URL: =~"^.+$"
	}
	if #seafileAIEnabled {
		#envData: SEAFILE_AI_SERVER_URL: =~"^.+$"
	}
	if initMode == true {
		#envData: {
			INIT_SEAFILE_ADMIN_EMAIL: =~"^.+$"
			CLUSTER_INIT_ES_HOST:     =~"^.+$"
		}
	}
}

#ExtraVolume: {
	name: string
	mountPath: string
	subPath?: string
	readOnly?: bool
	volumeInfo: corev1.#Volume & {
		name: _
	}
}

#Instance: {
	config: #Config

	objects: {
		cm: #ConfigMap & {#config: config}
		secret: #Secret & {#config: config}
		svc: #Service & {#config: config}
		if config.#dataVolumeEnabled {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		deployFrontend: #DeploymentFrontend & {#config: config}
		deployBackend: #DeploymentBackend & {#config: config}
	}

	tests: {}
}
