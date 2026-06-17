package templates

import (
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

	// The image values mirror the upstream Helm chart values.
	image: {
		repository: *"calcom/cal.com" | string
		tag:        string
		pullPolicy: *"IfNotPresent" | string
	}

	replicaCount: *1 | int

	imagePullSecrets: *[] | [...{name: string}]
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	podAnnotations: *{} | {[string]: string}

	podSecurityContext: *{} | {[string]: _}

	// The service values mirror the upstream Helm chart values.
	service: {
		main: {
			type: *"ClusterIP" | "ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
			ports: http: port: *3000 | int & >0 & <=65535
		}
	}

	// The ingress values mirror the upstream Helm chart values and common defaults.
	ingress: {
		main: {
			enabled: *false | bool
			primary: *true | bool
			nameOverride?: string
			annotations: *{} | {[string]: string}
			labels:      *{} | {[string]: string}
			className:   *"" | string
			hosts: *[
				{
					host: "chart-example.local"
					paths: [{
						path:     *"/" | string
						pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
						service: *{} | {
							name: *"" | string
							port: *0 | int & >=0 & <=65535
						}
					}]
				},
			] | [...{
				host: string
				paths: [...{
					path:     *"/" | string
					pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
					service: *{} | {
						name: *"" | string
						port: *0 | int & >=0 & <=65535
					}
				}]
			}]
			tls: *[] | [...{
				secretName?: string
				hosts: [...string]
			}]
		}
	}

	// Name of the Secret containing the required environment variables.
	secretRef: *"" | string

	_secretRef: string
	if secretRef != "" {
		_secretRef: secretRef
	}
	if secretRef == "" {
		_secretRef: metadata.name
	}

	// Automatically run database migrations on startup/upgrade.
	databaseMigration: *true | bool

	// Secret configuration for managing credentials via Timoni.
	secret: {
		enabled: *false | bool
		name:    *metadata.name | string
		data:    *{} | {[string]: string}
	}

	// Environment variables passed to the Cal.com container.
	env: *{} | {[string]: null | string | bool | int | number}

	// Security context applied to the Cal.com container and pod.
	securityContext: {
		automountServiceAccountToken: *false | bool
		seccompProfile:              *"RuntimeDefault" | "RuntimeDefault" | "Unconfined"
		appArmorProfile:             *"runtime/default" | string
		runAsUser:              *10001 | int
		runAsGroup:             *10001 | int
		fsGroup?:               int
		runAsNonRoot:           *true | bool
		readOnlyRootFilesystem: *true | bool
		capabilities: {
			drop: *["ALL"] | [...string]
		}
	}

	// Resources applied to the Cal.com container.
	resources: {
		requests: {
			cpu:    *"100m" | string
			memory: *"256Mi" | string
		}
		limits: {
			cpu:    *"1000m" | string
			memory: *"1Gi" | string
		}
	}

	// Autoscaling configuration.
	autoscaling: {
		enabled:                        *false | bool
		minReplicas:                    *1 | int & >0
		maxReplicas:                    *10 | int & >=minReplicas
		targetCPUUtilizationPercentage: *80 | int & >0 & <=100
		targetMemoryUtilizationPercentage: *80 | int & >0 & <=100
	}

	nodeSelector: *{} | {[string]: string}
	tolerations:  *[] | [...{}]
	affinity:     *{} | {[string]: _}

	// PostgreSQL configuration
	postgresql: {
		enabled: *false | bool
		image: {
			repository: *"postgres" | string
			tag:        *"16-alpine" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			username:         *"user" | string
			password:         *"password" | string
			database:         *"calcom" | string
			postgresPassword: *"postgres" | string
		}
		storage: {
			size:         *"10Gi" | string
			storageClass: *"standard" | string
		}
		resources: {
			requests: {
				cpu:    *"100m" | string
				memory: *"256Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"512Mi" | string
			}
		}
		service: {
			name: *"postgresql" | string
			port: *5432 | int & >0 & <=65535
		}
	}

	test: {
		enabled: bool | *false
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		svc:       #Service & {#config: config}
		deploy:    #Deployment & {#config: config}
		if config.ingress.main.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}
		if config.secret.enabled {
			secret: #Secret & {#config: config}
		}
		if config.postgresql.enabled {
			postgresql_pvc:    #PostgreSQLPVC & {#config: config}
			postgresql_secret: #PostgreSQLSecret & {#config: config}
			postgresql_svc:    #PostgreSQLService & {#config: config}
			postgresql_statefulset: #PostgreSQLStatefulSet & {#config: config}
		}
	}
}