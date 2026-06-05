package main

values: {
	nameOverride:     ""
	fullnameOverride: ""

	labels: {}
	podLabels: {}
	commonAnnotations: {}
	podAnnotations: {}
	imagePullSecrets: []

	serviceAccount: {
		create: true
		name:   ""
		annotations: {}
	}

	hieventsConfig: {
		app: {
			name:                            "Hi.Events"
			env:                             "local"
			debug:                           "false"
			url:                             "http://localhost:8080"
			frontendUrl:                     "http://localhost:8080"
			cdnUrl:                          "http://localhost:8080/storage"
			sanctumStatefulDomains:          "localhost:8080"
			sessionDomain:                   ""
			trustedProxies:                  "*"
			logQueries:                      "false"
			homepageViewsUpdateBatchSize:    8
			allowedInternalWebhookHosts:     ""
			emailLogoUrl:                    ""
			emailLogoLinkUrl:                ""
			disableRegistration:             "false"
			platformSupportEmail:            "support@example.com"
			saasModeEnabled:                 "false"
			saasStripeApplicationFeePercent: "0"
			saasStripeApplicationFeeFixed:   "0"
			stripeConnectAccountType:        "express"
			timezone:                        "UTC"
			locale:                          "en"
			viteApiUrlClient:                "http://localhost:8080/api"
			viteApiUrlServer:                "http://localhost:8080/api"
			viteFrontendUrl:                 "http://localhost:8080"
			port:                            8080
		}
		mail: {
			mailer:      "log"
			driver:      "log"
			host:        ""
			port:        587
			username:    ""
			encryption:  "tls"
			fromAddress: "hello@example.com"
			fromName:    "Hi.Events"
		}
		logging: {
			channel:             "stderr"
			level:               "info"
			deprecationsChannel: ""
		}
		queue: {
			connection:       "redis"
			webhookQueueName: "webhook-queue"
		}
		cache: driver: "redis"
		session: {
			driver:   "redis"
			lifetime: 120
		}
		broadcast: driver: "log"
		jwt: algo:         "HS256"

		storage: {
			driver:           "local"
			disk:             ""
			filesystemDriver: ""
			publicDisk:       ""
			privateDisk:      ""
		}
		postgresql: {
			port:        5432
			database:    "hievents"
			username:    "hievents"
			databaseUrl: ""
		}
		redis: {
			client:        "phpredis"
			port:          6379
			database:      0
			cacheDatabase: 1
			username:      ""
			url:           ""
		}
		s3: {
			region:               "us-east-1"
			publicBucket:         "hievents-public"
			privateBucket:        "hievents-private"
			endpoint:             "http://minio:9000"
			url:                  ""
			usePathStyleEndpoint: "true"
		}
	}

	secrets: {
		app: {
			useExisting: false
			secretName:  "app"
			// Data field name inside the Kubernetes Secret that stores Laravel's APP_KEY value.
			appKeySecretKey:         "app-key"
			appKey:                  "base64:7A8CbXQ6O2V5RzZpTzJvTzJvTzJvTzJvTzJvTzJvTzI="
			jwtSecretKey:            "jwt-secret"
			jwtSecret:               "base64:MjY1Njg5MGFiY2RlZmdoaWpsbW5vcHFyc3R1dnd4eXo="
			stripePublishableKeyKey: "stripe-publishable-key"
			stripePublishableKey:    ""
			stripeSecretKeyKey:      "stripe-secret-key"
			stripeSecretKey:         ""
			stripeWebhookSecretKey:  "stripe-webhook-secret"
			stripeWebhookSecret:     ""
		}
		postgresql: {
			useExisting: false
			secretName:  "postgresql"
			passwordKey: "postgres-password"
			password:    "change-me-please"
		}
		redis: {
			useExisting: false
			secretName:  "redis"
			passwordKey: "redis-password"
			password:    "change-me-please"
		}
		mail: {
			useExisting: false
			secretName:  "mail"
			passwordKey: "mail-password"
			password:    ""
		}
		s3: {
			useExisting:        false
			secretName:         "s3"
			accessKeyIdKey:     "aws-access-key-id"
			secretAccessKeyKey: "aws-secret-access-key"
			accessKeyId:        ""
			secretAccessKey:    ""
		}
	}

	backend: {
		enabled:      true
		replicaCount: 2
		image: {
			registry: "docker.io"
			repository: "daveearley/hi.events-backend"
			tag: "v1.9.0-beta"
			digest: ""
			pullPolicy: "IfNotPresent"
		}
		command: []
		args: []

		service: {type: "ClusterIP", port: 80, targetPort: 8080}
		probes: {
			type: "tcpSocket"
			startup: {periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 30}
			liveness: {initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 3}
			readiness: {initialDelaySeconds: 15, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 10}
		}
		resources: {
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1"
				memory: "1Gi"
			}
		}
		podSecurityContext: {
			fsGroup: 1000
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
		}

		persistence: {
			enabled:       true
			existingClaim: ""
			storageClass:  ""
			accessModes: ["ReadWriteOnce"]
			size:      "10Gi"
			mountPath: "/var/www/html/storage/app"
		}
		nodeSelector: {}
		tolerations: []
		affinity: {}
		topologySpreadConstraints: []

		autoscaling: {
			enabled:                        false
			minReplicas:                    2
			maxReplicas:                    10
			targetCPUUtilizationPercentage: 80
		}

		pdb: {
			enabled:      true
			minAvailable: 1
		}
	}

	frontend: {
		enabled:      true
		replicaCount: 2
		image: {
			registry:   "docker.io"
			repository: "daveearley/hi.events-frontend"
			tag:        "v1.9.0-beta"
			digest:     ""
			pullPolicy: "IfNotPresent"
		}

		env: viteApiUrlServer: ""

		service: {
			type:       "ClusterIP"
			port:       80
			targetPort: 5678
		}

		probes: {
			type: "tcpSocket"
			startup: {periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 30}
			liveness: {initialDelaySeconds: 30, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 5}
			readiness: {initialDelaySeconds: 15, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 10}
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

		podSecurityContext: {
			fsGroup: 1000
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
		}

		nodeSelector: {}
		tolerations: []
		affinity: {}
		topologySpreadConstraints: []

		autoscaling: {
			enabled:                        false
			minReplicas:                    2
			maxReplicas:                    10
			targetCPUUtilizationPercentage: 80
		}

		pdb: {
			enabled:      true
			minAvailable: 1
		}
	}

	webProxy: {
		enabled:      true
		replicaCount: 1
		image: {
			registry:   "docker.io"
			repository: "nginx"
			tag:        "1.27-alpine"
			digest:     ""
			pullPolicy: "IfNotPresent"
		}

		service: {
			type:       "ClusterIP"
			port:       80
			targetPort: 8080
		}
		probes: {
			startup: {periodSeconds: 5, timeoutSeconds: 3, failureThreshold: 12}
			liveness: {initialDelaySeconds: 15, periodSeconds: 10, timeoutSeconds: 3, failureThreshold: 3}
			readiness: {initialDelaySeconds: 5, periodSeconds: 10, timeoutSeconds: 3, failureThreshold: 3}
		}

		resources: {
			requests: {
				cpu:    "50m"
				memory: "64Mi"
			}
			limits: {
				cpu:    "250m"
				memory: "256Mi"
			}
		}
		podSecurityContext: {
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
		}
		nodeSelector: {}
		tolerations: []
		affinity: {}
		topologySpreadConstraints: []
	}

	worker: {
		enabled:      true
		replicaCount: 1
		command: ["php", "artisan", "queue:work"]
		args: ["--queue=default,webhook-queue", "--sleep=3", "--tries=3", "--timeout=60"]
		terminationGracePeriodSeconds: 60
		resources: {requests: {cpu: "100m", memory: "256Mi"}, limits: {cpu: "500m", memory: "768Mi"}}
		podSecurityContext: {}
		securityContext: {}

		nodeSelector: {}
		tolerations: []
		affinity: {}
		topologySpreadConstraints: []

		autoscaling: {
			enabled:                        false
			minReplicas:                    2
			maxReplicas:                    10
			targetCPUUtilizationPercentage: 80
		}
	}

	scheduler: {
		enabled:                    true
		schedule:                   "* * * * *"
		concurrencyPolicy:          "Forbid"
		successfulJobsHistoryLimit: 3
		failedJobsHistoryLimit:     3
		command: ["php", "artisan", "schedule:run"]
		args: ["--no-interaction"]
		resources: {requests: {cpu: "50m", memory: "128Mi"}, limits: {cpu: "250m", memory: "512Mi"}}
		podSecurityContext: {}
		securityContext: {}
	}

	migration: {
		enabled:          true
		useHelmHooks:     false
		hookDeletePolicy: "before-hook-creation,hook-succeeded"
		command: ["sh", "-c"]
		args: ["""
			php artisan migrate --force
			php artisan cache:clear
			php artisan config:clear
			php artisan route:clear
			php artisan view:clear
			php artisan storage:link
			"""]
		resources: {
			requests: {
				cpu: "100m"
				memory: "256Mi"
			}
			limits: {
				cpu: "500m"
				memory: "768Mi"
			}
		}
		podSecurityContext: {}
		securityContext: {}
	}

	initContainers: {
		postgresql: {
			enabled: true
			image: "postgres:17-alpine"
			imagePullPolicy: "IfNotPresent"
		}
		redis: {
			enabled: true
			image: "redis:7-alpine"
			imagePullPolicy: "IfNotPresent"
		}
	}

	postgresql: {
		enabled: true
		image: {
			repository: "postgres"
			tag: "17-alpine"
			pullPolicy: "IfNotPresent"
		}

		persistence: {
			enabled: true
			size: "10Gi"
			storageClass: ""
		}
		service: port: 5432
		resources: {}
	}
	externalDatabase: host: ""

	redis: {
		enabled: true
		image: {
			repository: "docker.io/valkey/valkey"
			tag: "9.1.0-alpine"
			pullPolicy: "IfNotPresent"
		}

		persistence: {
			enabled: true
			size: "2Gi"
			storageClass: ""
		}
		service: port: 6379
		resources: {}
	}
	externalRedis: host: ""

	httpRoute: {
		enabled: false
		annotations: {}
		parentRefs: []
		hostnames: []
		rules: apiPrefix: "/api"
	}

	networkPolicy: enabled: false
	test: enabled:          false
}
