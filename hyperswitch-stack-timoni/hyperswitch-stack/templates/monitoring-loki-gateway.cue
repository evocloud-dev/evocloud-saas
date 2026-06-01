package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
)

// Complete Loki Gateway template with all 8 files consolidated
monitoringLokiGateway: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace
	let fullname = #config.metadata.name + "-loki-gateway"
	let gatewayLabels = {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if loki.image.tag != "" {loki.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "gateway"
	}
	let gatewayTag = [if loki.gateway.image.tag != "" {loki.gateway.image.tag}, #config.moduleVersion][0]
	let gatewayImage = "\(loki.gateway.image.repository):\(gatewayTag)"

	if loki.gateway.enabled {
		// 1. configmap-gateway.yaml
		"configmap": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    gatewayLabels
			}
			data: "nginx.conf": loki.gateway.nginxConfig.file
		}

		// 2. deployment-gateway-nginx.yaml
		"deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    gatewayLabels
			}
			spec: {
				replicas:             loki.gateway.replicas
				strategy:             loki.gateway.deploymentStrategy
				revisionHistoryLimit: loki.loki.revisionHistoryLimit
				selector: matchLabels: gatewayLabels
				template: {
					metadata: {
						labels: gatewayLabels
					}
					spec: {
						serviceAccountName: [if loki.serviceAccount.name != "" {loki.serviceAccount.name}, "loki"][0]
						securityContext:               loki.gateway.podSecurityContext
						terminationGracePeriodSeconds: loki.gateway.terminationGracePeriodSeconds
						containers: [{
							name:            "nginx"
							image:           gatewayImage
							imagePullPolicy: loki.gateway.image.pullPolicy
							ports: [{name: "http-metrics", containerPort: loki.gateway.containerPort, protocol: "TCP"}]
							readinessProbe:  loki.gateway.readinessProbe
							securityContext: loki.gateway.containerSecurityContext
							volumeMounts: [
								{name: "config", mountPath: "/etc/nginx"},
								if loki.gateway.basicAuth.enabled {
									{name: "auth", mountPath: "/etc/nginx/secrets"}
								},
								{name: "tmp", mountPath: "/tmp"},
								{name: "cache", mountPath: "/var/cache/nginx"},
								{name: "run", mountPath: "/var/run"},
								{name: "docker-entrypoint-d-override", mountPath: "/docker-entrypoint.d"},
								...loki.gateway.extraVolumeMounts,
							]
							resources: loki.gateway.resources
						}]
						volumes: [
							{
								name: "config"
								configMap: {
									name: fullname
									items: [{key: "nginx.conf", path: "nginx.conf"}]
								}
							},
							if loki.gateway.basicAuth.enabled {
								{
									name: "auth"
									secret: secretName: [if loki.gateway.basicAuth.existingSecret != "" {loki.gateway.basicAuth.existingSecret}, fullname][0]
								}
							},
							{
								name:     "tmp"
								emptyDir: {}
							},
							{
								name:     "cache"
								emptyDir: {}
							},
							{
								name:     "run"
								emptyDir: {}
							},
							{
								name:     "docker-entrypoint-d-override"
								emptyDir: {}
							},
							...loki.gateway.extraVolumes,
						]
					}
				}
			}
		}

		// 3. hpa.yaml
		if loki.gateway.autoscaling.enabled {
			"hpa": autoscalingv2.#HorizontalPodAutoscaler & {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {name: fullname, namespace: ns, labels: gatewayLabels}
				spec: {
					scaleTargetRef: {apiVersion: "apps/v1", kind: "Deployment", name: fullname}
					minReplicas: loki.gateway.autoscaling.minReplicas
					maxReplicas: loki.gateway.autoscaling.maxReplicas
					metrics: [
						if loki.gateway.autoscaling.targetMemoryUtilizationPercentage != null {type: "Resource", resource: {name: "memory", target: {type: "Utilization", averageUtilization: loki.gateway.autoscaling.targetMemoryUtilizationPercentage}}},
						if loki.gateway.autoscaling.targetCPUUtilizationPercentage != null {type: "Resource", resource: {name: "cpu", target: {type: "Utilization", averageUtilization: loki.gateway.autoscaling.targetCPUUtilizationPercentage}}},
					]
				}
			}
		}

		// 4. ingress-gateway.yaml
		if loki.gateway.ingress.enabled {
			"ingress": netv1.#Ingress & {
				apiVersion: "networking.k8s.io/v1"
				kind:       "Ingress"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    gatewayLabels & loki.gateway.ingress.labels
					if len(loki.gateway.ingress.annotations) > 0 {
						annotations: loki.gateway.ingress.annotations
					}
				}
				spec: {
					if loki.gateway.ingress.ingressClassName != "" {
						ingressClassName: loki.gateway.ingress.ingressClassName
					}
					if len(loki.gateway.ingress.tls) > 0 {
						tls: loki.gateway.ingress.tls
					}
					rules: [for host in loki.gateway.ingress.hosts {
						host: host.host
						http: paths: [for path in host.paths {
							path:     path.path
							pathType: path.pathType
							backend: service: {
								name: fullname
								port: number: loki.gateway.service.port
							}
						}]
					}]
				}
			}
		}

		// 5. poddisruptionbudget-gateway.yaml
		if (!loki.gateway.autoscaling.enabled && loki.gateway.replicas > 1) || (loki.gateway.autoscaling.enabled && loki.gateway.autoscaling.minReplicas > 1) {
			"poddisruptionbudget": policyv1.#PodDisruptionBudget & {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {name: fullname, namespace: ns, labels: gatewayLabels}
				spec: {selector: matchLabels: gatewayLabels, maxUnavailable: 1}
			}
		}

		// 6. secret-gateway.yaml
		if loki.gateway.basicAuth.enabled && (loki.gateway.basicAuth.existingSecret == null || loki.gateway.basicAuth.existingSecret == "") {
			"secret": corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {name: fullname, namespace: ns, labels: gatewayLabels}
				stringData: ".htpasswd": loki.gateway.basicAuth.htpasswd
			}
		}

		// 7. service-gateway.yaml
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    gatewayLabels & loki.loki.serviceLabels & loki.gateway.service.labels
				if len(loki.loki.serviceAnnotations) > 0 || len(loki.gateway.service.annotations) > 0 {
					annotations: loki.loki.serviceAnnotations & loki.gateway.service.annotations
				}
			}
			spec: {
				type: loki.gateway.service.type
				if loki.gateway.service.clusterIP != null {
					clusterIP: loki.gateway.service.clusterIP
				}
				if loki.gateway.service.type == "LoadBalancer" && loki.gateway.service.loadBalancerIP != null {
					loadBalancerIP: loki.gateway.service.loadBalancerIP
				}
				ports: [{name: "http-metrics", port: loki.gateway.service.port, targetPort: "http-metrics", if loki.gateway.service.type == "NodePort" && loki.gateway.service.nodePort != null {nodePort: loki.gateway.service.nodePort}, protocol: "TCP"}]
				selector: gatewayLabels
			}
		}

		// Enterprise Gateway deployment
		if loki.enterprise.enabled && loki.enterprise.gelGateway {
			"deployment-enterprise": appsv1.#Deployment & {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    gatewayLabels
				}
				spec: {
					replicas:             loki.enterprise.gelGateway.replicas
					strategy:             loki.gateway.deploymentStrategy
					revisionHistoryLimit: loki.loki.revisionHistoryLimit
					selector: matchLabels: gatewayLabels
					template: {
						metadata: {
							labels: gatewayLabels
						}
						spec: {
							serviceAccountName: [if loki.serviceAccount.name != "" {loki.serviceAccount.name}, "loki"][0]
							securityContext:               loki.enterprise.gelGateway.podSecurityContext
							terminationGracePeriodSeconds: loki.enterprise.gelGateway.terminationGracePeriodSeconds
							containers: [{
								name:            "nginx"
								image:           gatewayImage
								imagePullPolicy: loki.gateway.image.pullPolicy
								ports: [{name: "http-metrics", containerPort: loki.gateway.containerPort, protocol: "TCP"}]
								readinessProbe:  loki.gateway.readinessProbe
								securityContext: loki.enterprise.gelGateway.containerSecurityContext
								volumeMounts: [
									{name: "config", mountPath: "/etc/nginx"},
									{name: "tmp", mountPath: "/tmp"},
									{name: "docker-entrypoint-d-override", mountPath: "/docker-entrypoint.d"},
								]
								resources: loki.enterprise.gelGateway.resources
							}]
							volumes: [
								{
									name: "config"
									configMap: {
										name: fullname
										items: [{key: "nginx.conf", path: "nginx.conf"}]
									}
								},
								{
									name: "tmp"
									emptyDir: {}
								},
								{
									name:     "docker-entrypoint-d-override"
									emptyDir: {}
								},
							]
						}
					}
				}
			}
		}
	}
}
