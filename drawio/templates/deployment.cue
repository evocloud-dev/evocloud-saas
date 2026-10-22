package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	_podSpec:   #config.workload.main.podSpec
	_container: _podSpec.containers.main
	_port:      #config.service.main.ports.main

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.workload.main.replicas
		revisionHistoryLimit: #config.workload.main.revisionHistoryLimit
		strategy:             #config.workload.main.strategy
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.metadata.labels & #config.selector.labels & {
					"pod.lifecycle": "permanent"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            _podSpec.serviceAccountName
				automountServiceAccountToken:  _podSpec.automountServiceAccountToken
				hostNetwork:                   _podSpec.hostNetwork
				hostPID:                       _podSpec.hostPID
				hostIPC:                       _podSpec.hostIPC
				shareProcessNamespace:         _podSpec.shareProcessNamespace
				enableServiceLinks:            _podSpec.enableServiceLinks
				restartPolicy:                 _podSpec.restartPolicy
				nodeSelector:                  #config.nodeSelector
				topologySpreadConstraints:     #config.topologySpreadConstraints
				dnsPolicy:                     _podSpec.dnsPolicy
				dnsConfig:                     _podSpec.dnsConfig
				terminationGracePeriodSeconds: _podSpec.terminationGracePeriodSeconds
				securityContext:               #config.securityContext.pod
				hostUsers:                     _podSpec.hostUsers
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
								containerPort: _port.targetPort
								protocol:      _port.protocol
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
								port:   _port.targetPort
								path:   _container.probes.liveness.path
								scheme: _container.probes.liveness.scheme
							}
							initialDelaySeconds: _container.probes.liveness.initialDelaySeconds
							failureThreshold:    _container.probes.liveness.failureThreshold
							successThreshold:    _container.probes.liveness.successThreshold
							timeoutSeconds:      _container.probes.liveness.timeoutSeconds
							periodSeconds:       _container.probes.liveness.periodSeconds
						}
						readinessProbe: {
							httpGet: {
								port:   _port.targetPort
								path:   _container.probes.readiness.path
								scheme: _container.probes.readiness.scheme
							}
							initialDelaySeconds: _container.probes.readiness.initialDelaySeconds
							failureThreshold:    _container.probes.readiness.failureThreshold
							successThreshold:    _container.probes.readiness.successThreshold
							timeoutSeconds:      _container.probes.readiness.timeoutSeconds
							periodSeconds:       _container.probes.readiness.periodSeconds
						}
						startupProbe: {
							httpGet: {
								port:   _port.targetPort
								path:   _container.probes.startup.path
								scheme: _container.probes.startup.scheme
							}
							initialDelaySeconds: _container.probes.startup.initialDelaySeconds
							failureThreshold:    _container.probes.startup.failureThreshold
							successThreshold:    _container.probes.startup.successThreshold
							timeoutSeconds:      _container.probes.startup.timeoutSeconds
							periodSeconds:       _container.probes.startup.periodSeconds
						}
						resources:       #config.resources
						securityContext: #config.securityContext.container
						env: [
							{
								name:  "TZ"
								value: "UTC"
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
							for k, v in _container.env {
								name:  k
								value: v
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
				]
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
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
