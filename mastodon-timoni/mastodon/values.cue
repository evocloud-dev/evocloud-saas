// Reference: https://github.com/mastodon/chart/blob/main/values.yaml

package main

values: {
	image: {
		repository: "ghcr.io/mastodon/mastodon"
		tag:        "v4.5.9"
		pullPolicy: "IfNotPresent"
	}

	mastodon: {
		logLevel: {
			rails:     "info"
			streaming: "info"
		}
		labels: {}
		podLabels: {}

		createAdmin: {
			enabled:      true
			username:     "not_gargron"
			email:        "admin@gmail.com"
			nodeSelector: {}
		}

		hooks: {
			dbPrepare: {
				enabled:      true
				nodeSelector: {}
			}
			dbMigrate: {
				enabled:      true
				nodeSelector: {}
			}
			deploySearch: {
				enabled:     true
				resetChewy:  true
				only:        ""
				concurrency: 5
				resources: {
					requests: {
						cpu:    "250m"
						memory: "256Mi"
					}
					limits: {
						cpu: "500m"
					}
				}
			}
			s3Upload: {
				enabled:  false
				endpoint: ""
				bucket:   ""
				acl:      "public-read"
				secretRef: {
					name: ""
					keys: {
						accesKeyId:      "acces-key-id"
						secretAccessKey: "secret-access-key"
					}
				}
				rclone: env: {}
				nodeSelector: {}
			}
		}

		cron: {
			removeMedia: {
				enabled:      true
				schedule:     "0 0 * * 0"
				nodeSelector: {}
			}
		}

		locale:            ""
		local_domain:      "localhost"
		web_domain:        null
		alternate_domains: []
		singleUserMode:    false
		authorizedFetch:   false
		limitedFederationMode: false
		

		persistence: {
			assets: {
				accessMode:      "ReadWriteOnce"
				keepAfterDelete: true
				resources: requests: storage: "10Gi"
				existingClaim: ""
			}
			system: {
				accessMode:      "ReadWriteOnce"
				keepAfterDelete: true
				resources: requests: storage: "100Gi"
				existingClaim: ""
			}
		}

		s3: {
			enabled:             false
			access_key:          ""
			access_secret:       ""
			existingSecret:      ""
			bucket:              ""
			endpoint:            ""
			protocol:            "https"
			hostname:            ""
			region:              ""
			permission:          ""
			alias_host:          ""
			multipart_threshold: ""
		}

		deepl: {
			enabled: false
			plan:    ""
			apiKeySecretRef: {
				name: ""
				key:  ""
			}
		}

		hcaptcha: {
			enabled: false
			siteId:  ""
			secretKeySecretRef: {
				name: ""
				key:  ""
			}
		}

		secrets: {
			secret_key_base: "e57b8506691c28f09b83b37e8c07e9d7c0f1e2d3c4b5a69788f9e0d1c2b3a4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7"
			otp_secret:      "c0f1e2d3c4b5a69788f9e0d1c2b3a4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7e57b8506691c28f09b83b37e8c07e9d7"
			vapid: {
				private_key: "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCp"
				public_key:  "BIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCp"
			}
			activeRecordEncryption: {
				primaryKey:        "SGVsbG8gV29ybGQgZnJvbSBQcm90b2NvbCBCdWZmZXJzIQ=="
				deterministicKey:  "QW50aWdyYXZpdHkgaXMgYXdlc29tZSEhISEhISEhISE="
				keyDerivationSalt: "U2FsdGVkX19WZXJ5U2VjcmV0U2FsdA=="
			}
			existingSecret: ""
		}

		revisionHistoryLimit: 2

		sidekiq: {
			podSecurityContext: {}
			securityContext:    {}
			resources:          {}
			affinity:           {}
			nodeSelector:       {}
			annotations:        {}
			labels:             {}
			podAnnotations:     {}
			podLabels:          {}
			updateStrategy: type: "Recreate"
			readinessProbe: {
				enabled:             true
				path:                "/opt/mastodon/tmp/sidekiq_process_has_started_and_will_begin_processing_jobs"
				initialDelaySeconds: 10
				periodSeconds:        2
				successThreshold:    1
				timeoutSeconds:      1
			}
			topologySpreadConstraints: []
			otel: {
				enabled:     false
				exporterUri: ""
				namePrefix:  ""
				nameSeparator: ""
			}
			workers: [
				{
					name:        "all-queues"
					concurrency: 25
					replicas:    1
					resources:   {}
					affinity:    {}
					nodeSelector: {}
					topologySpreadConstraints: []
					queues: [
						"default,8",
						"push,6",
						"ingress,4",
						"mailers,2",
						"pull",
						"scheduler",
						"fasp",
					]
					image: {
						repository: "ghcr.io/mastodon/mastodon"
						tag:        "v4.5.9"
					}
					customDatabaseConfigYml: configMapRef: {
						name: ""
						key:  ""
					}
				},
			]
		}

		smtp: {
			auth_method:          "plain"
			ca_file:              "/etc/ssl/certs/ca-certificates.crt"
			delivery_method:      "smtp"
			domain:               ""
			enable_starttls:      "auto"
			from_address:         "notifications@example.com"
			return_path:          ""
			openssl_verify_mode: "peer"
			port:                 587
			reply_to:             ""
			server:               "smtp.mailgun.org"
			tls:                  false
			login:                ""
			password:             ""
			existingSecret:       ""
			bulk: {
				enabled:             false
				auth_method:         "plain"
				ca_file:             "/etc/ssl/certs/ca-certificates.crt"
				domain:              ""
				enable_starttls:     "auto"
				from_address:        "notifications@example.com"
				openssl_verify_mode: "peer"
				port:                587
				server:              "smtp.mailgun.org"
				tls:                 false
				login:               ""
				password:            ""
				existingSecret:      ""
			}
		}

		streaming: {
			image: {
				repository: "ghcr.io/mastodon/mastodon-streaming"
				tag:        "v4.3.22"
			}
			port:     4000
			workers:  1
			base_url: null
			replicas: 2
			affinity: {}
			nodeSelector: {}
			annotations:  {}
			labels:         {}
			podAnnotations: {}
			podLabels:      {}
			updateStrategy: {
				type: "RollingUpdate"
				rollingUpdate: {
					maxSurge:       "10%"
					maxUnavailable: "25%"
				}
			}
			topologySpreadConstraints: []
			podSecurityContext:         {}
			securityContext:            {}
			resources:                  {}
			
			pdb: {
			   enable:   true
			   // minAvailable: 1
			   maxUnavailable: 1
			}

			extraCerts:                 {}
			extraEnvVars:               {}
		}

		web: {
			port:     3000
			replicas: 2
			affinity: {}
			nodeSelector: {}
			annotations:  {}
			labels:         {}
			podAnnotations: {}
			podLabels:      {}
			updateStrategy: {
				type: "RollingUpdate"
				rollingUpdate: {
					maxSurge:       "10%"
					maxUnavailable: "25%"
				}
			}
			topologySpreadConstraints: []
			podSecurityContext:         {}
			securityContext:            {}
			resources:                  {}
			
			pdb: {
			    enable:     true
			    minAvailable: 1
			    // maxUnavailable: 1
			}

			minThreads:                 "5"
			maxThreads:                 "5"
			workers:                    "2"
			persistentTimeout:          "20"
			image: {
				repository: "ghcr.io/mastodon/mastodon"
				tag:        "v4.5.9"
			}
			customDatabaseConfigYml: configMapRef: {
				name: ""
				key:  ""
			}
			otel: {
				enabled:     false
				exporterUri: ""
				namePrefix:  ""
				nameSeparator: ""
			}
		}

		cacheBuster: {
			enabled:    false
			httpMethod: "GET"
			authHeader: ""
			authToken: existingSecret: ""
		}

		metrics: {
			statsd: {
				address: ""
				exporter: {
					enabled: true
					port:    9102
				}
			}
			prometheus: {
				enabled: true
				port:    9394
				web: detailed:     true
				sidekiq: detailed: true
			}
		}

		otel: {
			enabled:       false
			exporterUri:   ""
			namePrefix:    "mastodon"
			nameSeparator: "-"
		}

		preparedStatements: true
		extraEnvVars:       {}
		// This allows internal pod-to-pod traffic to use HTTP by disabling Rails "force_ssl".
		// Set this to false if your organization requires full internal HTTPS.
		disableSslPatch: enabled: true
	}

	ingress: {
		enabled:          false
		annotations:      {}
		ingressClassName: ""
		hosts: [
			{
				host: "mastodon.local"
				paths: [
					{path: "/"},
				]
			},
		]
		tls: [
			{
				secretName: "mastodon-tls"
				hosts: [
					"mastodon.local"
				]
			},
		]
		streaming: {
			enabled:          false
			annotations:      {}
			ingressClassName: ""
			hosts: [
				{
					host: "streaming.mastodon.local"
					paths: [
						{path: "/"},
					]
				},
			]
			tls: [
				{
					secretName: "mastodon-tls"
					hosts: [
						"streaming.mastodon.local"
					]
				},
			]
		}
	}

	httproute: {
		enabled:     true
		labels:      {}
		annotations: {}
		parentRefs: [
			{
				name:        "example-gateway"
				namespace:   "example-gateway-namespace"
				sectionName: "websecure"
			},
		]
		hostnames: ["mastodon.local"]
		streamingParentRefs: [
			{
				name:        "example-streaming-gateway"
				namespace:   "example-streaming-gateway-namespace"
				sectionName: "websecure"
			}
		]
		streamingHostnames: ["streaming-mastodon.local"]
		rules: [
			{
				matches: [
					{
						path: {
							type:  "PathPrefix"
							value: "/"
						}
					},
				]
			},
		]
		streamingRules: [
			{
				matches: [
					{
						path: {
							type:  "PathPrefix"
							value: "/api/v1/streaming"
						}
					},
				]
			},
		]
	}

	elasticsearch: {
		enabled: true
		image: {
			repository: "opensearchproject/opensearch"
			tag:        "3.6.0"
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "512Mi"
			}
			limits: {
				memory: "2048Mi"
			}
		}
		master: nodeSelector:       {}
		data: nodeSelector:         {}
		coordinating: nodeSelector: {}
		ingest: nodeSelector:        {}
		metrics: nodeSelector:       {}
		caSecret: {}
	}

	postgresql: {
		enabled: true
		image: {
			repository: "bitnamilegacy/postgresql"
			tag:        "17.6.0-debian-12-r4"
		}
		postgresqlHostname: ""
		postgresqlPort:     5432
		direct: {
			hostname: ""
			port:     ""
			database: ""
		}
		auth: {
			database:       "mastodon_production"
			username:       "mastodon"
			password:       "mastodon"
			existingSecret: ""
		}
		readReplica: {
			hostname: ""
			port:     "5432"
			auth: {
				database:       ""
				username:       ""
				password:       ""
				existingSecret: ""
			}
		}
		primary: nodeSelector:      {}
		readReplicas: nodeSelector: {}
		backup: cronjob: nodeSelector: {}
	}

	redis: {
		enabled: true
		image: {
			repository: "valkey/valkey"
			tag:        "7.2.11-alpine"
		}
		hostname: ""
		port:     6379
		auth: {
			password:          "mastodon"
			existingSecret:    ""
			existingSecretKey: "redis-password"
		}
		replica: replicaCount: 1
		sidekiq: {
			enabled:  false
			hostname: ""
			port:     6379
			auth: {
				password:          ""
				existingSecret:    ""
				existingSecretKey: "redis-password"
			}
		}
		cache: {
			enabled:  false
			hostname: ""
			port:     6379
			auth: {
				password:          ""
				existingSecret:    ""
				existingSecretKey: "redis-password"
			}
		}
		master: nodeSelector:  {}
		replica: nodeSelector: {}
	}

	service: {
		type: "ClusterIP"
		port: 80
	}

	externalAuth: {
		oidc: {
			enabled: false
		}
		saml: {
			enabled: false
		}
		oauth_global: {
			omniauth_only: false
		}
		cas: {
			enabled: false
		}
		pam: {
			enabled: false
		}
		ldap: {
			enabled: false
		}
	}

	podSecurityContext: {
		runAsUser:  991
		runAsGroup: 991
		fsGroup:    991
	}

	securityContext: {}

	serviceAccount: {
		create:      true
		annotations: {}
		name:        ""
	}

	deploymentAnnotations: {}
	podAnnotations:        {}
	revisionPodAnnotation: true
	jobLabels:             {}
	jobAnnotations:        {}
	resources:             {}
	tolerations:           []
	affinity:              {}
	nodeSelector:          {}
	timezone:              "UTC"
	topologySpreadConstraints: []
	volumeMounts: []
	volumes: []
}
