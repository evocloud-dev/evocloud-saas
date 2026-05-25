package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	"encoding/base64"
)

#MinioSecret: {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "minio"
		}
	}
	type: "Opaque"
	data: {
		"root-user":     base64.Encode(null, #config.minio.auth.rootUser)
		"root-password": base64.Encode(null, #config.minio.auth.rootPassword)
	}
}

#MinioPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "minio"
		}
	}
	spec: {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.minio.persistence.size
	}
}

#MinioService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "minio"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [
			{
				name:       "minio-api"
				port:       9000
				targetPort: 9000
				protocol:   "TCP"
			},
			{
				name:       "minio-console"
				port:       9001
				targetPort: 9001
				protocol:   "TCP"
			}
		]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "minio"
		}
	}
}

#MinioDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "minio"
		}
	}
	spec: {
		strategy: type: "Recreate"
		selector: matchLabels: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "minio"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "minio"
			}
			spec: {
				automountServiceAccountToken: false
				securityContext: {
					fsGroup:             1001
					fsGroupChangePolicy: "OnRootMismatch"
				}
				initContainers: [
					{
						name:            "volume-permissions"
						image:           "docker.io/bitnamilegacy/os-shell:12-debian-12-r43"
						imagePullPolicy: "IfNotPresent"
						command: [
							"/bin/bash",
							"-ec",
							"chown -R 1001:1001 /bitnami/minio/data"
						]
						securityContext: {
							runAsUser: 0
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/bitnami/minio/data"
							}
						]
					}
				]
				containers: [{
					name:            "minio"
					image:           #config._minioImageRef
					imagePullPolicy: #config.minio.image.pullPolicy
					securityContext: {
						allowPrivilegeEscalation: false
						runAsUser:                1001
						runAsGroup:               1001
						runAsNonRoot:            true
						readOnlyRootFilesystem:  true
						capabilities: drop: ["ALL"]
						seccompProfile: type: "RuntimeDefault"
					}
					env: [
						{
							name:  "BITNAMI_DEBUG"
							value: "false"
						},
						{
							name:  "MINIO_SCHEME"
							value: "http"
						},
						{
							name:  "MINIO_FORCE_NEW_KEYS"
							value: "no"
						},
						{
							name:  "MINIO_API_PORT_NUMBER"
							value: "9000"
						},
						{
							name: "MINIO_ROOT_USER"
							valueFrom: secretKeyRef: {
								name: #config._minioSecretName
								key:  "root-user"
							}
						},
						{
							name: "MINIO_ROOT_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config._minioSecretName
								key:  "root-password"
							}
						},
						{
							name:  "MINIO_DEFAULT_BUCKETS"
							value: "zammad"
						},
						{
							name:  "MINIO_BROWSER"
							value: "off"
						},
						{
							name:  "MINIO_CONSOLE_PORT_NUMBER"
							value: "9001"
						},
						{
							name:  "MINIO_DATA_DIR"
							value: "/bitnami/minio/data"
						}
					]
					ports: [
						{
							name:          "minio-api"
							containerPort: 9000
							protocol:      "TCP"
						},
						{
							name:          "minio-console"
							containerPort: 9001
							protocol:      "TCP"
						}
					]
					livenessProbe: {
						httpGet: {
							path:   "/minio/health/live"
							port:   "minio-api"
							scheme: "HTTP"
						}
						initialDelaySeconds: 5
						periodSeconds:       5
						timeoutSeconds:      5
						successThreshold:    1
						failureThreshold:    5
					}
					readinessProbe: {
						tcpSocket: port: "minio-api"
						initialDelaySeconds: 5
						periodSeconds:       5
						timeoutSeconds:      1
						successThreshold:    1
						failureThreshold:    5
					}
					volumeMounts: [
						{
							name:      "empty-dir"
							mountPath: "/tmp"
							subPath:   "tmp-dir"
						},
						{
							name:      "empty-dir"
							mountPath: "/opt/bitnami/minio/tmp"
							subPath:   "app-tmp-dir"
						},
						{
							name:      "empty-dir"
							mountPath: "/.mc"
							subPath:   "app-mc-dir"
						},
						{
							name:      "data"
							mountPath: "/bitnami/minio/data"
						}
					]
				}]
				volumes: [
					{
						name: "empty-dir"
						emptyDir: {}
					},
					{
						name: "data"
						if #config.minio.persistence.enabled {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-minio"
						}
						if !#config.minio.persistence.enabled {
							emptyDir: {}
						}
					}
				]
			}
		}
	}
}
