package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PostgresService: corev1.#Service & {
	#config: #Config

	let _meta = timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "postgres"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   _meta
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeClusterIP
		selector: _meta.#LabelSelector
		ports: [
			{
				port:       #config.postgres.port
				protocol:   "TCP"
				name:       "postgres"
				targetPort: name
			},
		]
	}
}

#PostgresStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	let _meta = timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "postgres"
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata:   _meta
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: _meta.name
		selector: matchLabels: _meta.#LabelSelector
		template: {
			metadata: {
				labels: _meta.#LabelSelector
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.metadata.name
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            "postgres"
						image:           #config.postgres.image.reference
						imagePullPolicy: #config.postgres.image.pullPolicy
						ports: [
							{
								name:          "postgres"
								containerPort: #config.postgres.port
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "POSTGRES_DB"
								value: #config.postgres.database
							},
							{
								name:  "POSTGRES_USER"
								value: #config.postgres.user
							},
							{
								name:  "POSTGRES_PASSWORD"
								value: #config.postgres.password
							},
							{
								name:  "PGDATA"
								value: "/var/lib/postgresql/data/pgdata"
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-c",
								"pg_isready -U \(#config.postgres.user) -d \(#config.postgres.database)",
							]
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      3
							failureThreshold:    5
						}
						readinessProbe: {
							exec: command: [
								"sh",
								"-c",
								"pg_isready -U \(#config.postgres.user) -d \(#config.postgres.database)",
							]
							initialDelaySeconds: 5
							periodSeconds:       5
							timeoutSeconds:      3
							failureThreshold:    5
						}
						volumeMounts: [
							{
								name:      "postgres-data"
								mountPath: "/var/lib/postgresql/data"
							},
						]
						resources:       #config.postgres.resources
						securityContext: #config.postgres.securityContext
					},
				]
				securityContext: #config.postgres.podSecurityContext
				nodeSelector:    #config.nodeSelector
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
		volumeClaimTemplates: [
			{
				metadata: {
					name:   "postgres-data"
					labels: _meta.labels
					if #config.postgres.persistence.annotations != _|_ {
						annotations: #config.postgres.persistence.annotations
					}
				}
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: #config.postgres.persistence.accessModes
					resources: requests: storage: #config.postgres.persistence.size
					if #config.postgres.persistence.storageClass != _|_ {
						storageClassName: #config.postgres.persistence.storageClass
					}
				}
			},
		]
	}
}
