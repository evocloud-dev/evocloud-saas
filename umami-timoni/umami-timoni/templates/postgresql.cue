package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQL: {
	#config: #Config

	objects: {
		svc: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				type: "ClusterIP"
				ports: [{
					name:       "tcp-postgresql"
					port:       5432
					targetPort: "postgresql"
				}]
				selector: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
			}
		}

		"svc-hl": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-postgresql-hl"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [{
					name:       "tcp-postgresql"
					port:       5432
					targetPort: "postgresql"
				}]
				selector: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
			}
		}

		sts: appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      #config.metadata.name + "-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				serviceName: #config.metadata.name + "-postgresql-hl"
				replicas:    1
				selector: matchLabels: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
				template: {
					metadata: labels: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "postgresql"
							image: #config.#pgImageRef
							ports: [{
								name:          "postgresql"
								containerPort: 5432
							}]
							imagePullPolicy: #config.postgresql.image.pullPolicy
							env: [
								{
									name:  "POSTGRESQL_USERNAME"
									value: #config.postgresql.auth.username
								},
								{
									name:  "POSTGRESQL_PASSWORD"
									value: #config.postgresql.auth.password
								},
								{
									name:  "POSTGRESQL_DATABASE"
									value: #config.postgresql.auth.database
								},
							]
							livenessProbe:  #config.postgresql.livenessProbe
							readinessProbe: #config.postgresql.readinessProbe
							volumeMounts: [{
								name:      "data"
								mountPath: "/bitnami/postgresql"
							}]
						}]
						if !#config.postgresql.persistence.enabled {
							volumes: [{
								name: "data"
								emptyDir: {}
							}]
						}
					}
				}
				if #config.postgresql.persistence.enabled {
					volumeClaimTemplates: [
						{
							metadata: name: "data"
							spec: corev1.#PersistentVolumeClaimSpec & {
								accessModes: ["ReadWriteOnce"]
								resources: requests: storage: #config.postgresql.persistence.size
							}
						},
					]
				}
			}
		}
	}
}
