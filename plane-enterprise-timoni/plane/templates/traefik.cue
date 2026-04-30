package templates

#TraefikMiddleware: {
	#config: #Config

	apiVersion: "traefik.io/v1alpha1"
	kind:       "Middleware"
	metadata: {
		name:      "\(#config.metadata.name)-body-limit"
		namespace: #config.#namespace
	}
	spec: {
		buffering: {
			maxRequestBodyBytes: #config.ingress.traefik.maxRequestBodyBytes
		}
	}
}

#TraefikIngressRoute: {
	#config: #Config

	apiVersion: "traefik.io/v1alpha1"
	kind:       "IngressRoute"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-ingress"
	}
	spec: {
		entryPoints: ["web", "websecure"]
		routes: [
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/spaces/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-space", port: "space-3000"}]
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/god-mode/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-admin", port: "admin-3000"}]
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/api/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-api", port: "api-8000"}]
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/auth/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-api", port: "api-8000"}]
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/graphql/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-api", port: "api-8000"}]
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/marketplace/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-api", port: "api-8000"}]
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/live/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-live", port: "live-8080"}]
			},
			if #config.services.silo.enabled {
				{
					match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/silo/`)"
					kind:  "Rule"
					middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
						services: [{name:    "\(#config.metadata.name)-silo", port: "silo-3000"}]
				}
			},
			if #config.services.pi.enabled {
				{
					match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/pi/`)"
					kind:  "Rule"
					middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
						services: [{name:    "\(#config.metadata.name)-pi-api", port: "pi-api-8000"}]
				}
			},
			if #config.services.minio.local_setup && #config.env.docstore_bucket != "" {
				{
					match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/\(#config.env.docstore_bucket)/`)"
					kind:  "Rule"
					middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
						services: [{name: "\(#config.metadata.name)-minio", port: "minio-9000"}]
				}
			},
			{
				match: "(Host(`\(#config.license.licenseDomain)`) || Host(`localhost`)) && PathPrefix(`/`)"
				kind:  "Rule"
				middlewares: [{name: "\(#config.metadata.name)-body-limit"}]
				services: [{name:    "\(#config.metadata.name)-web", port: "web-3000"}]
			},
		]
		if #config.ssl.tls_secret_name != "" {
			tls: secretName: #config.ssl.tls_secret_name
		}
	}
}
