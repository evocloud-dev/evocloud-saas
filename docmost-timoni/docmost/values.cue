// Note that this file must have no imports and all values must be concrete.
// REFERENCE: https://github.com/helmforgedev/charts/blob/main/charts/docmost/values.yaml

@if(!debug)

package main

// Defaults
values: {
	nameOverride:     ""
	fullnameOverride: ""
	commonLabels: {}
	replicaCount: 1

	image: {
		repository: "docker.io/docmost/docmost"
		tag:        "0.90"
		pullPolicy: "IfNotPresent"
	}

	imagePullSecrets: []

	docmost: {
		appUrl:            ""
		appSecret:         ""
		jwtTokenExpiresIn: "30d"
		extraEnv: []
	}

	database: {
		mode: "auto"
		external: {
			host:                      ""
			port:                      5432
			name:                      "docmost"
			username:                  "docmost"
			password:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "database-password"
		}
	}

	postgresql: {
		enabled:      true
		architecture: "standalone"
		image: {
			repository: "docker.io/library/postgres"
			tag:        "18.4-trixie"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			database:         "docmost"
			username:         "docmost"
			password:         ""
			postgresPassword: ""
		}
		initdb: {
			scripts: {
				"10-docmost-bootstrap.sh": #"""
					#!/bin/sh
					set -e

					if [ -n "${APP_DATABASE}" ] && [ -n "${APP_USERNAME}" ]; then
					  psql --username "${POSTGRES_USER}" --dbname postgres \
					    --set=app_database="${APP_DATABASE}" \
					    --set=app_username="${APP_USERNAME}" <<'SQL'
					SELECT format('GRANT CREATE ON DATABASE %I TO %I', :'app_database', :'app_username') \gexec
					SQL

					  psql --username "${POSTGRES_USER}" --dbname "${APP_DATABASE}" <<'SQL'
					CREATE EXTENSION IF NOT EXISTS unaccent;
					CREATE EXTENSION IF NOT EXISTS pg_trgm;
					SQL
					fi
					"""#
			}
		}
		standalone: {
			persistence: {
				enabled: true
				size:    "8Gi"
			}
		}
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1Gi"
			}
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
		}
	}

	redis: {
		enabled:      true
		architecture: "standalone"
		image: {
			repository: "docker.io/valkey/valkey"
			tag:        "9.1.0-alpine"
			pullPolicy: "IfNotPresent"
		}
		auth: {
			enabled:  true
			password: ""
		}
		standalone: {
			persistence: {
				enabled: true
				size:    "1Gi"
			}
		}
		resources: {
			limits: {
				cpu:    "500m"
				memory: "256Mi"
			}
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
		}
		external: {
			host:                      ""
			port:                      6379
			password:                  ""
			existingSecret:            ""
			existingSecretPasswordKey: "redis-password"
		}
	}

	storage: {
		mode: "local"
		local: {
			enabled:      true
			storageClass: ""
			accessMode:   "ReadWriteOnce"
			size:         "10Gi"
			existingClaim: ""
			annotations: {}
		}
		s3: {
			region:                     "us-east-1"
			bucket:                     ""
			endpoint:                   ""
			forcePathStyle:             true
			accessKey:                  ""
			secretKey:                  ""
			existingSecret:             ""
			existingSecretAccessKeyKey: "access-key"
			existingSecretSecretKeyKey: "secret-key"
		}
	}

	backup: {
		enabled:                    true
		schedule:                   "0 3 * * *"
		suspend:                    false
		concurrencyPolicy:          "Forbid"
		successfulJobsHistoryLimit: 3
		failedJobsHistoryLimit:     3
		backoffLimit:               1
		archivePrefix:              "docmost"
		images: {
			postgresql: "docker.io/library/postgres:18.4-trixie"
			uploader:   "docker.io/helmforge/mc:1.0.0"
		}
		resources: {
			requests: {
				cpu: "500m"
			    memory: "512Mi"
		    }
		    limits: {
				cpu: "1000m"
			    memory: "1Gi"
		    }
	    }
		database: {
			pgDumpArgs: ""
		}
		s3: {
			endpoint:                   ""
			bucket:                     ""
			prefix:                     "docmost"
			createBucketIfNotExists:    true
			existingSecret:             ""
			existingSecretAccessKeyKey: "access-key"
			existingSecretSecretKeyKey: "secret-key"
			accessKey:                  ""
			secretKey:                  ""
		}
	}

	service: {
		type: "ClusterIP"
		port: 80
		annotations: {}
		ipFamilyPolicy: ""
		ipFamilies: []
	}

	ingress: {
		enabled:          false
		ingressClassName: ""
		annotations: {}
		hosts: []
		tls: []
	}

	startupProbe: {
		enabled:             true
		path:                "/api/health"
		initialDelaySeconds: 10
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    30
	}

	livenessProbe: {
		enabled:             true
		path:                "/api/health"
		initialDelaySeconds: 0
		periodSeconds:       20
		timeoutSeconds:      5
		failureThreshold:    3
	}

	readinessProbe: {
		enabled:             true
		path:                "/api/health"
		initialDelaySeconds: 0
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    3
	}

	resources: {
		requests: {
			cpu: "500m"
			memory: "512Mi"
		}
		limits: {
			cpu: "1000m"
			memory: "1Gi"
		}
	}


	podSecurityContext: {
		fsGroup: 10001
	}

	securityContext: {
		runAsUser:                10001
		runAsGroup:               10001
		runAsNonRoot:             true
		readOnlyRootFilesystem:   true
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
	}

	serviceAccount: {
		create:      true
		name:        ""
		annotations: {}
	}

	nodeSelector: {}

	tolerations: []

	affinity: {}

	priorityClassName: ""

	terminationGracePeriodSeconds: 30

	podLabels: {}

	podAnnotations: {}

	extraVolumeMounts: []

	extraVolumes: []

	extraManifests: []

	gateway: {
		enabled:     false
		annotations: {}
		parentRefs: []
		hostnames: []
		path:     "/"
		pathType: "PathPrefix"
	}


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
}
