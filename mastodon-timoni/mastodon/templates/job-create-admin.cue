package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#JobCreateAdmin: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-create-admin"
		labels: #config.metadata.labels
		annotations: {
			"helm.sh/hook":                "post-install"
			"helm.sh/hook-delete-policy": "before-hook-creation,hook-succeeded"
			"helm.sh/hook-weight":         "-1"
		}
	}
	spec: batchv1.#JobSpec & {
		template: {
			metadata: {
				name: "\(#config.metadata.name)-create-admin"
				if #config.mastodon.jobLabels != _|_ {
					labels: #config.mastodon.jobLabels
				}
				if #config.mastodon.jobAnnotations != _|_ {
					annotations: #config.mastodon.jobAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				restartPolicy: "Never"
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				securityContext: #config.podSecurityContext

				if !#config.mastodon.s3.enabled && (#config.mastodon.persistence.assets.accessMode == "ReadWriteOnce" || #config.mastodon.persistence.system.accessMode == "ReadWriteOnce") {
					affinity: podAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
						labelSelector: matchExpressions: [{
							key:      "app.kubernetes.io/part-of"
							operator: "In"
							values: ["rails"]
						}]
						topologyKey: "kubernetes.io/hostname"
					}]
				}

				if !#config.mastodon.s3.enabled {
					volumes: [
						{
							name: "assets"
							persistentVolumeClaim: claimName: {
								if #config.mastodon.persistence.assets.existingClaim != "" {
									#config.mastodon.persistence.assets.existingClaim
								}
								if #config.mastodon.persistence.assets.existingClaim == "" {
									"\(#config.metadata.name)-assets"
								}
							}
						},
						{
							name: "system"
							persistentVolumeClaim: claimName: {
								if #config.mastodon.persistence.system.existingClaim != "" {
									#config.mastodon.persistence.system.existingClaim
								}
								if #config.mastodon.persistence.system.existingClaim == "" {
									"\(#config.metadata.name)-system"
								}
							}
						},
					]
				}

				containers: [{
					name:            "create-admin"
					securityContext: #config.securityContext
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					command: [
						"bin/tootctl",
						"accounts",
						"create",
						#config.mastodon.createAdmin.username,
						"--email",
						#config.mastodon.createAdmin.email,
						"--confirmed",
						"--role",
						"Owner",
						"--approve",
					]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-env"},
						{
							secretRef: name: {
								if #config.mastodon.secrets.existingSecret != "" {
									#config.mastodon.secrets.existingSecret
								}
								if #config.mastodon.secrets.existingSecret == "" {
									#config.metadata.name
								}
							}
						},
					]
					_env: {
						DB_PASS: valueFrom: secretKeyRef: {
							name: {
								if #config.postgresql.auth.existingSecret != "" {
									#config.postgresql.auth.existingSecret
								}
								if #config.postgresql.auth.existingSecret == "" {
									"\(#config.metadata.name)-postgresql"
								}
							}
							key: "password"
						}
						REDIS_PASSWORD: valueFrom: secretKeyRef: {
							name: {
								if #config.redis.auth.existingSecret != "" {
									#config.redis.auth.existingSecret
								}
								if #config.redis.auth.existingSecret == "" {
									"\(#config.metadata.name)-redis"
								}
							}
							key: #config.redis.auth.existingSecretKey
						}
						if #config.redis.sidekiq.enabled && #config.redis.sidekiq.auth.existingSecret != "" {
							SIDEKIQ_REDIS_PASSWORD: valueFrom: secretKeyRef: {
								name: #config.redis.sidekiq.auth.existingSecret
								key:  #config.redis.sidekiq.auth.existingSecretKey
							}
						}
						if #config.redis.cache.enabled && #config.redis.cache.auth.existingSecret != "" {
							CACHE_REDIS_PASSWORD: valueFrom: secretKeyRef: {
								name: #config.redis.cache.auth.existingSecret
								key:  #config.redis.cache.auth.existingSecretKey
							}
						}
						PORT: value: "\(#config.mastodon.web.port)"
					}
					env: [ for k, v in _env { {name: k, v} }]
					if !#config.mastodon.s3.enabled {
						volumeMounts: [
							{
								name:      "assets"
								mountPath: "/opt/mastodon/public/assets"
							},
							{
								name:      "system"
								mountPath: "/opt/mastodon/public/system"
							},
						]
					}
				}]
				nodeSelector: #config.mastodon.createAdmin.nodeSelector
			}
		}
	}
}
