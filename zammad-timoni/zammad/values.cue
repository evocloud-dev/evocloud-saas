// Reference: https://github.com/zammad/zammad-helm/blob/main/zammad/values.yaml

package main

values: {
	image: {
		repository: "ghcr.io/zammad/zammad"
		tag:        ""
		digest:     ""
		pullPolicy: "IfNotPresent"
	}

	service: {
		type:        "ClusterIP"
		port:        8080
		appProtocol: "kubernetes.io/ws"
	}

	ingress: {
		enabled:   false
		className: ""
		annotations: {}
		hosts: [{
			host: "chart-example.local"
			paths: [{
				path:     "/"
				pathType: "ImplementationSpecific"
			}]
		}]
		tls:    []
		labels: {}
	}

	secrets: {
		autowizard: {
			useExisting: false
			secretKey:   "autowizard"
			secretName:  "autowizard"
		}
		elasticsearch: {
			useExisting: false
			secretKey:   "password"
			secretName:  "elastic-credentials"
		}
		postgresql: {
			useExisting: false
			secretKey:   "postgresql-pass"
			secretName:  "postgresql-pass"
		}
		redis: {
			useExisting: false
			secretKey:   "redis-password"
			secretName:  "redis-pass"
			sentinel: {
				useExisting: false
				secretKey:   "redis-sentinel-password"
				secretName:  "redis-sentinel-pass"
			}
		}
		s3: {
			useExisting: false
			secretKey:   "s3-url"
			secretName:  "s3-url"
		}
	}

	securityContext: {
		fsGroup:            1000
		fsGroupChangePolicy: "Always"
		runAsUser:          1000
		runAsNonRoot:       true
		runAsGroup:         1000
		seccompProfile: type: "RuntimeDefault"
	}

	zammadConfig: {
		elasticsearch: {
			enabled:        true
			host:           "zammad-elasticsearch-master"
			initialisation: true
			pass:           ""
			port:           9200
			reindex:        false
			schema:         "http"
			user:           ""
		}

		memcached: {
			enabled: true
			host:    "zammad-memcached"
			port:    11211
		}

		minio: {
			enabled: true
		}

		nginx: {
			replicas:              1
			trustedProxies:        []
			extraHeaders:          []
			websocketExtraHeaders: []
			clientMaxBodySize:     "50M"
			knowledgeBaseUrl:      ""
			listenIpv4:            true
			listenIpv6:            true
			startupProbe: {
				tcpSocket: port: 8080
				failureThreshold: 20
				periodSeconds:    4
			}
			livenessProbe: {
				tcpSocket: port: 8080
				failureThreshold: 5
				timeoutSeconds:   5
			}
			readinessProbe: {
				httpGet: {
					path: "/"
					port: 8080
				}
				failureThreshold: 5
				timeoutSeconds:   5
			}
			securityContext: {
				allowPrivilegeEscalation: false
				capabilities: drop: ["ALL"]
				readOnlyRootFilesystem: true
				privileged:             false
			}
			sidecars:                  []
			extraEnv:                  []
			podLabels:                 {}
			podAnnotations:            {}
			nodeSelector:              {}
			tolerations:               []
			affinity:                  {}
			topologySpreadConstraints: []
			resources: {
				requests: {
					cpu:    "50m"
					memory: "16Mi"
				}
				limits: {
					cpu:    "100m"
					memory: "32Mi"
				}
			}
		}

		postgresql: {
			enabled: true
			db:      "zammad_production"
			host:    "zammad-postgresql"
			pass:    "zammad"
			port:    5432
			user:    "zammad"
			options: "pool=50"
		}

		railsserver: {
			replicas: 1
			startupProbe: {
				tcpSocket: port: 3000
				failureThreshold: 20
				periodSeconds:    4
			}
			livenessProbe: {
				tcpSocket: port: 3000
				failureThreshold: 5
				timeoutSeconds:   5
			}
			readinessProbe: {
				httpGet: {
					path: "/"
					port: 3000
				}
				failureThreshold: 5
				timeoutSeconds:   5
			}
			securityContext: {
				allowPrivilegeEscalation: false
				capabilities: drop: ["ALL"]
				readOnlyRootFilesystem: true
				privileged:             false
			}
			sidecars:                  []
			trustedProxies:            "['127.0.0.1', '::1']"
			listenAddress:             "[::]"
			webConcurrency:            0
			extraEnv:                  []
			tmpdir:                    "/opt/zammad/tmp"
			podLabels:                 {}
			podAnnotations:            {}
			nodeSelector:              {}
			tolerations:               []
			topologySpreadConstraints: []
			resources: {
				requests: {
					cpu:    "100m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "300m"
					memory: "512Mi"
				}
			}
		}

		redis: {
			enabled:  true
			host:     "zammad-redis-master"
			port:     6379
			username: ""
			pass:     "zammad"
			tls:      false
			sentinel: {
				enabled:    true
				sentinels:  ["zammad-redis:26379"]
				masterName: "mymaster"
				username:   ""
				pass:       "zammad"
			}
		}

		scheduler: {
			securityContext: {
				allowPrivilegeEscalation: false
				capabilities: drop: ["ALL"]
				readOnlyRootFilesystem: true
				privileged:             false
			}
			sidecars:                  []
			extraEnv:                  []
			podLabels:                 {}
			podAnnotations:            {}
			nodeSelector:              {}
			tolerations:               []
			affinity:                  {}
			topologySpreadConstraints: []
			resources: {
				requests: {
					cpu:    "100m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "1024Mi"
				}
			}
		}

		storageVolume: {
			enabled: false
		}

		tmpDirVolume: {
			emptyDir: sizeLimit: "100Mi"
		}

		customVolumes:      []
		customVolumeMounts: []

		websocket: {
			startupProbe: {
				tcpSocket: port: 6042
				failureThreshold: 20
				periodSeconds:    4
			}
			livenessProbe: {
				tcpSocket: port: 6042
				failureThreshold: 10
				timeoutSeconds:   5
			}
			readinessProbe: {
				tcpSocket: port: 6042
				failureThreshold: 5
				timeoutSeconds:   5
			}
				resources: { 
					requests: {
						cpu:    "100m"
					    memory: "256Mi"
				    }
				    limits: {
						cpu:    "300m"
					    memory: "512Mi"
				    }
			    }

			securityContext: {
				allowPrivilegeEscalation: false
				capabilities: drop: ["ALL"]
				readOnlyRootFilesystem: true
				privileged:             false
			}
			listenAddress:             "::"
			sidecars:                  []
			extraEnv:                  []
			podLabels:                 {}
			podAnnotations:            {}
			affinity:                  {}
			nodeSelector:              {}
			tolerations:               []
			topologySpreadConstraints: []
		}

		initContainers: {
			elasticsearch: {
				resources: {
					requests: {
						cpu:    "100m"
						memory: "256Mi"
					}
					limits: {
						cpu:    "300m"
						memory: "1024Mi"
					}
				}
				securityContext: {
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
					readOnlyRootFilesystem: true
					privileged:             false
				}
			}
			postgresql: {
				resources: {
					requests: {
						cpu:    "100m"
						memory: "256Mi"
					}
					limits: {
						cpu:    "300m"
						memory: "1024Mi"
					}
				}
				securityContext: {
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
					readOnlyRootFilesystem: true
					privileged:             false
				}
			}
			volumePermissions: {
				enabled: true
				image: {
					repository: "alpine"
					tag:        "3.23.4"
					pullPolicy: "IfNotPresent"
				}
				command: ["/bin/sh", "-cx", "chmod 770 /opt/zammad/tmp"]
				resources: {
					requests: {
						cpu:    "10m"
						memory: "16Mi"
					}
					limits: {
						cpu:    "50m"
						memory: "32Mi"
					}
				}
				securityContext: {
					readOnlyRootFilesystem: true
					capabilities: drop: ["ALL"]
					privileged:    true
					runAsNonRoot: false
					runAsUser:    0
				}
			}
			zammad: {
				resources: {
					requests: {
						cpu:    "100m"
						memory: "256Mi"
					}
					limits: {
						cpu:    "300m"
						memory: "768Mi"
					}
				}
				securityContext: {
					allowPrivilegeEscalation: false
					capabilities: drop: ["ALL"]
					readOnlyRootFilesystem: true
					privileged:             false
				}
				customInit: ""
			}
		}

		initJob: {
			randomName:              true
			ttlSecondsAfterFinished: 300
			annotations:             {}
			podLabels:               {}
			podAnnotations:          {}
			podSpec:                 {}
			affinity:                {}
			nodeSelector:            {}
			tolerations:             []
			topologySpreadConstraints: []
		}

		cronJob: {
			reindex: {
				schedule:       "@weekly"
				suspend:        true
				annotations:    {}
				podLabels:      {}
				podAnnotations: {}
				podSpec:        {}
			}
		}
	}

	extraEnv: []

	autoWizard: {
		enabled: true
		config:  ""
	}

	affinity: {}
	commonLabels: {}
	nodeSelector: {}
	podAnnotations: {}
	podLabels:      {}
	tolerations:    []
	topologySpreadConstraints: []

	serviceAccount: {
		create:      false
		annotations: {}
		name:        ""
	}

	initContainers: []

	elasticsearch: {
		image: {
			repository: "docker.io/bitnamilegacy/elasticsearch:8.18.0-debian-12-r2"
		}
		sysctlImage: {
			repository: "bitnamilegacy/os-shell"
		}
		volumePermissions: {
			image: repository: "bitnamilegacy/os-shell"
		}
		metrics: {
			image: repository: "bitnamilegacy/elasticsearch-exporter"
		}
		global: security: allowInsecureImages: true
		clusterName: "zammad"
		coordinating: replicaCount: 0
		data:         replicaCount: 0
		ingest:       replicaCount: 0
		master: {
			heapSize:        "256m"
			masterOnly:      false
			replicaCount:    1
			resourcesPreset: "none"
			resources: {
				requests: {
					cpu:    "50m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "1024Mi"
				}
			}
		}
	}

	memcached: {
		replicaCount: 1
		resources: {
			requests: {
				cpu:    "20m"
				memory: "16Mi"
			}
			limits: {
				cpu:    "50m"
				memory: "32Mi"
			}
		}
	}

	minio: {
		image: {
			repository: "docker.io/bitnamilegacy/minio"
		}
		clientImage: {
			repository: "bitnamilegacy/minio-client"
		}
		global: security: allowInsecureImages: true
		defaultInitContainers: volumePermissions: image: repository: "bitnamilegacy/os-shell"
		console: image: repository: "bitnamilegacy/minio-object-browser"
		auth: {
			rootUser:     "zammadadmin"
			rootPassword: "zammadadmin"
		}
		defaultBuckets: "zammad"
		disableWebUI:   true
	}

	// settings for the postgres subchart

	postgresql: {
		image: {
			repository: "bitnamilegacy/postgresql"
		}
		volumePermissions: image: repository: "bitnamilegacy/os-shell"
		metrics: image: repository: "bitnamilegacy/postgres-exporter"
		global: security: allowInsecureImages: true
		auth: {
			username:            "zammad"
			replicationUsername: "repl_user"
			database:            "zammad_production"
			postgresPassword:    "zammad"
			password:            "zammad"
			replicationPassword: "zammad"
		}
		primary: {
			resources: {
				requests: {
					cpu:    "50m"
					memory: "128Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "512Mi"
				}
			}
		}
	}

	// settings for the redis subchart

	redis: {
		image: {
			repository: "docker.io/valkey/valkey"
			tag:        "9.1.0-alpine"
			pullPolicy: "Always"
		}
		sentinel: enabled:  true
		architecture:       "standalone"
		auth: password:     "zammad"
		resources: {
			requests: {
				cpu:    "20m"
				memory: "16Mi"
			}
			limits: {
				cpu:    "50m"
				memory: "32Mi"
			}
		}
	}
}
