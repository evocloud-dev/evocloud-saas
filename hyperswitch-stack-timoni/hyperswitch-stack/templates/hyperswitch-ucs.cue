package templates

import (
	"encoding/json"
	"strings"
)

hyperswitchUcs: {
	#config: #Config

	let _ucs = #config."hyperswitch-ucs"
	let _metadata = #config.metadata
	let ns = _metadata.namespace
	let _name = _metadata.name
	let fullname = "\(_name)-ucs"

	let commonLabels = {
		for k, v in _metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "hyperswitch-ucs-0.1.0"
		"app.kubernetes.io/name":       "hyperswitch-ucs"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    _ucs.image.tag
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":     "hyperswitch-ucs"
		"app.kubernetes.io/instance": _name
	}

	if _ucs.enabled {
		// File 1: configmap.yaml
		"configmap": {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "ucs-config-\(_name)"
				namespace: ns
				labels:    commonLabels
			}
			data: {
				let connectorsStr = strings.Join([
					for k, v in _ucs.config.connectors {
						let disputeLine = [if v.dispute_base_url != _|_ {"\n\(k).dispute_base_url = \"\(v.dispute_base_url)\""}, ""][0]
						"\(k).base_url = \"\(v.base_url)\"\(disputeLine)"
					},
				], "\n")

				"production.toml": """
					[log.console]
					enabled = \(_ucs.config.log.console.enabled)
					level = \"\(_ucs.config.log.console.level)\"
					log_format = \"\(_ucs.config.log.console.log_format)\"

					[server]
					host = \"\(_ucs.config.server.host)\"
					port = \(_ucs.config.server.port)
					type = \"\(_ucs.config.server.type)\"

					[metrics]
					host = \"\(_ucs.config.metrics.host)\"
					port = \(_ucs.config.metrics.port)

					[connectors]
					\(connectorsStr)
					
					[proxy]
					https_url = \"\(_ucs.config.proxy.https_url)\"
					http_url = \"\(_ucs.config.proxy.http_url)\"
					idle_pool_connection_timeout = \(_ucs.config.proxy.idle_pool_connection_timeout)
					bypass_proxy_urls = \(json.Marshal(_ucs.config.proxy.bypass_proxy_urls))
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
				if !_ucs.autoscaling.enabled {
					replicas: _ucs.replicaCount
				}
				selector: matchLabels: selectorLabels
				template: {
					metadata: {
						if len(_ucs.podAnnotations) > 0 {
							annotations: _ucs.podAnnotations
						}
						labels: selectorLabels
					}
					spec: {
						imagePullSecrets: [
							for s in _ucs.imagePullSecrets {{name: s}},
						]
						serviceAccountName: [if _ucs.serviceAccount.name != "" {_ucs.serviceAccount.name}, fullname][0]
						securityContext: _ucs.podSecurityContext
						containers: [
							{
								name:            "hyperswitch-ucs"
								securityContext: _ucs.securityContext
								image:           "\(_ucs.image.imageRegistry)/\(_ucs.image.repository):\(_ucs.image.tag)"
								imagePullPolicy: _ucs.image.pullPolicy
								ports: [
									{
										name:          "grpc"
										containerPort: _ucs.service.grpc.targetPort
										protocol:      "TCP"
									},
									{
										name:          "metrics"
										containerPort: _ucs.service.metrics.targetPort
										protocol:      "TCP"
									},
								]
								livenessProbe: {
									grpc: {
										port:    _ucs.livenessProbe.grpc.port
										service: _ucs.livenessProbe.grpc.service
									}
									initialDelaySeconds: _ucs.livenessProbe.initialDelaySeconds
									periodSeconds:       _ucs.livenessProbe.periodSeconds
									timeoutSeconds:      _ucs.livenessProbe.timeoutSeconds
									successThreshold:    _ucs.livenessProbe.successThreshold
									failureThreshold:    _ucs.livenessProbe.failureThreshold
								}
								readinessProbe: {
									grpc: {
										port:    _ucs.readinessProbe.grpc.port
										service: _ucs.readinessProbe.grpc.service
									}
									initialDelaySeconds: _ucs.readinessProbe.initialDelaySeconds
									periodSeconds:       _ucs.readinessProbe.periodSeconds
									timeoutSeconds:      _ucs.readinessProbe.timeoutSeconds
									successThreshold:    _ucs.readinessProbe.successThreshold
									failureThreshold:    _ucs.readinessProbe.failureThreshold
								}
								resources: _ucs.resources
								if len(_ucs.env) > 0 {
									env: _ucs.env
								}
								volumeMounts: [
									{
										name:      "ucs-config"
										mountPath: "/app/config/production.toml"
										subPath:   "production.toml"
									},
								]
							},
						]
						nodeSelector: _ucs.nodeSelector
						affinity:     _ucs.affinity
						tolerations:  _ucs.tolerations
						volumes: [
							{
								name: "ucs-config"
								configMap: {
									name:        "ucs-config-\(_name)"
									defaultMode: 420
								}
							},
						]
					}
				}
			}
		}

		// File 3: hpa.yaml
		if _ucs.autoscaling.enabled {
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
					minReplicas: _ucs.autoscaling.minReplicas
					maxReplicas: _ucs.autoscaling.maxReplicas
					metrics: [
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {
									type:               "Utilization"
									averageUtilization: _ucs.autoscaling.targetCPUUtilizationPercentage
								}
							}
						},
					]
				}
			}
		}

		// File 4: ingress.yaml
		if _ucs.ingress.enabled {
			"ingress": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "Ingress"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
					if len(_ucs.ingress.annotations) > 0 {
						annotations: _ucs.ingress.annotations
					}
				}
				spec: {
					if _ucs.ingress.className != "" {
						ingressClassName: _ucs.ingress.className
					}
					if len(_ucs.ingress.tls) > 0 {
						tls: _ucs.ingress.tls
					}
					rules: [
						for h in _ucs.ingress.hosts {
							{
								if h.host != _|_ {
									host: h.host
								}
								http: paths: [
									for p in h.paths {
										{
											path:     p.path
											pathType: p.pathType
											backend: service: {
												name: fullname
												port: number: _ucs.service.grpc.port
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
				type: _ucs.service.type
				ports: [
					{
						name:       "grpc"
						port:       _ucs.service.grpc.port
						targetPort: "grpc"
						protocol:   "TCP"
					},
					{
						name:       "metrics"
						port:       _ucs.service.metrics.port
						targetPort: "metrics"
						protocol:   "TCP"
					},
				]
				selector: selectorLabels
			}
		}

		// File 6: serviceaccount.yaml
		if _ucs.serviceAccount.create {
			"serviceaccount": {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name: [if _ucs.serviceAccount.name != "" {_ucs.serviceAccount.name}, fullname][0]
					namespace: ns
					labels:    commonLabels
					if len(_ucs.serviceAccount.annotations) > 0 {
						annotations: _ucs.serviceAccount.annotations
					}
				}
			}
		}
	}
}
