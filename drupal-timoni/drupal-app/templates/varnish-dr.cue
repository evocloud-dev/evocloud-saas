package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

#VarnishDestinationRule: {
	#config: #Config
	apiVersion: "networking.istio.io/v1alpha3"
	kind:       "DestinationRule"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "varnish"
	}
	spec: {
		host: "\(#config.metadata.name)-varnish.\(#config.metadata.namespace).svc.\(#config.varnish.clusterDomain)"
		trafficPolicy: tls: mode: #config.varnish.destinationRule.mode
	}
}
