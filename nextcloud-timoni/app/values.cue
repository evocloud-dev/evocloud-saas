package main

// Defaults
values: {
	image: {
		repository: "docker.io/library/nextcloud"
		digest:     ""
		tag:        "apache"
		pullPolicy: "IfNotPresent"
	}

	nameOverride:     ""
	fullnameOverride: ""
	deploymentAnnotations: {}
	deploymentLabels: {}
	
	lifecycle: {}

	nextcloud: {
		containerPort: 80
		trustedDomains: ["nextcloud.kube.home", "localhost"]
		trustedProxies: ["127.0.0.1", "10.0.0.0/8"]
		maintenanceWindowStart: 1
		forceSTSSet: true
		bruteForceProtection: false
		bruteForceWhitelistedIps: ["127.0.0.1", "::1"]
		datadir: "/var/www/html/data"

		phpConfigs: {}
		defaultConfigs: {
			".htaccess":                     true
			"apache-pretty-urls.config.php": true
			"apcu.config.php":               true
			"apps.config.php":               true
			"autoconfig.php":                true
			"redis.config.php":              true
			"reverse-proxy.config.php":      true
			"s3.config.php":                 true
			"smtp.config.php":               true
			"swift.config.php":              true
			"upgrade-disable-web.config.php": true
			"maintenance.config.php":         true
			"imaginary.config.php":          false
		}
		configs: {}

		hooks: {
			"pre-installation":  ""
			"post-installation": ""
			"pre-upgrade":       ""
			"post-upgrade":      ""
			"before-starting":   ""
		}

		// Admin credentials
		username: "admin"
		password: "changeme"

		existingSecret: {
			enabled:         false
			secretName:      ""
			usernameKey:     "nextcloud-username"
			passwordKey:     "nextcloud-password"
			tokenKey:        ""
			smtpUsernameKey: "smtp-username"
			smtpPasswordKey: "smtp-password"
			smtpHostKey:     "smtp-host"
		}

		mail: {
			enabled:     false
			fromAddress: "user"
			domain:      "domain.com"
			smtp: {
				host:     "domain.com"
				secure:   "ssl"
				port:     465
				authtype: "LOGIN"
				name:     "user"
				password: "pass"
			}
		}

		phpClientHttpsFix: {
			enabled:  false
			protocol: "https"
		}

		extraEnv: []

		objectStore: {
			s3: {
				enabled:      false
				accessKey:    ""
				secretKey:    ""
				legacyAuth:   false
				host:         ""
				ssl:          true
				port:         "443"
				region:       "eu-west-1"
				bucket:       ""
				prefix:       ""
				usePathStyle: false
				autoCreate:   false
				storageClass: "STANDARD"
				sse_c_key:    ""
				existingSecret: ""
				secretKeys: {
					host:      ""
					accessKey: ""
					secretKey: ""
					bucket:    ""
					sse_c_key: ""
				}
			}
			swift: {
				enabled:    false
				autoCreate: false
				user: {
					name:     ""
					password: ""
					domain:   ""
				}
				project: {
					name:   ""
					domain: ""
				}
				service:   ""
				region:    ""
				url:       ""
				container: ""
			}
		}
	}



	database: {
		internalDatabase: {
			enabled: false
			name:    "nextcloud"
		}
		mariadb: {
			enabled: false
			image:   "docker.io/bitnami/mariadb:latest"
			auth: {
				username:     "nextcloud"
				password:     "changeme"
				rootPassword: "changeme"
				database:     "nextcloud"
			}
			persistence: enabled: true
		}
		postgresql: {
			enabled:     true
			image:       "docker.io/bitnami/postgresql:latest"
			auth: {
				username: "nextcloud"
				password: "changeme"
				database: "nextcloud"
			}
			persistence: enabled: true
		}
		externalDatabase: {
			enabled:  false
			type:     "mysql"
			host:     ""
			user:     "nextcloud"
			password: ""
			database: "nextcloud"
			existingSecret: {
				enabled:     false
				secretName:  ""
				usernameKey: "db-username"
				passwordKey: "db-password"
				hostKey:     ""
				databaseKey: ""
			}
		}
	}

	service: {
		type:            "ClusterIP"
		port:            8080
		annotations:     {}
		loadBalancerIP:  ""
		ipFamilies:      ["IPv4"]
		ipFamilyPolicy:  ""
		sessionAffinity:       ""
		sessionAffinityConfig: {}
	}


	rbac: {
		enabled: false
		serviceAccount: {
			create: true
			name:   "nextcloud-serviceaccount"
			annotations: {}
		}
	}

	persistence: {
		enabled:       true
		storageClass:  ""
		existingClaim: ""
		accessMode:    "ReadWriteOnce"
		size:          "8Gi"
		annotations:   {}
		labels:        {}
		hostPath:      ""
		nextcloudData: {
			enabled:       false
			storageClass:  ""
			existingClaim: ""
			accessMode:    "ReadWriteOnce"
			size:          "8Gi"
			annotations:   {}
			labels:        {}
			hostPath:      ""
		}
	}

	metrics: {
		enabled:      false
		replicaCount: 1
		image: {
			repository: "xperimental/nextcloud-exporter"
			tag:        "0.8.0"
			digest:     ""
			pullPolicy: "IfNotPresent"
		}
		server:       ""
		timeout:      "5s"
		tlsSkipVerify: false
		https:        false
		token:        ""
		info: {
			apps:   false
			update: false
		}
		service: {
			type:           "ClusterIP"
			loadBalancerIP: ""
		}
		serviceMonitor: {
			enabled:       false
			namespace:     ""
			jobLabel:      ""
			interval:      "30s"
			scrapeTimeout: ""
		}
		rules: {
			enabled: false
			defaults: {
				enabled: true
				filter:  ""
			}
		}
	}

	imaginary: {
		enabled:      false
		replicaCount: 1
		image: {
			repository: "nextcloud/aio-imaginary"
			tag:        "latest"
			digest:     ""
			pullPolicy: "IfNotPresent"
		}
		service: {
			type:           "ClusterIP"
			loadBalancerIP: ""
			annotations:    {}
			labels:         {}
		}
		readinessProbe: {
			enabled:          true
			failureThreshold: 3
			successThreshold: 1
			periodSeconds:    10
			timeoutSeconds:   5
		}
		livenessProbe: {
			enabled:          true
			failureThreshold: 3
			successThreshold: 1
			periodSeconds:    10
			timeoutSeconds:   5
		}
	}

	hpa: {
		enabled:      false
		minPods:      1
		maxPods:      10
		cputhreshold: 60
	}

	cronjob: {
		enabled:   false
		type:      "cronjob"
		schedule:  "*/5 * * * *"
		successfulJobsHistoryLimit: 3
		failedJobsHistoryLimit:     5
		concurrencyPolicy:          "Forbid"
		backoffLimit:               1
	}

	ingress: {
		enabled:   false
		className: ""
		path:      "/"
		pathType:  "ImplementationSpecific"
		tls: []
		annotations: {}
		labels: {}
	}

	httpRoute: {
		enabled:   false
		apiVersion: "gateway.networking.k8s.io/v1beta1"
		kind:       "HTTPRoute"
		parentRefs: []
		hostnames: []
		rules: []
		annotations: {}
	}

	nginx: {
		enabled:         false
		image:           "docker.io/library/nginx:alpine"
		imagePullPolicy: "IfNotPresent"
		containerPort:   80
		ipFamilies:      ["IPv4"]

		config: {
			default:           true
			serverBlockCustom: ""
			headers: {
				"Strict-Transport-Security": ""
				"Referrer-Policy":           "no-referrer"
				"X-Content-Type-Options":    "nosniff"
				"X-Frame-Options":           "SAMEORIGIN"
				"X-Permitted-Cross-Domain-Policies": "none"
				"X-Robots-Tag":              "noindex, nofollow"
				"X-XSS-Protection":          "1; mode=block"
			}
		}
		
		resources: {}
		securityContext: {}
		extraEnv: []
	}

	livenessProbe: {
		enabled:             true
		initialDelaySeconds: 30
		periodSeconds:       10
		timeoutSeconds:      5
		successThreshold:    1
		failureThreshold:    3
	}
	readinessProbe: {
		enabled:             true
		initialDelaySeconds: 30
		periodSeconds:       10
		timeoutSeconds:      5
		successThreshold:    1
		failureThreshold:    3
	}
	startupProbe: {
		enabled:             true
		initialDelaySeconds: 30
		periodSeconds:       10
		timeoutSeconds:      5
		successThreshold:    1
		failureThreshold:    30
	}

	priorityClassName: ""

	redis: {
		enabled: true
		image: {
			registry:   "docker.io"
			repository: "bitnamilegacy/redis"
			tag:        "latest"
		}
		auth: {
			enabled:  true
			password: "changeme"
		}
		master: persistence: {
			enabled: true
			size:    "1Gi"
		}
	}

	externalRedis: {
		enabled:  false
		host:     ""
		port:     "6379"
		password: ""
	}

	test: image: {
		repository: "cgr.dev/chainguard/curl"
		digest:     ""
		tag:        "latest"
	}
}
