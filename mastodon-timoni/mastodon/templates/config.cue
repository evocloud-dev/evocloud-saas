package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: *"1.31.0" | string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: *"0.0.1" | string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion, #Name: "mastodon"}
	metadata: name: *"mastodon" | string

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository and tag is set in `values.cue`.
	image: {
		repository: *"" | string
		tag:        *"" | string
		pullPolicy: *"IfNotPresent" | string
		reference:  *"\(repository):\(tag)" | string
	}

	// The resources allows setting the container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"128Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The number of pods replicas.
	replicas: *1 | int
	revisionPodAnnotation: *true | bool
	timezone: * "UTC" | string
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]
	tolerations: *[] | [...corev1.#Toleration]
	affinity:    *{} | corev1.#Affinity
	nodeSelector: *{} | {[string]: string}
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	
	deploymentAnnotations: *{} | {[string]: string}
	podAnnotations: *{} | {[string]:        string}
	jobLabels: *{} | {[string]:             string}
	jobAnnotations: *{} | {[string]:        string}

	service: {
		type: *"ClusterIP" | string
		port: *80 | int
	}

	externalAuth: {
		oidc: {
			enabled:                     *false | bool
			display_name:                *"" | string
			issuer:                      *"" | string
			discovery:                   *true | bool
			scope:                       *["openid", "profile", "email"] | [...string]
			uid_field:                   *"preferred_username" | string
			client_id:                   *"" | string
			client_secret:               *"" | string
			redirect_uri:                *"" | string
			assume_email_is_verified:    *false | bool
			client_auth_method:          *"" | string
			response_type:               *"" | string
			response_mode:               *"" | string
			display:                     *"" | string
			prompt:                      *"" | string
			send_nonce:                  *"" | string
			send_scope_to_token_endpoint: *"" | string
			idp_logout_redirect_uri:     *"" | string
			http_scheme:                 *"" | string
			host:                        *"" | string
			port:                        *"" | string
			jwks_uri:                    *"" | string
			auth_endpoint:               *"" | string
			token_endpoint:              *"" | string
			user_info_endpoint:          *"" | string
			end_session_endpoint:        *"" | string
		}
		saml: {
			enabled:                   *false | bool
			acs_url:                   *"" | string
			issuer:                    *"" | string
			idp_sso_target_url:        *"" | string
			idp_cert:                  *"" | string
			idp_cert_fingerprint:      *"" | string
			name_identifier_format:    *"" | string
			cert:                      *"" | string
			private_key:               *"" | string
			want_assertion_signed:     *"" | string
			want_assertion_encrypted:  *"" | string
			assume_email_is_verified:  *"" | string
			uid_attribute:             *"" | string
			attributes_statements: {
				uid:            *"" | string
				email:          *"" | string
				full_name:      *"" | string
				first_name:     *"" | string
				last_name:      *"" | string
				verified:       *"" | string
				verified_email: *"" | string
			}
		}
		oauth_global: {
			omniauth_only: *false | bool
		}
		cas: {
			enabled:                  *false | bool
			url:                      *"" | string
			host:                     *"" | string
			port:                     *443 | int
			ssl:                      *true | bool
			validate_url:             *"" | string
			callback_url:             *"" | string
			logout_url:               *"" | string
			login_url:                *"" | string
			uid_field:                *"" | string
			ca_path:                  *"" | string
			disable_ssl_verification: *"" | string
			assume_email_is_verified: *"" | string
			keys: {
				uid:        *"" | string
				name:       *"" | string
				email:      *"" | string
				nickname:   *"" | string
				first_name: *"" | string
				last_name:  *"" | string
				location:   *"" | string
				image:      *"" | string
				phone:      *"" | string
			}
		}
		pam: {
			enabled:            *false | bool
			email_domain:       *"" | string
			default_service:    *"" | string
			controlled_service: *"" | string
		}
		ldap: {
			enabled: *false | bool
			host:    *"" | string
			port:    *389 | int
			method:  *"simple" | string
			tls_no_verify: *"" | string
			base:          *"" | string
			bind_dn:       *"" | string
			password:      *"" | string
			uid:           *"" | string
			mail:          *"" | string
			search_filter: *"" | string
			uid_conversion: {
				enabled: *"" | string
				search:  *"" | string
				replace: *"" | string
			}
			passwordSecretRef: {
				name: *"" | string
				key:  *"" | string
			}
		}
	}

	volumeMounts: *[] | [...corev1.#VolumeMount]
	volumes: *[] | [...corev1.#Volume]

	// The securityContext allows setting the container security context.
	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		privileged:               *false | bool
		runAsNonRoot:             *true | bool
		capabilities: {
			drop: *["ALL"] | [...string]
		}
		seccompProfile: {
			type: *"RuntimeDefault" | string
		}
		runAsUser: *991 | int
	}
	podSecurityContext: corev1.#PodSecurityContext & {
		runAsUser:  *991 | int
		runAsGroup: *991 | int
		fsGroup:    *991 | int
	}

	test: {
		enabled: *false | bool
	}

	// Define local aliases for defaults to be used in overrides
	_image: image
	_resources: resources
	_podSecurityContext: podSecurityContext
	_securityContext: securityContext
	_affinity: affinity
	_nodeSelector: nodeSelector
	_tolerations: tolerations
	_topologySpreadConstraints: topologySpreadConstraints

	// App settings.
	mastodon: {
		logLevel: {
			rails:     *"info" | string
			streaming: *"info" | string
		}
		labels: *{} | {[string]:    string}
		podLabels: *{} | {[string]: string}
		createAdmin: {
			enabled:      *true | bool
			username:     *"admin" | string
			email:        *"admin@example.com" | string
			nodeSelector: *_nodeSelector | {[string]: string}
		}
		hooks: {
			dbPrepare: {
				enabled:      *true | bool
				nodeSelector: *_nodeSelector | {[string]: string}
			}
			dbMigrate: {
				enabled:      *true | bool
				nodeSelector: *_nodeSelector | {[string]: string}
			}
			deploySearch: {
				enabled:     *false | bool
				resetChewy:  *true | bool
				only:        *"" | string
				concurrency: *5 | int
				resources:   *_resources | corev1.#ResourceRequirements
			}
			s3Upload: {
				enabled:  *false | bool
				endpoint: *"" | string
				bucket:   *"" |   string
				acl:      *"public-read" |   string
				secretRef: {
					name: *"" | string
					keys: {
						accesKeyId:      *"access-key-id" | string
						secretAccessKey: *"secret-access-key" | string
					}
				}
				rclone: env: *{} | {[string]: string}
				nodeSelector: *_nodeSelector | {[string]: string}
			}
		}
		cron: {
			removeMedia: {
				enabled:      *true | bool
				schedule:     *"0 0 * * 0" | string
				nodeSelector: *_nodeSelector | {[string]: string}
			}
		}
		locale:            *"" | string
		local_domain:      *"mastodon.local" | string
		web_domain:        *null | string | null
		alternate_domains: *[] | [...string]
		singleUserMode:    *false | bool
		authorizedFetch:   *false | bool
		limitedFederationMode: *false | bool
		disableSslPatch: {
			enabled: *true | bool
		}
		persistence: {
			assets: {
				accessMode:      *"ReadWriteOnce" | string
				keepAfterDelete: *true | bool
				resources: requests: storage: *"10Gi" | string
				existingClaim: *"" | string
				storageClassName: *null | string | null
			}
			system: {
				accessMode:      *"ReadWriteOnce" | string
				keepAfterDelete: *true | bool
				resources: requests: storage: *"100Gi" | string
				existingClaim: *"" | string
				storageClassName: *null | string | null
			}
		}
		s3: {
			enabled:             *false | bool
			access_key:          *"" | string
			access_secret:       *"" | string
			existingSecret:      *"" | string
			bucket:              *"" | string
			endpoint:            *"" | string
			protocol:            *"https" | string
			hostname:            *"" | string
			region:              *"us-east-1" | string
			permission:          *"public-read" | string
			alias_host:          *"" | string
			multipart_threshold: *"100MB" | string
		}
		deepl: {
			enabled: *false | bool
			plan:    *"free" | string
			apiKeySecretRef: {
				name: *"" | string
				key:  *"" | string
			}
		}
		hcaptcha: {
			enabled: *false | bool
			siteId:  *"" | string
			secretKeySecretRef: {
				name: *"" | string
				key:  *"" | string
			}
		}
		secrets: {
			secret_key_base: *"e57b8506691c28f09b83b37e8c07e9d7c0f1e2d3c4b5a69788f9e0d1c2b3a4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7" | string
			otp_secret:      *"c0f1e2d3c4b5a69788f9e0d1c2b3a4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7e57b8506691c28f09b83b37e8c07e9d7" | string
			vapid: {
				private_key: *"" | string
				public_key:  *"" | string
			}
			activeRecordEncryption: {
				primaryKey:        *"SGVsbG8gV29ybGQgZnJvbSBQcm90b2NvbCBCdWZmZXJzIQ==" | string
				deterministicKey:  *"QW50aWdyYXZpdHkgaXMgYXdlc29tZSEhISEhISEhISE=" | string
				keyDerivationSalt: *"U2FsdGVkX19WZXJ5U2VjcmV0U2FsdA==" | string
			}
			existingSecret: *"" | string
		}
		revisionHistoryLimit: *2 | int
		sidekiq: {
			podSecurityContext: *_podSecurityContext | corev1.#PodSecurityContext
			securityContext:    *_securityContext | corev1.#SecurityContext
			resources:          *_resources | corev1.#ResourceRequirements
			affinity:           *_affinity | corev1.#Affinity
			nodeSelector: *_nodeSelector | {[string]: string}
			annotations: *{} | {[string]:  string}
			labels: *{} | {[string]:       string}
			podAnnotations: *{} | {[string]: string}
			podLabels: *{} | {[string]:      string}
			updateStrategy: {
				type: *"RollingUpdate" | "Recreate"
				rollingUpdate?: {
					maxSurge:       *"25%" | string | int
					maxUnavailable: *"25%" | string | int
				}
			}
			readinessProbe: {
				enabled:             *true | bool
				path:                *"/health" | string
				initialDelaySeconds: *0 | int
				periodSeconds:        *10 | int
				successThreshold:    *1 | int
				timeoutSeconds:      *1 | int
				failureThreshold?:   *3 | int
			}
			topologySpreadConstraints: *_topologySpreadConstraints | [...corev1.#TopologySpreadConstraint]
			otel: {
				enabled:       *false | bool
				exporterUri:   *"" | string
				namePrefix:    *"" | string
				nameSeparator: *"" | string
			}
			workers: [...{
				name:        string
				concurrency: *5 | int
				replicas:    *1 | int
				resources:   *_resources | corev1.#ResourceRequirements
				affinity:    *_affinity | corev1.#Affinity
				nodeSelector: *_nodeSelector | {[string]: string}
				topologySpreadConstraints: *_topologySpreadConstraints | [...corev1.#TopologySpreadConstraint]
				queues: [...string]
				image: {
					repository: *_image.repository | string
					tag:        *_image.tag | string
					pullPolicy: *_image.pullPolicy | string
					reference:  *"\(repository):\(tag)" | string
				}
				customDatabaseConfigYml: configMapRef: {
					name: *"" | string
					key:  *"database.yml" | string
				}
			}]
			workers: [
				{
					name: "all-queues"
					queues: ["default,8", "push,6", "ingress,4", "mailers,2", "pull", "scheduler", "fasp"]
				}
			]
		}
		smtp: {
			auth_method:          *"plain" | string
			ca_file:              *"/etc/ssl/certs/ca-certificates.crt" | string
			delivery_method:      *"smtp" | string
			domain:               *"" | string
			enable_starttls:      *"auto" | string
			from_address:         *"notifications@example.com" | string
			return_path:          *"" | string
			openssl_verify_mode: *"peer" | string
			port:                 *587 | int
			reply_to:             *"" | string
			server:               *"" | string
			tls:                  *false | bool
			login:                *"" | string
			password:             *"" | string
			existingSecret:       *"" | string
			bulk: {
				enabled:             *false | bool
				auth_method:         *"plain" | string
				ca_file:             *"/etc/ssl/certs/ca-certificates.crt" | string
				domain:              *"" | string
				enable_starttls:     *"auto" | string
				from_address:        *"" | string
				openssl_verify_mode: *"peer" | string
				port:                *587 | int
				server:              *"" | string
				tls:                 *false | bool
				login:               *"" | string
				password:            *"" | string
				existingSecret:      *"" | string
			}
		}
		streaming: {
			image: {
				repository: *_image.repository | string
				tag:        *_image.tag | string
				pullPolicy: *_image.pullPolicy | string
				reference:  *"\(repository):\(tag)" | string
			}
			port:     *8080 | int
			workers:  *5 | int
			base_url: *null | string | null
			replicas: *1 | int
			affinity: *_affinity | corev1.#Affinity
			nodeSelector: *_nodeSelector | {[string]: string}
			annotations: *{} | {[string]:  string}
			labels: *{} | {[string]:         string}
			podAnnotations: *{} | {[string]: string}
			podLabels: *{} | {[string]:      string}
			updateStrategy: {
				type: *"RollingUpdate" | "Recreate"
				rollingUpdate?: {
					maxSurge:       *"25%" | string | int
					maxUnavailable: *"25%" | string | int
				}
			}
			topologySpreadConstraints: *_topologySpreadConstraints | [...corev1.#TopologySpreadConstraint]
			podSecurityContext:         *_podSecurityContext | corev1.#PodSecurityContext
			securityContext:            *_securityContext | corev1.#SecurityContext
			resources:                  *_resources | corev1.#ResourceRequirements
			pdb: {
				enable:          *true | bool
				minAvailable?:   int | string
				maxUnavailable?: int | string
			}
			livenessProbe: *{path: "/api/v1/streaming/health", port: "streaming"} | {[string]:    string | int}
			readinessProbe: *{path: "/api/v1/streaming/health", port: "streaming"} | {[string]:   string | int}
			startupProbe: *{path: "/api/v1/streaming/health", port: "streaming"} | {[string]:     string | int}
			extraCerts: {
				existingSecret: *"" | string
				name:           *"" | string
			}
			extraEnvVars: *{} | {[string]:     string}
		}
		web: {
			port:     *3000 | int
			replicas: *1 | int
			affinity: *_affinity | corev1.#Affinity
			nodeSelector: *_nodeSelector | {[string]: string}
			annotations: *{} | {[string]:  string}
			labels: *{} | {[string]:         string}
			podAnnotations: *{} | {[string]: string}
			podLabels: *{} | {[string]:      string}
			updateStrategy: {
				type: *"RollingUpdate" | "Recreate"
				rollingUpdate?: {
					maxSurge:       *"25%" | string | int
					maxUnavailable: *"25%" | string | int
				}
			}
			topologySpreadConstraints: *_topologySpreadConstraints | [...corev1.#TopologySpreadConstraint]
			podSecurityContext:         *_podSecurityContext | corev1.#PodSecurityContext
			securityContext:            *_securityContext | corev1.#SecurityContext
			resources:                  *_resources | corev1.#ResourceRequirements
			pdb: {
				enable:          *true | bool
				minAvailable?:   int | string
				maxUnavailable?: int | string
			}
			livenessProbe: *{port: "http"} | {[string]:    string | int}
			readinessProbe: *{path: "/health", port: "http"} | {[string]:   string | int}
			startupProbe: *{path: "/health", port: "http"} | {[string]:     string | int}
			minThreads:                 *"5" | string
			maxThreads:                 *"5" | string
			workers:                    *"2" | string
			persistentTimeout:          *"20" | string
			mallocArenaMax?:            string
			ldPreload:                  *"" | string
			image: {
				repository: *_image.repository | string
				tag:        *_image.tag | string
				pullPolicy: *_image.pullPolicy | string
				reference:  *"\(repository):\(tag)" | string
			}
			customDatabaseConfigYml: configMapRef: {
				name: *"" | string
				key:  *"database.yml" | string
			}
			otel: {
				enabled:     *false | bool
				exporterUri: *"" | string
				namePrefix:  *"" | string
				nameSeparator: *"" | string
			}
			extraCerts: {
				existingSecret: *"" | string
				name:           *"" | string
			}
		}
		cacheBuster: {
			enabled:    *false | bool
			httpMethod: *"GET" | string
			authHeader: *"" | string
			authToken: existingSecret: *"" | string
		}
		metrics: {
			statsd: {
				address: *"" | string
				exporter: {
					enabled: *false | bool
					port:    *9102 | int
				}
			}
			prometheus: {
				enabled: *false | bool
				port:    *10000 | int
				web: detailed:     *false | bool
				sidekiq: detailed: *false | bool
			}
		}
		otel: {
			enabled:       *false | bool
			exporterUri:   *"" | string
			namePrefix:    *"" | string
			nameSeparator: *"" | string
		}
		preparedStatements: *true | bool
		extraEnvVars: *{} | {[string]: string}
		extraEnvFrom: *"" | string
		trusted_proxy_ip: *null | string | null
	}

	ingress: {
		enabled:          *false | bool
		annotations: *{} | {[string]: string}
		ingressClassName: *"" | string
		hosts: *[] | [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"ImplementationSpecific" | "Prefix" | "Exact"
			}]
		}]
		tls: *[] | [...{
			secretName: string
			hosts: [...string]
		}]
		streaming: {
			enabled:          *false | bool
			annotations: *{} | {[string]: string}
			ingressClassName: *"" | string
			hosts: *[] | [...{
				host: string
				paths: [...{
					path:     string
					pathType: *"ImplementationSpecific" | "Prefix" | "Exact"
				}]
			}]
			tls: *[] | [...{
				secretName: string
				hosts: [...string]
			}]
		}
	}

	httproute: {
		enabled:     *false | bool
		labels: *{} | {[string]:      string}
		annotations: *{} | {[string]: string}
		parentRefs: *[] | [...{
			name:        string
			namespace:   string
			sectionName: *"" | string
		}]
		hostnames: *[] | [...string]
		streamingParentRefs: *[] | [...{
			name:        string
			namespace:   string
			sectionName: *"" | string
		}]
		streamingHostnames: *[] | [...string]
		rules: *[] | [..._]
		streamingRules: *[] | [..._]
	}

	elasticsearch: {
		enabled: *false | bool
		image: {
			repository: *"opensearchproject/opensearch" | string
			tag:        *"3.6.0" | string
			pullPolicy: *"IfNotPresent" | string
		}
		hostname:       *"" | string
		port:           *9200 | int
		tls:            *false | bool
		preset:         *"single-node" | string
		user:           *"admin" | string
		existingSecret: *"" | string
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | corev1.#ResourceQuantity
				memory: *"512Mi" | corev1.#ResourceQuantity
			}
			limits: {
				memory: *"2048Mi" | corev1.#ResourceQuantity
			}
		}
		master: nodeSelector: *_nodeSelector | {[string]:       string}
		data: nodeSelector: *_nodeSelector | {[string]:         string}
		coordinating: nodeSelector: *_nodeSelector | {[string]: string}
		ingest: nodeSelector: *_nodeSelector | {[string]:       string}
		metrics: nodeSelector: *_nodeSelector | {[string]:      string}
		caSecret: {
			name?: string
			key:   *"ca.crt" | string
		}
		indexPrefix: *"" | string
	}

	postgresql: {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/postgresql" | string
			tag:        *"14.2.3" | string
			pullPolicy: *"IfNotPresent" | string
		}
		postgresqlHostname: *"" | string
		postgresqlPort:     *5432 | int
		direct: {
			hostname: *null | string | null
			port:     *null | int | string | null
			database: *null | string | null
		}
		auth: {
			database:       *"mastodon" | string
			username:       *"mastodon" | string
			password:       *"" | string
			existingSecret: *"" | string
		}
		readReplica: {
			hostname: *"" | string
			port:     *5432 | int | string
			auth: {
				database:       *"mastodon" | string
				username:       *"mastodon" | string
				password:       *"" | string
				existingSecret: *"" | string
			}
		}
		primary: nodeSelector: *_nodeSelector | {[string]:      string}
		readReplicas: nodeSelector: *_nodeSelector | {[string]: string}
		backup: cronjob: nodeSelector: *_nodeSelector | {[string]: string}
	}

	redis: {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/redis" | string
			tag:        *"22.0.7" | string
			pullPolicy: *"IfNotPresent" | string
		}
		hostname: *"" | string
		port:     *6379 | int
		auth: {
			password:          *"" | string
			existingSecret:    *"" | string
			existingSecretKey: *"redis-password" | string
		}
		replica: replicaCount: *0 | int
		sidekiq: {
			enabled:  *false | bool
			hostname: *"" | string
			port:     *6379 | int
			auth: {
				password:          *"" | string
				existingSecret:    *"" | string
				existingSecretKey: *"redis-password" | string
			}
		}
		cache: {
			enabled:  *false | bool
			hostname: *"" | string
			port:     *6379 | int
			auth: {
				password:          *"" | string
				existingSecret:    *"" | string
				existingSecretKey: *"redis-password" | string
			}
		}
		master: nodeSelector: *_nodeSelector | {[string]:  string}
		replica: nodeSelector: *_nodeSelector | {[string]: string}
	}

	serviceAccount: {
		create:      *true | bool
		annotations: *{} | {[string]: string}
		name:        *"" | string
	}


	// Helpers (internal logic)
	#fullname:  metadata.name
	#namespace: metadata.namespace
	#labels:    metadata.labels
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa:       #ServiceAccount & {#config: config}
		cm:       #ConfigMap & {#config: config}
		"cm-patch": #ConfigMapPatch & {#config: config}

		web: #WebDeployment & {#config: config}
		"web-svc": #ServiceWeb & {#config: config}
		
		streaming: #StreamingDeployment & {#config: config}
		"streaming-svc": #ServiceStreaming & {#config: config}

		for w in config.mastodon.sidekiq.workers {
			"sidekiq-\(w.name)": #SidekiqDeployment & {#config: config, #worker: w}
		}

		if config.ingress.enabled {
			"web-ingress": #IngressWeb & {#config: config}
		}
		if config.ingress.streaming.enabled {
			"streaming-ingress": #IngressStreaming & {#config: config}
		}

		if config.httproute.enabled {
			"web-httproute": #HTTPRouteWeb & {#config: config}
		}
		if config.httproute.enabled {
			"streaming-httproute": #HTTPRouteStreaming & {#config: config}
		}

		if !config.mastodon.s3.enabled && config.mastodon.persistence.assets.existingClaim == "" {
			"pvc-assets": #PvcAssets & {#config: config}
		}
		if !config.mastodon.s3.enabled && config.mastodon.persistence.system.existingClaim == "" {
			"pvc-system": #PvcSystem & {#config: config}
		}

		if config.mastodon.secrets.existingSecret == "" {
			"secret-mastodon": #SecretMain & {#config: config}
		}
		if config.postgresql.enabled && config.postgresql.auth.existingSecret == "" {
			"secret-postgresql": #SecretPostgresql & {#config: config}
		}
		if config.mastodon.secrets.existingSecret == "" {
			"secret-prepare": #SecretPrepare & {#config: config}
		}
		if config.elasticsearch.enabled {
			"secret-elasticsearch": #SecretElasticsearch & {#config: config}
		}
		if config.redis.enabled && config.redis.auth.existingSecret == "" {
			"secret-redis": #SecretRedis & {#config: config}
		}
		if !config.redis.enabled && config.redis.auth.existingSecret == "" && config.redis.auth.password != "" {
			"secret-redis-pre-install": #SecretRedisPreInstall & {#config: config}
		}

		if config.mastodon.smtp.existingSecret == "" {
			"secret-smtp": #SecretSMTP & {#config: config}
		}
		if config.mastodon.smtp.bulk.enabled && config.mastodon.smtp.bulk.existingSecret == "" {
			"secret-smtp-bulk": #SecretSMTPBulk & {#config: config}
		}

		if config.mastodon.createAdmin.enabled {
			"job-create-admin": #JobCreateAdmin & {#config: config}
		}
		if config.mastodon.hooks.dbPrepare.enabled {
			"job-db-prepare": #JobDbPrepare & {#config: config}
		}
		if config.mastodon.hooks.dbMigrate.enabled {
			"job-db-pre-migrate": #JobDbPreMigrate & {#config: config}
			"job-db-migrate":     #JobDbMigrate & {#config: config}
		}
		if config.mastodon.hooks.deploySearch.enabled && config.elasticsearch.enabled {
			"job-deploy-search": #JobDeploySearch & {#config: config}
		}
		if config.mastodon.hooks.s3Upload.enabled {
			"job-assets-copy": #JobAssetsCopy & {#config: config}
		}
		if config.mastodon.cron.removeMedia.enabled {
			"cronjob-media-remove": #CronJobMediaRemove & {#config: config}
		}
		if config.mastodon.metrics.statsd.exporter.enabled && config.mastodon.metrics.statsd.address == "" {
			"statsd-mappings": #StatsDExporterMappings & {#config: config}
		}

		if config.mastodon.web.pdb.enable {
			"web-pdb": #PdbWeb & {#config: config}
		}
		if config.mastodon.streaming.pdb.enable {
			"streaming-pdb": #PdbStreaming & {#config: config}
		}

		if config.postgresql.enabled {
			"postgresql-svc": (#Postgresql & {#config: config}).service
			"postgresql-sts": (#Postgresql & {#config: config}).statefulSet
		}
		if config.redis.enabled {
			"redis-svc": (#Redis & {#config: config}).service
			"redis-sts": (#Redis & {#config: config}).statefulSet
		}
		if config.elasticsearch.enabled {
			"elasticsearch-svc-hl": (#Elasticsearch & {#config: config}).serviceHL
			"elasticsearch-svc":    (#Elasticsearch & {#config: config}).service
			"elasticsearch-sts":    (#Elasticsearch & {#config: config}).statefulSet
		}
	}

	tests: {
		"test-svc": #TestJob & {#config: config}
	}
}
