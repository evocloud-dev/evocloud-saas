package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis"
	}

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #meta.#LabelSelector
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata:   #meta
	spec: appsv1.#StatefulSetSpec & {
		serviceName: #meta.name
		replicas:    1
		selector: matchLabels: #meta.#LabelSelector
		template: {
			metadata: {
				labels: #meta.#LabelSelector
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            "redis"
						image:           #config.images.cache.reference
						imagePullPolicy: #config.images.cache.pullPolicy
						ports: [
							{
								name:          "redis"
								containerPort: #config.cache.port
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/data"
							},
						]
						livenessProbe: {
							exec: {
								command: ["redis-cli", "ping"]
							}
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
						}
						readinessProbe: {
							exec: {
								command: ["redis-cli", "ping"]
							}
							initialDelaySeconds: 5
							periodSeconds:       5
							timeoutSeconds:      5
						}
						resources: #config.cache.resources
						if #config.cache.securityContext != _|_ {
							securityContext: #config.cache.securityContext
						}
					},
				]
				if !#config.cache.persistence.enabled {
					volumes: [
						{
							name: "data"
							emptyDir: {}
						},
					]
				}
				if #config.cache.podSecurityContext != _|_ {
					securityContext: #config.cache.podSecurityContext
				}
				if #config.cache.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				nodeSelector: #config.nodeSelector
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				affinity: _affinity
			}
		}
		if #config.cache.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: [corev1.#ReadWriteOnce]
						resources: requests: (corev1.#ResourceStorage): #config.cache.persistence.size
						if #config.cache.persistence.storageClass != _|_ {
							storageClassName: #config.cache.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

#RedisService: corev1.#Service & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   #meta
	spec: corev1.#ServiceSpec & {
		type: [
			if #config.cache.service != _|_ { #config.cache.service.type },
			corev1.#ServiceTypeClusterIP,
		][0]
		selector: #meta.#LabelSelector
		ports: [
			{
				name:       "redis"
				port: [
					if #config.cache.service != _|_ { #config.cache.service.port },
					#config.cache.port,
				][0]
				targetPort: "redis"
				protocol:   "TCP"
			},
		]
	}
}
