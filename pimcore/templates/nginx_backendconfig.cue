package templates

#BackendConfigNginx: {
	#config: #Config

	apiVersion: "cloud.google.com/v1"
	kind:       "BackendConfig"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		timeoutSec: #config.nginx.backendConfig.timeoutSec
		healthCheck: {
			checkIntervalSec: #config.nginx.backendConfig.healthCheck.checkIntervalSec
			timeoutSec:       #config.nginx.backendConfig.healthCheck.timeoutSec
			healthyThreshold: #config.nginx.backendConfig.healthCheck.healthyThreshold
			unhealthyThreshold: #config.nginx.backendConfig.healthCheck.unhealthyThreshold
			type:        #config.nginx.backendConfig.healthCheck.type
			requestPath: #config.nginx.backendConfig.healthCheck.requestPath
			port:        #config.nginx.backendConfig.healthCheck.port
		}
	}
}
