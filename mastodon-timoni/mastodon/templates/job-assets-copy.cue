package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#JobAssetsCopy: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name:   "\(#config.metadata.name)-assets-upload"
		labels: #config.metadata.labels
		annotations: {
			"helm.sh/hook":                "pre-install,pre-upgrade"
			"helm.sh/hook-delete-policy": "before-hook-creation,hook-succeeded"
			"helm.sh/hook-weight":         "-1"
		}
	}
	spec: batchv1.#JobSpec & {
		template: {
			metadata: {
				name: "\(#config.metadata.name)-assets-upload"
				if #config.mastodon.jobLabels != _|_ {
					labels: #config.mastodon.jobLabels
				}
				if #config.mastodon.jobAnnotations != _|_ {
					annotations: #config.mastodon.jobAnnotations
				}
			}
			spec: {
				restartPolicy: "Never"
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				securityContext: #config.podSecurityContext
				volumes: [{
					name: "assets"
					emptyDir: {}
				}]
				initContainers: [{
					name:            "extract-assets"
					securityContext: #config.securityContext
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					command: ["cp"]
					args: ["-rv", "public", "/assets"]
					volumeMounts: [{
						name:      "assets"
						mountPath: "/assets"
					}]
				}]
				containers: [{
					name:            "upload-assets"
					securityContext: #config.securityContext
					image:           "rclone/rclone:1"
					imagePullPolicy: "Always"
					_env: {
						RCLONE_S3_NO_CHECK_BUCKET: value: "true"
						RCLONE_S3_ACL:             value: #config.mastodon.hooks.s3Upload.acl
						RCLONE_CONFIG_REMOTE_TYPE: value: "s3"
						RCLONE_CONFIG_REMOTE_PROVIDER: value: "AWS"
						RCLONE_CONFIG_REMOTE_ENDPOINT: value: #config.mastodon.hooks.s3Upload.endpoint
						RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID: valueFrom: secretKeyRef: {
							name: #config.mastodon.hooks.s3Upload.secretRef.name
							key:  #config.mastodon.hooks.s3Upload.secretRef.keys.accesKeyId
						}
						RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY: valueFrom: secretKeyRef: {
							name: #config.mastodon.hooks.s3Upload.secretRef.name
							key:  #config.mastodon.hooks.s3Upload.secretRef.keys.secretAccessKey
						}
						for k, v in #config.mastodon.hooks.s3Upload.rclone.env {
							"\(k)": value: v
						}
					}
					env: [ for k, v in _env { {name: k, v} }]
					command: ["rclone"]
					args: [
						"copy",
						"/assets/public",
						"remote:\(#config.mastodon.hooks.s3Upload.bucket)",
						"--fast-list",
						"--transfers=32",
						"--include",
						"{assets,packs}/**",
						"--progress",
						"-vv",
					]
					volumeMounts: [{
						name:      "assets"
						mountPath: "/assets"
					}]
					resources: {
						requests: {
							cpu:    "100m"
							memory: "256Mi"
						}
						limits: memory: "500Mi"
					}
				}]
				nodeSelector: #config.mastodon.hooks.s3Upload.nodeSelector
			}
		}
	}
}
