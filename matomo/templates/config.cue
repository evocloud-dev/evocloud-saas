package templates

import (
	corev1 "k8s.io/api/core/v1"
	k8sCore "k8s.io/api/core/v1"
	k8sMeta "k8s.io/apimachinery/pkg/apis/meta/v1"
	k8sNetworking "k8s.io/api/networking/v1"
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
	metadata: timoniv1.#Metadata & {
		#Version: moduleVersion
		annotations?: timoniv1.#Annotations
	}

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Helm-compatible metadata and release overrides.
	nameOverride: string | *""
	fullnameOverride: string | *""
	fullname: metadata.name
	namespaceOverride: string | *""
	clusterDomain: *"cluster.local" | string
	commonLabels: [string]: string
	replicaCount: *1 | int

	// The image allows setting the container image repository, tag, digest and pull policy.
	image: {
		repository:   *"docker.io/library/matomo" | string
		tag:        *"5.13.0-apache" | string
		pullPolicy: *"IfNotPresent" | string
		reference:   "\(repository):\(tag)" // combined image reference
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]

	// Matomo specific configuration
	matomo: {
		siteUrl:     string | *""
		trustedHost: string | *""
		extraEnv: [...k8sCore.#EnvVar] | *[]
		extraEnvFrom: [...k8sCore.#EnvFromSource] | *[]
	}

	// Database configuration
	database: {
		mode: *"auto" | string
		waitForConnection: {
			enabled: *true | bool
		}
		external: {
			host:                      string | *""
			port:                      *3306 | int
			name:                      *"matomo" | string
			username:                  *"matomo" | string
			password:                  string | *""
			existingSecret:            string | *""
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	// MySQL sub‑chart configuration (when enabled)
	mysql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		image: {
			registry:   *"docker.io" | string
			repository: *"library/mysql" | string
			tag:        *"9.7" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database:     *"matomo" | string
			username:     *"matomo" | string
			password:     string | *""
			rootPassword: string | *""
		}
		primary: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
			resources: {
				requests: {
					cpu:    *"100m" | timoniv1.#CPUQuantity
					memory: *"256Mi" | timoniv1.#MemoryQuantity
				}
				limits: {
					cpu:    *"500m" | timoniv1.#CPUQuantity
					memory: *"1Gi" | timoniv1.#MemoryQuantity
				}
			}
			podSecurityContext: {
				runAsUser:    *65510 | int
				runAsGroup:   *65510 | int
				fsGroup:      *65510 | int
				runAsNonRoot: *true | bool
				seccompProfile: {
					type: *"RuntimeDefault" | string
				}
			}
			securityContext: {
				allowPrivilegeEscalation: *false | bool
				runAsNonRoot:             *true | bool
				readOnlyRootFilesystem:   *false | bool
				capabilities: {
					drop: [*"ALL" | string]
					add?: [...string]
				}
			}
		}
	}

	// Persistence for Matomo files
	persistence: {
		enabled:      *true | bool
		storageClass: *null | string
		accessMode:   *"ReadWriteOnce" | string
		size:         *"10Gi" | string
		existingClaim: string | *""
		annotations: [string]: string
	}

	// Archiver CronJob configuration
	archiver: {
		enabled:                    *true | bool
		schedule:                   *"5 * * * *" | string
		concurrencyPolicy:          *"Forbid" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		activeDeadlineSeconds:      *7200 | int
		extraArgs: [...string] | *[]
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// PHP configuration (rendered into a ConfigMap)
	php: {
		ini: string | *"""
			memory_limit = 256M
			max_execution_time = 180
			upload_max_filesize = 64M
			post_max_size = 64M
			opcache.enable = 1
			opcache.memory_consumption = 128
			"""
	}

	// Apache configuration
	apache: {
		port: *8080 | (int & >0 & <=65535)
	}

	// Service definition
	service: {
		type:        *"ClusterIP" | string
		port:        *80 | (int & >0 & <=65535)
		annotations: [string]: string
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		ipFamilies: [...string] | *[]
	}

	// Ingress configuration
	ingress: {
		enabled:          *false | bool
		ingressClassName: *null | string
		annotations: [string]: string
		hosts: [...k8sNetworking.#IngressRule] | *[]
		tls: [...k8sNetworking.#IngressTLS] | *[]
	}

	// Gateway API HTTPRoute configuration (Merged & Deduplicated)
	gatewayAPI: {
		enabled: *false | bool
		httpRoutes: [...{
			parentRefs: [...{
				name:       string
				namespace?: string
				kind?:      *"Gateway" | string
				group?:     *"gateway.networking.k8s.io" | string
			}]
			hostnames?: [...string]
			rules: [...{
				matches?: [...{
					path?: {
						type?:  *"PathPrefix" | "Exact" | "RegularExpression"
						value?: string
					}
				}]
				backendRefs?: [...{
					name:       string
					port:       int & >0 & <=65535
					namespace?: string
					weight?:    int
				}]
			}]
		}] | *[]
	}

	// ExternalSecrets integration
	externalSecrets: {
		enabled:         *false | bool
		refreshInterval: *"1h" | string
		items: [...{
			secretKey: string
			remoteRef: {
				key:       string
				property?: string
			}
		}] | *[]
	}

	// Metrics / ServiceMonitor configuration
	metrics: {
		serviceMonitor: {
			enabled:       *false | bool
			interval:      *"30s" | string
			scrapeTimeout: *"10s" | string
			labels: [string]: string
			namespaceSelector: [string]: string
		}
	}

	// NetworkPolicy configuration
	networkPolicy: {
		enabled: *false | bool
		ingressFrom: [...{
			from?: [...{
				podSelector?:  k8sMeta.#LabelSelector
				namespaceSelector?: k8sMeta.#LabelSelector
			}]
			ports?: [...{
				protocol?: *"TCP" | "UDP"
				port?:     int | string
			}]
		}] | *[]
		egress: {
			enabled:  *false | bool
			allowDNS: *true | bool
			extraEnv: [...k8sCore.#EnvVar] | *[]
			extraEnvFrom: [...k8sCore.#EnvFromSource] | *[]
			extraTo: [...{}] | *[]
			extraEgress: [...{}] | *[]
		}
	}

	// PodDisruptionBudget configuration
	podDisruptionBudget: {
		enabled:        *true | bool
		maxUnavailable: *1 | int
		minAvailable:   *null | int | string
	}

	// ServiceAccount configuration
	serviceAccount: {
		create:                       *true | bool
		name:                         string | *""
		annotations:                  [string]: string
		automountServiceAccountToken: *true | bool
	}

	serviceAccountName: string
	if serviceAccount.name != "" {
		serviceAccountName: serviceAccount.name
	}
	if serviceAccount.name == "" {
		serviceAccountName: fullname
	}

		// Central naming calculations inside #Config struct
	fullname: string | *metadata.name
	
	configMapName: string
	if php.ini != "" {
		configMapName: "\(fullname)-php-config"
	}
	if php.ini == "" {
		configMapName: ""
	}

	// Optional pod‑level security contexts
	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext

	// Probes
	startupProbe: {
		enabled:             *true | bool
		path:                *"/matomo.php" | string
		initialDelaySeconds: *20 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *30 | int
	}
	livenessProbe: {
		enabled:             *true | bool
		path:                *"/matomo.php" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *20 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *6 | int
	}
	readinessProbe: {
		enabled:             *true | bool
		path:                *"/matomo.php" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *6 | int
	}

	// Main container resources (may be overridden per‑container via extraContainers)
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"256Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			memory: *"1Gi" | timoniv1.#MemoryQuantity
		}
	}

	terminationGracePeriodSeconds: *30 | int
	updateStrategy: {type: *"RollingUpdate" | string}

	podLabels: [string]: string
	podAnnotations: [string]: string
	priorityClassName: *null | string
	nodeSelector: [string]: string
	tolerations: [...corev1.#Toleration] | *[]
	affinity?:                  corev1.#Affinity
	topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]

	// Extra workloads and manifests
	extraInitContainers: [...{}] | *[]
	extraContainers: [...{}] | *[]
	extraVolumes: [...{}] | *[]
	extraVolumeMounts: [...{}] | *[]
	extraManifests: [...{}] | *[]
}

#Instance: {
    config: #Config

    objects: {
        if config.php.ini != "" {
            php_configmap: #PhpConfigMap & {#config: config}
        }
        if config.serviceAccount.create {
            serviceaccount: #ServiceAccount & {#config: config}
        }
        secret?: corev1.#Secret & {#config: config}
        pvc: #PersistentVolumeClaim & {#config: config}
        service: #Service & {#config: config}
        deployment: #Deployment & {#config: config}
        if config.metrics.serviceMonitor.enabled {
            servicemonitor: #ServiceMonitor & {#config: config}
        }
        if config.ingress.enabled {
            ingress: #Ingress & {#config: config}
        }
        if config.gatewayAPI.enabled {
            for idx, r in config.gatewayAPI.httpRoutes {
                "gatewayhttproute_\(idx)": #GatewayHttpRoute & {#config: config, #route: r}
            }
        }
        if config.networkPolicy.enabled {
            networkpolicy: #NetworkPolicy & {#config: config}
        }
        if config.podDisruptionBudget.enabled {
            pdb: #PodDisruptionBudget & {#config: config}
        }
        if config.mysql.enabled {
            mysql_sts:      #MySQLStatefulSet & {#config: config}
            mysql_svc:      #MySQLService & {#config: config}
            mysql_headless: #MySQLHeadlessService & {#config: config}
        }
        if config.archiver.enabled {
            cronjob: #CronJobArchiver & {#config: config}
        }
    }
}
