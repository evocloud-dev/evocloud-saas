package main

values: {
	nameOverride:     ""
	fullnameOverride: ""

	existingSecret: ""

	config: {
		publicUrl: "http://opensign.example.com"
		apiUrl:    "http://opensign.example.com/app"
	}

	server: {
		enabled: true
		image: {
			repository: "docker.io/opensign/opensignserver"
			tag:        "main"
			digest:     "sha256:674fa8393122cb550d5c2fa4ddae5e13989387f27d63db98e6c23272849a551e"
		}
		replicas: 1
		port:     8080
		env: {
			NODE_ENV: "production"
		}
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
			requests: {
				cpu:    "200m"
				memory: "256Mi"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
		persistence: {
			enabled:      true
			storageClass: ""
			accessMode:   "ReadWriteOnce"
			size:         "5Gi"
		}
		serviceAccount: {
			create: true
			name:   ""
		}
		probes: {
			startup: {
				enabled:             true
				initialDelaySeconds: 10
				periodSeconds:       5
				timeoutSeconds:      3
				failureThreshold:    30
			}
			liveness: {
				enabled:             true
				initialDelaySeconds: 30
				periodSeconds:       15
				timeoutSeconds:      5
				failureThreshold:    3
			}
			readiness: {
				enabled:             true
				initialDelaySeconds: 15
				periodSeconds:       10
				timeoutSeconds:      5
				failureThreshold:    3
			}
		}
	}

	client: {
		enabled: true
		image: {
			repository: "docker.io/opensign/opensign"
			tag:        "main"
			digest:     "sha256:093910c698c135e272a794ec1df81324c584b0c1011bb95da0c04ff22adb45ac"
		}
		replicas: 1
		port:     3000
		env: {}
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
		serviceAccount: {
			create: true
			name:   ""
		}
		autoscaling: {
			enabled:                           false
			minReplicas:                       1
			maxReplicas:                       5
			targetCPUUtilizationPercentage:    80
			targetMemoryUtilizationPercentage: 80
		}
		podDisruptionBudget: {
			enabled:        false
			minAvailable:   ""
			maxUnavailable: "1"
		}
		probes: {
			startup: {
				enabled:             true
				initialDelaySeconds: 5
				periodSeconds:       5
				timeoutSeconds:      3
				failureThreshold:    30
			}
			liveness: {
				enabled:             true
				initialDelaySeconds: 20
				periodSeconds:       15
				timeoutSeconds:      5
				failureThreshold:    3
			}
			readiness: {
				enabled:             true
				initialDelaySeconds: 10
				periodSeconds:       10
				timeoutSeconds:      5
				failureThreshold:    3
			}
		}
	}

	mongodb: {
		enabled: true
		image: {
			repository: "docker.io/library/mongo"
			tag:        "9.0.8"
			digest:     "sha256:20af90d0f14159e5532a4929608bc7cd9ecd718d3bae9d2f5457f4f0c509e3dc"
		}
		port: 27017
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
			requests: {
				cpu:    "200m"
				memory: "256Mi"
			}
		}
		podSecurityContext: {
			runAsNonRoot: true
			runAsUser:    999
			runAsGroup:   999
			fsGroup:      999
			seccompProfile: type: "RuntimeDefault"
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
		persistence: {
			enabled:      true
			storageClass: ""
			accessMode:   "ReadWriteOnce"
			size:         "10Gi"
		}
		serviceAccount: {
			create: true
			name:   ""
		}
		probes: {
			liveness: {
				enabled:             true
				initialDelaySeconds: 20
				periodSeconds:       15
				timeoutSeconds:      5
				failureThreshold:    3
			}
			readiness: {
				enabled:             true
				initialDelaySeconds: 10
				periodSeconds:       10
				timeoutSeconds:      5
				failureThreshold:    3
			}
		}
	}

	externalMongodb: {
		enabled:              false
		uri:                  ""
		existingSecret:       ""
		existingSecretKey:    "uri"
		existingSecretUriKey: ""
	}

	gateway: {
		enabled:     true
		annotations: {}
		parentRefs: [
			{
				name:      "shared-gtw"
				namespace: "kube-system"
			},
		]
		hostnames: [
			"opensign.example.com",
		]
	}

	backup: {
		enabled:                    false
		schedule:                   "0 2 * * *"
		suspend:                    false
		concurrencyPolicy:          "Forbid"
		successfulJobsHistoryLimit: 3
		failedJobsHistoryLimit:     3
		backoffLimit:               1
		archivePrefix:              "opensign"
		images: {
			mongodb:  "docker.io/library/mongo:9.0.8"
			uploader: "docker.io/helmforge/mc:1.0.0"
		}
		resources: {
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
		}
		s3: {
			endpoint:                   ""
			bucket:                     ""
			prefix:                     "opensign"
			createBucketIfNotExists:    true
			existingSecret:             ""
			existingSecretAccessKeyKey: "access-key"
			existingSecretSecretKeyKey: "secret-key"
			accessKey:                  ""
			secretKey:                  ""
		}
	}

	externalSecrets: {
		enabled:    false
		apiVersion: "external-secrets.io/v1"
		name:       ""
		secretStoreRef: {
			name: ""
			kind: "SecretStore"
		}
		target: {
			name:           ""
			creationPolicy: "Owner"
		}
		refreshInterval: "1h"
		annotations: {}
	}

	envSecret: {
		NODE_ENV:             "production"
		GENERATE_SOURCEMAP:   "false"
		REACT_APP_APPID:      "opensign"

		// Backend Core
		appName:              "open_sign_server"
		MASTER_KEY:           "opensign-master-key-12345"
		PARSE_MOUNT:          "/app"
		APP_ID:               "opensign"

		// Storage & Local Mode
		USE_LOCAL:            "true"
		DO_SPACE:             "DOSPACENAME"
		DO_ENDPOINT:          "ams3.digitaloceanspaces.com"
		DO_BASEURL:           "https://DOSPACENAME.ams3.digitaloceanspaces.com"
		DO_ACCESS_KEY_ID:     ""
		DO_SECRET_ACCESS_KEY: ""
		DO_REGION:            "us-west"

		// Email / Mailgun / SMTP
		MAILGUN_API_KEY:      ""
		MAILGUN_DOMAIN:       "mail.yourdomain.com"
		MAILGUN_SENDER:       "postmaster@mail.yourdomain.com"
		SMTP_ENABLE:          "true"
		SMTP_HOST:            "smtp.yourhost.com"
		SMTP_PORT:            "443"
		SMTP_USER_EMAIL:      "mailer@yourdomain.com"
		SMTP_PASS:            "password"

		// Document signing certificate (Base64-encoded PKCS#12 bundle + export passphrase).
		// REQUIRED for digital PDF signing when users finalize a document.
		// Leave empty if supplying via existingSecret, ExternalSecret, or UI console.
		// See README.md for instructions on generating a local dev certificate via OpenSSL.
		PFX_BASE64:           ""
		PASS_PHRASE:          ""
	}
}
