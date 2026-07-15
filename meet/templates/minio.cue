package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	networkingv1 "k8s.io/api/networking/v1"
	batchv1 "k8s.io/api/batch/v1"
)

#MinioService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			name:       "client"
			port:       9000
			targetPort: 9000
			protocol:   "TCP"
		}, {
			name:       "console"
			port:       9001
			targetPort: 9001
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "minio"
		}
		type: "ClusterIP"
	}
}

#MinioIngress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		annotations: {
			"nginx.ingress.kubernetes.io/proxy-body-size": "10m"
			if #config.minio.ingress.className != null {
				"kubernetes.io/ingress.class": #config.minio.ingress.className
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.minio.ingress.className != null {
			ingressClassName: #config.minio.ingress.className
		}
		rules: [{
			host: #config.minio.ingress.host
			http: paths: [{
				path:     "/"
				pathType: "Prefix"
				backend: service: {
					name: "\(#config.metadata.name)-minio"
					port: number: 9000
				}
			}]
		}]
		tls: [{
			hosts: [#config.minio.ingress.host]
			secretName: #config.minio.ingress.secretName
		}]
	}
}

#MinioDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-minio"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "minio"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		selector: matchLabels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "minio"
		}
		replicas: 1
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance": "extra"
				"app.kubernetes.io/name":     "minio"
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: #config.minio.automountServiceAccountToken
				serviceAccountName:           #config.minio.serviceAccountName
				if #config.minio.podSecurityContext != null {
					securityContext: #config.minio.podSecurityContext
				}
				containers: [{
					name: "minio"
					if #config.minio.securityContext != null {
						securityContext: #config.minio.securityContext
					}
					if #config.minio.resources != null {
						resources: #config.minio.resources
					}
					command: [
						"/bin/sh",
						"-c",
						"minio server --console-address :9001 /data",
					]
					env: [{
						name:  "MINIO_ROOT_USER"
						value: "meet"
					}, {
						name:  "MINIO_ROOT_PASSWORD"
						value: "password"
					}]
					image:           #config.minio.image.reference
					imagePullPolicy: "IfNotPresent"
					ports: [{
						containerPort: 9000
						name:          "client"
					}, {
						containerPort: 9001
						name:          "console"
					}]
					volumeMounts: [{
						name:      "data"
						mountPath: "/data"
					}, {
						name:      "mkcert"
						mountPath: "/etc/ssl/certs/mkcert-ca.pem"
						subPath:   "rootCA.pem"
					}]
				}]
				volumes: [{
					name: "data"
					emptyDir: {}
				}, {
					name: "mkcert"
					secret: secretName: #config.minio.caSecretName
				}]
			}
		}
	}
}

#MinioBucketJob: batchv1.#Job & {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-minio-bucket"
		namespace: #config.metadata.namespace
	}
	spec: batchv1.#JobSpec & {
		template: spec: corev1.#PodSpec & {
			containers: [{
				name:  "mc"
				image: #config.minio.mcImage.reference
				command: [
					"/bin/sh",
					"-c",
					"/usr/bin/mc alias set meet http://\(#config.metadata.name)-minio:9000 meet password && (/usr/bin/mc ls meet/meet-media-storage >/dev/null 2>&1 || /usr/bin/mc mb meet/meet-media-storage) && exit 0",
				]
			}]
			restartPolicy: "Never"
		}
		backoffLimit: 3
	}
}

#MinioWebhookJob: batchv1.#Job & {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-minio-webhook"
		namespace: #config.metadata.namespace
	}
	spec: batchv1.#JobSpec & {
		template: spec: corev1.#PodSpec & {
			containers: [{
				name:  "mc"
				image: #config.minio.mcImage.reference
				command: [
					"/bin/sh",
					"-c",
					"/usr/bin/mc alias set meet http://\(#config.metadata.name)-minio:9000 meet password && /usr/bin/mc admin config set meet notify_webhook:meet-webhook endpoint=\"https://\(#config.ingress.host)/api/v1.0/recordings/storage-hook/\" auth_token=\"Bearer password\" && /usr/bin/mc admin service restart meet --wait --json && sleep 15 && (/usr/bin/mc event add meet/meet-media-storage arn:minio:sqs::meet-webhook:webhook --event put --prefix \"recordings\" || true) && exit 0",
				]
			}]
			restartPolicy: "Never"
		}
		backoffLimit: 3
	}
}

#MinioCaSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.minio.caSecretName
		namespace: #config.metadata.namespace
	}
	type: "Opaque"
	stringData: {
		"rootCA.pem": #config.minio.caCert
	}
}
