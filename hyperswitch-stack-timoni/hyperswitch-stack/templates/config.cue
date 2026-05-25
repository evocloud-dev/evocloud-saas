package templates

import (
	str "strings"
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion: string | *"1.20.0"
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	moduleVersion: string | *"0.0.0"
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: {
		name: string | *"hyperswitch"
		namespace: string | *"hyperswitch"
	}


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

	fullnameOverride: *"" | string
	nameOverride:     *"" | string

	loadBalancer: {
		targetSecurityGroup: string | *"lg-security-group"
	}

	service: {
		type: string | *"ClusterIP"
		port: int | *80
	}

	services: {
		router: {
			host: string | *"http://localhost:8080"
		}
		sdk: {
			host: string | *"http://localhost:9050"
		}
	}

	global: {
		imageRegistry: string | *""
		image: {
			registry: string | *""
		}
		imagePullSecrets: [...string] | *[]
		clusterDomain: string | *"cluster.local"
		storageClass:  string | *""
		labels: {[string]: string} | *{}
		annotations: {[string]: string} | *{}
		podLabels: {[string]: string} | *{}
		podAnnotations: {[string]: string} | *{}
		env: [...corev1.#EnvVar] | *[]
		nodeSelector: {[string]: string} | *{}
		tolerations: [...corev1.#Toleration] | *[]
		affinity: corev1.#Affinity | *{}
		priorityClassName: string | *""
	}

	"hyperswitch-web": {
		fullnameOverride: string | *"hyperswitch-web"
		enabled:          bool | *true
		sdkDemo: enabled: bool | *false
		image: {
			registry:   string | *""
			repository: string | *"hyperswitch-web"
			tag:        string | *"v0.129.0"
			pullPolicy: string | *"IfNotPresent"
		}
		podAnnotations: {[string]: string} | *{}
		autoBuild: {
			enable:     bool | *true
			forceBuild: bool | *true
			gitCloneParam: gitVersion: string | *"0.129.0"
			nginxConfig: extraPath:    string | *"v1"
			buildParam: {
				envSdkUrl:     string | *"http://localhost:9050"
				envBackendUrl: string | *"http://localhost:8080"
				envLogsUrl:    string | *"http://localhost:3103"
			}
		}
		service: {
			type: string | *"ClusterIP"
			port: int | *9050
		}
		loadBalancer: targetSecurityGroup: string | *"loadbalancer-sg"
		tolerations: [...corev1.#Toleration] | *[]
		nodeSelector: {[string]: string} | *{}
		affinity: corev1.#Affinity | *{}
		ingress: {
			enabled:    bool | *false
			className:  string | *"alb"
			apiVersion: string | *"networking.k8s.io/v1"
			annotations: {[string]: string} | *{}
			hosts: [...{
				host?: string
				http: paths: [...{
					path:     string
					pathType: string
					backend: service: {
						name: string
						port: number: int
					}
				}]
			}] | *[]
			tls: [...{
				hosts: [...string]
				secretName: string
			}] | *[]
		}
	}

	"hyperswitch-app": {
		initDB: {
			enable: bool | *true
			refs:   string | *"tags"
			checkPGisUp: {
				imageRegistry: string | *"docker.io"
				image:         string | *"postgres:15-alpine"
				maxAttempt:    int | *30
			}
			migration: {
				imageRegistry: string | *"docker.io"
					image:         string | *"christophwurst/diesel-cli:latest"
			}
		}
		loadBalancer: targetSecurityGroup: string | *"lg-security-group"
		services: {
			router: {
				version:       string | *"v1.121.1"
				imageRegistry: string | *"docker.juspay.io"
				image:         string | *"juspaydotin/hyperswitch-router"
				host:          string | *"http://localhost:8080"
			}
			consumer: {
				enabled:                 bool | *true
				version:                 string | *"v1.121.0"
				imageRegistry:           string | *"docker.juspay.io"
				image:                   string | *"juspaydotin/hyperswitch-consumer"
				replicas:                int | *1
				progressDeadlineSeconds: int | *600
				strategy: {
					rollingUpdate: {
						maxSurge:       int | *1
						maxUnavailable: int | *0
					}
					type: string | *"RollingUpdate"
				}
				resources: {...} | *{}
				affinity: {...} | *{}
				nodeSelector: {...} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				terminationGracePeriodSeconds: int | *30
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				env: [...corev1.#EnvVar] | *[]
				binary: string | *"scheduler"
				configs: {
					scheduler: {
						consumer_group:             string | *"scheduler_group"
						graceful_shutdown_interval: int | *60000
						loop_interval:              int | *3000
						stream:                     string | *"scheduler_stream"
						consumer: {
							consumer_group: string | *"scheduler_group"
							disabled:       bool | *false
						}
						server: {
							port:    int | *3000
							host:    string | *"0.0.0.0"
							workers: int | *1
						}
					}
				}
			}
			producer: {
				enabled:                 bool | *true
				version:                 string | *"v1.121.1"
				imageRegistry:           string | *"docker.juspay.io"
				image:                   string | *"juspaydotin/hyperswitch-producer"
				replicas:                int | *1
				progressDeadlineSeconds: int | *600
				strategy: {
					rollingUpdate: {
						maxSurge:       int | *1
						maxUnavailable: int | *0
					}
					type: string | *"RollingUpdate"
				}
				resources: {...} | *{}
				affinity: {...} | *{}
				nodeSelector: {...} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				terminationGracePeriodSeconds: int | *30
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				env: [...corev1.#EnvVar] | *[]
				binary: string | *"scheduler"
				configs: {
					scheduler: {
						consumer_group:             string | *"scheduler_group"
						graceful_shutdown_interval: int | *60000
						loop_interval:              int | *30000
						stream:                     string | *"scheduler_stream"
						producer: {
							batch_size:        int | *50
							lock_key:          string | *"producer_locking_key"
							lock_ttl:          int | *160
							lower_fetch_limit: int | *900
							upper_fetch_limit: int | *0
						}
						server: {
							port:    int | *3000
							host:    string | *"0.0.0.0"
							workers: int | *1
						}
					}
				}
			}
			drainer: {
				enabled:                 bool | *false
				imageRegistry:           string | *"docker.juspay.io"
				image:                   string | *"juspaydotin/hyperswitch-drainer"
				version:                 string | *"v1.121.1"
				replicas:                int | *1
				progressDeadlineSeconds: int | *600
				strategy: {
					rollingUpdate: {
						maxSurge:       int | *1
						maxUnavailable: int | *0
					}
					type: string | *"RollingUpdate"
				}
				resources: {...} | *{}
				affinity: {...} | *{}
				nodeSelector: {...} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				terminationGracePeriodSeconds: int | *30
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				env: [...corev1.#EnvVar] | *[]
				configs: {
					drainer: {
						stream_name:       string | *"pt_key"
						num_partitions:    int | *64
						max_read_count:    int | *100
						shutdown_interval: int | *1000
						loop_interval:     int | *250
					}
					secrets: {
						master_key: string | *""
					}
					redis: {
						pool_size:       int | *10
						cluster_enabled: bool | *false
					}
				}
			}
			sdk: {
				host:       string | *"http://localhost:9050"
				version:    string | *"0.129.0"
				subversion: string | *"v1"
			}
		}
		server: {
			replicas:      int | *1
			imageRegistry: string | *"docker.juspay.io"
			image:         string | *"juspaydotin/hyperswitch-router"
			binary:        string | *"router"
			env: [...corev1.#EnvVar] | *[]
			strategy: {...} | *{type: "RollingUpdate"}
			resources: {...} | *{}
			affinity: {...} | *{}
			tolerations: [...corev1.#Toleration] | *[]
			nodeSelector: {...} | *{}
			podAnnotations: {[string]: string} | *{}
			annotations: {[string]: string} | *{}
			labels: {[string]: string} | *{}
			terminationGracePeriodSeconds: int | *30
			progressDeadlineSeconds:       int | *600
			livenessProbe: {...} | *{}
			readinessProbe: {...} | *{}
			secrets: {
				forex_api_key:          string | *"forex_api_key"
				forex_fallback_api_key: string | *"forex_fallback_api_key"
				jwt_secret:             string | *"test_admin"
				admin_api_key:          string | *"test_admin"
				master_enc_key:         string | *"471f22516724347bcca9c20c5fa88d9821c4604e63a6aceffd24605809c9237c"
				recon_admin_api_key:    string | *"test_admin"
			}
			locker: locker_enabled: bool | *true
			run_env: string | *"sandbox"
			email: active_email_client: string | *"SMTP"
			configs: {
				proxy: enabled:                 bool | *false
				email: allowed_unverified_days: int | *7
				multitenancy: {
					enabled: bool | *false
					global_tenant: {
						clickhouse_database: string | *"default"
						redis_key_prefix:    string | *""
						schema:              string | *"public"
						tenant_id:           string | *"global"
					}
					tenants: {
						public: {
							base_url:            string | *"http://localhost:8080"
							schema:              string | *"public"
							accounts_schema:     string | *"public"
							redis_key_prefix:    string | *""
							clickhouse_database: string | *"default"
							user: control_center_url: string | *"http://localhost:9000"
						}
					}
				}
			}
			ingress: {
				enabled:   bool | *false
				className: string | *"nginx"
				hostname:  string | *"hyperswitch.local"
				path:      string | *"/"
				pathType:  string | *"Prefix"
				tls: [...{
					hosts: [...string]
					secretName: string
				}] | *[]
				annotations: {[string]: string} | *{}
			}
			serviceAccount: {
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
			}
		}
		controlCenter: env: {[string]: string} | *{}
		autoscaling: {
			enabled:                        bool | *false
			minReplicas:                    int | *1
			maxReplicas:                    int | *4
			targetCPUUtilizationPercentage: int | *80
		}
		"hyperswitch-card-vault": {
			enabled: bool | *true
			backend: string | *"none"
			server: {
				imageRegistry: string | *"docker.juspay.io"
				image:         string | *"juspaydotin/hyperswitch-card-vault:v0.6.5-dev"
				version:       string | *"v0.6.5"
				host:          string | *"0.0.0.0"
				port:          int | *8080
				tenant_secrets: [string]: {
					master_key: string
					public_key: string | *""
					schema:     string | *"public"
				}
				extra: env: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				pod: annotations: {[string]: string} | *{}
				affinity: {...} | *{}
				nodeSelector: {...} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				vault: url: string | *"http://127.0.0.1:8200"
				externalKeyManager: {
					url:  string | *"http://localhost:5000"
					cert: string | *""
				}
				apiClient: identity: string | *""
			}
			initDB: {
				enable: bool | *true
				refs:   string | *"tags"
				checkPGisUp: {
					imageRegistry: string | *"docker.io"
					image:         string | *"postgres:15-alpine"
					maxAttempt:    int | *30
				}
				migration: {
					imageRegistry: string | *"docker.io"
					image:         string | *"christophwurst/diesel-cli:latest"
				}
			}
			vaultKeysJob: {
				enabled: bool | *true
				checkVaultService: {
					imageRegistry: string | *"docker.io"
					image:         string | *"curlimages/curl:8.7.1"
					maxAttempt:    int | *30
					host:          string | *""
				}
				keys: {
					key1: string | *""
					key2: string | *""
				}
			}
			redisMiscConfig: {
				checkRedisIsUp: initContainer: {
					enable:        bool | *true
					imageRegistry: string | *"docker.io"
					image:         string | *"redis:7-alpine"
					maxAttempt:    int | *30
				}
			}
			secrets: {
				locker_private_key: string | *"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
				aws: {
					key_id: string | *""
					region: string | *"us-east-1"
				}
				vault: token: string | *"hvs.dummy_token"
				tls: {
					certificate: string | *""
					private_key: string | *""
				}
				external_key_manager: cert: string | *""
				api_client: identity:       string | *""
			}
			postgresql: {
				enabled: bool | *true
				auth: {
					password: string | *"password123"
					username: string | *"db_user"
					database: string | *"locker-db"
				}
				containerPorts: postgresql: int | *5432
				imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
				shmVolume: {
					enabled:    bool | *true
					sizeLimit?: string | int
				}
				hostNetwork: bool | *false
				hostIPC:     bool | *false
				serviceAccount: name: string | *""
				primary: {
					configuration:         string | *""
					pgHbaConfiguration:    string | *""
					extendedConfiguration: string | *""
					annotations: {[string]: string} | *{}
					podAnnotations: {[string]: string} | *{}
					podLabels: {[string]: string} | *{}
					automountServiceAccountToken: bool | *false
					affinity: {...} | *{}
					nodeSelector: {[string]: string} | *{}
					tolerations: [...corev1.#Toleration] | *[]
					topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
					priorityClassName:             string | *""
					schedulerName:                 string | *""
					terminationGracePeriodSeconds: int | *30
					podSecurityContext: {
						enabled: bool | *true
						fsGroup: int | *1001
					}
					containerSecurityContext: {
						enabled:   bool | *true
						runAsUser: int | *1001
					}
					initContainers: [...corev1.#Container] | *[]
					extraContainers: [...corev1.#Container] | *[]
					resources: corev1.#ResourceRequirements | *{}
					initdb: {
						scripts: {[string]: string} | *{}
						scriptsConfigMap: string | *""
					}
					preInitDb: scripts: {[string]: string} | *{}
					volumePermissions: {
						enabled: bool | *false
						image: {
							registry:   string | *"docker.io"
							repository: string | *"bitnamilegacy/postgresql"
							tag:        string | *"16.1.0-debian-11-r9"
							pullPolicy: string | *"IfNotPresent"
						}
					}
					networkPolicy: {
						enabled:                  bool | *false
						allowExternal:            bool | *true
						allowExternalEgress:      bool | *true
						ingressNSMatchLabels:     {[string]: string} | *{}
						ingressNSPodMatchLabels:  {[string]: string} | *{}
						extraIngress:             [...{...}] | *[]
						extraEgress:              [...{...}] | *[]
					}
					pdb: create: bool | *false
					persistence: {
						enabled:      bool | *true
						size:         string | *"8Gi"
						storageClass: string | *""
						accessModes: [...string] | *["ReadWriteOnce"]
						annotations: {[string]: string} | *{}
						labels: {[string]: string} | *{}
					}
					resources: corev1.#ResourceRequirements | *{
						requests: {
							cpu:    "250m"
							memory: "500Mi"
						}
					}
					service: {
						type:            string | *"ClusterIP"
						sessionAffinity: string | *"None"
						annotations: {[string]: string} | *{}
						headless: annotations: {[string]: string} | *{}
						ports: postgresql: int | *5432
					}
					...
				}
				readReplicas: {
					replicaCount: int | *0
					tolerations: [...corev1.#Toleration] | *[]
					...
				}
				metrics: {
					enabled: bool | *false
					image: {
						registry:   string | *"docker.io"
						repository: string | *"bitnami/postgres-exporter"
						tag:        string | *"0.15.0-debian-12-r43"
					}
					containerSecurityContext: {
						enabled:   bool | *true
						runAsUser: int | *1001
					}
					service: ports: metrics: int | *9187
					resources: corev1.#ResourceRequirements | *{}
					customMetrics: string | *""
					serviceMonitor: {
						enabled:       bool | *false
						interval:      string | *""
						scrapeTimeout: string | *""
						jobLabel:      string | *""
						honorLabels:   bool | *false
						selector:      {[string]: string} | *{}
						relabelings:   [...{...}] | *[]
						metricRelabelings: [...{...}] | *[]
						namespace: string | *""
					}
				}
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/postgresql"
					tag:        string | *"16.1.0-debian-11-r9"
					pullPolicy: string | *"IfNotPresent"
				}
				...
			}
		}
		redis: {
			enabled:          bool | *true
			fullnameOverride: string | *""
			architecture:     "standalone" | "replication" | *"standalone"
			clusterDomain:    string | *"cluster.local"
			commonLabels: {[string]: string} | *{}
			commonAnnotations: {[string]: string} | *{}
			commonConfiguration: string | *""
			secretAnnotations: {[string]: string} | *{}
			extraDeploy: [...{...}] | *[]
			image: {
				registry:   string | *"docker.io"
				repository: string | *"bitnamilegacy/redis"
				tag:        string | *"7.2.3-debian-11-r2"
				pullPolicy: string | *"IfNotPresent"
				debug:      bool | *false
			}
			auth: {
				enabled:          bool | *false
				sentinel:         bool | *false
				existingSecret:   string | *""
				password:         string | *""
				usePasswordFiles: bool | *false
				secretKeys: userPasswordKey: string | *"redis-password"
			}
			tls: {
				enabled:        bool | *false
				authClients:    bool | *true
				autoGenerated:  bool | *false
				existingSecret: string | *""
			}
			master: {
				count: int | *1
				kind:  "StatefulSet" | "Deployment" | "DaemonSet" | *"StatefulSet"
				tolerations: [...corev1.#Toleration] | *[]
				configuration: string | *""
				disableCommands: [...string] | *[]
				containerPorts: redis: int | *6379
				service: {
					type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
					ports: redis:     int | *6379
					nodePorts: redis: string | int | *""
					clusterIP: string | *""
					annotations: {[string]: string} | *{}
					externalTrafficPolicy: string | *"Cluster"
					internalTrafficPolicy: string | *"Cluster"
					loadBalancerIP:        string | *""
					loadBalancerClass:     string | *""
					loadBalancerSourceRanges: [...string] | *[]
					sessionAffinity: string | *"None"
					sessionAffinityConfig: {...} | *{}
					externalIPs: [...string] | *[]
					extraPorts: [...corev1.#ServicePort] | *[]
				}
				persistence: {
					enabled:       bool | *true
					path:          string | *"/data"
					existingClaim: string | *""
					subPath:       string | *""
					subPathExpr:   string | *""
					medium:        string | *""
					sizeLimit:     string | *""
					storageClass:  string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					size: string | *"8Gi"
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					selector: {...} | *{}
					dataSource: {...} | *{}
				}
				persistentVolumeClaimRetentionPolicy: {
					enabled:     bool | *false
					whenDeleted: string | *"Retain"
					whenScaled:  string | *"Retain"
				}
				serviceAccount: {
					create:                       bool | *true
					name:                         string | *""
					automountServiceAccountToken: bool | *false
					annotations: {[string]: string} | *{}
				}
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				podSecurityContext: {
					enabled: bool | *true
					fsGroup: int | *1001
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsNonRoot:             bool | *true
					allowPrivilegeEscalation: bool | *false
					readOnlyRootFilesystem:   bool | *true
				}
				priorityClassName: string | *""
				affinity: corev1.#Affinity | *{}
				podAffinityPreset:     string | *""
				podAntiAffinityPreset: string | *"soft"
				nodeAffinityPreset: {
					type: string | *""
					key:  string | *""
					values: [...string] | *[]
				}
				nodeSelector: {[string]: string} | *{}
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				shareProcessNamespace: bool | *false
				schedulerName:         string | *""
				dnsPolicy:             string | *""
				dnsConfig: {...} | *{}
				enableServiceLinks:            bool | *true
				terminationGracePeriodSeconds: int | *30
				updateStrategy: {...} | *{type: "RollingUpdate"}
				minReadySeconds:     int | *0
				podManagementPolicy: string | *""
				lifecycleHooks: {...} | *{}
				command: [...string] | *[]
				args: [...string] | *[]
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 5}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 1, successThreshold: 1, failureThreshold: 5}
				startupProbe: corev1.#Probe | *{enabled: false, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 5}
				customLivenessProbe?: {...}
				customReadinessProbe?: {...}
				customStartupProbe?: {...}
				resources: corev1.#ResourceRequirements | *{}
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				sidecars: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
			}
			replica: {
				kind:          "StatefulSet" | "DaemonSet" | *"StatefulSet"
				replicaCount:  int | *0
				configuration: string | *""
				disableCommands: [...string] | *[]
				command: [...string] | *[]
				args: [...string] | *[]
				enableServiceLinks: bool | *true
				preExecCmds: [...string] | *[]
				extraFlags: [...string] | *[]
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				externalMaster: {
					enabled: bool | *false
					host:    string | *""
					port:    int | *6379
				}
				containerPorts: redis: int | *6379
				startupProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 10, periodSeconds: 10, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 22}
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 5}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 1, successThreshold: 1, failureThreshold: 5}
				customStartupProbe: {...} | *{}
				customLivenessProbe: {...} | *{}
				customReadinessProbe: {...} | *{}
				resources: corev1.#ResourceRequirements | *{}
				podSecurityContext: {
					enabled: bool | *true
					fsGroup: int | *1001
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *0
					runAsNonRoot:             bool | *true
					allowPrivilegeEscalation: bool | *false
					readOnlyRootFilesystem:   bool | *true
				}
				schedulerName: string | *""
				updateStrategy: {...} | *{type: "RollingUpdate"}
				minReadySeconds:     int | *0
				priorityClassName:   string | *""
				podManagementPolicy: string | *""
				hostAliases: [...corev1.#HostAlias] | *[]
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				shareProcessNamespace: bool | *false
				podAffinityPreset:     string | *""
				podAntiAffinityPreset: string | *"soft"
				nodeAffinityPreset: {
					type: string | *""
					key:  string | *""
					values: [...string] | *[]
				}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				dnsPolicy: string | *""
				dnsConfig: {...} | *{}
				lifecycleHooks: {...} | *{}
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				sidecars: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				persistence: {
					enabled:      bool | *true
					medium:       string | *""
					sizeLimit:    string | *""
					path:         string | *"/data"
					subPath:      string | *""
					subPathExpr:  string | *""
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					size: string | *"8Gi"
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					selector: {...} | *{}
					dataSource: {...} | *{}
					existingClaim: string | *""
				}
				persistentVolumeClaimRetentionPolicy: {
					enabled:     bool | *false
					whenScaled:  string | *"Retain"
					whenDeleted: string | *"Retain"
				}
				service: {
					type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
					ports: redis:     int | *6379
					nodePorts: redis: string | int | *""
					externalTrafficPolicy: string | *"Cluster"
					internalTrafficPolicy: string | *"Cluster"
					extraPorts: [...corev1.#ServicePort] | *[]
					clusterIP:         string | *""
					loadBalancerIP:    string | *""
					loadBalancerClass: string | *""
					loadBalancerSourceRanges: [...string] | *[]
					annotations: {[string]: string} | *{}
					sessionAffinity: string | *"None"
					sessionAffinityConfig: {...} | *{}
					externalIPs: [...string] | *[]
				}
				serviceAccount: {
					create:                       bool | *true
					name:                         string | *""
					automountServiceAccountToken: bool | *false
					annotations: {[string]: string} | *{}
				}
				autoscaling: {
					enabled:      bool | *false
					minReplicas:  int | *1
					maxReplicas:  int | *11
					targetCPU:    int | *0
					targetMemory: int | *0
				}
			}
			sentinel: {
				enabled:               bool | *false
				masterSet:             string | *"mymaster"
				quorum:                int | *2
				downAfterMilliseconds: int | *60000
				failoverTimeout:       int | *180000
				parallelSyncs:         int | *1
				configuration:         string | *""
				containerPorts: sentinel: int | *26379
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/redis-sentinel"
					tag:        string | *"7.2.3-debian-11-r2"
					pullPolicy: string | *"IfNotPresent"
					debug:      bool | *false
				}
				service: {
					type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
					ports: {
						redis:    int | *6379
						sentinel: int | *26379
					}
					nodePorts: {
						redis:    string | int | *""
						sentinel: string | int | *""
					}
					clusterIP: string | *""
					annotations: {[string]: string} | *{}
					headless: annotations: {[string]: string} | *{}
					externalTrafficPolicy: string | *"Cluster"
					loadBalancerIP:        string | *""
					loadBalancerClass:     string | *""
					loadBalancerSourceRanges: [...string] | *[]
					sessionAffinity: string | *"None"
					sessionAffinityConfig: {...} | *{}
					extraPorts: [...corev1.#ServicePort] | *[]
				}
				persistence: {
					enabled:      bool | *false
					medium:       string | *""
					sizeLimit:    string | *""
					path:         string | *"/opt/bitnami/redis-sentinel/etc"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					size: string | *"100Mi"
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					selector: {...} | *{}
					dataSource: {...} | *{}
				}
				persistentVolumeClaimRetentionPolicy: {
					enabled:     bool | *false
					whenScaled:  string | *"Retain"
					whenDeleted: string | *"Retain"
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *0
					runAsNonRoot:             bool | *true
					allowPrivilegeEscalation: bool | *false
					readOnlyRootFilesystem:   bool | *true
				}
				lifecycleHooks: {...} | *{}
				command: [...string] | *[]
				args: [...string] | *[]
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				externalMaster: {
					enabled: bool | *false
					host:    string | *""
					port:    int | *6379
				}
				startupProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 10, periodSeconds: 10, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 22}
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 5}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 20, periodSeconds: 5, timeoutSeconds: 1, successThreshold: 1, failureThreshold: 5}
				customStartupProbe: {...} | *{}
				customLivenessProbe: {...} | *{}
				customReadinessProbe: {...} | *{}
				resources: corev1.#ResourceRequirements | *{}
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				enableServiceLinks:            bool | *true
				terminationGracePeriodSeconds: int | *30
				annotations: {[string]: string} | *{}
				hpa: {
					enabled:      bool | *false
					minReplicas:  int | *3
					maxReplicas:  int | *11
					targetCPU:    int | *50
					targetMemory: int | *50
				}
			}
			metrics: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnami/redis-exporter"
					tag:        string | *"1.55.0-debian-11-r2"
					pullPolicy: string | *"IfNotPresent"
				}
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				resources: corev1.#ResourceRequirements | *{}
				startupProbe: corev1.#Probe | *{enabled: false, initialDelaySeconds: 10, periodSeconds: 10, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 5}
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 10, periodSeconds: 10, timeoutSeconds: 5, successThreshold: 1, failureThreshold: 5}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 1, successThreshold: 1, failureThreshold: 3}
				service: {
					type:                  "ClusterIP" | "LoadBalancer" | *"ClusterIP"
					port:                  int | *9121
					clusterIP:             string | *""
					externalTrafficPolicy: string | *"Cluster"
					loadBalancerIP:        string | *""
					loadBalancerClass:     string | *""
					loadBalancerSourceRanges: [...string] | *[]
					annotations: {[string]: string} | *{}
					extraPorts: [...corev1.#ServicePort] | *[]
				}
				serviceMonitor: {
					enabled:       bool | *false
					namespace:     string | *""
					interval:      string | *""
					scrapeTimeout: string | *""
					honorLabels:   bool | *false
					additionalLabels: {[string]: string} | *{}
				}
				podMonitor: {
					enabled:       bool | *false
					namespace:     string | *""
					interval:      string | *""
					scrapeTimeout: string | *""
					honorLabels:   bool | *false
					additionalLabels: {[string]: string} | *{}
				}
				prometheusRule: {
					enabled:   bool | *false
					namespace: string | *""
					additionalLabels: {[string]: string} | *{}
					rules: [...{...}] | *[]
				}
			}
			networkPolicy: {
				enabled:       bool | *false
				allowExternal: bool | *true
				extraIngress: [...{...}] | *[]
				extraEgress: [...{...}] | *[]
				metrics: allowExternal: bool | *true
			}
			pdb: {
				create:         bool | *false
				minAvailable:   string | int | *""
				maxUnavailable: string | int | *""
			}
			podSecurityPolicy: create: bool | *false
			serviceAccount: {
				create:                       bool | *true
				name:                         string | *""
				automountServiceAccountToken: bool | *false
				annotations: {[string]: string} | *{}
			}
			rbac: {
				create: bool | *false
				rules: [...rbacv1.#PolicyRule] | *[]
			}
			serviceBindings: enabled: bool | *false
			sysctl: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/redis"
					tag:        string | *"11-debian-11-r82"
					pullPolicy: string | *"IfNotPresent"
				}
				command: [...string] | *[]
				mountHostSys: bool | *true
				resources: corev1.#ResourceRequirements | *{}
			}
			volumePermissions: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/redis"
					tag:        string | *"7.2.3-debian-11-r3"
					pullPolicy: string | *"IfNotPresent"
				}
				containerSecurityContext: {
					runAsUser: string | int | *"auto"
				}
				resources: corev1.#ResourceRequirements | *{}
			}
		}
		redisMiscConfig: {
			checkRedisIsUp: initContainer: {
				enable:        bool | *true
				imageRegistry: string | *"docker.io"
				image:         string | *"redis:7-alpine"
				maxAttempt:    int | *30
			}
		}
		postgresql: {
			enabled:          bool | *true
			fullnameOverride: string | *""
			architecture:     "standalone" | "replication" | *"standalone"
			containerPorts: postgresql: int | *5432
			global: postgresql: auth: {
				username: string | *"hyperswitch"
				database: string | *"hyperswitch"
			}
			auth: {
				enablePostgresUser:  bool | *true
				postgresPassword:    string | *"password123"
				username:            string | *"hyperswitch"
				password:            string | *"password123"
				database:            string | *"hyperswitch"
				replicationUsername: string | *"repl_user"
				replicationPassword: string | *"password123"
				existingSecret:      string | *""
				secretKeys: {
					adminPasswordKey:       string | *"postgres-password"
					userPasswordKey:        string | *"password"
					replicationPasswordKey: string | *"replication-password"
				}
				usePasswordFiles: bool | *false
			}
			image: {
				registry:   string | *"docker.io"
				repository: string | *"bitnamilegacy/postgresql"
				tag:        string | *"16.1.0-debian-11-r9"
				pullPolicy: string | *"IfNotPresent"
				pullSecrets: [...string] | *[]
				debug: bool | *false
			}
			tls: {
				enabled:             bool | *false
				autoGenerated:       bool | *false
				preferServerCiphers: bool | *true
				certificatesSecret:  string | *""
				certFilename:        string | *""
				certKeyFilename:     string | *""
				certCAFilename:      string | *""
				crlFilename:         string | *""
			}
			serviceAccount: {
				create:                       bool | *true
				name:                         string | *""
				automountServiceAccountToken: bool | *false
				annotations: {[string]: string} | *{}
			}
			rbac: {
				create: bool | *false
				rules: [...{
					apiGroups: [...string]
					resources: [...string]
					verbs: [...string]
				}] | *[]
			}
			psp: {
				create: bool | *false
			}
			primary: {
				name:                      string | *"primary"
				configuration:             string | *""
				pgHbaConfiguration:        string | *""
				existingConfigmap:         string | *""
				extendedConfiguration:     string | *""
				existingExtendedConfigmap: string | *""
				initdb: {
					args:             string | *""
					postgresqlWalDir: string | *""
					scripts: {[string]: string} | *{}
					scriptsConfigMap: string | *""
					scriptsSecret:    string | *""
					user:             string | *""
					password:         string | *""
				}
				preInitDb: {
					scripts: {[string]: string} | *{}
					scriptsConfigMap: string | *""
					scriptsSecret:    string | *""
				}
				standby: {
					enabled:     bool | *false
					primaryHost: string | *""
					primaryPort: string | *""
				}
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				command: [...string] | *[]
				args: [...string] | *[]
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6, successThreshold: 1}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6, successThreshold: 1}
				startupProbe: corev1.#Probe | *{enabled: false, initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 1, failureThreshold: 15, successThreshold: 1}
				customLivenessProbe?: {...}
				customReadinessProbe?: {...}
				customStartupProbe?: {...}
				lifecycleHooks: {...} | *{}
				resourcesPreset: string | *"nano"
				resources: corev1.#ResourceRequirements | *{}
				podSecurityContext: {
					enabled:             bool | *true
					fsGroupChangePolicy: string | *"Always"
					sysctls: [...{...}] | *[]
					supplementalGroups: [...int] | *[]
					fsGroup: int | *1001
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *1001
					runAsNonRoot:             bool | *true
					privileged:               bool | *false
					readOnlyRootFilesystem:   bool | *true
					allowPrivilegeEscalation: bool | *false
					capabilities: drop: [...string] | *["ALL"]
					seccompProfile: type: string | *"RuntimeDefault"
				}
				automountServiceAccountToken: bool | *false
				hostAliases: [...corev1.#HostAlias] | *[]
				hostNetwork: bool | *false
				hostIPC:     bool | *false
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podAffinityPreset:     string | *""
				podAntiAffinityPreset: string | *"soft"
				nodeAffinityPreset: {
					type: string | *""
					key:  string | *""
					values: [...string] | *[]
				}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				priorityClassName:             string | *""
				schedulerName:                 string | *""
				terminationGracePeriodSeconds: string | *""
				updateStrategy: {
					type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
					rollingUpdate: {...} | *{}
				}
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				sidecars: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				pdb: {
					create:         bool | *true
					minAvailable:   string | int | *""
					maxUnavailable: string | int | *""
				}
				extraPodSpec: {...} | *{}
				networkPolicy: {
					enabled:             bool | *true
					allowExternal:       bool | *true
					allowExternalEgress: bool | *true
					extraIngress: [...{...}] | *[]
					extraEgress: [...{...}] | *[]
					ingressNSMatchLabels: {[string]: string} | *{}
					ingressNSPodMatchLabels: {[string]: string} | *{}
				}
				service: {
					type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
					ports: postgresql:     int | *5432
					nodePorts: postgresql: string | *""
					clusterIP: string | *""
					annotations: {[string]: string} | *{}
					loadBalancerClass:     string | *""
					loadBalancerIP:        string | *""
					externalTrafficPolicy: string | *"Cluster"
					loadBalancerSourceRanges: [...string] | *[]
					extraPorts: [...corev1.#ServicePort] | *[]
					sessionAffinity: string | *"None"
					sessionAffinityConfig: {...} | *{}
					headless: annotations: {[string]: string} | *{}
				}
				persistence: {
					enabled:       bool | *true
					volumeName:    string | *"data"
					existingClaim: string | *""
					mountPath:     string | *"/bitnami/postgresql"
					subPath:       string | *""
					storageClass:  string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					size: string | *"8Gi"
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					dataSource: {...} | *{}
					selector: {...} | *{}
				}
				persistentVolumeClaimRetentionPolicy: {
					enabled:     bool | *false
					whenDeleted: string | *"Retain"
					whenScaled:  string | *"Retain"
				}
			}
			readReplicas: {
				name:                  string | *"read"
				replicaCount:          int | *1
				extendedConfiguration: string | *""
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				command: [...string] | *[]
				args: [...string] | *[]
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6, successThreshold: 1}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6, successThreshold: 1}
				startupProbe: corev1.#Probe | *{enabled: false, initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 1, failureThreshold: 15, successThreshold: 1}
				customLivenessProbe?: {...}
				customReadinessProbe?: {...}
				customStartupProbe?: {...}
				lifecycleHooks: {...} | *{}
				resourcesPreset: string | *"nano"
				resources: corev1.#ResourceRequirements | *{}
				podSecurityContext: {
					enabled:             bool | *true
					fsGroupChangePolicy: string | *"Always"
					sysctls: [...{...}] | *[]
					supplementalGroups: [...int] | *[]
					fsGroup: int | *1001
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *1001
					runAsNonRoot:             bool | *true
					privileged:               bool | *false
					readOnlyRootFilesystem:   bool | *true
					allowPrivilegeEscalation: bool | *false
					capabilities: drop: [...string] | *["ALL"]
					seccompProfile: type: string | *"RuntimeDefault"
				}
				automountServiceAccountToken: bool | *false
				hostAliases: [...corev1.#HostAlias] | *[]
				hostNetwork: bool | *false
				hostIPC:     bool | *false
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podAffinityPreset:     string | *""
				podAntiAffinityPreset: string | *"soft"
				nodeAffinityPreset: {
					type: string | *""
					key:  string | *""
					values: [...string] | *[]
				}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				priorityClassName:             string | *""
				schedulerName:                 string | *""
				terminationGracePeriodSeconds: string | *""
				updateStrategy: {
					type: "RollingUpdate" | "OnDelete" | *"RollingUpdate"
					rollingUpdate: {...} | *{}
				}
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				sidecars: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				extraContainers: [...corev1.#Container] | *[]
				pdb: {
					create:         bool | *true
					minAvailable:   string | int | *""
					maxUnavailable: string | int | *""
				}
				extraPodSpec: {...} | *{}
				networkPolicy: {
					enabled:             bool | *true
					allowExternal:       bool | *true
					allowExternalEgress: bool | *true
					extraIngress: [...{...}] | *[]
					extraEgress: [...{...}] | *[]
					ingressNSMatchLabels: {[string]: string} | *{}
					ingressNSPodMatchLabels: {[string]: string} | *{}
				}
				service: {
					type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
					ports: postgresql:     int | *5432
					nodePorts: postgresql: string | *""
					clusterIP: string | *""
					annotations: {[string]: string} | *{}
					loadBalancerClass:     string | *""
					loadBalancerIP:        string | *""
					externalTrafficPolicy: string | *"Cluster"
					loadBalancerSourceRanges: [...string] | *[]
					extraPorts: [...corev1.#ServicePort] | *[]
					sessionAffinity: string | *"None"
					sessionAffinityConfig: {...} | *{}
					headless: annotations: {[string]: string} | *{}
				}
				persistence: {
					enabled:       bool | *true
					existingClaim: string | *""
					mountPath:     string | *"/bitnami/postgresql"
					subPath:       string | *""
					storageClass:  string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					size: string | *"8Gi"
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					dataSource: {...} | *{}
					selector: {...} | *{}
				}
			}
			metrics: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnami/postgres-exporter"
					tag:        string | *"0.15.0-debian-12-r43"
					digest:     string | *""
					pullPolicy: string | *"IfNotPresent"
					pullSecrets: [...string] | *[]
				}
				collectors: {[string]: bool} | *{}
				customMetrics: {...} | *{}
				extraEnvVars: [...corev1.#EnvVar] | *[]
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *1001
					runAsNonRoot:             bool | *true
					privileged:               bool | *false
					readOnlyRootFilesystem:   bool | *true
					allowPrivilegeEscalation: bool | *false
					capabilities: drop: [...string] | *["ALL"]
					seccompProfile: type: string | *"RuntimeDefault"
				}
				livenessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6, successThreshold: 1}
				readinessProbe: corev1.#Probe | *{enabled: true, initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6, successThreshold: 1}
				startupProbe: corev1.#Probe | *{enabled: false, initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 1, failureThreshold: 15, successThreshold: 1}
				customLivenessProbe?: {...}
				customReadinessProbe?: {...}
				customStartupProbe?: {...}
				resourcesPreset: string | *"nano"
				resources: corev1.#ResourceRequirements | *{}
				service: {
					type:            string | *"ClusterIP"
					sessionAffinity: string | *"None"
					clusterIP:       string | *""
					annotations: {[string]: string} | *{}
					ports: metrics: int | *9187
				}
				serviceMonitor: {
					enabled:       bool | *false
					namespace:     string | *""
					interval:      string | *"30s"
					scrapeTimeout: string | *""
					labels: {[string]: string} | *{}
					selector: {[string]: string} | *{}
					relabelings: [...{...}] | *[]
					metricRelabelings: [...{...}] | *[]
					honorLabels: bool | *false
					jobLabel:    string | *""
				}
				prometheusRule: {
					enabled:   bool | *false
					namespace: string | *""
					labels: {[string]: string} | *{}
					rules: [...{
						alert: string
						expr:  string
						for?:  string
						labels?: {[string]: string}
						annotations?: {[string]: string}
					}] | *[]
				}
			}
			serviceBindings: {
				enabled: bool | *false
			}
			backup: {
				enabled: bool | *false
				cronjob: {
					schedule:                   string | *"@daily"
					timeZone:                   string | *""
					concurrencyPolicy:          string | *"Allow"
					failedJobsHistoryLimit:     int | *1
					successfulJobsHistoryLimit: int | *3
					startingDeadlineSeconds:    string | *""
					ttlSecondsAfterFinished:    string | *""
					restartPolicy:              string | *"OnFailure"
					podSecurityContext: {
						enabled:             bool | *true
						fsGroupChangePolicy: string | *"Always"
						sysctls: [...{...}] | *[]
						supplementalGroups: [...int] | *[]
						fsGroup: int | *1001
					}
					containerSecurityContext: {
						enabled:                  bool | *true
						runAsUser:                int | *1001
						runAsGroup:               int | *1001
						runAsNonRoot:             bool | *true
						privileged:               bool | *false
						readOnlyRootFilesystem:   bool | *true
						allowPrivilegeEscalation: bool | *false
						capabilities: drop: [...string] | *["ALL"]
						seccompProfile: type: string | *"RuntimeDefault"
					}
					command: [...string] | *["/bin/sh", "-c", "pg_dumpall --clean --if-exists --load-via-partition-root --quote-all-identifiers --no-password --file=${PGDUMP_DIR}/pg_dumpall-$(date '+%Y-%m-%d-%H-%M').pgdump"]
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
					nodeSelector: {[string]: string} | *{}
					tolerations: [...corev1.#Toleration] | *[]
					resourcesPreset: string | *"nano"
					resources: corev1.#ResourceRequirements | *{}
					networkPolicy: enabled: bool | *true
					storage: {
						enabled:        bool | *true
						existingClaim:  string | *""
						resourcePolicy: string | *""
						storageClass:   string | *""
						accessModes: [...string] | *["ReadWriteOnce"]
						size: string | *"8Gi"
						annotations: {[string]: string} | *{}
						mountPath: string | *"/backup/pgdump"
						subPath:   string | *""
					}
					extraVolumeMounts: [...corev1.#VolumeMount] | *[]
					extraVolumes: [...corev1.#Volume] | *[]
				}
			}
			extraDeploy: [...{...}] | *[]
			commonLabels: {[string]: string} | *{}
			commonAnnotations: {[string]: string} | *{}
			...
		}
		externalPostgresql: {
			enabled: bool | *false
			primary: {
				host: string | *""
				auth: {
					username: string | *""
				}
				database: string | *""
			}
		}
		externalRedis: {
			enabled: bool | *false
			host:    string | *""
		}
		istio: {
			enabled: bool | *false
			destinationRule: trafficPolicy: {...} | *{}
			virtualService: {
				create: bool | *true
				hosts: [...string] | *["*"]
				gateways: [...string] | *["hyperswitch-gateway"]
				http: [...{
					name: string
				}] | *[]
			}
		}
		argoRollouts: {
			enabled:              bool | *false
			revisionHistoryLimit: int | *10
			canary: {
				steps: [...{...}] | *[]
				dynamicStableScale?:         bool
				abortScaleDownDelaySeconds?: int
				antiAffinity?: {...}
				maxSurge?:       string | int
				maxUnavailable?: string | int
				analysis: {
					enabled:      bool | *false
					interval:     string | *"1m"
					startingStep: int | *1
					args: [...{...}] | *[]
					victoriaMetrics: address?: string
				}
				trafficRouting: headerRouting: {
					enabled:   bool | *false
					routeName: string | *"canary-header-route"
					match: [...{...}] | *[]
				}
				trafficRouting: istio: {
					enabled: bool | *false
					destinationRule: {
						stableSubsetName: string | *"stable"
						canarySubsetName: string | *"canary"
					}
					virtualService: routeNames: [...string] | *[]
				}
			}
		}
		kafka: {
			name:          string | *"kafka"
			enabled:       bool | *true
			clusterDomain: string | *"cluster.local"
			image: {
				registry:   string | *"docker.io"
				repository: string | *"bitnamilegacy/kafka"
				tag:        string | *"3.9.0-debian-12-r1"
				pullPolicy: string | *"IfNotPresent"
				pullSecrets: [...string] | *[]
			}
			extraConfig: string | *""
			extraConfigYaml: {...} | *{}
			log4j:                      string | *""
			heapOpts:                   string | *"-Xmx1024m -Xms1024m"
			interBrokerProtocolVersion: string | *""
			saslEnabled:                bool | *false
			sslEnabled:                 bool | *false
			tls: {
				sslClientAuth:                   string | *"required"
				endpointIdentificationAlgorithm: string | *"https"
			}
			auth: {
				clientProtocol:      string | *"plaintext"
				interBrokerProtocol: string | *"plaintext"
				controllerProtocol:  string | *"plaintext"
			}
			sasl: {
				client: {
					users: [...string] | *[]
					passwords: [...string] | *[]
				}
				interbroker: {
					user:     string | *"inter_broker_user"
					password: string | *""
				}
				zookeeper: {
					user:     string | *""
					password: string | *""
				}
				controller: {
					user:     string | *""
					password: string | *""
				}
			}
			service: {
				type: string | *"ClusterIP"
				ports: {
					client:      int | *9092
					interbroker: int | *9094
					controller:  int | *9093
					external:    int | *9095
				}
				annotations: {[string]: string} | *{}
				sessionAffinity: string | *"None"
				sessionAffinityConfig: {...} | *{}
				extraPorts: [...{...}] | *[]
			}
			listeners: {
				client: {
					name:          string | *"CLIENT"
					protocol:      string | *"PLAINTEXT"
					containerPort: int | *9092
				}
				interbroker: {
					name:          string | *"INTERNAL"
					protocol:      string | *"PLAINTEXT"
					containerPort: int | *9094
				}
				controller: {
					name:          string | *"CONTROLLER"
					protocol:      string | *"PLAINTEXT"
					containerPort: int | *9093
				}
				external: {
					name:          string | *"EXTERNAL"
					protocol:      string | *"PLAINTEXT"
					containerPort: int | *9095
				}
				extraListeners: [...{
					name:          string
					protocol:      string
					containerPort: int
				}] | *[]
			}
			externalAccess: {
				enabled: bool | *false
				broker: service: {
					type: string | *"LoadBalancer"
					ports: external: int | *9095
					loadBalancerIPs: [...string] | *[]
					loadBalancerSourceRanges: [...string] | *[]
					loadBalancerAnnotations: [...{[string]: string}] | *[]
					annotations: {[string]: string} | *{}
					nodePorts: [...int] | *[]
					externalIPs: [...string] | *[]
					allocateLoadBalancerNodePorts: bool | *true
					loadBalancerClass:             string | *""
					publishNotReadyAddresses:      bool | *true
				}
				controller: service: {
					type: string | *"LoadBalancer"
					ports: external: int | *9095
					loadBalancerIPs: [...string] | *[]
					loadBalancerSourceRanges: [...string] | *[]
					loadBalancerAnnotations: [...{[string]: string}] | *[]
					annotations: {[string]: string} | *{}
					nodePorts: [...int] | *[]
					externalIPs: [...string] | *[]
					allocateLoadBalancerNodePorts: bool | *true
					loadBalancerClass:             string | *""
					publishNotReadyAddresses:      bool | *true
				}
				controller: forceExpose: bool | *false
			}
			metrics: {
				enabled: bool | *false
				jmx: {
					enabled: bool | *false
					image: {
						registry:   string | *"docker.io"
						repository: string | *"bitnami/jmx-exporter"
						tag:        string | *"1.0.1-debian-12-r9"
						pullPolicy: string | *"IfNotPresent"
					}
					containerSecurityContext: {
						enabled:                  bool | *true
						runAsUser:                int | *1001
						runAsGroup:               int | *1001
						runAsNonRoot:             bool | *true
						allowPrivilegeEscalation: bool | *false
						readOnlyRootFilesystem:   bool | *true
						capabilities: drop: ["ALL"]
					}
					containerPorts: metrics: int | *5556
					service: {
						ports: metrics: int | *5556
						clusterIP:       string | *""
						sessionAffinity: string | *"None"
						annotations: {[string]: string} | *{
							"prometheus.io/scrape": "true"
							"prometheus.io/port":   "5556"
							"prometheus.io/path":   "/metrics"
						}
					}
					resources: {...} | *{}
					whitelistObjectNames: [...string] | *[
						"kafka.controller:*",
						"kafka.server:*",
						"java.lang:*",
						"kafka.network:*",
						"kafka.log:*",
					]
					config:     string | *""
					extraRules: string | *""
				}
				serviceMonitor: {
					enabled:       bool | *false
					namespace:     string | *""
					path:          string | *"/metrics"
					interval:      string | *"30s"
					scrapeTimeout: string | *"10s"
					jobLabel:      string | *""
					labels: {[string]: string} | *{}
					selector: {[string]: string} | *{}
					relabelings: [...{...}] | *[]
					metricRelabelings: [...{...}] | *[]
					honorLabels: bool | *false
				}
				prometheusRule: {
					enabled:   bool | *false
					namespace: string | *""
					labels: {[string]: string} | *{}
					groups: [...{...}] | *[]
				}
			}
			kraft: {
				enabled:                bool | *true
				controllerQuorumVoters: string | *str.Join([
					for i in list.Range(0, controller.replicaCount, 1) {
						"\(i)@\(metadata.name)-kafka-controller-\(i).\(metadata.name)-kafka-controller-headless.\(metadata.namespace).svc.\(global.clusterDomain):9093"
					}
				], ",")
				clusterId:              string | *"4L6yzSreSSe9u9D3ZOWSTg"
			}
			rbac: {
				create: bool | *false
			}
			serviceAccount: {
				create:                       bool | *true
				name:                         string | *""
				automountServiceAccountToken: bool | *true
				annotations: {[string]: string} | *{}
			}
			networkPolicy: {
				enabled:             bool | *false
				allowExternal:       bool | *true
				allowExternalEgress: bool | *true
				ingressNSMatchLabels: {[string]: string} | *{}
				ingressNSPodMatchLabels: {[string]: string} | *{}
				extraIngress: [...{...}] | *[]
				extraEgress: [...{...}] | *[]
			}
			zookeeper: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnami/zookeeper"
					tag:        string | *"3.8.4-debian-12-r16"
					pullPolicy: string | *"IfNotPresent"
					debug:      bool | *false
					pullSecrets: [...string] | *[]
				}
				auth: {
					client: {
						enabled:         bool | *false
						clientUser:      string | *""
						clientPassword:  string | *""
						serverUsers:     string | *""
						serverPasswords: string | *""
						existingSecret:  string | *""
					}
					quorum: {
						enabled:         bool | *false
						learnerUser:     string | *""
						learnerPassword: string | *""
						serverUsers:     string | *""
						serverPasswords: string | *""
						existingSecret:  string | *""
					}
				}
				tickTime:                int | *2000
				initLimit:               int | *10
				syncLimit:               int | *5
				preAllocSize:            int | *65536
				snapCount:               int | *100000
				maxClientCnxns:          int | *60
				maxSessionTimeout:       int | *40000
				heapSize:                int | *1024
				fourlwCommandsWhitelist: string | *"srvr, mntr, ruok"
				minServerId:             int | *1
				listenOnAllIPs:          bool | *false
				zooServers:              string | *""
				autopurge: {
					snapRetainCount: int | *10
					purgeInterval:   int | *1
				}
				logLevel:          string | *"ERROR"
				jvmFlags:          string | *""
				dataLogDir:        string | *""
				configuration:     string | *""
				existingConfigmap: string | *""
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				command: [...string] | *[]
				args: [...string] | *[]
				replicaCount:         int | *1
				revisionHistoryLimit: int | *10
				containerPorts: {
					client:      int | *2181
					tls:         int | *3181
					follower:    int | *2888
					election:    int | *3888
					adminServer: int | *8080
					metrics:     int | *9141
				}
				livenessProbe: {
					enabled:             bool | *true
					initialDelaySeconds: int | *30
					periodSeconds:       int | *10
					timeoutSeconds:      int | *5
					failureThreshold:    int | *6
					successThreshold:    int | *1
					probeCommandTimeout: int | *3
				}
				readinessProbe: {
					enabled:             bool | *true
					initialDelaySeconds: int | *5
					periodSeconds:       int | *10
					timeoutSeconds:      int | *5
					failureThreshold:    int | *6
					successThreshold:    int | *1
					probeCommandTimeout: int | *2
				}
				startupProbe: {
					enabled:             bool | *false
					initialDelaySeconds: int | *30
					periodSeconds:       int | *10
					timeoutSeconds:      int | *1
					failureThreshold:    int | *15
					successThreshold:    int | *1
				}
				customLivenessProbe?: {...}
				customReadinessProbe?: {...}
				customStartupProbe?: {...}
				lifecycleHooks: {...} | *{}
				resources: corev1.#ResourceRequirements | *{}
				resourcesPreset: string | *"none"
				podSecurityContext: {
					enabled:             bool | *true
					fsGroupChangePolicy: string | *"Always"
					fsGroup:             int | *1001
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *1001
					runAsNonRoot:             bool | *true
					privileged:               bool | *false
					readOnlyRootFilesystem:   bool | *true
					allowPrivilegeEscalation: bool | *false
					capabilities: drop: ["ALL"]
					seccompProfile: type: "RuntimeDefault"
				}
				automountServiceAccountToken: bool | *false
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podAntiAffinityPreset: string | *"soft"
				podAffinityPreset:     string | *"soft"
				nodeAffinityPreset: {
					type: string | *"soft"
					key:  string | *""
					values: [...string] | *[]
				}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...{...}] | *[]
				podManagementPolicy: string | *"Parallel"
				priorityClassName:   string | *""
				schedulerName:       string | *""
				updateStrategy: {...} | *{}
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				sidecars: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				pdb: {
					create:         bool | *true
					minAvailable:   string | *""
					maxUnavailable: string | *""
				}
				enableServiceLinks: bool | *true
				clusterDomain:      string | *"cluster.local"
				diagnosticMode: {
					enabled: bool | *false
					command: [...string] | *["sleep"]
					args: [...string] | *["infinity"]
				}
				dnsPolicy: string | *""
				dnsConfig: {...} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				extraDeploy: [...{...}] | *[]
				service: {
					type: string | *"ClusterIP"
					ports: {
						client:   int | *2181
						tls:      int | *3181
						follower: int | *2888
						election: int | *3888
					}
					extraPorts: [...corev1.#ServicePort] | *[]
					disableBaseClientPort: bool | *false
					nodePorts: {
						client: string | *""
						tls:    string | *""
					}
					sessionAffinity: string | *"None"
					sessionAffinityConfig: {...} | *{}
					clusterIP:             string | *""
					externalTrafficPolicy: string | *"Cluster"
					loadBalancerIP:        string | *""
					loadBalancerSourceRanges: [...string] | *[]
					annotations: {[string]: string} | *{}
					headless: {
						servicenameOverride:      string | *""
						publishNotReadyAddresses: bool | *true
						annotations: {[string]: string} | *{}
					}
				}
				networkPolicy: {
					enabled:             bool | *true
					allowExternal:       bool | *true
					allowExternalEgress: bool | *true
					extraIngress: [...{...}] | *[]
					extraEgress: [...{...}] | *[]
					ingressNSMatchLabels: {[string]: string} | *{}
					ingressNSPodMatchLabels: {[string]: string} | *{}
				}
				serviceAccount: {
					create:                       bool | *true
					name:                         string | *""
					automountServiceAccountToken: bool | *false
					annotations: {[string]: string} | *{}
				}
				persistence: {
					enabled:      bool | *true
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					size:          string | *"8Gi"
					existingClaim: string | *""
					selector: {...} | *{}
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					dataLogDir: {
						size:          string | *"8Gi"
						existingClaim: string | *""
						selector: {...} | *{}
					}
				}
				volumePermissions: {
					enabled: bool | *false
					image: {
						registry:   string | *"docker.io"
						repository: string | *"bitnamilegacy/zookeeper"
						tag:        string | *"3.9.1-debian-11-r9"
						pullPolicy: string | *"IfNotPresent"
					}
					containerSecurityContext: {
						enabled:   bool | *true
						runAsUser: int | *0
					}
					resources: corev1.#ResourceRequirements | *{}
					resourcesPreset: string | *"none"
				}
				metrics: {
					enabled:       bool | *false
					containerPort: int | *0
					service: {
						type: string | *"ClusterIP"
						port: int | *9141
						annotations: {[string]: string} | *{}
					}
					serviceMonitor: {
						enabled:       bool | *false
						namespace:     string | *""
						interval:      string | *""
						scrapeTimeout: string | *""
						labels: {[string]: string} | *{}
						additionalLabels: {[string]: string} | *{}
						selector: {[string]: string} | *{}
						honorLabels: bool | *false
						relabelings: [...{...}] | *[]
						metricRelabelings: [...{...}] | *[]
						jobLabel: string | *""
						scheme:   string | *""
						tlsConfig: {...} | *{}
					}
					prometheusRule: {
						enabled:   bool | *false
						namespace: string | *""
						labels: {[string]: string} | *{}
						additionalLabels: {[string]: string} | *{}
						rules: [...{...}] | *[]
					}
				}
				tls: {
					client: {
						enabled:                      bool | *false
						auth:                         string | *"none"
						autoGenerated:                bool | *false
						tlsCert:                      string | *""
						tlsKey:                       string | *""
						caCert:                       string | *""
						existingSecret:               string | *""
						existingSecretKeystoreKey:    string | *""
						existingSecretTruststoreKey:  string | *""
						keystorePath:                 string | *"/opt/bitnami/zookeeper/config/certs/client/zookeeper.keystore.jks"
						truststorePath:               string | *"/opt/bitnami/zookeeper/config/certs/client/zookeeper.truststore.jks"
						passwordsSecretName:          string | *""
						passwordsSecretKeystoreKey:   string | *""
						passwordsSecretTruststoreKey: string | *""
						keystorePassword:             string | *""
						truststorePassword:           string | *""
					}
					quorum: {
						enabled:                      bool | *false
						auth:                         string | *"none"
						autoGenerated:                bool | *false
						tlsCert:                      string | *""
						tlsKey:                       string | *""
						caCert:                       string | *""
						existingSecret:               string | *""
						existingSecretKeystoreKey:    string | *""
						existingSecretTruststoreKey:  string | *""
						keystorePath:                 string | *"/opt/bitnami/zookeeper/config/certs/quorum/zookeeper.keystore.jks"
						truststorePath:               string | *"/opt/bitnami/zookeeper/config/certs/quorum/zookeeper.truststore.jks"
						passwordsSecretName:          string | *""
						passwordsSecretKeystoreKey:   string | *""
						passwordsSecretTruststoreKey: string | *""
						keystorePassword:             string | *""
						truststorePassword:           string | *""
					}
					resources: corev1.#ResourceRequirements | *{}
					resourcesPreset: string | *"nano"
				}
			}
			commonLabels: {[string]: string} | *{}
			commonAnnotations: {[string]: string} | *{}
			extraDeploy: [...{...}] | *[]
			volumePermissions: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/kafka"
					tag:        string | *"3.6.0-debian-11-r3"
				}
				containerSecurityContext: {
					enabled:   bool | *true
					runAsUser: int | *0
				}
				resources: {...} | *{}
			}

			broker: {
				replicaCount:        int | *3
				controllerOnly:      bool | *false
				minId:               int | *100
				podManagementPolicy: string | *"OrderedReady"
				updateStrategy: {
					type: string | *"RollingUpdate"
				}
				heapOpts: string | *"-Xmx1024m -Xms1024m"
				podSecurityContext: {
					enabled: bool | *true
					fsGroup: int | *1001
				}
				containerSecurityContext: {
					enabled:   bool | *true
					runAsUser: int | *1001
				}
				resources: {...} | *{}
				persistence: {
					enabled:      bool | *true
					mountPath:    string | *"/bitnami/kafka"
					size:         string | *"8Gi"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
				}
				logPersistence: {
					enabled:      bool | *false
					mountPath:    string | *"/opt/bitnami/kafka/logs"
					size:         string | *"8Gi"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
				}
				automountServiceAccountToken:  bool | *true
				hostNetwork:                   bool | *false
				hostIPC:                       bool | *false
				priorityClassName:             string | *""
				schedulerName:                 string | *""
				terminationGracePeriodSeconds: int | *30
				topologySpreadConstraints: [...{}] | *[]
				nodeSelector: {...} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: {...} | *{}
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				livenessProbe: {
					initialDelaySeconds: int | *10
					periodSeconds:       int | *10
					timeoutSeconds:      int | *5
					successThreshold:    int | *1
					failureThreshold:    int | *3
				}
				readinessProbe: {
					initialDelaySeconds: int | *5
					periodSeconds:       int | *10
					timeoutSeconds:      int | *5
					successThreshold:    int | *1
					failureThreshold:    int | *6
				}
				pdb: {
					create:         bool | *true
					minAvailable:   string | *""
					maxUnavailable: string | *""
				}
				autoscaling: {
					vpa: {
						enabled: bool | *false
						annotations: {[string]: string} | *{}
						updateMode: string | *"Auto"
						controlledResources?: [...string]
						maxAllowed?: {[string]: string | int}
						minAllowed?: {[string]: string | int}
					}
					hpa: {
						enabled:      bool | *false
						minReplicas:  int | *1
						maxReplicas:  int | *11
						targetCPU:    int | *50
						targetMemory: int | *50
					}
				}
				extraConfig: string | *""
			}

			controller: {
				replicaCount:        int | *3
				controllerOnly:      bool | *true
				minId:               int | *0
				podManagementPolicy: string | *"OrderedReady"
				updateStrategy: {
					type: string | *"RollingUpdate"
				}
				heapOpts: string | *"-Xmx1024m -Xms1024m"
				podSecurityContext: {
					enabled: bool | *true
					fsGroup: int | *1001
				}
				containerSecurityContext: {
					enabled:   bool | *true
					runAsUser: int | *1001
				}
				resources: {...} | *{}
				persistence: {
					enabled:      bool | *true
					mountPath:    string | *"/bitnami/kafka"
					size:         string | *"8Gi"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
				}
				logPersistence: {
					enabled:      bool | *false
					mountPath:    string | *"/opt/bitnami/kafka/logs"
					size:         string | *"8Gi"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
				}
				automountServiceAccountToken:  bool | *true
				hostNetwork:                   bool | *false
				hostIPC:                       bool | *false
				priorityClassName:             string | *""
				schedulerName:                 string | *""
				terminationGracePeriodSeconds: int | *30
				topologySpreadConstraints: [...{}] | *[]
				nodeSelector: {...} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: {...} | *{}
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				livenessProbe: {
					initialDelaySeconds: int | *10
					periodSeconds:       int | *10
					timeoutSeconds:      int | *5
					successThreshold:    int | *1
					failureThreshold:    int | *3
				}
				readinessProbe: {
					initialDelaySeconds: int | *5
					periodSeconds:       int | *10
					timeoutSeconds:      int | *5
					successThreshold:    int | *1
					failureThreshold:    int | *6
				}
				pdb: {
					create:         bool | *true
					minAvailable:   string | *""
					maxUnavailable: string | *""
				}
				autoscaling: {
					enabled: bool | *false
					vpa: {
						enabled: bool | *false
						annotations: {[string]: string} | *{}
						updateMode: string | *"Auto"
						controlledResources?: [...string]
						maxAllowed?: {[string]: string | int}
						minAllowed?: {[string]: string | int}
					}
					hpa: {
						enabled:      bool | *false
						minReplicas:  int | *1
						maxReplicas:  int | *11
						targetCPU:    int | *50
						targetMemory: int | *50
					}
				}
				extraConfig: string | *""
			}
			provisioning: {
				enabled:                      bool | *false
				automountServiceAccountToken: bool | *false
				numPartitions:                int | *1
				replicationFactor:            int | *1
				topics: [...{
					name:               string
					partitions?:        int
					replicationFactor?: int
					config: {[string]: string} | *{}
				}] | *[]
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				extraProvisioningCommands: [...string] | *[]
				parallel:   int | *1
				preScript:  string | *""
				postScript: string | *""
				auth: tls: {
					type:                        string | *"jks"
					certificatesSecret:          string | *""
					cert:                        string | *"tls.crt"
					key:                         string | *"tls.key"
					caCert:                      string | *"ca.crt"
					keystore:                    string | *"keystore.jks"
					truststore:                  string | *"truststore.jks"
					passwordsSecret:             string | *""
					keyPasswordSecretKey:        string | *"key-password"
					keystorePasswordSecretKey:   string | *"keystore-password"
					truststorePasswordSecretKey: string | *"truststore-password"
					keyPassword:                 string | *""
					keystorePassword:            string | *""
					truststorePassword:          string | *""
				}
				command: [...string] | *[]
				args: [...string] | *[]
				extraEnvVars: [...corev1.#EnvVar] | *[]
				extraEnvVarsCM:     string | *""
				extraEnvVarsSecret: string | *""
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				serviceAccount: {
					create:                       bool | *true
					name:                         string | *""
					automountServiceAccountToken: bool | *false
					annotations: {[string]: string} | *{}
				}
				resourcesPreset: string | *"micro"
				resources: corev1.#ResourceRequirements | *{}
				podSecurityContext: {
					enabled:             bool | *true
					fsGroupChangePolicy: string | *"Always"
					sysctls: [...{...}] | *[]
					supplementalGroups: [...int] | *[]
					fsGroup: int | *1001
					seccompProfile: type: string | *"RuntimeDefault"
				}
				containerSecurityContext: {
					enabled:                  bool | *true
					runAsUser:                int | *1001
					runAsGroup:               int | *1001
					runAsNonRoot:             bool | *true
					allowPrivilegeEscalation: bool | *false
					readOnlyRootFilesystem:   bool | *true
					capabilities: drop: ["ALL"]
				}
				interBrokerProtocolVersion: string | *""
				saslEnabledMechanisms:      string | *"PLAIN,SCRAM-SHA-256"
				enableServiceLinks:         bool | *true
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				sidecars: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				waitForKafka: bool | *true
				useHelmHooks: bool | *true
				...
			}
		}
		clickhouse: {
			name:         string | *"clickhouse"
			enabled:      bool | *true
			clusterName:  string | *"default"
			shards:       int | *1
			replicaCount: int | *1
			logLevel:     string | *"information"
			image: {
				registry:   string | *"docker.io"
				repository: string | *"bitnamilegacy/clickhouse"
				tag:        string | *"24.3"
				pullPolicy: string | *"IfNotPresent"
			}
			auth: {
				username: string | *"default"
				password: string | *"password123"
			}
			persistence: {
				enabled:       bool | *true
				size:          string | *"8Gi"
				storageClass?: string
				accessModes: [...string] | *["ReadWriteOnce"]
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				existingClaim?: string
			}
			tolerations: [...corev1.#Toleration] | *[]
			nodeSelector: {[string]: string} | *{}
			podAnnotations: {[string]: string} | *{}
			commonLabels: {[string]: string} | *{}
			commonAnnotations: {[string]: string} | *{}

			ingress: {
				enabled:   bool | *false
				hostname?: string
				path:      string | *"/"
				pathType:  string | *"Prefix"
				annotations: {[string]: string} | *{}
				ingressClassName?: string
				tls:               bool | *false
				...
			}

			service: {
				type: string | *"ClusterIP"
				annotations: {[string]: string} | *{}
				ports: {
					http:         int | *8123
					tcp:          int | *9000
					mysql:        int | *9004
					postgresql:   int | *9005
					interserver:  int | *9009
					https:        int | *8443
					tcpSecure:    int | *9440
					keeper:       int | *2181
					keeperInter:  int | *2888
					keeperSecure: int | *3181
					metrics:      int | *9363
				}
				nodePorts: {
					http?:         int
					https?:        int
					tcp?:          int
					tcpSecure?:    int
					keeper?:       int
					keeperInter?:  int
					keeperSecure?: int
					mysql?:        int
					postgresql?:   int
					interserver?:  int
					metrics?:      int
				}
				clusterIP?:      string
				sessionAffinity: string | *"None"
				sessionAffinityConfig?: {[string]: _}
				externalTrafficPolicy?: string
				loadBalancerSourceRanges?: [...string]
				loadBalancerIP?: string
			}

			containerPorts: {
				http:         int | *8123
				tcp:          int | *9000
				mysql:        int | *9004
				postgresql:   int | *9005
				interserver:  int | *9009
				https:        int | *8443
				tcpSecure:    int | *9440
				keeper:       int | *2181
				keeperInter:  int | *2888
				keeperSecure: int | *3181
				metrics:      int | *9363
			}

			tls: enabled: bool | *false
			metrics: {
				enabled: bool | *false
				prometheusRule: {
					enabled: bool | *false
					rules: [...{[string]: _}] | *[]
				}
				serviceMonitor: {
					enabled:    bool | *false
					namespace?: string
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
					jobLabel?:      string
					interval?:      string
					scrapeTimeout?: string
					honorLabels?:   bool
					metricRelabelings: [...{[string]: _}] | *[]
					relabelings: [...{[string]: _}] | *[]
					selector: {[string]: string} | *{}
				}
			}

			pdb: {
				create:          bool | *false
				minAvailable?:   int | string
				maxUnavailable?: int | string
			}

			extraOverrides?:      string
			usersExtraOverrides?: string
			initdbScripts?: {[string]: string}
			startdbScripts?: {[string]: string}

			podManagementPolicy: string | *"OrderedReady"
			updateStrategy: type: string | *"RollingUpdate"

			priorityClassName?: string
			schedulerName?:     string
			topologySpreadConstraints: [...{[string]: _}] | *[]

			podSecurityContext: {
				enabled: bool | *true
				fsGroup: int | *1001
			}

			containerSecurityContext: {
				enabled:      bool | *true
				runAsUser:    int | *1001
				runAsNonRoot: bool | *true
			}

			volumePermissions: {
				enabled: bool | *false
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/clickhouse"
					tag:        string | *"23.11.2-debian-11-r1"
					pullPolicy: string | *"IfNotPresent"
				}
			}

			terminationGracePeriodSeconds?: int
			hostAliases: [...{[string]: _}] | *[]

			zookeeper: {
				enabled:      bool | *true
				replicaCount: int | *1
				tickTime:     int | *2000
				logLevel:     string | *"ERROR"
				image: {
					registry:   string | *"docker.io"
					repository: string | *"bitnamilegacy/zookeeper"
					tag:        string | *"3.8.4-debian-12-r16"
					pullPolicy: string | *"IfNotPresent"
				}
				persistence: {
					enabled:       bool | *true
					size:          string | *"8Gi"
					storageClass?: string
					accessModes: [...string] | *["ReadWriteOnce"]
					dataLogDir: {
						size: string | *"8Gi"
					}
				}
				tolerations: [...corev1.#Toleration] | *[]
				containerPorts: {
					client:   int | *2181
					follower: int | *2888
					election: int | *3888
				}
			}
		}
		mailhog: {
			enabled: bool | *true
			image: {
				repository: string | *"mailhog/mailhog"
				tag:        string | *"v1.0.1"
				pullPolicy: string | *"IfNotPresent"
			}
			imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
			nameOverride:     string | *""
			fullnameOverride: string | *""
			serviceAccount: {
				create: bool | *true
				name:   string | *""
				imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
			}
			automountServiceAccountToken: bool | *false
			service: {
				annotations: {[string]: string} | *{}
				clusterIP: string | *""
				externalIPs: [...string] | *[]
				loadBalancerIP: string | *""
				loadBalancerSourceRanges: [...string] | *[]
				type: string | *"ClusterIP"
				port: {
					http: int | *8025
					smtp: int | *1025
				}
				nodePort: {
					http: string | *""
					smtp: string | *""
				}
			}
			securityContext: {
				runAsUser:    int | *1000
				runAsGroup:   int | *1000
				runAsNonRoot: bool | *true
				fsGroup:      int | *1000
			}
			containerSecurityContext: {
				readOnlyRootFilesystem:   bool | *true
				privileged:               bool | *false
				allowPrivilegeEscalation: bool | *false
				capabilities: drop: [...string] | *["ALL"]
			}
			ingress: {
				enabled: bool | *false
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				hosts: [...{
					host: string
					paths: [...string] | *["/"]
				}] | *[]
				tls: [...{
					secretName: string
					hosts: [...string]
				}] | *[]
			}
			auth: {
				enabled:        bool | *false
				existingSecret: string | *""
				fileName:       string | *"auth.txt"
				fileContents:   string | *""
			}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{}
			extraEnv: [...corev1.#EnvVar] | *[]
			resources: corev1.#ResourceRequirements | *{}
			affinity: corev1.#Affinity | *{}
			nodeSelector: {[string]: string} | *{}
			tolerations: [...corev1.#Toleration] | *[]
		}
		vector: {
			enabled: bool | *true
			commonLabels: {[string]: string} | *{}
			nameOverride:     string | *""
			fullnameOverride: string | *""
			role:             "Agent" | "Aggregator" | "Stateless-Aggregator" | *"Aggregator"
			rollWorkload:     bool | *true
			image: {
				repository: string | *"timberio/vector"
				pullPolicy: string | *"IfNotPresent"
				pullSecrets: [...string] | *[]
				tag:  string | *"0.42.0-distroless-libc"
				sha:  string | *""
				base: string | *""
			}
			replicas: int | *1
			hostAliases: [...{...}] | *[]
			podManagementPolicy: string | *"OrderedReady"
			env: [...corev1.#EnvVar] | *[]
			envFrom: [...corev1.#EnvFromSource] | *[]
			containerPorts: [...corev1.#ContainerPort] | *[]
			secrets: generic: [string]: string
			updateStrategy: {...} | *{}
			autoscaling: {
				enabled:  bool | *false
				external: bool | *false
				annotations: {[string]: string} | *{}
				minReplicas:                       int | *1
				maxReplicas:                       int | *10
				targetCPUUtilizationPercentage:    int | *80
				targetMemoryUtilizationPercentage: int | *80
				customMetric: {...} | *{}
				behavior: {...} | *{}
			}
			podDisruptionBudget: {
				enabled:        bool | *false
				minAvailable:   int | *1
				maxUnavailable: int | *0
			}
			rbac: create: bool | *true
			psp: create:  bool | *false
			serviceAccount: {
				create: bool | *true
				annotations: {[string]: string} | *{}
				name:           string | *""
				automountToken: bool | *true
			}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{"vector.dev/exclude": "true"}
			workloadResourceAnnotations: {[string]: string} | *{}
			podPriorityClassName: string | *""
			podHostNetwork:       bool | *false
			podSecurityContext: {...} | *{}
			securityContext: {...} | *{}
			command: [...string] | *[]
			args: [...string] | *["--config-dir", "/etc/vector/"]
			resources: corev1.#ResourceRequirements | *{}
			lifecycle: {...} | *{}
			minReadySeconds:               int | *0
			terminationGracePeriodSeconds: int | *60
			nodeSelector: {[string]: string} | *{}
			tolerations: [...corev1.#Toleration] | *[]
			affinity: corev1.#Affinity | *{}
			topologySpreadConstraints: [...{...}] | *[]
			service: {
				enabled: bool | *true
				type:    string | *"ClusterIP"
				annotations: {[string]: string} | *{}
				topologyKeys: [...string] | *[]
				ports: [...corev1.#ServicePort] | *[]
				externalTrafficPolicy: string | *""
				internalTrafficPolicy: string | *""
				loadBalancerIP:        string | *""
				ipFamilyPolicy:        string | *""
				ipFamilies: [...string] | *[]
			}
			serviceHeadless: enabled: bool | *true
			ingress: {
				enabled:   bool | *false
				className: string | *""
				annotations: {[string]: string} | *{}
				hosts: [...{
					host: string
					paths: [...{
						path:     string
						pathType: string
						port: {
							name:   string | *""
							number: string | *""
						}
					}]
				}] | *[]
				tls: [...{...}] | *[]
			}
			existingConfigMaps: [...string] | *[]
			dataDir: string | *""
			customConfig: {...} | *{}
			defaultVolumes: [...corev1.#Volume] | *[
				{name: "var-log", hostPath: path: "/var/log/"},
				{name: "var-lib", hostPath: path: "/var/lib/"},
				{name: "procfs", hostPath: path: "/proc"},
				{name: "sysfs", hostPath: path: "/sys"},
			]
			defaultVolumeMounts: [...corev1.#VolumeMount] | *[
				{name: "var-log", mountPath: "/var/log/", readOnly: true},
				{name: "var-lib", mountPath: "/var/lib", readOnly: true},
				{name: "procfs", mountPath: "/host/proc", readOnly: true},
				{name: "sysfs", mountPath: "/host/sys", readOnly: true},
			]
			extraVolumes: [...corev1.#Volume] | *[]
			extraVolumeMounts: [...corev1.#VolumeMount] | *[]
			initContainers: [...corev1.#Container] | *[]
			extraContainers: [...corev1.#Container] | *[]
			persistence: {
				enabled:       bool | *false
				existingClaim: string | *""
				storageClass:  string | *""
				accessModes: [...string] | *["ReadWriteOnce"]
				size: string | *"10Gi"
				finalizers: [...string] | *["kubernetes.io/pvc-protection"]
				selectors: {...} | *{}
				hostPath: {
					enabled: bool | *true
					path:    string | *"/var/lib/vector"
				}
				retentionPolicy: {...} | *{}
			}
			dnsPolicy: string | *"ClusterFirst"
			dnsConfig: {...} | *{}
			shareProcessNamespace: bool | *false
			livenessProbe: {...} | *{}
			readinessProbe: {...} | *{}
			podMonitor: {
				enabled:       bool | *false
				jobLabel:      string | *"app.kubernetes.io/name"
				port:          string | *"prom-exporter"
				path:          string | *"/metrics"
				interval:      string | *""
				scrapeTimeout: string | *""
				relabelings: [...{...}] | *[]
				metricRelabelings: [...{...}] | *[]
				podTargetLabels: [...string] | *[]
				additionalLabels: {[string]: string} | *{}
				honorLabels:     bool | *false
				honorTimestamps: bool | *true
			}
			logLevel: string | *"info"
			haproxy: {
				enabled: bool | *false
				image: {
					repository: string | *"haproxytech/haproxy-alpine"
					pullPolicy: string | *"IfNotPresent"
					pullSecrets: [...string] | *[]
					tag: string | *"2.6.12"
				}
				rollWorkload: bool | *true
				replicas:     int | *1
				serviceAccount: {
					create: bool | *true
					annotations: {[string]: string} | *{}
					name:           string | *""
					automountToken: bool | *true
				}
				strategy: {...} | *{}
				terminationGracePeriodSeconds: int | *60
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				podPriorityClassName: string | *""
				podSecurityContext: {...} | *{}
				securityContext: {...} | *{}
				containerPorts: [...corev1.#ContainerPort] | *[]
				service: {
					type: string | *"ClusterIP"
					annotations: {[string]: string} | *{}
					topologyKeys: [...string] | *[]
					ports: [...corev1.#ServicePort] | *[]
					externalTrafficPolicy: string | *""
					loadBalancerIP:        string | *""
					ipFamilyPolicy:        string | *""
					ipFamilies: [...string] | *[]
				}
				existingConfigMap: string | *""
				customConfig:      string | *""
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				initContainers: [...corev1.#Container] | *[]
				extraContainers: [...corev1.#Container] | *[]
				autoscaling: {
					enabled:                           bool | *false
					external:                          bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *80
					targetMemoryUtilizationPercentage: int | *80
					customMetric: {...} | *{}
				}
				resources: corev1.#ResourceRequirements | *{}
				livenessProbe: {...} | *{tcpSocket: port: 1024}
				readinessProbe: {...} | *{tcpSocket: port: 1024}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: corev1.#Affinity | *{}
			}
			extraObjects: [...{...}] | *[]
		}
		"hyperswitch-control-center": {
			enabled: bool | *true
			global: imageRegistry: string | *""
			dependencies: {
				router: host: string | *"http://localhost:8080"
				sdk: {
					host:            string | *"http://localhost:9050"
					version:         string | *"0.126.0"
					subversion:      string | *"v1"
					fullUrlOverride: string | *""
				}
				clickhouse: enabled: bool | *false
			}
			replicaCount: int | *1
			strategy: {
				type: string | *"RollingUpdate"
				rollingUpdate: {
					maxSurge:       int | *1
					maxUnavailable: int | *0
				}
			}
			progressDeadlineSeconds:       int | *600
			terminationGracePeriodSeconds: int | *30
			image: {
				registry:   string | *"docker.juspay.io"
				repository: string | *"juspaydotin/hyperswitch-control-center"
				pullPolicy: string | *"IfNotPresent"
				tag:        string | *"v1.38.2"
			}
			imagePullSecrets: [...{name: string}] | *[]
			nameOverride:     string | *""
			fullnameOverride: string | *""
			serviceAccount: {
				create:    bool | *true
				automount: bool | *true
				annotations: {[string]: string} | *{}
				name: string | *""
			}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{}
			podSecurityContext: {[string]: _} | *{}
			securityContext: {
				privileged: bool | *false
				[string]:   _
			}
			service: {
				type: string | *"ClusterIP"
				port: int | *9000
				annotations: {[string]: string} | *{}
			}
			ingress: {
				enabled:   bool | *false
				className: string | *""
				annotations: {[string]: string} | *{}
				hosts: [...{
					host: string
					paths: [...{
						path:     string
						pathType: string
					}]
				}] | *[]
				tls: [...{
					secretName: string
					hosts: [...string]
				}] | *[]
			}
			resources: {
				requests: {
					cpu:    string | *"100m"
					memory: string | *"100Mi"
				}
				limits?: {
					cpu:    string
					memory: string
				}
			}
			livenessProbe: {
				httpGet: {
					path: string | *"/"
					port: string | *"http"
				}
				initialDelaySeconds: int | *30
				periodSeconds:       int | *10
				timeoutSeconds:      int | *5
				failureThreshold:    int | *3
				successThreshold:    int | *1
			}
			readinessProbe: {
				httpGet: {
					path: string | *"/"
					port: string | *"http"
				}
				initialDelaySeconds: int | *10
				periodSeconds:       int | *5
				timeoutSeconds:      int | *3
				failureThreshold:    int | *3
				successThreshold:    int | *1
			}
			volumes: [...{name: string, [string]: _}] | *[]
			volumeMounts: [...{name: string, mountPath: string, [string]: _}] | *[]
			nodeSelector: {[string]: string} | *{}
			tolerations: [...{}] | *[]
			affinity: {[string]: _} | *{}
			config: {
				mixpanelToken: string | *"dd4da7f62941557e716fbc0a19f9cc7e"
				default: {
					features: {[string]: string | bool} | *{
						email:                       "true"
						branding:                    "false"
						surcharge:                   "true"
						quick_start:                 "true"
						recon:                       "true"
						payout:                      "true"
						frm:                         "true"
						mixpanel:                    "false"
						sample_data:                 "true"
						is_live_mode:                "false"
						feedback:                    "false"
						generate_report:             "true"
						system_metrics:              "false"
						test_live_toggle:            "false"
						test_processors:             "true"
						user_journey_analytics:      "false"
						totp:                        "false"
						authentication_analytics:    "false"
						compliance_certificate:      "true"
						configure_pmts:              "true"
						custom_webhook_headers:      "false"
						global_search:               "true"
						new_analytics:               "true"
						new_analytics_filters:       "true"
						new_analytics_refunds:       "true"
						new_analytics_smart_retries: "true"
						performance_monitor:         "true"
						tenant_user:                 "true"
						transaction_view:            true
						pm_authentication_processor: "true"
						tax_processors:              "true"
						threeds_authenticator:       "true"
						dev_alt_payment_methods:     false
						dev_click_to_pay:            "true"
						dev_debit_routing:           false
						dev_hypersense_v2_product:   false
						dev_intelligent_routing_v2:  false
						dev_modularity_v2:           false
						dev_recon_v2_product:        false
						dev_recovery_v2_product:     false
						dev_vault_v2_product:        false
						dev_webhooks:                false
						dispute_analytics:           "false"
						dispute_evidence_upload:     "false"
						down_time:                   false
						force_cookies:               false
						global_search_filters:       false
						granularity:                 false
						live_users_counter:          "false"
						maintainence_alert:          ""
						recon_v2:                    false
					}
					endpoints: {
						dss_certificate_url: string | *"https://app.hyperswitch.io/certificates/PCI_DSS_v4-0_AOC_Juspay_2024.pdf"
						favicon_url:         string | *""
						logo_url:            string | *""
						agreement_url:       string | *"https://app.hyperswitch.io/agreement/tc-hyperswitch-aug-23.pdf"
						agreement_version:   string | *"1.0.0"
						mixpanel_token:      string | *"dd4da7f62941557e716fbc0a19f9cc7e"
						hypersense_url:      string | *""
						recon_iframe_url:    string | *""
					}
					theme: {
						primary_color:                string | *"#006DF9"
						primary_hover_color:          string | *"#005ED6"
						sidebar_color:                string | *"#242F48"
						sidebar_border_color:         string | *"#ECEFF3"
						sidebar_primary:              string | *"#FCFCFD"
						sidebar_primary_text_color:   string | *"#1C6DEA"
						sidebar_secondary:            string | *"#FFFFFF"
						sidebar_secondary_text_color: string | *"#525866"
					}
					merchant_config: {
						new_analytics: {
							merchant_ids: [...string] | *[]
							org_ids: [...string] | *[]
							profile_ids: [...string] | *[]
						}
					}
				}
			}
			extraEnvVars: [...{name: string, value?: string, valueFrom?: _}] | *[]
			istio: {
				enabled: bool | *false
				virtualService: {
					enabled: bool | *false
					hosts: [...string] | *[]
					gateways: [...string] | *[]
					http: [...{}] | *[]
				}
				destinationRule: {
					enabled: bool | *false
					trafficPolicy: {[string]: _} | *{}
				}
			}
		}
		...
	}

	"hyperswitch-monitoring": {
		enabled: bool | *true
		global: {
			tolerations: [...corev1.#Toleration] | *[]
			imageRegistry: string | *""
			image: registry: string | *""
			imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
			rbac: {
				create:                      bool | *true
				createAggregateClusterRoles: bool | *true
				pspEnabled:                  bool | *false
				pspAnnotations: {[string]: string} | *{}
			}
			labels: stack: string | *"hyperswitch-monitoring"
		}
		"kube-prometheus-stack": {
			enabled:                   bool | *true
			nameOverride:              string | *""
			fullnameOverride:          string | *""
			namespaceOverride:         string | *""
			kubeTargetVersionOverride: string | *""
			kubernetesServiceMonitors: enabled: bool | *true
			windowsMonitoring: enabled:         bool | *false
			commonLabels: {[string]: string} | *{}
			cleanPrometheusOperatorObjectNames: bool | *false
			prometheus: prometheusSpec: {
				tolerations: [...corev1.#Toleration] | *[]
				ignoreNamespaceSelectors: bool | *false
				remoteWriteDashboards:    bool | *false
				image: {
					registry:   string | *"quay.io"
					repository: string | *"prometheus/prometheus"
					tag:        string | *"v2.54.1"
				}
			}
			kubeApiServer: {
				enabled: bool | *true
				tlsConfig: {
					serverName:         string | *"kubernetes"
					insecureSkipVerify: bool | *false
				}
				serviceMonitor: {
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					jobLabel:              string | *"component"
					selector: matchLabels: {
						component: string | *"apiserver"
						provider:  string | *"kubernetes"
					}
					metricRelabelings: [...{...}] | *[{
						action: "drop"
						regex:  "apiserver_request_duration_seconds_bucket;(0.15|0.2|0.3|0.35|0.4|0.45|0.6|0.7|0.8|0.9|1.25|1.5|1.75|2|3|3.5|4|4.5|6|7|8|9|15|25|40|50)"
						sourceLabels: ["__name__", "le"]
					}]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			kubelet: {
				enabled:   bool | *true
				namespace: string | *"kube-system"
				serviceMonitor: {
					attachMetadata: node: bool | *false
					interval:              string | *""
					scrapeTimeout:         string | *""
					honorLabels:           bool | *true
					honorTimestamps:       bool | *true
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					https:                 bool | *true
					insecureSkipVerify:    bool | *true
					cAdvisor:              bool | *true
					probes:                bool | *true
					resource:              bool | *false
					resourcePath:          string | *"/metrics/resource/v1alpha1"
					cAdvisorMetricRelabelings: [...{...}] | *[
						{sourceLabels: ["__name__"], action: "drop", regex: "container_cpu_(cfs_throttled_seconds_total|load_average_10s|system_seconds_total|user_seconds_total)"},
						{sourceLabels: ["__name__"], action: "drop", regex: "container_fs_(io_current|io_time_seconds_total|io_time_weighted_seconds_total|reads_merged_total|sector_reads_total|sector_writes_total|writes_merged_total)"},
						{sourceLabels: ["__name__"], action: "drop", regex: "container_memory_(mapped_file|swap)"},
						{sourceLabels: ["__name__"], action: "drop", regex: "container_(file_descriptors|tasks_state|threads_max)"},
						{sourceLabels: ["__name__"], action: "drop", regex: "container_spec.*"},
						{sourceLabels: ["id", "pod"], action: "drop", regex: ".+;"},
					]
					probesMetricRelabelings: [...{...}] | *[]
					cAdvisorRelabelings: [...{...}] | *[{action: "replace", sourceLabels: ["__metrics_path__"], targetLabel: "metrics_path"}]
					probesRelabelings: [...{...}] | *[{action: "replace", sourceLabels: ["__metrics_path__"], targetLabel: "metrics_path"}]
					resourceRelabelings: [...{...}] | *[{action: "replace", sourceLabels: ["__metrics_path__"], targetLabel: "metrics_path"}]
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[{action: "replace", sourceLabels: ["__metrics_path__"], targetLabel: "metrics_path"}]
					additionalLabels: {[string]: string} | *{}
				}
			}
			kubeControllerManager: {
				enabled: bool | *true
				endpoints: [...string] | *[]
				service: {
					enabled:    bool | *true
					port:       int | *10252
					targetPort: int | *10252
					selector: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceMonitor: {
					enabled:               bool | *true
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					port:                  string | *"http-metrics"
					jobLabel:              string | *"jobLabel"
					selector: {[string]: string} | *{}
					https:              bool | *null
					insecureSkipVerify: bool | *null
					serverName:         string | *null
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			coreDns: {
				enabled: bool | *true
				service: {
					enabled:    bool | *true
					port:       int | *9153
					targetPort: int | *9153
					selector: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceMonitor: {
					enabled:               bool | *true
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					port:                  string | *"http-metrics"
					jobLabel:              string | *"jobLabel"
					selector: {[string]: string} | *{}
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			kubeDns: {
				enabled: bool | *false
				service: {
					dnsmasq: {port: int | *10054, targetPort: int | *10054}
					skydns: {port: int | *10055, targetPort: int | *10055}
					selector: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceMonitor: {
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					jobLabel:              string | *"jobLabel"
					selector: {[string]: string} | *{}
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					dnsmasqMetricRelabelings: [...{...}] | *[]
					dnsmasqRelabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			kubeEtcd: {
				enabled: bool | *true
				endpoints: [...string] | *[]
				service: {
					enabled:    bool | *true
					port:       int | *2381
					targetPort: int | *2381
					selector: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceMonitor: {
					enabled:               bool | *true
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					scheme:                string | *"http"
					insecureSkipVerify:    bool | *false
					serverName:            string | *""
					caFile:                string | *""
					certFile:              string | *""
					keyFile:               string | *""
					port:                  string | *"http-metrics"
					jobLabel:              string | *"jobLabel"
					selector: {[string]: string} | *{}
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			kubeScheduler: {
				enabled: bool | *true
				endpoints: [...string] | *[]
				service: {
					enabled:    bool | *true
					port:       int | *10259
					targetPort: int | *10259
					selector: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceMonitor: {
					enabled:               bool | *true
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					https:                 bool | *null
					port:                  string | *"http-metrics"
					jobLabel:              string | *"jobLabel"
					selector: {[string]: string} | *{}
					insecureSkipVerify: bool | *null
					serverName:         string | *null
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			kubeProxy: {
				enabled: bool | *true
				endpoints: [...string] | *[]
				service: {
					enabled:    bool | *true
					port:       int | *10249
					targetPort: int | *10249
					selector: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceMonitor: {
					enabled:               bool | *true
					interval:              string | *""
					sampleLimit:           int | *0
					targetLimit:           int | *0
					labelLimit:            int | *0
					labelNameLengthLimit:  int | *0
					labelValueLengthLimit: int | *0
					proxyUrl:              string | *""
					port:                  string | *"http-metrics"
					jobLabel:              string | *"jobLabel"
					selector: {[string]: string} | *{}
					https: bool | *false
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			"kube-state-metrics": {
				enabled:           bool | *true
				prometheusScrape:  bool | *true
				nameOverride:      string | *""
				fullnameOverride:  string | *""
				namespaceOverride: string | *""
				image: {
					registry:   string | *"registry.k8s.io"
					repository: string | *"kube-state-metrics/kube-state-metrics"
					tag:        string | *"v2.13.0"
					sha:        string | *""
					pullPolicy: string | *"IfNotPresent"
				}
				imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
				global: {
					imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
					imageRegistry: string | *""
				}
				autosharding: enabled: bool | *false
				replicas:             int | *1
				updateStrategy:       string | *""
				revisionHistoryLimit: int | *10
				extraArgs: [...string] | *[]
				automountServiceAccountToken: bool | *true
				service: {
					port: int | *8080
					type: string | *"ClusterIP"
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
					nodePort:       int | *0
					loadBalancerIP: string | *""
					loadBalancerSourceRanges: [...string] | *[]
					clusterIP: string | *""
					annotations: {[string]: string} | *{}
				}
				customLabels: {[string]: string} | *{}
				selectorOverride: {[string]: string} | *{}
				releaseLabel: bool | *false
				hostNetwork:  bool | *false
				rbac: {
					create:          bool | *true
					useClusterRole:  bool | *true
					useExistingRole: string | *""
					extraRules: [...rbacv1.#PolicyRule] | *[]
				}
				kubeRBACProxy: {
					enabled: bool | *false
					image: {
						registry:   string | *"quay.io"
						repository: string | *"brancz/kube-rbac-proxy"
						tag:        string | *"v0.18.0"
						sha:        string | *""
						pullPolicy: string | *"IfNotPresent"
					}
					extraArgs: [...string] | *[]
					containerSecurityContext: {...} | *{readOnlyRootFilesystem: true, allowPrivilegeEscalation: false, capabilities: drop: ["ALL"]}
					resources: corev1.#ResourceRequirements | *{}
					volumeMounts: [...corev1.#VolumeMount] | *[]
				}
				serviceAccount: {
					create: bool | *true
					name:   string | *""
					imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
					annotations: {[string]: string} | *{}
					automountServiceAccountToken: bool | *true
				}
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				securityContext: {
					enabled: bool | *true
					value: corev1.#PodSecurityContext | *{fsGroup: 65534, runAsGroup: 65534, runAsUser: 65534}
				}
				priorityClassName: string | *""
				initContainers: [...corev1.#Container] | *[]
				containers: [...corev1.#Container] | *[]
				containerSecurityContext: {...} | *{allowPrivilegeEscalation: false, capabilities: drop: ["ALL"], readOnlyRootFilesystem: true, runAsNonRoot: true, runAsUser: 65534, seccompProfile: type: "RuntimeDefault"}
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				volumes: [...corev1.#Volume] | *[]
				volumeMounts: [...corev1.#VolumeMount] | *[]
				collectors: [...string] | *["certificatesigningrequests", "configmaps", "cronjobs", "daemonsets", "deployments", "endpoints", "endpointslices", "horizontalpodautoscalers", "ingresses", "jobs", "leases", "limitranges", "mutatingwebhookconfigurations", "namespaces", "networkpolicies", "nodes", "persistentvolumeclaims", "persistentvolumes", "poddisruptionbudgets", "pods", "replicasets", "replicationcontrollers", "resourcequotas", "secrets", "services", "statefulsets", "storageclasses", "validatingwebhookconfigurations", "volumeattachments"]
				metricLabelsAllowlist: [...string] | *[]
				metricAnnotationsAllowList: [...string] | *[]
				metricAllowlist: [...string] | *[]
				metricDenylist: [...string] | *[]
				namespaces: [...string] | *[]
				releaseNamespace: bool | *false
				namespacesDenylist: [...string] | *[]
				kubeconfig: enabled: bool | *false
				kubeconfig: secret:  string | *""
				customResourceState: {
					enabled: bool | *false
					config: {...} | *{}
				}
				extraManifests: [...{...}] | *[]
				podDisruptionBudget: {...} | *{}
				podSecurityPolicy: {
					enabled: bool | *false
					annotations: {[string]: string} | *{}
					additionalVolumes: [...string] | *[]
				}
				networkPolicy: {
					enabled: bool | *false
					flavor:  "kubernetes" | "cilium" | *"kubernetes"
					egress: [...{...}] | *[]
					ingress: [...{...}] | *[]
					podSelector: {...} | *{}
					cilium: kubeApiServerSelector: {...} | *{}
				}
				verticalPodAutoscaler: {
					enabled: bool | *false
					recommenders: [...{...}] | *[]
					controlledResources: [...string] | *[]
					controlledValues: string | *""
					maxAllowed: {[string]: string} | *{}
					minAllowed: {[string]: string} | *{}
					updatePolicy: {...} | *{}
				}
				selfMonitor: {
					enabled:           bool | *false
					telemetryHost:     string | *""
					telemetryPort:     int | *8081
					telemetryNodePort: int | *0
				}
				startupProbe: {
					enabled: bool | *false
					value: corev1.#Probe | *{failureThreshold: 3, initialDelaySeconds: 0, periodSeconds: 10, successThreshold: 1, timeoutSeconds: 5}
					httpGet: {
						scheme: string | *"HTTP"
						httpHeaders: [...corev1.#HTTPHeader] | *[]
					}
				}
				livenessProbe: {
					value: corev1.#Probe | *{failureThreshold: 3, initialDelaySeconds: 5, periodSeconds: 10, successThreshold: 1, timeoutSeconds: 5}
					httpGet: {
						scheme: string | *"HTTP"
						httpHeaders: [...corev1.#HTTPHeader] | *[]
					}
				}
				readinessProbe: {
					value: corev1.#Probe | *{failureThreshold: 3, initialDelaySeconds: 5, periodSeconds: 10, successThreshold: 1, timeoutSeconds: 5}
					httpGet: {
						scheme: string | *"HTTP"
						httpHeaders: [...corev1.#HTTPHeader] | *[]
					}
				}
				prometheus: monitor: enabled: bool | *false
			}
			"prometheus-node-exporter": {
				enabled:               bool | *true
				nameOverride:          string | *""
				fullnameOverride:      string | *""
				namespaceOverride:     string | *""
				forceDeployDashboards: bool | *false
				operatingSystems: {
					linux: enabled:  bool | *true
					darwin: enabled: bool | *false
				}
				releaseLabel: bool | *false
				commonLabels: {[string]: string} | *{}
				image: {
					registry:   string | *"quay.io"
					repository: string | *"prometheus/node-exporter"
					tag:        string | *""
					pullPolicy: string | *"IfNotPresent"
					digest:     string | *""
				}
				imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
				global: {
					imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
					imageRegistry: string | *""
				}
				revisionHistoryLimit: int | *10
				daemonsetAnnotations: {[string]: string} | *{}
				updateStrategy: appsv1.#DaemonSetUpdateStrategy | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				securityContext: corev1.#PodSecurityContext | *{}
				containerSecurityContext: corev1.#SecurityContext | *{}
				priorityClassName: string | *""
				extraInitContainers: [...corev1.#Container] | *[]
				terminationGracePeriodSeconds: int | *0
				hostNetwork:                   bool | *true
				hostPID:                       bool | *true
				hostIPC:                       bool | *false
				affinity: corev1.#Affinity | *{}
				dnsConfig: corev1.#PodDNSConfig | *{}
				nodeSelector: {[string]: string} | *{}
				restartPolicy: string | *""
				tolerations: [...corev1.#Toleration] | *[]
				resources: corev1.#ResourceRequirements | *{}
				extraArgs: [...string] | *[]
				env: {[string]: string} | *{}
				endpoints: [...string] | *[]
				extraManifests: [...{...}] | *[]
				networkPolicy: enabled: bool | *false
				service: {
					enabled:               bool | *true
					type:                  string | *"ClusterIP"
					clusterIP:             string | *""
					port:                  int | *9100
					servicePort:           int | *0
					targetPort:            int | string | *9100
					portName:              string | *"metrics"
					nodePort:              int | *0
					listenOnAllInterfaces: bool | *true
					annotations: {[string]: string} | *{"prometheus.io/scrape": "true"}
					labels: {[string]: string} | *{}
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
					externalTrafficPolicy: string | *""
				}
				serviceAccount: {
					create: bool | *true
					name:   string | *""
					annotations: {[string]: string} | *{}
					automountServiceAccountToken: bool | *false
					imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
				}
				rbac: {
					create:          bool | *true
					useExistingRole: string | *""
					pspEnabled:      bool | *false
					pspAnnotations: {[string]: string} | *{}
				}
				kubeRBACProxy: {
					enabled: bool | *false
					env: {[string]: string} | *{}
					image: {
						registry:   string | *"quay.io"
						repository: string | *"brancz/kube-rbac-proxy"
						tag:        string | *"v0.18.0"
						sha:        string | *""
						pullPolicy: string | *"IfNotPresent"
					}
					extraArgs: [...string] | *[]
					containerSecurityContext: corev1.#SecurityContext | *{}
					port:                         int | *8100
					portName:                     string | *"http"
					enableHostPort:               bool | *false
					proxyEndpointsPort:           int | *8888
					enableProxyEndpointsHostPort: bool | *false
					resources: corev1.#ResourceRequirements | *{}
				}
				hostRootFsMount: {
					enabled:          bool | *true
					mountPropagation: string | *"HostToContainer"
				}
				hostProcFsMount: mountPropagation: string | *""
				hostSysFsMount: mountPropagation:  string | *""
				extraHostVolumeMounts: [...{name: string, mountPath: string, hostPath: string, readOnly: bool | *true, mountPropagation?: string, type: string | *""}] | *[]
				sidecarVolumeMount: [...{name: string, mountPath: string, readOnly: bool | *true}] | *[]
				sidecarHostVolumeMounts: [...{name: string, mountPath: string, hostPath: string, readOnly: bool | *true, mountPropagation?: string}] | *[]
				configmaps: [...{name: string, mountPath: string}] | *[]
				secrets: [...{name: string, mountPath: string}] | *[]
				sidecars: [...corev1.#Container] | *[]
				livenessProbe: {
					value: corev1.#Probe | *{failureThreshold: 3, initialDelaySeconds: 0, periodSeconds: 10, successThreshold: 1, timeoutSeconds: 1}
					httpGet: {scheme: string | *"HTTP", httpHeaders: [...corev1.#HTTPHeader] | *[]}
				}
				readinessProbe: {
					value: corev1.#Probe | *{failureThreshold: 3, initialDelaySeconds: 0, periodSeconds: 10, successThreshold: 1, timeoutSeconds: 1}
					httpGet: {scheme: string | *"HTTP", httpHeaders: [...corev1.#HTTPHeader] | *[]}
				}
				prometheus: {
					monitor: {
						enabled: bool | *false
						additionalLabels: {[string]: string} | *{}
						namespace: string | *""
						jobLabel:  string | *""
						podTargetLabels: [...string] | *[]
						scheme: string | *"http"
						basicAuth: {...} | *{}
						bearerTokenFile: string | *""
						tlsConfig: {...} | *{}
						proxyUrl: string | *""
						selectorOverride: {[string]: string} | *{}
						attachMetadata: {...} | *{node: false}
						relabelings: [...{...}] | *[]
						metricRelabelings: [...{...}] | *[]
						interval:      string | *""
						scrapeTimeout: string | *"10s"
						apiVersion:    string | *""
					}
					podMonitor: {
						enabled:   bool | *false
						namespace: string | *""
						additionalLabels: {[string]: string} | *{}
						podTargetLabels: [...string] | *[]
						apiVersion: string | *""
						selectorOverride: {[string]: string} | *{}
						attachMetadata: {...} | *{node: false}
						jobLabel: string | *""
						scheme:   string | *"http"
						path:     string | *"/metrics"
						basicAuth: {...} | *{}
						bearerTokenSecret: {...} | *{}
						tlsConfig: {...} | *{}
						authorization: {...} | *{}
						oauth2: {...} | *{}
						proxyUrl:        string | *""
						interval:        string | *""
						scrapeTimeout:   string | *""
						honorTimestamps: bool | *true
						honorLabels:     bool | *true
						enableHttp2:     bool | *false
						filterRunning:   bool | *true
						followRedirects: bool | *false
						relabelings: [...{...}] | *[]
						metricRelabelings: [...{...}] | *[]
					}
				}
				verticalPodAutoscaler: {
					enabled: bool | *false
					recommenders: [...{...}] | *[]
					controlledResources: [...string] | *[]
					controlledValues: string | *""
					maxAllowed: {[string]: string} | *{}
					minAllowed: {[string]: string} | *{}
					updatePolicy: {...} | *{}
				}
			}
			grafana: {
				enabled:         bool | *true
				createConfigmap: bool | *true
				tolerations: [...corev1.#Toleration] | *[]
				replicas:             int | *1
				revisionHistoryLimit: int | *10
				deploymentStrategy: {[string]: _} | *{type: "RollingUpdate"}
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				useStatefulSet:               bool | *false
				headlessService:              bool | *false
				automountServiceAccountToken: bool | *true
				adminUser:                    string | *"admin"
				adminPassword:                string | *"prom-operator"
				admin: existingSecret: string | *""
				plugins: [...string] | *[]
				image: {
					registry:   string | *"docker.io"
					repository: string | *"grafana/grafana"
					tag:        string | *"11.2.0"
					pullPolicy: string | *"IfNotPresent"
				}
				forceDeployDashboards:      bool | *false
				forceDeployDatasources:     bool | *false
				defaultDashboardsEnabled:   bool | *true
				defaultDashboardsEditable:  bool | *false
				defaultDashboardsTimezone:  string | *"browser"
				namespaceOverride:          string | *""
				dashboardNamespaceOverride: string | *""
				deleteDatasources: [...{...}] | *[]
				prune: bool | *false
				additionalDataSources: [...{...}] | *[]
				env: {[string]: string} | *{}
				envValueFrom: {[string]: _} | *{}
				envFromSecret: string | *""
				envFromSecrets: [...] | *[]
				envFromConfigMaps: [...] | *[]
				resources: corev1.#ResourceRequirements | *{}
				readinessProbe: {[string]: _} | *{
					httpGet: {
						path: "/api/health"
						port: 3000
					}
				}
				livenessProbe: {[string]: _} | *{
					httpGet: {
						path: "/api/health"
						port: 3000
					}
				}
				lifecycleHooks: {[string]: _} | *{}
				extraContainers: string | *""
				topologySpreadConstraints: [...] | *[]
				nodeSelector: {[string]: string} | *{}
				affinity: corev1.#Affinity | *{}
				extraConfigmapMounts: [...] | *[]
				extraSecretMounts: [...] | *[]
				extraVolumeMounts: [...] | *[]
				extraVolumes: [...] | *[]
				extraEmptyDirMounts: [...] | *[]
				rbac: {
					create:         bool | *true
					namespaced:     bool | *false
					pspEnabled:     bool | *false
					pspUseAppArmor: bool | *false
					extraClusterRoleRules: [...] | *[]
					extraRoleRules: [...] | *[]
				}
				autoscaling: {
					enabled:      bool | *false
					minReplicas:  int | *1
					maxReplicas:  int | *10
					targetCPU:    string | *""
					targetMemory: string | *""
				}
				admin: {
					existingSecret: string | *""
					userKey:        string | *"admin-user"
					passwordKey:    string | *"admin-password"
				}
				service: {
					enabled:    bool | *true
					type:       string | *"ClusterIP"
					port:       int | *80
					targetPort: int | *3000
				}
				serviceMonitor: {
					enabled:   bool | *false
					interval:  string | *"30s"
					path:      string | *"/metrics"
					scheme:    string | *"http"
					namespace: string | *""
				}
				networkPolicy: {
					enabled: bool | *false
				}
				serviceAccount: {
					create:                       bool | *true
					name:                         string | *""
					automountServiceAccountToken: bool | *false
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
				persistence: {
					enabled: bool | *false
					type:    string | *"pvc"
					size:    string | *"10Gi"
					accessModes: [...string] | *["ReadWriteOnce"]
					storageClassName: string | *""
				}
				sidecar: {
					dashboards: {
						enabled:    bool | *false
						SCProvider: bool | *false
						label:      string | *"grafana_dashboard"
						additionalDashboardLabels: {[string]: string} | *{}
						labelValue:  string | *""
						folder:      string | *"/tmp/dashboards"
						watchMethod: string | *"WATCH"
						resource:    string | *"configmap"
						annotations: {[string]: string} | *{}
						multicluster: {
							global: enabled: bool | *false
							etcd: enabled:   bool | *false
						}
					}
					datasources: {
						enabled:     bool | *false
						label:       string | *"grafana_datasource"
						labelValue:  string | *""
						watchMethod: string | *"WATCH"
						resource:    string | *"configmap"
						annotations: {[string]: string} | *{}
						defaultDatasourceScrapeInterval: string | *""
						defaultDatasourceEnabled:        bool | *true
						name:                            string | *"Prometheus"
						uid:                             string | *"default"
						url:                             string | *""
						isDefaultDatasource:             bool | *true
						httpMethod:                      string | *"POST"
						timeout:                         int | *0
						exemplarTraceIdDestinations: {
							datasourceUid:    string | *""
							traceIdLabelName: string | *""
						}
						createPrometheusReplicasDatasources: bool | *false
						alertmanager: {
							enabled:                    bool | *true
							name:                       string | *"Alertmanager"
							uid:                        string | *"alertmanager"
							url:                        string | *""
							handleGrafanaManagedAlerts: bool | *false
							implementation:             string | *"prometheus"
						}
					}
				}
				imageRenderer: {
					enabled: bool | *false
					image: {
						registry:   string | *""
						repository: string | *"grafana/grafana-image-renderer"
						tag:        string | *"latest"
						pullPolicy: string | *"Always"
					}
					service: {
						enabled:    bool | *true
						port:       int | *8081
						targetPort: int | *8081
						portName:   string | *"http"
						labels: {[string]: string} | *{}
						annotations: {[string]: string} | *{}
						clusterIP: string | *""
					}
					serviceMonitor: {
						enabled:       bool | *false
						interval:      string | *""
						scrapeTimeout: string | *""
						path:          string | *"/metrics"
						scheme:        string | *"http"
						namespace:     string | *""
						labels: {[string]: string} | *{}
						relabelings: [...] | *[]
						tlsConfig: {[string]: _} | *{}
						targetLabels: [...] | *[]
					}
					autoscaling: {
						enabled:      bool | *false
						minReplicas:  int | *1
						maxReplicas:  int | *5
						targetCPU:    int | *0
						targetMemory: int | *0
						behavior: {[string]: _} | *{}
					}
					networkPolicy: {
						limitIngress: bool | *false
						limitEgress:  bool | *false
						extraIngressSelectors: [...] | *[]
					}
					resources: corev1.#ResourceRequirements | *{}
					nodeSelector: {[string]: string} | *{}
					affinity: corev1.#Affinity | *{}
					tolerations: [...corev1.#Toleration] | *[]
					podLabels: {[string]: string} | *{}
					podAnnotations: {[string]: string} | *{}
					env: {[string]: string} | *{}
					extraVolumeMounts: [...] | *[]
					extraConfigmapMounts: [...] | *[]
					extraSecretMounts: [...] | *[]
					extraVolumes: [...] | *[]
					securityContext: {[string]: _} | *{}
					containerSecurityContext: {[string]: _} | *{}
					priorityClassName:  string | *""
					serviceAccountName: string | *""
					hostAliases: [...] | *[]
				}
				ingress: {
					enabled:          bool | *true
					ingressClassName: string | *"alb"
					annotations: {[string]: string} | *{
						"alb.ingress.kubernetes.io/backend-protocol":         "HTTP"
						"alb.ingress.kubernetes.io/backend-protocol-version": "HTTP1"
						"alb.ingress.kubernetes.io/group.name":               "hyperswitch-monitoring-alb-ingress-group"
						"alb.ingress.kubernetes.io/ip-address-type":          "ipv4"
						"alb.ingress.kubernetes.io/listen-ports":             "[{\"HTTP\": 80}]"
						"alb.ingress.kubernetes.io/load-balancer-name":       "hyperswitch-monitoring"
						"alb.ingress.kubernetes.io/scheme":                   "internet-facing"
						"alb.ingress.kubernetes.io/security-groups":          "loadbalancer-sg"
						"alb.ingress.kubernetes.io/tags":                     "stack=hyperswitch-monitoring"
						"alb.ingress.kubernetes.io/target-type":              "ip"
					}
					hosts: [...{
						host: string | *""
						paths: [...{
							path:     string | *"/"
							pathType: string | *"Prefix"
						}] | *[{
							path:     "/"
							pathType: "Prefix"
						}]
					}] | *[{
						host: ""
						paths: [{
							path:     "/"
							pathType: "Prefix"
						}]
					}]
					tls: [...{
						hosts: [...string]
						secretName: string
					}] | *[]
					labels: {[string]: string} | *{}
					path:     string | *"/"
					pathType: string | *"Prefix"
					extraPaths: [...] | *[]
				}
				dashboardProviders: {[string]: _} | *{}
				dashboards: {[string]: {[string]: {json?: string, file?: string}}} | *{}
				alerting: {[string]: string | {secret?: string, secretFile?: string}} | *{}
				datasources: {[string]: {secret?: string}} | *{}
				notifiers: {[string]: {secret?: string}} | *{}
				envRenderSecret: {[string]: string} | *{}
				extraObjects: [...] | *[]
				gossipPortName: string | *"gossip"
				ldap: {
					enabled:        bool | *false
					existingSecret: string | *""
				}

			}
			alertmanager: {
				enabled: bool | *true
				annotations: {[string]: string} | *{}
				apiVersion: string | *"v2"
				enableFeatures: [...string] | *[]
				serviceAccount: {
					create: bool | *true
					name:   string | *""
					annotations: {[string]: string} | *{}
					automountServiceAccountToken: bool | *true
				}
				podDisruptionBudget: {
					enabled:        bool | *false
					minAvailable:   int | *1
					maxUnavailable: string | *""
				}
				config: {...} | *{
					global: resolve_timeout: "5m"
					inhibit_rules: [
						{source_matchers: ["severity = critical"], target_matchers: ["severity =~ warning|info"], equal: ["namespace", "alertname"]},
						{source_matchers: ["severity = warning"], target_matchers: ["severity = info"], equal: ["namespace", "alertname"]},
						{source_matchers: ["alertname = InfoInhibitor"], target_matchers: ["severity = info"], equal: ["namespace"]},
						{target_matchers: ["alertname = InfoInhibitor"]},
					]
					route: {
						group_by: ["namespace"]
						group_wait:      "30s"
						group_interval:  "5m"
						repeat_interval: "12h"
						receiver:        "null"
						routes: [{receiver: "null", matchers: ["alertname = \"Watchdog\""]}]
					}
					receivers: [{name: "null"}]
					templates: ["/etc/alertmanager/config/*.tmpl"]
				}
				stringConfig: string | *""
				templateFiles: {[string]: string} | *{}
				secret: {
					annotations: {[string]: string} | *{}
				}
				extraSecret: {
					name: string | *""
					annotations: {[string]: string} | *{}
					data: {[string]: string} | *{}
				}
				ingress: {
					enabled: bool | *false
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					ingressClassName: string | *""
					hosts: [...string] | *[]
					paths: [...string] | *[]
					pathType:    string | *"ImplementationSpecific"
					serviceName: string | *""
					servicePort: int | *0
					tls: [...{
						hosts: [...string]
						secretName: string
					}] | *[]
				}
				ingressPerReplica: {
					enabled: bool | *false
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					hostPrefix: string | *""
					hostDomain: string | *""
					paths: [...string] | *[]
					pathType:      string | *""
					tlsSecretName: string | *""
					tlsSecretPerReplica: {
						enabled: bool | *false
						prefix:  string | *"alertmanager"
					}
				}
				service: {
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					clusterIP: string | *""
					externalIPs: [...string] | *[]
					loadBalancerIP: string | *""
					loadBalancerSourceRanges: [...string] | *[]
					externalTrafficPolicy: string | *"Cluster"
					port:                  int | *9093
					targetPort:            int | *9093
					nodePort:              int | *30903
					additionalPorts: [...corev1.#ServicePort] | *[]
					sessionAffinity: string | *"None"
					sessionAffinityConfig: corev1.#SessionAffinityConfig | *{}
					type: string | *"ClusterIP"
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				servicePerReplica: {
					enabled: bool | *false
					annotations: {[string]: string} | *{}
					port:       int | *9093
					targetPort: int | *9093
					nodePort:   int | *30904
					loadBalancerSourceRanges: [...string] | *[]
					externalTrafficPolicy: string | *"Cluster"
					type:                  string | *"ClusterIP"
				}
				serviceMonitor: {
					selfMonitor: bool | *true
					interval:    string | *""
					additionalLabels: {[string]: string} | *{}
					proxyUrl:    string | *""
					scheme:      string | *""
					enableHttp2: bool | *true
					tlsConfig: {[string]: _} | *{}
					bearerTokenFile: string | *""
					metricRelabelings: [...{[string]: _}] | *[]
					relabelings: [...{[string]: _}] | *[]
					additionalEndpoints: [...{[string]: _}] | *[]
				}
				alertmanagerSpec: {
					podMetadata: {[string]: _} | *{}
					image: {
						registry:   string | *"quay.io"
						repository: string | *"prometheus/alertmanager"
						tag:        string | *"v0.27.0"
						sha:        string | *""
						pullPolicy: string | *"IfNotPresent"
					}
					version:           string | *""
					useExistingSecret: bool | *false
					secrets: [...string] | *[]
					automountServiceAccountToken: bool | *true
					configMaps: [...string] | *[]
					configSecret: string | *""
					web: {[string]: _} | *{}
					alertmanagerConfigSelector: {[string]: _} | *{}
					alertmanagerConfigNamespaceSelector: {[string]: _} | *{}
					alertmanagerConfiguration: {[string]: _} | *{}
					alertmanagerConfigMatcherStrategy: {[string]: _} | *{}
					logFormat: string | *"logfmt"
					logLevel:  string | *"info"
					replicas:  int | *1
					retention: string | *"120h"
					storage: {[string]: _} | *{}
					externalUrl: string | *""
					routePrefix: string | *"/"
					scheme:      string | *""
					tlsConfig: {[string]: _} | *{}
					paused: bool | *false
					nodeSelector: {[string]: string} | *{}
					resources: corev1.#ResourceRequirements | *{}
					securityContext: corev1.#PodSecurityContext | *{}
					affinity: corev1.#Affinity | *{}
					podAntiAffinity:            string | *""
					podAntiAffinityTopologyKey: string | *"kubernetes.io/hostname"
					tolerations: [...corev1.#Toleration] | *[]
					topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
					containers: [...corev1.#Container] | *[]
					initContainers: [...corev1.#Container] | *[]
					priorityClassName: string | *""
					additionalPeers: [...string] | *[]
					volumes: [...corev1.#Volume] | *[]
					volumeMounts: [...corev1.#VolumeMount] | *[]
					portName:                string | *"web"
					clusterAdvertiseAddress: string | *""
					clusterGossipInterval:   string | *""
					clusterPeerTimeout:      string | *""
					clusterPushpullInterval: string | *""
					clusterLabel:            string | *""
					forceEnableClusterMode:  bool | *false
					minReadySeconds:         int | *0
					additionalConfig: {[string]: _} | *{}
					listenLocal: bool | *false
				}
			}
			prometheusOperator: {
				enabled:              bool | *true
				fullnameOverride:     string | *""
				revisionHistoryLimit: int | *10
				strategy: {...} | *{}
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				priorityClassName: string | *""
				image: {
					registry:   string | *"quay.io"
					repository: string | *"prometheus-operator/prometheus-operator"
					tag:        string | *"v0.77.1"
					sha:        string | *""
					pullPolicy: string | *"IfNotPresent"
				}
				prometheusConfigReloader: {
					image: {
						registry:   string | *"quay.io"
						repository: string | *"prometheus-operator/prometheus-config-reloader"
						tag:        string | *"v0.77.0"
						sha:        string | *""
						pullPolicy: string | *"IfNotPresent"
					}
					resources: corev1.#ResourceRequirements | *{}
					enableProbe: bool | *false
				}
				thanosImage: {
					registry:   string | *"quay.io"
					repository: string | *"thanos/thanos"
					tag:        string | *"v0.36.1"
					sha:        string | *""
					pullPolicy: string | *"IfNotPresent"
				}
				kubeletService: {
					enabled:   bool | *true
					namespace: string | *"kube-system"
					selector:  string | *""
					name:      string | *""
				}
				logFormat: string | *"logfmt"
				logLevel:  string | *"info"
				denyNamespaces: [...string] | *[]
				namespaces: {
					releaseNamespace: bool | *false
					additional: [...string] | *[]
				}
				prometheusDefaultBaseImage:           string | *""
				prometheusDefaultBaseImageRegistry:   string | *""
				alertmanagerDefaultBaseImage:         string | *""
				alertmanagerDefaultBaseImageRegistry: string | *""
				alertmanagerInstanceNamespaces: [...string] | *[]
				alertmanagerInstanceSelector: string | *""
				alertmanagerConfigNamespaces: [...string] | *[]
				prometheusInstanceNamespaces: [...string] | *[]
				prometheusInstanceSelector: string | *""
				thanosRulerInstanceNamespaces: [...string] | *[]
				thanosRulerInstanceSelector: string | *""
				secretFieldSelector:         string | *""
				clusterDomain:               string | *""
				tls: {
					enabled:       bool | *true
					internalPort:  int | *10250
					tlsMinVersion: string | *"VersionTLS13"
				}
				env: {[string]: string} | *{}
				resources: corev1.#ResourceRequirements | *{}
				containerSecurityContext: corev1.#SecurityContext | *{}
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				readinessProbe: {
					enabled:             bool | *true
					initialDelaySeconds: int | *0
					periodSeconds:       int | *10
					timeoutSeconds:      int | *1
					successThreshold:    int | *1
					failureThreshold:    int | *3
				}
				livenessProbe: {
					enabled:             bool | *true
					initialDelaySeconds: int | *0
					periodSeconds:       int | *10
					timeoutSeconds:      int | *1
					successThreshold:    int | *1
					failureThreshold:    int | *3
				}
				extraVolumes: [...corev1.#Volume] | *[]
				dnsConfig: corev1.#PodDNSConfig | *{}
				securityContext: corev1.#PodSecurityContext | *{}
				serviceAccount: {
					create: bool | *true
					name:   string | *""
					annotations: {[string]: string} | *{}
					automountServiceAccountToken: bool | *true
				}
				automountServiceAccountToken: bool | *true
				hostNetwork:                  bool | *false
				nodeSelector: {[string]: string} | *{}
				affinity: corev1.#Affinity | *{}
				tolerations: [...corev1.#Toleration] | *[]
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
					clusterIP: string | *""
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
					externalIPs: [...string] | *[]
					loadBalancerIP: string | *""
					loadBalancerSourceRanges: [...string] | *[]
					externalTrafficPolicy: string | *"Cluster"
					type:                  string | *"ClusterIP"
					nodePort:              int | *30080
					nodePortTls:           int | *30443
				}
				serviceMonitor: {
					selfMonitor: bool | *true
					additionalLabels: {[string]: string} | *{}
					interval: string | *""
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
				}
				admissionWebhooks: {
					enabled:        bool | *true
					failurePolicy:  string | *"Fail"
					timeoutSeconds: int | *10
					caBundle:       string | *""
					annotations: {[string]: string} | *{}
					namespaceSelector: {...} | *{}
					objectSelector: {...} | *{}
					mutatingWebhookConfiguration: annotations: {[string]: string} | *{}
					validatingWebhookConfiguration: annotations: {[string]: string} | *{}
					deployment: {
						enabled:  bool | *false
						replicas: int | *1
						strategy: {...} | *{}
						podDisruptionBudget: {...} | *{}
						revisionHistoryLimit: int | *10
					}
					patch: {
						enabled: bool | *true
						image: {
							registry:   string | *"registry.k8s.io"
							repository: string | *"ingress-nginx/kube-webhook-certgen"
							tag:        string | *"v20221220-controller-v1.5.1-58-g787ea74b6"
							sha:        string | *""
							pullPolicy: string | *"IfNotPresent"
						}
						resources: corev1.#ResourceRequirements | *{}
						priorityClassName:       string | *""
						ttlSecondsAfterFinished: int | *60
						annotations: {[string]: string} | *{}
						podAnnotations: {[string]: string} | *{}
						nodeSelector: {[string]: string} | *{}
						affinity: corev1.#Affinity | *{}
						tolerations: [...corev1.#Toleration] | *[]
						securityContext: corev1.#PodSecurityContext | *{}
						serviceAccount: {
							create: bool | *true
							annotations: {[string]: string} | *{}
							automountServiceAccountToken: bool | *true
						}
					}
					certManager: {
						enabled: bool | *false
						rootCert: duration:      string | *""
						admissionCert: duration: string | *""
						issuerRef: {...} | *{}
					}
				}
				verticalPodAutoscaler: {
					enabled: bool | *false
					recommenders: [...{...}] | *[]
					controlledResources: [...string] | *[]
					controlledValues: string | *""
					maxAllowed: {[string]: string} | *{}
					minAllowed: {[string]: string} | *{}
					updatePolicy: {...} | *{}
				}
				networkPolicy: {
					enabled: bool | *false
					flavor:  string | *"kubernetes"
					matchLabels: {[string]: string} | *{}
					cilium: egress: [...{...}] | *[]
				}
			}
			thanosRuler: {
				enabled: bool | *false
				name:    string | *""
				annotations: {[string]: string} | *{}
				extraSecret: {
					name: string | *""
					annotations: {[string]: string} | *{}
					data: {[string]: string} | *{}
				}
				ingress: {
					enabled: bool | *false
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					hosts: [...string] | *[]
					paths: [...string] | *[]
					pathType:         string | *"ImplementationSpecific"
					ingressClassName: string | *""
					tls: [...{
						hosts: [...string]
						secretName: string
					}] | *[]
				}
				podDisruptionBudget: {
					enabled:        bool | *false
					minAvailable:   int | *null
					maxUnavailable: int | *null
				}
				service: {
					type:       string | *"ClusterIP"
					port:       int | *9091
					targetPort: int | *9091
					nodePort:   int | *0
					clusterIP:  string | *""
					externalIPs: [...string] | *[]
					loadBalancerIP: string | *""
					loadBalancerSourceRanges: [...string] | *[]
					externalTrafficPolicy: string | *"Cluster"
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					additionalPorts: [...corev1.#ServicePort] | *[]
					ipDualStack: {
						enabled: bool | *false
						ipFamilies: [...string] | *["IPv6", "IPv4"]
						ipFamilyPolicy: string | *"PreferDualStack"
					}
				}
				serviceAccount: {
					create: bool | *true
					name:   string | *""
					annotations: {[string]: string} | *{}
				}
				serviceMonitor: {
					selfMonitor:     bool | *false
					interval:        string | *""
					proxyUrl:        string | *""
					scheme:          string | *""
					bearerTokenFile: string | *""
					tlsConfig: {...} | *null
					metricRelabelings: [...{...}] | *[]
					relabelings: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
					additionalEndpoints: [...{
						port:            string
						interval:        string | *""
						proxyUrl:        string | *""
						scheme:          string | *""
						bearerTokenFile: string | *""
						tlsConfig: {...} | *null
						path: string
						metricRelabelings: [...{...}] | *[]
						relabelings: [...{...}] | *[]
					}] | *[]
				}
				thanosRulerSpec: {
					image: {
						registry:   string | *"quay.io"
						repository: string | *"thanos/thanos"
						tag:        string | *""
						sha:        string | *""
						pullPolicy: string | *"IfNotPresent"
					}
					replicas:                        int | *1
					listenLocal:                     bool | *false
					externalPrefix:                  string | *""
					externalPrefixNilUsesHelmValues: bool | *true
					additionalArgs: [...string] | *[]
					nodeSelector: {[string]: string} | *{}
					paused:             bool | *false
					logFormat:          string | *"logfmt"
					logLevel:           string | *"info"
					retention:          string | *"24h"
					evaluationInterval: string | *""
					ruleNamespaceSelector: {...} | *null
					ruleSelector: {...} | *null
					ruleSelectorNilUsesHelmValues: bool | *true
					alertQueryUrl:                 string | *""
					alertmanagersUrl: [...string] | *[]
					alertmanagersConfig: {
						secret: string | *null
						existingSecret: {
							key:  string | *""
							name: string | *""
						}
					}
					queryEndpoints: [...string] | *[]
					queryConfig: {
						secret: string | *null
						existingSecret: {
							key:  string | *""
							name: string | *""
						}
					}
					resources: corev1.#ResourceRequirements | *{}
					routePrefix: string | *"/"
					securityContext: corev1.#PodSecurityContext | *{}
					storage: {...} | *null
					objectStorageConfig: {
						secret: string | *null
						existingSecret: {
							key:  string | *""
							name: string | *""
						}
					}
					labels: {[string]: string} | *{}
					podMetadata: {...} | *null
					affinity: corev1.#Affinity | *{}
					podAntiAffinity:            string | *""
					podAntiAffinityTopologyKey: string | *"kubernetes.io/hostname"
					tolerations: [...corev1.#Toleration] | *[]
					topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
					containers: [...corev1.#Container] | *[]
					initContainers: [...corev1.#Container] | *[]
					priorityClassName: string | *""
					volumes: [...corev1.#Volume] | *[]
					volumeMounts: [...corev1.#VolumeMount] | *[]
					alertDropLabels: [...string] | *[]
					portName: string | *"web"
					web: {...} | *null
				}
			}
		}
		loki: {
			enabled: bool | *true
			imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
			deploymentMode: "SingleBinary" | "SimpleScalable" | "Distributed" | "SingleBinary<->SimpleScalable" | "SimpleScalable<->Distributed" | *"SingleBinary"
			image: {
				repository: string | *"grafana/loki"
				tag:        string | *"3.1.1"
				pullPolicy: string | *"IfNotPresent"
			}
			nameOverride:     string | *""
			fullnameOverride: string | *""
			serviceAccount: {
				create: bool | *true
				name:   string | *""
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				automountServiceAccountToken: bool | *true
				imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
			}
			rbac: {
				pspEnabled: bool | *false
				pspAnnotations: {[string]: string} | *{}
				sccEnabled: bool | *false
				namespaced: bool | *true
			}
			enterprise: {
				enabled:             bool | *false
				useExternalLicense:  bool | *false
				externalLicenseName: string | *"enterprise-logs-license"
				gelGateway:          bool | *false
				license: contents: string | *""
				image: {
					repository: string | *"grafana/enterprise-logs"
					tag:        string | *""
					pullPolicy: string | *"IfNotPresent"
				}
				version: string | *"v1.7.0"
				provisioner: {
					enabled: bool | *false
					image: {
						repository: string | *"grafana/enterprise-logs-provisioner"
						tag:        string | *""
						pullPolicy: string | *"IfNotPresent"
					}
					priorityClassName: string | *null
					securityContext: corev1.#PodSecurityContext | *{
						fsGroup:      10001
						runAsGroup:   10001
						runAsNonRoot: true
						runAsUser:    10001
					}
					extraVolumeMounts: [...corev1.#VolumeMount] | *[]
					env: [...corev1.#EnvVar] | *[]
					affinity: corev1.#Affinity | *{}
					nodeSelector: {[string]: string} | *{}
					tolerations: [...corev1.#Toleration] | *[]
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
				tokengen: {
					enabled:           bool | *false
					targetModule:      string | *"tokengen"
					priorityClassName: string | *null
					securityContext: corev1.#PodSecurityContext | *{}
					extraArgs: [...string] | *[]
					extraVolumeMounts: [...corev1.#VolumeMount] | *[]
					extraVolumes: [...corev1.#Volume] | *[]
					env: [...corev1.#EnvVar] | *[]
					extraEnvFrom: [...corev1.#EnvFromSource] | *[]
					affinity: corev1.#Affinity | *{}
					nodeSelector: {[string]: string} | *{}
					tolerations: [...corev1.#Toleration] | *[]
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
				adminToken: {
					additionalNamespaces: [...string] | *[]
				}
				additionalTenants: [...{
					name:            string
					secretNamespace: string
				}] | *[]
			}
			kubectlImage: {
				repository: string | *"bitnami/kubectl"
				tag:        string | *"1.28.2"
				pullPolicy: string | *"IfNotPresent"
			}
			loki: {
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				revisionHistoryLimit:      int | *10
				configStorageType:         "ConfigMap" | "Secret" | *"ConfigMap"
				generatedConfigObjectName: string | *"loki-config"
				config:                    string | *""
				structuredConfig: {...} | *{}
				runtimeConfig: {...} | *{}
				schemaConfig: {...} | *{}
				useTestSchema: bool | *false
				auth_enabled:  bool | *false
				podSecurityContext: corev1.#PodSecurityContext | *{
					fsGroup:      10001
					runAsGroup:   10001
					runAsNonRoot: true
					runAsUser:    10001
				}
				containerSecurityContext: corev1.#SecurityContext | *{
					readOnlyRootFilesystem:   true
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
				}
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				serviceAnnotations: {[string]: string} | *{}
				serviceLabels: {[string]: string} | *{}
				readinessProbe: corev1.#Probe | *{
					httpGet: {
						path: "/ready"
						port: "http-metrics"
					}
					initialDelaySeconds: 45
				}
				livenessProbe: corev1.#Probe | *{
					httpGet: {
						path: "/ready"
						port: "http-metrics"
					}
					initialDelaySeconds: 45
				}
				storage: {
					type: "s3" | "gcs" | "azure" | "swift" | "alibabacloud" | "filesystem" | *"filesystem"
					bucketNames: {
						chunks: string | *"chunks"
						ruler:  string | *"ruler"
						admin:  string | *"admin"
					}
					s3: {
						endpoint:         string | *""
						region:           string | *""
						secretAccessKey:  string | *""
						accessKeyId:      string | *""
						s3ForcePathStyle: bool | *false
						insecure:         bool | *false
					}
					filesystem: {
						chunks_directory:    string | *"/var/loki/chunks"
						rules_directory:     string | *"/var/loki/rules"
						admin_api_directory: string | *"/var/loki/admin"
					}
				}
			}
			sidecar: rules: enabled: bool | *false
			ingress: {
				enabled:          bool | *false
				ingressClassName: string | *""
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				hosts: [...string] | *[]
				tls: [...{
					hosts: [...string]
					secretName?: string
				}] | *[]
			}
			networkPolicy: {
				enabled: bool | *false
				flavor:  "kubernetes" | "cilium" | *"kubernetes"
				ingress: {
					namespaceSelector: {[string]: string} | *{}
					podSelector: {[string]: string} | *{}
				}
				metrics: {
					cidrs: [...string] | *[]
					namespaceSelector: {[string]: string} | *{}
					podSelector: {[string]: string} | *{}
				}
				alertmanager: {
					port: int | *9093
					namespaceSelector: {[string]: string} | *{}
					podSelector: {[string]: string} | *{}
				}
				externalStorage: {
					ports: [...int] | *[]
					cidrs: [...string] | *[]
				}
				discovery: {
					port: int | *0
					namespaceSelector: {[string]: string} | *{}
					podSelector: {[string]: string} | *{}
				}
			}
			test: {
				enabled:              bool | *false
				canaryServiceAddress: string | *"http://loki-canary:3500/metrics"
				prometheusAddress:    string | *""
				timeout:              string | *"1m"
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
			}
			lokiCanary: {
				enabled: bool | *true
				image: {
					registry:   string | *null
					repository: string | *"grafana/loki-canary"
					tag:        string | *"3.1.1"
					pullPolicy: string | *"IfNotPresent"
				}
				labelname:         string | *"loki_canary_push_label"
				push:              bool | *false
				priorityClassName: string | *""
				updateStrategy: {...} | *{}
				annotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				resources: corev1.#ResourceRequirements | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				dnsConfig: {...} | *null
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
			}
			memberlist: service: {
				annotations: {[string]: string} | *{}
				publishNotReadyAddresses: bool | *false
			}
			gateway: {
				enabled:        bool | *true
				replicas:       int | *1
				containerPort:  int | *8080
				verboseLogging: bool | *true
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *3
					targetCPUUtilizationPercentage:    int | *60
					targetMemoryUtilizationPercentage: int | *null
				}
				deploymentStrategy: appsv1.#DeploymentStrategy | *{
					type: "RollingUpdate"
				}
				image: {
					registry:   string | *"docker.io"
					repository: string | *"nginxinc/nginx-unprivileged"
					tag:        string | *"1.27-alpine"
					pullPolicy: string | *"IfNotPresent"
				}
				priorityClassName: string | *""
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				lifecycle: {...} | *{}
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				podSecurityContext: corev1.#PodSecurityContext | *{
					fsGroup:      101
					runAsGroup:   101
					runAsNonRoot: true
					runAsUser:    101
				}
				containerSecurityContext: corev1.#SecurityContext | *{
					readOnlyRootFilesystem:   true
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
				}
				resources: corev1.#ResourceRequirements | *{}
				extraContainers: [...corev1.#Container] | *[]
				terminationGracePeriodSeconds: int | *30
				affinity: corev1.#Affinity | *{}
				dnsConfig: {...} | *{}
				nodeSelector: {[string]: string} | *{}
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				tolerations: [...corev1.#Toleration] | *[]
				service: {
					port:           int | *80
					type:           string | *"ClusterIP"
					clusterIP:      string | *null
					nodePort:       int | *null
					loadBalancerIP: string | *null
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
				}
				ingress: {
					enabled:          bool | *false
					ingressClassName: string | *""
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					hosts: [...{
						host: string
						paths: [...{
							path:     string
							pathType: string | *"ImplementationSpecific"
						}]
					}] | *[]
					tls: [...{
						secretName: string
						hosts: [...string]
					}] | *[]
				}
				basicAuth: {
					enabled:        bool | *false
					username:       string | *null
					password:       string | *null
					htpasswd:       string | *null
					existingSecret: string | *null
				}
				readinessProbe: corev1.#Probe | *{
					httpGet: {
						path: "/"
						port: "http-metrics"
					}
					initialDelaySeconds: 15
					timeoutSeconds:      1
				}
				nginxConfig: {
					schema:           string | *"http"
					enableIPv6:       bool | *true
					logFormat:        string | *""
					serverSnippet:    string | *""
					httpSnippet:      string | *""
					ssl:              bool | *false
					customReadUrl:    string | *null
					customWriteUrl:   string | *null
					customBackendUrl: string | *null
					resolver:         string | *""
					file:             string | *"""
						worker_processes  5;
						error_log  /dev/stderr;
						pid        /tmp/nginx.pid;
						worker_rlimit_nofile 8192;

						  events {
						    worker_connections  4096;
						  }

						  http {
						    client_body_temp_path /tmp/client_temp;
						    proxy_temp_path       /tmp/proxy_temp_path;
						    fastcgi_temp_path     /tmp/fastcgi_temp;
						    uwsgi_temp_path       /tmp/uwsgi_temp;
						    scgi_temp_path        /tmp/scgi_temp;

						    client_max_body_size 100M;
						    proxy_http_version 1.1;

						    upstream loki-backend {
						      server \(metadata.name)-loki:3100;
						    }

						    server {
						      listen          \(containerPort);
						      server_name     localhost;

						      location = /loki/api/v1/push {
						        proxy_pass      http://loki-backend;
						      }

						      location = /loki/api/v1/tail {
						        proxy_pass      http://loki-backend;
						        proxy_set_header Upgrade $http_upgrade;
						        proxy_set_header Connection "upgrade";
						      }

						      location ~ /loki/api/.* {
						        proxy_pass      http://loki-backend;
						      }

						      location ~ /admin/api/.* {
						        proxy_pass      http://\(metadata.name)-loki:3100;
						      }

						      location = / {
						        return 200 'OK';
						        add_header Content-Type text/plain;
						      }

						      location = /ready {
						        return 200 'OK';
						        add_header Content-Type text/plain;
						      }
						    }
						  }
						"""
				}
			}
			adminApi: {
				replicas: int | *1
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				priorityClassName: string | *""
				podSecurityContext: corev1.#PodSecurityContext | *{
					fsGroup:      10001
					runAsGroup:   10001
					runAsNonRoot: true
					runAsUser:    10001
				}
				containerSecurityContext: corev1.#SecurityContext | *{
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
					readOnlyRootFilesystem: true
				}
				strategy: appsv1.#DeploymentStrategy | *{
					type: "RollingUpdate"
					rollingUpdate: {
						maxSurge:       "25%"
						maxUnavailable: "25%"
					}
				}
				readinessProbe: corev1.#Probe | *{
					httpGet: {
						path: "/ready"
						port: "http-metrics"
					}
					initialDelaySeconds: 15
					timeoutSeconds:      1
				}
				resources: corev1.#ResourceRequirements | *{}
				extraArgs: {[string]: string} | *{}
				env: [...corev1.#EnvVar] | *[]
				hostAliases: [...corev1.#HostAlias] | *[]
				nodeSelector: {[string]: string} | *{}
				affinity: corev1.#Affinity | *{}
				tolerations: [...corev1.#Toleration] | *[]
				terminationGracePeriodSeconds: int | *30
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraContainers: [...corev1.#Container] | *[]
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
			}
			extraObjects: [...{...}] | *[]

			// Replicas for validation and scaling
			singleBinary: {
				replicas:                      int | *0
				targetModule:                  string | *"all"
				terminationGracePeriodSeconds: int | *30
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				selectorLabels: {[string]: string} | *{}
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
				}
				priorityClassName: string | *""
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				dnsConfig: {...} | *null
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				persistence: {
					enabled: bool | *false
					annotations: {[string]: string} | *{}
					storageClass: string | *null
					size:         string | *"10Gi"
					selector: {...} | *{}
					enableStatefulSetAutoDeletePVC: bool | *false
				}
				serviceAnnotations: {[string]: string} | *{}
			}
			backend: {
				replicas:                      int | *0
				targetModule:                  string | *"all"
				podManagementPolicy:           string | *"OrderedReady"
				terminationGracePeriodSeconds: int | *30
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				selectorLabels: {[string]: string} | *{}
				priorityClassName: string | *""
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				dnsConfig: {...} | *null
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				initContainers: [...corev1.#Container] | *[]
				persistence: {
					volumeClaimsEnabled: bool | *false
					annotations: {[string]: string} | *{}
					storageClass: string | *null
					size:         string | *"10Gi"
					selector: {...} | *{}
					enableStatefulSetAutoDeletePVC: bool | *false
					dataVolumeParameters: {...} | *{emptyDir: {}}
				}
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
				}
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
				pdb: {
					enabled:        bool | *false
					maxUnavailable: int | string | *null
					minAvailable:   int | string | *null
				}
			}
			read: {
				replicas:                      int | *0
				legacyReadTarget:              bool | *false
				targetModule:                  string | *"read"
				terminationGracePeriodSeconds: int | *30
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
				}
				persistence: {
					enabled:      bool | *false
					size:         string | *"10Gi"
					storageClass: string | *null
				}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
			}
			write: {
				replicas:                      int | *0
				targetModule:                  string | *"write"
				podManagementPolicy:           string | *"OrderedReady"
				terminationGracePeriodSeconds: int | *30
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				selectorLabels: {[string]: string} | *{}
				priorityClassName: string | *""
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				dnsConfig: {...} | *null
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeClaimTemplates: [...corev1.#PersistentVolumeClaim] | *[]
				initContainers: [...corev1.#Container] | *[]
				extraContainers: [...corev1.#Container] | *[]
				lifecycle: corev1.#Lifecycle | *{}
				persistence: {
					volumeClaimsEnabled: bool | *false
					annotations: {[string]: string} | *{}
					storageClass: string | *null
					size:         string | *"10Gi"
					selector: {...} | *{}
					enableStatefulSetAutoDeletePVC: bool | *false
					dataVolumeParameters: {...} | *{}
				}
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
				}
			}
			ingester: {
				replicas: int | *0
				image: {
					registry:   string | *null
					repository: string | *null
					tag:        string | *null
				}
				command:           string | *""
				priorityClassName: string | *""
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				readinessProbe: corev1.#Probe | *{}
				livenessProbe: corev1.#Probe | *{}
				resources: corev1.#ResourceRequirements | *{}
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				terminationGracePeriodSeconds: int | *30
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				affinity: corev1.#Affinity | *{
					podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchLabels: "app.kubernetes.io/component": "ingester"
						topologyKey: "kubernetes.io/hostname"
					}]
				}
				appProtocol: grpc: string | *""
				lifecycle: corev1.#Lifecycle | *{}
				persistence: {
					enabled:      bool | *true
					inMemory:     bool | *false
					size:         string | *"10Gi"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					whenDeleted:                    string | *"Retain"
					whenScaled:                     string | *"Retain"
					enableStatefulSetAutoDeletePVC: bool | *false
					claims: [...{
						name:         string
						size:         string
						storageClass: string | *null
						annotations: {[string]: string} | *{}
					}] | *[{
						name:         "data"
						size:         "10Gi"
						storageClass: null
						annotations: {}
					}]
				}
				maxUnavailable: int | string | *null
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
				}
				zoneAwareReplication: {
					enabled:           bool | *false
					maxUnavailablePct: int | *33
					migration: {
						enabled:   bool | *false
						writePath: bool | *false
					}
					zoneA: {
						nodeSelector: {[string]: string} | *{}
						tolerations: [...corev1.#Toleration] | *[]
						extraAffinity: corev1.#Affinity | *{}
						annotations: {[string]: string} | *{}
						podAnnotations: {[string]: string} | *{}
					}
					zoneB: {
						nodeSelector: {[string]: string} | *{}
						tolerations: [...corev1.#Toleration] | *[]
						extraAffinity: corev1.#Affinity | *{}
						annotations: {[string]: string} | *{}
						podAnnotations: {[string]: string} | *{}
					}
					zoneC: {
						nodeSelector: {[string]: string} | *{}
						tolerations: [...corev1.#Toleration] | *[]
						extraAffinity: corev1.#Affinity | *{}
						annotations: {[string]: string} | *{}
						podAnnotations: {[string]: string} | *{}
					}
				}
			}
			distributor: {
				replicas: int | *0
				hostAliases: [...corev1.#HostAlias] | *[]
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *3
					targetCPUUtilizationPercentage:    int | *60
					targetMemoryUtilizationPercentage: int | *null
					customMetrics: [...{...}] | *[]
					behavior: {
						enabled: bool | *false
						scaleDown: {...} | *{}
						scaleUp: {...} | *{}
					}
				}
				image: {
					registry:   string | *null
					repository: string | *null
					tag:        string | *null
				}
				command:           string | *""
				priorityClassName: string | *""
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				resources: corev1.#ResourceRequirements | *{}
				extraContainers: [...corev1.#Container] | *[]
				terminationGracePeriodSeconds: int | *30
				affinity: corev1.#Affinity | *{
					podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchLabels: "app.kubernetes.io/component": "distributor"
						topologyKey: "kubernetes.io/hostname"
					}]
				}
				maxUnavailable: int | string | *null
				maxSurge:       int | string | *0
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				appProtocol: grpc: string | *""
			}
			querier: replicas: int | *0
			queryFrontend: {
				replicas: int | *0
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
					customMetrics: [...{...}] | *[]
					behavior: {
						enabled: bool | *false
						scaleDown: {...} | *{}
						scaleUp: {...} | *{}
					}
				}
				maxUnavailable:                int | string | *1
				terminationGracePeriodSeconds: int | *30
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				dnsConfig: corev1.#PodDNSConfig | *null
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				appProtocol: {
					grpc: string | *null
				}
			}
			queryScheduler: {
				replicas:                      int | *0
				maxUnavailable:                int | string | *1
				terminationGracePeriodSeconds: int | *30
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
			}
			indexGateway: {
				replicas: int | *0
				image: {
					registry:   string | *null
					repository: string | *null
					tag:        string | *null
				}
				command:           string | *""
				priorityClassName: string | *""
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				readinessProbe: corev1.#Probe | *{}
				livenessProbe: corev1.#Probe | *{}
				resources: corev1.#ResourceRequirements | *{}
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				terminationGracePeriodSeconds: int | *30
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				affinity: corev1.#Affinity | *{
					podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchLabels: "app.kubernetes.io/component": "index-gateway"
						topologyKey: "kubernetes.io/hostname"
					}]
				}
				appProtocol: grpc: string | *""
				lifecycle: corev1.#Lifecycle | *{}
				joinMemberlist: bool | *false
				persistence: {
					enabled:      bool | *true
					inMemory:     bool | *false
					size:         string | *"10Gi"
					storageClass: string | *""
					accessModes: [...string] | *["ReadWriteOnce"]
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					whenDeleted:                    string | *"Retain"
					whenScaled:                     string | *"Retain"
					enableStatefulSetAutoDeletePVC: bool | *false
				}
				maxUnavailable: int | string | *null
			}
			compactor: {
				replicas: int | *0
				image: {
					registry:   string | *null
					repository: string | *null
					tag:        string | *null
				}
				command:           string | *""
				priorityClassName: string | *""
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				readinessProbe: corev1.#Probe | *{}
				livenessProbe: corev1.#Probe | *{}
				resources: corev1.#ResourceRequirements | *{}
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				terminationGracePeriodSeconds: int | *30
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				affinity: corev1.#Affinity | *{
					podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchLabels: "app.kubernetes.io/component": "compactor"
						topologyKey: "kubernetes.io/hostname"
					}]
				}
				appProtocol: grpc: string | *""
				lifecycle: corev1.#Lifecycle | *{}
				persistence: {
					enabled:      bool | *false
					size:         string | *"10Gi"
					storageClass: string | *null
					annotations: {[string]: string} | *{}
					claims: [...{
						name:         string
						size:         string
						storageClass: string | *null
						annotations: {[string]: string} | *{}
					}] | *[{
						name:         "data"
						size:         "10Gi"
						storageClass: null
						annotations: {}
					}]
					enableStatefulSetAutoDeletePVC: bool | *false
					whenDeleted:                    string | *"Retain"
					whenScaled:                     string | *"Retain"
				}
				serviceAccount: {
					create: bool | *false
					name:   string | *""
					imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
					annotations: {[string]: string} | *{}
					automountServiceAccountToken: bool | *true
				}
			}
			tableManager: {
				enabled:                       bool | *false
				terminationGracePeriodSeconds: int | *30
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				serviceMonitor: {
					enabled:       bool | *false
					interval:      string | *"15s"
					scrapeTimeout: string | *null
					relabelings: [...{...}] | *[]
					metricRelabelings: [...{...}] | *[]
				}
			}
			bloomBuilder: {
				replicas:                      int | *0
				command:                       string | *null
				priorityClassName:             string | *""
				terminationGracePeriodSeconds: int | *30
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
				}
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
				pdb: {
					enabled:        bool | *false
					maxUnavailable: int | string | *null
					minAvailable:   int | string | *null
				}
			}
			resultsCache: {
				enabled:         bool | *false
				batchSize:       int | *256
				parallelism:     int | *10
				timeout:         string | *"500ms"
				defaultValidity: string | *"12h"
				replicas:        int | *1
				port:            int | *11211
				allocatedMemory: int | *1024
				maxItemMemory:   int | *1
				connectionLimit: int | *1024
				initContainers: [...corev1.#Container] | *[]
				annotations: {[string]: string} | *{}
				nodeSelector: {[string]: string} | *{}
				affinity: corev1.#Affinity | *{}
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				tolerations: [...corev1.#Toleration] | *[]
				podDisruptionBudget: {
					enabled:        bool | *false
					maxUnavailable: int | string | *null
					minAvailable:   int | string | *null
				}
				priorityClassName: string | *""
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podManagementPolicy:           string | *"Parallel"
				terminationGracePeriodSeconds: int | *60
				statefulStrategy: appsv1.#StatefulSetUpdateStrategy | *{
					type: "RollingUpdate"
				}
				extraExtendedOptions: string | *""
				extraArgs: {[string]: string} | *{}
				extraContainers: [...corev1.#Container] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				resources: corev1.#ResourceRequirements | *null
				service: {
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
				}
				persistence: {
					enabled:      bool | *false
					storageSize:  string | *"10G"
					storageClass: string | *null
					mountPath:    string | *"/data"
				}
			}
			chunksCache: {
				enabled:              bool | *true
				batchSize:            int | *4
				parallelism:          int | *5
				timeout:              string | *"2000ms"
				defaultValidity:      string | *"0s"
				replicas:             int | *1
				port:                 int | *11211
				allocatedMemory:      int | *8192
				maxItemMemory:        int | *5
				connectionLimit:      int | *16384
				writebackSizeLimit:   string | *"500MB"
				writebackBuffer:      int | *500000
				writebackParallelism: int | *1
				initContainers: [...corev1.#Container] | *[]
				annotations: {[string]: string} | *{}
				nodeSelector: {[string]: string} | *{}
				affinity: corev1.#Affinity | *{}
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				tolerations: [...corev1.#Toleration] | *[]
				podDisruptionBudget: {
					enabled:        bool | *false
					maxUnavailable: int | string | *1
					minAvailable:   int | string | *null
				}
				priorityClassName: string | *""
				podLabels: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podManagementPolicy:           string | *"Parallel"
				terminationGracePeriodSeconds: int | *60
				statefulStrategy: appsv1.#StatefulSetUpdateStrategy | *{
					type: "RollingUpdate"
				}
				extraExtendedOptions: string | *""
				extraArgs: {[string]: string} | *{}
				extraContainers: [...corev1.#Container] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				resources: corev1.#ResourceRequirements | *null
				service: {
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
				}
				persistence: {
					enabled:      bool | *false
					storageSize:  string | *"10G"
					storageClass: string | *null
					mountPath:    string | *"/data"
				}
			}
			memcached: {
				image: {
					repository: string | *"memcached"
					tag:        string | *"1.6.29-alpine"
					pullPolicy: string | *"IfNotPresent"
				}
				podSecurityContext: corev1.#PodSecurityContext | *{
					fsGroup:      1001
					runAsGroup:   1001
					runAsNonRoot: true
					runAsUser:    1001
				}
				containerSecurityContext: corev1.#SecurityContext | *{
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
					readOnlyRootFilesystem: true
				}
			}
			memcachedExporter: {
				enabled: bool | *false
				image: {
					repository: string | *"prom/memcached-exporter"
					tag:        string | *"v0.15.0"
					pullPolicy: string | *"IfNotPresent"
				}
				resources: corev1.#ResourceRequirements | *{}
				containerSecurityContext: corev1.#SecurityContext | *{
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
					readOnlyRootFilesystem: true
				}
				extraArgs: {[string]: string} | *{}
			}
			querier: {
				replicas: int | *0
				autoscaling: {
					enabled:                           bool | *false
					minReplicas:                       int | *1
					maxReplicas:                       int | *10
					targetCPUUtilizationPercentage:    int | *null
					targetMemoryUtilizationPercentage: int | *null
					customMetrics: [...{...}] | *[]
					behavior: {
						enabled: bool | *false
						scaleDown: {...} | *{}
						scaleUp: {...} | *{}
					}
				}
				maxUnavailable:                int | string | *1
				terminationGracePeriodSeconds: int | *30
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				dnsConfig: corev1.#PodDNSConfig | *null
				serviceLabels: {[string]: string} | *{}
				serviceAnnotations: {[string]: string} | *{}
				appProtocol: {
					grpc: string | *null
				}
			}
			patternIngester: {
				replicas:                      int | *0
				terminationGracePeriodSeconds: int | *30
				command:                       string | *null
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				persistence: {
					enabled:                        bool | *false
					enableStatefulSetAutoDeletePVC: bool | *false
					whenDeleted:                    string | *"Delete"
					whenScaled:                     string | *"Retain"
					claims: [...{
						name:          string
						size:          string
						storageClass?: string
						annotations: {[string]: string} | *{}
					}] | *[]
				}
				readinessProbe: corev1.#Probe | *null
			}
			bloomGateway: {
				replicas:                      int | *0
				command:                       string | *null
				priorityClassName:             string | *""
				terminationGracePeriodSeconds: int | *30
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				persistence: {
					enabled:                        bool | *false
					enableStatefulSetAutoDeletePVC: bool | *false
					whenDeleted:                    string | *"Retain"
					whenScaled:                     string | *"Retain"
					claims: [...{
						name:         string
						size:         string | *"10Gi"
						storageClass: string | *null
						annotations: {[string]: string} | *{}
					}] | *[]
				}
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
			}
			bloomPlanner: {
				replicas:                      int | *0
				command:                       string | *null
				priorityClassName:             string | *""
				terminationGracePeriodSeconds: int | *30
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				resources: corev1.#ResourceRequirements | *{}
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				persistence: {
					enabled:                        bool | *false
					enableStatefulSetAutoDeletePVC: bool | *false
					whenDeleted:                    string | *"Retain"
					whenScaled:                     string | *"Retain"
					claims: [...{
						name:         string
						size:         string | *"10Gi"
						storageClass: string | *null
						annotations: {[string]: string} | *{}
					}] | *[]
				}
				service: {
					labels: {[string]: string} | *{}
					annotations: {[string]: string} | *{}
				}
			}
			ruler: {
				enabled:                       bool | *false
				replicas:                      int | *0
				terminationGracePeriodSeconds: int | *30
				extraArgs: [...string] | *[]
				extraEnv: [...corev1.#EnvVar] | *[]
				extraEnvFrom: [...corev1.#EnvFromSource] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				extraVolumes: [...corev1.#Volume] | *[]
				extraContainers: [...corev1.#Container] | *[]
				initContainers: [...corev1.#Container] | *[]
				affinity: corev1.#Affinity | *{}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				resources: corev1.#ResourceRequirements | *{}
				priorityClassName: string | *null
				podAnnotations: {[string]: string} | *{}
				podLabels: {[string]: string} | *{}
				hostAliases: [...corev1.#HostAlias] | *[]
				persistence: {
					enabled:      bool | *false
					size:         string | *"10Gi"
					storageClass: string | *null
					annotations: {[string]: string} | *{}
				}
				directories: {[string]: {...}} | *{}
			}

			// Validations (Parity with validate.yaml)
			if enterprise.enabled && !enterprise.useExternalLicense {
				enterprise: license: contents: string & !=""
			}

			monitoring: {
				dashboards: {
					enabled:   bool | *false
					namespace: string | *null
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{grafana_dashboard: "1"}
				}
				rules: {
					enabled:  bool | *false
					alerting: bool | *true
					disabled: {[string]: bool} | *{}
					namespace: string | *null
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					additionalRuleLabels: {[string]: string} | *{}
					additionalGroups: [...{...}] | *[]
				}
				serviceMonitor: {
					enabled:   bool | *false
					namespace: string | *null
					namespaceSelector: {...} | *{}
					annotations: {[string]: string} | *{}
					labels: {[string]: string} | *{}
					interval:      string | *"15s"
					scrapeTimeout: string | *null
					relabelings: [...{...}] | *[]
					metricRelabelings: [...{...}] | *[]
					scheme: string | *"http"
					tlsConfig: {...} | *null
					metricsInstance: {
						enabled: bool | *false
						annotations: {[string]: string} | *{}
						labels: {[string]: string} | *{}
						remoteWrite: [...{...}] | *[]
					}
				}
				selfMonitoring: {
					enabled: bool | *false
					tenant: {
						name:            string | *"self-monitoring"
						password:        string | *null
						secretNamespace: string | *null
					}
					grafanaAgent: {
						enabled:         bool | *false
						installOperator: bool | *false
						annotations: {[string]: string} | *{}
						labels: {[string]: string} | *{}
						enableConfigReadAPI: bool | *false
						priorityClassName:   string | *null
						resources: corev1.#ResourceRequirements | *{}
						tolerations: [...corev1.#Toleration] | *[]
					}
					logsInstance: {
						enabled: bool | *false
						annotations: {[string]: string} | *{}
						labels: {[string]: string} | *{}
						clients: [...{...}] | *[]
					}
					podLogs: {
						enabled:    bool | *false
						apiVersion: string | *"monitoring.grafana.com/v1alpha1"
						annotations: {[string]: string} | *{}
						labels: {[string]: string} | *{}
						additionalPipelineStages: [...{...}] | *[]
						relabelings: [...{...}] | *[]
					}
				}
			}
		}
		"grafana-agent-operator": {
			nameOverride:     string | *""
			fullnameOverride: string | *""
			annotations: {[string]: string} | *{}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{}
			podSecurityContext: corev1.#PodSecurityContext | *{}
			containerSecurityContext: corev1.#SecurityContext | *{}
			rbac: {
				create:                bool | *true
				podSecurityPolicyName: string | *""
			}
			serviceAccount: {
				create: bool | *true
				name:   string | *""
			}
			image: {
				registry:   string | *"docker.io"
				repository: string | *"grafana/agent-operator"
				tag:        string | *"v0.39.1"
				pullPolicy: string | *"IfNotPresent"
				pullSecrets: [...string] | *[]
			}
			hostAliases: [...corev1.#HostAlias] | *[]
			kubeletService: {
				namespace:   string | *"default"
				serviceName: string | *"kubelet"
			}
			extraArgs: [...string] | *[]
			resources: corev1.#ResourceRequirements | *{}
			nodeSelector: {[string]: string} | *{}
			tolerations: [...corev1.#Toleration] | *[]
			affinity: corev1.#Affinity | *{}
		}
		"rollout-operator": {
			enabled: bool | *false
			image: {
				repository: string | *"grafana/rollout-operator"
				pullPolicy: string | *"IfNotPresent"
				tag:        string | *"v0.8.2"
			}
			imagePullSecrets: [...corev1.#LocalObjectReference] | *[]
			hostAliases: [...corev1.#HostAlias] | *[]
			nameOverride:     string | *""
			fullnameOverride: string | *""
			serviceAccount: {
				create: bool | *true
				annotations: {[string]: string} | *{}
				name: string | *""
			}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{}
			podSecurityContext: corev1.#PodSecurityContext | *{}
			securityContext: corev1.#SecurityContext | *{}
			resources: corev1.#ResourceRequirements | *{
				limits: memory: "200Mi"
				requests: {
					cpu:    "100m"
					memory: "100Mi"
				}
			}
			minReadySeconds: int | *10
			nodeSelector: {[string]: string} | *{}
			tolerations: [...corev1.#Toleration] | *[]
			affinity: corev1.#Affinity | *{}
			priorityClassName: string | *""
			serviceMonitor: {
				enabled:   bool | *false
				namespace: string | *null
				namespaceSelector: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				interval:      string | *null
				scrapeTimeout: string | *null
				relabelings: [...{...}] | *[]
			}
		}
		singleBinary: tolerations: [...corev1.#Toleration] | *[]
		minio: {
			enabled:          bool | *false
			nameOverride:     string | *""
			fullnameOverride: string | *""
			clusterDomain:    string | *"cluster.local"
			image: {
				repository: string | *"quay.io/minio/minio"
				tag:        string | *"RELEASE.2022-09-17T00-09-45Z"
				pullPolicy: string | *"IfNotPresent"
			}
			imagePullSecrets: [...string] | *[]
			mcImage: {
				repository: string | *"quay.io/minio/mc"
				tag:        string | *"RELEASE.2022-09-16T09-16-47Z"
				pullPolicy: string | *"IfNotPresent"
			}
			mode: "distributed" | "standalone" | "gateway" | *"distributed"
			additionalLabels: {[string]: string} | *{}
			additionalAnnotations: {[string]: string} | *{}
			ignoreChartChecksums: bool | *false
			extraArgs: [...string] | *[]
			extraVolumes: [...corev1.#Volume] | *[]
			extraVolumeMounts: [...corev1.#VolumeMount] | *[]
			minioAPIPort:     string | *"9000"
			minioConsolePort: string | *"9001"
			DeploymentUpdate: {
				type:           string | *"RollingUpdate"
				maxUnavailable: int | string | *0
				maxSurge:       int | string | *"100%"
			}
			StatefulSetUpdate: {
				updateStrategy: string | *"RollingUpdate"
			}
			priorityClassName: string | *""
			runtimeClassName:  string | *""
			rootUser:          string | *""
			rootPassword:      string | *""
			existingSecret:    string | *""
			certsPath:         string | *"/etc/minio/certs/"
			configPathmc:      string | *"/etc/minio/mc/"
			mountPath:         string | *"/export"
			bucketRoot:        string | *""
			drivesPerNode:     int | *1
			replicas:          int | *16
			pools:             int | *1
			gateway: {
				type:     string | *"nas"
				replicas: int | *4
			}
			tls: {
				enabled:    bool | *false
				certSecret: string | *""
				publicCrt:  string | *"public.crt"
				privateKey: string | *"private.key"
			}
			trustedCertsSecret: string | *""
			persistence: {
				enabled: bool | *true
				annotations: {[string]: string} | *{}
				existingClaim: string | *""
				storageClass:  string | *""
				VolumeName:    string | *""
				accessMode:    string | *"ReadWriteOnce"
				size:          string | *"500Gi"
				subPath:       string | *""
			}
			service: {
				type:           string | *"ClusterIP"
				clusterIP:      string | *""
				loadBalancerIP: string | *""
				externalIPs: [...string] | *[]
				port:     string | *"9000"
				nodePort: int | *32000
				annotations: {[string]: string} | *{}
			}
			ingress: {
				enabled: bool | *false
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				ingressClassName: string | *""
				path:             string | *"/"
				hosts: [...string] | *["minio-example.local"]
				tls: [...{
					secretName: string
					hosts: [...string]
				}] | *[]
			}
			consoleService: {
				type:           string | *"ClusterIP"
				clusterIP:      string | *""
				loadBalancerIP: string | *""
				externalIPs: [...string] | *[]
				port:     string | *"9001"
				nodePort: int | *32001
				annotations: {[string]: string} | *{}
			}
			consoleIngress: {
				enabled: bool | *false
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				ingressClassName: string | *""
				path:             string | *"/"
				hosts: [...string] | *["console.minio-example.local"]
				tls: [...{
					secretName: string
					hosts: [...string]
				}] | *[]
			}
			nodeSelector: {[string]: string} | *{}
			tolerations: [...corev1.#Toleration] | *[]
			affinity: corev1.#Affinity | *{}
			topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *{}
			securityContext: {
				enabled:             bool | *true
				sccEnabled:          bool | *false
				runAsUser:           int | *1000
				runAsGroup:          int | *1000
				fsGroup:             int | *1000
				fsGroupChangePolicy: string | *"OnRootMismatch"
			}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{}
			resources: corev1.#ResourceRequirements | *{
				requests: memory: "512Mi"
			}
			policies: [...{
				name: string
				statements: [...{
					resources: [...string]
					actions: [...string]
					conditions?: [...{[string]: string}]
				}]
			}] | *[]
			makePolicyJob: {
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				securityContext: {
					enabled:    bool | *false
					runAsUser:  int | *1000
					runAsGroup: int | *1000
					fsGroup:    int | *1000
				}
				resources: corev1.#ResourceRequirements | *{
					requests: memory: "128Mi"
				}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: corev1.#Affinity | *{}
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				exitCommand: string | *""
			}
			users: [...{
				accessKey:          string
				secretKey:          string
				policy:             string
				existingSecret?:    string
				existingSecretKey?: string
			}] | *[
				{
					accessKey: "console"
					secretKey: "console123"
					policy:    "consoleAdmin"
				},
			]
			makeUserJob: {
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				securityContext: {
					enabled:    bool | *false
					runAsUser:  int | *1000
					runAsGroup: int | *1000
					fsGroup:    int | *1000
				}
				resources: corev1.#ResourceRequirements | *{
					requests: memory: "128Mi"
				}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: corev1.#Affinity | *{}
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				exitCommand: string | *""
			}
			buckets: [...{
				name:          string
				policy:        string | *"none"
				purge:         bool | *false
				versioning:    bool | *false
				objectlocking: bool | *false
			}] | *[]
			makeBucketJob: {
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				securityContext: {
					enabled:    bool | *false
					runAsUser:  int | *1000
					runAsGroup: int | *1000
					fsGroup:    int | *1000
				}
				resources: corev1.#ResourceRequirements | *{
					requests: memory: "128Mi"
				}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: corev1.#Affinity | *{}
				extraVolumes: [...corev1.#Volume] | *[]
				extraVolumeMounts: [...corev1.#VolumeMount] | *[]
				exitCommand: string | *""
			}
			customCommands: [...{
				command: string
			}] | *[]
			customCommandJob: {
				podAnnotations: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
				securityContext: {
					enabled:    bool | *false
					runAsUser:  int | *1000
					runAsGroup: int | *1000
					fsGroup:    int | *1000
				}
				resources: corev1.#ResourceRequirements | *{
					requests: memory: "128Mi"
				}
				nodeSelector: {[string]: string} | *{}
				tolerations: [...corev1.#Toleration] | *[]
				affinity: corev1.#Affinity | *{}
				exitCommand: string | *""
			}
			environment: {[string]: string} | *{}
			extraSecret: string | *""
			oidc: {
				enabled:      bool | *false
				configUrl:    string | *""
				clientId:     string | *""
				clientSecret: string | *""
				claimName:    string | *"policy"
				scopes:       string | *"openid,profile,email"
				redirectUri:  string | *""
				claimPrefix:  string | *""
				comment:      string | *""
			}
			networkPolicy: {
				enabled:       bool | *false
				allowExternal: bool | *true
			}
			podDisruptionBudget: {
				enabled:        bool | *false
				maxUnavailable: int | *1
			}
			serviceAccount: {
				create: bool | *true
				name:   string | *"minio-sa"
			}
			metrics: {
				serviceMonitor: {
					enabled:     bool | *false
					includeNode: bool | *false
					public:      bool | *true
					additionalLabels: {[string]: string} | *{}
					relabelConfigs: {[string]: string} | *{}
					relabelConfigsCluster: {[string]: string} | *{}
					namespace:     string | *""
					interval:      string | *"30s"
					scrapeTimeout: string | *"10s"
				}
			}
			etcd: {
				endpoints: [...string] | *[]
				pathPrefix:        string | *""
				corednsPathPrefix: string | *""
				clientCert:        string | *""
				clientCertKey:     string | *""
			}
		}
		promtail: {
			enabled: bool | *true
			tolerations: [...corev1.#Toleration] | *[]
		}
		"opentelemetry-collector": {
			enabled: bool | *true
			mode:    "daemonset" | "deployment" | "statefulset" | *"deployment"
			command: {
				name: string | *""
				extraArgs: [...string] | *[]
			}
			image: {
				registry:   string | *""
				repository: string | *"otel/opentelemetry-collector-contrib"
				pullPolicy: string | *"IfNotPresent"
				tag:        string | *"0.122.1"
			}
			replicaCount:         int | *1
			revisionHistoryLimit: int | *10
			config: {...} | *{}
			presets: {
				logsCollection: {
					enabled:              bool | *false
					includeCollectorLogs: bool | *false
					storeCheckpoints:     bool | *false
					maxRecombineLogSize:  int | *102400
				}
				hostMetrics: enabled: bool | *false
				kubernetesAttributes: {
					enabled:                  bool | *false
					extractAllPodLabels:      bool | *false
					extractAllPodAnnotations: bool | *false
				}
				kubeletMetrics: enabled:   bool | *false
				kubernetesEvents: enabled: bool | *false
				clusterMetrics: enabled:   bool | *false
			}
			configMap: create: bool | *true
			serviceAccount: {
				create: bool | *true
				annotations: {[string]: string} | *{}
				name: string | *""
			}
			clusterRole: {
				create: bool | *false
				annotations: {[string]: string} | *{}
				name: string | *""
				rules: [...corev1.#PolicyRule] | *[]
			}
			podSecurityContext: corev1.#PodSecurityContext | *{}
			securityContext: corev1.#ContainerSecurityContext | *{}
			nodeSelector: {[string]: string} | *{}
			tolerations: [...corev1.#Toleration] | *[]
			affinity: corev1.#Affinity | *{}
			priorityClassName: string | *""
			resources: corev1.#ResourceRequirements | *{}
			podAnnotations: {[string]: string} | *{}
			podLabels: {[string]: string} | *{}
			hostNetwork: bool | *false
			dnsPolicy:   string | *""
			dnsConfig: {...} | *null
			extraEnvs: [...corev1.#EnvVar] | *[]
			extraEnvsFrom: [...corev1.#EnvFromSource] | *[]
			extraVolumes: [...corev1.#Volume] | *[]
			extraVolumeMounts: [...corev1.#VolumeMount] | *[]
			ports: {[string]: {
				enabled:       bool | *true
				containerPort: int
				servicePort:   int
				hostPort:      int | *null
				protocol:      string | *"TCP"
				appProtocol:   string | *null
			}} | *{}
			service: {
				enabled: bool | *true
				type:    string | *"ClusterIP"
				annotations: {[string]: string} | *{}
			}
			ingress: {
				enabled:          bool | *false
				ingressClassName: string | *null
				annotations: {[string]: string} | *{}
				hosts: [...{
					host: string
					paths: [...{
						path:     string
						pathType: string | *"Prefix"
						port:     int
					}]
				}] | *[]
				tls: [...{
					secretName: string
					hosts: [...string]
				}] | *[]
			}
			serviceMonitor: {
				enabled: bool | *false
				metricsEndpoints: [...{
					port:     string
					interval: string | *null
					relabelings: [...{...}] | *[]
					metricRelabelings: [...{...}] | *[]
				}] | *[]
				extraLabels: {[string]: string} | *{}
			}
			podMonitor: {
				enabled: bool | *false
				metricsEndpoints: [...{
					port:     string
					interval: string | *null
				}] | *[]
				extraLabels: {[string]: string} | *{}
			}
			podDisruptionBudget: {
				enabled:        bool | *false
				minAvailable:   int | *null
				maxUnavailable: int | *null
			}
			autoscaling: {
				enabled:                           bool | *false
				minReplicas:                       int | *1
				maxReplicas:                       int | *10
				targetCPUUtilizationPercentage:    int | *80
				targetMemoryUtilizationPercentage: int | *null
				behavior: {...} | *null
			}
			networkPolicy: {
				enabled: bool | *false
				annotations: {[string]: string} | *{}
				allowIngressFrom: [...{...}] | *[]
				extraIngressRules: [...{...}] | *[]
				egressRules: [...{...}] | *[]
			}
			prometheusRule: {
				enabled: bool | *false
				groups: [...{...}] | *[]
				extraLabels: {[string]: string} | *{}
			}
			extraManifests: [...{...}] | *[]
		}
		promtail: {
			enabled: bool | *true
			daemonset: {
				enabled: bool | *true
				autoscaling: {
					enabled: bool | *false
				}
			}
			deployment: {
				enabled:      bool | *false
				replicaCount: int | *1
				autoscaling: {
					enabled:                        bool | *false
					minReplicas:                    int | *1
					maxReplicas:                    int | *10
					targetCPUUtilizationPercentage: int | *80
				}
				strategy: {
					type: string | *"RollingUpdate"
				}
			}
			service: {
				enabled: bool | *false
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
			}
			secret: {
				labels: {[string]: string} | *{}
				annotations: {[string]: string} | *{}
			}
			configmap: {
				enabled: bool | *false
			}
			image: {
				registry:   string | *"docker.io"
				repository: string | *"grafana/promtail"
				tag:        string | *"3.0.0"
				pullPolicy: string | *"IfNotPresent"
			}
			imagePullSecrets: [...string] | *[]
			hostAliases: [...corev1.#HostAlias] | *[]
			hostNetwork: bool | *false
			annotations: {[string]: string} | *{}
			updateStrategy: {...} | *{}
			podLabels: {[string]: string} | *{}
			podAnnotations: {[string]: string} | *{}
			priorityClassName: string | *""
			resources: corev1.#ResourceRequirements | *{}
			podSecurityContext: corev1.#PodSecurityContext | *{
				runAsUser:  0
				runAsGroup: 0
			}
			containerSecurityContext: corev1.#ContainerSecurityContext | *{
				readOnlyRootFilesystem:   true
				allowPrivilegeEscalation: false
				capabilities: drop: ["ALL"]
			}
			rbac: {
				create:     bool | *true
				pspEnabled: bool | *false
			}
			serviceAccount: {
				create: bool | *true
				name:   string | *null
				annotations: {[string]: string} | *{}
			}
			nodeSelector: {[string]: string} | *{}
			affinity: corev1.#Affinity | *{}
			tolerations: [...corev1.#Toleration] | *[
				{
					key:      "node-role.kubernetes.io/master"
					operator: "Exists"
					effect:   "NoSchedule"
				},
				{
					key:      "node-role.kubernetes.io/control-plane"
					operator: "Exists"
					effect:   "NoSchedule"
				},
			]
			defaultVolumes: [...corev1.#Volume] | *[
				{
					name: "run"
					hostPath: path: "/run/promtail"
				},
				{
					name: "containers"
					hostPath: path: "/var/lib/docker/containers"
				},
				{
					name: "pods"
					hostPath: path: "/var/log/pods"
				},
			]
			defaultVolumeMounts: [...corev1.#VolumeMount] | *[
				{
					name:      "run"
					mountPath: "/run/promtail"
				},
				{
					name:      "containers"
					mountPath: "/var/lib/docker/containers"
					readOnly:  true
				},
				{
					name:      "pods"
					mountPath: "/var/log/pods"
					readOnly:  true
				},
			]
			extraVolumes: [...corev1.#Volume] | *[]
			extraVolumeMounts: [...corev1.#VolumeMount] | *[]
			extraArgs: [...string] | *[]
			extraEnv: [...corev1.#EnvVar] | *[]
			extraEnvFrom: [...corev1.#EnvFromSource] | *[]
			serviceMonitor: {
				enabled:   bool | *false
				namespace: string | *null
				annotations: {[string]: string} | *{}
				labels: {[string]: string} | *{}
				interval: string | *null
				relabelings: [...{...}] | *[]
				metricRelabelings: [...{...}] | *[]
				prometheusRule: {
					enabled: bool | *false
					rules: [...{...}] | *[]
					additionalLabels: {[string]: string} | *{}
				}
			}
			extraPorts: {[string]: {
				name:          string
				containerPort: int
				protocol:      string | *"TCP"
				service: {
					type: string | *"ClusterIP"
					port: int
				}
				ingress: {
					enabled: bool | *false
					hosts: [...string] | *[]
				}
			}} | *{}
			sidecar: {
				configReloader: {
					enabled: bool | *false
					image: {
						registry:   string | *"ghcr.io"
						repository: string | *"jimmidyson/configmap-reload"
						tag:        string | *"v0.12.0"
						pullPolicy: string | *"IfNotPresent"
					}
					extraArgs: [...string] | *[]
					extraEnv: [...corev1.#EnvVar] | *[]
					extraEnvFrom: [...corev1.#EnvFromSource] | *[]
					containerSecurityContext: corev1.#ContainerSecurityContext | *{
						readOnlyRootFilesystem:   true
						allowPrivilegeEscalation: false
						capabilities: drop: ["ALL"]
					}
					resources: corev1.#ResourceRequirements | *{}
					config: {
						serverPort: int | *9533
					}
					serviceMonitor: enabled: bool | *true
				}
			}
			config: {
				let _name = metadata.name
				enabled:    bool | *true
				logLevel:   string | *"info"
				logFormat:  string | *"logfmt"
				serverPort: int | *3101
				let _clients = [
					{url: "http://\(_name)-loki-gateway/loki/api/v1/push"},
				]
				clients: [...{...}] | *_clients
				positions: {...} | *{
					filename: "/run/promtail/positions.yaml"
				}
				snippets: {
					pipelineStages: [...{...}] | *[{cri: {}}]
					common: [...{...}] | *[]
					extraRelabelConfigs: [...{...}] | *[]
					scrapeConfigs: string | *""
				}
				file: """
					server:
					  log_level: \(logLevel)
					  http_listen_port: \(serverPort)
					
					clients:
					  - url: http://\(_name)-loki-gateway/loki/api/v1/push
					
					positions:
					  filename: "/run/promtail/positions.yaml"
					
					scrape_configs:
					- job_name: kubernetes-pods
					  kubernetes_sd_configs:
					  - role: pod
					  relabel_configs:
					  - action: labelmap
					    regex: __meta_kubernetes_pod_label_(.+)
					  - source_labels: [__meta_kubernetes_namespace]
					    action: replace
					    target_label: namespace
					  - source_labels: [__meta_kubernetes_pod_name]
					    action: replace
					    target_label: pod
					"""
			}
			networkPolicy: {
				enabled: bool | *false
				metrics: {
					podSelector: {...} | *{}
					namespaceSelector: {...} | *{}
					cidrs: [...string] | *[]
				}
				k8sApi: {
					port: int | *8443
					cidrs: [...string] | *[]
				}
			}
			podSecurityPolicy: {...} | *{
				privileged:               true
				allowPrivilegeEscalation: true
				volumes: ["secret", "hostPath", "downwardAPI"]
				hostNetwork: false
				hostIPC:     false
				hostPID:     false
				runAsUser: rule:          "RunAsAny"
				seLinux: rule:            "RunAsAny"
				supplementalGroups: rule: "RunAsAny"
				fsGroup: rule:            "RunAsAny"
				readOnlyRootFilesystem: true
				requiredDropCapabilities: ["ALL"]
			}
			extraObjects: [...{...}] | *[]
		}
		postgresql: {
			external: bool | *false
			primary: {
				host:     string | *"postgresql"
				port:     int | *5432
				username: string | *"hyperswitch"
				password: string | *"ZGJwYXNzd29yZDEx"
				database: string | *"hyperswitch"
			}
		}
	}

	"hyperswitch-ucs": {
		enabled:          bool | *false
		fullnameOverride: string | *"hyperswitch-ucs"
		image: {
			imageRegistry: string | *"ghcr.io"
			repository:    string | *"juspay/connector-service"
			pullPolicy:    string | *"IfNotPresent"
			tag:           string | *"main-b1487cb"
		}
		imagePullSecrets: [...string] | *[]
		nameOverride: string | *""
		serviceAccount: {
			create: bool | *true
			annotations: {[string]: string} | *{}
			name: string | *""
		}
		podAnnotations: {[string]: string} | *{}
		podSecurityContext: {...} | *{}
		securityContext: {...} | *{}
		service: {
			type: string | *"ClusterIP"
			grpc: {
				port:       int | *8000
				targetPort: int | *8000
			}
			metrics: {
				port:       int | *8080
				targetPort: int | *8080
			}
		}
		ingress: {
			enabled:   bool | *false
			className: string | *""
			annotations: {[string]: string} | *{}
			hosts: [...{
				host?: string
				paths: [...{
					path:     string
					pathType: string
				}]
			}] | *[]
			tls: [...{
				secretName: string
				hosts: [...string]
			}] | *[]
		}
		resources: corev1.#ResourceRequirements | *{
			limits: {
				cpu:    "1000m"
				memory: "1000Mi"
			}
			requests: {
				cpu:    "400m"
				memory: "400Mi"
			}
		}
		autoscaling: {
			enabled:                        bool | *false
			minReplicas:                    int | *1
			maxReplicas:                    int | *100
			targetCPUUtilizationPercentage: int | *80
		}
		nodeSelector: {[string]: string} | *{}
		tolerations: [...corev1.#Toleration] | *[]
		affinity: corev1.#Affinity | *{}
		livenessProbe: {
			failureThreshold:    int | *3
			initialDelaySeconds: int | *90
			periodSeconds:       int | *30
			successThreshold:    int | *1
			timeoutSeconds:      int | *10
			grpc: {
				port:    int | *8000
				service: string | *"grpc.health.v1.Health"
			}
		}
		readinessProbe: {
			failureThreshold:    int | *5
			initialDelaySeconds: int | *30
			periodSeconds:       int | *30
			successThreshold:    int | *1
			timeoutSeconds:      int | *5
			grpc: {
				port:    int | *8000
				service: string | *"grpc.health.v1.Health"
			}
		}
		replicaCount: int | *1
		config: {
			log: console: {
				enabled:    bool | *true
				level:      string | *"DEBUG"
				log_format: string | *"json"
			}
			server: {
				host: string | *"0.0.0.0"
				port: int | *8000
				type: string | *"grpc"
			}
			metrics: {
				host: string | *"0.0.0.0"
				port: int | *8080
			}
			connectors: {[string]: {
				base_url:          string
				dispute_base_url?: string
			}} | *{
				adyen: {
					base_url:         "https://{{merchant_endpoint_prefix}}-checkout-live.adyenpayments.com/checkout/"
					dispute_base_url: "https://{{merchant_endpoint_prefix}}-ca-live.adyen.com/"
				}
				razorpay: base_url:        "https://api.razorpay.com/"
				fiserv: base_url:          "https://cert.api.fiservapps.com/"
				elavon: base_url:          "https://api.convergepay.com/VirtualMerchant/"
				xendit: base_url:          "https://api.xendit.co/"
				razorpayv2: base_url:      "https://api.razorpay.com/"
				checkout: base_url:        "https://api.checkout.com/"
				authorizedotnet: base_url: "https://api.authorize.net/xml/v1/request.api/"
			}
			proxy: {
				https_url:                    string | *"https_proxy"
				http_url:                     string | *"http_proxy"
				idle_pool_connection_timeout: int | *90
				bypass_proxy_urls: [...string] | *["localhost", "local"]
			}
		}
		env: [...corev1.#EnvVar] | *[]
	}

	"hyperswitch-web": {
		enabled:      bool | *false
		replicaCount: int | *1
		sdkDemo: {
			enabled:                 bool | *true
			replicas:                int | *1
			progressDeadlineSeconds: int | *600
			strategy: {
				rollingUpdate: {
					maxSurge:       int | *1
					maxUnavailable: int | *0
				}
				type: string | *"RollingUpdate"
			}
			terminationGracePeriodSeconds: int | *30
			podAnnotations: {[string]: string} | *{}
			annotations: {[string]: string} | *{}
			labels: {[string]: string} | *{
				app: "\(metadata.name)-sdk-demo"
			}
			serviceAccountAnnotations: {[string]: string} | *{}
			env: {[string]: string} | *{
				host:   "\(metadata.name)-sdk-demo"
				binary: "sdk"
			}
			nodeAffinity: corev1.#NodeAffinity | *{}
		}
		autoBuild: {
			enable:             bool | *true
			forceBuild:         bool | *false
			buildImageRegistry: string | *"docker.juspay.io"
			buildImage:         string | *"juspaydotin/hyperswitch-web"
			gitCloneParam: {
				gitRepo:    string | *"https://github.com/juspay/hyperswitch-web"
				gitVersion: string | *"v0.129.0"
			}
			buildParam: {
				envSdkUrl:     string | *"https://hyperswitch-sdk"
				envBackendUrl: string | *"https://hyperswitch"
				envLogsUrl:    string | *"https://hyperswitch-sdk-logs"
				disableCSP:    string | *"false"
			}
			nginxConfig: {
				buildImageRegistry: string | *"docker.io"
				extraPath:          string | *"v1"
				image:              string | *"nginx"
				tag:                string | *"1.25.3"
				pullPolicy:         string | *"IfNotPresent"
			}
		}
		imagePullSecrets: [...string] | *[]
		nameOverride:     string | *""
		fullnameOverride: string | *""
		serviceAccount: {
			create:    bool | *true
			automount: bool | *true
			annotations: {[string]: string} | *{}
			name: string | *""
		}
		podAnnotations: {[string]: string} | *{}
		podLabels: {[string]: string} | *{}
		podSecurityContext: corev1.#PodSecurityContext | *{}
		securityContext: corev1.#ContainerSecurityContext | *{}
		service: {
			type: string | *"ClusterIP"
			port: int | *9050
		}
		ingress: {
			enabled:   bool | *true
			className: string | *"nginx"
			annotations: {[string]: string} | *{}
			hosts: [...{
				host?: string
				paths: [...{
					path:     string
					pathType: string
				}]
			}] | *[]
			tls: [...{
				secretName: string
				hosts: [...string]
			}] | *[]
		}
		resources: corev1.#ResourceRequirements | *{
			limits: {
				cpu:    "1500m"
				memory: "3Gi"
			}
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
		}
		autoscaling: {
			enabled:                           bool | *false
			minReplicas:                       int | *1
			maxReplicas:                       int | *5
			targetCPUUtilizationPercentage:    int | *80
			targetMemoryUtilizationPercentage: int | *80
		}
		volumes: [...corev1.#Volume] | *[]
		volumeMounts: [...corev1.#VolumeMount] | *[]
		env: {
			sdkEnv:                string | *"sandbox"
			enableLogging:         string | *"false"
			sdkVersion:            string | *"v1"
			sdkTagVersion:         string | *""
			sentryDsn:             string | *""
			visaApiKeyId:          string | *""
			visaApiCertificatePem: string | *""
		}
		envFrom: [...corev1.#EnvFromSource] | *[]
		nodeSelector: {[string]: string} | *{}
		tolerations: [...corev1.#Toleration] | *[]
		affinity: corev1.#Affinity | *{}
		loadBalancer: {
			targetSecurityGroup: string | *"loadBalancer-sg"
		}
		services: {
			router: {
				host: string | *"http://localhost:8080"
			}
			sdkDemo: {
				imageRegistry:             string | *"docker.juspay.io"
				image:                     string | *"juspaydotin/hyperswitch-web:v0.129.0"
				hyperswitchPublishableKey: string | *"pub_key"
				hyperswitchSecretKey:      string | *"secret_key"
			}
		}
	}

	"hyperswitch-control-center": {
		enabled:          bool | *true
		fullnameOverride: string | *"hyperswitch-control-center"
		dependencies: {
			router: host: string | *"http://localhost:8080"
			sdk: {
				host:       string | *"http://localhost:9050"
				version:    string | *"0.129.0"
				subversion: string | *"v1"
			}
		}
		image: {
			registry:   string | *"docker.juspay.io"
			repository: string | *"juspaydotin/hyperswitch-control-center"
			pullPolicy: string | *"IfNotPresent"
			tag:        string | *"v1.38.2"
		}
		service: {
			type: string | *"ClusterIP"
			port: int | *9000
		}
		resources: requests: {
			cpu:    string | *"100m"
			memory: string | *"100Mi"
		}
		tolerations: [...corev1.#Toleration] | *[]
		...
	}

	disableInternalSecrets: bool | *false
	test: {
		enabled: *false | bool
	}
	...
}

#MergeAnnotations: {
	#global: {[string]: string} | *{}
	#local: {[string]: string} | *{}
	#result: {
		for k, v in #global {"\(k)": v}
		for k, v in #local {"\(k)": v}
	}
}

#Instance: {
	config: #Config

	objects: {
		for name, obj in _objects {
			"\(name)": obj
		}
	}

	tests: {
		for name, obj in _tests {
			"\(name)": obj
		}
	}

	_tests: {
		if config.test.enabled {
			"test-job": #TestJob & {#config: config}
		}
	}

	_objects: {
		"router-config": #RouterTomlConfigMap & {#config: config}
		"router-sa": #RouterServiceAccount & {#config: config}
		"router-svc": #RouterService & {#config: config}
		"router-workload": #RouterWorkload & {#config: config}
		if config."hyperswitch-app".server.ingress.enabled {
			"router-ingress": #RouterIngress & {#config: config}
		}
		if config."hyperswitch-app".autoscaling.enabled {
			"router-hpa": #RouterHPA & {#config: config}
		}

		if config."hyperswitch-app".services.consumer.enabled {
			"consumer-config": #ConsumerConfigMap & {#config: config}
			"consumer-workload": #ConsumerDeployment & {#config: config}
		}

		if config."hyperswitch-app".services.producer.enabled {
			"producer-config": #ProducerConfigMap & {#config: config}
			"producer-workload": #ProducerDeployment & {#config: config}
		}

		if config."hyperswitch-app".services.drainer.enabled {
			"drainer-config": #DrainerConfigMap & {#config: config}
			"drainer-secret": #DrainerSecret & {#config: config}
			"drainer-workload": #DrainerDeployment & {#config: config}
		}

		if config."hyperswitch-app".kafka.enabled {
			"kafka-scripts": #KafkaScripts & {#config: config}
			let k_secrets = #KafkaSecrets & {#config: config}
			"kafka-user-passwords": k_secrets.userPasswords
			for i, sb in k_secrets.serviceBindings {
				"kafka-svcbind-user-\(i)": sb
			}
			if config."hyperswitch-app".kafka.kraft.enabled {
				"kafka-kraft-cluster-id": k_secrets.kraftClusterId
			}
			"kafka-log4j": #KafkaLog4jConfigMap & {#config: config}
			"kafka-svc": #KafkaService & {#config: config}
			if config."hyperswitch-app".kafka.networkPolicy.enabled {
				"kafka-networkpolicy": #KafkaNetworkPolicy & {#config: config}
			}

			// Broker
			let broker = #KafkaBroker & {#config: config}
			"kafka-broker-config-secret": broker.configSecret
			"kafka-broker-configmap":     broker.configMap
			"kafka-broker-sts":           broker.statefulSet
			"kafka-broker-headless-svc":  broker.headlessSvc
			if config."hyperswitch-app".kafka.externalAccess.enabled {
				for i, svc in broker.externalSvcs {
					"kafka-broker-external-svc-\(i)": svc
				}
			}
			if config."hyperswitch-app".kafka.broker.pdb.create {
				for i, p in broker.pdb {
					"kafka-broker-pdb-\(i)": p
				}
			}
			if config."hyperswitch-app".kafka.broker.autoscaling.hpa.enabled {
				for i, h in broker.hpa {
					"kafka-broker-hpa-\(i)": h
				}
			}
			if config."hyperswitch-app".kafka.broker.autoscaling.vpa.enabled {
				for i, v in broker.vpa {
					"kafka-broker-vpa-\(i)": v
				}
			}

			// Controller
			let controller = #KafkaController & {#config: config}
			for i, s in controller.configSecret {
				"kafka-controller-config-secret-\(i)": s
			}
			for i, m in controller.configMap {
				"kafka-controller-configmap-\(i)": m
			}
			for i, sts in controller.statefulSet {
				"kafka-controller-sts-\(i)": sts
			}
			for i, svc in controller.headlessSvc {
				"kafka-controller-headless-svc-\(i)": svc
			}
			for i, svc in controller.externalSvcs {
				"kafka-controller-external-svc-\(i)": svc
			}
			for i, p in controller.pdb {
				"kafka-controller-pdb-\(i)": p
			}
			for i, h in controller.hpa {
				"kafka-controller-hpa-\(i)": h
			}
			for i, v in controller.vpa {
				"kafka-controller-vpa-\(i)": v
			}

			let krb = #KafkaRBAC & {#config: config}
			for i, sa in krb.serviceAccount {"kafka-sa-\(i)": sa}
			for i, r in krb.role {"kafka-role-\(i)": r}
			for i, rb in krb.roleBinding {"kafka-rb-\(i)": rb}

			if config."hyperswitch-app".kafka.metrics.enabled {
				let km = #KafkaMetrics & {#config: config}
				for i, cm in km.jmxConfigMap {"kafka-jmx-cm-\(i)": cm}
				for i, svc in km.jmxService {"kafka-jmx-svc-\(i)": svc}
				for i, sm in km.jmxServiceMonitor {"kafka-jmx-sm-\(i)": sm}
				for i, pr in km.prometheusRule {"kafka-jmx-pr-\(i)": pr}
			}

			// Extra
			let ke = #KafkaExtra & {#config: config}
			for i, e in ke.objects {"kafka-extra-\(i)": e}

			if config."hyperswitch-app".kafka.provisioning.enabled {
				let kp = #KafkaProvisioning & {#config: config}
				"kafka-prov-sa":  kp.serviceAccount
				"kafka-prov-job": kp.job
				if str.Contains(str.ToUpper(config."hyperswitch-app".kafka.listeners.client.protocol), "SSL") && config."hyperswitch-app".kafka.provisioning.auth.tls.passwordsSecret == "" {
					"kafka-prov-tls": kp.tlsSecret
				}
			}

			if config."hyperswitch-app".kafka.zookeeper.enabled {
				let kz = #KafkaZookeeper & {#config: config}
				"kafka-zk-scripts": kz.scriptsConfigMap
				"kafka-zk-svc":     kz.service
				"kafka-zk-h-svc":   kz.headlessService
				"kafka-zk-sts":     kz.statefulSet
				for i, s in kz.serviceAccount {"kafka-zk-sa-\(i)": s}
				for i, p in kz.pdb {"kafka-zk-pdb-\(i)": p}
				for i, n in kz.networkPolicy {"kafka-zk-np-\(i)": n}
				for i, s in kz.authSecret {"kafka-zk-auth-secret-\(i)": s}
				for i, s in kz.quorumSecret {"kafka-zk-quorum-secret-\(i)": s}
				for i, s in kz.tlsSecrets {"kafka-zk-tls-crt-\(i)": s}
				for i, s in kz.tlsPasswordSecrets {"kafka-zk-tls-pass-\(i)": s}
				for i, s in kz.metricsService {"kafka-zk-metrics-svc-\(i)": s}
				for i, s in kz.serviceMonitor {"kafka-zk-sm-\(i)": s}
				for i, s in kz.prometheusRule {"kafka-zk-pr-\(i)": s}
				for i, s in kz.extraDeploy {"kafka-zk-extra-\(i)": s}
				for i, s in kz.configMap {"kafka-zk-cm-list-\(i)": s}
			}
		}

		// Redis
		if config."hyperswitch-app".redis.enabled {
			let redis = config."hyperswitch-app".redis
			"redis-config": #RedisConfigMap & {#config: config}
			"redis-health": #RedisHealthConfigMap & {#config: config}
			"redis-scripts": #RedisScriptsConfigMap & {#config: config}
			"redis-headless-svc": #RedisHeadlessService & {#config: config}
			if redis.auth.enabled && redis.auth.existingSecret == "" {
				"redis-secret": #RedisSecret & {#config: config}
			}
			if redis.serviceBindings.enabled {
				"redis-svcbind": #RedisServiceBindingSecret & {#config: config}
			}
			if redis.serviceAccount.create && !redis.master.serviceAccount.create && !redis.replica.serviceAccount.create {
				"redis-sa": #RedisServiceAccount & {#config: config}
			}
			if redis.metrics.enabled {
				"redis-metrics-svc": #RedisMetricsService & {#config: config}
				if redis.metrics.serviceMonitor.enabled {
					"redis-servicemonitor": #RedisServiceMonitor & {#config: config}
				}
				if redis.metrics.podMonitor.enabled {
					"redis-podmonitor": #RedisPodMonitor & {#config: config}
				}
				if redis.metrics.prometheusRule.enabled {
					"redis-prometheusrule": #RedisPrometheusRule & {#config: config}
				}
			}
			if redis.networkPolicy.enabled {
				"redis-networkpolicy": #RedisNetworkPolicy & {#config: config}
			}
			if redis.pdb.create {
				"redis-pdb": #RedisPDB & {#config: config}
			}
			if redis.rbac.create {
				"redis-role": #RedisRole & {#config: config}
				"redis-rolebinding": #RedisRoleBinding & {#config: config}
			}
			if redis.tls.enabled && redis.tls.autoGenerated && redis.tls.existingSecret == "" {
				"redis-tls-secret": #RedisTLSSecret & {#config: config}
			}
			if redis.master.count > 0 && (redis.architecture != "replication" || !redis.sentinel.enabled) {
				"redis-master-app": #RedisMasterApplication & {#config: config}
				if !redis.sentinel.enabled {
					"redis-master-svc": #RedisMasterService & {#config: config}
				}
				if redis.podSecurityPolicy.create {
					"redis-master-psp": #RedisMasterPSP & {#config: config}
				}
				if redis.architecture == "standalone" && redis.master.kind == "Deployment" && redis.master.persistence.enabled && redis.master.persistence.existingClaim == "" {
					"redis-master-pvc": #RedisMasterPVC & {#config: config}
				}
				if redis.master.serviceAccount.create {
					"redis-master-sa": #RedisMasterServiceAccount & {#config: config}
				}
			}
			if redis.architecture == "replication" && !redis.sentinel.enabled && redis.replica.replicaCount > 0 {
				"redis-replica-app": #RedisReplicasApplication & {#config: config}
				if redis.replica.serviceAccount.create {
					"redis-replica-sa": #RedisReplicasServiceAccount & {#config: config}
				}
			}
			if redis.architecture == "replication" && redis.sentinel.enabled {
				"redis-sentinel-sts": #RedisSentinelStatefulSet & {#config: config}
				"redis-sentinel-svc": #RedisSentinelService & {#config: config}
				"redis-sentinel-ports-cm": #RedisSentinelPortsConfigMap & {#config: config}
				if redis.replica.autoscaling.enabled {
					"redis-sentinel-hpa": #RedisSentinelHPA & {#config: config}
				}
				if redis.sentinel.service.type == "NodePort" {
					for i in list.Range(0, redis.replica.replicaCount, 1) {
						"redis-sentinel-node-svc-\(i)": #RedisSentinelNodeService & {#config: config, #index: i}
					}
				}
			}
			let re = #RedisExtra & {#config: config}
			for i, e in re.objects {"redis-extra-\(i)": e}
		}

		// Clickhouse
		if config."hyperswitch-app".clickhouse.enabled {
			"ch-config": #ClickhouseMainConfigMap & {#config: config}
			"ch-extra-config": #ClickhouseConfigMapExtra & {#config: config}
			"ch-users-config": #ClickhouseConfigMapUsersExtra & {#config: config}
			"ch-scripts": #ClickhouseScriptsConfigMap & {#config: config}
			"ch-script":  #ClickhouseConfigMap & {#config: config}
			"ch-secret": #ClickhouseSecret & {#config: config}
			"ch-sa": #ClickhouseServiceAccount & {#config: config}
			"ch-svc": #ClickhouseService & {#config: config}
			"ch-headless": #ClickhouseServiceHeadless & {#config: config}
			"ch-sts": #ClickhouseStatefulSet & {#config: config}
			"ch-init": #ClickhouseInitJob & {#config: config}

			if config."hyperswitch-app".clickhouse.ingress.enabled {
				"ch-ingress": #ClickhouseIngress & {#config: config}
			}

			if config."hyperswitch-app".clickhouse.zookeeper.enabled {
				"zk-config": #ZookeeperConfigMap & {#config: config}
				"zk-scripts": #ZookeeperScriptsConfigMap & {#config: config}
				"zk-sa": #ZookeeperServiceAccount & {#config: config}
				"zk-svc": #ZookeeperService & {#config: config}
				"zk-headless": #ZookeeperHeadlessService & {#config: config}
				"zk-sts": #ZookeeperStatefulSet & {#config: config}
			}
		}

		// Mailhog
		if config."hyperswitch-app".mailhog.enabled {
			let mh = #Mailhog & {#config: config}
			"mailhog-svc":      mh.service
			"mailhog-workload": mh.deployment
			if mh.authSecret != _|_ {
				"mailhog-auth-secret": mh.authSecret
			}
			if mh.serviceAccount != _|_ {
				"mailhog-sa": mh.serviceAccount
			}
			if mh.ingress != _|_ {
				"mailhog-ingress": mh.ingress
			}
		}

		// Card Vault
		if config."hyperswitch-app"."hyperswitch-card-vault".enabled {
			"cv-config": #CardVaultConfigMap & {#config: config}
			"cv-secrets": #CardVaultSecrets & {#config: config}
			"cv-svc": #CardVaultService & {#config: config}
			"cv-sa": #CardVaultServiceAccount & {#config: config}
			"cv-deployment": #CardVaultDeployment & {#config: config}

			// Card Vault PostgreSQL
			if config."hyperswitch-app"."hyperswitch-card-vault".postgresql.enabled {
				"cv-pg-secret": #CardVaultPostgresqlSecret & {#config: config}

				// Primary
				"cv-pg-primary-cm": #CardVaultPostgresqlPrimaryConfigMap & {#config: config}
				"cv-pg-primary-extended-cm": #CardVaultPostgresqlPrimaryExtendedConfigMap & {#config: config}
				if len(config."hyperswitch-app"."hyperswitch-card-vault".postgresql.primary.initdb.scripts) > 0 {
					"cv-pg-primary-init-cm": #CardVaultPostgresqlPrimaryInitializationConfigMap & {#config: config}
				}
				if len(config."hyperswitch-app"."hyperswitch-card-vault".postgresql.primary.preInitDb.scripts) > 0 {
					"cv-pg-primary-preinit-cm": #CardVaultPostgresqlPrimaryPreinitializationConfigMap & {#config: config}
				}
				"cv-pg-primary-sts": #CardVaultPostgresqlPrimaryStatefulSet & {#config: config}
				"cv-pg-primary-svc": #CardVaultPostgresqlService & {#config: config}
				"cv-pg-primary-headless": #CardVaultPostgresqlHeadlessService & {#config: config}
				if config."hyperswitch-app"."hyperswitch-card-vault".postgresql.primary.pdb.create {
					"cv-pg-primary-pdb": #CardVaultPostgresqlPrimaryPDB & {#config: config}
				}
				if config."hyperswitch-app"."hyperswitch-card-vault".postgresql.metrics.enabled {
					"cv-pg-primary-metrics-svc": #CardVaultPostgresqlPrimaryMetricsService & {#config: config}
					"cv-pg-primary-metrics-cm":  #CardVaultPostgresqlPrimaryMetricsConfigMap & {#config: config}
					if config."hyperswitch-app"."hyperswitch-card-vault".postgresql.metrics.serviceMonitor.enabled {
						"cv-pg-primary-sm": #CardVaultPostgresqlPrimaryServiceMonitor & {#config: config}
					}
				}
				if config."hyperswitch-app"."hyperswitch-card-vault".postgresql.primary.networkPolicy.enabled {
					"cv-pg-primary-np": #CardVaultPostgresqlPrimaryNetworkPolicy & {#config: config}
				}

				// Read
				if config."hyperswitch-app"."hyperswitch-card-vault".postgresql.readReplicas.replicaCount > 0 {
					"cv-pg-read-sts": #CardVaultPostgresqlReadStatefulSet & {#config: config}
					"cv-pg-read-svc": #CardVaultPostgresqlReadService & {#config: config}
					"cv-pg-read-headless": #CardVaultPostgresqlReadHeadlessService & {#config: config}
				}
			}

			// Card Vault Migration Job
			if config."hyperswitch-app"."hyperswitch-card-vault".initDB.enable {
				"cv-pg-migration-job": #CardVaultMigrationJob & {#config: config}
			}
			// Card Vault Keys Job (Dev mode)
			if config."hyperswitch-app"."hyperswitch-card-vault".vaultKeysJob.enabled {
				"cv-vault-keys-job": #CardVaultKeysJobDev & {#config: config}
			}
		}

		// Vector
		if config."hyperswitch-app".vector.enabled {
			"vector-cm": #VectorConfigMap & {#config: config}
			"vector-sa": #VectorServiceAccount & {#config: config}
			if config."hyperswitch-app".vector.role == "Agent" && config."hyperswitch-app".vector.rbac.create {
				"vector-cr": (#VectorRBAC & {#config: config}).clusterRole
				"vector-crb": (#VectorRBAC & {#config: config}).clusterRoleBinding
			}
			if len(config."hyperswitch-app".vector.secrets.generic) > 0 {
				"vector-secret": #VectorSecret & {#config: config}
			}
			if config."hyperswitch-app".vector.service.enabled {
				"vector-svc": #VectorService & {#config: config}
			}
			if config."hyperswitch-app".vector.serviceHeadless.enabled {
				"vector-headless-svc": #VectorHeadlessService & {#config: config}
			}
			if !config."hyperswitch-app".vector.serviceHeadless.enabled && config."hyperswitch-app".vector.service.enabled {
				"vector-headless-svc": #VectorHeadlessServiceLegacy & {#config: config}
			}
			if config."hyperswitch-app".vector.autoscaling.enabled && config."hyperswitch-app".vector.role != "Agent" {
				"vector-hpa": #VectorHPA & {#config: config}
			}
			if config."hyperswitch-app".vector.haproxy.enabled {
				"vector-haproxy-cm": #VectorHAProxyConfigMap & {#config: config}
				"vector-haproxy-deployment": #VectorHAProxyDeployment & {#config: config}
				"vector-haproxy-svc": #VectorHAProxyService & {#config: config}
				if config."hyperswitch-app".vector.haproxy.serviceAccount.create {
					"vector-haproxy-sa": #VectorHAProxyServiceAccount & {#config: config}
				}
				if config."hyperswitch-app".vector.haproxy.autoscaling.enabled {
					"vector-haproxy-hpa": #VectorHAProxyHPA & {#config: config}
				}
			}
			if config."hyperswitch-app".vector.podDisruptionBudget.enabled {
				"vector-pdb": #VectorPDB & {#config: config}
			}
			if config."hyperswitch-app".vector.ingress.enabled {
				"vector-ingress": #VectorIngress & {#config: config}
			}
			if config."hyperswitch-app".vector.podMonitor.enabled {
				"vector-podmonitor": #VectorPodMonitor & {#config: config}
			}
			if config."hyperswitch-app".vector.psp.create {
				"vector-psp": #VectorPSP & {#config: config}
			}
			if config."hyperswitch-app".vector.role == "Agent" {
				"vector-agent": #VectorDaemonSet & {#config: config}
			}
			if config."hyperswitch-app".vector.role == "Stateless-Aggregator" {
				"vector-stateless-aggregator": #VectorDeployment & {#config: config}
			}
			if config."hyperswitch-app".vector.role == "Aggregator" {
				"vector-aggregator": #VectorStatefulSet & {#config: config}
			}
			let ve = #VectorExtra & {#config: config}
			for i, e in ve.objects {"vector-extra-\(i)": e}
		}

		// Miscellaneous
		"router-configs": #RouterConfigMap & {#config: config}
		if !config.disableInternalSecrets {
			"router-secrets": #RouterSecret & {#config: config}
		}

		// DB Migration Job
		if config."hyperswitch-app".initDB.enable {
			"app-db-job": #AppDbJob & {#config: config}
		}

		// Hooks
		"prestart-hook": #PrestartHook & {#config: config}
		"poststart-hook": #PoststartHook & {#config: config}

		// Istio
		if config."hyperswitch-app".istio.enabled {
			"istio-dr": #IstioDestinationRule & {#config: config}
			"istio-vs": #IstioVirtualService & {#config: config}
		}

		// PostgreSQL
		if config."hyperswitch-app".postgresql.enabled {
			let pg = config."hyperswitch-app".postgresql
			if pg.serviceAccount.create {
				"postgresql-sa": #PostgresqlServiceAccount & {#config: config}
			}
			if pg.auth.existingSecret == "" {
				"postgresql-secret": #PostgresqlSecret & {#config: config}
			}
			if pg.serviceBindings.enabled && pg.auth.postgresPassword != "" {
				"postgresql-svcbind-postgres": #PostgresqlSvcBindPostgresSecret & {#config: config}
			}
			if pg.serviceBindings.enabled && pg.auth.password != "" {
				"postgresql-svcbind-custom-user": #PostgresqlSvcBindCustomSecret & {#config: config}
			}
			if pg.tls.enabled && pg.tls.autoGenerated && pg.tls.certificatesSecret == "" {
				"postgresql-tls-secret": #PostgresqlTlsSecret & {#config: config}
			}
			if pg.rbac.create {
				"postgresql-role": #PostgresqlRole & {#config: config}
				"postgresql-rolebinding": #PostgresqlRoleBinding & {#config: config}
			}
			if pg.psp.create {
				"postgresql-psp": #PostgresqlPSP & {#config: config}
			}
			if pg.metrics.enabled && pg.metrics.prometheusRule.enabled {
				"postgresql-prometheus-rule": #PostgresqlPrometheusRule & {#config: config}
			}
			if pg.primary.configuration != "" || pg.primary.pgHbaConfiguration != "" {
				"postgresql-primary-config": #PostgresqlPrimaryConfigMap & {#config: config}
			}
			if pg.primary.extendedConfiguration != "" {
				"postgresql-primary-extended-config": #PostgresqlPrimaryExtendedConfigMap & {#config: config}
			}
			if len(pg.primary.initdb.scripts) > 0 {
				"postgresql-primary-init-config": #PostgresqlPrimaryInitConfigMap & {#config: config}
			}
			if len(pg.primary.preInitDb.scripts) > 0 {
				"postgresql-primary-pre-init-config": #PostgresqlPrimaryPreInitConfigMap & {#config: config}
			}
			if pg.metrics.enabled {
				"postgresql-primary-metrics-svc": #PostgresqlPrimaryMetricsService & {#config: config}
				if pg.metrics.customMetrics != "" {
					"postgresql-primary-metrics-config": #PostgresqlPrimaryMetricsConfigMap & {#config: config}
				}
				if pg.metrics.serviceMonitor.enabled {
					"postgresql-primary-sm": #PostgresqlPrimaryServiceMonitor & {#config: config}
				}
			}
			if pg.primary.networkPolicy.enabled {
				"postgresql-primary-np": #PostgresqlPrimaryNetworkPolicy & {#config: config}
			}
			if pg.primary.pdb.create {
				"postgresql-primary-pdb": #PostgresqlPrimaryPDB & {#config: config}
			}
			"postgresql-primary-headless-svc": #PostgresqlPrimaryHeadlessService & {#config: config}
			"postgresql-primary-svc": #PostgresqlPrimaryService & {#config: config}
			"postgresql-primary-sts": #PostgresqlPrimaryStatefulSet & {#config: config}

			if pg.architecture == "replication" {
				if pg.readReplicas.extendedConfiguration != "" {
					"postgresql-read-extended-config": #PostgresqlReadExtendedConfigMap & {#config: config}
				}
				if pg.metrics.enabled {
					"postgresql-read-metrics-svc": #PostgresqlReadMetricsService & {#config: config}
					if len(pg.metrics.customMetrics) > 0 {
						"postgresql-read-metrics-config": #PostgresqlReadMetricsConfigMap & {#config: config}
					}
					if pg.metrics.serviceMonitor.enabled {
						"postgresql-read-sm": #PostgresqlReadServiceMonitor & {#config: config}
					}
				}
				if pg.readReplicas.networkPolicy.enabled {
					"postgresql-read-np": #PostgresqlReadNetworkPolicy & {#config: config}
				}
				if pg.readReplicas.pdb.create {
					"postgresql-read-pdb": #PostgresqlReadPDB & {#config: config}
				}
				"postgresql-read-sts": #PostgresqlReadStatefulSet & {#config: config}
				"postgresql-read-svc": #PostgresqlReadService & {#config: config}
				"postgresql-read-headless-svc": #PostgresqlReadHeadlessService & {#config: config}
			}

			if pg.backup.enabled {
				if pg.backup.cronjob.storage.enabled && pg.backup.cronjob.storage.existingClaim == "" {
					"postgresql-backup-pvc": #PostgresqlBackupPVC & {#config: config}
				}
				if pg.backup.cronjob.networkPolicy.enabled {
					"postgresql-backup-np": #PostgresqlBackupNetworkPolicy & {#config: config}
				}
				"postgresql-backup-cronjob": #PostgresqlBackupCronJob & {#config: config}
			}
			let pe = #PostgresqlExtra & {#config: config}
			for i, e in pe.objects {"postgresql-extra-\(i)": e}
		}

		// Hyperswitch Control Center
		if config."hyperswitch-app"."hyperswitch-control-center".enabled {
			"cc-cm": #HyperswitchControlCenterConfigMap & {#config: config}
			"cc-deployment": #HyperswitchControlCenterDeployment & {#config: config}
			"cc-svc": #HyperswitchControlCenterService & {#config: config}
			if config."hyperswitch-app"."hyperswitch-control-center".serviceAccount.create {
				"cc-sa": #HyperswitchControlCenterServiceAccount & {#config: config}
			}
			if config."hyperswitch-app"."hyperswitch-control-center".ingress.enabled {
				"cc-ingress": #HyperswitchControlCenterIngress & {#config: config}
			}
			if config."hyperswitch-app"."hyperswitch-control-center".istio.enabled {
				if config."hyperswitch-app"."hyperswitch-control-center".istio.virtualService.enabled {
					"cc-vs": #HyperswitchControlCenterIstioVirtualService & {#config: config}
				}
				if config."hyperswitch-app"."hyperswitch-control-center".istio.destinationRule.enabled {
					"cc-dr": #HyperswitchControlCenterIstioDestinationRule & {#config: config}
				}
			}
		}

		if config."hyperswitch-monitoring".enabled {
			let mon = config."hyperswitch-monitoring"

			// Register CRDs
			for name, obj in monitoringCRDs {
				"monitoring-crd-\(name)": obj
			}
			"monitoring-datasources": #HyperswitchMonitoringGrafanaDatasources & {#config: config}
			"monitoring-payments-dashboard": #HyperswitchGrafanaPaymentsDashboard & {#config: config}
			"monitoring-pod-usage-dashboard": #HyperswitchGrafanaPodUsageDashboard & {#config: config}
			if mon."kube-prometheus-stack".grafana.ingress.enabled {
				"monitoring-grafana-ingress": #HyperswitchGrafanaIngress & {#config: config}
			}

			// Register Grafana sub-chart resources
			for name, obj in (monitoringGrafana & {#config: config}) {
				"monitoring-grafana-\(name)": obj
			}

			// Register Grafana dashboards
			for name, obj in (monitoringGrafanaDashboards & {#config: config}) {
				"monitoring-grafana-dashboard-\(name)": obj
			}
			if mon."kube-prometheus-stack"."kube-state-metrics".enabled {
				for name, obj in (monitoringKubeStateMetrics & {#config: config}) {
					"monitoring-kube-state-metrics-\(name)": obj
				}
			}
			if mon."kube-prometheus-stack"."prometheus-node-exporter".enabled {
				for name, obj in (monitoringPrometheusNodeExporter & {#config: config}) {
					"monitoring-prometheus-node-exporter-\(name)": obj
				}
			}
			if mon."kube-prometheus-stack".alertmanager.enabled {
				for name, obj in (monitoringAlertmanager & {#config: config}) {
					"monitoring-alertmanager-\(name)": obj
				}
			}

			// K8s component exporters
			for name, obj in (monitoringKubeExporters & {#config: config}) {
				"monitoring-kube-exporter-\(name)": obj
			}

			if mon."kube-prometheus-stack".prometheusOperator.enabled {
				for name, obj in (monitoringPrometheusOperator & {#config: config}) {
					"monitoring-prometheus-operator-\(name)": obj
				}
				for name, obj in (monitoringPrometheusOperatorWebhooks & {#config: config}) {
					"monitoring-prometheus-operator-webhook-\(name)": obj
				}
				for name, obj in (monitoringPrometheusOperatorWebhookDeployment & {#config: config}) {
					"monitoring-prometheus-operator-webhook-deploy-\(name)": obj
				}
				for name, obj in (monitoringPrometheusOperatorWebhookPatch & {#config: config}) {
					"monitoring-prometheus-operator-webhook-patch-\(name)": obj
				}
				for name, obj in (monitoringThanosRuler & {#config: config}) {
					"monitoring-thanos-ruler-\(name)": obj
				}
			}

			if mon.loki.enabled {
				for name, obj in (monitoringLokiGrafanaAgentOperator & {#config: config}) {
					"monitoring-loki-gao-\(name)": obj
				}
				if mon.minio.enabled {
					for name, obj in (monitoringLokiMinio & {#config: config}) {
						"monitoring-loki-minio-\(name)": obj
					}
				}
				if mon."rollout-operator".enabled {
					for name, obj in (monitoringLokiRolloutOperator & {#config: config}) {
						"monitoring-loki-rollout-operator-\(name)": obj
					}
				}
				for name, obj in (monitoringLokiCore & {#config: config}) {
					"monitoring-loki-core-\(name)": obj
				}
				for name, obj in (monitoringLokiDistributor & {#config: config}) {
					"monitoring-loki-distributor-\(name)": obj
				}
				for name, obj in (monitoringLokiCompactor & {#config: config}) {
					"monitoring-loki-compactor-\(name)": obj
				}
				for name, obj in (monitoringLokiGateway & {#config: config}) {
					"monitoring-loki-gateway-\(name)": obj
				}
				for name, obj in (monitoringLokiAdminApi & {#config: config}) {
					"monitoring-loki-admin-api-\(name)": obj
				}
				for name, obj in (monitoringLokiBackend & {#config: config}) {
					"monitoring-loki-backend-\(name)": obj
				}

				// for name, obj in (monitoringLokiChunksCache & {#config: config}) {
				// 	"monitoring-loki-chunks-cache-\(name)": obj
				// }
				// for name, obj in (monitoringLokiResultsCache & {#config: config}) {
				// 	"monitoring-loki-results-cache-\(name)": obj
				// }
				for name, obj in (monitoringLokiBloomBuilder & {#config: config}) {
					"monitoring-loki-bloom-builder-\(name)": obj
				}
				for name, obj in (monitoringLokiBloomGateway & {#config: config}) {
					"monitoring-loki-bloom-gateway-\(name)": obj
				}
				for name, obj in (monitoringLokiBloomPlanner & {#config: config}) {
					"monitoring-loki-bloom-planner-\(name)": obj
				}
				for name, obj in (monitoringLokiIndexGateway & {
					#loki:         config."hyperswitch-monitoring".loki
					#indexGateway: config."hyperswitch-monitoring".loki.indexGateway
					#metadata:     config.metadata
				}) {
					"monitoring-loki-index-gateway-\(name)": obj
				}
				for name, obj in (monitoringLokiIngester & {
					#loki:     config."hyperswitch-monitoring".loki
					#ingester: config."hyperswitch-monitoring".loki.ingester
					#metadata: config.metadata
				}) {
					"monitoring-loki-ingester-\(name)": obj
				}
				for name, obj in (monitoringLokiRead & {
					#loki:     config."hyperswitch-monitoring".loki
					#read:     config."hyperswitch-monitoring".loki.read
					#metadata: config.metadata
				}) {
					"monitoring-loki-read-\(name)": obj
				}
				for name, obj in (monitoringLokiResultsCache & {
					#loki:         config."hyperswitch-monitoring".loki
					#resultsCache: config."hyperswitch-monitoring".loki.resultsCache
					#metadata:     config.metadata
				}) {
					"monitoring-loki-results-cache-\(name)": obj
				}
				for name, obj in (monitoringLokiRuler & {
					#loki:     config."hyperswitch-monitoring".loki
					#ruler:    config."hyperswitch-monitoring".loki.ruler
					#metadata: config.metadata
				}) {
					"monitoring-loki-ruler-\(name)": obj
				}
				for name, obj in (monitoringLokiSingleBinary & {
					#loki:         config."hyperswitch-monitoring".loki
					#singleBinary: config."hyperswitch-monitoring".loki.singleBinary
					#metadata:     config.metadata
				}) {
					"monitoring-loki-single-binary-\(name)": obj
				}
				for name, obj in (monitoringLokiTableManager & {
					#loki:         config."hyperswitch-monitoring".loki
					#tableManager: config."hyperswitch-monitoring".loki.tableManager
					#metadata:     config.metadata
				}) {
					"monitoring-loki-table-manager-\(name)": obj
				}
				for name, obj in (monitoringLokiTokengen & {
					#loki:     config."hyperswitch-monitoring".loki
					#metadata: config.metadata
				}) {
					"monitoring-loki-tokengen-\(name)": obj
				}
				for name, obj in (monitoringLokiWrite & {
					#loki:     config."hyperswitch-monitoring".loki
					#write:    config."hyperswitch-monitoring".loki.write
					#metadata: config.metadata
				}) {
					"monitoring-loki-write-\(name)": obj
				}
				for name, obj in (monitoringOpentelemetryCollector & {
					#config: config
				}) {
					"monitoring-otel-collector-\(name)": obj
				}
				for name, obj in (monitoringPromtail & {
					#config: config
				}) {
					"monitoring-promtail-\(name)": obj
				}
				for name, obj in (monitoringLokiCanary & {#config: config}) {
					"monitoring-loki-canary-\(name)": obj
				}
				for name, obj in (monitoringLokiMemcached & {#config: config}) {
					"monitoring-loki-memcached-\(name)": obj
				}
				for name, obj in (monitoringLokiMonitoring & {#config: config}) {
					"monitoring-loki-monitoring-\(name)": obj
				}
				for name, obj in (monitoringLokiPatternIngester & {#config: config}) {
					"monitoring-loki-pattern-ingester-\(name)": obj
				}
				for name, obj in (monitoringLokiProvisioner & {#config: config}) {
					"monitoring-loki-provisioner-\(name)": obj
				}
				for name, obj in (monitoringLokiQuerier & {
					#loki:     config."hyperswitch-monitoring".loki
					#querier:  config."hyperswitch-monitoring".loki.querier
					#metadata: config.metadata
				}) {
					"monitoring-loki-querier-\(name)": obj
				}
				for name, obj in (monitoringLokiQueryFrontend & {
					#loki:          config."hyperswitch-monitoring".loki
					#queryFrontend: config."hyperswitch-monitoring".loki.queryFrontend
					#metadata:      config.metadata
				}) {
					"monitoring-loki-query-frontend-\(name)": obj
				}
				for name, obj in (monitoringLokiQueryScheduler & {
					#loki:           config."hyperswitch-monitoring".loki
					#queryScheduler: config."hyperswitch-monitoring".loki.queryScheduler
					#metadata:       config.metadata
				}) {
					"monitoring-loki-query-scheduler-\(name)": obj
				}
				for name, obj in (hyperswitchUcs & {
					#config: config
				}) {
					"hyperswitch-ucs-\(name)": obj
				}
				for name, obj in (hyperswitchWeb & {
					#config: config
				}) {
					"hyperswitch-web-\(name)": obj
				}
			}
		}
	}
}
