package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MariaDBSubchart: appsv1.#StatefulSet & {
	#config: #Config

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
			"app.kubernetes.io/name":     "\(#config.metadata.name)-mariadb"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		serviceName: "\(#config.metadata.name)-mariadb-hl"
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-mariadb"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				containers: [
					{
						name:  "mariadb"
						image: "\(#config["mariadb-subchart"].image.repository):\(#config["mariadb-subchart"].image.tag)"
						env: [
							{
								name: "MARIADB_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.metadata.name
									key:  "mariadb-root-password"
								}
							},
							{
								name: "MARIADB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.metadata.name
									key:  "mariadb-password"
								}
							},
						]
						ports: [
							{
								name:          "mariadb"
								containerPort: 3306
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/bitnami/mariadb"
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
