package templates

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.replicas
		revisionHistoryLimit: 3
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"pod.lifecycle":                "permanent"
					"truecharts.org/pvc":           "data"
					"app.kubernetes.io/version":    #config.moduleVersion
					"app.kubernetes.io/managed-by": "timoni"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccount.name
				automountServiceAccountToken: false
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
				affinity:                     #config.affinity
				topologySpreadConstraints:    #config.topologySpreadConstraints
				dnsPolicy:                    "ClusterFirst"
				dnsConfig: options: [
					{name: "ndots", value: "1"},
				]
				terminationGracePeriodSeconds: 60
				securityContext:               #config.podSecurityContext
				hostUsers:                     true
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          #config.service.portName
								containerPort: #config.service.targetPort
								protocol:      corev1.#ProtocolTCP
							},
						]
						volumeMounts: [
							if #config.persistence.data.enabled {
								name:      "data"
								mountPath: #config.persistence.data.mountPath
								readOnly:  false
							},
							{name: "devshm", mountPath: "/dev/shm", readOnly: false},
							{name: "shared", mountPath: "/shared", readOnly: false},
							{name: "tmp", mountPath: "/tmp", readOnly: false},
							{name: "varlogs", mountPath: "/var/logs", readOnly: false},
							{name: "varrun", mountPath: "/var/run", readOnly: false},
						]
						livenessProbe: {
							httpGet: {
								port:   #config.service.targetPort
								path:   "/"
								scheme: "HTTP"
							}
							initialDelaySeconds: 12
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       15
						}
						readinessProbe: {
							httpGet: {
								port:   #config.service.targetPort
								path:   "/"
								scheme: "HTTP"
							}
							initialDelaySeconds: 10
							failureThreshold:    4
							successThreshold:    2
							timeoutSeconds:      5
							periodSeconds:       12
						}
						startupProbe: {
							httpGet: {
								port:   #config.service.targetPort
								path:   "/"
								scheme: "HTTP"
							}
							initialDelaySeconds: 10
							failureThreshold:    60
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						if #config.workload.main.podSpec.containers.main.resources != _|_ {
							resources: #config.workload.main.podSpec.containers.main.resources
						}
						if #config.workload.main.podSpec.containers.main.resources == _|_ {
							resources: #config.resources
						}
						securityContext: corev1.#SecurityContext & {
							runAsNonRoot:             #config.securityContext.container.runAsNonRoot
							runAsUser:                #config.securityContext.container.runAsUser
							runAsGroup:               #config.securityContext.container.runAsGroup
							readOnlyRootFilesystem:   #config.securityContext.container.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.securityContext.allowPrivilegeEscalation
							privileged:               #config.securityContext.privileged
							seccompProfile:           #config.securityContext.seccompProfile
							capabilities:             #config.securityContext.capabilities
						}
						let _env = #config.workload.main.podSpec.containers.main.env
						let _pwd = _env.DATABASE_PASSWORD.secretKeyRef.name
						let _url = _env.DATABASE_URL.secretKeyRef.name
						// https://www.traccar.org/configuration-file/
						env: [
							{name: "TZ", value: #config.env.TZ},
							{name: "UMASK", value: "0022"},
							{name: "UMASK_SET", value: "0022"},
							{name: "NVIDIA_VISIBLE_DEVICES", value: "void"},
							{name: "PUID", value: "\(#config.env.PUID)"},
							{name: "USER_ID", value: "\(#config.env.PUID)"},
							{name: "UID", value: "\(#config.env.PUID)"},
							{name: "PGID", value: "\(#config.env.PGID)"},
							{name: "GROUP_ID", value: "\(#config.env.PGID)"},
							{name: "GID", value: "\(#config.env.PGID)"},
							{name: "CONFIG_USE_ENVIRONMENT_VARIABLES", value: "\(_env.CONFIG_USE_ENVIRONMENT_VARIABLES)"},
							{name: "DATABASE_DRIVER", value: _env.DATABASE_DRIVER},
							{
								name: "DATABASE_PASSWORD"
								valueFrom: secretKeyRef: {
									key: _env.DATABASE_PASSWORD.secretKeyRef.key
									name: string
									if strings.HasPrefix(_pwd, #config.metadata.name) {
										name: _pwd
									}
									if !strings.HasPrefix(_pwd, #config.metadata.name) {
										name: "\(#config.metadata.name)-\(_pwd)"
									}
								}
							},
							{
								name: "DATABASE_URL"
								valueFrom: secretKeyRef: {
									key: _env.DATABASE_URL.secretKeyRef.key
									name: string
									if strings.HasPrefix(_url, #config.metadata.name) {
										name: _url
									}
									if !strings.HasPrefix(_url, #config.metadata.name) {
										name: "\(#config.metadata.name)-\(_url)"
									}
								}
							},
							{name: "DATABASE_USER", value: _env.DATABASE_USER},
							{name: "LOGGER_CONSOLE", value: "\(_env.LOGGER_CONSOLE)"},
						]
					},
				]
				if #config.cnpg.enabled {
					let _waitContainer = #config.initContainers["system-cnpg-wait"]
					initContainers: [
						{
							name:            "\(#config.metadata.name)-system-cnpg-wait"
							image:           _waitContainer.image.reference
							imagePullPolicy: _waitContainer.image.pullPolicy
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
								  pg_isready -U \(#config.cnpg.user) -d \(#config.cnpg.database) -h \(#config.metadata.name)-cnpg-main-rw
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
							resources: _waitContainer.resources
							securityContext: {
								runAsNonRoot:             true
								runAsUser:                568
								runAsGroup:               568
								readOnlyRootFilesystem:   true
								allowPrivilegeEscalation: false
								privileged:               false
								seccompProfile: type: "RuntimeDefault"
								capabilities: {
									add: []
									drop: ["ALL"]
								}
							}
							env: [
								{name: "TZ", value: #config.env.TZ},
								{name: "UMASK", value: "0022"},
								{name: "UMASK_SET", value: "0022"},
								{name: "NVIDIA_VISIBLE_DEVICES", value: "void"},
								{name: "S6_READ_ONLY_ROOT", value: "1"},
							]
						},
					]
				}
				volumes: [
					{
						name: "devshm"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "shared"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "varlogs"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					{
						name: "varrun"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "2400Mi"
						}
					},
					if #config.persistence.data.enabled {
						name: "data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
					},
				]
			}
		}
	}
}
