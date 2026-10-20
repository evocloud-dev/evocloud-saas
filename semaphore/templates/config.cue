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

	_fullname: metadata.name
	_labels:   metadata.labels

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

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
	replicas: *1 | int & >0

	// Security context settings mirroring values.yaml (`securityContext.container`) and pod/initContainer defaults.
	securityContext: {
		container: corev1.#SecurityContext & {
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *false | bool
			runAsUser:                *0 | int
			runAsGroup:               *0 | int
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
		initContainer: corev1.#SecurityContext & {
			runAsNonRoot:             *true | bool
			runAsUser:                *568 | int
			runAsGroup:               *568 | int
			readOnlyRootFilesystem:   *true | bool
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
			capabilities: {
				add:  *[] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		pod: corev1.#PodSecurityContext & {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			supplementalGroups:  *[568] | [...int]
			sysctls:             *[] | [...corev1.#Sysctl]
		}
	}

	// The service settings mirroring values.yaml (`service.main.ports.main`).
	service: {
		main: {
			annotations?:            timoniv1.#Annotations
			type:                    *"ClusterIP" | string
			publishNotReadyAddresses: *false | bool
			ports: {
				main: {
					port:       *3000 | int & >0 & <=65535
					protocol:   *"http" | "tcp" | "TCP" | "HTTP" | string
					targetPort: *3000 | int & >0 & <=65535
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

	// Workload configuration mirroring values.yaml (`workload.main.podSpec.containers.main.env`).
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						env: {
							SEMAPHORE_DB_DIALECT: *"postgres" | string
							SEMAPHORE_DB_USER:    *cnpg.main.user | string
							SEMAPHORE_DB:         *cnpg.main.database | string
							SEMAPHORE_DB_PORT:    *5432 | int | string
							SEMAPHORE_DB_HOST: {
								secretKeyRef: {
									name: *"cnpg-main-urls" | string
									key:  *"host" | string
								}
							}
							SEMAPHORE_DB_PASS: {
								secretKeyRef: {
									name: *"cnpg-main-user" | string
									key:  *"password" | string
								}
							}
							SEMAPHORE_ACCESS_KEY_ENCRYPTION: {
								secretKeyRef: {
									name: *"semaphore-secrets" | string
									key:  *"SEMAPHORE_ACCESS_KEY_ENCRYPTION" | string
								}
							}
							SEMAPHORE_PLAYBOOK_PATH:  *persistence.data.mountPath | string
							SEMAPHORE_ADMIN:          *"admin" | string
							SEMAPHORE_ADMIN_NAME:     *"admin" | string
							SEMAPHORE_ADMIN_PASSWORD: *"changeme" | string
							SEMAPHORE_ADMIN_EMAIL:    *"admin@localhost" | string
							SEMAPHORE_LDAP_ACTIVATED: *"no" | string
							SEMAPHORE_LDAP_NEEDTLS:   *"no" | string
							[string]:                 #EnvValue
						}
					}
				}
			}
		}
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// Pods are scheduled on amd64 nodes by default.
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// The affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: *timoniv1.#AffinityPresetNone | timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	// Semaphore secret and base container defaults.
	semaphore: {
		accessKeyEncryption: *"mhRwnWnp57QztexJJkHtYf618h4dapMu" | string
		tz:                  *"UTC" | string
		umask:               *"0022" | string
		puid:                *"568" | string
		pgid:                *"568" | string
	}

	// Persistence settings mirroring values.yaml (`persistence.config` and `persistence.data`).
	persistence: {
		config: {
			enabled:      *true | bool
			mountPath:    *"/etc/semaphore" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			storage:      *"100Gi" | string
			storageClass?: string
		}
		data: {
			enabled:      *true | bool
			mountPath:    *"/data" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			storage:      *"100Gi" | string
			storageClass?: string
		}
	}

	// CloudNativePG (CNPG) database settings.
	cnpg: {
		main: {
			enabled:    *true | bool
			user:       *"semaphore" | string
			password:   *"PLACEHOLDERPASSWORD" | string
			database:   *"semaphore" | string
			port:       *5432 | int & >0 & <=65535
			instances:  *2 | int & >0
			image!:     timoniv1.#Image
			waitImage!: timoniv1.#Image
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
			waitResources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    *"10m" | timoniv1.#CPUQuantity
					memory: *"50Mi" | timoniv1.#MemoryQuantity
				}
				limits: {
					cpu:    *"500m" | timoniv1.#CPUQuantity
					memory: *"512Mi" | timoniv1.#MemoryQuantity
				}
			}
			storage: {
				size:        *"100Gi" | string
				accessModes: *["ReadWriteOnce"] | [...string]
			}
			walStorage: {
				size:        *"100Gi" | string
				accessModes: *["ReadWriteOnce"] | [...string]
			}
		}
	}
}

#EnvValue: string | int | bool | {
	secretKeyRef: {
		name: string
		key:  string
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.cnpg.main.enabled {
			cnpgUrlsSecret: #CNPGUrlsSecret & {#config: config}
			cnpgUserSecret: #CNPGUserSecret & {#config: config}
		}
		semaphoreSecret: #SemaphoreSecret & {#config: config}

		if config.persistence.config.enabled {
			configPVC: #ConfigPVC & {#config: config}
		}
		if config.persistence.data.enabled {
			dataPVC: #DataPVC & {#config: config}
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

		if config.cnpg.main.enabled {
			cnpgCluster: #CNPGCluster & {#config: config}
		}
	}
}
