package templates

import (
	appsv1 "k8s.io/api/apps/v1"
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

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!: timoniv1.#Image

	// The resources allows setting the container resource requirements.
	// Defaults match TrueCharts nexus-oss specifications.
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

	// The number of pod replicas.
	// By default, the number of replicas is 1.
	replicas: *1 | int & >0

	// The revision history limit.
	revisionHistoryLimit: *3 | int & >=0

	// Deployment strategy.
	strategy: appsv1.#DeploymentStrategy & {
		type: *appsv1.#RecreateDeploymentStrategyType | appsv1.#DeploymentStrategyType
	}

	// Security context matching values.yaml (container and pod).
	securityContext: {
		container: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *200 | int64
			runAsGroup:               *200 | int64
			seccompProfile: {
				type: *corev1.#SeccompProfileTypeRuntimeDefault | corev1.#SeccompProfileType
			}
			capabilities: corev1.#Capabilities & {
				drop: *["ALL"] | [...string]
				add:  *[] | [...string]
			}
		}
		pod: corev1.#PodSecurityContext & {
			fsGroup:             *200 | int64
			fsGroupChangePolicy: *corev1.#FSGroupChangeOnRootMismatch | corev1.#PodFSGroupChangePolicy
			supplementalGroups:  *[568] | [...int64]
			sysctls:             *[] | [...corev1.#Sysctl]
		}
	}

	// Service settings matching values.yaml.
	service: {
		main: {
			type: *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			ports: {
				main: {
					port:       *10288 | int & >0 & <=65535
					targetPort: *8081 | int & >0 & <=65535
					protocol:   *"TCP" | string
				}
			}
			publishNotReadyAddresses: *false | bool
			annotations?:             timoniv1.#Annotations
		}
	}

	// ServiceAccount settings.
	serviceAccount: {
		create:       *false | bool
		name:         *"" | string
		annotations?: timoniv1.#Annotations
	}

	automountServiceAccountToken: *false | bool
	hostNetwork:                  *false | bool
	hostPID:                      *false | bool
	hostIPC:                      *false | bool
	shareProcessNamespace:        *false | bool
	enableServiceLinks:           *false | bool
	restartPolicy:                *corev1.#RestartPolicyAlways | corev1.#RestartPolicy
	hostUsers:                    *true | bool

	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	dnsPolicy: *corev1.#DNSClusterFirst | corev1.#DNSPolicy
	dnsConfig: *{
		options: [
			{
				name:  "ndots"
				value: "1"
			},
		]
	} | corev1.#PodDNSConfig

	terminationGracePeriodSeconds: *60 | int & >=0

	// Pod optional settings.
	podAnnotations?:            {[string]: string}
	podLabels?:                 timoniv1.#Labels
	imagePullSecrets?:          [...timoniv1.#ObjectReference]
	tolerations?:               [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// The affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	// Persistence settings matching values.yaml.
	persistence: {
		data: {
			enabled:       *true | bool
			mountPath:     *"/nexus-data" | string
			accessMode:    *corev1.#ReadWriteOnce | corev1.#PersistentVolumeAccessMode
			size:          *"100Gi" | string
			storageClass?: string
		}
	}

	// Workload settings matching values.yaml.
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						env: {
							INSTALL4J_ADD_VM_PARAMS: *"-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs" | string
						}
					}
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
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.persistence.data.enabled {
			pvc: #PersistentVolumeClaim & {#config: config}
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
