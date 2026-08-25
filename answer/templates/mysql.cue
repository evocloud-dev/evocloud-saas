package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	resource "k8s.io/apimachinery/pkg/api/resource"
)

#MySQLSecret: {
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
		"mysql-user-password": #config.mysql.auth.password
		if #config.mysql.auth.rootPassword != "" {
			"mysql-root-password": #config.mysql.auth.rootPassword
		}
	}
}

#MySQLService: {
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
		ports: [{
			port:       3306
			targetPort: 3306
			protocol:   "TCP"
			name:       "mysql"
		}]
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#MySQLHeadlessService: {
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
		ports: [{
			port:       3306
			targetPort: 3306
			protocol:   "TCP"
			name:       "mysql"
		}]
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#MySQLStatefulSet: {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.fullname)-mysql-headless"
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
				automountServiceAccountToken: [
					if #config.mysql.automountServiceAccountToken != _|_ {
						#config.mysql.automountServiceAccountToken
					},
					false,
				][0]
				serviceAccountName: [
					if #config.mysql.serviceAccountName != _|_ {
						#config.mysql.serviceAccountName
					},
					if #config.serviceAccount.create {
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						}
						if #config.serviceAccount.name == "" {
							#config.fullname
						}
					},
					"default",
				][0]
				if #config.mysql.podSecurityContext != _|_ {
					securityContext: #config.mysql.podSecurityContext
				}
				containers: [{
					name:            "mysql"
					image:           "\(#config.mysql.image.repository):\(#config.mysql.image.tag)"
					imagePullPolicy: #config.mysql.image.pullPolicy
					if #config.mysql.securityContext != _|_ {
						securityContext: #config.mysql.securityContext
					}
					ports: [{
						containerPort: 3306
						name:          "mysql"
					}]
					if #config.mysql.resources != _|_ {
						resources: #config.mysql.resources
					}
					env: [
						{
							name:  "MYSQL_DATABASE"
							value: #config.mysql.auth.database
						},
						{
							name:  "MYSQL_USER"
							value: #config.mysql.auth.username
						},
						{
							name: "MYSQL_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "\(#config.fullname)-mysql-auth"
								key:  "mysql-user-password"
							}
						},
						if #config.mysql.auth.rootPassword != "" {
							name: "MYSQL_ROOT_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "\(#config.fullname)-mysql-auth"
								key:  "mysql-root-password"
							}
						},
					]
					volumeMounts: [{
						name:      "data"
						mountPath: "/var/lib/mysql"
					}]
				}]
				if !#config.mysql.standalone.persistence.enabled {
					volumes: [{
						name: "data"
						emptyDir: {}
					}]
				}
			}
		}
		if #config.mysql.standalone.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						resources: requests: (corev1.#ResourceStorage): resource.#Quantity & #config.mysql.standalone.persistence.size
					}
				},
			]
		}
	}
}
