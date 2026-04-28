package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#WorkerDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "worker"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.worker.autoscaling.enabled {
			replicas: #config.worker.replicaCount
		}
		selector: matchLabels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-worker"}).labels & {
			"app.kubernetes.io/component": "worker"
		}
		template: {
			metadata: {
				if #config.worker.podAnnotations != _|_ {
					annotations: #config.worker.podAnnotations
				}
				labels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-worker"}).labels & {
					"app.kubernetes.io/component": "worker"
				}
			}
			spec: corev1.#PodSpec & {
				if #config.global.imagePullSecrets != [] {
					imagePullSecrets: #config.global.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.worker.replicaCount > 1 {
					affinity: podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [
						{
							weight: 100
							podAffinityTerm: {
								labelSelector: matchExpressions: [
									{
										key:      "app.kubernetes.io/component"
										operator: "In"
										values: ["worker"]
									},
								]
								topologyKey: "kubernetes.io/hostname"
							}
						},
					]
				}
				containers: [
					{
						name: "saleor-worker"
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
						image:           "\(#config.global.image.repository):\(#config.global.image.tag)"
						imagePullPolicy: #config.global.image.pullPolicy
						command: ["celery"]
						args: ["--app=saleor.celeryconf:app", "worker", "-E", "--loglevel=info"]
						livenessProbe: {
							exec: command: ["/bin/sh", "-c", "celery -A saleor inspect ping -d celery@$HOSTNAME"]
							initialDelaySeconds: 30
							periodSeconds:       30
							timeoutSeconds:      15
							successThreshold:    1
							failureThreshold:    3
						}
						readinessProbe: {
							exec: command: ["/bin/sh", "-c", "celery -A saleor inspect ping -d celery@$HOSTNAME"]
							initialDelaySeconds: 30
							periodSeconds:       30
							timeoutSeconds:      15
							successThreshold:    1
							failureThreshold:    3
						}
						resources: #config.worker.resources
						volumeMounts: [
							if #config.#internal.readReplicaEnabled {
								{
									name:      "settings"
									mountPath: "/app/saleor/settings.py"
									subPath:   "settings.py"
								}
							},
							if #config.storage.gcs.enabled && #config.storage.gcs.credentials.jsonKey != "" {
								{
									name:      "gcs-credentials"
									mountPath: "/var/secrets/google"
									readOnly:  true
								}
							},
						]
						env: #config.#internal.celeryEnv
					},
				]
				volumes: [
					if #config.#internal.readReplicaEnabled {
						{
							name: "settings"
							configMap: name: "\(#config.metadata.name)-settings"
						}
					},
					if #config.storage.gcs.enabled && #config.storage.gcs.credentials.jsonKey != "" {
						{
							name: "gcs-credentials"
							secret: secretName: "\(#config.metadata.name)-gcs-credentials"
						}
					},
				]
				if #config.worker.nodeSelector != _|_ {
					nodeSelector: #config.worker.nodeSelector
				}
				if #config.worker.tolerations != _|_ {
					tolerations: #config.worker.tolerations
				}
				if #config.worker.affinity != _|_ {
					affinity: #config.worker.affinity
				}
			}
		}
	}
}
