// Reference: https://github.com/helmforgedev/charts/blob/main/charts/strapi/values.yaml
package main

// Default values for Strapi module.
values: {
	// Override the module name used in resource names.
	nameOverride: ""

	// Override the full release name used in resource names.
	fullnameOverride: ""

	// Labels added to every resource created by this chart/module.
	commonLabels: {}

	// Number of replicas for the Strapi deployment.
	// IMPORTANT: Multi-replica (>1) requires S3 or Cloudinary upload provider.
	// Local filesystem uploads only work with replicaCount: 1.
	replicaCount: 1

	// Image
	// HelmForge provides a production-ready Strapi base image (helmforge/strapi-base)
	// that includes Strapi 5.50.2 with all official plugins, multi-database support,
	// security hardening, and health check endpoints.

	image: {
		// Container image repository for your Strapi project.
		repository: "ghcr.io/evocloud-dev/oci/strapi-base"
		// Container image tag.
		tag:        "5.52.1"
		// Image pull policy.
		pullPolicy: "IfNotPresent"
		digest:     ""
	}

	// Image pull secrets for private registries.
	imagePullSecrets: []

	// Strapi Configuration
	strapi: {
		// Host interface.
		host: "0.0.0.0"

		// Container port exposed by Strapi.
		port: 1337

		// Public URL of the Strapi instance (auto-detected from ingress if empty).
		url: ""

		// Node environment.
		nodeEnv: "production"

		// Disable telemetry.
		telemetryDisabled: true

		// Start command override.
		command: []

		// Start arguments override.
		args: []

		// Additional environment variables for the Strapi container.
		extraEnv: []

		// Upload Provider
		// By default, Strapi stores uploads on the local filesystem (PVC).
		// For production multi-replica deployments, configure an S3-compatible
		// provider or Cloudinary to store uploads in object storage.

		upload: {
			// Upload provider: local | aws-s3 | cloudinary
			provider: "local"

			s3: {
				// Enable S3/MinIO upload provider.
				enabled: false

				// S3 endpoint (leave empty for AWS S3, set for MinIO/R2/Backblaze).
				endpoint: ""

				// S3 region.
				region: "us-east-1"

				// S3 bucket for uploads.
				bucket: ""

				// S3 path prefix (folder).
				prefix: ""

				// Use existing secret for S3 credentials.
				// Keys: access-key, secret-key
				existingSecret: ""

				// Key in existing secret for access key.
				existingSecretAccessKeyKey: "access-key"

				// Key in existing secret for secret key.
				existingSecretSecretKeyKey: "secret-key"

				// Inline S3 access key (not recommended for production).
				accessKey: ""

				// Inline S3 secret key (not recommended for production).
				secretKey: ""

				// S3 ACL (private | public-read).
				acl: "private"

				// Base URL for accessing files (CDN). If empty, S3 URL is used.
				baseUrl: ""

				// Custom S3 parameters (e.g., CacheControl, ContentDisposition).
				params: {}
			}

			cloudinary: {
				// Enable Cloudinary upload provider.
				enabled: false

				// Cloudinary cloud name.
				cloudName: ""

				// Cloudinary API key.
				apiKey: ""

				// Cloudinary API secret (use existingSecret in production).
				apiSecret: ""

				// Use existing secret for Cloudinary credentials.
				// Keys: api-key, api-secret
				existingSecret: ""

				// Key in existing secret for API key.
				existingSecretApiKeyKey: "api-key"

				// Key in existing secret for API secret.
				existingSecretApiSecretKey: "api-secret"
			}
		}

		// Performance Tuning
		performance: {
			// Node.js options (e.g., "--max-old-space-size=2048").
			nodeOptions: ""

			// Log level: fatal | error | warn | info | debug | trace.
			logLevel: "info"

			// Pretty print logs (development only).
			prettyPrint: false

			// Force JSON structured logs.
			forceJsonLogs: true
		}

		// Admin Panel Configuration
		admin: {
			// Custom admin panel path (default: /admin).
			path: "/admin"

			// Enable admin panel auto-open on start (development only).
			autoOpen: false

			// Admin JWT expiration time (e.g., 7d, 30d).
			jwtExpiration: "7d"

			// Rate limit for admin login attempts.
			rateLimit: {
				enabled:    true
				max:        5
				timeWindow: 900000
			}

			// Forgotten password configuration.
			forgotPassword: {
				enabled: true
			}
		}

		// Email Configuration
		email: {
			// Email provider: smtp | sendgrid | none
			provider: "none"

			// Default "from" email address.
			defaultFrom: "noreply@example.com"

			// Default "reply-to" email address.
			defaultReplyTo: ""

			smtp: {
				// SMTP host.
				host: ""

				// SMTP port.
				port: 587

				// SMTP username.
				username: ""

				// SMTP password (use existingSecret in production).
				password: ""

				// Use existing secret for SMTP credentials.
				// Keys: smtp-password
				existingSecret: ""

				// Key in existing secret for password.
				existingSecretPasswordKey: "smtp-password"

				// Use TLS.
				secure: false

				// Require TLS.
				requireTLS: true

				// Ignore TLS errors (not recommended).
				ignoreTLS: false
			}

			sendgrid: {
				// SendGrid API key.
				apiKey: ""

				// Use existing secret.
				// Keys: sendgrid-api-key
				existingSecret: ""

				// Key in existing secret.
				existingSecretApiKeyKey: "sendgrid-api-key"
			}
		}

		// GraphQL Configuration
		graphql: {
			// Enable GraphQL playground in development.
			playgroundEnabled: false

			// GraphQL endpoint path.
			endpoint: "/graphql"

			// Enable GraphQL introspection (disable in production).
			introspection: false

			// Max query depth.
			maxDepth: 10

			// Max query complexity.
			maxComplexity: 1000

			// Enable Apollo sandbox.
			apolloSandbox: false
		}

		// API Configuration
		api: {
			rest: {
				// Default limit for pagination.
				defaultLimit: 25

				// Max limit for pagination.
				maxLimit: 100
			}
		}

		// Server Configuration
		server: {
			// Body parser size limits.
			bodyParser: {
				jsonLimit: "1mb"
				formLimit: "56kb"
				textLimit: "1mb"
			}

			// Enable response compression.
			compression: enabled: true

			// Enable cron jobs.
			cron: enabled: true

			// Logger configuration.
			logger: level: "info"
		}
	}

	// Application Secrets
	// Strapi requires APP_KEYS, API_TOKEN_SALT, ADMIN_JWT_SECRET, JWT_SECRET,
	// and TRANSFER_TOKEN_SALT. The module auto-generates them if not provided.

	secrets: {
		// Use an existing secret containing all Strapi app secrets.
		existingSecret: ""

		// Existing secret key for APP_KEYS (comma-separated).
		existingSecretAppKeysKey: "app-keys"

		// Existing secret key for API token salt.
		existingSecretApiTokenSaltKey: "api-token-salt"

		// Existing secret key for admin JWT secret.
		existingSecretAdminJwtSecretKey: "admin-jwt-secret"

		// Existing secret key for application JWT secret.
		existingSecretJwtSecretKey: "jwt-secret"

		// Existing secret key for transfer token salt.
		existingSecretTransferTokenSaltKey: "transfer-token-salt"

		// Explicit APP_KEYS value (comma-separated). Auto-generated if empty.
		appKeys: ""

		// Explicit API token salt. Auto-generated if empty.
		apiTokenSalt: ""

		// Explicit admin JWT secret. Auto-generated if empty.
		adminJwtSecret: ""

		// Explicit application JWT secret. Auto-generated if empty.
		jwtSecret: ""

		// Explicit transfer token salt. Auto-generated if empty.
		transferTokenSalt: ""
	}

	// Database
	// Strapi supports SQLite, PostgreSQL, and MySQL.
	// Mode detection (when mode is auto):
	// 1. database.external.host or database.external.existingSecret -> external
	// 2. postgresql.enabled -> PostgreSQL subchart
	// 3. mysql.enabled -> MySQL subchart
	// 4. Fallback -> SQLite

	database: {
		// Database mode: auto | sqlite | external | postgresql | mysql
		mode: "auto"

		sqlite: {
			// Directory mounted for the SQLite database file.
			directory: "/opt/app/.tmp"

			// SQLite database filename.
			filename: "data.db"
		}

		external: {
			// External database vendor: postgres | mysql
			vendor: "postgres"

			// External database hostname.
			host: ""

			// External database port (auto-detected from vendor if empty).
			port: ""

			// Database name.
			name: "strapi"

			// Database username.
			username: "strapi"

			// Database password (ignored when existingSecret is set).
			password: ""

			// Existing secret for the database password.
			existingSecret: ""

			// Key in the existing secret for the database password.
			existingSecretPasswordKey: "database-password"

			ssl: enabled: false
		}

		pool: {
			// Minimum database connections per replica.
			min: 2

			// Maximum database connections per replica.
			max: 10

			// Connection acquisition timeout (ms).
			acquireTimeoutMillis: 30000

			// Idle connection timeout (ms).
			idleTimeoutMillis: 30000
		}
	}

	// PostgreSQL Subchart
	postgresql: {
		// Deploy PostgreSQL as a subchart.
		enabled:      true
		architecture: "standalone"
		image: {
			repository: "docker.io/library/postgres"
			tag:        "18.6-trixie"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			database:                  "strapi"
			username:                  "strapi"
			password:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "database-password"
		}
		primary: {
			persistence: {
				enabled:      true
				size:         "8Gi"
				storageClass: ""
			}
			resources: {
				requests: {
					cpu:    "250m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "1"
					memory: "512Mi"
				}
			}
		}
	}

	// MySQL Subchart
	mysql: {
		// Deploy MySQL as a subchart.
		enabled:      false
		architecture: "standalone"
		image: {
			repository: "docker.io/library/mysql"
			tag:        "9.7.2"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			database:                  "strapi"
			username:                  "strapi"
			password:                  "strapi-password"
			rootPassword:              "root-password"
			existingSecret:            ""
			existingSecretPasswordKey: "database-password"
		}
		primary: {
			persistence: {
				enabled:      true
				size:         "8Gi"
				storageClass: ""
			}
			resources: {
				requests: {
					cpu:    "250m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "1"
					memory: "512Mi"
				}
			}
		}
	}

	// Persistence
	persistence: {
		// Enable persistent storage for uploads and SQLite data.
		enabled:      true
		storageClass: ""
		accessMode:   "ReadWriteOnce"
		size:         "5Gi"
		existingClaim: ""
		annotations:   {}

		uploads: {
			// Uploads directory inside the Strapi container.
			mountPath: "/opt/app/public/uploads"
			// PVC subPath used for uploads data.
			subPath:   "uploads"
		}

		sqlite: subPath: "sqlite"
	}

	// Resources
	// CPU and memory requests/limits for the Strapi container.
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

	// Security Context
	podSecurityContext: {
		fsGroup: 65510
		seccompProfile: type: "RuntimeDefault"
	}

	securityContext: {
		runAsNonRoot:             true
		runAsUser:                65510
		runAsGroup:               65510
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}

	// Probes
	startupProbe: {
		enabled:             true
		initialDelaySeconds: 10
		periodSeconds:       5
		timeoutSeconds:      3
		failureThreshold:    30
	}

	livenessProbe: {
		enabled:             true
		initialDelaySeconds: 0
		periodSeconds:       15
		timeoutSeconds:      5
		failureThreshold:    3
	}

	readinessProbe: {
		enabled:             true
		initialDelaySeconds: 0
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    3
	}

	// Service
	service: {
		type:           "ClusterIP"
		port:           80
		annotations:    {}
		ipFamilyPolicy: null
		ipFamilies:     []
	}

	// Ingress
	ingress: {
		enabled:          false
		ingressClassName: ""
		annotations:      {}
		hosts:            []
		tls:              []
	}

	// Service Account
	serviceAccount: {
		create:                       false
		name:                         ""
		annotations:                  {}
		automountServiceAccountToken: false
	}

	// Backup (CronJob + S3)
	backup: {
		enabled:                    false
		schedule:                   "0 3 * * *"
		suspend:                    false
		concurrencyPolicy:          "Forbid"
		successfulJobsHistoryLimit: 3
		failedJobsHistoryLimit:     3
		backoffLimit:               1
		archivePrefix:              "strapi"
		images: {
			utility:    "docker.io/library/alpine:3.22"
			postgresql: "docker.io/library/postgres:18.3-alpine"
			mysql:      "docker.io/library/mysql:8.4"
			uploader:   "docker.io/helmforge/mc:1.0.0"
		}
		resources: {}
		s3: {
			endpoint:                ""
			bucket:                  ""
			prefix:                  "strapi"
			createBucketIfNotExists: true
			existingSecret:          ""
			existingSecretAccessKeyKey: "access-key"
			existingSecretSecretKeyKey: "secret-key"
			accessKey:              ""
			secretKey:              ""
		}
		database: {
			host:                      ""
			port:                      ""
			name:                      ""
			username:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "database-password"
			postgresDumpArgs:          ""
			mysqlDumpArgs:             "--single-transaction --quick --skip-lock-tables --no-tablespaces"
		}
	}

	// Scheduling
	nodeSelector:                  {}
	tolerations:                   []
	affinity:                      {}
	topologySpreadConstraints:     []
	priorityClassName:             ""
	terminationGracePeriodSeconds: 30

	// Pod-Level Metadata
	podLabels:      {}
	podAnnotations: {}

	// Extra
	extraVolumeMounts: []
	extraVolumes:      []
	extraManifests:    []

	// Gateway API
	gatewayAPI: {
		enabled:     false
		apiVersion:  "gateway.networking.k8s.io/v1"
		annotations: {}
		parentRefs:  []
		hostnames:   []
		matches:     []
	}

	externalSecrets: {
		enabled: false
		items:   []
	}
}
