package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MySQL: {
	#config: #Config

	objects: {
		svc: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-mysql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				type: "ClusterIP"
				ports: [{
					name:       "mysql"
					port:       3306
					targetPort: 3306
				}]
				selector: "app.kubernetes.io/name": #config.metadata.name + "-mysql"
			}
		}

		"svc-hl": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-mysql-hl"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [{
					name:       "mysql"
					port:       3306
					targetPort: 3306
				}]
				selector: "app.kubernetes.io/name": #config.metadata.name + "-mysql"
			}
		}

		sts: appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      #config.metadata.name + "-mysql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				serviceName: #config.metadata.name + "-mysql-hl"
				replicas:    1
				selector: matchLabels: "app.kubernetes.io/name": #config.metadata.name + "-mysql"
				template: {
					metadata: labels: "app.kubernetes.io/name": #config.metadata.name + "-mysql"
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "mysql"
							image: #config.#myImageRef
							ports: [{
								name:          "mysql"
								containerPort: 3306
							}]
							imagePullPolicy: #config.mysql.image.pullPolicy
							env: [
								{
									name:  "MYSQL_USER"
									value: #config.mysql.auth.username
								},
								{
									name:  "MYSQL_PASSWORD"
									value: #config.mysql.auth.password
								},
								{
									name:  "MYSQL_DATABASE"
									value: #config.mysql.auth.database
								},
								{
									name:  "MYSQL_ROOT_PASSWORD"
									value: #config.mysql.auth.password
								},
							]
							livenessProbe:  #config.mysql.livenessProbe
							readinessProbe: #config.mysql.readinessProbe
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
					volumeClaimTemplates: [
						{
							metadata: name: "data"
							spec: corev1.#PersistentVolumeClaimSpec & {
								accessModes: ["ReadWriteOnce"]
								resources: requests: storage: #config.mysql.persistence.size
							}
						},
					]
				}
			}
		}
	}
}
