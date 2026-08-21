package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#NginxDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#nginxServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "nginx"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.nginx.replicaCount
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "nginx"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "nginx"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.create
				securityContext:              #config.nginx.podSecurityContext
				if !#config.persistence.appPublic.enabled {
					initContainers: [{
						name:            "seed-public-dir"
						image:           "\(#config.app.image.repository):\(#config.app.image.tag)"
						imagePullPolicy: #config.app.image.pullPolicy
						securityContext: #config.nginx.initSecurityContext
						command: [
							"/bin/sh",
							"-c",
							"""
								mkdir -p /var/www/html/public
								cp -r /tmp/public/. /var/www/html/public/ 2>/dev/null || true
								""",
						]
						volumeMounts: [{
							name:      "app-public"
							mountPath: "/var/www/html/public"
						}]
					}]
				}
				containers: [{
					name:            "nginx"
					image:           "\(#config.nginx.image.repository):\(#config.nginx.image.tag)"
					imagePullPolicy: #config.nginx.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.nginx.containerPort
						protocol:      "TCP"
					}]
					livenessProbe: {
						tcpSocket: port: "http"
						initialDelaySeconds: 20
						periodSeconds:       20
					}
					readinessProbe: {
						tcpSocket: port: "http"
						initialDelaySeconds: 10
						periodSeconds:       10
					}
					resources:       #config.nginx.resources
					securityContext: #config.nginx.securityContext
					volumeMounts: [
						{
							name:      "app-public"
							mountPath: "/var/www/html/public"
							readOnly:  true
						},
						{
							name:      "app-storage"
							mountPath: "/var/www/html/storage"
							readOnly:  true
						},
						{
							name:      "nginx-config"
							mountPath: "/etc/nginx/conf.d"
							readOnly:  true
						},
					]
				}]
				volumes: [
					{
						name: "app-public"
						if #config.persistence.appPublic.enabled {
							persistentVolumeClaim: claimName: "\(#config.#fullname)-app-public"
						}
						if !#config.persistence.appPublic.enabled {
							emptyDir: {}
						}
					},
					{
						name: "app-storage"
						if #config.persistence.appStorage.enabled {
							persistentVolumeClaim: claimName: "\(#config.#fullname)-app-storage"
						}
						if !#config.persistence.appStorage.enabled {
							emptyDir: {}
						}
					},
					{
						name: "nginx-config"
						configMap: name: #config.#nginxServiceName
					},
				]
			}
		}
	}
}

#NginxService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#nginxServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "nginx"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.nginx.service.type
		ports: [{
			name:       "http"
			port:       #config.nginx.service.port
			targetPort: "http"
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "nginx"
		}
	}
}
