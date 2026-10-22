package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// ProbeConfig defines the HTTP probe settings for the container.
#ProbeConfig: {
	type: *"http" | "https"
	path: *"/" | string
	scheme: corev1.#URIScheme & [
		if type == "https" {"HTTPS"},
		"HTTP",
	][0]
	initialDelaySeconds: int & >=0
	failureThreshold:    int & >=1
	successThreshold:    int & >=1
	timeoutSeconds:      int & >=1
	periodSeconds:       int & >=1
}

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
			"pod.name":                   *"main" | string
		}
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!: timoniv1.#Image

	// Security context settings mirroring values.yaml (`securityContext.container`) and pod defaults.
	securityContext: {
		container: corev1.#SecurityContext & {
			runAsNonRoot:             *false | bool
			runAsUser:                *0 | int
			runAsGroup:               *0 | int
			readOnlyRootFilesystem:   *false | bool
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			seccompProfile: {
				type: *"RuntimeDefault" | corev1.#SeccompProfileType
			}
			capabilities: {
				add: *["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		pod: corev1.#PodSecurityContext & {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | corev1.#PodFSGroupChangePolicy
			supplementalGroups: *[568] | [...int]
			sysctls: *[] | [...corev1.#Sysctl]
		}
	}

	// Service settings mirroring values.yaml (`service.main.ports.main`).
	service: {
		main: {
			enabled:                  *true | bool
			annotations?:             timoniv1.#Annotations
			type:                     *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			publishNotReadyAddresses: *false | bool
			ports: {
				main: {
					enabled:    *true | bool
					port:       *10214 | int & >0 & <=65535
					targetPort: *8080 | int & >0 & <=65535
					protocol:   *corev1.#ProtocolTCP | corev1.#Protocol
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

	// Workload settings mirroring values.yaml (`workload.main.podSpec.containers.main`).
	workload: {
		main: {
			replicas:             *1 | int & >0
			revisionHistoryLimit: *3 | int & >=0
			strategy: appsv1.#DeploymentStrategy & {
				type: *"Recreate" | appsv1.#DeploymentStrategyType
			}
			podSpec: {
				serviceAccountName:           *"default" | string
				automountServiceAccountToken: *false | bool
				hostNetwork:                  *false | bool
				hostPID:                      *false | bool
				hostIPC:                      *false | bool
				shareProcessNamespace:        *false | bool
				enableServiceLinks:           *false | bool
				restartPolicy:                *corev1.#RestartPolicyAlways | corev1.#RestartPolicy
				dnsPolicy:                    *corev1.#DNSClusterFirst | corev1.#DNSPolicy
				dnsConfig: corev1.#PodDNSConfig & {
					options: *[
						{
							name:  "ndots"
							value: "1"
						},
					] | [...corev1.#PodDNSConfigOption]
				}
				terminationGracePeriodSeconds: *60 | int & >=0
				hostUsers:                     *true | bool
				containers: {
					main: {
						probes: {
							liveness: #ProbeConfig & {
								initialDelaySeconds: *12 | int & >=0
								failureThreshold:    *5 | int & >=1
								successThreshold:    *1 | int & >=1
								timeoutSeconds:      *5 | int & >=1
								periodSeconds:       *15 | int & >=1
							}
							readiness: #ProbeConfig & {
								initialDelaySeconds: *10 | int & >=0
								failureThreshold:    *4 | int & >=1
								successThreshold:    *2 | int & >=1
								timeoutSeconds:      *5 | int & >=1
								periodSeconds:       *12 | int & >=1
							}
							startup: #ProbeConfig & {
								initialDelaySeconds: *10 | int & >=0
								failureThreshold:    *60 | int & >=1
								successThreshold:    *1 | int & >=1
								timeoutSeconds:      *3 | int & >=1
								periodSeconds:       *5 | int & >=1
							}
						}
						env: {[string]: string}
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

	// Affinity rules (optional).
	affinity?: corev1.#Affinity
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
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
