package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#ConsumerConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "consumer-cm-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"ROUTER__SCHEDULER__CONSUMER_GROUP":             app.services.consumer.configs.scheduler.consumer_group
		"ROUTER__SCHEDULER__GRACEFUL_SHUTDOWN_INTERVAL": "\(app.services.consumer.configs.scheduler.graceful_shutdown_interval)"
		"ROUTER__SCHEDULER__LOOP_INTERVAL":              "\(app.services.consumer.configs.scheduler.loop_interval)"
		"ROUTER__SCHEDULER__STREAM":                     app.services.consumer.configs.scheduler.stream
		"ROUTER__SCHEDULER__CONSUMER__CONSUMER_GROUP":   app.services.consumer.configs.scheduler.consumer.consumer_group
		"ROUTER__SCHEDULER__CONSUMER__DISABLED":         "\(app.services.consumer.configs.scheduler.consumer.disabled)"
		"ROUTER__SCHEDULER__SERVER__PORT":               "\(app.services.consumer.configs.scheduler.server.port)"
		"ROUTER__SCHEDULER__SERVER__HOST":               app.services.consumer.configs.scheduler.server.host
		"ROUTER__SCHEDULER__SERVER__WORKERS":            "\(app.services.consumer.configs.scheduler.server.workers)"
	}
}

#ConsumerDeployment: appsv1.#Deployment & {
	#config: #Config
	let app = #config."hyperswitch-app"

	_baseName: "\(#config.metadata.name)-consumer"
	_registry: string
	if #config.global.imageRegistry == "" {
		_registry: (app.services.consumer.imageRegistry | *"docker.juspay.io")
	}
	if #config.global.imageRegistry != "" {
		_registry: #config.global.imageRegistry
	}

	let _appLabels = {
		"app.kubernetes.io/name":       _baseName
		"app.kubernetes.io/version":    app.services.consumer.version
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/managed-by": "timoni"
		"app":                          _baseName
		"version":                      app.services.consumer.version
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:        _baseName
		namespace:   #config.metadata.namespace
		annotations: #config.global.annotations & app.services.consumer.annotations
		labels:      _appLabels & #config.global.labels & app.services.consumer.labels
	}
	spec: {
		progressDeadlineSeconds: app.services.consumer.progressDeadlineSeconds
		replicas:                app.services.consumer.replicas
		revisionHistoryLimit:    10
		selector: matchLabels: {
			"app":                        _baseName
			"app.kubernetes.io/instance": #config.metadata.name
		}
		strategy: app.services.consumer.strategy

		template: {
			metadata: {
				annotations: #config.global.podAnnotations & app.services.consumer.podAnnotations & {
					"checksum/consumer-config": "dynamic-checksum-by-timoni"
					"checksum/configs":         "dynamic-checksum-by-timoni"
					"checksum/secrets":         "dynamic-checksum-by-timoni"
				}
				labels: _appLabels & #config.global.labels & app.services.consumer.labels
			}
			spec: {
				tolerations:  app.services.consumer.tolerations
				affinity:     app.services.consumer.affinity
				nodeSelector: app.services.consumer.nodeSelector

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
						name:            "hyperswitch-consumer"
						image:           "\(_registry)/\(app.services.consumer.image):\(app.services.consumer.version)"
						imagePullPolicy: "IfNotPresent"
						lifecycle: preStop: exec: command: ["/bin/bash", "-c", "pkill -15 node"]
						env: list.Concat([
							[
								{name: "BINARY", value: app.services.consumer.binary},
								{name: "SCHEDULER_FLOW", value: "consumer"},
							],
							#config.global.env,
							app.services.consumer.env,
							_metaEnvs,
							_genericEnvs,
							_pgEnvs,
						])
						envFrom: [
							{configMapRef: {name: "\(#config.metadata.name)-configs"}},
							{configMapRef: {name: "consumer-cm-\(#config.metadata.name)"}},
							if !#config.disableInternalSecrets {
								{secretRef: {name: "\(#config.metadata.name)-secrets"}}
							},
						]
						resources: app.services.consumer.resources
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
				terminationGracePeriodSeconds: app.services.consumer.terminationGracePeriodSeconds
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
