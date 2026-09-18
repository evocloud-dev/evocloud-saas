package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

// #ReverseProxyServiceAccount mirrors upstream reverse-proxy/rbac.yaml ServiceAccount
#ReverseProxyServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

// #ReverseProxyRole mirrors upstream reverse-proxy/rbac.yaml Role
#ReverseProxyRole: rbacv1.#Role & {
	#config: #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	rules: [
		{
			apiGroups: ["discovery.k8s.io"]
			resources: ["endpointslices"]
			verbs: ["get", "list", "watch"]
		},
	]
}

// #ReverseProxyRoleBinding mirrors upstream reverse-proxy/rbac.yaml RoleBinding
#ReverseProxyRoleBinding: rbacv1.#RoleBinding & {
	#config: #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(#config.metadata.name)-reverseproxy"
	}
	subjects: [
		{
			kind:      "ServiceAccount"
			name:      "\(#config.metadata.name)-reverseproxy"
			namespace: #config.metadata.namespace
		},
	]
}

// #ReverseProxyConfigMap mirrors upstream reverse-proxy/configmap.yaml
#ReverseProxyConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	data: "nginx.conf": {
		if #config.reverseProxy.nginxConfigOverride != _|_ && #config.reverseProxy.nginxConfigOverride != "" {
			#config.reverseProxy.nginxConfigOverride
		}
		if #config.reverseProxy.nginxConfigOverride == _|_ || #config.reverseProxy.nginxConfigOverride == "" {
			"""
			worker_processes auto;
			pid /run/nginx/nginx.pid;

			events {
			    worker_connections 1024;
			}

			http {
			    client_body_temp_path /tmp/client_temp;
			    proxy_temp_path       /tmp/proxy_temp;
			    fastcgi_temp_path     /tmp/fastcgi_temp;
			    uwsgi_temp_path       /tmp/uwsgi_temp;
			    scgi_temp_path        /tmp/scgi_temp;

			    access_log /dev/stdout;
			    error_log  /dev/stderr;

			    # Send "Connection: upgrade" only for real WebSocket requests. Plain
			    # HTTP requests get "Connection: close", otherwise Collabora holds the
			    # connection open waiting for a WebSocket upgrade that never arrives.
			    map $http_upgrade $connection_upgrade {
			        default upgrade;
			        ''      close;
			    }

			    upstream coolwsd {
			        zone coolwsd 64k;
			        hash $arg_\(#config.reverseProxy.hashParam);
			        server \(#config.metadata.name)-reverseproxy-headless.\(#config.metadata.namespace).svc.cluster.local:\(#config.reverseProxy.upstreamPort);
			    }
			\(#_controllerUpstream)
			    server {
			        listen \(#config.reverseProxy.containerPort);
			        server_name _;

			        location = /nginx-health {
			            return 200 "ok\\n";
			        }
			\(#_controllerLocation)
			        location / {
			            proxy_pass               http://coolwsd;
			            proxy_http_version       1.1;
			            proxy_set_header         Host $host;
			            proxy_set_header         Upgrade $http_upgrade;
			            proxy_set_header         Connection $connection_upgrade;
			            client_max_body_size     0;
			            proxy_read_timeout       \(#config.reverseProxy.proxyTimeout);
			            proxy_send_timeout       \(#config.reverseProxy.proxyTimeout);
			        }
			    }
			}
			"""
		}
	}

	#_controllerUpstream: {
		if #config.reverseProxy.controller.enabled {
			"""
			    upstream controller {
			        server \(#config.reverseProxy.controller.upstream);
			    }
			"""
		}
		if !#config.reverseProxy.controller.enabled {
			""
		}
	}

	#_controllerLocation: {
		if #config.reverseProxy.controller.enabled {
			"""
			        location ~* ^/controller(/|$) {
			            proxy_pass               http://controller;
			            proxy_http_version       1.1;
			            proxy_set_header         Host $host;
			            proxy_set_header         Upgrade $http_upgrade;
			            proxy_set_header         Connection $connection_upgrade;
			            client_max_body_size     0;
			            proxy_read_timeout       \(#config.reverseProxy.proxyTimeout);
			            proxy_send_timeout       \(#config.reverseProxy.proxyTimeout);
			        }
			"""
		}
		if !#config.reverseProxy.controller.enabled {
			""
		}
	}
}

// #ReverseProxyService mirrors upstream reverse-proxy/service.yaml
#ReverseProxyService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.reverseProxy.service.type
		ports: [{
			port:       #config.reverseProxy.service.port
			targetPort: "http"
			protocol:   "TCP"
			name:       "http"
		}]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

// #ReverseProxyHeadlessService mirrors upstream reverse-proxy/headless-service.yaml
#ReverseProxyHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [{
			port:       #config.reverseProxy.upstreamPort
			targetPort: "http"
			protocol:   "TCP"
			name:       "http"
		}]
		selector: #config.selector.labels & {
			type: "main"
		}
	}
}

// #ReverseProxyDeployment mirrors upstream reverse-proxy/deployment.yaml
#ReverseProxyDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.reverseProxy.replicaCount
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
					"app.kubernetes.io/instance": #config.metadata.name
				}
				if #config.reverseProxy.podAnnotations != _|_ {
					annotations: #config.reverseProxy.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.reverseProxy.endpointReloader.enabled {
					serviceAccountName:    "\(#config.metadata.name)-reverseproxy"
					shareProcessNamespace: true
				}
				securityContext: #config.reverseProxy.podSecurityContext
				containers: [
					{
						name:            "\(#config.metadata.name)-reverseproxy"
						securityContext: #config.reverseProxy.securityContext
						image:           "\(#config.reverseProxy.image.repository):\(#config.reverseProxy.image.tag)"
						imagePullPolicy: #config.reverseProxy.image.pullPolicy
						ports: [{
							name:          "http"
							containerPort: #config.reverseProxy.containerPort
							protocol:      "TCP"
						}]
						readinessProbe: {
							httpGet: {
								path: "/nginx-health"
								port: #config.reverseProxy.containerPort
							}
							initialDelaySeconds: 3
							periodSeconds:       10
						}
						livenessProbe: {
							httpGet: {
								path: "/nginx-health"
								port: #config.reverseProxy.containerPort
							}
							initialDelaySeconds: 5
							periodSeconds:       20
						}
						if #config.reverseProxy.resources != _|_ {
							resources: #config.reverseProxy.resources
						}
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/etc/nginx/nginx.conf"
								subPath:   "nginx.conf"
								readOnly:  true
							},
							{
								name:      "nginx-run"
								mountPath: "/run/nginx"
							},
						]
					},
					if #config.reverseProxy.endpointReloader.enabled {
						name:            "reloader"
						securityContext: #config.reverseProxy.securityContext
						image:           "\(#config.reverseProxy.endpointReloader.image.repository):\(#config.reverseProxy.endpointReloader.image.tag)"
						imagePullPolicy: #config.reverseProxy.endpointReloader.image.pullPolicy
						env: [{
							name:  "HOME"
							value: "/tmp"
						}]
						command: ["/bin/sh", "-c"]
						args: [
							"""
							set -u
							echo "reloader: waiting for nginx pid file"
							while [ ! -s /run/nginx/nginx.pid ]; do sleep 1; done
							echo "reloader: watching EndpointSlices for \(#config.metadata.name)-reverseproxy-headless"
							while true; do
							  kubectl get endpointslices -n \(#config.metadata.namespace) \\
							    -l kubernetes.io/service-name=\(#config.metadata.name)-reverseproxy-headless \\
							    --watch -o name 2>&1 | while read -r ev; do
							      sleep 2
							      pid=\"$(cat /run/nginx/nginx.pid 2>/dev/null || echo '')\"
							      if [ -n \"$pid\" ]; then
							        echo \"reloader: COOL endpoints changed ($ev), reloading nginx (pid $pid)\"
							        kill -HUP \"$pid\" 2>/dev/null || echo \"reloader: HUP failed\"
							      fi
							    done
							  echo \"reloader: watch dropped, reconnecting in 3s\"
							  sleep 3
							done
							""",
						]
						volumeMounts: [{
							name:      "nginx-run"
							mountPath: "/run/nginx"
						}]
					},
				]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.metadata.name)-reverseproxy"
					},
					{
						name: "nginx-run"
						emptyDir: {}
					},
				]
				if #config.reverseProxy.nodeSelector != _|_ {
					nodeSelector: #config.reverseProxy.nodeSelector
				}
				if #config.reverseProxy.affinity != _|_ {
					affinity: #config.reverseProxy.affinity
				}
				if #config.reverseProxy.tolerations != _|_ {
					tolerations: #config.reverseProxy.tolerations
				}
			}
		}
	}
}

// #ReverseProxyIngress mirrors upstream reverse-proxy/ingress.yaml
#ReverseProxyIngress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.reverseProxy.ingress.annotations != _|_ {
			annotations: #config.reverseProxy.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.reverseProxy.ingress.className != _|_ {
			ingressClassName: #config.reverseProxy.ingress.className
		}
		if #config.reverseProxy.ingress.tls != _|_ {
			tls: #config.reverseProxy.ingress.tls
		}
		if #config.reverseProxy.ingress.hosts != _|_ {
			rules: [
				for h in #config.reverseProxy.ingress.hosts {
					host: h.host
					http: paths: [
						for p in h.paths {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: "\(#config.metadata.name)-reverseproxy"
								port: number: #config.reverseProxy.service.port
							}
						},
					]
				},
			]
		}
	}
}

// #ReverseProxyRoute mirrors upstream reverse-proxy/route.yaml
#ReverseProxyRoute: {
	#config: #Config
	apiVersion: "route.openshift.io/v1"
	kind:       "Route"
	metadata: {
		name:      "\(#config.metadata.name)-reverseproxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-reverseproxy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.reverseProxy.route.annotations != _|_ {
			annotations: #config.reverseProxy.route.annotations
		}
	}
	spec: {
		if #config.reverseProxy.route.host != _|_ && #config.reverseProxy.route.host != "" {
			host: #config.reverseProxy.route.host
		}
		to: {
			kind:   "Service"
			name:   "\(#config.metadata.name)-reverseproxy"
			weight: 100
		}
		port: targetPort: "http"
		if #config.reverseProxy.route.tls != _|_ {
			tls: #config.reverseProxy.route.tls
		}
		wildcardPolicy: "None"
	}
}
