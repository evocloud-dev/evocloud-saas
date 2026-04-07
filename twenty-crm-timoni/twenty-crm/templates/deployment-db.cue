package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DatabaseDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name: "\(#config.metadata.name)-db"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "db"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		strategy: #config.db.internal.strategy
		replicas: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "db"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      #config.metadata.name
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "db"
			}
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "db"
						image:           #config.db.internal.image.reference
						imagePullPolicy: #config.db.internal.image.pullPolicy
						ports: [
							{
								containerPort: 5432
								name:          "tcp-db"
							},
						]
						env: [
							{
								name: "PGUSER_SUPERUSER"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-db-superuser"
									key:  "username"
								}
							},
							{
								name: "PGPASSWORD_SUPERUSER"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-db-superuser"
									key:  "password"
								}
							},
							{
								name:  "SPILO_PROVIDER"
								value: #config.db.internal.env.SPILO_PROVIDER
							},
							{
								name:  "ALLOW_NOSSL"
								value: #config.db.internal.env.ALLOW_NOSSL
							},
						]
						resources: #config.db.internal.resources
						volumeMounts: [
							if #config.db.internal.persistence.enabled {
								{
									name:      "db-data"
									mountPath: "/home/postgres/pgdata"
								}
							},
						]
					},
				]
				volumes: [
					if #config.db.internal.persistence.enabled {
						{
							name: "db-data"
							persistentVolumeClaim: claimName: {
								if #config.db.internal.persistence.existingClaim != "" {
									#config.db.internal.persistence.existingClaim
								}
								if #config.db.internal.persistence.existingClaim == "" {
									"\(#config.metadata.name)-db"
								}
							}
						}
					},
				]
			}
		}
	}
}
