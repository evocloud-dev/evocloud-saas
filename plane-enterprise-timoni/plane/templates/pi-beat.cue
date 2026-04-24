package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#PIBeatDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-beat-wl"
	}
	spec: {
		replicas: 1
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-beat"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-beat"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-pi-beat"
					image:           "\(#config.services.pi.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					command: [
						"/bin/bash",
						"-c",
						"set -e\nexec ./bin/entrypoint-celery-beat.sh\n",
					]
					resources: {
						requests: {
							cpu:    "500m"
							memory: "1000Mi"
						}
						limits: {
							cpu:    "500m"
							memory: "1000Mi"
						}
					}
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-pi-api-vars"},
						{secretRef: name:    "\(#config.metadata.name)-pi-api-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-opensearch-secrets"},
					]
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
