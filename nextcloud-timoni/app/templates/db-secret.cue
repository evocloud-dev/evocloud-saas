package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #DbSecret is the literal conversion of db-secret.yaml.
//
// The Secret is only emitted when:
//   - At least one DB engine is enabled: mariadb OR postgresql OR externalDatabase
//   - AND externalDatabase.existingSecret.enabled == false
//
// Mirrors Helm's:
//   {{- if or .Values.mariadb.enabled .Values.externalDatabase.enabled .Values.postgresql.enabled }}
//   {{- if not .Values.externalDatabase.existingSecret.enabled }}
//
// Credential source is mutually exclusive — exactly as Helm's if/else if/else chain:
//   mariadb.enabled     → read from mariadb.auth.*
//   postgresql.enabled  → read from postgresql.global.postgresql.auth.*
//   else                → read from externalDatabase.*
#DbSecret: corev1.#Secret & {
	#in: #Config

	apiVersion: "v1"
	kind:       "Secret"

	metadata: {
		// Helm uses .Release.Name (not fullname) for this secret — we match that exactly.
		name:      "\(#in.metadata.name)-db"
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
	}

	type: "Opaque"

	// stringData accepts plain-text values — Kubernetes handles base64 encoding.
	stringData: {
		// Branch 1: MariaDB — mirrors {{- if .Values.mariadb.enabled }}
		if #in.database.mariadb.enabled {
			"\(#in.database.externalDatabase.existingSecret.usernameKey)": #in.database.mariadb.auth.username
			"\(#in.database.externalDatabase.existingSecret.passwordKey)": #in.database.mariadb.auth.password
		}

		// Branch 2: PostgreSQL — mirrors {{- else if .Values.postgresql.enabled }}
		if !#in.database.mariadb.enabled && #in.database.postgresql.enabled {
			"\(#in.database.externalDatabase.existingSecret.usernameKey)": #in.database.postgresql.auth.username
			"\(#in.database.externalDatabase.existingSecret.passwordKey)": #in.database.postgresql.auth.password
		}

		// Branch 3: External DB — mirrors {{- else }} (externalDatabase.enabled)
		if !#in.database.mariadb.enabled && !#in.database.postgresql.enabled {
			"\(#in.database.externalDatabase.existingSecret.usernameKey)": #in.database.externalDatabase.user
			"\(#in.database.externalDatabase.existingSecret.passwordKey)": #in.database.externalDatabase.password
		}
	}
}
