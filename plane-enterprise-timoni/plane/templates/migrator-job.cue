package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#MigratorJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-api-migrate"
	}
	spec: {
		backoffLimit: 3
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-api-migrate"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-api-migrate"
					image:           "\(#config.services.api.image):\(#config.planeVersion)" // Uses same image as API
					imagePullPolicy: "Always"
					command: ["./bin/docker-entrypoint-migrator.sh"]
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
				restartPolicy:      "OnFailure"
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
