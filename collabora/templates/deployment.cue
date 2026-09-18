package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	#config:     #Config
	#cmName:     string
	#secretName: string

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
			if #config.deployment.labels != _|_ {
				#config.deployment.labels
			}
		}
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
			if #config.deployment.annotations != _|_ {
				#config.deployment.annotations
			}
		}
	}
	spec: appsv1.#DeploymentSpec & {
		minReadySeconds: #config.deployment.minReadySeconds
		if !#config.autoscaling.enabled {
			replicas: #config.replicas
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		strategy: {
			type: #config.deployment.type
			if #config.deployment.type == "RollingUpdate" {
				rollingUpdate: {
					maxUnavailable: #config.deployment.maxUnavailable
					maxSurge:       #config.deployment.maxSurge
				}
			}
		}
		selector: matchLabels: #config.selector.labels & {
			type: "main"
		}
		template: {
			metadata: {
				annotations: {
					"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
				}
				labels: #config.selector.labels & {
					"app.kubernetes.io/instance": #config.metadata.name
					type:                         "main"
					if #config.podLabels != _|_ {
						#config.podLabels
					}
				}
			}
			spec: corev1.#PodSpec & {
				if #config.deployment.hostAliases != _|_ {
					hostAliases: #config.deployment.hostAliases
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				hostNetwork:                  #config.hostNetwork
				hostPID:                      #config.hostPID
				hostIPC:                      #config.hostIPC
				shareProcessNamespace:        #config.shareProcessNamespace
				enableServiceLinks:           #config.enableServiceLinks
				restartPolicy:                #config.restartPolicy
				nodeSelector:                 #config.nodeSelector
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				dnsPolicy: #config.dnsPolicy
				if #config.dnsConfig != _|_ {
					dnsConfig: #config.dnsConfig
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				hostUsers: #config.hostUsers
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.deployment.containerPort
								protocol:      "TCP"
							},
						]
						securityContext: #config.securityContext
						envFrom: [
							{
								configMapRef: {
									name: #cmName
								}
							},
						]
						env: [
							{
								name: "username"
								valueFrom: secretKeyRef: {
									name: #secretName
									key:  [if #config.collabora.existingSecret.enabled {#config.collabora.existingSecret.usernameKey}, "username"][0]
								}
							},
							{
								name: "password"
								valueFrom: secretKeyRef: {
									name: #secretName
									key:  [if #config.collabora.existingSecret.enabled {#config.collabora.existingSecret.passwordKey}, "password"][0]
								}
							},
							for e in #config.collabora.env {e},
							for e in #config.extraEnvVars {e},
						]
						volumeMounts: #config._allVolumeMounts
						resources:    #config.resources
						if #config.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path:   #config.probes.liveness.path
									port:   #config.deployment.containerPort
									scheme: #config.probes._scheme
								}
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								periodSeconds:       #config.probes.liveness.periodSeconds
								timeoutSeconds:      #config.probes.liveness.timeoutSeconds
								successThreshold:    #config.probes.liveness.successThreshold
								failureThreshold:    #config.probes.liveness.failureThreshold
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path:   #config.probes.readiness.path
									port:   #config.deployment.containerPort
									scheme: #config.probes._scheme
								}
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								successThreshold:    #config.probes.readiness.successThreshold
								failureThreshold:    #config.probes.readiness.failureThreshold
							}
						}
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path:   #config.probes.startup.path
									port:   #config.deployment.containerPort
									scheme: #config.probes._scheme
								}
								failureThreshold: #config.probes.startup.failureThreshold
								periodSeconds:    #config.probes.startup.periodSeconds
							}
						}
					},
				]
				volumes: #config._allVolumes
			}
		}
	}
}
