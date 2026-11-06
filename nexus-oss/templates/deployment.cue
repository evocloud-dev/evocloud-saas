package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the instance selector labels.
	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas:             #config.replicas
		revisionHistoryLimit: #config.revisionHistoryLimit
		strategy:             #config.strategy
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podLabels != _|_ {
					labels: #config.podLabels
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: "default"
				if #config.serviceAccount.create {
					serviceAccountName: #config.metadata.name
				}
				if !#config.serviceAccount.create && #config.serviceAccount.name != "" {
					serviceAccountName: #config.serviceAccount.name
				}

				automountServiceAccountToken:  #config.automountServiceAccountToken
				hostNetwork:                   #config.hostNetwork
				hostPID:                       #config.hostPID
				hostIPC:                       #config.hostIPC
				shareProcessNamespace:         #config.shareProcessNamespace
				enableServiceLinks:            #config.enableServiceLinks
				restartPolicy:                 #config.restartPolicy
				hostUsers:                     #config.hostUsers
				nodeSelector:                  #config.nodeSelector
				dnsPolicy:                     #config.dnsPolicy
				dnsConfig:                     #config.dnsConfig
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				securityContext:               #config.securityContext.pod

				if _affinity.#Enabled {
					affinity: _affinity
				}

				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}

				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}

				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
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
								name:          "main"
								containerPort: #config.service.main.ports.main.targetPort
								protocol:      #config.service.main.ports.main.protocol
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: #config.persistence.data.mountPath
								readOnly:  false
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
								port:   #config.service.main.ports.main.targetPort
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
								port:   #config.service.main.ports.main.targetPort
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
								port:   #config.service.main.ports.main.targetPort
								path:   "/"
								scheme: "HTTP"
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
								name:  "S6_READ_ONLY_ROOT"
								value: "1"
							},
							{
								name:  "INSTALL4J_ADD_VM_PARAMS"
								value: #config.workload.main.podSpec.containers.main.env.INSTALL4J_ADD_VM_PARAMS
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
						name:     "shared"
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
					{
						name: "data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
					},
				]
			}
		}
	}
}
