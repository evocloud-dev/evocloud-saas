package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ValkeyService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-valkey-primary"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "valkey"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "tcp-valkey"
				port:       6379
				targetPort: "valkey"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "valkey"
		}
	}
}

#ValkeyStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config._fullname)-valkey-primary"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "valkey"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config._fullname)-valkey-primary"
		replicas:    1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "valkey"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "valkey"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					fsGroup: 1001
				}
				containers: [
					{
						name:  "valkey"
						image: "\(#config.valkey.image.registry)/\(#config.valkey.image.repository):\(#config.valkey.image.tag)"
						imagePullPolicy: #config.valkey.image.pullPolicy
						securityContext: {
							runAsUser:                1001
							runAsGroup:               1001
							runAsNonRoot:             true
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
						}
						env: [
							{
								name: "VALKEY_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._fullname)-valkey"
									key:  "tasks-password"
								}
							},
						]
						ports: [
							{
								name:          "valkey"
								containerPort: 6379
							},
						]
						volumeMounts: [
							{
								name:      "valkey-data"
								mountPath: #config.valkey.persistence.mountPath
								if #config.valkey.persistence.subPath != "" {
									subPath: #config.valkey.persistence.subPath
								}
							},
							{
								name:      "valkey-tmp"
								mountPath: "/opt/bitnami/valkey/tmp"
							},
							{
								name:      "valkey-logs"
								mountPath: "/opt/bitnami/valkey/logs"
							},
							{
								name:      "valkey-etc"
								mountPath: "/opt/bitnami/valkey/etc"
							},
						]
					},
				]
				volumes: [
					{
						name: "valkey-tmp"
						emptyDir: {}
					},
					{
						name: "valkey-logs"
						emptyDir: {}
					},
					{
						name: "valkey-etc"
						emptyDir: {}
					},
				]
			}
		}
		volumeClaimTemplates: [
			if #config.valkey.persistence.enabled {
				corev1.#PersistentVolumeClaim & {
					metadata: name: "valkey-data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: [#config.valkey.persistence.accessMode]
						if #config.valkey.persistence.storageClass != "" {
							storageClassName: #config.valkey.persistence.storageClass
						}
						resources: requests: storage: #config.valkey.persistence.size
					}
				}
			},
		]
	}
}

#ValkeyHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-valkey-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "caching"
		}
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				name:       "tcp-redis"
				port:       6379
				targetPort: "valkey"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "caching"
		}
	}
}

#ValkeyReplicasService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-valkey-replicas"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "caching"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "tcp-redis"
				port:       6379
				targetPort: "valkey"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "caching"
		}
	}
}

#ValkeyReplicasStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config._fullname)-valkey-replicas"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "caching"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config._fullname)-valkey-headless"
		replicas:    #config.valkey.replicaCount
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "caching"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "caching"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					fsGroup: 1001
				}
				containers: [
					{
						name:  "valkey"
						image: "\(#config.valkey.image.registry)/\(#config.valkey.image.repository):\(#config.valkey.image.tag)"
						imagePullPolicy: #config.valkey.image.pullPolicy
						securityContext: {
							runAsUser:                1001
							runAsGroup:               1001
							runAsNonRoot:             true
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
						}
						env: [
							{
								name: "VALKEY_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._fullname)-valkey"
									key:  "tasks-password"
								}
							},
							{
								name: "VALKEY_REPLICATION_MODE"
								value: "replica"
							},
							{
								name: "VALKEY_PRIMARY_HOST"
								value: "\(#config._fullname)-valkey-primary"
							},
							{
								name: "VALKEY_PRIMARY_PORT_NUMBER"
								value: "6379"
							},
							{
								name: "VALKEY_PRIMARY_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._fullname)-valkey"
									key:  "tasks-password"
								}
							},
						]
						ports: [
							{
								name:          "valkey"
								containerPort: 6379
							},
						]
						volumeMounts: [
							{
								name:      "valkey-data"
								mountPath: #config.valkey.persistence.mountPath
								if #config.valkey.persistence.subPath != "" {
									subPath: #config.valkey.persistence.subPath
								}
							},
							{
								name:      "valkey-tmp"
								mountPath: "/opt/bitnami/valkey/tmp"
							},
							{
								name:      "valkey-logs"
								mountPath: "/opt/bitnami/valkey/logs"
							},
							{
								name:      "valkey-etc"
								mountPath: "/opt/bitnami/valkey/etc"
							},
						]
					},
				]
				volumes: [
					{
						name: "valkey-tmp"
						emptyDir: {}
					},
					{
						name: "valkey-logs"
						emptyDir: {}
					},
					{
						name: "valkey-etc"
						emptyDir: {}
					},
				]
			}
		}
		volumeClaimTemplates: [
			if #config.valkey.persistence.enabled {
				corev1.#PersistentVolumeClaim & {
					metadata: name: "valkey-data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: [#config.valkey.persistence.accessMode]
						if #config.valkey.persistence.storageClass != "" {
							storageClassName: #config.valkey.persistence.storageClass
						}
						resources: requests: storage: #config.valkey.persistence.size
					}
				}
			},
		]
	}
}
