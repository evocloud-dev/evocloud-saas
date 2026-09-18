package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#NginxDenyConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-nginxdeny"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	data: "nginx.conf": """
		events { }
		http {
		    server {
		        listen 80 default_server;
		        location / {
		            return 403;
		        }
		    }
		}
		"""
}

#NginxDenyService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-nginxdeny"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			port:       #config.nginxDeny.service.port
			targetPort: #config.nginxDeny.containerPort
			protocol:   "TCP"
			name:       "http"
		}]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-nginxdeny"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		type: "ClusterIP"
	}
}

#NginxDenyDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-nginxdeny"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.nginxDeny.replicaCount
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-nginxdeny"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-nginxdeny"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				containers: [{
					name:            "nginx-deny"
					image:           "\(#config.nginxDeny.image.repository):\(#config.nginxDeny.image.tag)"
					imagePullPolicy: #config.nginxDeny.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.nginxDeny.containerPort
						protocol:      "TCP"
					}]
					volumeMounts: [{
						name:      "config"
						mountPath: "/etc/nginx/nginx.conf"
						subPath:   "nginx.conf"
					}]
				}]
				volumes: [{
					name: "config"
					configMap: name: "\(#config.metadata.name)-nginxdeny"
				}]
			}
		}
	}
}

#NginxDenyIngress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-nginxdeny"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.nginxDeny.ingress.annotations != _|_ {
			annotations: #config.nginxDeny.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.nginxDeny.ingress.className != "" {
			ingressClassName: #config.nginxDeny.ingress.className
		}
		if #config.nginxDeny.ingress.tls != _|_ {
			tls: #config.nginxDeny.ingress.tls
		}
		if #config.nginxDeny.ingress.hosts != _|_ {
			rules: [
				for h in #config.nginxDeny.ingress.hosts {
					host: h.host
					http: paths: [
						for p in h.paths {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: "\(#config.metadata.name)-nginxdeny"
								port: number: #config.nginxDeny.service.port
							}
						},
					]
				},
			]
		}
	}
}

