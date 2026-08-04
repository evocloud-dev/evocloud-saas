package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MySQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.metadata.name)-mysql-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/component": "primary"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "mysql"
					"app.kubernetes.io/instance": #config.metadata.name
					"app.kubernetes.io/component": "primary"
				}
			}
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "mysql"
						image:           "\(#config.mysql.image.registry)/\(#config.mysql.image.repository):\(#config.mysql.image.tag)"
						imagePullPolicy: #config.mysql.image.pullPolicy
						ports: [
							{
								containerPort: 3306
								name:          "mysql"
							},
						]
						env: [
							if #config.mysql.auth.rootPassword != "" {
								{
									name:  "MYSQL_ROOT_PASSWORD"
									value: #config.mysql.auth.rootPassword
								}
							},
							if #config.mysql.auth.rootPassword == "" {
								{
									name:  "MYSQL_ALLOW_EMPTY_PASSWORD"
									value: "yes"
								}
							},
							{
								name:  "MYSQL_DATABASE"
								value: #config.mysql.auth.database
							},
							if #config.mysql.auth.username != "" {
								{
									name:  "MYSQL_USER"
									value: #config.mysql.auth.username
								}
							},
							if #config.mysql.auth.password != "" {
								{
									name:  "MYSQL_PASSWORD"
									value: #config.mysql.auth.password
								}
							},
						]
						volumeMounts: [
							{
								name:      "mysql-data"
								mountPath: "/var/lib/mysql"
							},
						]
						resources:       #config.mysql.primary.resources
						securityContext: #config.mysql.primary.securityContext
					},
				]
				securityContext: #config.mysql.primary.podSecurityContext
			}
		}
		if #config.mysql.primary.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "mysql-data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						resources: {
							requests: storage: #config.mysql.primary.persistence.size
						}
					}
				},
			]
		}
	}
}

#MySQLService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/component": "primary"
		}
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: 3306
				protocol:   "TCP"
			},
		]
	}
}

#MySQLHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mysql-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		clusterIP: "None"
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/component": "primary"
		}
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: 3306
				protocol:   "TCP"
			},
		]
	}
}
