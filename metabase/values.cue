// Reference: https://github.com/helmforgedev/charts/blob/main/charts/metabase/values.yaml

@if(!debug)

package main

values: {
	nameOverride:     ""
	fullnameOverride: ""
	commonLabels: {}

	image: {
		repository: "docker.io/metabase/metabase"
		tag:        "v0.63.5"
		pullPolicy: "IfNotPresent"
	}
	imagePullSecrets: []

	waitForDatabase: {
		image: {
			repository: "docker.io/library/busybox"
			tag:        "1.37"
			pullPolicy: "IfNotPresent"
		}
	}

	metabase: {
		port:                3000
		// Generate one using: openssl rand -base64 32
		encryptionSecretKey: ""
		existingSecret:      ""
		existingSecretKey:   "encryption-secret-key"
		siteUrl:             ""
		aiFeaturesEnabled:   false
		javaTimezone:        "UTC"
		javaOpts:            ""
		extraEnv: []
	}

	database: {
		external: {
			host:                      ""
			port:                      "5432"
			name:                      "metabase"
			username:                  "metabase"
			password:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "password"
		}
	}

	serviceAccount: {
		create:      true
		name:        ""
		annotations: {}
	}

	service: {
		type:           "ClusterIP"
		port:           80
		annotations: {}
		ipFamilyPolicy: ""
		ipFamilies: []
	}

	gateway: {
		enabled:     true
		annotations: {}
		parentRefs: []
		hostnames: []
		path:     "/"
		pathType: "PathPrefix"
	}

	probes: {
		startup: {
			enabled:             true
			path:                "/api/health"
			initialDelaySeconds: 90
			periodSeconds:       10
			timeoutSeconds:      5
			failureThreshold:    30
		}
		liveness: {
			enabled:             true
			path:                "/api/health"
			initialDelaySeconds: 0
			periodSeconds:       15
			timeoutSeconds:      5
			failureThreshold:    3
		}
		readiness: {
			enabled:             true
			path:                "/api/health"
			initialDelaySeconds: 0
			periodSeconds:       10
			timeoutSeconds:      5
			failureThreshold:    3
		}
	}

	resources: {
		requests: {
			cpu:    "250m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "2Gi"
		}
	}

	podSecurityContext: {
		runAsUser:           65510
		runAsGroup:          65510
		fsGroup:             65510
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext: {
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		capabilities: {
			drop: ["ALL"]
		}
	}

	backup: {
		// Enable scheduled PostgreSQL backups to S3-compatible storage
		enabled: false
		// Cron schedule for backups (default: daily at 03:00 UTC)
		schedule: "0 3 * * *"
		// Suspend the CronJob without deleting it
		suspend: false
		// Concurrency policy: Forbid, Replace, Allow
		concurrencyPolicy: "Forbid"
		// Number of successful job records to keep
		successfulJobsHistoryLimit: 3
		// Number of failed job records to keep
		failedJobsHistoryLimit: 3
		// Maximum retries per backup job
		backoffLimit: 1
		// Prefix for backup archive filenames
		archivePrefix: "metabase"
		images: {
			// Image used for PostgreSQL backup (must have pg_dump)
			postgresql: "docker.io/library/postgres:18.4-trixie"
			// Image used for S3 upload (MinIO client)
			uploader: "docker.io/helmforge/mc:1.0.0"
		}
		// Resources for backup containers
		resources: {}
		s3: {
			// S3-compatible endpoint URL
			endpoint: ""
			// Target bucket name
			bucket: ""
			// Key prefix within the bucket
			prefix: "metabase"
			// Auto-create the bucket if it does not exist
			createBucketIfNotExists: true
			// Use an existing secret for S3 credentials
			existingSecret: ""
			// Key in the existing secret for the access key
			existingSecretAccessKeyKey: "access-key"
			// Key in the existing secret for the secret key
			existingSecretSecretKeyKey: "secret-key"
			// Inline S3 access key (ignored when existingSecret is set)
			accessKey: ""
			// Inline S3 secret key (ignored when existingSecret is set)
			secretKey: ""
		}
		// Override database credentials for backup (uses app credentials if empty)
		database: {
			host:                      ""
			port:                      ""
			name:                      ""
			username:                  ""
			password:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "password"
			postgresDumpArgs:          ""
		}
	}

	nodeSelector: {}
	tolerations: []
	affinity: {}
	topologySpreadConstraints: []
	priorityClassName:             ""
	terminationGracePeriodSeconds: 30

	podLabels: {}
	podAnnotations: {}

	extraVolumes: []
	extraVolumeMounts: []
	extraInitContainers: []
	extraManifests: []

	externalSecrets: {
		enabled:         false
		apiVersion:      "external-secrets.io/v1"
		refreshInterval: "0"
		secretStoreRef: {
			name: ""
			kind: "SecretStore"
		}
		target: {
			creationPolicy: "Owner"
		}
		data: []
	}

	postgresql: {
		enabled:      true
		architecture: "standalone"
		podSecurityContext: {
			runAsUser:           65510
			runAsGroup:          65510
			fsGroup:             65510
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   true
			runAsNonRoot:             true
			capabilities: {
				drop: ["ALL"]
			}
		}
		image: {
			repository: "docker.io/library/postgres"
			tag:        "18.4-trixie"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			database: "metabase"
			username: "metabase"
			password: "change-me-please-db-password!"
		}
		initdb: {
			scripts: {
				"02-extensions.sql": "CREATE EXTENSION IF NOT EXISTS citext;\n"
			}
		}
		standalone: {
			persistence: {
				enabled: true
				size:    "8Gi"
			}
			resources: {
				requests: {
					cpu:    "100m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "768Mi"
				}
			}
		}
	}
}
