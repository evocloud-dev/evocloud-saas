package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	netv1 "k8s.io/api/networking/v1"
	"strings"
)

#HyperswitchControlCenterName: {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _fullname = cc.fullnameOverride | *""
	let _name = cc.nameOverride | *""
	let _stackName = #config.metadata.name
	result: [if _fullname != "" {_fullname}, [if _name != "" {_name}, "\(_stackName)-control-center"][0]][0]
}

#HyperswitchControlCenterLabels: {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	result: {
		"helm.sh/chart":                "hyperswitch-control-center-0.1.0"
		"app":                          _name
		"app.kubernetes.io/name":       _name
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    cc.image.tag
		"app.kubernetes.io/managed-by": "Helm"
	}
}

#HyperswitchControlCenterSelectorLabels: {
	#config: #Config
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	result: {
		"app":                        _name
		"app.kubernetes.io/instance": #config.metadata.name
	}
}

// 1. /charts/hyperswitch-control-center/templates/configmap.yaml
#HyperswitchControlCenterConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result
	let hyperloaderUrl = [if cc.dependencies.sdk.fullUrlOverride != "" {cc.dependencies.sdk.fullUrlOverride}, "\(cc.dependencies.sdk.host)/web/\(cc.dependencies.sdk.version)/\(cc.dependencies.sdk.subversion)/HyperLoader.js"][0]

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    _labels
	}
	data: {
		binary:                                        "dashboard"
		apiBaseUrl:                                    cc.dependencies.router.host
		sdkBaseUrl:                                    hyperloaderUrl
		default__endpoints__api_url:                   cc.dependencies.router.host
		default__endpoints__sdk_url:                   hyperloaderUrl
		default__endpoints__apple_pay_certificate_url: "\(cc.dependencies.router.host)/applepay-domain/apple-developer-merchantid-domain-association"
		default__features__audit_trail:                "\(cc.dependencies.clickhouse.enabled)"

		// mixpanelToken
		"mixpanelToken": cc.config.mixpanelToken

		// config.default.features
		for k, v in cc.config.default.features {
			"default__features__\(k)": "\(v)"
		}

		// config.default.endpoints
		for k, v in cc.config.default.endpoints {
			"default__endpoints__\(k)": "\(v)"
		}

		// config.default.theme
		for k, v in cc.config.default.theme {
			"default__theme__\(k)": "\(v)"
		}

		// config.default.merchant_config.new_analytics
		for k, v in cc.config.default.merchant_config.new_analytics {
			"default__merchant_config__new_analytics__\(k)": strings.Join([for x in v {"\(x)"}], ",")
		}
	}
}

// 2. /charts/hyperswitch-control-center/templates/deployment.yaml
#HyperswitchControlCenterDeployment: appsv1.#Deployment & {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result
	let selectorLabels = (#HyperswitchControlCenterSelectorLabels & {#config: #config}).result
	let saName = [if cc.serviceAccount.name != "" {cc.serviceAccount.name}, [if cc.serviceAccount.create {_name}, "default"][0]][0]
	let _image = [if cc.global.imageRegistry != "" {cc.global.imageRegistry}, cc.image.registry][0] + "/" + cc.image.repository + ":" + cc.image.tag

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    _labels
	}
	spec: {
		replicas:                cc.replicaCount
		revisionHistoryLimit:    10
		progressDeadlineSeconds: cc.progressDeadlineSeconds
		strategy:                cc.strategy
		selector: matchLabels: selectorLabels
		template: {
			metadata: {
				annotations: {
					"checksum/config": "cc-config-checksum" // Placeholder
					for k, v in cc.podAnnotations {"\(k)": v}
				}
				labels: _labels & {
					for k, v in cc.podLabels {"\(k)": v}
				}
			}
			spec: corev1.#PodSpec & {
				if len(cc.imagePullSecrets) > 0 {
					imagePullSecrets: [
						for s in cc.imagePullSecrets {
							name: s.name
						},
					]
				}
				serviceAccountName: saName
				if len([for k, v in cc.podSecurityContext {k}]) > 0 {
					securityContext: cc.podSecurityContext
				}
				containers: [
					{
						name: "hyperswitch-control-center"
						if len([for k, v in cc.securityContext {k}]) > 0 {
							securityContext: cc.securityContext
						}
						image:           _image
						imagePullPolicy: cc.image.pullPolicy
						lifecycle: preStop: exec: command: [
							"/bin/bash",
							"-c",
							"pkill -15 node",
						]
						envFrom: [{configMapRef: {name: _name}}]
						if len(cc.extraEnvVars) > 0 {
							env: cc.extraEnvVars
						}
						ports: [{
							name:          "http"
							containerPort: cc.service.port
							protocol:      "TCP"
						}]
						if len([for k, v in cc.livenessProbe {k}]) > 0 {
							livenessProbe: cc.livenessProbe
						}
						if len([for k, v in cc.readinessProbe {k}]) > 0 {
							readinessProbe: cc.readinessProbe
						}
						if len([for k, v in cc.resources {k}]) > 0 {
							resources: cc.resources
						}
						terminationMessagePath:   "/dev/termination-log"
						terminationMessagePolicy: "File"
						if len(cc.volumeMounts) > 0 {
							volumeMounts: cc.volumeMounts
						}
					},
				]
				if len(cc.volumes) > 0 {
					volumes: cc.volumes
				}
				dnsPolicy:                     "ClusterFirst"
				restartPolicy:                 "Always"
				schedulerName:                 "default-scheduler"
				terminationGracePeriodSeconds: cc.terminationGracePeriodSeconds
				if len([for k, v in cc.nodeSelector {k}]) > 0 {
					nodeSelector: cc.nodeSelector
				}
				if len([for k, v in cc.affinity {k}]) > 0 {
					affinity: cc.affinity
				}
				if len(cc.tolerations) > 0 {
					tolerations: cc.tolerations
				}
			}
		}
	}
}

// 3. /charts/hyperswitch-control-center/templates/service.yaml
#HyperswitchControlCenterService: corev1.#Service & {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result
	let selectorLabels = (#HyperswitchControlCenterSelectorLabels & {#config: #config}).result

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		if len(cc.service.annotations) > 0 {
			annotations: cc.service.annotations
		}
		labels: _labels
	}
	spec: {
		type: cc.service.type
		if cc.service.type == "ClusterIP" {
			internalTrafficPolicy: "Cluster"
		}
		ipFamilies: ["IPv4"]
		ipFamilyPolicy: "SingleStack"
		ports: [
			{
				name:       "http"
				port:       80
				targetPort: cc.service.port
				protocol:   "TCP"
			},
			{
				name:       "https"
				port:       443
				targetPort: cc.service.port
				protocol:   "TCP"
			},
		]
		selector:        selectorLabels
		sessionAffinity: "None"
	}
}

// 4. /charts/hyperswitch-control-center/templates/serviceaccount.yaml
#HyperswitchControlCenterServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result
	let saName = [if cc.serviceAccount.name != "" {cc.serviceAccount.name}, [if cc.serviceAccount.create {_name}, "default"][0]][0]

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      saName
		namespace: #config.metadata.namespace
		labels:    _labels
		if len(cc.serviceAccount.annotations) > 0 {
			annotations: cc.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: cc.serviceAccount.automount
}

// 5. /charts/hyperswitch-control-center/templates/ingress.yaml
#HyperswitchControlCenterIngress: netv1.#Ingress & {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    _labels
		if len(cc.ingress.annotations) > 0 {
			annotations: cc.ingress.annotations
		}
	}
	spec: {
		if cc.ingress.className != "" {
			ingressClassName: cc.ingress.className
		}
		if len(cc.ingress.tls) > 0 {
			tls: [
				for t in cc.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
		rules: [
			for h in cc.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: _name
							port: number: 80
						}
					},
				]
			},
		]
	}
}

// 6. /charts/hyperswitch-control-center/templates/istio-virtualservice.yaml
#HyperswitchControlCenterIstioVirtualService: {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result

	apiVersion: "networking.istio.io/v1beta1"
	kind:       "VirtualService"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    _labels
	}
	spec: {
		hosts:    cc.istio.virtualService.hosts
		gateways: cc.istio.virtualService.gateways
		http: [
			for rule in cc.istio.virtualService.http {
				rule & {
					route: [{
						destination: {
							host: _name
							port: number: 80
						}
					}]
				}
			},
		]
	}
}

// 7. /charts/hyperswitch-control-center/templates/istio-destinationrule.yaml
#HyperswitchControlCenterIstioDestinationRule: {
	#config: #Config
	let cc = #config."hyperswitch-app"."hyperswitch-control-center"
	let _name = (#HyperswitchControlCenterName & {#config: #config}).result
	let _labels = (#HyperswitchControlCenterLabels & {#config: #config}).result

	apiVersion: "networking.istio.io/v1beta1"
	kind:       "DestinationRule"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    _labels
	}
	spec: {
		host:          _name
		trafficPolicy: cc.istio.destinationRule.trafficPolicy
	}
}
