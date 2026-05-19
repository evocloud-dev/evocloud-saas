// Reference: https://github.com/apache/superset/blob/master/helm/superset/values.yaml
package main

values: {
	nameOverride:     ""
	fullnameOverride: ""
	extraLabels: {}
	runAsUser: 0
	secretEnv: {
		create: true
	}
	serviceAccountName: null
	serviceAccount: {
		create:      true
		annotations: {}
	}

	bootstrapScript: #"""
		#!/bin/bash
		apt update && apt install -y gcc libpq-dev python3-dev pkg-config libmariadb-dev libsasl2-dev
		# Ensure we install into Superset's virtual environment
		export VIRTUAL_ENV=/app/.venv
		export PATH="$VIRTUAL_ENV/bin:$PATH"
		uv pip install psycopg2-binary \
			pydynamodb clickhouse-connect \
			pydruid pyhive impyla kylinpy pinotdb sqlalchemy-solr sqlalchemy-redshift pydoris \
			sqlalchemy-drill pymssql couchbase-sqlalchemy sqlalchemy-cratedb denodo-sqlalchemy \
			pyathena[pandas] PyAthenaJDBC  sqlalchemy_dremio elasticsearch-dbapi sqlalchemy-exasol \
			sqlalchemy-bigquery shillelagh[gsheetsapi] firebolt-sqlalchemy ibm_db_sa nzalchemy mysqlclient oceanbase_py \
			cx_Oracle sqlalchemy-parseable hdbcli sqlalchemy-hana sqlalchemy-singlestoredb starrocks snowflake-sqlalchemy \
			taospy taos-ws-py teradatasqlalchemy trino sqlalchemy-vertica-python ydb-sqlalchemy
			cockroachdb && \
		if [ ! -f ~/bootstrap ]; then echo "Running Superset with uid 0" > ~/bootstrap; fi 
		"""#
	
	configFromSecret: null
	envFromSecret:    null
	envFromSecrets: []
	extraEnv: {}
	extraEnvRaw: []
	extraSecretEnv: {
		SUPERSET_SECRET_KEY: "8pxm1PEMtREbH8gMcsHdKWdGCb6N5IBoBzKYGqiuC45IKK0bZRvV2cc+"
	}
	extraConfigs: {}
	extraSecrets: {}
	extraVolumes: []
	extraVolumeMounts: []
	configOverrides: {}
	configOverridesFiles: {}
	configMountPath:      "/app/pythonpath"
	extraConfigMountPath: "/app/configs"
	image: {
		repository: "apachesuperset.docker.scarf.sh/apache/superset"
		tag:        "5.0.0"
		pullPolicy: "IfNotPresent"
	}
	imagePullSecrets: []
	initImage: {
		repository: "apache/superset"
		tag:        "dockerize"
		pullPolicy: "IfNotPresent"
	}
	service: {
		type: "ClusterIP"
		port: 8088
		annotations: {}
		loadBalancerIP: null
		nodePort: {
			http: null
		}
	}
	ingress: {
		enabled:          false
		ingressClassName: null
		annotations:      {}
		path:             "/"
		pathType:         "ImplementationSpecific"
		hosts: [
			"chart-example.local",
		]
		tls: []
		extraHostsRaw: []
	}
	resources: {}
	hostAliases: []
	supersetNode: {
		replicas: {
			enabled:      true
			replicaCount: 1
		}
		autoscaling: {
			enabled:                        false
			minReplicas:                    1
			maxReplicas:                    2
			targetCPUUtilizationPercentage: 80
		}
		podDisruptionBudget: {
			enabled:      false
			minAvailable: 1
		}
		command: [
			"/bin/sh",
			"-c",
			". /app/pythonpath/superset_bootstrap.sh; /usr/bin/run-server.sh",
		]
		connections: {
			redis_host:      null
			redis_port:      "6379"
			redis_user:      ""
			redis_cache_db:  "1"
			redis_celery_db: "0"
			redis_ssl: {
				enabled:       false
				ssl_cert_reqs: "CERT_NONE"
			}
			db_type: "postgresql"
			db_host: null
			db_port: "5432"
			db_user: "superset"
			db_pass: "superset"
			db_name: "superset"
		}
		env:         {}
		forceReload: false
		initContainers: [
			{
				name:            "wait-for-postgres"
				image:           "apache/superset:dockerize"
				imagePullPolicy: "IfNotPresent"
				envFrom: [
					{
						secretRef: {
							name: "superset-env"
						}
					},
				]
				command: [
					"/bin/sh",
					"-c",
					"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -timeout 120s",
				]
				resources: {
					limits: {
						memory: "256Mi"
					}
					requests: {
						cpu:    "250m"
						memory: "128Mi"
					}
				}
			},
		]
		extraContainers:           []
		deploymentAnnotations:     {}
		deploymentLabels:          {}
		affinity:                  {}
		topologySpreadConstraints: []
		podAnnotations:            {}
		podLabels:                 {}
		startupProbe: {
			httpGet: {
				path: "/health"
				port: "http"
			}
			initialDelaySeconds: 15
			timeoutSeconds:      1
			failureThreshold:    60
			periodSeconds:       5
			successThreshold:    1
		}
		livenessProbe: {
			httpGet: {
				path: "/health"
				port: "http"
			}
			initialDelaySeconds: 15
			timeoutSeconds:      1
			failureThreshold:    3
			periodSeconds:       15
			successThreshold:    1
		}
		readinessProbe: {
			httpGet: {
				path: "/health"
				port: "http"
			}
			initialDelaySeconds: 15
			timeoutSeconds:      1
			failureThreshold:    3
			periodSeconds:       15
			successThreshold:    1
		}
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1536Mi"
			}
			requests: {
				cpu:    "250m"
				memory: "768Mi"
			}
		}
		podSecurityContext:       {}
		containerSecurityContext: {}
		strategy:                 {}
	}
	supersetWorker: {
		replicas: {
			enabled:      true
			replicaCount: 1
		}
		autoscaling: {
			enabled:                        false
			minReplicas:                    1
			maxReplicas:                    2
			targetCPUUtilizationPercentage: 80
		}
		podDisruptionBudget: {
			enabled:      false
			minAvailable: 1
		}
		command: [
			"/bin/sh",
			"-c",
			". /app/pythonpath/superset_bootstrap.sh; celery --app=superset.tasks.celery_app:app worker --concurrency=2",
		]
		forceReload: false
		initContainers: [
			{
				name:            "wait-for-postgres-redis"
				image:           "apache/superset:dockerize"
				imagePullPolicy: "IfNotPresent"
				envFrom: [
					{
						secretRef: {
							name: "superset-env"
						}
					},
				]
				command: [
					"/bin/sh",
					"-c",
					"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
				]
				resources: {
					limits: {
						memory: "256Mi"
					}
					requests: {
						cpu:    "250m"
						memory: "128Mi"
					}
				}
			},
		]
		extraContainers:           []
		deploymentAnnotations:     {}
		deploymentLabels:          {}
		affinity:                  {}
		topologySpreadConstraints: []
		podAnnotations:            {}
		podLabels:                 {}
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1024Mi"
			}
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
		}
		podSecurityContext:       {}
		containerSecurityContext: {}
		strategy:                 {}
		livenessProbe: {
			exec: {
				command: [
					"sh",
					"-c",
					"celery -A superset.tasks.celery_app:app inspect ping -d celery@$HOSTNAME",
				]
			}
			initialDelaySeconds: 120
			timeoutSeconds:      60
			failureThreshold:    3
			periodSeconds:       60
			successThreshold:    1
		}
		startupProbe:      {}
		readinessProbe:    {}
		priorityClassName: null
	}
	supersetCeleryBeat: {
		enabled: false
		podDisruptionBudget: {
			enabled:      false
			minAvailable: 1
		}
		command: [
			"/bin/sh",
			"-c",
			". /app/pythonpath/superset_bootstrap.sh; celery --app=superset.tasks.celery_app:app beat --pidfile /tmp/celerybeat.pid --schedule /tmp/celerybeat-schedule",
		]
		forceReload: false
		initContainers: [
			{
				name:            "wait-for-postgres-redis"
				image:           "apache/superset:dockerize"
				imagePullPolicy: "IfNotPresent"
				envFrom: [
					{
						secretRef: {
							name: "superset-env"
						}
					},
				]
				command: [
					"/bin/sh",
					"-c",
					"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
				]
				resources: {
					limits: {
						memory: "256Mi"
					}
					requests: {
						cpu:    "250m"
						memory: "128Mi"
					}
				}
			},
		]
		extraContainers:           []
		deploymentAnnotations:     {}
		affinity:                  {}
		topologySpreadConstraints: []
		podAnnotations:            {}
		podLabels:                 {}
		resources:                 {}
		podSecurityContext:       {}
		containerSecurityContext: {}
		priorityClassName:         null
	}
	supersetCeleryFlower: {
		enabled:      false
		replicaCount: 1
		podDisruptionBudget: {
			enabled:      false
			minAvailable: 1
		}
		command: [
			"/bin/sh",
			"-c",
			"celery --app=superset.tasks.celery_app:app flower",
		]
		service: {
			type:           "ClusterIP"
			annotations:    {}
			loadBalancerIP: null
			port:           5555
			nodePort: {
				http: null
			}
		}
		startupProbe: {
			httpGet: {
				path: "/api/workers"
				port: "flower"
			}
			initialDelaySeconds: 5
			timeoutSeconds:      1
			failureThreshold:    60
			periodSeconds:       5
			successThreshold:    1
		}
		livenessProbe: {
			httpGet: {
				path: "/api/workers"
				port: "flower"
			}
			initialDelaySeconds: 5
			timeoutSeconds:      1
			failureThreshold:    3
			periodSeconds:       5
			successThreshold:    1
		}
		readinessProbe: {
			httpGet: {
				path: "/api/workers"
				port: "flower"
			}
			initialDelaySeconds: 5
			timeoutSeconds:      1
			failureThreshold:    3
			periodSeconds:       5
			successThreshold:    1
		}
		initContainers: [
			{
				name:            "wait-for-postgres-redis"
				image:           "apache/superset:dockerize"
				imagePullPolicy: "IfNotPresent"
				envFrom: [
					{
						secretRef: {
							name: "superset-env"
						}
					},
				]
				command: [
					"/bin/sh",
					"-c",
					"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
				]
				resources: {
					limits: {
						memory: "256Mi"
					}
					requests: {
						cpu:    "250m"
						memory: "128Mi"
					}
				}
			},
		]
		extraContainers:           []
		deploymentAnnotations:     {}
		affinity:                  {}
		topologySpreadConstraints: []
		podAnnotations:            {}
		podLabels:                 {}
		resources:                 {}
		podSecurityContext:       {}
		containerSecurityContext: {}
		priorityClassName:         null
	}
	supersetWebsockets: {
		enabled:      false
		replicaCount: 1
		podDisruptionBudget: {
			enabled:      false
			minAvailable: 1
		}
		ingress: {
			path:     "/ws"
			pathType: "Prefix"
		}
		image: {
			repository: "oneacrefund/superset-websocket"
			tag:        "latest"
			pullPolicy: "IfNotPresent"
		}
		config: {
			port:        8080
			logLevel:    "debug"
			logToFile:   false
			logFilename: "app.log"
			statsd: {
				host:       "127.0.0.1"
				port:       8125
				globalTags: []
			}
			redis: {
				port:     6379
				host:     ""
				password: ""
				db:       0
				ssl:      false
			}
			redisStreamPrefix: "async-events-"
			jwtSecret:         "Z4kXEUrBVOhZk6heKzR1uPL7Qx2EjtzgumO8GIeVbSI="
			jwtCookieName:     "async-token"
		}
		service: {
			type:           "ClusterIP"
			annotations:    {}
			loadBalancerIP: null
			port:           8080
			nodePort: {
				http: null
			}
		}
		command:                  []
		resources: {
			limits: {
				cpu:    "300m"
				memory: "256Mi"
			}
			requests: {
				cpu:    "50m"
				memory: "128Mi"
			}
		}
		extraContainers:           []
		deploymentAnnotations:     {}
		affinity:                  {}
		topologySpreadConstraints: []
		podAnnotations:            {}
		podLabels:                 {}
		strategy:                 {}
		podSecurityContext:       {}
		containerSecurityContext: {}
		startupProbe: {
			httpGet: {
				path: "/health"
				port: "ws"
			}
			initialDelaySeconds: 5
			timeoutSeconds:      1
			failureThreshold:    60
			periodSeconds:       5
			successThreshold:    1
		}
		livenessProbe: {
			httpGet: {
				path: "/health"
				port: "ws"
			}
			initialDelaySeconds: 5
			timeoutSeconds:      1
			failureThreshold:    3
			periodSeconds:       5
			successThreshold:    1
		}
		readinessProbe: {
			httpGet: {
				path: "/health"
				port: "ws"
			}
			initialDelaySeconds: 5
			timeoutSeconds:      1
			failureThreshold:    3
			periodSeconds:       5
			successThreshold:    1
		}
		priorityClassName: null
	}
	init: {
		resources: {
			limits: {
				cpu:    "1000m"
				memory: "1536Mi"
			}
			requests: {
				cpu:    "250m"
				memory: "768Mi"
			}
		}
		command: [
			"/bin/sh",
			"-c",
			". /app/pythonpath/superset_bootstrap.sh; . /app/pythonpath/superset_init.sh",
		]
		enabled: true
		jobAnnotations: {
			"helm.sh/hook":               "post-install,post-upgrade"
			"helm.sh/hook-delete-policy": "before-hook-creation"
		}
		loadExamples: false
		createAdmin:  true
		adminUser: {
			username:  "admin"
			firstname: "Superset"
			lastname:  "Admin"
			email:     "admin@superset.com"
			password:  "admin"
		}
		initContainers: [
			{
				name:            "wait-for-postgres"
				image:           "apache/superset:dockerize"
				imagePullPolicy: "IfNotPresent"
				envFrom: [
					{
						secretRef: {
							name: "superset"
						}
					},
				]
				command: [
					"/bin/sh",
					"-c",
					"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -timeout 120s",
				]
				resources: {
					limits: {
						memory: "256Mi"
					}
					requests: {
						cpu:    "250m"
						memory: "128Mi"
					}
				}
			},
		]
		initscript: #"""
			#!/bin/sh
			set -eu
			echo "Upgrading DB schema..."
			superset db upgrade
			echo "Initializing roles..."
			superset init
			echo "Creating admin user..."
			superset fab create-admin \
			                --username admin \
			                --firstname Superset \
			                --lastname Admin \
			                --email admin@superset.com \
			                --password admin \
			                || true
			if [ -f "/app/configs/import_datasources.yaml" ]; then
			  echo "Importing database connections.... "
			  superset import_datasources -p /app/configs/import_datasources.yaml
			fi
			"""#
		extraContainers:           []
		podAnnotations:            {}
		podLabels:                 {}
		podSecurityContext:       {}
		containerSecurityContext: {}
		tolerations:               []
		affinity:                  {}
		topologySpreadConstraints: []
		priorityClassName:         null
	}
	postgresql: {
		enabled: true
		auth: {
			existingSecret: null
			username:       "superset"
			password:       "superset"
			database:       "superset"
		}
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/postgresql"
			tag:        "14.17.0-debian-12-r3"
		}
		primary: {
			persistence: {
				enabled: true
				accessModes: [
					"ReadWriteOnce",
				]
			}
			service: {
				ports: {
					postgresql: "5432"
				}
			}
		}
	}
	redis: {
		enabled:      true
		architecture: "standalone"
		auth: {
			enabled:           false
			existingSecret:    ""
			existingSecretKey: ""
			password:          "superset"
		}
		master: {
			persistence: {
				enabled: false
				accessModes: [
					"ReadWriteOnce",
				]
			}
		}
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/redis"
			tag:        "7.0.10-debian-11-r4"
		}
	}
	nodeSelector:              {}
	tolerations:               []
	affinity:                  {}
	topologySpreadConstraints: []
	priorityClassName:         null
}