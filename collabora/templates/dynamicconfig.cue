package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

// #DynamicConfigMap mirrors upstream dynamicConfig/configmap.yaml
#DynamicConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	data: "config.json": #config.dynamicConfig.configuration
}

// #DynamicConfigService mirrors upstream dynamicConfig/service.yaml
#DynamicConfigService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
			type:                         "dynconfig"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [{
			port:       #config.dynamicConfig.service.port
			targetPort: "http"
			protocol:   "TCP"
			name:       "http"
		}]
		selector: #config.selector.labels & {
			type: "dynconfig"
		}
	}
}

// #DynamicConfigIngress mirrors upstream dynamicConfig/ingress.yaml
#DynamicConfigIngress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.dynamicConfig.ingress.annotations != _|_ {
			annotations: #config.dynamicConfig.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.dynamicConfig.ingress.className != _|_ {
			ingressClassName: #config.dynamicConfig.ingress.className
		}
		if #config.dynamicConfig.ingress.tls != _|_ {
			tls: #config.dynamicConfig.ingress.tls
		}
		if #config.dynamicConfig.ingress.hosts != _|_ {
			rules: [
				for h in #config.dynamicConfig.ingress.hosts {
					host: h.host
					http: paths: [
						for p in h.paths {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: "\(#config.metadata.name)-dynconfig"
								port: number: #config.dynamicConfig.service.port
							}
						},
					]
				},
			]
		}
	}
}

// #DynamicConfigDeployment mirrors upstream dynamicConfig/deployment.yaml
#DynamicConfigDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.dynamicConfig.replicaCount
		selector: matchLabels: #config.selector.labels & {
			type: "dynconfig"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					type: "dynconfig"
				}
				if #config.dynamicConfig.podAnnotations != _|_ {
					annotations: #config.dynamicConfig.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.serviceAccountName
				if #config.dynamicConfig.podSecurityContext != _|_ {
					securityContext: #config.dynamicConfig.podSecurityContext
				}
				containers: [{
					name: "\( #config.metadata.name )-dynconfig"
					if #config.dynamicConfig.securityContext != _|_ {
						securityContext: #config.dynamicConfig.securityContext
					}
					image:           "\(#config.dynamicConfig.image.repository):\(#config.dynamicConfig.image.tag)"
					imagePullPolicy: #config.dynamicConfig.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.dynamicConfig.containerPort
						protocol:      "TCP"
					}]
					if #config.dynamicConfig.probes.readiness.enabled {
						readinessProbe: {
							httpGet: {
								path:   "/"
								port:   #config.dynamicConfig.containerPort
								scheme: #config.dynamicConfig.probes.scheme
							}
							initialDelaySeconds: #config.dynamicConfig.probes.readiness.initialDelaySeconds
							periodSeconds:       #config.dynamicConfig.probes.readiness.periodSeconds
							timeoutSeconds:      #config.dynamicConfig.probes.readiness.timeoutSeconds
							successThreshold:    #config.dynamicConfig.probes.readiness.successThreshold
							failureThreshold:    #config.dynamicConfig.probes.readiness.failureThreshold
						}
					}
					if #config.dynamicConfig.probes.liveness.enabled {
						livenessProbe: {
							httpGet: {
								path:   "/"
								port:   #config.dynamicConfig.containerPort
								scheme: #config.dynamicConfig.probes.scheme
							}
							initialDelaySeconds: #config.dynamicConfig.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.dynamicConfig.probes.liveness.periodSeconds
							timeoutSeconds:      #config.dynamicConfig.probes.liveness.timeoutSeconds
							successThreshold:    #config.dynamicConfig.probes.liveness.successThreshold
							failureThreshold:    #config.dynamicConfig.probes.liveness.failureThreshold
						}
					}
					if #config.dynamicConfig.probes.startup.enabled {
						startupProbe: {
							httpGet: {
								path:   "/"
								port:   #config.dynamicConfig.containerPort
								scheme: #config.dynamicConfig.probes.scheme
							}
							failureThreshold: #config.dynamicConfig.probes.startup.failureThreshold
							periodSeconds:    #config.dynamicConfig.probes.startup.periodSeconds
						}
					}
					if #config.dynamicConfig.env != _|_ {
						env: #config.dynamicConfig.env
					}
					if #config.dynamicConfig.resources != _|_ {
						resources: #config.dynamicConfig.resources
					}
					volumeMounts: [{
						name:      "config"
						mountPath: "/etc/nginx/conf.d/config.json"
						subPath:   "config.json"
					}]
				}]
				volumes: [{
					name: "config"
					configMap: name: [
						if #config.dynamicConfig.existingConfigMap.enabled {#config.dynamicConfig.existingConfigMap.name},
						"\(#config.metadata.name)-dynconfig",
					][0]
				}]
				if #config.dynamicConfig.nodeSelector != _|_ {
					nodeSelector: #config.dynamicConfig.nodeSelector
				}
				if #config.dynamicConfig.affinity != _|_ {
					affinity: #config.dynamicConfig.affinity
				}
				if #config.dynamicConfig.tolerations != _|_ {
					tolerations: #config.dynamicConfig.tolerations
				}
			}
		}
	}
}

// #DynamicConfigStatefulSet mirrors upstream dynamicConfig/statefulset.yaml
#DynamicConfigStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.metadata.name)-dynconfig"
		replicas:    1
		selector: matchLabels: #config.selector.labels & {
			type: "dynconfig"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					type: "dynconfig"
				}
				if #config.dynamicConfig.podAnnotations != _|_ {
					annotations: #config.dynamicConfig.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.serviceAccountName
				if #config.dynamicConfig.podSecurityContext != _|_ {
					securityContext: #config.dynamicConfig.podSecurityContext
				}
				containers: [
					{
						name: "\( #config.metadata.name )-dynconfig"
						if #config.dynamicConfig.securityContext != _|_ {
							securityContext: #config.dynamicConfig.securityContext
						}
						image:           "\(#config.dynamicConfig.image.repository):\(#config.dynamicConfig.image.tag)"
						imagePullPolicy: #config.dynamicConfig.image.pullPolicy
						ports: [{
							name:          "http"
							containerPort: #config.dynamicConfig.containerPort
							protocol:      "TCP"
						}]
						if #config.dynamicConfig.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path:   "/"
									port:   #config.dynamicConfig.containerPort
									scheme: #config.dynamicConfig.probes.scheme
								}
								initialDelaySeconds: #config.dynamicConfig.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.dynamicConfig.probes.readiness.periodSeconds
								timeoutSeconds:      #config.dynamicConfig.probes.readiness.timeoutSeconds
								successThreshold:    #config.dynamicConfig.probes.readiness.successThreshold
								failureThreshold:    #config.dynamicConfig.probes.readiness.failureThreshold
							}
						}
						if #config.dynamicConfig.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path:   "/"
									port:   #config.dynamicConfig.containerPort
									scheme: #config.dynamicConfig.probes.scheme
								}
								initialDelaySeconds: #config.dynamicConfig.probes.liveness.initialDelaySeconds
								periodSeconds:       #config.dynamicConfig.probes.liveness.periodSeconds
								timeoutSeconds:      #config.dynamicConfig.probes.liveness.timeoutSeconds
								successThreshold:    #config.dynamicConfig.probes.liveness.successThreshold
								failureThreshold:    #config.dynamicConfig.probes.liveness.failureThreshold
							}
						}
						if #config.dynamicConfig.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path:   "/"
									port:   #config.dynamicConfig.containerPort
									scheme: #config.dynamicConfig.probes.scheme
								}
								failureThreshold: #config.dynamicConfig.probes.startup.failureThreshold
								periodSeconds:    #config.dynamicConfig.probes.startup.periodSeconds
							}
						}
						if #config.dynamicConfig.env != _|_ {
							env: #config.dynamicConfig.env
						}
						if #config.dynamicConfig.resources != _|_ {
							resources: #config.dynamicConfig.resources
						}
						volumeMounts: [{
							name:      "config"
							mountPath: "/usr/share/nginx/html/config"
						}]
					},
					{
						name:  "\( #config.metadata.name )-dynconfig-upload"
						image: "\(#config.dynamicConfig.upload.image.repository)@\(#config.dynamicConfig.upload.image.digest)"
						envFrom: [{
							secretRef: name: "\(#config.metadata.name)-upload-env"
						}]
						ports: [{
							name:          "upload-http"
							containerPort: 3000
						}]
						volumeMounts: [{
							name:      "config"
							mountPath: "/config"
						}]
					},
				]
				if #config.dynamicConfig.nodeSelector != _|_ {
					nodeSelector: #config.dynamicConfig.nodeSelector
				}
				if #config.dynamicConfig.affinity != _|_ {
					affinity: #config.dynamicConfig.affinity
				}
				if #config.dynamicConfig.tolerations != _|_ {
					tolerations: #config.dynamicConfig.tolerations
				}
			}
		}
		volumeClaimTemplates: [
			{
				metadata: name: "config"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: [#config.dynamicConfig.upload.pvc.accessMode]
					resources: requests: storage: #config.dynamicConfig.upload.pvc.size
					if #config.dynamicConfig.upload.pvc.storageClassName != _|_ {
						storageClassName: #config.dynamicConfig.upload.pvc.storageClassName
					}
				}
			},
		]
	}
}

// #DynamicConfigUploadSecret mirrors upstream dynamicConfig/upload_secret.yaml
#DynamicConfigUploadSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-upload-env"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	type: "Opaque"
	stringData: {
		"KEY_\(#config.dynamicConfig.upload.key)": "/config/config.json"
	}
}

// #DynamicConfigUploadIngress mirrors upstream dynamicConfig/ingress_upload.yaml
#DynamicConfigUploadIngress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig-upload"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.dynamicConfig.upload.ingress.annotations != _|_ {
			annotations: #config.dynamicConfig.upload.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.dynamicConfig.upload.ingress.className != _|_ {
			ingressClassName: #config.dynamicConfig.upload.ingress.className
		}
		if #config.dynamicConfig.upload.ingress.tls != _|_ {
			tls: #config.dynamicConfig.upload.ingress.tls
		}
		if #config.dynamicConfig.upload.ingress.hosts != _|_ {
			rules: [
				for h in #config.dynamicConfig.upload.ingress.hosts {
					host: h.host
					http: paths: [
						for p in h.paths {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: "\(#config.metadata.name)-dynconfig"
								port: number: #config.dynamicConfig.upload.service.port
							}
						},
					]
				},
			]
		}
	}
}

// #DynamicConfigFlow mirrors upstream dynamicConfig/flow_dynconfig.yaml
#DynamicConfigFlow: {
	#config: #Config
	apiVersion: "logging.banzaicloud.io/v1beta1"
	kind:       "Flow"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		match: [{
			select: {
				labels: #config.selector.labels & {
					type: "dynconfig"
				}
				container_names: [
					"\(#config.metadata.name)-dynconfig",
				]
			}
		}]
		filters: [
			{
				parser: {
					hash_value_field:      "nginx"
					reserve_data:          true
					reserve_time:          true
					remove_key_name_field: true
					parse: {
						type: "multi_format"
						patterns: [
							{
								format:      "regexp"
								expression:  #"^(?<remote>[^ ]*) -?(?<host>.*) -?(?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S*) ?(?<path>[^\"]*) (?<httpversion>HTTP\/[0-9\.]+)?" (?<code>[^ ]*) (?<size>[^ ]*) "-?(?<referer>[^\"]*)" "(?<agent>[^\"]*)" "(?:(?<upstream_address_list>[^\"-]*)|-)"?$"#
								types:       "code:integer,size:integer,upstream_address_list:array"
								time_key:    "time"
								time_format: "%d/%b/%Y:%H:%M:%S %z"
							},
							{format: "none"},
						]
					}
				}
			},
			if #config.dynamicConfig.logging.additionalFilters != _|_ {
				for f in #config.dynamicConfig.logging.additionalFilters {f}
			},
		]
		if #config.dynamicConfig.logging.globalOutputRefs != _|_ {
			globalOutputRefs: #config.dynamicConfig.logging.globalOutputRefs
		}
		if #config.dynamicConfig.logging.localOutputRefs != _|_ {
			localOutputRefs: #config.dynamicConfig.logging.localOutputRefs
		}
	}
}

// #DynamicConfigUploadFlow mirrors upstream dynamicConfig/flow_dynconfig_upload.yaml
#DynamicConfigUploadFlow: {
	#config: #Config
	apiVersion: "logging.banzaicloud.io/v1beta1"
	kind:       "Flow"
	metadata: {
		name:      "\(#config.metadata.name)-dynconfig-upload"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		match: [{
			select: {
				labels: #config.selector.labels & {
					type: "dynconfig"
				}
				container_names: [
					"\(#config.metadata.name)-dynconfig-upload",
				]
			}
		}]
		filters: [
			{
				parser: {
					hash_value_field:      "simple-upload"
					reserve_data:          true
					remove_key_name_field: true
					parse: {
						type: "multi_format"
						patterns: [
							{
								format:     "regexp"
								expression: #"^\[(?<ip>[a-f0-9\.:]+)\]\s\[(?<statuscode>\d+)\]\s(?<message>.*)"#
								types:      "statuscode:integer"
							},
							{format: "none"},
						]
					}
				}
			},
			if #config.dynamicConfig.upload.logging.additionalFilters != _|_ {
				for f in #config.dynamicConfig.upload.logging.additionalFilters {f}
			},
		]
		if #config.dynamicConfig.upload.logging.globalOutputRefs != _|_ {
			globalOutputRefs: #config.dynamicConfig.upload.logging.globalOutputRefs
		}
		if #config.dynamicConfig.upload.logging.localOutputRefs != _|_ {
			localOutputRefs: #config.dynamicConfig.upload.logging.localOutputRefs
		}
	}
}
