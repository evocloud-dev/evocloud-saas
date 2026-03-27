package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MariaDBStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-mariadb-sts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-mariadb-sts"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		serviceName: "\(#config.metadata.name)-mariadb-sts"
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-mariadb-sts"
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
						name:            "mariadb"
						image:           "\(#config["mariadb-sts"].image.repository):\(#config["mariadb-sts"].image.tag)"
						imagePullPolicy: #config["mariadb-sts"].image.pullPolicy
						env: [
							{
								name: "MARIADB_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.metadata.name
									key:  "mariadb-root-password"
								}
							},
						]
						ports: [
							{
								name:          "mysql"
								containerPort: 3306
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							tcpSocket: port: 3306
							initialDelaySeconds: 30
							periodSeconds:       10
						}
						readinessProbe: {
							tcpSocket: port: 3306
							initialDelaySeconds: 5
							periodSeconds:       10
						}
						resources: #config["mariadb-sts"].resources
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/mysql"
							},
							if #config["mariadb-sts"].myCnf != _|_ {
								{
									name:      "config"
									mountPath: "/etc/mysql/conf.d/my.cnf"
									subPath:   "my.cnf"
								}
							},
						]
					},
				]
				if #config["mariadb-sts"].myCnf != _|_ {
					volumes: [
						{
							name: "config"
							configMap: name: "\(#config.metadata.name)-mariadb-sts"
						},
					]
				}
			}
		}
		volumeClaimTemplates: [
			{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					if #config["mariadb-sts"].persistence.storageClass != "" {
						storageClassName: #config["mariadb-sts"].persistence.storageClass
					}
					resources: requests: storage: #config["mariadb-sts"].persistence.size
				}
			},
		]
	}
}
