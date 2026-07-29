package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerLiveService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      *"\((#config.metadata.name))-live" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.liveService.annotations != _|_ {
			annotations: #config.server.liveService.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.server.liveService.type
		ports: [
			{
				name:       "rtmp"
				port:       #config.server.liveService.portRtmp
				protocol:   "TCP"
				targetPort: "rtmp"
				#appProto:  *"" | string
				if (#config.server.liveService["appProtocol"] & string) != _|_ {
					#appProto: #config.server.liveService["appProtocol"]
				}
				if #appProto != "" {
					appProtocol: #appProto
				}
				if #config.server.liveService.type == "NodePort" && #config.server.liveService.nodePortRtmp != _|_ {
					nodePort: #config.server.liveService.nodePortRtmp
				}
			},
			{
				name:       "rtmps"
				port:       #config.server.liveService.portRtmps
				protocol:   "TCP"
				targetPort: "rtmps"
				#appProto2: *"" | string
				if (#config.server.liveService["appProtocol"] & string) != _|_ {
					#appProto2: #config.server.liveService["appProtocol"]
				}
				if #appProto2 != "" {
					appProtocol: #appProto2
				}
				if #config.server.liveService.type == "NodePort" && #config.server.liveService.nodePortRtmps != _|_ {
					nodePort: #config.server.liveService.nodePortRtmps
				}
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		if (#config.server.liveService.trafficDistribution & string) != _|_ {
			trafficDistribution: #config.server.liveService.trafficDistribution
		}
	}
}
