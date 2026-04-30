package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#WorkerDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-worker-wl"
	}
	spec: {
		replicas: #config.services.worker.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-worker"
		}
		template: {
			metadata: labels: {
				"app.name": "\(#config.#namespace)-\(#config.metadata.name)-worker"
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-worker"
					image:           "\(#config.services.api.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					command: [
						"/bin/bash",
						"-c",
						"set -e\nexec ./bin/docker-entrypoint-worker.sh\n",
					]
					resources: #config.services.worker.resources
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-app-vars"},
						{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-opensearch-secrets"},
						if #config.services.silo.enabled {
							{secretRef: name: "\(#config.metadata.name)-silo-secrets"}
						},
					]
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
