package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
)

#MigrationJob: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-migration"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#JobSpec & {
		template: spec: corev1.#PodSpec & {
			restartPolicy: "OnFailure"
			containers: [{
				name:            "migration"
				image:           "\(#config.global.image.repository):\(#config.global.image.tag)"
				imagePullPolicy: #config.global.image.pullPolicy
				command: ["python", "manage.py", "migrate"]
				env: list.Concat([
					#config.migrations.extraEnv,
					[
						{name: "DATABASE_URL", valueFrom: secretKeyRef: {name: "\(#config.metadata.name)-secrets", key: "database-url"}},
						{name: "REDIS_URL", valueFrom: secretKeyRef: {name: "\(#config.metadata.name)-secrets", key: "redis-url"}},
						{name: "SECRET_KEY", valueFrom: secretKeyRef: {name: "\(#config.metadata.name)-secrets", key: "secret-key"}},
						{name: "PYTHONPATH", value: "/app/saleor/saleor/settings.py"},
					],
				])
				volumeMounts: [{
					name:      "settings"
					mountPath: "/app/saleor/saleor/settings.py"
					subPath:   "settings.py"
				}]
				resources: #config.migrations.resources
			}]
			volumes: [{
				name: "settings"
				configMap: name: "\(#config.metadata.name)-settings"
			}]
			if #config.migrations.nodeSelector != _|_ {
				nodeSelector: #config.migrations.nodeSelector
			}
			if #config.migrations.tolerations != _|_ {
				tolerations: #config.migrations.tolerations
			}
			if #config.migrations.affinity != _|_ {
				affinity: #config.migrations.affinity
			}
		}
	}
}
