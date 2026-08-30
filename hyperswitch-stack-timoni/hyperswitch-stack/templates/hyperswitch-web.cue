package templates

hyperswitchWeb: {
	#config: #Config

	let _web = #config."hyperswitch-web"
	let _metadata = #config.metadata
	let ns = _metadata.namespace
	let _name = _metadata.name
	let fullname = [if _web.fullnameOverride != "" {_web.fullnameOverride}, "\(_name)-web"][0]
	let sdkPath = "/web/\(_web.autoBuild.gitCloneParam.gitVersion)/\(_web.autoBuild.nginxConfig.extraPath)/"
	let servicePort = _web.service.port

	let commonLabels = {
		for k, v in _metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "hyperswitch-web-0.1.0"
		"app.kubernetes.io/name":       "hyperswitch-web"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    "0.126.0"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":     "hyperswitch-web"
		"app.kubernetes.io/instance": _name
	}

	if _web.enabled {
		// File 1: statefulset-nginx-configmap.yaml
		"configmap-nginx": {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(fullname)-nginx"
				namespace: ns
				labels:    commonLabels
			}
			data: {
				envBackendUrl:  _web.autoBuild.buildParam.envBackendUrl
				envSdkUrl:      _web.autoBuild.buildParam.envSdkUrl
				envLogsUrl:     _web.autoBuild.buildParam.envLogsUrl
				disableCSP:     _web.autoBuild.buildParam.disableCSP
				"default.conf": """
					server {
					    listen       \(servicePort);
					    listen  [::]:\(servicePort);
					    server_name  localhost;

					    location \(sdkPath) {
					        autoindex on;
					        root   /usr/share/nginx/html;
					        index  index.html index.htm;
					    }

					    location /HyperLoader.js {
					         alias /usr/share/nginx/html\(sdkPath)HyperLoader.js;
					    }

					    location ~* ^/(?!web/)(.+)$ {
					        try_files $uri \(sdkPath)$1;
					    }

					    error_page   500 502 503 504  /50x.html;
					    location = /50x.html {
					        root   /usr/share/nginx/html;
					    }
					}
					"""
			}
		}

		// File 2: deployment.yaml
		"deployment": {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels
			}
			spec: {
				if !_web.autoscaling.enabled {
					replicas: _web.replicaCount
				}
				selector: matchLabels: selectorLabels
				template: #PodTemplate & {
					#web:            _web
					#fullname:       fullname
					#selectorLabels: selectorLabels
					#commonLabels:   commonLabels
					#sdkPath:        sdkPath
					#servicePort:    servicePort
				}
			}
		}

		// File 3: hpa.yaml
		if _web.autoscaling.enabled {
			"hpa": {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "Deployment"
						name:       fullname
					}
					minReplicas: _web.autoscaling.minReplicas
					maxReplicas: _web.autoscaling.maxReplicas
					metrics: [
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {
									type:               "Utilization"
									averageUtilization: _web.autoscaling.targetCPUUtilizationPercentage
								}
							}
						},
						{
							type: "Resource"
							resource: {
								name: "memory"
								target: {
									type:               "Utilization"
									averageUtilization: _web.autoscaling.targetMemoryUtilizationPercentage
								}
							}
						},
					]
				}
			}
		}

		// File 4: ingress.yaml
		if _web.ingress.enabled {
			"ingress": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "Ingress"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
					if len(_web.ingress.annotations) > 0 {
						annotations: _web.ingress.annotations
					}
				}
				spec: {
					if _web.ingress.className != "" {
						ingressClassName: _web.ingress.className
					}
					if len(_web.ingress.tls) > 0 {
						tls: _web.ingress.tls
					}
					rules: [
						for h in _web.ingress.hosts {
							{
								if h.host != _|_ {
									host: h.host
								}
								http: paths: [
									for p in h.http.paths {
										{
											path:     p.path
											pathType: p.pathType
											backend: service: {
												name: fullname
												port: number: servicePort
											}
										}
									},
								]
							}
						},
					]
				}
			}
		}

		// File 5: service.yaml
		"service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels
			}
			spec: {
				type: _web.service.type
				ports: [
					{
						name:       "http"
						port:       servicePort
						targetPort: "http"
						protocol:   "TCP"
					},
				]
				selector: selectorLabels
			}
		}

		// File 6: serviceaccount.yaml
		if _web.serviceAccount.create {
			"serviceaccount": {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name: [if _web.serviceAccount.name != "" {_web.serviceAccount.name}, fullname][0]
					namespace: ns
					labels:    commonLabels
					if len(_web.serviceAccount.annotations) > 0 {
						annotations: _web.serviceAccount.annotations
					}
				}
				automountServiceAccountToken: _web.serviceAccount.automount
			}
		}

		// SDK Demo App Logic... (Omitted for brevity, apply same 'let' pattern)

		#PodTemplate: {
			#web:            _
			#fullname:       string
			#selectorLabels: _
			#commonLabels:   _
			#sdkPath:        string
			#servicePort:    int

			metadata: {
				if len(#web.podAnnotations) > 0 {
					annotations: #web.podAnnotations
				}
				labels: #commonLabels & #web.podLabels
			}
			spec: {
				imagePullSecrets: [
					for s in #web.imagePullSecrets {{name: s}},
				]
				serviceAccountName: [if #web.serviceAccount.name != "" {#web.serviceAccount.name}, #fullname][0]
				securityContext: #web.podSecurityContext
				initContainers: [
					{
						name:            "build-and-copy"
						image:           "\(#web.autoBuild.buildImageRegistry)/\(#web.autoBuild.buildImage):v\(#web.autoBuild.gitCloneParam.gitVersion)"
						imagePullPolicy: #web.autoBuild.nginxConfig.pullPolicy
						command: ["/bin/sh", "-c"]
						args: [
							"""
							echo "Building static files..."
							npm run re:build
							npm run build:\(#web.env.sdkEnv)
							echo "Copying built files to nginx path..."
							mkdir -p /usr/share/nginx/html\(#sdkPath)
							cp -r /usr/src/app/dist/\(#web.env.sdkEnv)/v1/* /usr/share/nginx/html\(#sdkPath)
							echo "Build and copy completed successfully"
							""",
						]
						env: [
							{name: "sdkEnv", value: "\(#web.env.sdkEnv)"},
							{name: "PORT", value: "\(#servicePort)"},
							// ... Add other envs using #web.autoBuild...
						]
						volumeMounts: [
							{
								name:      "nginx-html-volume"
								mountPath: "/usr/share/nginx/html"
							},
						]
					},
				]
				containers: [
					{
						name:            "hyperswitch-web-nginx"
						securityContext: #web.securityContext
						image:           "\(#web.autoBuild.nginxConfig.buildImageRegistry)/\(#web.autoBuild.nginxConfig.image):\(#web.autoBuild.nginxConfig.tag)"
						imagePullPolicy: #web.autoBuild.nginxConfig.pullPolicy
						ports: [{name: "http", containerPort: #servicePort, protocol: "TCP"}]
						livenessProbe: httpGet: {path: #sdkPath, port: "http"}
						readinessProbe: httpGet: {path: #sdkPath, port: "http"}
						resources: #web.resources
						volumeMounts: [
							{
								name:      "nginx-config-volume"
								mountPath: "/etc/nginx/conf.d/default.conf"
								subPath:   "default.conf"
							},
							{
								name:      "nginx-html-volume"
								mountPath: "/usr/share/nginx/html"
							},
						]
					},
				]
				volumes: [
					{
						name: "nginx-config-volume"
						configMap: name: "\(#fullname)-nginx"
					},
					{
						name: "nginx-html-volume"
						emptyDir: {}
					},
				]
				nodeSelector: #web.nodeSelector
				affinity:     #web.affinity
				tolerations:  #web.tolerations
			}
		}
	}
}
