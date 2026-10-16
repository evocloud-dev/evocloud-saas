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
	metadata: timoniv1.#Metadata & {
		#Version: moduleVersion
		labels: {
			"app.kubernetes.io/instance": metadata.name
			release:                      metadata.name
		}
	}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	_fullname: metadata.name
	_labels:   metadata.labels

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {
		#Name: metadata.name
		labels: {
			"app.kubernetes.io/instance": metadata.name
			"pod.name":                   "main"
		}
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!: timoniv1.#Image

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
	// By default, the number of replicas is 1.
	replicas: *1 | int & >0

	// Service account name for the pod.
	serviceAccountName: *"default" | string

	// Timezone used for container env.
	TZ: *"UTC" | string

	// The securityContext allows setting the container and pod security context,
	// mirroring values.yaml (securityContext.container and securityContext.pod).
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
				add: *["NET_BIND_SERVICE", "CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		pod: corev1.#PodSecurityContext & {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | corev1.#PodFSGroupChangePolicy
			supplementalGroups:  *[568] | [...int]
			sysctls: *[
				{
					name:  "net.ipv4.ip_unprivileged_port_start"
					value: "80"
				},
			] | [...corev1.#Sysctl]
		}
	}

	// The service allows setting the Kubernetes Service configuration,
	// mirroring values.yaml (service.main.ports.main).
	service: {
		main: {
			enabled:                  *true | bool
			type:                     *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			publishNotReadyAddresses: *false | bool
			annotations?:             timoniv1.#Annotations
			ports: {
				main: {
					enabled:    *true | bool
					port:       *10012 | int & >0 & <=65535
					protocol:   *"TCP" | corev1.#Protocol
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
		matches?:            [...]
		filters?:            [...]
		backendRefs?:        [...]
		omitDefaultBackend: *false | bool
	}

	#HTTPRouteItem: {
		name:         *"" | string
		labels?:      {[string]: string}
		annotations?: {[string]: string}
		parentRefs!:  [...#HTTPRouteParentRef] & [_, ...]
		hostnames:    *[] | [...string]
		rules:        *[] | [...#HTTPRouteRule]
	}

	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes:       *[] | [...#HTTPRouteItem]
	}

	// Persistence settings for grav volumes, mirroring values.yaml.
	persistence: {
		config: {
			enabled:       *true | bool
			mountPath:     *"/config" | string
			readOnly:      *false | bool
			size:          *"100Gi" | string
			accessModes:   *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
			storageClass?: string
		}
		devshm: {
			enabled:   *true | bool
			mountPath: *"/dev/shm" | string
			readOnly:  *false | bool
			medium:    *"Memory" | corev1.#StorageMedium
			sizeLimit: *"2400Mi" | string
		}
		shared: {
			enabled:   *true | bool
			mountPath: *"/shared" | string
			readOnly:  *false | bool
		}
		tmp: {
			enabled:   *true | bool
			mountPath: *"/tmp" | string
			readOnly:  *false | bool
			medium:    *"Memory" | corev1.#StorageMedium
			sizeLimit: *"2400Mi" | string
		}
		varlogs: {
			enabled:   *true | bool
			mountPath: *"/var/logs" | string
			readOnly:  *false | bool
			medium:    *"Memory" | corev1.#StorageMedium
			sizeLimit: *"2400Mi" | string
		}
		varrun: {
			enabled:   *true | bool
			mountPath: *"/var/run" | string
			readOnly:  *false | bool
			medium:    *"Memory" | corev1.#StorageMedium
			sizeLimit: *"2400Mi" | string
		}
	}

	// Container environment variables.
	env: *[
		{
			name:  "TZ"
			value: TZ
		},
		{
			name:  "UMASK"
			value: "0022"
		},
		{
			name:  "UMASK_SET"
			value: "0022"
		},
		{
			name:  "NVIDIA_VISIBLE_DEVICES"
			value: "void"
		},
		{
			name:  "PUID"
			value: "568"
		},
		{
			name:  "USER_ID"
			value: "568"
		},
		{
			name:  "UID"
			value: "568"
		},
		{
			name:  "PGID"
			value: "568"
		},
		{
			name:  "GROUP_ID"
			value: "568"
		},
		{
			name:  "GID"
			value: "568"
		},
	] | [...corev1.#EnvVar]

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints: *[
		{
			maxSkew:           1
			whenUnsatisfiable: "ScheduleAnyway"
			topologyKey:       "kubernetes.io/hostname"
			labelSelector: {
				matchLabels: selector.labels
			}
			nodeAffinityPolicy: "Honor"
			nodeTaintsPolicy:   "Honor"
		},
	] | [...corev1.#TopologySpreadConstraint]

	// Pods are scheduled on amd64 nodes by default.
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// The affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: *"none" | timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
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
									"config",
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
		if config.persistence.config.enabled {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if config.service.main.enabled {
			svc: #Service & {#config: config}
		}
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