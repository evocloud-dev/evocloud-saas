package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#HttpdConfigMap: corev1.#ConfigMap & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "httpd-config"
	}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata:   #meta
	data: {
		"default.conf.template": """
			server {
			  listen 80;
			  server_name localhost;
			  server_tokens off;
			  proxy_connect_timeout 600;
			  proxy_send_timeout 600;
			  proxy_read_timeout 600;
			  send_timeout 600;
			  client_max_body_size 600M;

			  location / {
			    proxy_set_header Host $host;
			    proxy_set_header X-Real-IP $remote_addr;
			    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			    proxy_set_header X-Forwarded-Proto $scheme;
			    proxy_pass http://${NGINX_APPLICATION_HOSTNAME}:8000;
			  }
			}
			"""
	}
}

#HttpdDeployment: appsv1.#Deployment & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "httpd"
	}

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #meta.#LabelSelector
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #meta
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.httpd.replicas
		selector: matchLabels: #meta.#LabelSelector
		template: {
			metadata: {
				labels: #meta.#LabelSelector
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            "httpd"
						image:           #config.images.httpd.reference
						imagePullPolicy: #config.images.httpd.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: 80
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "NGINX_APPLICATION_HOSTNAME"
								value: #config.metadata.name + "-application"
							},
						]
						volumeMounts: [
							{
								name:      "httpd-templates"
								mountPath: "/etc/nginx/templates"
								readOnly:  true
							},
						]
						livenessProbe: {
							tcpSocket: {
								port: "http"
							}
							initialDelaySeconds: 10
							periodSeconds:       10
						}
						readinessProbe: {
							httpGet: {
								path: "/health"
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       5
						}
						resources:       #config.httpd.resources
						if #config.httpd.securityContext != _|_ {
							securityContext: #config.httpd.securityContext
						}
					},
				]
				volumes: [
					{
						name: "httpd-templates"
						configMap: name: #config.metadata.name + "-httpd-config"
					},
				]
				if #config.httpd.podSecurityContext != _|_ {
					securityContext: #config.httpd.podSecurityContext
				}
				if #config.httpd.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				nodeSelector: #config.nodeSelector
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				affinity: _affinity
			}
		}
	}
}

#HttpdService: corev1.#Service & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "httpd"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   #meta
	spec: corev1.#ServiceSpec & {
		type: [
			if #config.httpd.service != _|_ { #config.httpd.service.type },
			corev1.#ServiceTypeClusterIP,
		][0]
		selector: #meta.#LabelSelector
		ports: [
			{
				name:       "http"
				port: [
					if #config.httpd.service != _|_ { #config.httpd.service.port },
					#config.httpd.port,
				][0]
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}