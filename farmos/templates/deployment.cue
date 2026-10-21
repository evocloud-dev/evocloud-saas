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
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.replicas
		revisionHistoryLimit: 3
		strategy: {
			type: "Recreate"
		}
		selector: {
			matchLabels: #config.selector.labels
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & #config.selector.labels & {
					"pod.lifecycle": "permanent"
					if #config.persistence.sitesdirectory.enabled {
						"truecharts.org/pvc": "sitesdirectory"
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
				affinity:                     #config.affinity
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.topologySpreadConstraints == _|_ {
					topologySpreadConstraints: [
						{
							maxSkew:           1
							whenUnsatisfiable: "ScheduleAnyway"
							topologyKey:       "kubernetes.io/hostname"
							labelSelector: {
								matchLabels: #config.selector.labels
							}
							nodeAffinityPolicy: "Honor"
							nodeTaintsPolicy:   "Honor"
						},
					]
				}
				dnsPolicy: "ClusterFirst"
				dnsConfig: {
					options: [
						{
							name:  "ndots"
							value: "1"
						},
					]
				}
				terminationGracePeriodSeconds: 60
				securityContext:               #config.securityContext.pod
				hostUsers:                     true
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.service.main.ports.main.targetPort
								protocol:      strings.ToUpper(#config.service.main.ports.main.protocol)
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
							if #config.persistence.sitesdirectory.enabled {
								{
									name:      "sitesdirectory"
									mountPath: #config.persistence.sitesdirectory.mountPath
									readOnly:  false
								}
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
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
							tcpSocket: {
								port: #config.service.main.ports.main.targetPort
							}
							initialDelaySeconds: 12
							failureThreshold:    5
							successThreshold:    1
							timeoutSeconds:      5
							periodSeconds:       15
						}
						readinessProbe: {
							tcpSocket: {
								port: #config.service.main.ports.main.targetPort
							}
							initialDelaySeconds: 10
							failureThreshold:    4
							successThreshold:    2
							timeoutSeconds:      5
							periodSeconds:       12
						}
						startupProbe: {
							tcpSocket: {
								port: #config.service.main.ports.main.targetPort
							}
							initialDelaySeconds: 10
							failureThreshold:    60
							successThreshold:    1
							timeoutSeconds:      3
							periodSeconds:       5
						}
						resources:       #config.resources
						securityContext: #config.securityContext.container
						env: [
							{
								name:  "TZ"
								value: #config.tz
							},
							{
								name:  "UMASK"
								value: "0022"
							},
							{
								name:  "UMASK_SET"
								value: "0022"
							},
							{
								name:  "NVIDIA_VISIBLE_DEVICES"
								value: "void"
							},
							{
								name:  "PUID"
								value: "568"
							},
							{
								name:  "USER_ID"
								value: "568"
							},
							{
								name:  "UID"
								value: "568"
							},
							{
								name:  "PGID"
								value: "568"
							},
							{
								name:  "GROUP_ID"
								value: "568"
							},
							{
								name:  "GID"
								value: "568"
							},
							if #config.postgresql.enabled {
								{
									name:  "POSTGRES_HOST"
									value: "\(#config._fullname)-postgresql"
								}
							},
							if #config.postgresql.enabled {
								{
									name:  "POSTGRES_PORT"
									value: "\(#config.postgresql.service.port)"
								}
							},
							if #config.postgresql.enabled {
								{
									name: "POSTGRES_DB"
									valueFrom: {
										secretKeyRef: {
											name: "\(#config._fullname)-postgresql"
											key:  "POSTGRES_DB"
										}
									}
								}
							},
							if #config.postgresql.enabled {
								{
									name: "POSTGRES_USER"
									valueFrom: {
										secretKeyRef: {
											name: "\(#config._fullname)-postgresql"
											key:  "POSTGRES_USER"
										}
									}
								}
							},
							if #config.postgresql.enabled {
								{
									name: "POSTGRES_PASSWORD"
									valueFrom: {
										secretKeyRef: {
											name: "\(#config._fullname)-postgresql"
											key:  "POSTGRES_PASSWORD"
										}
									}
								}
							},
						]
					},
				]
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
					if #config.persistence.sitesdirectory.enabled {
						{
							name: "sitesdirectory"
							persistentVolumeClaim: {
								claimName: "\(#config.metadata.name)-sitesdirectory"
							}
						}
					},
				]
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}
