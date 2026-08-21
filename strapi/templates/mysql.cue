package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MySQLSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-mysql-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"mysql-root-password": [
			if #config.mysql.auth.rootPassword != "" {#config.mysql.auth.rootPassword},
			"strapi-mysql-root-password",
		][0]
		"database-password": [
			if #config.mysql.auth.password != "" {#config.mysql.auth.password},
			"strapi-mysql-password",
		][0]
	}
}

#MySQLSVC: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: "mysql"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#MySQLHeadlessSVC: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-mysql-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: "mysql"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#MySQLSts: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.fullname)-mysql-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "mysql"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: [
					if #config.serviceAccount.name != "" {#config.serviceAccount.name},
					#config.fullname,
				][0]
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				securityContext: {
					fsGroup:      65510
					runAsUser:    65510
					runAsGroup:   65510
					runAsNonRoot: true
					seccompProfile: type: "RuntimeDefault"
				}
				containers: [
					{
						name:            "mysql"
						image:           [if #config.mysql.image != _|_ {"\(#config.mysql.image.repository):\(#config.mysql.image.tag)"}, "docker.io/library/mysql:9.7.1"][0]
						imagePullPolicy: "IfNotPresent"
						securityContext: {
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
							runAsNonRoot: true
							runAsUser:    65510
							runAsGroup:   65510
							seccompProfile: type: "RuntimeDefault"
						}
						ports: [
							{
								name:          "mysql"
								containerPort: 3306
								protocol:      "TCP"
							},
						]
						env: [
							{name: "MYSQL_DATABASE", value: #config.mysql.auth.database},
							{name: "MYSQL_USER", value: #config.mysql.auth.username},
							{
								name: "MYSQL_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.fullname)-mysql-auth"
									key:  "database-password"
								}
							},
							{
								name: "MYSQL_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.fullname)-mysql-auth"
									key:  "mysql-root-password"
								}
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/mysql"
							},
						]
						if #config.mysql.primary.resources != _|_ {
							resources: #config.mysql.primary.resources
						}
					},
				]
				if !#config.mysql.primary.persistence.enabled {
					volumes: [
						{
							name: "data"
							emptyDir: {}
						},
					]
				}
			}
		}
		if #config.mysql.primary.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						if #config.mysql.primary.persistence.storageClass != "" {
							storageClassName: #config.mysql.primary.persistence.storageClass
						}
						resources: requests: storage: #config.mysql.primary.persistence.size
					}
				},
			]
		}
	}
}
