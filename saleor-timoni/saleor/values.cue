package main

// REFERENCE: https://github.com/trieb-work/helm-charts/blob/main/charts/saleor/values.yaml

values: {
	global: {
		imagePullSecrets: []
		storageClass:     ""
		databaseUrl:      ""
		secretKey:        "gCQjUmvlDmixmJWHpxtAXbkNhEthTqK5AAjTw8lZwjU="
		redisUrl:         ""
		celeryRedisUrl:   ""
		image: {
			repository: "ghcr.io/saleor/saleor"
			tag:        "3.23.3"
			pullPolicy: "IfNotPresent"
		}
		database: {
			primaryUrl:        ""
			replicaUrl:        ""
			maxConnections:    150
			connectionTimeout: 5
			connMaxAge:        0
		}
		tls: {
			enabled:    false
			secretName: ""
		}
	}

	serviceMesh: {
		enabled: false
		istio: {
			enabled: false
			api: {
				circuitBreaker: {
					enabled:        false
					maxConnections: 100
				}
				timeout: {
					enabled: false
					http:    "10s"
				}
			}
		}
	}

	commonLabels: {}
	commonAnnotations: {}

	api: {
		enabled:      true
		replicaCount: 2
		extraEnv: [
			{name: "ALLOWED_HOSTS", value:        "*"},
			{name: "ALLOWED_CLIENT_HOSTS", value: "*"},
		]
		service: {
			type: "ClusterIP"
			port: 8000
		}
		resources: {
			requests: {
				cpu:    "512m"
				memory: "512Mi"
			}
			limits: {
				// cpu:    "500m"
				memory: "1024Mi"
			}
		}
		autoscaling: {
			enabled:                        true
			minReplicas:                    2
			maxReplicas:                    4
			targetCPUUtilizationPercentage: 80
			//
		}
		securityContext: {}
		podAnnotations: {}
		imagePullSecrets: []
	}

	dashboard: {
		enabled:      true
		replicaCount: 1
		image: {
			repository: "ghcr.io/saleor/saleor-dashboard"
			tag:        "3.23.3"
			pullPolicy: "IfNotPresent"
		}
		appsMarketplaceApiUrl: "https://apps.saleor.io/api/v2/saleor-apps"
		appsExtensionsApiUrl:  "https://apps.saleor.io/api/v2/saleor-apps"
		isCloudInstance:       false
		extraEnv: []

		service: {
			type: "ClusterIP"
			port: 80
		}
		resources: {
			requests: {
				cpu:    "500m"
				memory: "256Mi"
			}
			limits: {
				// cpu:    "500m"
				memory: "512Mi"
			}
		}
		autoscaling: {
			enabled:                           true
			minReplicas:                       1
			maxReplicas:                       3
			targetCPUUtilizationPercentage:    80
			// targetMemoryUtilizationPercentage: 80
		}
		securityContext: {
			runAsUser:  0
			runAsGroup: 0
		}
	}

	worker: {
		enabled:      true
		replicaCount: 1
		
		extraEnv: []
		resources: {
			requests: {
				cpu:    "500m"
				memory: "1024Mi"
			}
			limits: {
				//cpu:    "500m"
				memory: "1431Mi"
			}
		}
		autoscaling: {
			enabled:                           true
			minReplicas:                       1
			maxReplicas:                       3
			targetCPUUtilizationPercentage:    80
			// targetMemoryUtilizationPercentage: 80
		}
		scheduler: resources: {
			requests: {
				cpu:    "250m"
				memory: "256Mi"
			}
			limits: {
				// cpu:    "300m"
				memory: "512Mi"
			}
		}
	}

	migrations: {
		enabled:  true
		extraEnv: []
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				// cpu:    "200m"
				memory: "512Mi"
			}
		}
		nodeSelector: {}
		affinity:     {}
		tolerations:  []
	}

	storage: {
		s3: {
			enabled: false
			credentials: {
				accessKeyId:     ""
				secretAccessKey: ""
			}
			config: {
				region:                 "us-east-1"
				staticBucketName:       ""
				customDomain:           ""
				mediaBucketName:        ""
				mediaCustomDomain:      ""
				mediaPrivateBucketName: ""
				defaultAcl:             ""
				queryStringAuth:        false
				queryStringExpire:      3600
				endpointUrl:            ""
			}
		}
		gcs: {
			enabled: false
			credentials: jsonKey: ""
			config: {
				staticBucketName:       ""
				customEndpoint:         ""
				mediaBucketName:        ""
				mediaCustomEndpoint:    ""
				mediaPrivateBucketName: ""
				defaultAcl:             ""
				queryStringAuth:        false
			}
		}
	}

	postgresql: {
		enabled:      true
		architecture: "standalone"
		image: {
			repository: "postgres"
			tag:        "15-alpine"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			database:            "postgres"
			postgresPassword:    "saleor"
			replicationPassword: "saleor"
			existingSecret:      "postgresql-credentials"
			secretKeys: {
				adminPasswordKey:       "postgresql-password"
				userPasswordKey:        "user-password"
				replicationPasswordKey: "replication-password"
			}
		}
		primary: {
			persistence: size: "8Gi"
			resources: requests: {
				cpu:    "500m"
				memory: "2Gi"
			}
			extendedConfiguration: """
				work_mem = 64MB
				maintenance_work_mem = 256MB
				shared_buffers = 500MB
				temp_buffers = 16MB
				max_connections = 150
				"""
		}
		readReplicas: {
			replicaCount: 1
			persistence: size: "8Gi"
			resources: requests: {
				cpu:    "500m"
				memory: "1Gi"
			}
			extendedConfiguration: """
				work_mem = 64MB
				maintenance_work_mem = 256MB
				shared_buffers = 250MB
				temp_buffers = 16MB
				max_connections = 150
				"""
		}
	}

	redis: {
		enabled:      true
		architecture: "standalone"
		image: {
			repository: "valkey/valkey"
			tag:        "8.1-alpine"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			enabled:                   true
			password:                  "saleor"
			existingSecret:            ""
			existingSecretPasswordKey: ""
		}
		master: {
			persistence: size: "8Gi"
			resources: requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
		}
	}

	ingress: {
		enabled:     false
		className:   ""
		annotations: {}
		api: {
			enabled:     false
			annotations: {
				"nginx.ingress.kubernetes.io/proxy-body-size": "20m"
			}
			hosts: [
				{
					host: "chart-example.local"
					paths: [
						{path: "/graphql/", pathType:    "Prefix"},
						{path: "/thumbnail/", pathType:  "Prefix"},
						{path: "/.well-known/jwks.json", pathType: "ImplementationSpecific"},
					]
				},
			]
			tls: []
			// tls: [
			// 	{
			// 		secretName: "saleor-tls"
			// 		hosts: ["chart-example.local"]
			// 	},
			// ]
		}
	}

	imageCredentials: {
		enabled:  false
		registry: ""
		username: ""
		password: ""
	}

	serviceAccount: {
		create:      true
		annotations: {}
		name:        ""
	}

	podSecurityContext: {}
	securityContext:    {}
	nodeSelector:       {}
	tolerations:        []
	affinity:           {}
}
