package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgresqlSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	stringData: {
		"password": #config.postgresql.auth.password
	}
}

#PostgresqlService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "tcp-postgresql"
				port:       5432
				targetPort: "tcp-postgresql"
			},
		]
	}
}

#PostgresqlHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-hl"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type:      "ClusterIP"
		clusterIP: "None"
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "tcp-postgresql"
				port:       5432
				targetPort: "tcp-postgresql"
			},
		]
	}
}

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
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
			spec: {
				automountServiceAccountToken: false
				serviceAccountName: "\(#config.metadata.name)-postgresql"
				if #config.postgresql.podSecurityContext != _|_ {
					securityContext: #config.postgresql.podSecurityContext
				}
				containers: [
					{
						name:            "postgresql"
						image:           "\(#config.postgresql.image.registry)/\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						imagePullPolicy: "IfNotPresent"
						env: [
							{
								name:  "POSTGRES_USER"
								value: #config.postgresql.auth.username
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql"
									key:  "password"
								}
							},
							{
								name:  "POSTGRES_DB"
								value: #config.postgresql.auth.database
							},
						]
						ports: [
							{
								name:          "tcp-postgresql"
								containerPort: 5432
							},
						]
						if #config.postgresql.resources != _|_ {
							resources: #config.postgresql.resources
						}
						if #config.postgresql.securityContext != _|_ {
							securityContext: #config.postgresql.securityContext
						}
						if #config.postgresql.persistence.enabled {
							volumeMounts: [
								{
									name:      "data"
									mountPath: "/var/lib/postgresql"
								},
							]
						}
					},
				]
			}
		}
		if #config.postgresql.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "data"
					spec: {
						accessModes: #config.postgresql.persistence.accessModes
						if #config.postgresql.persistence.resources != _|_ {
							resources: #config.postgresql.persistence.resources
						}
						if #config.postgresql.persistence.storageClassName != "" {
							storageClassName: #config.postgresql.persistence.storageClassName
						}
					}
				},
			]
		}
	}
}

#PostgresqlServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
}
