package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#ProducerConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "producer-cm-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"ROUTER__SCHEDULER__CONSUMER_GROUP":             app.services.producer.configs.scheduler.consumer_group
		"ROUTER__SCHEDULER__GRACEFUL_SHUTDOWN_INTERVAL": "\(app.services.producer.configs.scheduler.graceful_shutdown_interval)"
		"ROUTER__SCHEDULER__LOOP_INTERVAL":              "\(app.services.producer.configs.scheduler.loop_interval)"
		"ROUTER__SCHEDULER__STREAM":                     app.services.producer.configs.scheduler.stream
		"ROUTER__SCHEDULER__PRODUCER__BATCH_SIZE":       "\(app.services.producer.configs.scheduler.producer.batch_size)"
		"ROUTER__SCHEDULER__PRODUCER__LOCK_KEY":         app.services.producer.configs.scheduler.producer.lock_key
		"ROUTER__SCHEDULER__PRODUCER__LOCK_TTL":         "\(app.services.producer.configs.scheduler.producer.lock_ttl)"
		"ROUTER__SCHEDULER__PRODUCER__LOWER_FETCH_LIMIT": "\(app.services.producer.configs.scheduler.producer.lower_fetch_limit)"
		"ROUTER__SCHEDULER__PRODUCER__UPPER_FETCH_LIMIT": "\(app.services.producer.configs.scheduler.producer.upper_fetch_limit)"
		"ROUTER__SCHEDULER__SERVER__PORT":               "\(app.services.producer.configs.scheduler.server.port)"
		"ROUTER__SCHEDULER__SERVER__HOST":               app.services.producer.configs.scheduler.server.host
		"ROUTER__SCHEDULER__SERVER__WORKERS":            "\(app.services.producer.configs.scheduler.server.workers)"
	}
}

#ProducerDeployment: appsv1.#Deployment & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:        "\(#config.metadata.name)-producer"
		namespace:   #config.metadata.namespace
		annotations: #config.global.annotations & app.services.producer.annotations
		labels: #config.global.labels & app.services.producer.labels & {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-producer"
			"app.kubernetes.io/version":    app.services.producer.version
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app":                          "\(#config.metadata.name)-producer"
			"version":                      app.services.producer.version
		}
	}
	spec: {
		progressDeadlineSeconds: app.services.producer.progressDeadlineSeconds
		replicas:                app.services.producer.replicas
		revisionHistoryLimit:    10
		selector: matchLabels: {
			"app":                        "\(#config.metadata.name)-producer"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		strategy: app.services.producer.strategy

		template: {
			metadata: {
				annotations: #config.global.podAnnotations & app.services.producer.podAnnotations & {
					"checksum/producer-config": "dynamic-checksum-by-timoni"
					"checksum/configs":         "dynamic-checksum-by-timoni"
					"checksum/secrets":         "dynamic-checksum-by-timoni"
				}
				labels: #config.global.labels & app.services.producer.labels & {
					"app.kubernetes.io/name":       "\(#config.metadata.name)-producer"
					"app.kubernetes.io/version":    app.services.producer.version
					"app.kubernetes.io/instance":   #config.metadata.name
					"app.kubernetes.io/managed-by": "timoni"
					"app":                          "\(#config.metadata.name)-producer"
					"version":                      app.services.producer.version
				}
			}
			spec: {
				tolerations:  #config.global.tolerations
				affinity:     app.services.producer.affinity
				nodeSelector: #config.global.nodeSelector

				if len(#config.global.tolerations) == 0 && len((app.services.producer.tolerations | *[])) > 0 {
					tolerations: app.services.producer.tolerations
				}
				if len(#config.global.nodeSelector) == 0 && len((app.services.producer.nodeSelector | *{})) > 0 {
					nodeSelector: app.services.producer.nodeSelector
				}

				_pgInit: (#PostgresqlInitContainer & {#config: #config}).container
				_redisInit: (#RedisInitContainer & {#config: #config}).container

				initContainers: [
					if app.initDB.enable {_pgInit},
					if app.redisMiscConfig.checkRedisIsUp.initContainer.enable {_redisInit},
				]

				_metaEnvs: #MetadataEnvs
				_genericEnvs: (#GenericEnvs & {#config: #config}).env
				_pgEnvs: (#PostgresqlSecretsEnvs & {#config: #config}).env

				containers: [
					{
						name:            "hyperswitch-producer"
						image:           "\([if #config.global.imageRegistry != "" {#config.global.imageRegistry}, app.services.producer.imageRegistry][0])/\(app.services.producer.image):\(app.services.producer.version)"
						imagePullPolicy: "IfNotPresent"
						lifecycle: preStop: exec: command: ["/bin/bash", "-c", "pkill -15 node"]
						env: list.Concat([
							[
								{name: "BINARY", value: app.services.producer.binary},
								{name: "SCHEDULER_FLOW", value: "producer"},
							],
							#config.global.env,
							app.services.producer.env,
							_metaEnvs,
							_genericEnvs,
							_pgEnvs,
						])
						envFrom: [
							{configMapRef: {name: "\(#config.metadata.name)-configs"}},
							{configMapRef: {name: "producer-cm-\(#config.metadata.name)"}},
							if !#config.disableInternalSecrets {
								{secretRef: {name: "\(#config.metadata.name)-secrets"}}
							},
						]
						resources: app.services.producer.resources
						securityContext: privileged: false
						terminationMessagePath:   "/dev/termination-log"
						terminationMessagePolicy: "File"
						volumeMounts: [
							{
								mountPath: "/local/config/\(app.server.run_env).toml"
								name:      "hyperswitch-config"
								subPath:   "router.toml"
							},
						]
					},
				]
				dnsPolicy:     "ClusterFirst"
				restartPolicy: "Always"
				schedulerName: "default-scheduler"
				securityContext: {}
				serviceAccountName:            "\(#config.metadata.name)-router-role"
				terminationGracePeriodSeconds: app.services.producer.terminationGracePeriodSeconds
				volumes: [
					{
						name: "hyperswitch-config"
						configMap: {
							name:        "router-cm-\(#config.metadata.name)"
							defaultMode: 420
						}
					},
				]
			}
		}
	}
}
