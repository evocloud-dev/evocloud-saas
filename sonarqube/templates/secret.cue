package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-secrets"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"

	let databaseMode = #config.databaseMode
	let needsDbSecret = databaseMode == "external" && #config.database.external.existingSecret == "" && !(#config.externalSecrets.enabled && #config.externalSecrets.database.enabled) && #config.database.external.password != ""
	let needsMonitoringSecret = #config.sonarqube.monitoringPasscode != "" && #config.sonarqube.existingMonitoringPasscodeSecret == "" && !(#config.externalSecrets.enabled && #config.externalSecrets.monitoringPasscode.enabled)

	stringData: {
		if needsDbSecret {
			"\(#config.database.external.existingSecretPasswordKey)": #config.database.external.password
		}
		if needsMonitoringSecret {
			"\(#config.sonarqube.existingMonitoringPasscodeSecretKey)": #config.sonarqube.monitoringPasscode
		}
	}
}
