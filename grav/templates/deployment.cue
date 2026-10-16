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
		revisionHistoryLimit: 3
		strategy: {
			type: "Recreate"
		}
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.metadata.labels & #config.selector.labels & {
					"pod.lifecycle": "permanent"
					if #config.persistence.config.enabled {
						"truecharts.org/pvc": "config"
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: false
				hostNetwork:                  false
				hostPID:                      false
				hostIPC:                      false
				shareProcessNamespace:        false
				enableServiceLinks:           false
				restartPolicy:                "Always"
				nodeSelector:                 #config.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
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
								protocol:      #config.service.main.ports.main.protocol
							},
						]
						volumeMounts: [
							if #config.persistence.config.enabled {
								{
									name:      "config"
									mountPath: #config.persistence.config.mountPath
									readOnly:  #config.persistence.config.readOnly
								}
							},
							if #config.persistence.devshm.enabled {
								{
									name:      "devshm"
									mountPath: #config.persistence.devshm.mountPath
									readOnly:  #config.persistence.devshm.readOnly
								}
							},
							if #config.persistence.shared.enabled {
								{
									name:      "shared"
									mountPath: #config.persistence.shared.mountPath
									readOnly:  #config.persistence.shared.readOnly
								}
							},
							if #config.persistence.tmp.enabled {
								{
									name:      "tmp"
									mountPath: #config.persistence.tmp.mountPath
									readOnly:  #config.persistence.tmp.readOnly
								}
							},
							if #config.persistence.varlogs.enabled {
								{
									name:      "varlogs"
									mountPath: #config.persistence.varlogs.mountPath
									readOnly:  #config.persistence.varlogs.readOnly
								}
							},
							if #config.persistence.varrun.enabled {
								{
									name:      "varrun"
									mountPath: #config.persistence.varrun.mountPath
									readOnly:  #config.persistence.varrun.readOnly
								}
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
						env:             #config.env
					},
				]
				volumes: [
					if #config.persistence.devshm.enabled {
						{
							name: "devshm"
							emptyDir: {
								medium:    #config.persistence.devshm.medium
								sizeLimit: #config.persistence.devshm.sizeLimit
							}
						}
					},
					if #config.persistence.shared.enabled {
						{
							name:     "shared"
							emptyDir: {}
						}
					},
					if #config.persistence.tmp.enabled {
						{
							name: "tmp"
							emptyDir: {
								medium:    #config.persistence.tmp.medium
								sizeLimit: #config.persistence.tmp.sizeLimit
							}
						}
					},
					if #config.persistence.varlogs.enabled {
						{
							name: "varlogs"
							emptyDir: {
								medium:    #config.persistence.varlogs.medium
								sizeLimit: #config.persistence.varlogs.sizeLimit
							}
						}
					},
					if #config.persistence.varrun.enabled {
						{
							name: "varrun"
							emptyDir: {
								medium:    #config.persistence.varrun.medium
								sizeLimit: #config.persistence.varrun.sizeLimit
							}
						}
					},
					if #config.persistence.config.enabled {
						{
							name: "config"
							persistentVolumeClaim: {
								claimName: "\(#config.metadata.name)-config"
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