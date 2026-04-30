package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#OutboxPollerDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-outbox-poller-wl"
	}
	spec: {
		replicas: #config.services.outbox_poller.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-outbox-poller"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-outbox-poller"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-outbox-poller"
					image:           "\(#config.services.api.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.outbox_poller.resources
					command: [
						"./bin/docker-entrypoint-outbox-poller.sh",
					]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-outbox-poller-vars"},
						{configMapRef: name: "\(#config.metadata.name)-app-vars"},
						{secretRef: name:    "\(#config.metadata.name)-app-secrets"},
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
