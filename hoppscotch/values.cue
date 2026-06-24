// Note that this file must have no imports and all values must be concrete.
// Reference: https://github.com/helmforgedev/charts/blob/main/charts/hoppscotch/values.yaml

@if(!debug)

package main

// Defaults
values: {
	mode:              "dev"
	nameOverride:      ""
	fullnameOverride:  ""
	namespaceOverride: ""
	commonLabels: {}
	clusterDomain: "cluster.local"

	image: {
		repository: "docker.io/hoppscotch/hoppscotch"
		tag:        "2026.5.0"
		pullPolicy: "IfNotPresent"
	}

	imagePullSecrets: []

	baseUrl:           "http://localhost:3000"
	adminUrl:          "http://localhost:3100"
	backendGqlUrl:     "http://localhost:3170/graphql"
	backendWsUrl:      "wss://localhost:3170/graphql"
	backendApiUrl:     "http://localhost:3170/v1"
	shortcodeBaseUrl:  "http://localhost:3000"
	whitelistedOrigins: "http://localhost:3170,http://localhost:3000,http://localhost:3100,app://localhost_3200,app://hoppscotch"
	enableSubpathBasedAccess: false
	tosLink:           "https://docs.hoppscotch.io/support/terms"
	privacyPolicyLink: "https://docs.hoppscotch.io/support/privacy"

	proxy: {
		appUrl: ""
	}

	encryption: {
		key:               "default-32-char-encryption-key-!"
		existingSecret:    ""
		existingSecretKey: "data-encryption-key"
	}

	signingKey: {
		key:               "jN2YMEHnJqjc66E+asFu4suONIAq8LJYid6G+Zjii1j4IpxU+blxdETmLP2QDJdeDzuAKgz9g8kwCT05fpYrag=="
		existingSecret:    ""
		existingSecretKey: "webapp-server-signing-key"
	}

	postgresql: {
		enabled: true
		image: {
			repository: "docker.io/library/postgres"
			tag:        "18.4-trixie" 
			pullPolicy: "IfNotPresent"
		}
		auth: {
			database: "hoppscotch"
			username: "hoppscotch"
			password: ""
		}
		standalone: {
			persistence: {
				enabled: true
				size:    "10Gi"
			}
			resources: {
				requests: {
					cpu:    "100m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "512Mi"
				}
			}
		}
		initdb: {
			scripts: {
				"02-hoppscotch-extensions.sh": """
					#!/bin/bash
					set -euo pipefail
					export PGPASSWORD="${POSTGRES_PASSWORD}"
					psql --username "${POSTGRES_USER}" --dbname "${APP_DATABASE}" \\
					  -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'

					"""
			}
		}
	}

	postgresqlExtensionsJob: {
		enabled:                  true
		requireExistingResources: true
		image: {
			repository: "docker.io/library/postgres"
			tag:        "18.3-trixie"
			pullPolicy: "IfNotPresent"
		}
		backoffLimit:          6
		activeDeadlineSeconds: 300
		podAnnotations: {}
		podSecurityContext: {
			runAsNonRoot: true
			runAsUser:    999
			fsGroup:      999
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext: {
			allowPrivilegeEscalation: false
			capabilities: {
				drop: ["ALL"]
			}
			readOnlyRootFilesystem: true
			runAsNonRoot:           true
			runAsUser:              999
		}
		resources: {
			requests: {
				cpu:    "10m"
				memory: "32Mi"
			}
			limits: {
				cpu:    "100m"
				memory: "128Mi"
			}
		}
	}

	database: {
		external: {
			enabled:                   false
			host:                      ""
			port:                      5432
			name:                      "hoppscotch"
			username:                  "hoppscotch"
			password:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "postgres-password"
			url:                       "postgresql://username:password@url:5432/dbname"
			existingSecretUrlKey:      ""
		}
	}

	auth: {
		// Hoppscotch Self-Host Documentation: https://docs.hoppscotch.io/documentation/self-host/getting-started
		providers: "EMAIL,GITHUB"
		github: {
			enabled:                       true
			clientId:                      ""
			clientSecret:                  ""
			existingSecret:                ""
			existingSecretClientIdKey:     "github-client-id"
			existingSecretClientSecretKey: "github-client-secret"
			scope:                         "user:email"
			callbackUrl:                   ""
		}
		google: {
			enabled:                       false
			clientId:                      "dummy-google-client-id"
			clientSecret:                  "dummy-google-client-secret"
			existingSecret:                ""
			existingSecretClientIdKey:     "google-client-id"
			existingSecretClientSecretKey: "google-client-secret"
			scope:                         "email,profile"
			callbackUrl:                   ""
		}
		microsoft: {
			enabled:                       false
			clientId:                      ""
			clientSecret:                  ""
			existingSecret:                ""
			existingSecretClientIdKey:     "microsoft-client-id"
			existingSecretClientSecretKey: "microsoft-client-secret"
			scope:                         "user.read"
			callbackUrl:                   ""
		}
	}

	mailer: {
		enabled:               false
		from:                  ""
		useCustomConfigs:      false
		smtpUrl:               ""
		host:                  ""
		port:                  587
		secure:                true
		user:                  ""
		password:              ""
		tlsRejectUnauthorized: true
		existingSecret:        ""
		existingSecretSmtpUrlKey:  "smtp-url"
		existingSecretPasswordKey: "smtp-password"
	}

	replicaCount: 1

	deployment: {
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxUnavailable: 0
				maxSurge:       1
			}
		}
	}

	serviceAccount: {
		create:                       true
		name:                         ""
		automountServiceAccountToken: false
		annotations: {}
	}

	podSecurityContext: {
		fsGroup:      1000
		runAsNonRoot: true
	}

	containerSecurityContext: {
		allowPrivilegeEscalation: false
		capabilities: {
			drop: ["ALL"]
		}
		readOnlyRootFilesystem: false
		runAsNonRoot:           true
		runAsUser:              1000
	}

	resources: {
		requests: {
			cpu:    "200m"
			memory: "256Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "512Mi"
		}
	}

	service: {
		type:          "ClusterIP"
		port:          80
		containerPort: 8081
		ipFamilies: []
	}

	ingress: {
		enabled:          false
		ingressClassName: ""
		host:             ""
		annotations: {}
		tls: []
	}

	gateway: {
		enabled:    true
		parentRefs: []
		hostnames: []
		path:     "/"
		pathType: "PathPrefix"
		annotations: {}
	}

	externalSecrets: {
		enabled:    false
		apiVersion: "external-secrets.io/v1"
		secretStoreRef: {
			name: ""
			kind: "SecretStore"
		}
		refreshInterval: "1h"
		data: []
		dataFrom: []
		annotations: {}
	}

	metrics: {
		enabled: false
		serviceMonitor: {
			enabled:  false
			interval: "30s"
			labels: {}
		}
	}

	networkPolicy: {
		enabled: false
		ingress: []
		egress: []
	}

	podDisruptionBudget: {
		enabled:      true
		minAvailable: 1
	}

	podAnnotations: {}
	podLabels: {}
	nodeSelector: {}
	tolerations: []
	affinity: {}
	topologySpreadConstraints: []

	initContainers: []
	extraEnv: []
	extraEnvFrom: []
}
