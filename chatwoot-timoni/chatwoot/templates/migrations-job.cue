package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#MigrationJob: {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-migrate"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
			"helm.sh/hook":                #config.hooks.migrate.hookAnnotation
			"helm.sh/hook-delete-policy": "hook-succeeded,before-hook-creation"
			"helm.sh/hook-weight":        "-1"
		}
	}
	spec: batchv1.#JobSpec & {
		template: spec: corev1.#PodSpec & {
			if #config.imagePullSecrets != _|_ {
				imagePullSecrets: #config.imagePullSecrets
			}
			restartPolicy: "Never"
			if #config.tolerations != _|_ {
				tolerations: #config.tolerations
			}
			if #config.nodeSelector != _|_ {
				nodeSelector: #config.nodeSelector
			}
			initContainers: [
				{
					name:            "init-postgres"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					command: ["/bin/sh"]
					args: ["-c", "until pg_isready -h \(#config.#postgresql.host) -p \(#config.#postgresql.port); do sleep 2; done; echo 'Database ready to accept connections.';"]
				},
				{
					name:            "init-redis"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					command: ["sh", "-c", "until getent hosts \(#config.#redis.host) ; do echo waiting for \(#config.#redis.host) ; sleep 2; done;"]
				},
			]
			containers: [{
				name:  "db-migrate-job"
				image: "\(#config.image.repository):\(#config.image.tag)"
				args: [
					"bundle",
					"exec",
					"rails",
					"db:chatwoot_prepare",
				]
				env: [
					if #config.postgresql.auth.existingSecret != _|_ {
						{
							name: "POSTGRES_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.postgresql.auth.existingSecret
								key:  "password"
							}
						}
					},
					if #config.redis.auth.existingSecret != _|_ {
						{
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.redis.auth.existingSecret
								key:  "password"
							}
						}
					},
				]
				envFrom: [
					{
						secretRef: name: "\(#config.metadata.name)-env"
					},
					if #config.existingEnvSecret != "" {
						{
							secretRef: name: #config.existingEnvSecret
						}
					},
				]
				imagePullPolicy: #config.image.pullPolicy
				volumeMounts: [{
					name:      "cache"
					mountPath: "/app/tmp"
				}]
			}]
			serviceAccountName: #config.metadata.name
			if #config.podSecurityContext != _|_ {
				securityContext: #config.podSecurityContext
			}
			volumes: [{
				name: "cache"
				emptyDir: {}
			}]
			if #config.affinity != _|_ {
				affinity: #config.affinity
			}
		}
	}
}
