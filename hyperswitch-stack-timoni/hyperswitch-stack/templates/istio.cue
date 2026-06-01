package templates

import (
	"list"
)

#IstioDestinationRule: {
	#config: #Config
	let app = #config."hyperswitch-app"

	_baseName: "\(#config.metadata.name)-server"

	apiVersion: "networking.istio.io/v1beta1"
	kind:       "DestinationRule"
	metadata: {
		name:      "\(_baseName)-dr"
		namespace: #config.metadata.namespace
		labels: #config.global.labels & {
			"app.kubernetes.io/name":       _baseName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/component":  "istio-destination-rule"
		}
	}
	spec: {
		host: _baseName
		if app.argoRollouts.enabled && app.argoRollouts.canary.trafficRouting.istio.enabled {
			subsets: [
				{
					name: app.argoRollouts.canary.trafficRouting.istio.destinationRule.stableSubsetName
					labels: {
						"app":                        _baseName
						"app.kubernetes.io/instance": #config.metadata.name
					}
				},
				{
					name: app.argoRollouts.canary.trafficRouting.istio.destinationRule.canarySubsetName
					labels: {
						"app":                        _baseName
						"app.kubernetes.io/instance": #config.metadata.name
					}
				},
			]
		}
		if app.istio.destinationRule.trafficPolicy != _|_ {
			trafficPolicy: app.istio.destinationRule.trafficPolicy
		}
	}
}

#IstioVirtualService: {
	#config: #Config
	let app = #config."hyperswitch-app"

	_baseName: "\(#config.metadata.name)-server"

	apiVersion: "networking.istio.io/v1beta1"
	kind:       "VirtualService"
	metadata: {
		name:      "\(_baseName)-vs"
		namespace: #config.metadata.namespace
		labels: #config.global.labels & {
			"app.kubernetes.io/name":       _baseName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/component":  "istio-virtual-service"
		}
	}
	spec: {
		if len(app.istio.virtualService.hosts) > 0 {
			hosts: app.istio.virtualService.hosts
		}
		if len(app.istio.virtualService.gateways) > 0 {
			gateways: app.istio.virtualService.gateways
		}
		if len(app.istio.virtualService.http) > 0 && app.services.router.enabled {
			http: [
				if app.argoRollouts.enabled && app.argoRollouts.canary.trafficRouting.istio.enabled && app.argoRollouts.canary.trafficRouting.headerRouting.enabled {
					name: app.argoRollouts.canary.trafficRouting.headerRouting.routeName
					match: [
						for m in app.argoRollouts.canary.trafficRouting.headerRouting.match {
							headers: "\(m.headerName)": m.headerValue
						},
					]
					route: [
						{
							destination: {
								host:   _baseName
								subset: app.argoRollouts.canary.trafficRouting.istio.destinationRule.canarySubsetName
								port: number: 80
							}
							weight: 100
						},
					]
				},
				for h in app.istio.virtualService.http {
					if h.name != _|_ {name: h.name}
					if h.match != _|_ {match: h.match}
					if h.rewrite != _|_ {rewrite: h.rewrite}
					if h.timeout != _|_ {timeout: h.timeout}
					if h.retries != _|_ {retries: h.retries}

					let _isArgoRolloutManaged = app.argoRollouts.enabled && app.argoRollouts.canary.trafficRouting.istio.enabled && h.name != _|_ && list.Contains(app.argoRollouts.canary.trafficRouting.istio.virtualService.routeNames, h.name)

					if _isArgoRolloutManaged {
						route: [
							{
								destination: {
									host:   _baseName
									subset: app.argoRollouts.canary.trafficRouting.istio.destinationRule.stableSubsetName
									port: number: 80
								}
								weight: 100
							},
							{
								destination: {
									host:   _baseName
									subset: app.argoRollouts.canary.trafficRouting.istio.destinationRule.canarySubsetName
									port: number: 80
								}
								weight: 0
							},
						]
					}
					if !_isArgoRolloutManaged {
						route: [
							{
								destination: {
									host: _baseName
									port: number: 80
								}
								weight: (h.weight | *100)
							},
						]
					}
				},
			]
		}
	}
}
