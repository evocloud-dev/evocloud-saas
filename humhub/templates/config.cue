package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults mirroring values.yaml exactly.
#Config: {
	// Timoni injected runtime metadata
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: labels: {
		"app.kubernetes.io/instance": metadata.name
		"app.kubernetes.io/name":     metadata.name
		"release":                    metadata.name
	}
	metadata: annotations?: timoniv1.#Annotations
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Node selector for scheduling
	nodeSelector: *{"kubernetes.io/arch": "amd64"} | {[string]: string}

	// Runtime class name (optional)
	runtimeClassName: *"" | string

	// Common environment and container defaults
	envDefaults: {
		tz:                    *"UTC" | string
		umask:                 *"0022" | string
		nvidiaVisibleDevices: *"void" | string
		puid:                  *"568" | string
		pgid:                  *"568" | string
	}
	emptyDirMemoryLimit: *"2400Mi" | string
	podSecurityContext: {
		fsGroup:             *568 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		supplementalGroups:  *[568] | [...int]
	}
	resources: {
		requests: {
			cpu:    *"75m" | string
			memory: *"200Mi" | string
		}
		limits: {
			cpu:    *"1500m" | string
			memory: *"2400Mi" | string
		}
	}
	initResources: {
		requests: {
			cpu:    *"10m" | string
			memory: *"50Mi" | string
		}
		limits: {
			cpu:    *"500m" | string
			memory: *"512Mi" | string
		}
	}

	// 1. image
	image: {
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
		repository: *"ghcr.io/mriedmann/humhub-phponly" | string
		tag:        *"1.17.2@sha256:3f00ef2b0ef98b4665acdad27f7f0c40325391182193bdb783c64e26a9b94b2c" | string
	}

	// 2. nginxImage
	nginxImage: {
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
		repository: *"ghcr.io/mriedmann/humhub-nginx" | string
		tag:        *"1.17.2@sha256:47fb119e2e0a182546a93646efcb5cd3f480171398eb1551b31e2030ec93c578" | string
	}


	// 3. securityContext
	securityContext: {
		container: {
			runAsNonRoot:             *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsUser:                *0 | int
			runAsGroup:               *0 | int
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
		}
	}
	initSecurityContext: {
		runAsNonRoot:             *true | bool
		runAsUser:                *568 | int
		runAsGroup:               *568 | int
		readOnlyRootFilesystem:   *true | bool
		allowPrivilegeEscalation: *false | bool
		privileged:               *false | bool
	}
	mainCapabilities: {
		add:  *["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
		drop: *["ALL"] | [...string]
	}
	nginxCapabilities: {
		add:  *["NET_BIND_SERVICE", "CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
		drop: *["ALL"] | [...string]
	}

	// 4. service
	service: {
		main: {
			targetSelector: *"nginx" | string
			ports: {
				main: {
					protocol:       *"http" | string
					targetSelector: *"nginx" | string
					targetPort:     *80 | int
					port:           *8080 | int
				}
			}
		}
		backend: {
			enabled:        *true | bool
			type:           *"ClusterIP" | string
			targetSelector: *"main" | string
			ports: {
				backend: {
					enabled:        *true | bool
					targetPort:     *9000 | int
					targetSelector: *"main" | string
					port:           *9000 | int
				}
			}
		}
	}

	// 5. humhub
	humhub: {
		nginx: {
			max_client_body_size: *"10m" | string
			keep_alive_timeout:   *65 | int
			whitelist:            *"10.0.0.0/8;172.16.0.0/16;192.168.0.0/24" | string
		}
		proto: *"http" | string
		host:  *"localhost:8080" | string
		admin: {
			login:    *"admin" | string
			password: *"test" | string
			email:    *"humhub@example.com" | string
		}
		mailer: {
			sys_address:           *"noreply@example.com" | string
			sys_name:              *"HumHub" | string
			type:                  *"smtp" | string
			hostname:              *"" | string
			port:                  *1025 | int
			user:                  *"" | string
			password:              *"" | string
			encrypt:               *"" | string
			allow_self_sign_certs: *false | bool
		}
	}

	// 6. workload
	workload: {
		main: {
			replicas:             *1 | int
			revisionHistoryLimit: *3 | int
			podSpec: {
				containers: {
					main: {
						probes: {
							liveness: {
								enabled: *true | bool
								type:    *"exec" | string
								command: *"/usr/local/bin/php-fpm-healthcheck" | string
							}
							readiness: {
								enabled: *true | bool
								type:    *"exec" | string
								command: *"/usr/local/bin/php-fpm-healthcheck" | string
							}
							startup: {
								enabled: *true | bool
								type:    *"exec" | string
								command: *"/usr/local/bin/php-fpm-healthcheck" | string
							}
						}
						env: {[string]: bool | string | int | {...}}
					}
				}
			}
		}
		nginx: {
			enabled:              *true | bool
			type:                 *"Deployment" | string
			replicas:             *1 | int
			revisionHistoryLimit: *3 | int
			podSpec: {
				containers: {
					nginx: {
						enabled:       *true | bool
						primary:       *true | bool
						imageSelector: *"nginxImage" | string
						env: {[string]: string | int}
						probes: {
							liveness: {
								enabled: *true | bool
								type:    *"http" | string
								path:    *"/ping" | string
								port:    *80 | int
							}
							readiness: {
								enabled: *true | bool
								type:    *"http" | string
								path:    *"/ping" | string
								port:    *80 | int
							}
							startup: {
								enabled: *true | bool
								type:    *"tcp" | string
								port:    *80 | int
							}
						}
					}
				}
			}
		}
	}

	// 7. persistence
	persistence: {
		config: {
			name:      *"\(metadata.name)-config" | string
			enabled:   *true | bool
			mountPath: *"/var/www/localhost/htdocs/protected/config" | string
			size:      *"100Gi" | string
		}
		assets: {
			name:      *"\(metadata.name)-assets" | string
			enabled:   *true | bool
			mountPath: *"/var/www/localhost/htdocs/assets" | string
			size:      *"100Gi" | string
			targetSelector?: [string]: [string]: mountPath: string
		}
		themes: {
			name:      *"\(metadata.name)-themes" | string
			enabled:   *true | bool
			mountPath: *"/var/www/localhost/htdocs/themes" | string
			size:      *"100Gi" | string
			targetSelector?: [string]: [string]: mountPath: string
		}
		modules: {
			name:      *"\(metadata.name)-modules" | string
			enabled:   *true | bool
			mountPath: *"/var/www/localhost/htdocs/protected/modules" | string
			size:      *"100Gi" | string
			targetSelector?: [string]: [string]: mountPath: string
		}
		uploads: {
			name:      *"\(metadata.name)-uploads" | string
			enabled:   *true | bool
			mountPath: *"/var/www/localhost/htdocs/uploads" | string
			size:      *"100Gi" | string
			targetSelector?: [string]: [string]: mountPath: string
		}
	}

	// 8. mariadb
	mariadb: {
		labels: timoniv1.#Labels & {
			"app.kubernetes.io/name":       "mariadb"
			"app.kubernetes.io/instance":   metadata.name
			"app.kubernetes.io/version":    moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
			"release":                      metadata.name
		}
		enabled:                       *true | bool
		replicas:                      *1 | int
		revisionHistoryLimit:          *3 | int
		strategyType:                  *"Recreate" | string
		terminationGracePeriodSeconds: *60 | int
		mariadbUsername:               *"humhub" | string
		mariadbDatabase:               *"humhub" | string
		password:                      *"humhub" | string
		rootPassword:                  *"rootpassword" | string
		host:                          *"\(metadata.name)-mariadb" | string
		port:                          *3306 | int
		credsSecretName:               *"\(metadata.name)-mariadbcreds" | string
		passinitConfigMapName:         *"\(metadata.name)-mariadb-passinit" | string
		dataPvcName:                   *"\(metadata.name)-mariadb-data" | string
		serviceName:                   *"\(metadata.name)-mariadb" | string
		plainporthost:                 *"\(host):\(port)" | string
		jdbc:                          *"jdbc:sqlserver://\(host):\(port)/\(mariadbDatabase)" | string
		jdbcMariadb:                  *"jdbc:mariadb://\(host):\(port)/\(mariadbDatabase)" | string
		jdbcMysql:                    *"jdbc:mysql://\(host):\(port)/\(mariadbDatabase)" | string
		url:                           *"sql://\(mariadbUsername):\(password)@\(host):\(port)/\(mariadbDatabase)" | string
		urlnossl:                      *"sql://\(mariadbUsername):\(password)@\(host):\(port)/\(mariadbDatabase)?sslmode=disable" | string
		image: {
			repository: *"docker.io/bitnamisecure/mariadb" | string
			tag:        *"latest@sha256:16c4d59ca1e33e557e5003596d244aefac4dd03220c8967ae12e3cee2a4c7dd9" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		waitImage: {
			repository: *"oci.trueforge.org/containerforge/mariadb-client" | string
			tag:        *"12.3.3@sha256:fc2f5a8787aa02c7cbc25103f8b97e6a03d492d1516e3ecc8b30a0939af1b718" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		securityContext: {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			container: {
				runAsUser:                *568 | int
				runAsGroup:               *0 | int
				runAsNonRoot:             *false | bool
				readOnlyRootFilesystem:   *false | bool
				allowPrivilegeEscalation: *false | bool
				privileged:               *false | bool
			}
			capabilities: {
				add:  *[] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		resources: {
			requests: {
				cpu:    *"75m" | string
				memory: *"200Mi" | string
			}
			limits: {
				cpu:    *"1500m" | string
				memory: *"2400Mi" | string
			}
		}
		probes: {
			liveness: {
				command:             *["/bin/bash", "-ec", "until /opt/bitnami/scripts/mariadb/healthcheck.sh; do sleep 2; done"] | [...string]
				initialDelaySeconds: *12 | int
				failureThreshold:    *5 | int
				successThreshold:    *1 | int
				timeoutSeconds:      *5 | int
				periodSeconds:       *15 | int
			}
			readiness: {
				command:             *["/bin/bash", "-ec", "until /opt/bitnami/scripts/mariadb/healthcheck.sh; do sleep 2; done"] | [...string]
				initialDelaySeconds: *10 | int
				failureThreshold:    *4 | int
				successThreshold:    *2 | int
				timeoutSeconds:      *5 | int
				periodSeconds:       *12 | int
			}
			startup: {
				command:             *["/bin/bash", "-ec", "until /opt/bitnami/scripts/mariadb/healthcheck.sh; do sleep 2; done"] | [...string]
				initialDelaySeconds: *10 | int
				failureThreshold:    *60 | int
				successThreshold:    *1 | int
				timeoutSeconds:      *3 | int
				periodSeconds:       *5 | int
			}
		}
		persistence: {
			enabled: *true | bool
			size:    *"100Gi" | string
		}
	}

	// 9. redis
	redis: {
		labels: timoniv1.#Labels & {
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   metadata.name
			"app.kubernetes.io/version":    moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
			"release":                      metadata.name
		}
		enabled:                       *true | bool
		replicas:                      *1 | int
		revisionHistoryLimit:          *3 | int
		updateStrategyType:            *"RollingUpdate" | string
		terminationGracePeriodSeconds: *60 | int
		password:                      *"humhubredis" | string
		host:                          *"\(metadata.name)-redis" | string
		port:                          *6379 | int
		credsSecretName:               *"\(metadata.name)-rediscreds" | string
		healthConfigMapName:           *"\(metadata.name)-redis-health" | string
		serviceName:                   *"\(metadata.name)-redis" | string
		plainporthost:                 *"\(host):\(port)" | string
		plainhostpass:                 *":\(password)@\(host)" | string
		url:                           *"redis://:\(password)@\(host):\(port)/0" | string
		image: {
			repository: *"docker.io/bitnamisecure/valkey" | string
			tag:        *"latest@sha256:b330d587970c5925265a12d367feba4b6cd89078c75ba118ffb70002834c1a7c" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		waitImage: {
			repository: *"oci.trueforge.org/containerforge/valkey-tools" | string
			tag:        *"1.1.0@sha256:7c2c18f0feeaa391d662a508c2d11fbb4cc7b5f1b07ff034ceb02a61df28db1d" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		allowEmptyPassword:            *"no" | string
		securityContext: {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			container: {
				runAsUser:                *568 | int
				runAsGroup:               *0 | int
				runAsNonRoot:             *false | bool
				readOnlyRootFilesystem:   *false | bool
				allowPrivilegeEscalation: *false | bool
				privileged:               *false | bool
			}
			capabilities: {
				add:  *[] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		resources: {
			requests: {
				cpu:    *"75m" | string
				memory: *"200Mi" | string
			}
			limits: {
				cpu:    *"1500m" | string
				memory: *"2400Mi" | string
			}
		}
		probes: {
			liveness: {
				command:             *["sh", "-c", "/health/ping_liveness_local.sh 2"] | [...string]
				initialDelaySeconds: *12 | int
				failureThreshold:    *5 | int
				successThreshold:    *1 | int
				timeoutSeconds:      *5 | int
				periodSeconds:       *15 | int
			}
			readiness: {
				command:             *["sh", "-c", "/health/ping_readiness_local.sh 2"] | [...string]
				initialDelaySeconds: *10 | int
				failureThreshold:    *4 | int
				successThreshold:    *2 | int
				timeoutSeconds:      *5 | int
				periodSeconds:       *12 | int
			}
			startup: {
				command:             *["sh", "-c", "/health/ping_readiness_local.sh 2"] | [...string]
				initialDelaySeconds: *10 | int
				failureThreshold:    *60 | int
				successThreshold:    *1 | int
				timeoutSeconds:      *3 | int
				periodSeconds:       *5 | int
			}
		}
	}

	podAnnotations?: {[string]: string}

	test: {
		enabled: *false | bool
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa:           #ServiceAccount & {#config:     config}
		secret:       #Secret & {#config:             config}
		mariadbCreds: #MariaDBCredsSecret & {#config: config}
		redisCreds:   #RedisCredsSecret & {#config:   config}
		svc:          #MainService & {#config:        config}
		backendSvc:   #BackendService & {#config:     config}

		deployMain:  #MainDeployment & {#config:  config}
		deployNginx: #NginxDeployment & {#config: config}

		if config.persistence.config.enabled {
			pvcConfig: #ConfigPVC & {#config: config}
		}
		if config.persistence.assets.enabled {
			pvcAssets: #AssetsPVC & {#config: config}
		}
		if config.persistence.themes.enabled {
			pvcThemes: #ThemesPVC & {#config: config}
		}
		if config.persistence.modules.enabled {
			pvcModules: #ModulesPVC & {#config: config}
		}
		if config.persistence.uploads.enabled {
			pvcUploads: #UploadsPVC & {#config: config}
		}

		if config.mariadb.enabled {
			mariadbPassinit: #MariaDBPassinit & {#config:   config}
			mariadbDeploy:   #MariaDBDeployment & {#config: config}
			mariadbSvc:      #MariaDBService & {#config:    config}
			if config.mariadb.persistence.enabled {
				mariadbPvc: #MariaDBPVC & {#config: config}
			}
		}

		if config.redis.enabled {
			redisHealth: #RedisHealthConfigMap & {#config: config}
			redisSts:    #RedisStatefulSet & {#config:     config}
			redisSvc:    #RedisService & {#config:         config}
		}
	}

	tests: {}
}
