package templates

#IstioDestinationRule: {
	#config:    #Config
	apiVersion: "networking.istio.io/v1alpha3"
	kind:       "DestinationRule"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		host: "\(#config.metadata.name)-api"
		trafficPolicy: {
			if #config.serviceMesh.istio.api.connectionPool.enabled {
				connectionPool: http: {
					http1MaxPendingRequests:  #config.serviceMesh.istio.api.connectionPool.http1MaxPendingRequests
					maxRequestsPerConnection: #config.serviceMesh.istio.api.connectionPool.maxRequestsPerConnection
				}
			}
			if #config.serviceMesh.istio.api.outlierDetection.enabled {
				outlierDetection: {
					consecutive5xxErrors: #config.serviceMesh.istio.api.outlierDetection.consecutiveErrors
					interval:             #config.serviceMesh.istio.api.outlierDetection.interval
					baseEjectionTime:     #config.serviceMesh.istio.api.outlierDetection.baseEjectionTime
					maxEjectionPercent:   #config.serviceMesh.istio.api.outlierDetection.maxEjectionPercent
				}
			}
			if #config.serviceMesh.istio.api.loadBalancer.enabled {
				loadBalancer: simple: "LEAST_REQUEST"
			}
		}
	}
}

#IstioVirtualService: {
	#config:    #Config
	apiVersion: "networking.istio.io/v1alpha3"
	kind:       "VirtualService"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		hosts: ["\(#config.metadata.name)-api"]
		http: [{
			route: [{
				destination: host: "\(#config.metadata.name)-api"
			}]
			if #config.serviceMesh.istio.api.timeout.enabled {
				timeout: #config.serviceMesh.istio.api.timeout.http
			}
			retries: {
				attempts:      #config.serviceMesh.istio.api.circuitBreaker.maxRetries
				perTryTimeout: "2s"
				retryOn:       "connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes"
			}
		}]
	}
}
