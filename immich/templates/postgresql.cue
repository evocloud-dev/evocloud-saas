package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLStatefulSetBuilder: {
	_config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(_config.fullname)-postgresql"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "database"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(_config.fullname)-postgresql-primary-headless"
		replicas:    1
		selector: matchLabels: _config.metadata.labels & {
			"app.kubernetes.io/component": "database"
		}
		template: corev1.#PodTemplateSpec & {
			metadata: labels: _config.metadata.labels & _config.commonLabels & {
				"app.kubernetes.io/component": "database"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccountName
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				securityContext:              _config.podSecurityContext
				containers: [{
					name:            "postgresql"
					image:           "\(_config.postgresql.image.repository):\(_config.postgresql.image.tag)"
					imagePullPolicy: _config.postgresql.image.pullPolicy
					ports: [{
						name:          "postgresql"
						containerPort: _config.postgresql.service.port
					}]
					env: [
						{name: "POSTGRES_DB", value: _config.postgresql.auth.database},
						{name: "POSTGRES_USER", value: _config.postgresql.auth.username},
						{
							name: "POSTGRES_PASSWORD"
							valueFrom: secretKeyRef: {
								name: _config.dbSecretName
								key:  _config.dbSecretKey
							}
						},
						for e in _config.postgresql.extraEnv {e},
					]
					if _config.postgresql.standalone.resources != _|_ {
						resources: _config.postgresql.standalone.resources
					}
					securityContext: _config.postgresql.securityContext
					volumeMounts: [
						{
							name:      "data"
							mountPath: "/var/lib/postgresql/data"
						},
						for vm in _config.postgresql.extraVolumeMounts {vm},
					]
				}]
				volumes: [
					for v in _config.postgresql.extraVolumes {v},
				]
			}
		}
		if _config.postgresql.standalone.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: _config.postgresql.standalone.persistence.size
				}
			}]
		}
	}
}

#PostgreSQLServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.fullname)-postgresql"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "database"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "postgresql"
			port:       _config.postgresql.service.port
			targetPort: "postgresql"
		}]
		selector: _config.metadata.labels & {
			"app.kubernetes.io/component": "database"
		}
	}
}

#PostgreSQLHeadlessServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.fullname)-postgresql-primary-headless"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "database"
		}
	}
	spec: {
		clusterIP: "None"
		type:      "ClusterIP"
		ports: [{
			name:       "postgresql"
			port:       _config.postgresql.service.port
			targetPort: "postgresql"
		}]
		selector: _config.metadata.labels & {
			"app.kubernetes.io/component": "database"
		}
	}
}
