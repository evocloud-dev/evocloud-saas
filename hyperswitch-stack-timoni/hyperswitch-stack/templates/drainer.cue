package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DrainerConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "drainer-cm-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"DRAINER__DRAINER__STREAM_NAME":       app.services.drainer.configs.drainer.stream_name
		"DRAINER__DRAINER__NUM_PARTITIONS":    "\(app.services.drainer.configs.drainer.num_partitions)"
		"DRAINER__DRAINER__MAX_READ_COUNT":    "\(app.services.drainer.configs.drainer.max_read_count)"
		"DRAINER__DRAINER__SHUTDOWN_INTERVAL": "\(app.services.drainer.configs.drainer.shutdown_interval)"
		"DRAINER__DRAINER__LOOP_INTERVAL":     "\(app.services.drainer.configs.drainer.loop_interval)"
		"DRAINER__SECRETS__MASTER_KEY":        app.services.drainer.configs.secrets.master_key
		"DRAINER__REDIS__POOL_SIZE":           "\(app.services.drainer.configs.redis.pool_size)"
		"DRAINER__REDIS__CLUSTER_ENABLED":     "\(app.services.drainer.configs.redis.cluster_enabled)"
		"DRAINER__LOG__FILE__ENABLED":         "false"
		"DRAINER__LOG__CONSOLE__ENABLED":      "true"
		"DRAINER__MASTER_DATABASE__CONNECTION_TIMEOUT": "10"
		"DRAINER__LOG__CONSOLE__LEVEL":        "debug"
		"DRAINER__REDIS__USE_LEGACY_VERSION":  "true"
		"DRAINER__REDIS__ENABLED":             "true"
		"DRAINER__REDIS__DB":                  "0"
		let _redisInit = #RedisInitContainer & {#config: #config}
		"DRAINER__REDIS__HOST":                _redisInit.redisHost
		"DRAINER__REDIS__PORT":                "6379"
		"DRAINER__REDIS__URL":                 "redis://\(_redisInit.redisHost):6379/0"
		"ROUTER__REDIS__HOST":                _redisInit.redisHost
		"ROUTER__REDIS__PORT":                "6379"
		"ROUTER__REDIS__ENABLED":             "true"
		"ROUTER__REDIS__CLUSTER_ENABLED":     "false"
		"ROUTER__EMAIL__SMTP__USERNAME":      "hyperswitch"
		"ROUTER__EMAIL__SMTP__PASSWORD":      "hyperswitch"
		"DRAINER__SERVER__HOST":              "0.0.0.0"
	}
}

#DrainerSecret: corev1.#Secret & {
	#config: #Config

	let _pgInit = #PostgresqlInitContainer & {#config: #config}
	let _redisInit = #RedisInitContainer & {#config: #config}

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "drainer-secret-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	// Timoni automatically base64 encodes stringData when rendering to Kubernetes,
	// but Timoni CUE doesn't have a built-in base64 stringData to data converter by default unless rendered.
	// Since K8s v1.#Secret supports stringData natively, we can just use stringData!
	stringData: {
		"DRAINER__MASTER_DATABASE__HOST":     _pgInit.pgHost
		"DRAINER__MASTER_DATABASE__DBNAME":   _pgInit.pgDB
		"DRAINER__MASTER_DATABASE__PORT":     "5432"
		"DRAINER__MASTER_DATABASE__USERNAME": _pgInit.pgUser
		"DRAINER__REDIS__HOST":               _redisInit.redisHost
		"DRAINER__REDIS__PORT":               "6379"
	}
}

#DrainerDeployment: appsv1.#Deployment & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:        "\(#config.metadata.name)-drainer"
		namespace:   #config.metadata.namespace
		annotations: #config.global.annotations & app.services.drainer.annotations
		labels: #config.global.labels & app.services.drainer.labels & {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-drainer"
			"app.kubernetes.io/version":    app.services.drainer.version
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app":                          "\(#config.metadata.name)-drainer"
			"version":                      app.services.drainer.version
		}
	}
	spec: {
		progressDeadlineSeconds: app.services.drainer.progressDeadlineSeconds
		replicas:                app.services.drainer.replicas
		selector: matchLabels: {
			"app":                        "\(#config.metadata.name)-drainer"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		strategy: app.services.drainer.strategy

		template: {
			metadata: {
				annotations: #config.global.podAnnotations & app.services.drainer.podAnnotations & {
					"checksum/drainer-cm":     "dynamic-checksum-by-timoni"
					"checksum/drainer-secret": "dynamic-checksum-by-timoni"
				}
				labels: #config.global.labels & app.services.drainer.labels & {
					"app.kubernetes.io/name":       "\(#config.metadata.name)-drainer"
					"app.kubernetes.io/version":    app.services.drainer.version
					"app.kubernetes.io/instance":   #config.metadata.name
					"app.kubernetes.io/managed-by": "timoni"
					"app":                          "\(#config.metadata.name)-drainer"
					"version":                      app.services.drainer.version
				}
			}
			spec: {
				tolerations:  #config.global.tolerations
				affinity:     app.services.drainer.affinity
				nodeSelector: #config.global.nodeSelector

				if len(#config.global.tolerations) == 0 && len((app.services.drainer.tolerations | *[])) > 0 {
					tolerations: app.services.drainer.tolerations
				}
				if len(#config.global.nodeSelector) == 0 && len((app.services.drainer.nodeSelector | *{})) > 0 {
					nodeSelector: app.services.drainer.nodeSelector
				}

				_pgInit: (#PostgresqlInitContainer & {#config: #config}).container
				_redisInit: (#RedisInitContainer & {#config: #config}).container

				initContainers: [
					if app.initDB.enable {_pgInit},
					if app.redisMiscConfig.checkRedisIsUp.initContainer.enable {_redisInit},
				]

				_metaEnvs: #MetadataEnvs
				_genericEnvs: (#GenericEnvs & {#config: #config}).env
				_pgEnvVars: (#PostgresqlSecretsEnvs & {#config: #config}).env
				_pgPass: [for env in _pgEnvVars if env.name == "ROUTER__MASTER_DATABASE__PASSWORD" {env.valueFrom}][0]

				_drainerSecretEnvs: [
					if !#config.disableInternalSecrets {
						name:      "DRAINER__MASTER_DATABASE__PASSWORD"
						valueFrom: _pgPass
					},
				]

				containers: [
					{
						name:            "hyperswitch-drainer"
						image:           "\([if #config.global.imageRegistry != "" {#config.global.imageRegistry}, app.services.drainer.imageRegistry][0])/\(app.services.drainer.image):\(app.services.drainer.version)"
						imagePullPolicy: "Always"
						ports: [
							{
								containerPort: 8080
								name:          "http"
								protocol:      "TCP"
							},
						]
						env: list.Concat([
							#config.global.env,
							app.services.drainer.env,
							_drainerSecretEnvs,
							_genericEnvs,
							_metaEnvs,
							[
								{
									name:  "DRAINER__REDIS__HOST"
									value: (#RedisInitContainer & {#config: #config}).redisHost
								},
								{
									name:  "DRAINER__REDIS__PORT"
									value: "6379"
								},
								{
									name:  "DRAINER__REDIS__ENABLED"
									value: "true"
								},
								{
									name:  "DRAINER__REDIS__USE_LEGACY_VERSION"
									value: "true"
								},
								{
									name:  "ROUTER__REDIS__HOST"
									value: (#RedisInitContainer & {#config: #config}).redisHost
								},
								{
									name:  "ROUTER__REDIS__PORT"
									value: "6379"
								},
								{
									name:  "ROUTER__REDIS__ENABLED"
									value: "true"
								},
								{
									name:  "ROUTER__API_KEYS__HASH_KEY"
									value: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
								},
							],
						])
						envFrom: [
							{configMapRef: {name: "\(#config.metadata.name)-configs"}},
							{configMapRef: {name: "drainer-cm-\(#config.metadata.name)"}},
							if !#config.disableInternalSecrets {
								{secretRef: {name: "drainer-secret-\(#config.metadata.name)"}}
							},
						]
						resources: app.services.drainer.resources
						securityContext: {
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
							privileged:               false
							readOnlyRootFilesystem:   false
							runAsGroup:               1000
							runAsNonRoot:            true
							runAsUser:                1000
						}
						volumeMounts: [
							{
								mountPath: "/local/config/\(app.server.run_env).toml"
								name:      "hyperswitch-config"
								subPath:   "router.toml"
							},
							{
								mountPath: "/var/log/hyperswitch"
								name:      "log-dir"
							},
						]
					},
				]
				securityContext: fsGroup: 1000
				terminationGracePeriodSeconds: app.services.drainer.terminationGracePeriodSeconds
				serviceAccountName:            "\(#config.metadata.name)-router-role"
				volumes: [
					{
						name: "hyperswitch-config"
						configMap: {
							name:        "router-cm-\(#config.metadata.name)"
							defaultMode: 420
						}
					},
					{
						name: "log-dir"
						emptyDir: {}
					},
				]
			}
		}
	}
}
