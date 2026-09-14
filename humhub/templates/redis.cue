package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisHealthConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.redis.healthConfigMapName
		namespace: #config.metadata.namespace
		labels:    #config.redis.labels
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

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.redis.serviceName
		namespace: #config.metadata.namespace
		labels:    #config.redis.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:             #config.redis.replicas
		revisionHistoryLimit: #config.redis.revisionHistoryLimit
		serviceName:          #config.redis.serviceName
		updateStrategy: type: #config.redis.updateStrategyType
		selector: matchLabels: {
			"pod.name":                  "main"
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: #config.redis.labels & {
					"pod.lifecycle": "permanent"
					"pod.name":      "main"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				if #config.runtimeClassName != _|_ && #config.runtimeClassName != "" {
					runtimeClassName: #config.runtimeClassName
				}
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
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
				dnsPolicy: "ClusterFirst"
				dnsConfig: options: [
					{
						name:  "ndots"
						value: "1"
					},
				]
				terminationGracePeriodSeconds: #config.redis.terminationGracePeriodSeconds
				securityContext: {
					fsGroup:             #config.redis.securityContext.fsGroup
					fsGroupChangePolicy: #config.redis.securityContext.fsGroupChangePolicy
					supplementalGroups: [#config.redis.securityContext.fsGroup]
					sysctls: []
				}
				hostUsers: true
				containers: [
					{
						name:            #config.redis.serviceName
						image:           #config.redis.image.repository + ":" + #config.redis.image.tag
						imagePullPolicy: #config.redis.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.redis.port
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name:      "devshm"
								mountPath: "/dev/shm"
								readOnly:  false
							},
							{
								name:      "shared"
								mountPath: "/shared"
								readOnly:  false
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
								readOnly:  false
							},
							{
								name:      "valkey-health"
								mountPath: "/health"
								readOnly:  false
							},
							{
								name:      "varlogs"
								mountPath: "/var/logs"
								readOnly:  false
							},
							{
								name:      "varrun"
								mountPath: "/var/run"
								readOnly:  false
							},
						]
						livenessProbe: {
							exec: command:       #config.redis.probes.liveness.command
							initialDelaySeconds: #config.redis.probes.liveness.initialDelaySeconds
							failureThreshold:    #config.redis.probes.liveness.failureThreshold
							successThreshold:    #config.redis.probes.liveness.successThreshold
							timeoutSeconds:      #config.redis.probes.liveness.timeoutSeconds
							periodSeconds:       #config.redis.probes.liveness.periodSeconds
						}
						readinessProbe: {
							exec: command:       #config.redis.probes.readiness.command
							initialDelaySeconds: #config.redis.probes.readiness.initialDelaySeconds
							failureThreshold:    #config.redis.probes.readiness.failureThreshold
							successThreshold:    #config.redis.probes.readiness.successThreshold
							timeoutSeconds:      #config.redis.probes.readiness.timeoutSeconds
							periodSeconds:       #config.redis.probes.readiness.periodSeconds
						}
						startupProbe: {
							exec: command:       #config.redis.probes.startup.command
							initialDelaySeconds: #config.redis.probes.startup.initialDelaySeconds
							failureThreshold:    #config.redis.probes.startup.failureThreshold
							successThreshold:    #config.redis.probes.startup.successThreshold
							timeoutSeconds:      #config.redis.probes.startup.timeoutSeconds
							periodSeconds:       #config.redis.probes.startup.periodSeconds
						}
						resources: {
							requests: {
								cpu:    #config.redis.resources.requests.cpu
								memory: #config.redis.resources.requests.memory
							}
							limits: {
								cpu:    #config.redis.resources.limits.cpu
								memory: #config.redis.resources.limits.memory
							}
						}
						securityContext: {
							runAsNonRoot:             #config.redis.securityContext.container.runAsNonRoot
							runAsUser:                #config.redis.securityContext.container.runAsUser
							runAsGroup:               #config.redis.securityContext.container.runAsGroup
							readOnlyRootFilesystem:   #config.redis.securityContext.container.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.redis.securityContext.container.allowPrivilegeEscalation
							privileged:               #config.redis.securityContext.container.privileged
							seccompProfile: type: "RuntimeDefault"
							capabilities: {
								add:  #config.redis.securityContext.capabilities.add
								drop: #config.redis.securityContext.capabilities.drop
							}
						}
						env: [
							{name: "TZ", value: #config.envDefaults.tz},
							{name: "UMASK", value: #config.envDefaults.umask},
							{name: "UMASK_SET", value: #config.envDefaults.umask},
							{name: "NVIDIA_VISIBLE_DEVICES", value: #config.envDefaults.nvidiaVisibleDevices},
							{name: "PUID", value: #config.envDefaults.puid},
							{name: "USER_ID", value: #config.envDefaults.puid},
							{name: "UID", value: #config.envDefaults.puid},
							{name: "PGID", value: #config.envDefaults.pgid},
							{name: "GROUP_ID", value: #config.envDefaults.pgid},
							{name: "GID", value: #config.envDefaults.pgid},
							{name: "ALLOW_EMPTY_PASSWORD", value: #config.redis.allowEmptyPassword},
							{name: "VALKEY_PASSWORD", value: #config.redis.password},
							{name: "VALKEY_PORT", value: "\(#config.redis.port)"},
						]
					},
				]
				volumes: [
					{
						name: "valkey-health"
						configMap: {
							name:        #config.redis.healthConfigMapName
							defaultMode: 0o755
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
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					{
						name:     "shared"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					{
						name: "varlogs"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
					{
						name: "varrun"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: #config.emptyDirMemoryLimit
						}
					},
				]
			}
		}
	}
}

#RedisService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.redis.serviceName
		namespace: #config.metadata.namespace
		labels:    #config.redis.labels & {
			"service.name": "main"
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: false
		ports: [
			{
				port:       #config.redis.port
				protocol:   "TCP"
				name:       "main"
				targetPort: #config.redis.port
			},
		]
		selector: {
			"pod.name":                  "main"
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

