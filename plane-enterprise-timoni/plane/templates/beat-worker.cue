package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#BeatWorkerDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-beat-worker-wl"
	}
	spec: {
		replicas: #config.services.beatworker.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-beat-worker"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-beat-worker"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-beat-worker"
					image:           "\(#config.services.api.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.beatworker.resources
					command: [
						"./bin/docker-entrypoint-beat.sh",
					]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-app-vars"},
						{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-opensearch-secrets"},
						if #config.services.silo.enabled {
							{secretRef: name: "\(#config.metadata.name)-silo-secrets"}
						},
					]
					if #config.extraEnv != [] {
						env: #config.extraEnv
					}
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
