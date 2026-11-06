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

	// The image configuration, mirroring values.yaml.
	image: timoniv1.#Image & {
		repository: *"docker.io/fletchto99/hexo-dev-blog" | string
		tag:        *"latest@sha256:76b545d32ba15df60867e0dd3ef818bc833dcf9c23dac51e6efa355af2d8f6e2" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}

	// Persistence configuration for Hexo data and config, mirroring values.yaml.
	persistence: {
		config: {
			enabled:        *true | bool
			mountPath:      *"/config" | string
			accessMode:     *"ReadWriteOnce" | string
			size:           *"100Gi" | string
			storageClass?:  string
			existingClaim?: string
		}
	}

	// Security context configuration, mirroring values.yaml.
	securityContext: {
		container: corev1.#SecurityContext & {
			readOnlyRootFilesystem:   *false | bool
			runAsGroup:               *0 | int
			runAsUser:                *0 | int
			runAsNonRoot:             *false | bool
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
			capabilities: {
				add: *["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
	}

	// Pod security context settings, mirroring hexo.yaml.
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup:             *568 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		supplementalGroups:  *[568] | [...int]
		sysctls:             *[] | [...corev1.#Sysctl]
	}

	// Service configuration, mirroring values.yaml.
	service: {
		main: {
			annotations?:              timoniv1.#Annotations
			publishNotReadyAddresses: *false | bool
			ports: {
				main: {
					port:       *10306 | int & >0 & <=65535
					protocol:   *"http" | "https" | "TCP" | "UDP" | string
					targetPort: *8080 | int & >0 & <=65535
				}
			}
		}
	}

	// Workload container configuration, mirroring values.yaml.
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						env: {
							TZ:                     *"UTC" | string
							UMASK:                  *"0022" | string
							UMASK_SET:              *"0022" | string
							NVIDIA_VISIBLE_DEVICES: *"void" | string
							PUID:                   *"568" | string
							USER_ID:                *"568" | string
							UID:                    *"568" | string
							PGID:                   *"568" | string
							GROUP_ID:               *"568" | string
							GID:                    *"568" | string
							HEXO_PLUGINS:           *"" | string
							[string]:               string
						}
					}
				}
			}
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

	// The number of pods replicas.
	replicas: *1 | int & >0

	// Revision history limit for Deployment.
	revisionHistoryLimit: *3 | int32

	// Health check probes matching hexo.yaml.
	probes: {
		liveness: corev1.#Probe & {
			httpGet: {
				path:   *"/" | string
				port:   *8080 | int | string
				scheme: *"HTTP" | string
			}
			initialDelaySeconds: *12 | int
			failureThreshold:    *5 | int
			successThreshold:    *1 | int
			timeoutSeconds:      *5 | int
			periodSeconds:       *15 | int
		}
		readiness: corev1.#Probe & {
			httpGet: {
				path:   *"/" | string
				port:   *8080 | int | string
				scheme: *"HTTP" | string
			}
			initialDelaySeconds: *10 | int
			failureThreshold:    *4 | int
			successThreshold:    *2 | int
			timeoutSeconds:      *5 | int
			periodSeconds:       *12 | int
		}
		startup: corev1.#Probe & {
			httpGet: {
				path:   *"/" | string
				port:   *8080 | int | string
				scheme: *"HTTP" | string
			}
			initialDelaySeconds: *10 | int
			failureThreshold:    *60 | int
			successThreshold:    *1 | int
			timeoutSeconds:      *3 | int
			periodSeconds:       *5 | int
		}
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]

	// Topology spread constraints mirroring hexo.yaml.
	topologySpreadConstraints: *[
		{
			maxSkew:           1
			whenUnsatisfiable: "ScheduleAnyway"
			topologyKey:       "kubernetes.io/hostname"
			labelSelector: matchLabels: selector.labels
			nodeAffinityPolicy: "Honor"
			nodeTaintsPolicy:   "Honor"
		},
	] | [...corev1.#TopologySpreadConstraint]

	// Node selector mirroring hexo.yaml.
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// Affinity rules mirroring hexo.yaml.
	affinity: corev1.#Affinity & {
		if persistence.config.enabled {
			podAffinity: {
				requiredDuringSchedulingIgnoredDuringExecution: [
					{
						topologyKey: *"kubernetes.io/hostname" | string
						labelSelector: matchExpressions: [
							{
								key:      "truecharts.org/pvc"
								operator: "In"
								values: ["config"]
							},
						]
					},
				]
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
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa:  #ServiceAccount & {#config: config}
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
		if config.persistence.config.enabled && config.persistence.config.existingClaim == _|_ {
			pvc: #PersistentVolumeClaim & {#config: config}
		}

		deploy: #Deployment & {#config: config}
	}
}
