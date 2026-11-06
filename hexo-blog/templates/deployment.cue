package templates

import (
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
		revisionHistoryLimit: #config.revisionHistoryLimit
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: {
					#config.selector.labels
					if #config.persistence.config.enabled {
						"truecharts.org/pvc": "config"
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.metadata.name
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
				dnsPolicy: "ClusterFirst"
				dnsConfig: options: [{
					name:  "ndots"
					value: "1"
				}]
				terminationGracePeriodSeconds: 60
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				hostUsers: true
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
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name:      "config"
								mountPath: #config.persistence.config.mountPath
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
						livenessProbe:   #config.probes.liveness
						readinessProbe:  #config.probes.readiness
						startupProbe:    #config.probes.startup
						resources:       #config.resources
						securityContext: #config.securityContext.container
						env: [
							for k, v in #config.workload.main.podSpec.containers.main.env {
								name:  k
								value: v
							},
						]
					},
				]
				volumes: [
					if #config.persistence.config.enabled {
						name: "config"
						persistentVolumeClaim: {
							claimName: *"\(#config.metadata.name)-config" | string
							if #config.persistence.config.existingClaim != _|_ {
								claimName: #config.persistence.config.existingClaim
							}
						}
					},
					if !#config.persistence.config.enabled {
						name: "config"
						emptyDir: {}
					},
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
