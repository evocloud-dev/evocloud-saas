package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisCredsSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-rediscreds"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		plain:            "\(#config.metadata.name)-redis"
		plainhost:        "\(#config.metadata.name)-redis"
		plainhostpass:    "\(#config.redis.redisUsername):\(#config.redis.password)@\(#config.metadata.name)-redis"
		plainporthost:    "\(#config.metadata.name)-redis:\(#config.redis.port)"
		"redis-password": #config.redis.password
		url:              "redis://\(#config.redis.redisUsername):\(#config.redis.password)@\(#config.metadata.name)-redis:\(#config.redis.port)/0"
	}
}

#RedisHealthConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-redis-health"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/version":   #config.moduleVersion
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"ping_liveness_local.sh": """
			#!/bin/bash
			[[ -n "$VALKEY_PASSWORD" ]] && export VALKEYCLI_AUTH="$VALKEY_PASSWORD"
			response=$(
			  timeout -s 3 $1 \\
			  valkey-cli \\
			    -h localhost \\
			    -p $VALKEY_PORT \\
			    ping
			)
			if [ "$response" != "PONG" ] && [ "$response" != "LOADING Valkey is loading the dataset in memory" ]; then
			  echo "$response"
			  exit 1
			fi
			"""

		"ping_liveness_local_and_master.sh": """
			script_dir="$(dirname "$0")"
			exit_status=0
			"$script_dir/ping_liveness_local.sh" $1 || exit_status=$?
			"$script_dir/ping_liveness_master.sh" $1 || exit_status=$?
			exit $exit_status
			"""

		"ping_liveness_master.sh": """
			#!/bin/bash
			[[ -n "$VALKEY_MASTER_PASSWORD" ]] && export VALKEYCLI_AUTH="$VALKEY_MASTER_PASSWORD"
			response=$(
			  timeout -s 3 $1 \\
			  valkey-cli \\
			    -h $VALKEY_MASTER_HOST \\
			    -p $VALKEY_MASTER_PORT_NUMBER \\
			    ping
			)
			if [ "$response" != "PONG" ] && [ "$response" != "LOADING Valkey is loading the dataset in memory" ]; then
			  echo "$response"
			  exit 1
			fi
			"""

		"ping_readiness_local.sh": """
			#!/bin/bash
			[[ -n "$VALKEY_PASSWORD" ]] && export VALKEYCLI_AUTH="$VALKEY_PASSWORD"
			response=$(
			  timeout -s 3 $1 \\
			  valkey-cli \\
			    -h localhost \\
			    -p $VALKEY_PORT \\
			    ping
			)
			if [ "$response" != "PONG" ]; then
			  echo "failed to connect using password: $VALKEY_PASSWORD response: $response"
			  exit 1
			fi
			"""

		"ping_readiness_local_and_master.sh": """
			script_dir="$(dirname "$0")"
			exit_status=0
			"$script_dir/ping_readiness_local.sh" $1 || exit_status=$?
			"$script_dir/ping_readiness_master.sh" $1 || exit_status=$?
			exit $exit_status
			"""

		"ping_readiness_master.sh": """
			#!/bin/bash
			[[ -n "$VALKEY_MASTER_PASSWORD" ]] && export VALKEYCLI_AUTH="$VALKEY_MASTER_PASSWORD"
			response=$(
			  timeout -s 3 $1 \\
			  valkey-cli \\
			    -h $VALKEY_MASTER_HOST \\
			    -p $VALKEY_MASTER_PORT_NUMBER \\
			    ping
			)
			if [ "$response" != "PONG" ]; then
			  echo "$response"
			  exit 1
			fi
			"""
	}
}

#RedisService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels: {
			"service.name":                 "main"
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/version":   #config.moduleVersion
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: false
		ports: [
			{
				name:       "main"
				port:       #config.redis.port
				protocol:   corev1.#ProtocolTCP
				targetPort: #config.redis.port
			},
		]
		selector: {
			"pod.name":                   "main"
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/version":   #config.moduleVersion
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:             1
		revisionHistoryLimit: 3
		serviceName:          "\(#config.metadata.name)-redis"
		updateStrategy: type: appsv1.#RollingUpdateStatefulSetStrategyType
		selector: matchLabels: {
			"pod.name":                   "main"
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"pod.name":                   "main"
					"pod.lifecycle":              "permanent"
					"app.kubernetes.io/name":     "redis"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				if #config.runtimeClassName != _|_ {
					runtimeClassName: #config.runtimeClassName
				}
				hostNetwork:           false
				hostPID:               false
				hostIPC:               false
				shareProcessNamespace: false
				enableServiceLinks:    false
				restartPolicy:         corev1.#RestartPolicyAlways
				nodeSelector: {
					"kubernetes.io/arch": "amd64"
				}
				topologySpreadConstraints: [
					{
						maxSkew:           1
						whenUnsatisfiable: "ScheduleAnyway"
						topologyKey:       "kubernetes.io/hostname"
						labelSelector: matchLabels: {
							"pod.name":                   "main"
							"app.kubernetes.io/name":     "redis"
							"app.kubernetes.io/instance": #config.metadata.name
						}
						nodeAffinityPolicy: "Honor"
						nodeTaintsPolicy:   "Honor"
					},
				]
				dnsPolicy: corev1.#DNSClusterFirst
				dnsConfig: options: [
					{
						name:  "ndots"
						value: "1"
					},
				]
				terminationGracePeriodSeconds: 60
				securityContext:                #config.securityContext.pod
				hostUsers:                      true
				containers: [
					{
						name:            "\(#config.metadata.name)-redis"
						image:           #config.redis.image.reference
						imagePullPolicy: #config.redis.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.redis.port
								protocol:      corev1.#ProtocolTCP
							},
						]
						volumeMounts: [
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "valkey-health", mountPath: "/health", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-c",
								"/health/ping_liveness_local.sh 2",
							]
							initialDelaySeconds: 12
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       15
						}
						readinessProbe: {
							exec: command: [
								"sh",
								"-c",
								"/health/ping_readiness_local.sh 2",
							]
							initialDelaySeconds: 10
							failureThreshold:    4
							successThreshold:    2
							timeoutSeconds:      5
							periodSeconds:       12
						}
						startupProbe: {
							exec: command: [
								"sh",
								"-c",
								"/health/ping_readiness_local.sh 2",
							]
							initialDelaySeconds: 10
							failureThreshold:    60
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						resources:       #config.redis.resources
						securityContext: #config.redis.securityContext.container
						env: [
							{name: "TZ", value: "UTC"},
							{name: "UMASK", value: "0022"},
							{name: "UMASK_SET", value: "0022"},
							{name: "NVIDIA_VISIBLE_DEVICES", value: "void"},
							{name: "PUID", value: "568"},
							{name: "USER_ID", value: "568"},
							{name: "UID", value: "568"},
							{name: "PGID", value: "568"},
							{name: "GROUP_ID", value: "568"},
							{name: "GID", value: "568"},
							{name: "ALLOW_EMPTY_PASSWORD", value: "no"},
							{name: "VALKEY_PASSWORD", value: #config.redis.password},
							{name: "VALKEY_PORT", value: "\(#config.redis.port)"},
						]
					},
				]
				volumes: [
					{
						name: "valkey-health"
						configMap: {
							name:        "\(#config.metadata.name)-redis-health"
							defaultMode: 493
							optional:    false
							items: [
								{key: "ping_readiness_local.sh", path: "ping_readiness_local.sh"},
								{key: "ping_liveness_local.sh", path: "ping_liveness_local.sh"},
								{key: "ping_readiness_master.sh", path: "ping_readiness_master.sh"},
								{key: "ping_liveness_master.sh", path: "ping_liveness_master.sh"},
								{key: "ping_liveness_local_and_master.sh", path: "ping_liveness_local_and_master.sh"},
								{key: "ping_readiness_local_and_master.sh", path: "ping_readiness_local_and_master.sh"},
							]
						}
					},
					{
						name: "devshm"
						emptyDir: {
							medium:    corev1.#StorageMediumMemory
							sizeLimit: "2400Mi"
						}
					},
					{
						name:     "shared"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: {
							medium:    corev1.#StorageMediumMemory
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "varlogs"
						emptyDir: {
							medium:    corev1.#StorageMediumMemory
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "varrun"
						emptyDir: {
							medium:    corev1.#StorageMediumMemory
							sizeLimit: "2400Mi"
						}
					},
				]
			}
		}
	}
}
