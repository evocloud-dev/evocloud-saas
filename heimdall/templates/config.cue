package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// #Config defines the schema and defaults for Heimdall.
#Config: {
	// The kubeVersion is set at apply-time via timoni.cue.
	kubeVersion!: string
	// Minimum Kubernetes version is 1.26.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// Module version for labels.
	moduleVersion!: string

	// Metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Override the chart/application name
	nameOverride: *"" | string

	// Override the full release name
	fullnameOverride: *"" | string

	// Labels to add to all resources
	commonLabels: *{} | {[string]: string}

	// Image configuration
	image: timoniv1.#Image & {
		repository: *"docker.io/linuxserver/heimdall" | string
		tag:        *"2.8.2" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}

	// Image pull secrets
	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	// Heimdall application configuration
	heimdall: {
		// User ID for file permissions
		puid: *1000 | int
		// Group ID for file permissions
		pgid: *1000 | int
		// Timezone
		timezone: *"UTC" | string
		// Extra environment variables
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	// Persistence for /config
	persistence: {
		enabled:       *true | bool
		storageClass:  *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"1Gi" | string
		existingClaim: *"" | string
		annotations: *{} | {[string]: string}
	}

	// S3 Backup configuration
	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Allow" | "Replace"
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"heimdall" | string

		images: {
			archiver: *"docker.io/library/alpine:3.22" | string
			uploader: *"docker.io/helmforge/mc:1.0.0" | string
		}

		resources: corev1.#ResourceRequirements | *{}

		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"heimdall" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
	}

	// Pod resources
	resources: *{
		requests: {
			cpu:    "50m"
			memory: "128Mi"
		}
		limits: {
			memory: "256Mi"
		}
	} | corev1.#ResourceRequirements

	// Pod security context
	podSecurityContext: *{
		fsGroup: 1000
	} | corev1.#PodSecurityContext

	// Container security context
	securityContext: corev1.#SecurityContext | *{}

	// Startup probe
	startupProbe: {
		enabled:             *true | bool
		path:                *"/" | string
		initialDelaySeconds: *5 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *3 | int
		failureThreshold:    *12 | int
	}

	// Liveness probe
	livenessProbe: {
		enabled:             *true | bool
		path:                *"/" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *20 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	// Readiness probe
	readinessProbe: {
		enabled:             *true | bool
		path:                *"/" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	// Service
	service: {
		type: *"ClusterIP" | string
		port: *80 | int
		annotations: *{} | {[string]: string}
	}

	// Ingress
	ingress: {
		enabled:          *false | bool
		ingressClassName: *"" | string
		annotations: *{} | {[string]: string}
		hosts: *[] | [...{
			host: string
			paths: *[{path: "/", pathType: "Prefix"}] | [...{
				path:     string
				pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
			}]
		}]
		tls: *[] | [...{
			secretName: string
			hosts: [...string]
		}]
	}

	// Service Account
	serviceAccount: {
		create:                       *false | bool
		automountServiceAccountToken: *false | bool
		name:                         *"" | string
		annotations: *{} | {[string]: string}
	}

	// Scheduling & placement
	nodeSelector: *{} | {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity: corev1.#Affinity | *{}
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int

	// Pod-level metadata
	podLabels: *{} | {[string]: string}
	podAnnotations: *{} | {[string]: string}

	// Extra volumes & mounts
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraVolumes: *[] | [...corev1.#Volume]
	extraManifests: *[] | [...{...}]

	// Test settings
	test: {
		enabled: *false | bool
	}

	// Helper computed properties
	name: [
		if nameOverride != "" {nameOverride},
		"heimdall",
	][0]

	fullname: [
		if fullnameOverride != "" {fullnameOverride},
		"\(metadata.name)-\(name)",
	][0]

	namespace: metadata.namespace

	serviceAccountName: [
		if serviceAccount.name != "" {serviceAccount.name},
		if serviceAccount.create {fullname},
		"default",
	][0]

	backupSecretName: [
		if backup.s3.existingSecret != "" {backup.s3.existingSecret},
		"\(fullname)-backup-s3",
	][0]

	pvcName: [
		if persistence.existingClaim != "" {persistence.existingClaim},
		fullname,
	][0]

	selectorLabels: {
		"app.kubernetes.io/name":     name
		"app.kubernetes.io/instance": metadata.name
	}

	standardLabels: {
		"app.kubernetes.io/name":       name
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    image.tag
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}
}

// #Instance outputs all Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		deploy: #DeploymentBuilder & {_config: config}
		svc: #ServiceBuilder & {_config: config}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVCBuilder & {_config: config}
		}

		if config.ingress.enabled {
			ingress: #IngressBuilder & {_config: config}
		}

		if config.serviceAccount.create {
			sa: #ServiceAccountBuilder & {_config: config}
		}

		if config.backup.enabled {
			backupCronJob: #BackupCronJobBuilder & {_config: config}
			if config.backup.s3.accessKey != "" && config.backup.s3.existingSecret == "" {
				backupSecret: #BackupSecretBuilder & {_config: config}
			}
		}
	}
}
