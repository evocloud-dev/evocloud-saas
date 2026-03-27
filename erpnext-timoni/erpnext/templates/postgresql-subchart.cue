package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLSubchart: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		serviceName: "\(#config.metadata.name)-postgresql-hl"
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				containers: [
					{
						name:  "postgresql"
						image: "\(#config["postgresql-subchart"].image.repository):\(#config["postgresql-subchart"].image.tag)"
						env: [
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.metadata.name
									key:  "postgres-password"
								}
							},
						]
						ports: [
							{
								name:          "postgresql"
								containerPort: 5432
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/bitnami/postgresql"
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
					resources: requests: storage: "8Gi"
				}
			},
		]
	}
}
