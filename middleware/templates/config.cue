package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Name and labels overrides matching Helm values.
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     *{} | {[string]: string}

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
	if commonLabels != _|_ {
		metadata: labels: commonLabels
	}

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!: timoniv1.#Image

	// Image pull secrets.
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	// Number of pod replicas. Recreate strategy used by default.
	replicas: *1 | int & >0

	// Middleware application configuration.
	middleware: {
		frontendPort:         *3333 | int & >0 & <=65535
		analyticsPort:        *9696 | int & >0 & <=65535
		syncPort:             *9697 | int & >0 & <=65535
		environment:          *"prod" | string
		internalDbEnabled:    *"false" | string
		internalRedisEnabled: *"false" | string
		timezone:             *"UTC" | string
		extraEnv:             *[] | [...corev1.#EnvVar]
	}

	// External PostgreSQL database settings (when not using bundled subchart).
	externalDatabase: {
		enabled:                   *false | bool
		host:                      *"" | string
		port:                      *5432 | int & >0 & <=65535
		name:                      *"mhq-oss" | string
		user:                      *"middleware" | string
		password:                  *"" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"user-password" | string
	}

	// External Redis settings (when not using bundled subchart).
	externalRedis: {
		enabled: *false | bool
		host:    *"" | string
		port:    *6379 | int & >0 & <=65535
	}

	// Bundled PostgreSQL configuration.
	postgresql: {
		enabled: *true | bool
		image:   *#_defaultPgImage | timoniv1.#Image
		auth: {
			database: *"mhq-oss" | string
			username: *"middleware" | string
			password: *"" | string
		}
		resources:          *{} | corev1.#ResourceRequirements
		podSecurityContext: *{} | corev1.#PodSecurityContext
		securityContext:    *{} | corev1.#SecurityContext
		persistence: {
			size:         *"8Gi" | timoniv1.#MemoryQuantity | string
			storageClass: *"" | string
			accessModes:  *[corev1.#ReadWriteOnce] | [...corev1.#PersistentVolumeAccessMode]
		}
	}

	#_defaultPgImage: timoniv1.#Image & {
		repository: *"docker.io/library/postgres" | string
		tag:        *"18.6-trixie" | string
		digest:     *"" | string
	}

	// Bundled Redis configuration.
	redis: {
		enabled:                      *true | bool
		image:                        *#_defaultRedisImage | timoniv1.#Image
		architecture:                 *"standalone" | string
		resources:                    *{} | corev1.#ResourceRequirements
		podSecurityContext:           *{} | corev1.#PodSecurityContext
		securityContext:              *{} | corev1.#SecurityContext
		automountServiceAccountToken: *false | bool
		persistence: {
			size:         *"8Gi" | timoniv1.#MemoryQuantity | string
			storageClass: *"" | string
			accessModes:  *[corev1.#ReadWriteOnce] | [...corev1.#PersistentVolumeAccessMode]
		}
	}

	#_defaultRedisImage: timoniv1.#Image & {
		repository: *"docker.io/library/redis" | string
		tag:        *"8.10.1" | string
		digest:     *"" | string
	}

	// Persistence for /app/keys.
	persistence: {
		enabled:       *true | bool
		size:          *"1Gi" | timoniv1.#MemoryQuantity | string
		storageClass:  *"" | string
		accessModes:   *[corev1.#ReadWriteOnce] | [...corev1.#PersistentVolumeAccessMode]
		existingClaim: *"" | string
	}

	// Service account configuration.
	serviceAccount: {
		create:                       *false | bool
		name:                         *"" | string
		annotations:                  *{} | timoniv1.#Annotations
		automountServiceAccountToken: *false | bool
	}

	// Service configuration.
	service: {
		type:        *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port:        *80 | int & >0 & <=65535
		annotations: *{} | timoniv1.#Annotations
	}

	// Ingress configuration.
	ingress: {
		enabled:          *false | bool
		ingressClassName: *"traefik" | string
		annotations:     *{} | timoniv1.#Annotations
		hosts:            *[] | [...{
			host: string
			paths: *[{
				path:     *"/" | string
				pathType: *"Prefix" | string
			}] | [...{
				path:     string
				pathType: *"Prefix" | "Exact" | "ImplementationSpecific" | string
			}]
		}]
		tls: *[] | [...{
			hosts: [...string]
			secretName: string
		}]
	}

	// Gateway API
	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes:       *[] | [...{
			name?:        string
			labels?:      {[string]: string}
			annotations?: {[string]: string}
			parentRefs:   [...{
				name:         string
				namespace?:   string
				group?:       string
				kind?:        string
				sectionName?: string
				port?:        int
			}]
			hostnames?:   [...string]
			rules?:       [...{
				matches?: [...{
					path?: {
						type?:  *"PathPrefix" | "Exact" | "RegularExpression" | string
						value?: string
					}
					headers?: [...{
						type?:  *"Exact" | "RegularExpression" | string
						name:   string
						value:  string
					}]
					queryParams?: [...{
						type?:  *"Exact" | "RegularExpression" | string
						name:   string
						value:  string
					}]
					method?: string
				}]
				filters?: [..._]
				backendRefs?: [...{
					name:       string
					namespace?: string
					port?:      int
					group?:     string
					kind?:      string
					weight?:    int
				}]
				omitDefaultBackend?: bool
			}]
		}]
	}

	// Health probes configuration.
	probes: {
		startup: {
			enabled:             *true | bool
			initialDelaySeconds: *30 | int
			periodSeconds:       *5 | int
			timeoutSeconds:      *3 | int
			failureThreshold:    *30 | int
		}
		liveness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int
			periodSeconds:       *15 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
		readiness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
	}

	// Compute resources.
	resources: *{} | corev1.#ResourceRequirements

	// Security contexts.
	podSecurityContext: *{} | corev1.#PodSecurityContext
	securityContext:    *{} | corev1.#SecurityContext

	// Scheduling.
	nodeSelector: *{} | {[string]: string}
	tolerations:  *[] | [...corev1.#Toleration]
	affinity:     *{} | (timoniv1.#AffinityValues & {
		podAntiAffinity?: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:    corev1.#NodeAffinity
		podAffinity?:     corev1.#PodAffinity
	})
	topologySpreadConstraints:     *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int

	// Pod metadata.
	podLabels:      *{} | {[string]: string}
	podAnnotations: *{} | {[string]: string}

	// Extra volumes and volume mounts.
	extraVolumes:      *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]

	// Extra manifests to deploy.
	extraManifests: *[] | [...{
		apiVersion: string
		kind:       string
		metadata: {
			name: string
			[string]: _
		}
		[string]: _
	}]

	// Test Job settings.
	test: {
		enabled: *false | bool
		image!:  timoniv1.#Image
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		deploy: #Deployment & {#config: config}
		svc:    #Service & {#config: config}
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.gatewayAPI.enabled {
			for i, route in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {#config: config, #route: route, #index: i}
			}
		}
		if config.postgresql.enabled && !config.externalDatabase.enabled {
			"pg-auth":         #PostgresqlSecret & {#config: config}
			"pg-config":       #PostgresqlConfigMap & {#config: config}
			"pg-initdb":       #PostgresqlInitDb & {#config: config}
			"pg-headless-svc": #PostgresqlHeadlessService & {#config: config}
			"pg-svc":          #PostgresqlService & {#config: config}
			"pg-sts":          #PostgresqlStatefulSet & {#config: config}
		}
		if config.redis.enabled && !config.externalRedis.enabled {
			"redis-auth":         #RedisSecret & {#config: config}
			"redis-config":       #RedisConfigMap & {#config: config}
			"redis-headless-svc": #RedisHeadlessService & {#config: config}
			"redis-svc":          #RedisService & {#config: config}
			"redis-sts":          #RedisStatefulSet & {#config: config}
		}
		for i, manifest in config.extraManifests {
			"extra-\(i)": manifest
		}
	}

	tests: {
		"test-svc": #TestJob & {#config: config}
	}
}
