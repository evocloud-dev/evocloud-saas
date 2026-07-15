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
		name:      "\(#config.metadata.name)-mysql-auth"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	type: "Opaque"
	stringData: "mysql-user-password": #config.mysql.auth.password
}

#MySQLService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			name:       "mysql"
			port:       3306
			targetPort: "mysql"
			protocol:   "TCP"
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
		name:      "\(#config.metadata.name)-mysql-headless"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [{
			name:       "mysql"
			port:       3306
			targetPort: "mysql"
			protocol:   "TCP"
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
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.metadata.name)-mysql-headless"
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
				terminationGracePeriodSeconds: 30
				containers: [{
					name:            "mysql"
					image:           "\(#config.mysql.image.repository):\(#config.mysql.image.tag)"
					imagePullPolicy: #config.mysql.image.pullPolicy
					ports: [{
						name:          "mysql"
						containerPort: 3306
						protocol:      "TCP"
					}]
					env: [
						{name: "MYSQL_DATABASE", value: #config.mysql.auth.database},
						{name: "MYSQL_USER", value: #config.mysql.auth.username},
						{
							name: "MYSQL_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "\(#config.metadata.name)-mysql-auth"
								key:  "mysql-user-password"
							}
						},
						{
							name: "MYSQL_ROOT_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "\(#config.metadata.name)-mysql-auth"
								key:  "mysql-user-password"
							}
						},
					]
					if len(#config.mysql.standalone.resources) > 0 {
						resources: #config.mysql.standalone.resources
					}
					volumeMounts: [{
						name:      "data"
						mountPath: "/var/lib/mysql"
					}]
					livenessProbe: {
						exec: command: ["mysqladmin", "ping", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    3
					}
					readinessProbe: {
						exec: command: ["mysqladmin", "ping", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
						initialDelaySeconds: 5
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    3
					}
				}]
			}
		}
		if #config.mysql.standalone.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: #config.mysql.standalone.persistence.size
				}
			}]
		}
	}
}
