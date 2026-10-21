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
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {
		#Version: moduleVersion
		labels: {
			"app.kubernetes.io/instance": metadata.name
		}
	}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	_fullname: metadata.name
	_labels:   metadata.labels

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {
		#Name: metadata.name
		labels: {
			"app.kubernetes.io/instance": metadata.name
			"pod.name":                   *"main" | string
		}
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	image!: timoniv1.#Image

	// Timezone and user/group settings.
	tz: *"UTC" | string

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

	// The number of pods replicas.
	replicas: *1 | int & >0

	// Persistence configuration for farmOS sites directory.
	persistence: {
		sitesdirectory: {
			enabled:   *true | bool
			mountPath: *"/var/www/html/sites" | string
			size:      *"100Gi" | string
			accessModes: *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
			storageClass?: string
		}
	}

	// PostgreSQL database settings.
	postgresql: {
		enabled: *true | bool
		image!:  timoniv1.#Image
		auth: {
			database: *"farmos" | string
			username: *"farmos" | string
			password: *"farmos-secret-password" | string
		}
		service: {
			port: *5432 | int & >0 & <=65535
		}
		persistence: {
			enabled: *true | bool
			size:    *"10Gi" | string
			accessModes: *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
			storageClass?: string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"50m" | timoniv1.#CPUQuantity
				memory: *"128Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"1024Mi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// SecurityContext configuration for container and pod.
	securityContext: {
		container: corev1.#SecurityContext & {
			runAsNonRoot:             *false | bool
			runAsUser:                *0 | int
			runAsGroup:               *0 | int
			readOnlyRootFilesystem:   *false | bool
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
			capabilities: {
				add: *[
					"NET_BIND_SERVICE",
					"CHOWN",
					"SETUID",
					"SETGID",
					"FOWNER",
					"DAC_OVERRIDE",
				] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		pod: corev1.#PodSecurityContext & {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | corev1.#PodFSGroupChangePolicy
			supplementalGroups: *[568] | [...int]
			sysctls: *[
				{
					name:  "net.ipv4.ip_unprivileged_port_start"
					value: "80"
				},
			] | [...corev1.#Sysctl]
		}
	}

	// Service configuration mirroring Helm service.main.ports.main.
	service: {
		main: {
			annotations?: timoniv1.#Annotations
			type:         *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			ports: {
				main: {
					port:       *80 | int & >0 & <=65535
					protocol:   *"TCP" | "UDP" | "SCTP" | "tcp" | "udp" | "sctp"
					targetPort: *80 | int & >0 & <=65535
				}
			}
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

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// NodeSelector defaults to amd64 architecture as in farmos.yaml.
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// Affinity rules.
	affinity: {
		nodeAffinity?:    corev1.#NodeAffinity
		podAntiAffinity?: corev1.#PodAntiAffinity
		podAffinity: *{
			requiredDuringSchedulingIgnoredDuringExecution: [
				{
					topologyKey: "kubernetes.io/hostname"
					labelSelector: {
						matchExpressions: [
							{
								key:      "truecharts.org/pvc"
								operator: "In"
								values: [
									"sitesdirectory",
								]
							},
						]
					}
				},
			]
		} | corev1.#PodAffinity
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.persistence.sitesdirectory.enabled {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if config.postgresql.enabled {
			pgSecret: #PostgresqlSecret & {#config: config}
			pgSvc: #PostgresqlService & {#config: config}
			pgSts: #PostgresqlStatefulSet & {#config: config}
		}
		svc: #Service & {#config: config}
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
