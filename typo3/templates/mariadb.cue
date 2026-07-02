package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MariaDB: {
	#config: #Config

	objects: [
		corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-mariadb"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			type: corev1.#SecretTypeOpaque
			stringData: {
				"mariadb-password":      #config.mariadb.auth.password
				"mariadb-root-password": #config.mariadb.auth.password
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-mariadb"
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
					"app.kubernetes.io/name":      "mariadb"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-mariadb-headless"
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
					"app.kubernetes.io/name":      "mariadb"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-mariadb"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				replicas: 1
				selector: matchLabels: {
					"app.kubernetes.io/name":      "mariadb"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				serviceName: "\(#config.metadata.name)-mariadb-headless"
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      "mariadb"
						"app.kubernetes.io/instance":  #config.metadata.name
					}
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "mariadb"
							image: "\(#config.mariadb.image.repository):\(#config.mariadb.image.tag)"
							env: [{
								name:  "MARIADB_DATABASE"
								value: #config.mariadb.auth.database
							}, {
								name:  "MARIADB_USER"
								value: #config.mariadb.auth.username
							}, {
								name: "MARIADB_PASSWORD"
								valueFrom: secretKeyRef: {
									key:  "mariadb-password"
									name: "\(#config.metadata.name)-mariadb"
								}
							}, {
								name: "MARIADB_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									key:  "mariadb-root-password"
									name: "\(#config.metadata.name)-mariadb"
								}
							}]
							ports: [{
								name:          "mysql"
								containerPort: 3306
							}]
							volumeMounts: [{
								name:      "data"
								mountPath: "/bitnami/mariadb"
							}]
						}]
						if !#config.mariadb.persistence.enabled {
							volumes: [{
								name: "data"
								emptyDir: {}
							}]
						}
					}
				}
				if #config.mariadb.persistence.enabled {
					volumeClaimTemplates: [{
						metadata: name: "data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							if len(#config.mariadb.persistence.accessModes) > 0 {
								accessModes: #config.mariadb.persistence.accessModes
							}
							resources: #config.mariadb.persistence.resources
							if #config.mariadb.persistence.storageClassName != "" {
								storageClassName: #config.mariadb.persistence.storageClassName
							}
						}
					}]
				}
			}
		}
	]
}
