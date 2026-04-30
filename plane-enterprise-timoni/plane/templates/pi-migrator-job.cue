package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#PIMigratorJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-api-migrate"
	}
	spec: {
		backoffLimit: 3
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-api-migrate"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-pi-api-migrate"
					image:           "\(#config.services.pi.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					command: [
						"/bin/bash",
						"-c",
						"set -e\nexec ./bin/entrypoint-migrator.sh\n",
					]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-pi-api-vars"},
						{secretRef: name:    "\(#config.metadata.name)-pi-api-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-opensearch-secrets"},
					]
				}]
				restartPolicy:      "OnFailure"
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
