package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	batchv1 "k8s.io/api/batch/v1"
)

#MinioService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-minio"
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.minio.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "minio-9000"
			port:       9000
			protocol:   "TCP"
			targetPort: 9000
		}, {
			name:       "minio-9001"
			port:       9001
			protocol:   "TCP"
			targetPort: 9001
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-minio"
		}
	}
}

#MinioStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-minio"
	}
	spec: {
		serviceName: "\(#config.metadata.name)-minio"
		replicas:    #config.services.minio.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-minio"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-minio"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.minio }}
				nodeSelector: #config.services.minio.nodeSelector
				tolerations:  #config.services.minio.tolerations
				affinity:     #config.services.minio.affinity

				containers: [{
					name:            "\(#config.metadata.name)-minio"
					image:           #config.services.minio.image
					imagePullPolicy: "IfNotPresent"
					args: ["server", "/data", "--console-address", ":9001"]
					ports: [{
						containerPort: 9000
						name:          "minio-9000"
					}, {
						containerPort: 9001
						name:          "minio-9001"
					}]
					env: [{
						name:  "MINIO_ROOT_USER"
						value: #config.services.minio.root_user
					}, {
						name:  "MINIO_ROOT_PASSWORD"
						value: #config.services.minio.root_password
					}]
					volumeMounts: [{
						name:      "minio-data"
						mountPath: "/data"
					}]
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "minio-data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				storageClassName: #config.env.storageClass
				resources: requests: storage: #config.services.minio.volumeSize
			}
		}]
	}
}

#MinioBucketJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-minio-bucket-create"
	}
	spec: {
		backoffLimit:   6
		completionMode: "NonIndexed"
		template: {
			spec: {
				// {{- include "plane.podScheduling" .Values.services.minio }}
				nodeSelector: #config.services.minio.nodeSelector
				tolerations:  #config.services.minio.tolerations
				affinity:     #config.services.minio.affinity

				restartPolicy: "OnFailure"
				initContainers: [{
					name:  "init"
					image: "busybox"
					command: ["sh", "-c", "until nslookup \((#config.metadata.name))-minio.\((#config.#namespace)).svc.cluster.local; do echo waiting for \((#config.metadata.name))-minio; sleep 2; done"]
				}]
				containers: [{
					name:            "\(#config.metadata.name)-minio-bucket"
					image:           #config.services.minio.image_mc
					imagePullPolicy: "Always"
					command:         ["/bin/sh"]
					args: [
						"-c",
						"/usr/bin/mc config host add plane-app-minio http://\(#config.metadata.name)-minio.\(#config.#namespace).svc.cluster.local:9000 \"$AWS_ACCESS_KEY_ID\" \"$AWS_SECRET_ACCESS_KEY\"; /usr/bin/mc mb plane-app-minio/$AWS_S3_BUCKET_NAME; /usr/bin/mc anonymous set download plane-app-minio/$AWS_S3_BUCKET_NAME; exit 0;",
					]
					envFrom: [{
						secretRef: {
							name:     "\(#config.metadata.name)-doc-store-secrets"
							optional: false
						}
					}]
					if #config.extraEnv != [] {
						env: [
							for e in #config.extraEnv {e},
						]
					}
				}]
				serviceAccount:                "\(#config.metadata.name)-srv-account"
				serviceAccountName:            "\(#config.metadata.name)-srv-account"
				terminationGracePeriodSeconds: 120
			}
		}
	}
}
