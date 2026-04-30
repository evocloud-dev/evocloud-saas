// REFERENCE: https://github.com/saeid-a/coolify-helm/blob/main/charts/coolify/values.yaml

package main

values: {
	global: {
		namespace:        "coolify"
		registryUrl:      "ghcr.io"
		storageClassName: ""
	}

	coolifyApp: {
		enabled:      true
		replicaCount: 1
		image: {
			repository: "ghcr.io/coollabsio/coolify"
			tag:        "4.0.0-beta.418"
			pullPolicy: "IfNotPresent"
		}
		service: {
			type:       "ClusterIP"
			port:       8000
			targetPort: 8080
		}
		workingDir: "/var/www/html"
		// Database migration configuration
		migration: {
			enabled:    true
			timeout:    300
			runSeeders: true
		}
		// # Add host networking options for Docker socket access
		hostNetwork: enabled: false
		extraHosts: [
			{
				name: "host.docker.internal"
				ip:   "host-gateway"
			},
		]
		resources: {
			limits: {
				memory: "1Gi"
				cpu:    "1000m"
			}
			requests: {
				memory: "512Mi"
				cpu:    "250m"
			}
		}
		healthCheck: {
			enabled:             true
			path:                "/api/health"
			initialDelaySeconds: 30
			periodSeconds:       5
			timeoutSeconds:      2
			failureThreshold:    10
			successThreshold:    1
		}
		php: {
			memoryLimit:          "256M"
			fpmPmControl:         "dynamic"
			fpmPmStartServers:    1
			fpmPmMinSpareServers: 1
			fpmPmMaxSpareServers: 10
			fpmPmMaxChildren:     20
			fpmPmMaxRequests:     500
		}
		podDisruptionBudget: {
			enabled:      true
			minAvailable: 1
			// maxUnavailable: 0
		}
		autoscaling: {
			enabled:                           true
			minReplicas:                       1
			maxReplicas:                       2
			targetCPUUtilizationPercentage:    80
			targetMemoryUtilizationPercentage: 80
		}
		initContainers: {
			setupStorage: resources: {
				limits: {
					memory: "256Mi"
					cpu:    "200m"
				}
				requests: {
					memory: "128Mi"
					cpu:    "100m"
				}
			}
			migration: resources: {
				limits: {
					memory: "512Mi"
					cpu:    "500m"
				}
				requests: {
					memory: "256Mi"
					cpu:    "100m"
				}
			}
		}
	}

	postgresql: {
		enabled: true
		auth: {
			existingSecret: "coolify-postgresql"
			secretKeys: {
				adminPasswordKey: "postgres-password"
				userPasswordKey:  "password"
			}
			postgresPassword: "postgrespassword"
			username:         "coolify"
			password:         "coolifypassword"
			database:         "coolify"
		}
		primary: {
			image: {
				repository: "postgres"
				tag:        "15-alpine"
				pullPolicy: "IfNotPresent"
			}
			persistence: {
				enabled:     true
				size:        "8Gi"
				accessModes: ["ReadWriteOnce"]
				storageClass: ""
			}
			resources: {}
			securityContext: {
				enabled:                true
				readOnlyRootFilesystem: false
			}
		}
		healthCheck: {
			enabled:             true
			initialDelaySeconds: 10
			periodSeconds:       5
			timeoutSeconds:      2
			failureThreshold:    10
		}
	}

	redis: {
		enabled:      true
		architecture: "standalone"
		auth: {
			enabled:                   true
			sentinel:                  true
			existingSecret:            "coolify-redis"
			existingSecretPasswordKey: "redis-password"
			password:                  "coolifyredis"
		}
		image: {
			repository: "valkey/valkey"
			tag:        "8.1-alpine"
			pullPolicy: "IfNotPresent"
		}
		master: {
			persistence: enabled: true
			resources: {}
		}
		replica: {
			replicaCount: 0
			persistence: enabled: false
		}
		persistence: {
			enabled:          true
			size:             "2Gi"
			accessModes:      ["ReadWriteOnce"]
			storageClassName: ""
		}
		service: ports: redis: 6379
		commonConfiguration: """
			save 20 1
			loglevel warning
			"""
	}

	soketi: {
		enabled:      true
		replicaCount: 1
		image: {
			repository: "ghcr.io/coollabsio/coolify-realtime"
			tag:        "1.0.13"
			pullPolicy: "Always"
		}
		service: {
			type:        "ClusterIP"
			appPort:     6001
			metricsPort: 6002
		}
		debug: false
		resources: {
			limits: {
				memory: "512Mi"
				cpu:    "500m"
			}
			requests: {
				memory: "256Mi"
				cpu:    "100m"
			}
		}
		healthCheck: {
			enabled:             true
			initialDelaySeconds: 10
			periodSeconds:       5
			timeoutSeconds:      2
			failureThreshold:    10
		}
		extraHosts: [
			{
				name: "host.docker.internal"
				ip:   "host-gateway"
			},
		]
	}

	config: {
		APP_NAME:                 "Coolify"
		APP_ENV:                  "production"
		APP_URL:                  "http://localhost:8000"
		APP_DEBUG:                false
		DB_DATABASE:              "coolify"
		PHP_MEMORY_LIMIT:         "256M"
		PHP_FPM_PM_CONTROL:       "dynamic"
		PHP_FPM_PM_START_SERVERS: 1
		PHP_FPM_PM_MIN_SPARE_SERVERS: 1
		PHP_FPM_PM_MAX_SPARE_SERVERS: 10
		SOKETI_DEBUG:             false
		DB_CONNECTION:            "pgsql"
		DB_HOST:                  ""
		DB_PORT:                  5432
		REDIS_HOST:               ""
		REDIS_PORT:               6379
		REGISTRY_URL:             "ghcr.io"
		APP_OPTIMIZE:             true
		VIEW_COMPILED_PATH:       "/var/www/html/storage/framework/views"
		SESSION_LIFETIME:         120
		SANCTUM_STATEFUL_DOMAINS: "localhost:8000,127.0.0.1:8000"
	}

	secrets: {
		APP_ID:             "coolify-instance"
		APP_KEY:            "base64:xZW/NBFucHhBaBybNsgXJzy83TcC6atI8PuzAUbh638="
		ROOT_USERNAME:      "admin"
		ROOT_USER_EMAIL:    "admin@gmail.com"
		ROOT_USER_PASSWORD: "Changeit@123."
		DB_USERNAME:        "coolify"
		DB_PASSWORD:        "coolifypassword"
		REDIS_PASSWORD:     "coolifyredis"
		PUSHER_APP_ID:      ""
		PUSHER_APP_KEY:     ""
		PUSHER_APP_SECRET:  ""
	}

	sharedDataPvc: {
		name:             ""
		size:             "1Gi"
		accessModes:      ["ReadWriteOnce"]
		storageClassName: ""
	}

	securityContext: {
		enabled:                  true
		fsGroup:                  0
		runAsUser:                0
		runAsGroup:               0
		runAsNonRoot:             false
		allowPrivilegeEscalation: true
		readOnlyRootFilesystem:   false
		capabilities: {
			drop: ["ALL"]
			add: ["CHOWN", "SETUID", "SETGID", "DAC_OVERRIDE", "FOWNER", "SETPCAP"]
		}
	}

	networkPolicy: {
		enabled: true
		ingress: []
		egress: []
	}

	serviceMonitor: {
		enabled:   true
		namespace: ""
		labels: {}
	}

	ingress: {
		enabled:     false
		className:   ""
		annotations: {}
		hosts: [
			{
				host: "coolify.local"
				paths: [
					{
						path:     "/"
						pathType: "Prefix"
					},
				]
			},
		]
		tls: []
	}
}
