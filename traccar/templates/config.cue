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
	selector: timoniv1.#Selector & {
		#Name: metadata.name
		labels: {
			"pod.name":                   "main"
			"app.kubernetes.io/instance": metadata.name
		}
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	image!: timoniv1.#Image & {
		digest: *"" | string
	}

	// Service configuration mirroring values.yaml (service.main.ports.main)
	service: {
		main: {
			ports: {
				main: {
					port:       *8082 | int & >0 & <=65535
					targetPort: *8082 | int & >0 & <=65535
				}
			}
		}
		port:         *main.ports.main.port | int & >0 & <=65535
		targetPort:   *main.ports.main.targetPort | int & >0 & <=65535
		portName:     *"main" | string
		annotations?: timoniv1.#Annotations
	}

	// Persistence configuration mirroring values.yaml (persistence.data)
	persistence: {
		data: {
			enabled:     *true | bool
			mountPath:   *"/opt/traccar/data" | string
			accessModes: *["ReadWriteOnce"] | [...string]
			size:        *"100Gi" | string
			storageClass?: string
		}
	}

	// CNPG (CloudNativePG) database configuration mirroring values.yaml (cnpg.main)
	cnpg: {
		main: {
			enabled:  *true | bool
			user:     *"traccar" | string
			database: *"traccar" | string
			image?: timoniv1.#Image
			resources?: timoniv1.#ResourceRequirements
		}
		enabled:    *main.enabled | bool
		user:       *main.user | string
		database:   *main.database | string
		password:   *"PLACEHOLDERPASSWORD" | string
		port:       *5432 | int & >0 & <=65535
		instances:  *2 | int & >0
		storage:    *"100Gi" | string
		walStorage: *"100Gi" | string
		resources: timoniv1.#ResourceRequirements & {
			if main.resources != _|_ {
				main.resources
			}
			requests: {
				cpu:    *"75m" | timoniv1.#CPUQuantity
				memory: *"200Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1500m" | timoniv1.#CPUQuantity
				memory: *"2400Mi" | timoniv1.#MemoryQuantity
			}
		}
		image: timoniv1.#Image & {
			if main.image != _|_ {
				main.image
			}
			repository: *"ghcr.io/cloudnative-pg/postgresql" | string
			tag:        *"16.15" | string
			digest:     *"sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a" | string
		}
	}

	// SecurityContext mirroring values.yaml (securityContext.container)
	securityContext: {
		container: {
			runAsNonRoot:           *false | bool
			readOnlyRootFilesystem: *false | bool
			runAsUser:              *0 | int
			runAsGroup:             *0 | int
		}
		allowPrivilegeEscalation: *false | bool
		privileged:               *false | bool
		seccompProfile: corev1.#SeccompProfile & {
			type: *"RuntimeDefault" | corev1.#SeccompProfileType
		}
		capabilities: {
			drop: *["ALL"] | [...string]
			add: *["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
		}
	}

	// Workload configuration mirroring values.yaml (workload.main.podSpec)
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						resources?: timoniv1.#ResourceRequirements
						env: {
							CONFIG_USE_ENVIRONMENT_VARIABLES: *true | bool
							LOGGER_CONSOLE:                   *true | bool
							DATABASE_DRIVER:                  *"org.postgresql.Driver" | string
							DATABASE_USER:                    *cnpg.user | string
							DATABASE_PASSWORD: {
								secretKeyRef: {
									name: *"cnpg-main-user" | string
									key:  *"password" | string
								}
							}
							DATABASE_URL: {
								secretKeyRef: {
									name: *"cnpg-main-urls" | string
									key:  *"jdbc" | string
								}
							}
						}
					}
				}
			}
		}
	}

	// ServiceAccount configuration.
	serviceAccount: {
		create: *false | bool
		name:   string
		if !create {
			name: *"default" | string
		}
		if create {
			name: *metadata.name | string
		}
	}

	// The resources allows setting the container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"75m" | timoniv1.#CPUQuantity
			memory: *"200Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"1500m" | timoniv1.#CPUQuantity
			memory: *"2400Mi" | timoniv1.#MemoryQuantity
		}
	}

	// Init containers configuration mirroring values.yaml (initContainers)
	initContainers: {
		"system-cnpg-wait": {
			image: timoniv1.#Image & {
				repository: *"oci.trueforge.org/containerforge/postgresql-client" | string
				tag:        *"9.6.24" | string
				digest:     *"sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93" | string
			}
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    *"10m" | timoniv1.#CPUQuantity
					memory: *"50Mi" | timoniv1.#MemoryQuantity
				}
				limits: {
					cpu:    *"500m" | timoniv1.#CPUQuantity
					memory: *"512Mi" | timoniv1.#MemoryQuantity
				}
			}
		}
	}

	// The number of pods replicas.
	replicas: *1 | int & >0

	// Environment configuration
	env: {
		TZ:   *"UTC" | string
		PUID: *568 | int
		PGID: *568 | int
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup:             *568 | int
		fsGroupChangePolicy: *"OnRootMismatch" | corev1.#PodFSGroupChangePolicy
		supplementalGroups:  *[568] | [...int]
		sysctls:             *[] | [...corev1.#Sysctl]
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints: *[
		corev1.#TopologySpreadConstraint & {
			maxSkew:            1
			whenUnsatisfiable:  "ScheduleAnyway"
			topologyKey:        "kubernetes.io/hostname"
			labelSelector:      matchLabels: selector.labels
			nodeAffinityPolicy: "Honor"
			nodeTaintsPolicy:   "Honor"
		},
	] | [...corev1.#TopologySpreadConstraint]

	// Pods are scheduled on amd64 nodes by default (as in traccar.yaml).
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// Affinity rules matching traccar.yaml podAffinity to pvc data.
	affinity: corev1.#Affinity & {
		podAffinity: {
			requiredDuringSchedulingIgnoredDuringExecution: [
				{
					topologyKey: "kubernetes.io/hostname"
					labelSelector: matchExpressions: [
						{
							key:      "truecharts.org/pvc"
							operator: "In"
							values: ["data"]
						},
					]
				},
			]
		}
	}
	// Gateway API settings
	#HTTPRouteParentRef: {
		name!:       string
		group:       *"" | string
		kind:        *"" | string
		namespace:   *"" | string
		sectionName: *"" | string
		port:        *0 | int
	}

	#HTTPRouteRule: {
		matches?: [...]
		filters?: [...]
		backendRefs?: [...]
		omitDefaultBackend: *false | bool
	}

	#HTTPRouteItem: {
		name: *"" | string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		parentRefs!: [...#HTTPRouteParentRef] & [_, ...]
		hostnames: *[] | [...string]
		rules: *[] | [...#HTTPRouteRule]
	}

	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes: *[] | [...#HTTPRouteItem]
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.cnpg.enabled {
			"cnpg-urls":    #CNPGUrlsSecret & {#config: config}
			"cnpg-user":    #CNPGUserSecret & {#config: config}
			"cnpg-cluster": #CNPGCluster & {#config: config}
		}
		if config.persistence.data.enabled {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		svc:    #Service & {#config: config}
		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {
					#config: config
					#route:  r
					#index:  i
				}
			}
		}
		deploy: #Deployment & {#config: config}
	}
}
