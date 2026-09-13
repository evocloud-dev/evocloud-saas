package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#MySQLSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-mysql-auth"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"mysql-user-password": [
			if #config.mysql.auth.password != "" {#config.mysql.auth.password},
			"CHANGE_ME_MYSQL_PASSWORD",
		][0]
		if #config.mysql.auth.rootPassword != "" {
			"mysql-root-password": #config.mysql.auth.rootPassword
		}
		"mysql-root-password": [
			if #config.mysql.auth.rootPassword != "" {#config.mysql.auth.rootPassword},
			"CHANGE_ME_MYSQL_ROOT_PASSWORD",
		][0]
	}
}

#MySQLService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-mysql"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
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

#MySQLHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-mysql-headless"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
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

#MySQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-mysql"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
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
				automountServiceAccountToken: false
				serviceAccountName:           #config.serviceAccountName
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
					if #config.mysql.standalone.resources != _|_ {
						resources: #config.mysql.standalone.resources
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
						{
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
						if #config.mysql.standalone.persistence.storageClass != "" {
							storageClassName: #config.mysql.standalone.persistence.storageClass
						}
						resources: requests: (corev1.#ResourceStorage): resource.#Quantity & #config.mysql.standalone.persistence.size
					}
				},
			]
		}
	}
}
