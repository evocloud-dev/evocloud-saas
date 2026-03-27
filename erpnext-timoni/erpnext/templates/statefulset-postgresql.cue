package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-sts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql-sts"
			"app.kubernetes.io/instance": #config.metadata.name
		}

		serviceName: "\(#config.metadata.name)-postgresql-sts"
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql-sts"
				"app.kubernetes.io/instance": #config.metadata.name
			}

			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				containers: [
					{
						name:            "postgresql"
						image:           "\(#config["postgresql-sts"].image.repository):\(#config["postgresql-sts"].image.tag)"
						imagePullPolicy: #config["postgresql-sts"].image.pullPolicy
						env: [
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.metadata.name
									key:  "postgres-password"
								}
							},
							{
								name:  "PGDATA"
								value: "/var/lib/postgresql/data/pgdata"
							},
						]
						ports: [
							{
								name:          "postgresql"
								containerPort: 5432
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							tcpSocket: port: 5432
							initialDelaySeconds: 30
							periodSeconds:       10
						}
						readinessProbe: {
							tcpSocket: port: 5432
							initialDelaySeconds: 5
							periodSeconds:       10
						}
						resources: #config["postgresql-sts"].resources
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/postgresql/data"
							},
						]
					},
				]
			}
		}
		volumeClaimTemplates: [
			{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					if #config["postgresql-sts"].persistence.storageClass != "" {
						storageClassName: #config["postgresql-sts"].persistence.storageClass
					}
					resources: requests: storage: #config["postgresql-sts"].persistence.size
				}
			},
		]
	}
}
