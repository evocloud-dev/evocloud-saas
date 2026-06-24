package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLExtensionsJob: batchv1.#Job & {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.fullname)-pg-extensions"
		namespace: #config.namespace
		labels:    #config.labels
		annotations: {
			"helm.sh/hook":               "pre-upgrade"
			"helm.sh/hook-weight":        "1"
			"helm.sh/hook-delete-policy": "hook-succeeded"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit:          #config.postgresqlExtensionsJob.backoffLimit
		activeDeadlineSeconds: #config.postgresqlExtensionsJob.activeDeadlineSeconds
		template: {
			metadata: {
				if #config.postgresqlExtensionsJob.podAnnotations != _|_ && len(#config.postgresqlExtensionsJob.podAnnotations) > 0 {
					annotations: #config.postgresqlExtensionsJob.podAnnotations
				}
				labels: #config.selectorLabels
			}
			spec: corev1.#PodSpec & {
				restartPolicy:      "OnFailure"
				serviceAccountName: #config.serviceAccountName
				securityContext:    #config.postgresqlExtensionsJob.podSecurityContext
				containers: [
					{
						name:            "pg-extensions"
						image:           "\(#config.postgresqlExtensionsJob.image.repository):\(#config.postgresqlExtensionsJob.image.tag)"
						imagePullPolicy: #config.postgresqlExtensionsJob.image.pullPolicy
						command: [
							"sh",
							"-ec",
							"psql -v ON_ERROR_STOP=1 -c \"CREATE EXTENSION IF NOT EXISTS pg_trgm;\"\n",
						]
						env: [
							{
								name:  "PGHOST"
								value: #config.databaseHost
							},
							{
								name:  "PGPORT"
								value: "\(#config.databasePort)"
							},
							{
								name:  "PGDATABASE"
								value: #config.databaseName
							},
							{
								name:  "PGUSER"
								value: #config.postgresql.auth.username
							},
							{
								name: "PGPASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.postgresqlSecretName
									key:  [if #config.postgresql.auth.existingSecretUserPasswordKey != _|_ && #config.postgresql.auth.existingSecretUserPasswordKey != "" { #config.postgresql.auth.existingSecretUserPasswordKey }, "user-password"][0]
								}
							},
						]
						securityContext: #config.postgresqlExtensionsJob.securityContext
						resources:       #config.postgresqlExtensionsJob.resources
					},
				]
			}
		}
	}
}
