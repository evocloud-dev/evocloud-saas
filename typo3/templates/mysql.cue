package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MySQL: {
	#config: #Config

	objects: [
		corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-mysql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			type: corev1.#SecretTypeOpaque
			stringData: {
				"mysql-password":      #config.mysql.auth.password
				"mysql-root-password": #config.mysql.auth.password
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-mysql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				ports: [{
					name:       "mysql"
					port:       3306
					protocol:   "TCP"
					targetPort: "mysql"
				}]
				selector: {
					"app.kubernetes.io/name":      "mysql"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-mysql-headless"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				clusterIP: "None"
				ports: [{
					name:       "mysql"
					port:       3306
					protocol:   "TCP"
					targetPort: "mysql"
				}]
				selector: {
					"app.kubernetes.io/name":      "mysql"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-mysql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				replicas: 1
				selector: matchLabels: {
					"app.kubernetes.io/name":      "mysql"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				serviceName: "\(#config.metadata.name)-mysql-headless"
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      "mysql"
						"app.kubernetes.io/instance":  #config.metadata.name
					}
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "mysql"
							image: "\(#config.mysql.image.repository):\(#config.mysql.image.tag)"
							env: [{
								name:  "MYSQL_DATABASE"
								value: #config.mysql.auth.database
							}, {
								name:  "MYSQL_USER"
								value: #config.mysql.auth.username
							}, {
								name: "MYSQL_PASSWORD"
								valueFrom: secretKeyRef: {
									key:  "mysql-password"
									name: "\(#config.metadata.name)-mysql"
								}
							}, {
								name: "MYSQL_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									key:  "mysql-root-password"
									name: "\(#config.metadata.name)-mysql"
								}
							}]
							ports: [{
								name:          "mysql"
								containerPort: 3306
							}]
							volumeMounts: [{
								name:      "data"
								mountPath: "/bitnami/mysql"
							}]
						}]
						if !#config.mysql.persistence.enabled {
							volumes: [{
								name: "data"
								emptyDir: {}
							}]
						}
					}
				}
				if #config.mysql.persistence.enabled {
					volumeClaimTemplates: [{
						metadata: name: "data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							if len(#config.mysql.persistence.accessModes) > 0 {
								accessModes: #config.mysql.persistence.accessModes
							}
							resources: #config.mysql.persistence.resources
							if #config.mysql.persistence.storageClassName != "" {
								storageClassName: #config.mysql.persistence.storageClassName
							}
						}
					}]
				}
			}
		}
	]
}
