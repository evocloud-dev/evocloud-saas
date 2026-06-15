package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		revisionHistoryLimit: 3
		replicas:             1
		strategy: type:        "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: true
				dnsPolicy:                    "ClusterFirst"
				enableServiceLinks:           true
				securityContext: {
					fsGroup: #config.securityContext.runAsGroup
	            }
				containers: [
					{
						name:            #config.metadata.name
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
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
							runAsUser:  #config.securityContext.runAsUser
					        runAsGroup: #config.securityContext.runAsGroup
					        runAsNonRoot: #config.securityContext.runAsNonRoot
					        readOnlyRootFilesystem: #config.securityContext.readOnlyRootFilesystem
					        capabilities: {
								drop: #config.securityContext.capabilities.drop
					        }
				        }
						ports: [
							{
								name:          "http"
								containerPort: #config.service.main.ports.http.port
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							tcpSocket: port: #config.service.main.ports.http.port
							initialDelaySeconds: 0
							failureThreshold:    3
							timeoutSeconds:      1
							periodSeconds:       10
						}
						readinessProbe: {
							tcpSocket: port: #config.service.main.ports.http.port
							initialDelaySeconds: 0
							failureThreshold:    3
							timeoutSeconds:      1
							periodSeconds:       10
						}
						startupProbe: {
							tcpSocket: port: #config.service.main.ports.http.port
							initialDelaySeconds: 0
							failureThreshold:    30
							timeoutSeconds:      1
							periodSeconds:       5
						}
						#env: [
							for key, val in #config.env if val != null {
								name:  key
								value: "\(val)"
							},
						]
						if len(#env) > 0 {
							env: #env
						}
						#volumeMounts: [
							if #config.persistence.data.enabled {
								{name: "data", mountPath: #config.persistence.data.mountPath}
							},
						]
						if len(#volumeMounts) > 0 {
							volumeMounts: #volumeMounts
						}
					},
				]

				initContainers: [{
					name:  "fix-permissions"
	                image: "busybox:1.36"
	                command: ["sh", "-c", "chown -R 1000:1000 /readeck && chmod -R u+rwX,g+rwX /readeck"]
	                securityContext: {
						runAsUser: 0
	                }
	                volumeMounts: [{
						name:      "data"
		                mountPath: #config.persistence.data.mountPath
	                }]
                }]

				#volumes: [
					if #config.persistence.data.enabled {
						{
							name: "data"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
						}
					},
				]
				if len(#volumes) > 0 {
					volumes: #volumes
				}
			}
		}
	}
}