package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MainDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.workload.main.replicas
		revisionHistoryLimit: #config.workload.main.revisionHistoryLimit
		strategy: type:       "Recreate"
		selector: matchLabels: {
			"pod.name":                  "main"
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"pod.name":           "main"
					"pod.lifecycle":      "permanent"
					"truecharts.org/pvc": "code"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				if #config.runtimeClassName != _|_ && #config.runtimeClassName != "" {
					runtimeClassName: #config.runtimeClassName
				}
				enableServiceLinks:            #config.enableServiceLinks
				hostNetwork:                   #config.hostNetwork
				hostPID:                       #config.hostPID
				hostIPC:                       #config.hostIPC
				shareProcessNamespace:         #config.shareProcessNamespace
				restartPolicy:                 #config.restartPolicy
				nodeSelector:                  #config.nodeSelector
				affinity:                      #config.affinity
				topologySpreadConstraints:     #config.topologySpreadConstraints
				dnsPolicy:                     #config.dnsPolicy
				dnsConfig:                     #config.dnsConfig
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				securityContext: {
					fsGroup:             #config.podSecurityContext.fsGroup
					fsGroupChangePolicy: #config.podSecurityContext.fsGroupChangePolicy
					supplementalGroups:  #config.podSecurityContext.supplementalGroups
					sysctls: []
				}
				hostUsers: #config.hostUsers
				containers: [
					{
						name:            "cloud9"
						image:           #config.image.repository + ":" + #config.image.tag
						imagePullPolicy: #config.image.pullPolicy
						tty:             false
						stdin:           false
						ports: [
							{
								name:          "main"
								containerPort: #config.service.main.ports.main.targetPort
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							if #config.persistence.code.enabled {
								{
									name:      "code"
									mountPath: #config.persistence.code.mountPath
									readOnly:  false
								}
							},
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
							httpGet: {
								path:   #config.workload.main.podSpec.containers.main.probes.liveness.path
								port:   #config.service.main.ports.main.targetPort
								scheme: "HTTP"
							}
							initialDelaySeconds: #config.workload.main.podSpec.containers.main.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.workload.main.podSpec.containers.main.probes.liveness.periodSeconds
							failureThreshold:    #config.workload.main.podSpec.containers.main.probes.liveness.failureThreshold
							successThreshold:    #config.workload.main.podSpec.containers.main.probes.liveness.successThreshold
							timeoutSeconds:      #config.workload.main.podSpec.containers.main.probes.liveness.timeoutSeconds
						}
						readinessProbe: {
							httpGet: {
								path:   #config.workload.main.podSpec.containers.main.probes.readiness.path
								port:   #config.service.main.ports.main.targetPort
								scheme: "HTTP"
							}
							initialDelaySeconds: #config.workload.main.podSpec.containers.main.probes.readiness.initialDelaySeconds
							periodSeconds:       #config.workload.main.podSpec.containers.main.probes.readiness.periodSeconds
							failureThreshold:    #config.workload.main.podSpec.containers.main.probes.readiness.failureThreshold
							successThreshold:    #config.workload.main.podSpec.containers.main.probes.readiness.successThreshold
							timeoutSeconds:      #config.workload.main.podSpec.containers.main.probes.readiness.timeoutSeconds
						}
						startupProbe: {
							httpGet: {
								path:   #config.workload.main.podSpec.containers.main.probes.startup.path
								port:   #config.service.main.ports.main.targetPort
								scheme: "HTTP"
							}
							initialDelaySeconds: #config.workload.main.podSpec.containers.main.probes.startup.initialDelaySeconds
							periodSeconds:       #config.workload.main.podSpec.containers.main.probes.startup.periodSeconds
							failureThreshold:    #config.workload.main.podSpec.containers.main.probes.startup.failureThreshold
							successThreshold:    #config.workload.main.podSpec.containers.main.probes.startup.successThreshold
							timeoutSeconds:      #config.workload.main.podSpec.containers.main.probes.startup.timeoutSeconds
						}
						resources: {
							requests: {
								cpu:    #config.resources.requests.cpu
								memory: #config.resources.requests.memory
							}
							limits: {
								cpu:    #config.resources.limits.cpu
								memory: #config.resources.limits.memory
							}
						}
						securityContext: {
							runAsNonRoot:             #config.securityContext.container.runAsNonRoot
							runAsUser:                #config.securityContext.container.runAsUser
							runAsGroup:               #config.securityContext.container.runAsGroup
							readOnlyRootFilesystem:   #config.securityContext.container.readOnlyRootFilesystem
							allowPrivilegeEscalation: #config.securityContext.container.allowPrivilegeEscalation
							privileged:               #config.securityContext.container.privileged
							seccompProfile:           #config.securityContext.container.seccompProfile
							capabilities:             #config.securityContext.container.capabilities
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
							for k, v in #config.workload.main.podSpec.containers.main.env {
								name:  k
								value: "\(v)"
							},
						]
					},
				]
				volumes: [
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
					if #config.persistence.code.enabled {
						{
							name: "code"
							persistentVolumeClaim: claimName: #config.persistence.code.name
						}
					},
				]
			}
		}
	}
}
