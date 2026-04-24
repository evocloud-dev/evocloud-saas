package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-redis"
	}
	spec: {
		type:      "ClusterIP"
		if !#config.services.redis.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "redis-6379"
			port:       6379
			protocol:   "TCP"
			targetPort: 6379
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-redis"
		}
	}
}

#RedisDeployment: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-redis-wl"
	}
	spec: {
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-redis"
		}
		serviceName: "\(#config.metadata.name)-redis"
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-redis"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-redis"
					image:           #config.services.redis.image
					imagePullPolicy: "IfNotPresent"
					stdin:           true
					tty:             true
					if #config.extraEnv != [] {
						env: #config.extraEnv
					}
					volumeMounts: [{
						name:      "pvc-\(#config.metadata.name)-redis-vol"
						mountPath: "/data"
						subPath:   ""
					}]
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "pvc-\(#config.metadata.name)-redis-vol"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: #config.services.redis.volumeSize
				storageClassName: #config.env.storageClass
				volumeMode:       "Filesystem"
			}
		}]
	}
}
