package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PGSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-postgresql-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"postgres-password": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"strapi-postgres-password",
		][0]
		"database-password": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"strapi-postgres-password",
		][0]
	}
}

#PGSVC: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "tcp-postgresql"
				port:       5432
				targetPort: "tcp-postgresql"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PGHeadlessSVC: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				name:       "tcp-postgresql"
				port:       5432
				targetPort: "tcp-postgresql"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PGSts: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.fullname)-postgresql-primary-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "postgresql"
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
						name:            "postgresql"
						image:           [if #config.postgresql.image != _|_ {"\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"}, "docker.io/library/postgres:18.4-trixie"][0]
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
								name:          "tcp-postgresql"
								containerPort: 5432
								protocol:      "TCP"
							},
						]
						env: [
							{name: "POSTGRES_DB", value: #config.postgresql.auth.database},
							{name: "POSTGRES_USER", value: #config.postgresql.auth.username},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.fullname)-postgresql-auth"
									key:  "database-password"
								}
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/postgresql"
							},
						]
						if #config.postgresql.primary.resources != _|_ {
							resources: #config.postgresql.primary.resources
						}
					},
				]
				if !#config.postgresql.primary.persistence.enabled {
					volumes: [
						{
							name: "data"
							emptyDir: {}
						},
					]
				}
			}
		}
		if #config.postgresql.primary.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						if #config.postgresql.primary.persistence.storageClass != "" {
							storageClassName: #config.postgresql.primary.persistence.storageClass
						}
						resources: requests: storage: #config.postgresql.primary.persistence.size
					}
				},
			]
		}
	}
}
