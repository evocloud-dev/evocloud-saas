package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#JobInit: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#helpers.fullname)-init"
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: batchv1.#JobSpec & {
		ttlSecondsAfterFinished: 300
		activeDeadlineSeconds:   600
		backoffLimit:            2
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      #helpers.name
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "init"
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				restartPolicy: "OnFailure"
				securityContext: #config.podSecurityContext
				initContainers: [{
					name:            "db-check"
					image:           "\(#config.postgres.image.repository):\(#config.postgres.image.tag)"
					imagePullPolicy: "IfNotPresent"
					command: [
						"/bin/sh",
						"-c",
						"""
							set -e
							# Wait for database to be ready
							until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"; do
							  echo "Waiting for database..."
							  sleep 2
							done

							# Skip init if database already has tables (idempotent - never overwrite existing data)
							if psql -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" | grep -qv "^0$"; then
							  echo "Database already has tables, skipping init"
							  echo "skip" > /shared/skip
							fi
							""",
					]
					env: [{
						name:  "PGHOST"
						value: #config.database.host
					}, {
						name:  "PGPORT"
						value: "\(#config.database.port)"
					}, {
						name:  "PGUSER"
						value: #config.database.user
					}, {
						name:  "PGDATABASE"
						value: #config.database.name
					}, {
						name: "PGPASSWORD"
						valueFrom: secretKeyRef: {
							name: #helpers.dbSecretName
							key:  #config.database.passwordKey
						}
					}]
					securityContext: #config.securityContext
					volumeMounts: [{
						name:      "init-flag"
						mountPath: "/shared"
					}, if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
						{
							name:      "tmp"
							mountPath: "/tmp"
						}
					}]
				}]
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				containers: [{
					name:            "listmonk-init"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					securityContext: #config.securityContext
					volumeMounts: [{
						name:      "listmonk-config"
						mountPath: "/listmonk/config.toml"
						subPath:   "config.toml"
					}, if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
						{
							name:      "tmp"
							mountPath: "/tmp"
						}
					}]
					command: [
						"/bin/sh",
						"-c",
						"""
							if [ -f /shared/skip ]; then
							  echo "DB already initialized, skipping install"
							  exit 0
							fi
							exec /listmonk/listmonk --install --yes
							""",
					]
					env: [{
						name:  "LISTMONK_ADMIN_USER"
						value: #config.admin.username
					}, {
						name:  "LISTMONK_ADMIN_PASSWORD"
						value: #config.admin.password
					}, {
						name:  "LISTMONK_app__address"
						value: #config.app.address
					}, {
						name:  "LISTMONK_app__lang"
						value: #config.app.lang
					}, {
						name:  "LISTMONK_db__host"
						value: #config.database.host
					}, {
						name:  "LISTMONK_db__port"
						value: "\(#config.database.port)"
					}, {
						name:  "LISTMONK_db__user"
						value: #config.database.user
					}, {
						name:  "LISTMONK_db__database"
						value: #config.database.name
					}, {
						name:  "LISTMONK_db__ssl_mode"
						value: #config.database.sslMode
					}, {
						name:  "LISTMONK_db__max_open"
						value: "\(#config.database.maxOpen)"
					}, {
						name:  "LISTMONK_db__max_idle"
						value: "\(#config.database.maxIdle)"
					}, {
						name:  "LISTMONK_db__max_lifetime"
						value: #config.database.maxLifetime
					}, {
						name: "LISTMONK_db__password"
						valueFrom: secretKeyRef: {
							name: #helpers.dbSecretName
							key:  #config.database.passwordKey
						}
					}]
				}]
				volumes: [{
					name: "init-flag"
					emptyDir: {}
				}, {
					name: "listmonk-config"
					configMap: {
						name: #helpers.fullname
						items: [{
							key:  "config.toml"
							path: "config.toml"
						}]
					}
				}, if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
					{
						name: "tmp"
						emptyDir: {}
					}
				}]
			}
		}
	}
}
