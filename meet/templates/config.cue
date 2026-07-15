package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and default types for the entire meet infrastructure.
#Config: {
	kubeVersion!:   string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string
	chartName:      *"meet" | string
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
		path:                string
		initialDelaySeconds: int
		periodSeconds:       int
		timeoutSeconds?:     int
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
		}]
		pdb: enabled: *false | bool
		...
	}

	// Ingress Configurations
	ingress:           #IngressBase
	ingressWebhook:    #IngressBase
	ingressAdmin:      #IngressBase
	ingressMedia:      #IngressBase
	ingressMediaFiles: #IngressBase

	// External Name Services
	serviceMedia: {
		host:        string
		port:        int
		annotations: {[string]: string}
	}
	serviceMediaFiles: {
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
		cronjobs: [...{
			name:     string
			schedule: string
			command: [...string]
		}]
		mergeDuplicateUsers: {
			annotations: {[string]: string}
			enabled:     bool
			command: [...string]
			restartPolicy: "Never" | "OnFailure"
		}
	}

	frontend: #ComponentDeploymentBase & {
		outlookAddon: {
			enabled:              bool
			appName:              string
			baseUrl:              string
			enableSourceTracking: bool
			feedbackForm:         string
			id:                   string
			manifestTemplate?:    string
		}
	}

	summary: #ComponentDeploymentBase

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

	// Celery Infrastructure Stack
	celeryBackend:        #ComponentDeploymentBase
	celerySummarize:      #ComponentDeploymentBase
	celerySummaryBackend: #ComponentDeploymentBase
	celeryTranscribe:     #ComponentDeploymentBase & {
		image: timoniv1.#Image
		instances: [...{
			name:          string
			image?:        timoniv1.#Image
			extraEnvVars:  {[string]: _}
			replicas?:     int
			command?: [...string]
			args?: [...string]
			resources?:    timoniv1.#ResourceRequirements
			nodeSelector?: {[string]: string}
			affinity?:     corev1.#Affinity
			tolerations?: [...corev1.#Toleration]
			pdb?: enabled: bool
		}]
	}

	// Autonomous Agents
	agentMetadata: #ComponentDeploymentBase & { image: timoniv1.#Image }
	agentSubtitles: #ComponentDeploymentBase & { image: timoniv1.#Image }

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
			secretName: *"mkcert" | string
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
				cpu:    *"10m" | string
				memory: *"128Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"512Mi" | string
			}
		}
	}

	minio: {
		enabled: *true | bool
		image:   #Image
		mcImage: #Image
		caSecretName: *"\(metadata.name)-mkcert" | string
		caCert:       *"" | string
		ingress: {
			enabled:    *true | bool
			className:  *null | string
			host:       *"minio.127.0.0.1.nip.io" | string
			secretName: *"\(metadata.name)-mkcert" | string
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

	livekit: {
		enabled:   *true | bool
		image:     #Image
		host:      *"livekit.127.0.0.1.nip.io" | string
		apiKey:    *"devkey" | string
		apiSecret: *"secret" | string
		nodeIP:    *"127.0.0.1" | string
		ingress: {
			enabled:    *true | bool
			className:  *"nginx" | null | string
			secretName: *"meet-mkcert" | string
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

	frontendNginxConfig: {
		enabled: *true | bool
	}

	secrets: {
		enabled: *false | bool
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
		if config.frontend.outlookAddon.enabled {
			"outlook-addon-manifest": #OutlookAddonManifestConfigMap & {#config: config}
		}

		"frontend-deploy": #FrontendDeployment & {#config: config}
		"frontend-svc":    #FrontendService & {#config: config}
		
		"summary-deploy": #SummaryDeployment & {#config: config}
		"summary-svc":    #SummaryService & {#config: config}

		"backend-deploy": #BackendDeployment & {#config: config}
		"backend-svc":    #BackendService & {#config: config}
		
		"celery-backend-deploy": #CeleryBackendDeployment & {#config: config}
		"celery-summarize-deploy": #CelerySummarizeDeployment & {#config: config}
		"celery-summary-backend-deploy": #CelerySummaryBackendDeployment & {#config: config}
		
		"agent-subtitles-deploy": #AgentSubtitlesDeployment & {#config: config}
		"agent-metadata-deploy": #AgentMetadataDeployment & {#config: config}

		"backend-job-createsuperuser": #CreateSuperuserJob & {#config: config}
		"backend-job-migrate": #MigrateJob & {#config: config}
		"backend-job-merge-duplicate-users": #MergeDuplicateUsersJob & {#config: config}

		if config.frontend.pdb.enabled {
			"frontend-pdb": #FrontendPodDisruptionBudget & {#config: config}
		}
		if config.summary.pdb.enabled {
			"summary-pdb": #SummaryPodDisruptionBudget & {#config: config}
		}
		if config.backend.pdb.enabled {
			"backend-pdb": #BackendPodDisruptionBudget & {#config: config}
		}
		if config.celeryBackend.pdb.enabled {
			"celery-backend-pdb": #CeleryBackendPodDisruptionBudget & {#config: config}
		}
		if config.celerySummarize.pdb.enabled {
			"celery-summarize-pdb": #CelerySummarizePodDisruptionBudget & {#config: config}
		}
		if config.celerySummaryBackend.pdb.enabled {
			"celery-summary-backend-pdb": #CelerySummaryBackendPodDisruptionBudget & {#config: config}
		}
		if config.agentSubtitles.pdb.enabled {
			"agent-subtitles-pdb": #AgentSubtitlesPodDisruptionBudget & {#config: config}
		}
		if config.agentMetadata.pdb.enabled {
			"agent-metadata-pdb": #AgentMetadataPodDisruptionBudget & {#config: config}
		}

		for cron in config.backend.cronjobs {
			"backend-cronjob-\(cron.name)": #BackendCronJob & {#config: config, #cron: cron}
		}

		for inst in config.celeryTranscribe.instances {
			"\(config.metadata.name)-celery-transcribe-\(inst.name)": #CeleryTranscribeDeployment & {#config: config, #instance: inst}
			
			if (inst.pdb.enabled | *config.celeryTranscribe.pdb.enabled | *false) {
				"\(config.metadata.name)-celery-transcribe-\(inst.name)-pdb": #CeleryTranscribePDB & {#config: config, #instance: inst}
			}
		}

		if config.ingress.enabled {
			"ingress-main": #Ingress & {#config: config}
		}
		if config.ingressAdmin.enabled {
			"ingress-admin": #IngressAdmin & {#config: config}
		}
		if config.ingressWebhook.enabled {
			"ingress-webhook": #IngressWebhook & {#config: config}
		}
		if config.ingressMedia.enabled {
			"ingress-media": #IngressMedia & {#config: config}
			"service-media": #ServiceMedia & {#config: config}
		}
		if config.ingressMediaFiles.enabled {
			"ingress-media-files": #IngressMediaFiles & {#config: config}
			"service-media-files": #ServiceMediaFiles & {#config: config}
		}
		if config.posthog.ingress.enabled {
			"ingress-posthog": #IngressPosthog & {#config: config}
			"posthog-proxy":   #PosthogProxyService & {#config: config}
		}
		if config.posthog.ingressAssets.enabled {
			"posthog-assets-proxy": #PosthogAssetsProxyService & {#config: config}
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
			"minio-webhook-job": #MinioWebhookJob & {#config: config}
		}

		if config.livekit.enabled {
			"livekit-svc": #LivekitService & {#config: config}
			"livekit-cm":  #LivekitConfigMap & {#config: config}
			"livekit-deploy": #LivekitDeployment & {#config: config}
			if config.livekit.ingress.enabled {
				"livekit-ingress": #LivekitIngress & {#config: config}
			}
		}
		if config.frontendNginxConfig.enabled {
			"frontend-nginx-config-cm": #FrontendNginxConfigMap & {#config: config}
		}
		if config.secrets.enabled {
			"bitwarden-cli-deploy": #BitwardenCliDeployment & {#config: config}
			"bitwarden-cli-svc":    #BitwardenCliService & {#config: config}
			"bitwarden-login-store": #ClusterSecretStore & {#config: config, #name: "bitwarden-login", #url: "http://bitwarden-cli-\(config.metadata.namespace).\(config.metadata.namespace).svc.cluster.local:8087/object/item/{{ .remoteRef.key }}", #jsonPath: "$.login"}
			"bitwarden-fields-store": #ClusterSecretStore & {#config: config, #name: "bitwarden-fields", #url: "http://bitwarden-cli-\(config.metadata.namespace).\(config.metadata.namespace).svc.cluster.local:8087/object/fields/{{ .remoteRef.key }}", #jsonPath: ""}
			"bitwarden-attachments-store": #ClusterSecretStore & {#config: config, #name: "bitwarden-attachments", #url: "http://bitwarden-cli-\(config.metadata.namespace).\(config.metadata.namespace).svc.cluster.local:8087/object/attachment/{{ .remoteRef.key }}", #jsonPath: ""}
			"external-secret-backend": #ExternalSecret & {#config: config}
		}
	}
}