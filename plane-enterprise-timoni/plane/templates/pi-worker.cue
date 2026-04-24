package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#PIWorkerDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-worker-wl"
	}
	spec: {
		replicas: #config.services.pi_worker.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-worker"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-worker"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-pi-worker"
					image:           "\(#config.services.pi.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.pi_worker.resources
					command: [
						"/bin/bash",
						"-c",
						"set -e\nexec ./bin/entrypoint-celery-worker.sh\n",
					]
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
