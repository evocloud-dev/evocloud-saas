package templates

#Ingress: {
	#config: #Config

	if #config.kubeVersion =~ "^1\\.(19|[2-9][0-9])" {
		apiVersion: "networking.k8s.io/v1"
	}
	if #config.kubeVersion =~ "^1\\.(1[4-8])" {
		apiVersion: "networking.k8s.io/v1beta1"
	}
	if !#config.kubeVersion =~ "^1\\.(1[4-9]|[2-9][0-9])" {
		apiVersion: "extensions/v1beta1"
	}
	kind: "Ingress"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		if #config.ingress.labels != _|_ {
			labels: #config.metadata.labels & #config.ingress.labels
		}
		if #config.ingress.labels == _|_ {
			labels: #config.metadata.labels
		}
		if #config.ingress.annotations != _|_ && #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations & #config.ingress.annotations
		}
		if #config.ingress.annotations != _|_ && #config.metadata.annotations == _|_ {
			annotations: #config.ingress.annotations
		}
		if #config.ingress.annotations == _|_ && #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}
		if len(#config.ingress.tls) > 0 {
			tls: #config.ingress.tls
		}
		rules: [
			for hostData in #config.ingress.hosts {
				host: hostData.host
				http: paths: [
					for pathData in hostData.paths {
						path: pathData.path
						if pathData.pathType != "" && #config.kubeVersion =~ "^1\\.(1[8-9]|[2-9][0-9])" {
							pathType: pathData.pathType
						}
						backend: {
							if #config.kubeVersion =~ "^1\\.(19|[2-9][0-9])" {
								service: {
									name: "\(#config.metadata.name)-nginx"
									port: {
										number: #config.service.port
									}
								}
							}
							if !#config.kubeVersion =~ "^1\\.(19|[2-9][0-9])" {
								serviceName: "\(#config.metadata.name)-nginx"
								servicePort: #config.service.port
							}
						}
					},
				]
			},
		]
	}
}
