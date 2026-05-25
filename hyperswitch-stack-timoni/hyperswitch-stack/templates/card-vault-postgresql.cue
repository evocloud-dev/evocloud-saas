package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// 1. /charts/hyperswitch-card-vault/charts/postgresql/templates/secrets.yaml
#CardVaultPostgresqlSecret: corev1.#Secret & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-locker-db"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/name": "locker-db"
		}
	}
	type: "Opaque"
	stringData: {
		"password": pg.auth.password
	}
}

// Helper to merge annotations safely
#MergeAnnotations: {
	#global: {[string]: string}
	#local: {[string]: string}
	#result: {
		for k, v in #global {"\(k)": v}
		for k, v in #local {"\(k)": v}
	}
}
