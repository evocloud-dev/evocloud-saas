// Default values for peertube-helm.
// This is a YAML-formatted file.
// Declare variables to be passed into your templates.
package main

values: {
	global: {
		image: {
			registry:   null
			pullPolicy: "IfNotPresent"
		}
		// Global list of Image pull secrets.
		// When set, it overrides any imagePullSecrets defined in other components of the chart
		imagePullSecrets: []

		// Override the name of the chart.
		nameOverride:      null
		// Override the expanded name of the chart.
		fullnameOverride:  null
		// Override the target namespace for the chart.
		namespaceOverride: null
		// Additional container environment variables to apply to all containers and init containers
		extraEnvVars: []
		// - name: TZ
		//   value: Europe/Berlin

		// Global List of node taints to tolerate.
		// Non-global values will override the global value.
		// See: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration
		tolerations: []

		// Global node labels for pod assignment.
		// Non-global values will override the global value.
		nodeSelector: {}
	}

	server: {
		enabled:  true
		replicas: 1

		// Image pull secrets
		imagePullSecrets: []
		// - name: secretName

		container: {
			image: {
				registry:   "docker.io"
				repository: "chocobozzz/peertube"
				// If missing, defaults to image.pullPolicy
				pullPolicy: null
				// Overrides the image tag whose default is the chart appVersion
				tag:        "v8.2.2"
			}
			resources: {
				requests: {
					cpu:    "100m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
			securityContext: {
				runAsNonRoot:             true
				privileged:               false
				allowPrivilegeEscalation: false
				readOnlyRootFilesystem:   true
				capabilities: drop: ["ALL"]
				seccompProfile: type: "RuntimeDefault"
			}
			// Additional container environment variables.
			extraEnvVars: [
				{
					// Forces Node.js to use IPv4 DNS resolution first to bypass Happy Eyeballs timeouts 
					// when communicating with the external plugin index registry in clusters without IPv6 routing.
					name:  "NODE_OPTIONS"
					value: "--dns-result-order=ipv4first --no-network-family-autoselection"
				},
				{
					// Redirects HOME to the persistent writeable mount (/data) to allow plugin installation 
					// cache initialization (pnpm) under readOnlyRootFilesystem: true.
					name:  "HOME"
					value: "/data"
				},
				// - name: TZ
				//   value: Europe/Berlin
			]
			// Extra arguments passed to the container on the command line
			extraArgs: {}
		}

		// Array of extra containers to run alongside peertube
		extraContainers: []
		// - name: myapp-container
		//   image: busybox
		//   command: ['sh', '-c', 'echo Hello && sleep 3600']
		// Deployment annotations
		annotations: {}

		// Additional annotations to add to each pod
		podAnnotations: {}
		// annotation: foo

		// Additional labels to add to each pod
		podLabels: {}
		// label: foo

		// Security context for the pod
		podSecurityContext: {
			runAsUser:  65510
			runAsGroup: 65510
			fsGroup:    65510
		}

		podDisruptionBudget: {
			enabled:                    true
			// Cannot be used if `maxUnavailable` is set
			minAvailable:               1
			// Cannot be used if `minAvailable` is set
			maxUnavailable:             null
			// Unhealthy pod eviction policy to be used
			// Possible values are `IfHealthyBudget` or `AlwaysAllow`
			unhealthyPodEvictionPolicy: null
		}

		// List of node taints to tolerate
		tolerations: []
		// Node labels for pod assignment
		nodeSelector: {}

		antiAffinity: {
			// Pod antiAffinities toggle
			// Enabled by default but can be disabled if you want to schedule pods to the same node
			enabled: true
		}

		// Pod anti affinity constraints
		podAntiAffinity: {
			preferredDuringSchedulingIgnoredDuringExecution: [
				{
					weight: 1
					podAffinityTerm: {
						labelSelector: matchExpressions: [
							{
								key:      "app.kubernetes.io/component"
								operator: "In"
								values: [
									"server",
								]
							},
						]
						topologyKey: "kubernetes.io/hostname"
					}
				},
			]
		}

		// Pod affinity constraints
		podAffinity: {}

		// Node affinity constraints
		nodeAffinity: {}

		grafana: {
			namespace: null
			annotations: {}
			labels: {}
			// Create GrafanaDashboard custom resource referencing to the configMap
			grafanaDashboard: {
				enabled:                   true
				folder:                    "peertube"
				allowCrossNamespaceImport: true
				matchLabels: dashboards: "grafana"
			}
			dashboards: {
				metrics: {
					createConfigMap: true
					configMapName:   "peertube-grafana-metrics"
				}
			}
		}

		containerPort: 9000
		metricsPort:   9091
		rtmpPort:      1935
		rtmpsPort:     1936

		config: {
			createConfigMap: true
			// Required if `createConfigMap` is false.
			configMapName:   null
			configMapAnnotations: {}
			// argocd.argoproj.io/sync-options: Replace=true

			admin: {
				password:       "MySuperSecretPassword123"
				existingSecret: ""
			}
			secrets: {
				peertube:       "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
				existingSecret: ""
			}
			raw: """
				listen:
				  hostname: 
				  port: 9000
				trust_proxy:
				  - 'loopback'
				webserver:
				""" +
				// Set to false for local testing/port-forwarding, true for production HTTPS.
				"""

				  https: false
				""" +
				// The external domain/host name of your PeerTube instance. Set to "localhost" for local port-forwarding.
				"""

				  hostname: "localhost"
				""" +
				// The external port. Set to 9000 for local port-forwarding, 443 for standard HTTPS.
				"""

				  port: 9000
				log:
				  level: info
				open_telemetry:
				  metrics:
				    enabled: false
				    playback_stats_interval: "15 seconds"
				    http_request_duration:
				      enabled: false
				    prometheus_exporter:
				      hostname: "0.0.0.0"
				      port: 9091
				admin:
				  email: 'admin@example.com'
				live:
				  enabled: false
				  rtmp:
				    enabled: true
				    hostname: 0.0.0.0
				    port: 31935
				  rtmps:
				    enabled: false
				    hostname: 0.0.0.0
				    port: 31936
				"""
		}

		// transcoding:
		//   enabled: true
		//
		//   ## This setting should match components.runner.enabled
		//   remote_runners:
		//     enabled: true
		//
		//   threads: 1
		//   concurrency: 1
		//
		// instance:
		//   name: "Peertube"
		//   short_description: "PeerTube, an ActivityPub-federated video streaming platform using P2P directly in your web browser."
		//   description: "Welcome to this PeerTube instance!"
		//
		// video_transcription:
		//   enabled: true
		//   engine: 'whisper-ctranslate2'
		//   remote_runners:
		//     enabled: true

		objectStorage: {
			enabled:        false
			// Object storage config
			// Ref: https://github.com/Chocobozzz/PeerTube/blob/develop/config/default.yaml#L157
			// `credentials` must not be defined in values.yaml
			// When `object_storage.enabled: true` you must provide existingSecret
			config: null
			// config: {
			// 	endpoint: ""
			// 	upload_acl: {
			// 		public: "public-read"
			// 		private: "private"
			// 	}
			// 	web_videos: {
			// 		bucket_name: "web-videos"
			// 		prefix: ""
			// 		base_url: ""
			// 	}
			// }

			// The name of an existing secret with credentials (must contain key `access-key-id` and `secret-access-key`)
			existingSecret: ""
		}

		externalPostgres: {
			hostname:       ""
			port:           5432
			ssl:            false
			suffix:         ""
			db:             ""
			username:       ""
			password:       ""
			// The name of an existing secret with Postgres (must contain key `postgres-password` and `postgres-username` if username is not `default`) and Sentinel credentials
			// If set, the `externalPostgres.username` and `externalPostgres.password` parameters are ignored
			existingSecret: ""
			pool: max: 5
		}

		externalRedis: {
			hostname:       ""
			port:           6379
			db:             0
			password:       ""
			// The name of an existing secret with Redis (must contain key `redis-password`) and Sentinel credentials
			// If set, the `externalRedis.username` parameter is ignored
			existingSecret: ""
			sentinel: {
				enabled:   false
				enableTls: false
			}
		}

		service: {
			type: "ClusterIP"
			// Service annotations
			annotations: {}
			// Works only if `service.type` is set to "NodePort"
			nodePort: null
			port: 9000
			appProtocol: ""
			// Service traffic distribution policy
			// Set to `PreferClose` to route traffic to nearby endpoints, reducing latency and cross-zone costs
			trafficDistribution: null
		}

		metricsService: {
			create:   true
			port:     9091
			type:     "ClusterIP"
			// Only used if `type` is `NodePort`
			nodePort: null
			annotations: {}
			appProtocol:         ""
			// Service traffic distribution policy
			// Set to `PreferClose` to route traffic to nearby endpoints, reducing latency and cross-zone costs
			trafficDistribution: null
		}

		liveService: {
			create:        true
			portRtmp:      1935
			portRtmps:     1936
			type:          "NodePort"
			// Only used if `type` is `NodePort`
			nodePortRtmp:  31935
			// Only used if `type` is `NodePort`
			nodePortRtmps: 31936
			annotations: {}
			appProtocol: ""
			// Service traffic distribution policy
			// Set to `PreferClose` to route traffic to nearby endpoints, reducing latency and cross-zone costs
			trafficDistribution: null
		}

		serviceMonitor: {
			enabled: false
			additionalAnnotations: {}
			additionalLabels: {}
			namespace: null
			interval:      "30s"
			scrapeTimeout: "25s"
			secure:        false
			tlsConfig: {}
			relabelings: []
			metricRelabelings: []
		}

		// Change `hostNetwork` to `true` when you want the pod to share its host's network namespace
		// Update the `dnsPolicy` accordingly as well to suit the host network mode
		hostNetwork: false

		// `dnsPolicy` determines the manner in which DNS resolution happens in the cluster
		// In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`
		// See: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy
		dnsPolicy: null

		// `dnsConfig` allows to specify DNS configuration for the pod
		dnsConfig: null
		// dnsConfig: {
		// 	nameservers: [
		// 		"8.8.8.8"
		// 	]
		// 	options: [
		// 		{
		// 			name: "ndots"
		// 			value: "2"
		// 		},
		// 		{
		// 			name: "edns0"
		// 		}
		// 	]
		// }

		persistence: {
			enabled: true
			annotations: {}
			size:          "200Gi"
			storageClass:  ""
			volumeName:    ""
			accessMode:    "ReadWriteOnce"
			// Use existing PVC instead of creating new one
			existingClaim: ""
		}

		rbac: {
			create: true
		}

		serviceAccount: {
			create: true
			name:   ""
			annotations: {}
		}

		// Enables network rules for server pods
		networkPolicy: {
			enabled: false
			ingress: []
			egress: []
		}

		topologySpreadConstraints: []

		// See `kubectl explain deployment.spec.strategy` for more information
		// https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
		deploymentStrategy: {
			type: "RollingUpdate"
		}

		// Deployment update strategy
		// See: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
		updateStrategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       1
				maxUnavailable: "40%"
			}
		}

		// Horizontal Pod Autoscaler
		// Enable only with proper HA setup (Redis adapter, CDN)
		// See: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
		autoscaling: {
			enabled:     true
			minReplicas: 1
			maxReplicas: 3
			metrics: {}
			behavior: {}
		}

		// Vertical Pod Autoscaler
		// See: https://kubernetes.io/docs/concepts/workloads/autoscaling/#scaling-workloads-vertically/
		vpa: {
			enabled: true
			annotations: {}
			// Possible values: Off, Initial, Auto
			updateMode: "Initial"
			resourcePolicy: {}
			// - containerName: peertube
			//   minAllowed:
			//     cpu: "200m"
			//     memory: "512Mi"
			//   maxAllowed:
			//     cpu: "2"
			//     memory: "2Gi"
			//   controlledResources: ["cpu","memory"]
		}

		ingress: {
			enabled:          false
			ingressClassName: ""
			annotations: {}

			// Hosts must be provided if Ingress is enabled
			hosts: []
			// - peertube.domain.com
			path:     "/"
			// For Kubernetes >=1.18 you should specify the pathType: https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types
			pathType: "Prefix"
			// Enable TLS configuration for the hostname defined at `peertube.baseUrl`
			// TLS certificate will be retrieved from a TLS secret `peertube-server-tls`
			// You can create this secret via `certificate` or `certificateSecret` option
			tls:      false
			// The list of additional hostnames to be covered by ingress record
			extraHosts: []
			// Extra paths to prepend to every host configuration
			// This is useful when working with annotation based services
			extraPaths: []
			// Additional ingress rules
			// Can be templated
			extraRules: []
			// Additional TLS configuration
			extraTls: []
		}

		// Enables Gateway API HTTPRoute
		httpRoute: {
			enabled: true
			annotations: {}
			parentRefs: []
			// - name: my-gateway
			//   namespace: gateway-system
			//   sectionName: https
			hostnames: []
			// - peertube.domain.com
			matches: []
			// Can be templated
			filters: []
			// Can be templated
			extraRules: []
		}

		// Enables Gateway API TCPRoute for the live (RTMP/RTMPS) service
		tcpRoute: {
			enabled: true
			annotations: {}
			rtmp: {
				enabled: true
				parentRefs: []
				// - name: my-tcp-gateway
				//   namespace: gateway-system
				//   sectionName: rtmp
			}
			rtmps: {
				enabled: true
				parentRefs: []
				// - name: my-tcp-gateway
				//   namespace: gateway-system
				//   sectionName: rtmps
			}
		}

		certificate: {
			enabled: false
			// Certificate primary domain (commonName)
			// Defaults to first host defined in `ingress.hosts`
			domain:  ""
			// Certificate Subject Alternate Names (SANs)
			additionalHosts: []
			// The requested 'duration' (i.e. lifetime) of the certificate
			// Defaults to 2160h = 90d if not specified
			// See: https://cert-manager.io/docs/usage/certificate
			duration:    ""
			// How long before expiration should a certificate be renewed
			// Defaults to 360h = 15d if not specified
			// See: https://cert-manager.io/docs/usage/certificate
			renewBefore: ""
			// Certificate issuer
			// https://cert-manager.io/docs/concepts/issuer
			issuer: {
				// Issuer group (mandatory for external issuer `cert-manager.io`)
				group: ""
				// Issuer type: `Issuer` or `ClusterIssuer`
				kind:  ""
				// Issuer name.
				name:  ""
			}
			// Private key of the certificate
			privateKey: {
				// Rotation policy of private key when certificate is re-issued
				// Possible values are: `Never` or `Always`
				rotationPolicy: "Never"
				// The PKCS encoding for private key
				// Possible values are: `PCKS1` or `PKCS8`
				encoding:       "PKCS1"
				// Algorithm used to generate certificate private key
				// Possible values are: `RSA`, `Ed25519` or `ECDSA`
				algorithm:      "RSA"
				// Key bit size of the private key
				// If algorithm is set to `Ed25519`, size is ignored
				size:           2048
			}
			// Certificate annotations
			annotations: {}
			// Allowed key usages.
			// Ref: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.KeyUsage
			usages: []
			// Annotations for composing certificate from existing kubernetes resources
			secretTemplateAnnotations: {}
		}

		// TLS certificate configuration via Secret
		certificateSecret: {
			// Create `peertube-server-tls` secret
			enabled: false
			// `peertube-server-tls` annotations
			annotations: {}
			// Private Key of the certificate
			key: ""
			// Certificate data
			crt: ""
		}

		startupProbe: {
			httpGet: {
				path:   "/api/v1/ping"
				port:   "server"
				scheme: "HTTP"
			}
			failureThreshold:    20
			initialDelaySeconds: 2
			periodSeconds:       6
		}

		livenessProbe: {
			httpGet: {
				path:   "/api/v1/ping"
				port:   "server"
				scheme: "HTTP"
			}
			initialDelaySeconds: 30
			periodSeconds:       30
			timeoutSeconds:      5
			failureThreshold:    2
			successThreshold:    1
		}

		readinessProbe: {
			httpGet: {
				path:   "/api/v1/ping"
				port:   "server"
				scheme: "HTTP"
			}
			initialDelaySeconds: 5
			periodSeconds:       10
			timeoutSeconds:      5
			failureThreshold:    6
			successThreshold:    1
		}

		revisionHistoryLimit: 10
		priorityClassName:    ""
	}

	runner: {
		// Set to `true` if at least one `remote_runners` has `enabled: true` in server's config
		enabled: true

		// Image pull secrets
		imagePullSecrets: []
		// - name: secretName

		persistence: {
			enabled: true
			annotations: {}
			size:          "20Gi"
			storageClass:  ""
			volumeName:    ""
			accessMode:    "ReadWriteOnce"
			// Use existing PVC instead of creating new one
			existingClaim: ""
		}

		serviceAccount: {
			create: true
			name:   ""
			annotations: {}
		}

		// Enables network rules for runner pods
		networkPolicy: {
			enabled: false
			ingress: []
			egress: []
		}

		initContainer: {
			image: {
				registry:   "docker.io"
				repository: "zendet/peertube-runner"
				pullPolicy: "IfNotPresent"
				tag:        "0.4.0-ctranslate2"
			}
			resources: {
				requests: {
					cpu:    "200m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
			// Additional container environment variables.
			extraEnvVars: []
			// - name: TZ
			//   value: Europe/Berlin
		}

		container: {
			image: {
				registry:   "docker.io"
				repository: "zendet/peertube-runner"
				pullPolicy: "IfNotPresent"
				tag:        "0.4.0-ctranslate2"
			}
			resources: {
				requests: {
					cpu:    "200m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
			// Additional container environment variables.
			extraEnvVars: []
			// - name: TZ
			//   value: Europe/Berlin
		}

		// Array of extra init containers
		extraInitContainers: []
		// - name: init-container
		//   image: busybox
		//   command: ['sh', '-c', 'echo Hello']

		// Array of extra containers to run alongside peertube
		extraContainers: []
		// - name: myapp-container
		//   image: busybox
		//   command: ['sh', '-c', 'echo Hello && sleep 3600']

		// StatefulSet annotations
		annotations: {}

		// Additional annotations to add to each pod
		podAnnotations: {}
		// annotation: foo

		// Additional labels to add to each pod
		podLabels: {}
		// label: foo

		// Security context for the pod
		podSecurityContext: {
			runAsUser:  999
			runAsGroup: 999
			fsGroup:    999
		}

		// Change `hostNetwork` to `true` when you want the pod to share its host's network namespace
		// Update the `dnsPolicy` accordingly as well to suit the host network mode
		hostNetwork: false

		// `dnsPolicy` determines the manner in which DNS resolution happens in the cluster
		// In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`
		// See: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy
		dnsPolicy: null

		// `dnsConfig` allows to specify DNS configuration for the pod
		dnsConfig: null
		// dnsConfig: {
		// 	nameservers: [
		// 		"8.8.8.8"
		// 	]
		// 	options: [
		// 		{
		// 			name: "ndots"
		// 			value: "2"
		// 		},
		// 		{
		// 			name: "edns0"
		// 		}
		// 	]
		// }

		service: {
			annotations: {}
		}

		// KEDA ScaledObject for runner queue-based scaling
		kedaDefaults: {
			enabled:         true
			minReplicas:     1
			maxReplicas:     20
			cooldownPeriod:  300 // Global cooldown period in seconds
			pollingInterval: 30  // Polling interval in seconds

			// PostgreSQL scaler
			// See: https://keda.sh/docs/2.18/scalers/postgresql
			postgresql: {
				host:     ""
				port:     "5432"
				userName: "peertube"
				dbName:   "peertube"
				sslmode:  "disable"
				// 1 replica per N pending jobs
				targetQueryValue: "1"
				existingSecret:   ""
				passwordKey:      "postgres-password"
				// Full SQL override (must return a single integer)
				query: "SELECT COALESCE(COUNT(*),0)::integer FROM \"runnerJob\" WHERE state IN (1, 5) AND \"type\" IN ('vod-web-video-transcoding', 'vod-hls-transcoding', 'vod-audio-merge-transcoding')"
			}

			// Advanced HPA behavior configuration
			// advanced: {
			// 	horizontalPodAutoscalerConfig: {
			// 		behavior: {
			// 			scaleDown: {
			// 				stabilizationWindowSeconds: 300
			// 				policies: [
			// 					{
			// 						type: "Percent"
			// 						value: 50
			// 						periodSeconds: 60
			// 					}
			// 				]
			// 			}
			// 			scaleUp: {
			// 				stabilizationWindowSeconds: 30
			// 				policies: [
			// 					{
			// 						type: "Percent"
			// 						value: 100
			// 						periodSeconds: 30
			// 					}
			// 				]
			// 			}
			// 		}
			// 	}
			// }

			// Fallback CPU scaling
			cpu: {
				enabled:                        true
				targetCPUUtilizationPercentage: 80
			}
		}

		podDisruptionBudget: {
			enabled:                    true
			// Cannot be used if `maxUnavailable` is set
			minAvailable:               1
			// Cannot be used if `minAvailable` is set
			maxUnavailable:             null
			// Unhealthy pod eviction policy to be used
			// Possible values are `IfHealthyBudget` or `AlwaysAllow`
			unhealthyPodEvictionPolicy: null
		}

		// List of node taints to tolerate
		tolerations: []
		// Node labels for pod assignment
		nodeSelector: {}

		antiAffinity: {
			// Pod antiAffinities toggle
			// Enabled by default but can be disabled if you want to schedule pods to the same node
			enabled: true
		}

		// Pod anti affinity constraints
		podAntiAffinity: {
			preferredDuringSchedulingIgnoredDuringExecution: [
				{
					weight: 1
					podAffinityTerm: {
						labelSelector: matchExpressions: [
							{
								key:      "app.kubernetes.io/component"
								operator: "In"
								values: [
									"runner",
								]
							},
						]
						topologyKey: "kubernetes.io/hostname"
					}
				},
			]
		}

		// Pod affinity constraints.
		podAffinity: {}

		// Node affinity constraints.
		nodeAffinity: {}

		startupProbe: {
			exec: {
				command: [
					"sh",
					"-ec",
					"id=\"${RUNNER_GROUP_ID}-$(echo \"$POD_NAME\" | sed 's/.*-//')\"\ntimeout 2 peertube-runner --id \"$id\" list-registered >/dev/null\n",
				]
			}
			failureThreshold: 60
			periodSeconds:    2
			timeoutSeconds:   3
		}

		livenessProbe: {
			exec: {
				command: [
					"sh",
					"-ec",
					"id=\"${RUNNER_GROUP_ID}-$(echo \"$POD_NAME\" | sed 's/.*-//')\"\ntimeout 2 peertube-runner --id \"$id\" list-registered >/dev/null\n",
				]
			}
			periodSeconds:    30
			timeoutSeconds:   3
			failureThreshold: 2
		}

		readinessProbe: {
			exec: {
				command: [
					"sh",
					"-ec",
					"id=\"${RUNNER_GROUP_ID}-$(echo \"$POD_NAME\" | sed 's/.*-//')\"\ntimeout 2 peertube-runner --id \"$id\" list-registered >/dev/null\n",
				]
			}
			periodSeconds:    10
			timeoutSeconds:   3
			failureThreshold: 3
		}

		// Vertical Pod Autoscaler.
		vpa: {
			enabled:    true
			updateMode: "Initial"
			resourcePolicy: {
				containerPolicies: [
					{
						containerName: "runner"
						controlledResources: ["cpu", "memory"]
						minAllowed: {
							cpu:    "500m"
							memory: "1Gi"
						}
						maxAllowed: {
							cpu:    "4"
							memory: "8Gi"
						}
						controlledValues: "RequestsOnly"
					},
				]
			}
		}

		runnerGroups: [
			{
				name:     "VOD Transcoding Runners"
				id:       "vod"
				replicas: 1
				jobTypes: [
					"vod-web-video-transcoding",
					"vod-hls-transcoding",
					"vod-audio-merge-transcoding",
				]
				keda: {
					enabled:     true
					maxReplicas: 10
				}
				config: {
					// The PeerTube runner registration token.
					// Retrieve this token from the Admin UI by going to:
					// Administration -> Runners -> Remote runners -> Click "Runner registration tokens"
					registrationToken: "ptrrt-16249b22-ddb7-4b00-8ca2-de0c496ae0a0"
					createConfigMap: true
					// Required if `createConfigMap` is false.
					configMapName:   null
					configMapAnnotations: {}
					// Run peertube-runner unregister [...] instead of graceful-shutdown
					unregisterOnExit: false
					// Raw configuration for runner, will be converted into TOML
					// See: https://docs.joinpeertube.org/maintain/tools#configuration
					// Omit the `registeredInstances` section
					// Can be templated.
					raw: """
						jobs:
						  concurrency: 2
						ffmpeg:
						  threads: 0
						  nice: 20
						transcription:
						  engine: whisper-ctranslate2
						  enginePath: /usr/local/bin/whisper-ctranslate2
						  model: large-v2
						"""
					// The name of an existing secret with runner token (must contain key `registration-token` and `runner-url`).
					existingSecret: ""
				}
			},
		]
	}

	postgresql: {
		enabled: true
		image: {
			registry:   "docker.io"
			repository: "postgres"
			tag:        "16-alpine"
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
		}
		persistence: {
			enabled:      true
			size:         "10Gi"
			storageClass: ""
			accessModes: ["ReadWriteOnce"]
			existingClaim: ""
		}
		service: {
			port: 5432
		}
	}

	redis: {
		enabled: true
		image: {
			registry:   "docker.io"
			repository: "redis"
			tag:        "7-alpine"
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
		persistence: {
			enabled:      true
			size:         "5Gi"
			storageClass: ""
			accessModes: ["ReadWriteOnce"]
			existingClaim: ""
		}
		service: {
			port: 6379
		}
	}
}
