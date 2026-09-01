package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:      *"" | string
	fullnameOverride:  *"" | string
	namespaceOverride: *"" | string

	fullname: [
		if fullnameOverride != "" {fullnameOverride},
		if nameOverride != "" {nameOverride},
		metadata.name,
	][0]

	namespace: [
		if namespaceOverride != "" {namespaceOverride},
		metadata.namespace,
	][0]

	serviceAccountName: [
		if serviceAccount.name != "" {serviceAccount.name},
		fullname,
	][0]

	userdataPvcName: [
		if persistence.userdata.existingClaim != "" {persistence.userdata.existingClaim},
		"\(fullname)-userdata",
	][0]

	confPvcName: [
		if persistence.conf.existingClaim != "" {persistence.conf.existingClaim},
		"\(fullname)-conf",
	][0]

	addonsPvcName: [
		if persistence.addons.existingClaim != "" {persistence.addons.existingClaim},
		"\(fullname)-addons",
	][0]

	image: timoniv1.#Image & {
		repository: *"docker.io/openhab/openhab" | string
		tag:        *"5.2.0" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	replicaCount: 1

	serviceAccount: {
		create:                       *true | bool
		automountServiceAccountToken: *false | bool
		annotations:                  {[string]: string}
		name:                         *"" | string
	}

	podAnnotations: {[string]: string}
	podLabels:      {[string]: string}

	podSecurityContext: corev1.#PodSecurityContext | *{
		fsGroup: 9001
		seccompProfile: type: "RuntimeDefault"
	}

	securityContext: corev1.#SecurityContext | *{
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
	}

	service: {
		type:           *"ClusterIP" | string
		port:           *8080 | int
		ipFamilyPolicy: *"" | string
		ipFamilies:     *[] | [...string]
	}

	persistence: {
		userdata: #PersistenceItem & {
			enabled:     true
			accessMode:  "ReadWriteOnce"
			size:        "5Gi"
		}
		conf: #PersistenceItem & {
			enabled:     true
			accessMode:  "ReadWriteOnce"
			size:        "1Gi"
		}
		addons: #PersistenceItem & {
			enabled:     true
			accessMode:  "ReadWriteOnce"
			size:        "2Gi"
		}
	}

	admin: {
		secretEnabled:  *false | bool
		username:       *"admin" | string
		password:       *"" | string
		existingSecret: *"" | string
	}

	configMaps: {
		syncImage: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		syncResources: corev1.#ResourceRequirements | *{
			requests: {
				cpu:    "50m"
				memory: "32Mi"
			}
			limits: {
				cpu:    "100m"
				memory: "64Mi"
			}
		}
		sitemaps: #ConfigMapFileGroup
		things:   #ConfigMapFileGroup
		items:    #ConfigMapFileGroup
	}

	env: {
		TZ:                 *"UTC" | string
		EXTRA_JAVA_OPTS:    *"" | string
		OPENHAB_HTTP_PORT:  *"8080" | string
		OPENHAB_HTTPS_PORT: *"8443" | string
	}

	karaf: {
		enabled: *false | bool
		service: {
			type:           *"ClusterIP" | string
			port:           *8101 | int
			ipFamilyPolicy: *"" | string
			ipFamilies:     *[] | [...string]
		}
	}

	resources: corev1.#ResourceRequirements | *{
		requests: {
			cpu:    "500m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "2000m"
			memory: "2Gi"
		}
	}

	startupProbe: corev1.#Probe | *{
		httpGet: {
			path: "/rest/uuid"
			port: "http"
		}
		initialDelaySeconds: 60
		failureThreshold:    60
		periodSeconds:       10
	}

	livenessProbe: corev1.#Probe | *{
		httpGet: {
			path: "/rest/uuid"
			port: "http"
		}
		periodSeconds:    30
		failureThreshold: 3
		timeoutSeconds:   5
	}

	readinessProbe: corev1.#Probe | *{
		httpGet: {
			path: "/rest/uuid"
			port: "http"
		}
		periodSeconds:    10
		failureThreshold: 5
		timeoutSeconds:   5
	}

	metrics: {
		enabled: *false | bool
		podAnnotations: enabled: *true | bool
		serviceMonitor: {
			enabled:           *false | bool
			namespace:         *"" | string
			interval:          *"60s" | string
			scrapeTimeout:     *"10s" | string
			additionalLabels:  {[string]: string}
			relabelings:       *[] | [...{[string]: string}]
			metricRelabelings: *[] | [...{[string]: string}]
		}
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"openhab" | string
		include: {
			userdata: *true | bool
			conf:     *true | bool
		}
		images: {
			utility: timoniv1.#Image & {
				repository: *"docker.io/library/alpine" | string
				tag:        *"3.22" | string
				digest:     *"" | string
				pullPolicy: *"IfNotPresent" | string
			}
			uploader: timoniv1.#Image & {
				repository: *"docker.io/helmforge/mc" | string
				tag:        *"1.0.0" | string
				digest:     *"" | string
				pullPolicy: *"IfNotPresent" | string
			}
		}
		resources: corev1.#ResourceRequirements
		s3: {
			endpoint:       *"" | string
			bucket:         *"" | string
			prefix:         *"openhab" | string
			accessKey:      *"" | string
			secretKey:      *"" | string
			existingSecret: *"" | string
		}
	}

	nodeSelector:               {[string]: string}
	tolerations?:               [...corev1.#Toleration]
	affinity?:                  corev1.#Affinity
	extraVolumes:               *[] | [...corev1.#Volume]
	extraVolumeMounts:          *[] | [...corev1.#VolumeMount]
	extraEnv:                   *[] | [...corev1.#EnvVar]
	extraManifests:             *[] | [...{...}]

	gateway: {
		enabled: *false | bool
		hostnames: *["openhab.local"] | [...string]
		parentRefs: *[] | [...{[string]: string}]
	}

	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"1h" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"ClusterSecretStore" | string
		}
		target: creationPolicy: *"Owner" | string
		data: *[] | [...{[string]: string}]
	}

	test: enabled: *false | bool
}

#PersistenceItem: {
	enabled:       *true | bool
	storageClass:  *"" | string
	accessMode:    *"ReadWriteOnce" | string
	size:          string
	existingClaim: *"" | string
}

#ConfigMapFileGroup: {
	enabled: *false | bool
	files:   {[string]: string}
}

#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			serviceAccount: #ServiceAccountBuilder & {_config: config}
		}
		statefulSet: #StatefulSetBuilder & {_config: config}
		service:     #ServiceBuilder & {_config: config}

		if config.karaf.enabled {
			karafService: #KarafServiceBuilder & {_config: config}
		}
		if config.persistence.userdata.enabled && config.persistence.userdata.existingClaim == "" {
			userdataPVC: #PVCBuilder & {_config: config, _name: "userdata", _pvcConfig: config.persistence.userdata}
		}
		if config.persistence.conf.enabled && config.persistence.conf.existingClaim == "" {
			confPVC: #PVCBuilder & {_config: config, _name: "conf", _pvcConfig: config.persistence.conf}
		}
		if config.persistence.addons.enabled && config.persistence.addons.existingClaim == "" {
			addonsPVC: #PVCBuilder & {_config: config, _name: "addons", _pvcConfig: config.persistence.addons}
		}
		if config.configMaps.sitemaps.enabled && len(config.configMaps.sitemaps.files) > 0 {
			sitemapsConfigMap: #SitemapsConfigMapBuilder & {_config: config}
		}
		if config.configMaps.things.enabled && len(config.configMaps.things.files) > 0 {
			thingsConfigMap: #ThingsConfigMapBuilder & {_config: config}
		}
		if config.configMaps.items.enabled && len(config.configMaps.items.files) > 0 {
			itemsConfigMap: #ItemsConfigMapBuilder & {_config: config}
		}
		if config.admin.secretEnabled && config.admin.existingSecret == "" {
			adminSecret: #AdminSecretBuilder & {_config: config}
		}
		if config.gateway.enabled {
			httpRoute: #HTTPRouteBuilder & {_config: config}
		}
		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecretBuilder & {_config: config}
		}
		if config.metrics.enabled && config.metrics.serviceMonitor.enabled {
			serviceMonitor: #ServiceMonitorBuilder & {_config: config}
		}
		if config.backup.enabled {
			if config.backup.s3.existingSecret == "" {
				backupSecret: #BackupSecretBuilder & {_config: config}
			}
			backupConfigMap: #BackupConfigMapBuilder & {_config: config}
			backupCronJob:   #BackupCronJobBuilder & {_config: config}
		}
		for idx, m in config.extraManifests {
			"extra-manifest-\(idx)": m
		}
	}

	tests: {}
}
