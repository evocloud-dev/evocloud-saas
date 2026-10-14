package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#MysqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "mysql"
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
						name:            "mysql"
						image:           #config.images.database.reference
						imagePullPolicy: #config.images.database.pullPolicy
						args: ["mysqld", "--skip-log-bin"]
						ports: [
							{
								name:          "mysql"
								containerPort: 3306
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "MYSQL_DATABASE"
								value: #config.database.name
							},
							if #config.database.allowEmptyPassword {
								name:  "MYSQL_ALLOW_EMPTY_PASSWORD"
								value: "yes"
							},
							if !#config.database.allowEmptyPassword {
								name:  "MYSQL_ROOT_PASSWORD"
								value: #config.database.password
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/mysql"
							},
						]
						livenessProbe: {
							exec: {
								command: ["mysqladmin", "ping", "-h", "localhost"]
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
						}
						readinessProbe: {
							exec: {
								command: ["mysqladmin", "ping", "-h", "localhost"]
							}
							initialDelaySeconds: 15
							periodSeconds:       10
							timeoutSeconds:      5
						}
						resources: #config.database.resources
						if #config.database.securityContext != _|_ {
							securityContext: #config.database.securityContext
						}
					},
				]
				if !#config.database.persistence.enabled {
					volumes: [
						{
							name: "data"
							emptyDir: {}
						},
					]
				}
				if #config.database.podSecurityContext != _|_ {
					securityContext: #config.database.podSecurityContext
				}
				if #config.database.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
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
		if #config.database.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: [corev1.#ReadWriteOnce]
						resources: requests: (corev1.#ResourceStorage): #config.database.persistence.size
						if #config.database.persistence.storageClass != _|_ {
							storageClassName: #config.database.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

#MysqlService: corev1.#Service & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "mysql"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   #meta
	spec: corev1.#ServiceSpec & {
		type: [
			if #config.database.service != _|_ { #config.database.service.type },
			corev1.#ServiceTypeClusterIP,
		][0]
		selector: #meta.#LabelSelector
		ports: [
			{
				name:       "mysql"
				port: [
					if #config.database.service != _|_ { #config.database.service.port },
					#config.database.port,
				][0]
				targetPort: "mysql"
				protocol:   "TCP"
			},
		]
	}
}
