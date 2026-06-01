package templates

import (
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	"list"
)

#RouterTomlConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "router-cm-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
	}
	data: {
		if app.server.run_env == "production" {
			"router.toml": _routerProductionToml
		}
		if app.server.run_env == "sandbox" {
			"router.toml": _routerSandboxToml
		}
		if app.server.run_env != "production" && app.server.run_env != "sandbox" {
			"router.toml": _routerIntegToml
		}
	}
}

#RouterServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:        "\(#config.metadata.name)-router-role"
		namespace:   #config.metadata.namespace
		annotations: app.server.serviceAccount.annotations
		labels:      app.server.serviceAccount.labels
	}
}

#RouterService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-server"
		namespace: #config.metadata.namespace
	}
	spec: {
		internalTrafficPolicy: "Cluster"
		ipFamilies: ["IPv4"]
		ipFamilyPolicy: "SingleStack"
		ports: [
			{
				name:       "http"
				port:       80
				protocol:   "TCP"
				targetPort: 8080
			},
			{
				name:       "https"
				port:       443
				protocol:   "TCP"
				targetPort: 8080
			},
		]
		selector: {
			"app":                        "\(#config.metadata.name)-server"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		sessionAffinity: "None"
		type:            "ClusterIP"
	}
}

#RouterIngress: netv1.#Ingress & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:        "\(#config.metadata.name)-server-ingress"
		namespace:   #config.metadata.namespace
		annotations: app.server.ingress.annotations
	}
	spec: {
		if app.server.ingress.className != _|_ {
			ingressClassName: app.server.ingress.className
		}
		if len(app.server.ingress.tls) > 0 {
			tls: app.server.ingress.tls
		}
		rules: [
			{
				if app.server.ingress.hostname != _|_ {
					host: app.server.ingress.hostname
				}
				http: paths: [
					{
						path:     app.server.ingress.path
						pathType: app.server.ingress.pathType
						backend: service: {
							name: "\(#config.metadata.name)-server"
							port: number: 80
						}
					},
				]
			},
		]
	}
}

#RouterAnalysisTemplate: {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "argoproj.io/v1alpha1"
	kind:       "AnalysisTemplate"
	metadata: {
		name:      "\(#config.metadata.name)-server-ab-testing"
		namespace: #config.metadata.namespace
		labels: #config.global.labels & {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-server"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	spec: metrics: [
		{
			name:             "error-5xx-check"
			interval:         app.argoRollouts.canary.analysis.interval
			successCondition: "result == 0"
			failureLimit:     3
			provider: prometheus: {
				if app.argoRollouts.canary.analysis.victoriaMetrics.address != _|_ {
					address: app.argoRollouts.canary.analysis.victoriaMetrics.address
				}
				query: """
					sum(increase(
					  http_requests_total{
					    app="\(#config.metadata.name)-server",
					    version="\(app.services.router.version)",
					    status=~"5.."
					  }[1m]
					))
					"""
			}
		},
	]
}

#RouterHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-server"
		namespace: #config.metadata.namespace
	}
	spec: {
		scaleTargetRef: {
			if app.argoRollouts.enabled {
				apiVersion: "argoproj.io/v1alpha1"
				kind:       "Rollout"
			}
			if !app.argoRollouts.enabled {
				apiVersion: "apps/v1"
				kind:       "Deployment"
			}
			name: "\(#config.metadata.name)-server"
		}
		minReplicas: app.autoscaling.minReplicas
		maxReplicas: app.autoscaling.maxReplicas
		metrics: [
			{
				type: "Resource"
				resource: {
					name: "cpu"
					target: {
						type:               "Utilization"
						averageUtilization: app.autoscaling.targetCPUUtilizationPercentage
					}
				}
			},
		]
	}
}

#RouterWorkload: {
	#config: #Config
	let app = #config."hyperswitch-app"

	if app.argoRollouts.enabled {
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Rollout"
	}
	if !app.argoRollouts.enabled {
		apiVersion: "apps/v1"
		kind:       "Deployment"
	}

	metadata: {
		name:        "\(#config.metadata.name)-server"
		namespace:   #config.metadata.namespace
		annotations: #config.global.annotations & app.server.annotations
		labels: #config.global.labels & app.server.labels & {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-server"
			"app.kubernetes.io/version":    app.services.router.version
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app":                          "\(#config.metadata.name)-server"
			"version":                      app.services.router.version
		}
	}

	spec: {
		progressDeadlineSeconds: app.server.progressDeadlineSeconds
		if !app.autoscaling.enabled {
			replicas: app.server.replicas
		}
		if app.argoRollouts.enabled {
			revisionHistoryLimit: app.argoRollouts.revisionHistoryLimit
		}
		if !app.argoRollouts.enabled {
			revisionHistoryLimit: 10
		}
		selector: matchLabels: {
			"app":                        "\(#config.metadata.name)-server"
			"app.kubernetes.io/instance": #config.metadata.name
		}

		if app.argoRollouts.enabled {
			strategy: canary: {
				if len(app.argoRollouts.canary.steps) > 0 {
					steps: app.argoRollouts.canary.steps
				}
				if app.argoRollouts.canary.dynamicStableScale != _|_ {dynamicStableScale: app.argoRollouts.canary.dynamicStableScale}
				if app.argoRollouts.canary.abortScaleDownDelaySeconds != _|_ {abortScaleDownDelaySeconds: app.argoRollouts.canary.abortScaleDownDelaySeconds}
				if app.argoRollouts.canary.analysis.enabled {
					analysis: {
						templates: [{templateName: "\(#config.metadata.name)-server-ab-testing"}]
						startingStep: app.argoRollouts.canary.analysis.startingStep
						if len(app.argoRollouts.canary.analysis.args) > 0 {args: app.argoRollouts.canary.analysis.args}
					}
				}
				if app.argoRollouts.canary.antiAffinity != _|_ {antiAffinity: app.argoRollouts.canary.antiAffinity}
				if app.argoRollouts.canary.maxSurge != _|_ {maxSurge: app.argoRollouts.canary.maxSurge}
				if app.argoRollouts.canary.maxUnavailable != _|_ {maxUnavailable: app.argoRollouts.canary.maxUnavailable}
				if app.argoRollouts.canary.trafficRouting.istio.enabled {
					trafficRouting: istio: {
						virtualService: {
							name: "\(#config.metadata.name)-server-vs"
							if len(app.argoRollouts.canary.trafficRouting.istio.virtualService.routeNames) > 0 {
								routes: app.argoRollouts.canary.trafficRouting.istio.virtualService.routeNames
							}
						}
						destinationRule: {
							name:             "\(#config.metadata.name)-server-dr"
							canarySubsetName: app.argoRollouts.canary.trafficRouting.istio.destinationRule.canarySubsetName
							stableSubsetName: app.argoRollouts.canary.trafficRouting.istio.destinationRule.stableSubsetName
						}
					}
				}
			}
		}
		if !app.argoRollouts.enabled {
			strategy: app.server.strategy
		}

		template: {
			metadata: {
				annotations: #config.global.podAnnotations & app.server.podAnnotations & {
					"checksum/router-config": "dynamic-checksum-by-timoni"
					"checksum/configs":       "dynamic-checksum-by-timoni"
					"checksum/secrets":       "dynamic-checksum-by-timoni"
				}
				labels: #config.global.labels & app.server.labels & {
					"app.kubernetes.io/name":       "\(#config.metadata.name)-server"
					"app.kubernetes.io/version":    app.services.router.version
					"app.kubernetes.io/instance":   #config.metadata.name
					"app.kubernetes.io/managed-by": "timoni"
					"app":                          "\(#config.metadata.name)-server"
					"version":                      app.services.router.version
				}
			}
			spec: {
				tolerations:  #config.global.tolerations
				affinity:     app.server.affinity
				nodeSelector: #config.global.nodeSelector

				if len(#config.global.tolerations) == 0 && len((app.server.tolerations | *[])) > 0 {
					tolerations: app.server.tolerations
				}
				if len(#config.global.nodeSelector) == 0 && len((app.server.nodeSelector | *{})) > 0 {
					nodeSelector: app.server.nodeSelector
				}

				_pgInit: (#PostgresqlInitContainer & {#config: #config}).container
				_redisInit: (#RedisInitContainer & {#config: #config}).container

				initContainers: [
					if app.initDB.enable {_pgInit},
					if app.redisMiscConfig.checkRedisIsUp.initContainer.enable {_redisInit},
				]

				_metaEnvs: #MetadataEnvs
				_genericEnvs: (#GenericEnvs & {#config: #config}).env
				_pgEnvs: (#PostgresqlSecretsEnvs & {#config: #config}).env

				containers: [
					{
						name:            "router"
						image:           "\([if #config.global.imageRegistry != "" {#config.global.imageRegistry}, app.server.imageRegistry][0])/\(app.server.image):\(app.services.router.version)"
						imagePullPolicy: "IfNotPresent"
						lifecycle: preStop: exec: command: ["/bin/bash", "-c", "pkill -15 node"]
						env: list.Concat([
							[
								{name: "BINARY", value: app.server.binary},
							],
							#config.global.env,
							app.server.env,
							_metaEnvs,
							_genericEnvs,
							_pgEnvs,
						])
						envFrom: [
							{configMapRef: {name: "\(#config.metadata.name)-configs"}},
							if !#config.disableInternalSecrets {
								{secretRef: {name: "\(#config.metadata.name)-secrets"}}
							},
						]
						if len(app.server.livenessProbe) > 0 {livenessProbe: app.server.livenessProbe}
						if len(app.server.readinessProbe) > 0 {readinessProbe: app.server.readinessProbe}
						ports: [
							{
								containerPort: 8080
								name:          "http"
								protocol:      "TCP"
							},
						]
						resources: app.server.resources
						securityContext: privileged: false
						terminationMessagePath:   "/dev/termination-log"
						terminationMessagePolicy: "File"
						volumeMounts: [
							{
								mountPath: "/local/config/\(app.server.run_env).toml"
								name:      "router-config"
								subPath:   "router.toml"
							},
						]
					},
				]
				dnsPolicy:     "ClusterFirst"
				restartPolicy: "Always"
				schedulerName: "default-scheduler"
				securityContext: {}
				serviceAccountName:            "\(#config.metadata.name)-router-role"
				terminationGracePeriodSeconds: app.server.terminationGracePeriodSeconds
				volumes: [
					{
						name: "router-config"
						configMap: {
							name:        "router-cm-\(#config.metadata.name)"
							defaultMode: 420
						}
					},
				]
			}
		}
	}
}
