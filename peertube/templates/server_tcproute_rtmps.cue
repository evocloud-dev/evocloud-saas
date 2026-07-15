package templates

#ServerTCPRouteRtmps: {
	#config:    #Config
	apiVersion: "gateway.networking.k8s.io/v1alpha2"
	kind:       "TCPRoute"
	metadata: {
		name:      *"\((#config.metadata.name))-server-live-rtmps" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.tcpRoute.annotations != _|_ {
			annotations: #config.server.tcpRoute.annotations
		}
	}
	spec: {
		if #config.server.tcpRoute.rtmps.parentRefs != _|_ {
			parentRefs: #config.server.tcpRoute.rtmps.parentRefs
		}
		rules: [
			{
				backendRefs: [
					{
						name: *"\((#config.metadata.name))-live" | string
						port: #config.server.liveService.portRtmps
					}
				]
			}
		]
	}
}
