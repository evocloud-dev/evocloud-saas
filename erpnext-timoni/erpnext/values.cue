package main

// values.cue is used to provide default values for the Instance config.
values: {
	// Configure external redis host
	externalRedis: {
		cache: ""
		queue: ""
	}

	image: {
		repository: "frappe/erpnext"
		tag:        "v16.10.1"
		pullPolicy: "IfNotPresent"
	}

	nginx: {
		replicaCount: 1
		autoscaling: {
			enabled:     true
			minReplicas: 1
			maxReplicas: 3
			targetCPU:   75
			targetMemory: 75
		}
		environment: {
			upstreamRealIPAddress:   "127.0.0.1"
			upstreamRealIPRecursive: "off"
			upstreamRealIPHeader:    "X-Forwarded-For"
			frappeSiteNameHeader:    "erp.cluster.local"

			proxyReadTimeout:        "120"
			clientMaxBodySize:       "50m"
		}
		livenessProbe: {
			tcpSocket: port: 8080
			initialDelaySeconds: 5
			periodSeconds:       10
		}
		readinessProbe: {
			tcpSocket: port: 8080
			initialDelaySeconds: 5
			periodSeconds:       10
		}
		service: {
			type: "ClusterIP"
			port: 8080
		}
		resources: {
			requests: {
				cpu: "100m"
				memory: "128Mi"
			}
			limits: {
				memory: "512Mi"
			}
		}
		nodeSelector: {}
		tolerations: []
		affinity: {}
		defaultTopologySpread: {
			maxSkew:           1
			topologyKey:       "kubernetes.io/hostname"
			whenUnsatisfiable: "DoNotSchedule"
		}
		envVars: []
		initContainers: []
		sidecars: []
	}

	worker: {
		gunicorn: {
			replicaCount: 1
			autoscaling: {
				enabled:     true
				minReplicas: 1
				maxReplicas: 3
				targetCPU:   75
				targetMemory: 75
			}
			livenessProbe: {
				override: false
				probe: {
					tcpSocket: port: 8000
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
			readinessProbe: {
				override: false
				probe: {
					tcpSocket: port: 8000
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
			service: {
				type: "ClusterIP"
				port: 8000
			}
			resources: {
				requests: {
					cpu: "100m"
					memory: "128Mi"
				}
				limits: {
					memory: "1Gi"
				}
			}
			nodeSelector: {}
			tolerations: []
			affinity: {}
			args: []
			envVars: []
			initContainers: []
			sidecars: []
		}

		default: {
			replicaCount: 1
			autoscaling: {
				enabled:     true
				minReplicas: 1
				maxReplicas: 3
				targetCPU:   75
				targetMemory: 75
			}
			resources: {
				requests: {
					cpu: "100m"
					memory: "128Mi"
				}
				limits: {
					memory: "1Gi"
				}
			}
			nodeSelector: {}
			tolerations: []
			affinity: {}
			livenessProbe: {
				override: false
				probe: {}
			}
			readinessProbe: {
				override: false
				probe: {}
			}
			envVars: []
			initContainers: []
			sidecars: []
		}

		short: {
			replicaCount: 1
			autoscaling: {
				enabled:     true
				minReplicas: 1
				maxReplicas: 3
				targetCPU:   75
				targetMemory: 75
			}
			resources: {
				requests: {
					cpu: "100m"
					memory: "128Mi"
				}
				limits: {
					memory: "1Gi"
				}
			}
			nodeSelector: {}
			tolerations: []
			affinity: {}
			livenessProbe: {
				override: false
				probe: {}
			}
			readinessProbe: {
				override: false
				probe: {}
			}
			envVars: []
			initContainers: []
			sidecars: []
		}

		long: {
			replicaCount: 1
			autoscaling: {
				enabled:     true
				minReplicas: 1
				maxReplicas: 3
				targetCPU:   75
				targetMemory: 75
			}
			resources: {
				requests: {
					cpu: "100m"
					memory: "128Mi"
				}
				limits: {
					memory: "1Gi"
				}
			}
			nodeSelector: {}
			tolerations: []
			affinity: {}
			livenessProbe: {
				override: false
				probe: {}
			}
			readinessProbe: {
				override: false
				probe: {}
			}
			envVars: []
			initContainers: []
			sidecars: []
		}

		scheduler: {
			replicaCount: 1
			resources: {
				requests: {
					cpu: "100m"
					memory: "128Mi"
				}
				limits: {
					memory: "512Mi"
				}
			}
			nodeSelector: {}
			tolerations: []
			affinity: {}
			livenessProbe: {
				override: false
				probe: {}
			}
			readinessProbe: {
				override: false
				probe: {}
			}
			envVars: []
			initContainers: []
			sidecars: []
		}

		defaultTopologySpread: {
			maxSkew:           1
			topologyKey:       "kubernetes.io/hostname"
			whenUnsatisfiable: "DoNotSchedule"
		}

		healthProbe: """
			exec:
			  command:
			    - bash
			    - -c
			    - |-
			      echo "Pinging backing services";
			      {{- if (index .Values \"mariadb-sts\").enabled }}
			      wait-for-it {{ include \"erpnext.fullname\" . }}-mariadb-sts:3306 -t 1;
			      {{- else if (index .Values \"postgresql-sts\").enabled }}
			      wait-for-it {{ include \"erpnext.fullname\" . }}-postgresql-sts:5432 -t 1;
			      {{- else if or .Values.mariadb.enabled (get .Values \"mariadb-subchart\").enabled }}
			      (
			        wait-for-it {{ .Release.Name }}-mariadb-subchart:3306 -t 0 || \\
			        wait-for-it {{ .Release.Name }}-mariadb:3306 -t 0 || \\
			        wait-for-it {{ .Release.Name }}-mariadb-subchart-primary:3306 -t 0 || \\
			        wait-for-it {{ .Release.Name }}-mariadb-primary:3306 -t 1
			      )
			      {{- else if or .Values.postgresql.enabled (get .Values \"postgresql-subchart\").enabled }}
			      (
			        wait-for-it {{ .Release.Name }}-postgresql-subchart:5432 -t 0 || \\
			        wait-for-it {{ .Release.Name }}-postgresql:5432 -t 1
			      )
			      {{- else if or .Values.postgresql.enabled (index .Values \"postgresql-subchart\").enabled }}
			      wait-for-it {{ .Release.Name }}-postgresql-subchart:5432 -t 1;
			      {{- else if .Values.dbHost }}
			      wait-for-it {{ .Values.dbHost }}:{{ .Values.dbPort }} -t 1;
			      {{- end }}
			      {{- if .Values.externalRedis.cache }}
			      wait-for-it $(echo {{ .Values.externalRedis.cache }} | sed 's,redis://,,') -t 1;
			      {{- else if (index .Values \"valkey-cache\").enabled }}
			      wait-for-it {{ .Release.Name }}-valkey-cache:6379 -t 1;
			      {{- else if (index .Values \"dragonfly-cache\").enabled }}
			      wait-for-it {{ .Release.Name }}-dragonfly-cache:6379 -t 1;
			      {{- else if (index .Values \"redis-cache\").enabled }}
			      wait-for-it {{ .Release.Name }}-redis-cache-master:6379 -t 1;
			      {{- end }}
			      {{- if .Values.externalRedis.queue }}
			      wait-for-it $(echo {{ .Values.externalRedis.queue }} | sed 's,redis://,,') -t 1;
			      {{- else if (index .Values \"valkey-queue\").enabled }}
			      wait-for-it {{ .Release.Name }}-valkey-queue:6379 -t 1;
			      {{- else if (index .Values \"dragonfly-queue\").enabled }}
			      wait-for-it {{ .Release.Name }}-dragonfly-queue:6379 -t 1;
			      {{- else if (index .Values \"redis-queue\").enabled }}
			      wait-for-it {{ .Release.Name }}-redis-queue-master:6379 -t 1;
			      {{- end }}
			"""
	}

	socketio: {
		replicaCount: 1
		autoscaling: {
			enabled:     true
			minReplicas: 1
			maxReplicas: 3
			targetCPU:   75
			targetMemory: 75
		}
		livenessProbe: {
			tcpSocket: port: 9000
			initialDelaySeconds: 5
			periodSeconds:       10
		}
		readinessProbe: {
			tcpSocket: port: 9000
			initialDelaySeconds: 5
			periodSeconds:       10
		}
		resources: {
			requests: {
				cpu: "100m"
				memory: "128Mi"
			}
			limits: {
				memory: "512Mi"
			}
		}
		nodeSelector: {}
		tolerations: []
		affinity: {}
		service: {
			type: "ClusterIP"
			port: 9000
		}
		envVars: []
		initContainers: []
		sidecars: []
	}

	persistence: {
		worker: {
			enabled: true
			size:    "8Gi"
			accessModes: ["ReadWriteOnce"]
		}
		logs: {
			enabled: true
			size:    "8Gi"
			accessModes: ["ReadWriteOnce"]
		}
	}

	ingress: {
		enabled:     false
		annotations: {}
		hosts: [
			{
				host: "erp.cluster.local"
				paths: [
					{
						path:     "/"
						pathType: "ImplementationSpecific"
					},
				]
			},
		]
		tls: []
	}

	httproute: {
		enabled:     true
		annotations: {}
		parentRefs: [{
			gatewayName:      "erpnext-gateway",
			gatewayNamespace: "erpnext",
			gatewaySectionName: "http",
		}]
		hostnames: ["evocloud.dev"]
		rules: [
			{
				matches: [
					{
						pathType: "PathPrefix"
						path:     "/"
					},
				]
			},
		]
	}

	jobs: {
		volumePermissions: {
			enabled: true
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		configure: {
			enabled:      true
			fixVolume:    true
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
			envVars: []
		}

		createSite: {
			enabled:             true
			forceCreate:         true
			siteName:            "erp.cluster.local"
			adminPassword:       "changeit"
			adminExistingSecret: ""
			installApps: ["erpnext"]
			dbType:       "mariadb"
			backoffLimit: 0
			resources: {
				requests: {
					cpu: "500m"
					memory: "1Gi"
				}
				limits: {
					memory: "2Gi"
				}
			}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		createMultipleSites: {
			enabled:     false
			forceCreate: false
			sites: [
				{
					name: "erp.cluster.local"
					installApps: ["erpnext", "hrms", "payments"]
				},
			]
			adminPassword: "changeit"
			dbType:        "mariadb"
			backoffLimit:  0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		dropSite: {
			enabled:      false
			forced:       false
			siteName:     "erp.cluster.local"
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		dropMultipleSites: {
			enabled: false
			forced:  false
			sites: [
				{name: "site1.example.com"},
				{name: "site2.example.com"},
			]
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		backup: {
			enabled:      false
			siteName:     "erp.cluster.local"
			withFiles:    true
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		backupMultipleSites: {
			enabled:   false
			withFiles: true
			sites: [
				{name: "erp.cluster.local"},
			]
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		migrate: {
			enabled:      false
			siteName:     "erp.cluster.local"
			skipFailing:  false
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		migrateMultipleSites: {
			enabled:     false
			skipFailing: false
			sites: [
				{name: "erp.cluster.local"},
			]
			backoffLimit: 0
			resources: {}
			nodeSelector: {}
			tolerations: []
			affinity: {}
		}
		custom: {
			enabled:        false
			jobName:        ""
			labels:         {}
			backoffLimit:   0
			initContainers: []
			containers:     []
			restartPolicy:  "Never"
			volumes:        []
			nodeSelector:   {}
			affinity:       {}
			tolerations:    []
		}
	}

	imagePullSecrets: []
	nameOverride:     ""
	fullnameOverride: ""

	serviceAccount: {
		create: true
	}

	podSecurityContext: {
		supplementalGroups: [1000]
	}

	securityContext: {
		capabilities: {
			add: ["CAP_CHOWN"]
		}
	}

	"mariadb-sts": {
		enabled: true

		image: {
			repository: "mariadb"
			tag:        "10.6"
			pullPolicy: "IfNotPresent"
		}
		rootPassword: "changeit"
		persistence: {
			size: "8Gi"
		}
		resources: {}
		myCnf: """
			[mysqld]
			skip-character-set-client-handshake
			skip-innodb-read-only-compressed
			character-set-server=utf8mb4
			collation-server=utf8mb4_unicode_ci
			"""
	}

	"mariadb-subchart": {
		enabled: false
		rootPassword: "changeit"
		password: "changeit"
		image: {
			repository: "bitnamilegacy/mariadb"
			tag:        "10.6.17-debian-11-r10"
		}
	}

	mariadb: enabled: false
	
	"dragonfly-cache": {
		enabled: false
		image: {
			repository: "ghcr.io/dragonflydb/dragonfly"
			tag:        "v1.37.0"
		}
		args: ["--proactor_threads=1"]
	}
	"dragonfly-queue": {
		enabled: false
		storage: enabled: true
		image: {
			repository: "ghcr.io/dragonflydb/dragonfly"
			tag:        "v1.37.0"
		}
		args: ["--proactor_threads=1"]
	}

	postgresql: enabled: false


	"postgresql-subchart": {
		enabled: false
		image: {
			repository: "bitnamilegacy/postgresql"
			tag:        "14"
		}
	}

	"postgresql-sts": {
		enabled: false

		image: {
			repository: "postgres"
			tag:        "15"
			pullPolicy: "IfNotPresent"
		}
		postgresUser:     "postgres"
		postgresPassword: "changeit"
		persistence: {
			size: "8Gi"
		}
		resources: {}
	}

	"redis-cache": {
		enabled: false


		image: {
			repository: "bitnamilegacy/redis"
			tag:        "7.0"
		}
	}

	"redis-queue": {
		enabled: false


		image: {
			repository: "bitnamilegacy/redis"
			tag:        "7.0"
		}
	}

	"valkey-cache": {
		enabled: true

		image: {
			repository: "valkey/valkey"
			tag:        "7.2"
		}
	}

	"valkey-queue": {
		enabled: true

		image: {
			repository: "valkey/valkey"
			tag:        "7.2"
		}
	}
}
