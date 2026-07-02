package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #config.metadata & {
		name: #config.#serviceName
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		if len(#config.deploymentStrategy) > 0 {
			strategy: #config.deploymentStrategy
		}
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: #config.automountServiceAccountToken
				serviceAccountName: #config.#serviceAccountName
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if len(#config.podSecurityContext) > 0 {
					securityContext: #config.podSecurityContext
				}
				initContainers: [{
					name: "populate-html"
					image: #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					command: ["sh", "-c", "cp -r /var/www/html/. /mnt/html/"]
					if len(#config.securityContext) > 0 {
						securityContext: #config.securityContext
					}
					volumeMounts: [{
						name: "html"
						mountPath: "/mnt/html"
					}]
				}]
				containers: [{
					name:            "typo3"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					if len(#config.securityContext) > 0 {
						securityContext: #config.securityContext
					}
					ports: [{
						name:          "http"
						containerPort: 80
						protocol:      "TCP"
					}]
					if len(#config.resources) > 0 {
						resources: #config.resources
					}
					volumeMounts: [
						if #config.persistence.fileadmin.enabled {
							{
								name:      "fileadmin"
								mountPath: "/var/www/html/fileadmin"
							}
						},
						if #config.persistence.typo3conf.enabled {
							{
								name:      "typo3conf"
								mountPath: "/var/www/html/typo3conf"
							}
						},
						{
							name:      "html"
							mountPath: "/var/www/html"
						},
						{
							name:      "tmp"
							mountPath: "/tmp"
						},
						{
							name:      "var-run"
							mountPath: "/var/run"
						},
						{
							name:      "var-lock"
							mountPath: "/var/lock"
						},
						{
							name:      "var-log"
							mountPath: "/var/log"
						},
					]
				}]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				volumes: [
					if #config.persistence.fileadmin.enabled {
						{
							name: "fileadmin"
							persistentVolumeClaim: {
								claimName: "\(#config.metadata.name)-fileadmin"
								if #config.persistence.fileadmin.existingClaim != "" {
									claimName: #config.persistence.fileadmin.existingClaim
								}
							}
						}
					},
					if #config.persistence.typo3conf.enabled {
						{
							name: "typo3conf"
							persistentVolumeClaim: {
								claimName: "\(#config.metadata.name)-typo3conf"
								if #config.persistence.typo3conf.existingClaim != "" {
									claimName: #config.persistence.typo3conf.existingClaim
								}
							}
						}
					},
					{
						name: "html"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: {}
					},
					{
						name: "var-run"
						emptyDir: {}
					},
					{
						name: "var-lock"
						emptyDir: {}
					},
					{
						name: "var-log"
						emptyDir: {}
					},
				]
			}
		}
	}
}