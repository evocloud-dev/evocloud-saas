package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and default types for the entire docs infrastructure.
#Config: {
	kubeVersion!:   string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string
	chartName:      *"docs" | string
	frontendName:   *"\(metadata.name)-frontend" | string
	backendName:    *"\(metadata.name)-backend" | string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels:      timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	image!: timoniv1.#Image & {
		tag:    *"" | string
		digest: *"" | string
		credentials?: {
			username?: string
			password?: string
			registry?: string
			name?:     string
		}
	}

	nameOverride:     string
	fullnameOverride: string

	commonEnvVars: {[string]: _}

	djangoSecretKey: string
	djangoSuperUserEmail: string
	djangoSuperUserPass: string
	aiApiKey: string
	aiBaseUrl: string
	oidc: {
		clientId: string
		clientSecret: string
	}

	#TLSConfig: {
		secretName: *null | string
		enabled:    bool
		additional: [...{
			secretName: string
			hosts: [...string]
		}]
	}

	#Image: {
		repository: string
		tag:        *"" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
		reference:  string
		if digest != "" {
			reference: "\(repository)@\(digest)"
		}
		if digest == "" {
			reference: "\(repository):\(tag)"
		}
	}

	#IngressBase: {
		enabled:   bool
		className: *null | string
		host:      string
		path:      string
		hosts: [...string]
		tls: #TLSConfig
		annotations?: {[string]: string}
		customBackends?: [..._]
	}

	#ProbeConfig: {
		initialDelaySeconds?: int
		periodSeconds?:       int
		timeoutSeconds?:     int
		path?:                string
		exec?: {
			command: [...string]
		}
	}

	#ServiceBase: {
		type:         *"ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
		port:         int & >0 & <=65535
		targetPort:   *port | (int & >0 & <=65535)
		annotations:  {[string]: {}} | {[string]: string}
		externalName?: string
	}

	#ComponentDeploymentBase: {
		image?:                #Image
		dpAnnotations:         *{} | {[string]: string}
		command: [...string]
		args: [...string]
		replicas:              *1 | (int & >=0)
		shareProcessNamespace: *false | bool
		sidecars: [..._]
		migrateJobAnnotations?: {[string]: string}
		automountServiceAccountToken: *false | bool
		serviceAccountName:           *"default" | string
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
			seccompProfile: type: *"RuntimeDefault" | string
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsNonRoot: *true | bool
			runAsUser:    *65510 | int
			runAsGroup:   *65510 | int
			fsGroup:      *65510 | int
			seccompProfile: type: *"RuntimeDefault" | string
		}
		envVars:            *{} | {[string]: _}
		podAnnotations:     *{} | {[string]: string}
		service?:           #ServiceBase
		probes: {
			liveness?:  #ProbeConfig
			readiness?: #ProbeConfig
			startup?:   #ProbeConfig
		}
		resources:    timoniv1.#ResourceRequirements | *{
			requests: {
				cpu:    *"10m" | string
				memory: *"32Mi" | string
			}
			limits: {
				cpu:    *"200m" | string
				memory: *"128Mi" | string
			}
		}
		nodeSelector: *{} | {[string]: string}
		tolerations: [...corev1.#Toleration]
		affinity: *{} | corev1.#Affinity
		hostAliases?: [...corev1.#HostAlias]
		persistence: *{} | {[string]: {
			type:      *"persistentVolumeClaim" | "emptyDir"
			size?:     string
			mountPath: string
		}}
		extraVolumeMounts: [...{
			name:      string
			mountPath: string
			subPath:   *"" | string
			readOnly:  *false | bool
		}]
		extraVolumes: [...{
			name:           string
			existingClaim?: string
			hostPath?:      {[string]: _}
			csi?:           {[string]: _}
			configMap?:     {[string]: _}
			emptyDir?:      {[string]: _}
			secret?:        {[string]: _}
		}]
		pdb: enabled: *false | bool
		...
	}

	// Ingress Configurations
	ingress:                 #IngressBase
	ingressAdmin:            #IngressBase
	ingressCollaborationWS:  #IngressBase
	ingressCollaborationApi: #IngressBase
	ingressMedia:            #IngressBase

	// External Name Services
	serviceMedia: {
		host:        string
		port:        int
		annotations: {[string]: string}
	}

	// Applications & Deployments
	backend: #ComponentDeploymentBase & {
		jobs: {
			ttlSecondsAfterFinished: int
			backoffLimit:            int
		}
		migrate: {
			command: [...string]
			restartPolicy: "Never" | "OnFailure"
		}
		createsuperuser: {
			command: [...string]
			restartPolicy: "Never" | "OnFailure"
		}
		job: {
			name:          string
			command:       [...string]
			restartPolicy: "Never" | "OnFailure"
			annotations?:  {[string]: string}
		}
		cronjobs: [...{
			name:     string
			schedule: string
			command: [...string]
			concurrencyPolicy?:          "Allow" | "Forbid" | "Replace"
			successfulJobsHistoryLimit?: int
			failedJobsHistoryLimit?:     int
			restartPolicy?:              "Never" | "OnFailure"
		}]
		themeCustomization: {
			enabled: bool
			file_content: string
			mount_path: string
		}
		celery: #ComponentDeploymentBase
	}

	frontend: #ComponentDeploymentBase & {
		replicas: int
		image?: {
			repository?: string
			tag?:        string
			pullPolicy?: string
		}
		command?: [...string]
		args?: [...string]
		shareProcessNamespace?: bool
		sidecars?: [..._]
		securityContext?: {[string]: _}
		podSecurityContext?: {[string]: _}
		envVars?: {[string]: _}
		envFrom?: [..._]
		podAnnotations?: {[string]: string}
		dpAnnotations?: {[string]: string}
		service?: {
			type?:       string
			port?:       int
			targetPort?: int
			annotations?: {[string]: string}
		}
		probes?: {
			liveness?: {
				path?: string
				initialDelaySeconds?: int
				periodSeconds?: int
			}
			readiness?: {
				path?: string
				initialDelaySeconds?: int
				periodSeconds?: int
			}
		}
		resources?: {[string]: _}
		nodeSelector?: {[string]: string}
		tolerations?: [..._]
		affinity?: {[string]: _}
		persistence?: {[string]: {
			type?:      string
			size?:     string
			mountPath?: string
		}}
		extraVolumeMounts?: [...{
			name?:      string
			mountPath?: string
			subPath?:  string
			readOnly?: bool
		}]
		extraVolumes?: [...{
			name?:           string
			existingClaim?: string
			hostPath?:      {[string]: _}
			csi?:           {[string]: _}
			configMap?:     {[string]: _}
			emptyDir?:      {[string]: _}
			secret?:        {[string]: _}
		}]
		pdb?: { enabled?: bool }
		serviceAccountName?: string
		automountServiceAccountToken?: bool
	}

	yProvider: #ComponentDeploymentBase & {
		image?: #Image
		converter: {
			enabled:  bool
			replicas: int
			resources: {[string]: _}
			service: {
				type:       *"ClusterIP" | string
				port:       *80 | int
				targetPort: *3000 | int
				annotations: *{} | {[string]: string}
			}
			command?: [...string]
			args?: [...string]
			envVars?: {[string]: _}
			securityContext?: {[string]: _}
			persistence?: {[string]: {
				type:      string
				size?:     string
				mountPath: string
			}}
			extraVolumeMounts?: [...{
				name:      string
				mountPath: string
				subPath?:  string
				readOnly?: bool
			}]
			extraVolumes?: [...{
				name:           string
				existingClaim?: string
				hostPath?:      {[string]: _}
				csi?:           {[string]: _}
				configMap?:     {[string]: _}
				emptyDir?:      {[string]: _}
				secret?:        {[string]: _}
			}]
			pdb: enabled: *false | bool
		}
	}

	docSpec: #ComponentDeploymentBase & {
		enabled: bool
		replicas: int
		image?: {
			repository?: string
			tag?:        string
			pullPolicy?: string
		}
		command?: [...string]
		args?: [...string]
		shareProcessNamespace?: bool
		sidecars?: [..._]
		securityContext?: {[string]: _}
		podSecurityContext?: {[string]: _}
		envVars?: {[string]: _}
		envFrom?: [..._]
		podAnnotations?: {[string]: string}
		dpAnnotations?: {[string]: string}
		service?: {
			type?:       string
			port?:       int
			targetPort?: int
			annotations?: {[string]: string}
		}
		probes?: {
			liveness?: {
				path?: string
				initialDelaySeconds?: int
				periodSeconds?: int
			}
			readiness?: {
				path?: string
				initialDelaySeconds?: int
				periodSeconds?: int
			}
		}
		resources?: {[string]: _}
		nodeSelector?: {[string]: string}
		tolerations?: [..._]
		affinity?: {[string]: _}
		persistence?: {[string]: {
			type?:      string
			size?:     string
			mountPath?: string
		}}
		extraVolumeMounts?: [...{
			name?:      string
			mountPath?: string
			subPath?:  string
			readOnly?: bool
		}]
		extraVolumes?: [...{
			name?:           string
			existingClaim?: string
			hostPath?:      {[string]: _}
			csi?:           {[string]: _}
			configMap?:     {[string]: _}
			emptyDir?:      {[string]: _}
			secret?:        {[string]: _}
		}]
		pdb?: { enabled?: bool }
		serviceAccountName?: string
		automountServiceAccountToken?: bool
	}

	ingressRedirects: {
		enabled:   bool
		className: *null | string
		host:      string
		tls: {
			enabled:    bool
			secretName: *null | string
			additional: [...{
				secretName: string
				hosts: [...string]
			}]
		}
		rules: [...{
			host?: string
			from:  string
			to:    string
			code?: int | string
		}]
	}


	// Posthog Integration proxy setups
	posthog: {
		fullname: *"\(metadata.name)-posthog" | string
		ingress:  #IngressBase
		ingressAssets: #IngressBase
		service:       #ServiceBase
		assetsService: #ServiceBase & {
			customBackends?: [..._]
		}
	}


	postgresql: {
		enabled:  *true | bool
		image:    #Image
		host:     *"" | string
		database: *"" | string
		username: *"" | string
		password: *"" | string
		automountServiceAccountToken: *false | bool
		serviceAccountName:           *"default" | string
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsNonRoot: *true | bool
			runAsUser:    *65510 | int
			runAsGroup:   *65510 | int
			fsGroup:      *65510 | int
			seccompProfile: type: *"RuntimeDefault" | string
		}
		resources:    timoniv1.#ResourceRequirements | *{
			requests: {
				cpu:    *"10m" | string
				memory: *"64Mi" | string
			}
			limits: {
				cpu:    *"200m" | string
				memory: *"256Mi" | string
			}
		}
	}

	kc_postgresql: {
		enabled:  *true | bool
		image:    #Image
		host:     *"" | string
		database: *"" | string
		username: *"" | string
		password: *"" | string
		automountServiceAccountToken: *false | bool
		serviceAccountName:           *"default" | string
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsNonRoot: *true | bool
			runAsUser:    *65510 | int
			runAsGroup:   *65510 | int
			fsGroup:      *65510 | int
			seccompProfile: type: *"RuntimeDefault" | string
		}
		resources:    timoniv1.#ResourceRequirements | *{
			requests: {
				cpu:    *"10m" | string
				memory: *"64Mi" | string
			}
			limits: {
				cpu:    *"200m" | string
				memory: *"256Mi" | string
			}
		}
	}

	redis: {
		enabled: *true | bool
		image:   #Image
		automountServiceAccountToken: *false | bool
		serviceAccountName:           *"default" | string
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsNonRoot: *true | bool
			runAsUser:    *65510 | int
			runAsGroup:   *65510 | int
			fsGroup:      *65510 | int
			seccompProfile: type: *"RuntimeDefault" | string
		}
		resources:    timoniv1.#ResourceRequirements | *{
			requests: {
				cpu:    *"10m" | string
				memory: *"32Mi" | string
			}
			limits: {
				cpu:    *"200m" | string
				memory: *"128Mi" | string
			}
		}
	}

	keycloak: {
		enabled:   *true | bool
		image:     #Image
		adminUser: *"su" | string
		adminPassword: *"su" | string
		host:          *"keycloak.127.0.0.1.nip.io" | string
		ingress: {
			enabled:    *true | bool
			className:  *"nginx" | null | string
			secretName: *"\(metadata.name)-tls" | string
			annotations?: {[string]: string}
		}
		db: {
			host:     *"kc-postgres" | string
			database: *"keycloak" | string
			username: *"keycloak" | string
			password: *"keycloak" | string
			schema:   *"public" | string
		}
		realmJson: *"" | string
		automountServiceAccountToken: *false | bool
		serviceAccountName:           *"default" | string
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsNonRoot: *true | bool
			runAsUser:    *65510 | int
			runAsGroup:   *65510 | int
			fsGroup:      *65510 | int
			seccompProfile: type: *"RuntimeDefault" | string
		}
		resources:    timoniv1.#ResourceRequirements | *{
			requests: {
				cpu:    "100m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1000m"
				memory: "1536Mi"
			}
		}
	}

	minio: {
		enabled: *true | bool
		image:   #Image
		mcImage: #Image
		caSecretName: *"\(metadata.name)-ca" | string
		caCert:       *"" | string
		ingress: {
			enabled:    *true | bool
			className:  *null | string
			host:       *"minio.127.0.0.1.nip.io" | string
			secretName: *"\(metadata.name)-tls" | string
		}
		automountServiceAccountToken: *false | bool
		serviceAccountName:           *"default" | string
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsNonRoot: *true | bool
			runAsUser:    *65510 | int
			runAsGroup:   *65510 | int
			fsGroup:      *65510 | int
			seccompProfile: type: *"RuntimeDefault" | string
		}
		resources:    timoniv1.#ResourceRequirements | *{
			requests: {
				cpu:    *"10m" | string
				memory: *"32Mi" | string
			}
			limits: {
				cpu:    *"200m" | string
				memory: *"128Mi" | string
			}
		}
	}

	// Catch-all for injection maps
	extraManifests: [..._]
	test:  {
		enabled: *false | bool
	}
}

// Instance converts validated engine configurations out to Kubernetes objects
#Instance: {
	config: #Config

	objects: {
		"frontend-deploy": #FrontendDeployment & {#config: config}
		"frontend-svc":    #FrontendService & {#config: config}

		"backend-deploy": #BackendDeployment & {#config: config}
		"backend-svc":    #BackendService & {#config: config}
		if config.backend.themeCustomization.enabled {
			"theme-customization-cm": #ThemeCustomizationConfigMap & {#config: config}
		}

		"celery-worker-deploy": #CeleryWorkerDeployment & {#config: config}

		if config.docSpec.enabled {
			"docspec-deploy": #DocSpecDeployment & {#config: config}
			"docspec-svc":    #DocSpecService & {#config: config}
		}

		"y-provider-deploy": #YProviderDeployment & {#config: config}
		"y-provider-svc":    #YProviderService & {#config: config}
		if config.yProvider.converter.enabled {
			"y-provider-converter-deploy": #YProviderConverterDeployment & {#config: config}
			"y-provider-converter-svc":    #YProviderConverterService & {#config: config}
			if config.yProvider.converter.pdb.enabled {
				"y-provider-converter-pdb": #YProviderConverterPDB & {#config: config}
			}
		}

		"backend-job-createsuperuser": #CreateSuperuserJob & {#config: config}
		"backend-job-migrate": #MigrateJob & {#config: config}

		if len(config.backend.job.command) > 0 {
			"backend-job": #BackendJob & {#config: config}
		}



		for cron in config.backend.cronjobs {
			"backend-cronjob-\(cron.name)": #BackendCronJob & {#config: config, #cron: cron}
		}


		if config.frontend.pdb.enabled {
			"frontend-pdb": #FrontendPodDisruptionBudget & {#config: config}
		}
		if config.backend.pdb.enabled {
			"backend-pdb": #BackendPodDisruptionBudget & {#config: config}
		}
		if config.yProvider.pdb.enabled {
			"y-provider-pdb": #YProviderPodDisruptionBudget & {#config: config}
		}

		if config.ingress.enabled {
			"ingress-main": #Ingress & {#config: config}
		}
		if config.ingressAdmin.enabled {
			"ingress-admin": #IngressAdmin & {#config: config}
		}
		if config.ingressCollaborationWS.enabled {
			"ingress-collaboration-ws": #IngressCollaborationWS & {#config: config}
		}
		if config.ingressCollaborationApi.enabled {
			"ingress-collaboration-api": #IngressCollaborationApi & {#config: config}
		}
		if config.ingressMedia.enabled {
			"ingress-media": #IngressMedia & {#config: config}
			"service-media": #ServiceMedia & {#config: config}
		}
		if config.ingressRedirects.enabled {
			for idx, rule in config.ingressRedirects.rules {
				"ingress-redirect-\(idx)": #IngressRedirect & {#config: config, #rule: rule, #index: idx}
			}
		}

		if config.posthog.ingress.enabled {
			"ingress-posthog": #IngressPosthog & {#config: config}
			"posthog-proxy":   #PosthogProxyService & {#config: config}
		}
		if config.posthog.ingressAssets.enabled {
			"ingress-posthog-assets": #IngressPosthogAssets & {#config: config}
			"posthog-assets-proxy":   #PosthogAssetsProxyService & {#config: config}
		}


		if config.postgresql.enabled {
			"postgresql-svc": #PostgresqlService & {#config: config}
			"postgresql-sts": #PostgresqlStatefulSet & {#config: config}
		}
		if config.kc_postgresql.enabled {
			"kc-postgresql-svc": #KcPostgresqlService & {#config: config}
			"kc-postgresql-sts": #KcPostgresqlStatefulSet & {#config: config}
		}
		if config.redis.enabled {
			"redis-svc": #RedisService & {#config: config}
			"redis-cm":  #RedisConfigMap & {#config: config}
			"redis-deploy": #RedisDeployment & {#config: config}
		}
		if config.keycloak.enabled {
			"keycloak-realm-cm": #RealmConfigMap & {#config: config}
			"keycloak-svc":      #KeycloakService & {#config: config}
			if config.keycloak.ingress.enabled {
				"keycloak-ingress": #KeycloakIngress & {#config: config}
			}
			"keycloak-sts":      #KeycloakStatefulSet & {#config: config}
		}
		if config.minio.enabled {
			"minio-svc": #MinioService & {#config: config}
			if config.minio.ingress.enabled {
				"minio-ingress": #MinioIngress & {#config: config}
			}
			if config.minio.caCert != "" {
				"minio-ca-secret": #MinioCaSecret & {#config: config}
			}
			"minio-deploy": #MinioDeployment & {#config: config}
			"minio-bucket-job": #MinioBucketJob & {#config: config}
		}
	}
}