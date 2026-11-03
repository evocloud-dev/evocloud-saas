package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#NocodbDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.replicas
		revisionHistoryLimit: 3
		strategy: {
			type: appsv1.#RecreateDeploymentStrategyType
		}
		selector: matchLabels: {
			"pod.name":                   "main"
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"pod.name":                   "main"
					"pod.lifecycle":              "permanent"
					"app.kubernetes.io/instance": #config.metadata.name
					if #config.persistence.data.enabled {
						"truecharts.org/pvc": "data"
					}
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				if #config.runtimeClassName != _|_ {
					runtimeClassName: #config.runtimeClassName
				}
				hostNetwork:            false
				hostPID:                false
				hostIPC:                false
				shareProcessNamespace:  false
				enableServiceLinks:     false
				restartPolicy:          corev1.#RestartPolicyAlways
				nodeSelector: {
					"kubernetes.io/arch": "amd64"
				}
				if #config.persistence.data.enabled {
					affinity: podAffinity: requiredDuringSchedulingIgnoredDuringExecution: [
						{
							topologyKey: "kubernetes.io/hostname"
							labelSelector: matchExpressions: [
								{
									key:      "truecharts.org/pvc"
									operator: "In"
									values: ["data"]
								},
							]
						},
					]
				}
				topologySpreadConstraints: [
					{
						maxSkew:           1
						whenUnsatisfiable: "ScheduleAnyway"
						topologyKey:       "kubernetes.io/hostname"
						labelSelector: matchLabels: {
							"pod.name":                   "main"
							"app.kubernetes.io/name":     #config.metadata.name
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
						name:            "nocodb"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.service.main.ports.main.port
								protocol:      corev1.#ProtocolTCP
							},
						]
						volumeMounts: [
							if #config.persistence.data.enabled {
								{
									name:      "data"
									mountPath: #config.persistence.data.mountPath
									readOnly:  false
								}
							},
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						livenessProbe: {
							httpGet: {
								port:   #config.service.main.ports.main.port
								path:   #config.workload.main.podSpec.containers.main.probes.liveness.path
								scheme: corev1.#URISchemeHTTP
							}
							initialDelaySeconds: 12
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       15
						}
						readinessProbe: {
							httpGet: {
								port:   #config.service.main.ports.main.port
								path:   #config.workload.main.podSpec.containers.main.probes.readiness.path
								scheme: corev1.#URISchemeHTTP
							}
							initialDelaySeconds: 10
							failureThreshold:    4
							successThreshold:    2
							timeoutSeconds:      5
							periodSeconds:       12
						}
						startupProbe: {
							httpGet: {
								port:   #config.service.main.ports.main.port
								path:   #config.workload.main.podSpec.containers.main.probes.startup.path
								scheme: corev1.#URISchemeHTTP
							}
							initialDelaySeconds: 10
							failureThreshold:    60
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						resources:       #config.workload.main.podSpec.containers.main.resources
						securityContext: #config.securityContext.container
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)-configmap"
							},
						]
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
							{name: "AWS_ACCESS_KEY_ID", value: #config.workload.main.podSpec.containers.main.env.AWS_ACCESS_KEY_ID},
							{name: "AWS_BUCKET", value: #config.workload.main.podSpec.containers.main.env.AWS_BUCKET},
							{name: "AWS_BUCKET_PATH", value: #config.workload.main.podSpec.containers.main.env.AWS_BUCKET_PATH},
							{name: "AWS_SECRET_ACCESS_KEY", value: #config.workload.main.podSpec.containers.main.env.AWS_SECRET_ACCESS_KEY},
							{name: "DISABLE_SPLASH_SCREEN", value: "\(#config.workload.main.podSpec.containers.main.env.DISABLE_SPLASH_SCREEN)"},
							{
								name: "NC_AUTH_JWT_SECRET"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-secrets"
									key:  "NC_AUTH_JWT_SECRET"
								}
							},
							{name: "NC_DISABLE_CACHE", value: "\(#config.workload.main.podSpec.containers.main.env.NC_DISABLE_CACHE)"},
							{name: "NC_DISABLE_ERR_REPORT", value: "\(#config.workload.main.podSpec.containers.main.env.NC_DISABLE_ERR_REPORT)"},
							{name: "NC_DISABLE_TELE", value: "\(#config.workload.main.podSpec.containers.main.env.NC_DISABLE_TELE)"},
							{name: "NC_EXPORT_MAX_TIMEOUT", value: "\(#config.workload.main.podSpec.containers.main.env.NC_EXPORT_MAX_TIMEOUT)"},
							{name: "NC_INVITE_ONLY_SIGNUP", value: "\(#config.workload.main.podSpec.containers.main.env.NC_INVITE_ONLY_SIGNUP)"},
							{name: "NC_JWT_EXPIRES_IN", value: #config.workload.main.podSpec.containers.main.env.NC_JWT_EXPIRES_IN},
							{name: "NC_PUBLIC_URL", value: #config.workload.main.podSpec.containers.main.env.NC_PUBLIC_URL},
							{
								name: "NC_REDIS_URL"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-rediscreds"
									key:  "url"
								}
							},
							{name: "NC_REQUEST_BODY_SIZE", value: #config.workload.main.podSpec.containers.main.env.NC_REQUEST_BODY_SIZE},
							{name: "NC_SENTRY_DSN", value: #config.workload.main.podSpec.containers.main.env.NC_SENTRY_DSN},
							{name: "PORT", value: "\(#config.service.main.ports.main.port)"},
						]
					},
				]
				initContainers: [
					{
						name:            "\(#config.metadata.name)-system-cnpg-wait"
						image:           #config.cnpg.main.clientImage
						imagePullPolicy: corev1.#PullIfNotPresent
						tty:             false
						stdin:           false
						command: [
							"/bin/sh",
							"-c",
							"""
								/bin/sh <<'EOF'
								echo "Executing DB waits..."
								echo "Testing Database availability on [CNPG RW]"
								until
								  echo "Testing database on url: [\(#config.metadata.name)-cnpg-main-rw]"
								  pg_isready -U \(#config.cnpg.main.user) -d \(#config.cnpg.main.database) -h \(#config.metadata.name)-cnpg-main-rw
								  do sleep 5
								done
								echo "Database available on url: [\(#config.metadata.name)-cnpg-main-rw]"
								echo "Done executing DB waits..."
								EOF
								""",
						]
						volumeMounts: [
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						resources:       #config.initResources
						securityContext: #config.initSecurityContext
						env: [
							{name: "TZ", value: "UTC"},
							{name: "UMASK", value: "0022"},
							{name: "UMASK_SET", value: "0022"},
							{name: "NVIDIA_VISIBLE_DEVICES", value: "void"},
							{name: "S6_READ_ONLY_ROOT", value: "1"},
						]
					},
					{
						name:            "\(#config.metadata.name)-system-redis-wait"
						image:           #config.redis.toolsImage
						imagePullPolicy: corev1.#PullIfNotPresent
						tty:             false
						stdin:           false
						command: [
							"/bin/sh",
							"-c",
							"""
								/bin/bash <<'EOF'
								echo "Executing DB waits..."
								[[ -n "$REDIS_PASSWORD" ]] && export REDISCLI_AUTH="$REDIS_PASSWORD";
								export LIVE=false;
								until "$LIVE";
								do
								  response=$(
								      timeout -s 3 2 \\
								      valkey-cli \\
								        -h "$REDIS_HOST" \\
								        -p "$REDIS_PORT" \\
								        ping
								    )
								  if [ "$response" == "PONG" ] || [ "$response" == "LOADING Redis is loading the dataset in memory" ]; then
								    LIVE=true
								    echo "$response"
								    echo "Redis Responded, ending initcontainer and starting main container(s)..."
								  else
								    echo "$response"
								    echo "Redis not responding... Sleeping for 10 sec..."
								    sleep 10
								  fi;
								done
								EOF
								""",
						]
						volumeMounts: [
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						resources:       #config.initResources
						securityContext: #config.initSecurityContext
						env: [
							{name: "TZ", value: "UTC"},
							{name: "UMASK", value: "0022"},
							{name: "UMASK_SET", value: "0022"},
							{name: "NVIDIA_VISIBLE_DEVICES", value: "void"},
							{name: "S6_READ_ONLY_ROOT", value: "1"},
							{
								name: "REDIS_HOST"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-rediscreds"
									key:  "plainhost"
								}
							},
							{name: "REDIS_PASSWORD", value: #config.redis.password},
							{name: "REDIS_PORT", value: "\(#config.redis.port)"},
						]
					},
				]
				volumes: [
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
					if #config.persistence.data.enabled {
						{
							name: "data"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
						}
					},
				]
			}
		}
	}
}
